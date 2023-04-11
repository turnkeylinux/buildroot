#!/usr/bin/make -f
# Copyright (c) 2020-2021 TurnKey GNU/Linux - https://www.turnkeylinux.org

LOCAL_DISTRO := $(shell lsb_release -si | tr [A-Z] [a-z])
LOCAL_CODENAME := $(shell lsb_release -sc)
LOCAL_RELEASE := $(LOCAL_DISTRO)/$(LOCAL_CODENAME)
SHELL := /bin/bash

ifndef RELEASE
$(info RELEASE not defined - falling back to system: '$(LOCAL_RELEASE)')
RELEASE := $(LOCAL_RELEASE)
endif
CERT_PATH := usr/local/share/ca-certificates

# transitional related
# note: these packages will be build & installed in the order they're defined
PACKAGES := turnkey-gitwrapper autoversion verseek turnkey-chroot

.PHONY: complete
complete: install

BUILDROOT := y
FAB_SHARE_PATH ?= /usr/share/fab
include $(FAB_SHARE_PATH)/product.mk

# setup apt and dns for root.build
define bootstrap/post
	if [ -n "$(TRANSITION_NO_TURNKEY_APT_REPO)" ]; then \
		echo "TRANSITION_NO_TURNKEY_APT_REPO" > $O/bootstrap/turnkey-transition-info; \
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
		if [ -f $O/root.patched/turnkey-transition-info ]; then\
			echo "note this is a transitional build, some functionality will be disabled";\
		fi
endef

ifneq ($(LOCAL_RELEASE),$(RELEASE))
export TRANSITION_NO_TURNKEY_APT_REPO=y
install: transition_pkg_install
	rsync --delete -Hac $O/root.patched/ $(FAB_PATH)/buildroots/$$(basename $$RELEASE)/
else
install: pkg_install
	rsync --delete -Hac $O/root.patched/ $(FAB_PATH)/buildroots/$$(basename $$RELEASE)/
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

.PHONY: pkg_install
pkg_install: root.patched
	fab-chroot $O/root.patched "apt-get update && apt-get install -y turnkey-lazyclass turnkey-gitwrapper verseek autoversion" \
		|| (echo "Apt failed; is this a transition? If so, please check README for final steps to install required TurnKey software & rsync."; exit 1);
	fab-chroot $O/root.patched "apt-get clean";
