#!/usr/bin/make -f
# Copyright (c) 2020 TurnKey GNU/Linux - https://www.turnkeylinux.org

ifndef RELEASE
DISTRO := $(shell lsb_release -is | tr [:upper:] [:lower:])
CODENAME := $(shell lsb_release -sc)
AUTORELEASE := $(DISTRO)/$(CODENAME)
$(info RELEASE not defined - falling back to system: '$(AUTORELEASE)')
RELEASE := $(AUTORELEASE)
endif

.PHONY: any
all: install

BUILDROOT := y
FAB_SHARE_PATH ?= /usr/share/fab
include $(FAB_SHARE_PATH)/product.mk

# setup apt and dns for root.build
define bootstrap/post

	fab-apply-overlay $(COMMON_OVERLAYS_PATH)/bootstrap_apt $O/bootstrap;
	fab-chroot $O/bootstrap "echo nameserver 8.8.8.8 > /etc/resolv.conf";
	fab-chroot $O/bootstrap "echo nameserver 8.8.4.4 >> /etc/resolv.conf";
	mkdir -p $O/bootstrap/usr/local/share/ca-certificates/;
	# temporarily allow cert to not exist
	cp /usr/local/share/ca-certificates/squid_proxyCA.crt $O/bootstrap/usr/local/share/ca-certificates/ || true;
	fab-chroot $O/bootstrap --script $(COMMON_CONF_PATH)/bootstrap_apt;
endef

define root.patched/cleanup
        # kill stray processes
        fuser -k $O/root.patched || true
endef

.PHONY: transition
transition: root.patched

	$(info Please check README for final steps to install required TurnKey software & rsync.)

.PHONY: install
install: root.patched
	fab-chroot $O/root.patched "apt-get update && apt-get install -y turnkey-lazyclass turnkey-gitwrapper verseek autoversion" \
		|| (echo "Apt failed; is this a transition? If so, please check README for final steps to install required TurnKey software & rsync."; exit 1);
	fab-chroot $O/root.patched "apt-get clean"
