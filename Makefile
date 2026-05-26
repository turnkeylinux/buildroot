#!/usr/bin/make -f
# Copyright (c) 2020-2025 TurnKey GNU/Linux - https://www.turnkeylinux.org

HOST_DISTRO := $(shell lsb_release -si | tr [A-Z] [a-z])
HOST_CODENAME := $(shell lsb_release -sc)
HOST_DEB_VER := $(shell lsb_release -sr)
HOST_RELEASE := $(HOST_DISTRO)/$(HOST_CODENAME)
HOST_ARCH := $(shell dpkg --print-architecture)
SHELL := /bin/bash

CERT_PATH := usr/local/share/ca-certificates
BUILDROOT := y
FAB_SHARE_PATH ?= /usr/share/fab

# transitional related
# note: these packages will be built & installed in the order they're defined
PACKAGES := turnkey-gitwrapper autoversion verseek turnkey-chroot

ifdef SUDO_USER
  $(info running as sudo)
  SUDO := running as sudo - set FAB_PATH explicitly
endif

ifndef FAB_PATH
  $(error FAB_PATH is not set $(SUDO))
else
  BOOTSTRAPS_PATH ?= $(FAB_PATH)/bootstraps
  BUILDROOTS_PATH ?= $(FAB_PATH)/buildroots
endif
BOOTSTRAPS_PATH := $(BOOTSTRAPS_PATH)
BUILDROOTS_PATH := $(BUILDROOTS_PATH)

ifndef RELEASE
  $(info RELEASE not defined - falling back to system: '$(HOST_RELEASE)')
  RELEASE := $(HOST_RELEASE)
endif

ifndef FAB_ARCH
  $(info FAB_ARCH not defined - falling back to system: '$(HOST_ARCH)')
  FAB_ARCH := $(HOST_ARCH)
endif

DEFAULT_DIR := $(shell basename $(RELEASE))-$(FAB_ARCH)
BOOTSTRAP ?= $(BOOTSTRAPS_PATH)/$(DEFAULT_DIR)
CHROOT_DIR ?= $(BUILDROOTS_PATH)/$(DEFAULT_DIR)
CHROOT_DIR := $(CHROOT_DIR)

.PHONY: complete
complete: pkg_install

include $(FAB_SHARE_PATH)/product.mk

define help/pre
    @echo
    @echo 'Configurable variables'
    @echo '======================'
    @echo '  Env var                    [VALUE]'
    @echo '  -------                    -------'
    @echo '# General config'
    @echo '  FAB_PATH (required)        $(value FAB_PATH)'
    @echo '  FAB_ARCH                   $(value FAB_ARCH)'
    @echo '  RELEASE                    $(value RELEASE)'
    @echo '  TKL_TESTING=y              # enable Turnkey testing repo'
    @echo '  NO_PROXY=true              # disable proxy caching'
    @echo
    @echo '# Base paths'
    @echo '  BOOTSTRAPS_PATH            $(value BOOTSTRAPS_PATH)'
    @echo '  BUILDROOTS_PATH            $(value BUILDROOTS_PATH)'
    @echo
    @echo '# Target paths (overrides base path/s if set)'
    @echo '  CHROOT_DIR                 $(value CHROOT_DIR)'
    @echo '  BOOTSTRAP                  $(value BOOTSTRAP)'
endef

# override full fab product.mk help
define help/body
    @echo
endef

# setup apt and dns for root.build
define bootstrap/post
	echo "export RELEASE=$(RELEASE)" > $O/bootstrap/turnkey-buildenv;
	echo "export HOST_DEB_VER=$(HOST_DEB_VER)" >> $O/bootstrap/turnkey-buildenv;
	echo "export HOST_ARCH=$(HOST_ARCH)" >> $O/bootstrap/turnkey-buildenv;
	echo "export FAB_ARCH=$(FAB_ARCH)" >> $O/bootstrap/turnkey-buildenv;
	if [ -n "$(NO_TURNKEY_APT_REPO)" ]; then \
		echo "export NO_TURNKEY_APT_REPO=y" >> $O/bootstrap/turnkey-buildenv; \
	fi
	if [ -n "$(TKL_TESTING)" ]; then \
		echo "export TKL_TESTING=y" >> $O/bootstrap/turnkey-buildenv; \
	fi
	if [ -n "$(APT_PROXY_OVERRIDE)" ]; then \
		echo "export APT_PROXY_OVERRIDE=$(APT_PROXY_OVERRIDE)" >> $O/bootstrap/turnkey-buildenv; \
	elif [ -n "$(NO_PROXY)" ]; then \
		echo "export NO_PROXY=$(NO_PROXY)" >> $O/bootstrap/turnkey-buildenv; \
	fi
	fab-apply-overlay $(COMMON_OVERLAYS_PATH)/bootstrap_apt $O/bootstrap;
	fab-chroot $O/bootstrap "echo nameserver 8.8.8.8 > /etc/resolv.conf";
	fab-chroot $O/bootstrap "echo nameserver 8.8.4.4 >> /etc/resolv.conf";
	mkdir -p $O/bootstrap/$(CERT_PATH);
	# temporarily allow cert to not exist
	cp /$(CERT_PATH)/squid_proxyCA.crt $O/bootstrap/$(CERT_PATH)/ || true;
	fab-chroot $O/bootstrap --script $(COMMON_CONF_PATH)/bootstrap_apt;
endef

define root.patched/cleanup
	# kill stray processes
	fuser -k $O/root.patched || true;\
	if [ -f $O/root.patched/turnkey-buildenv ]; then\
		echo "note this is a transitional build, some functionality will be disabled";\
	fi
endef

install: pkg_install
	mkdir -p $(BUILDROOTS_PATH)
	rsync --delete -Hac $O/root.patched/ $(CHROOT_DIR)/

pkg_install: normal_pkg_install
ifdef NO_TURNKEY_APT_REPO
  pkg_install: transition_pkg_install
else
  ifneq ($(HOST_RELEASE),$(RELEASE))
    $(info # transition detected - building $(RELEASE) on $(HOST_RELEASE))
    $(info # to disable TKL apt repos rerun with NO_TURNKEY_APT_REPO=y set)
  endif
  ifneq ($(HOST_ARCH),$(FAB_ARCH))
    $(info # build on foreign architecture detected - building $(FAB_ARCH) on $(HOST_ARCH))
    $(info # to disable TKL apt repos rerun with NO_TURNKEY_APT_REPO=y set)
  endif
endif

.PHONY: transition_pkg_install
transition_pkg_install: root.patched
	mkdir -p $O/root.patched/root/builddeps /turnkey/public;\
	i=0
	for pkg in ${PACKAGES}; do\
		LOCAL="/turnkey/public/$${pkg}";\
		if [ ! -d "$${LOCAL}" ]; then\
			git clone https://github.com/turnkeylinux/"$${pkg}" "$${LOCAL}";\
		fi;\
		cp -a $${LOCAL} $O/root.patched/root/builddeps/$$(printf "%03d-%s" "$$i" "$$pkg");\
		((i++));\
	done;\
	\
	fab-chroot --script "$O/../scripts/install_packages.sh" "$O/root.patched"

.PHONY: normal_pkg_install
normal_pkg_install: root.patched
	fab-chroot $O/root.patched "apt-get update && apt-get install -y turnkey-lazyclass turnkey-gitwrapper verseek autoversion" \
		|| (echo "Apt failed; is this a transition? If so, please check README for final steps to install required TurnKey software & rsync."; exit 1);
	fab-chroot $O/root.patched "apt-get clean";
