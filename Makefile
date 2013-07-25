ifndef RELEASE
$(error RELEASE not defined, e.g., debian/wheezy)
endif

default: root.patched

FAB_SHARE_PATH ?= /usr/share/fab
include $(FAB_SHARE_PATH)/product.mk

TARGET_RSYNC = $(FAB_PATH)/buildroots/$(shell basename $(RELEASE))/

define root.patched/post
	@echo;
	@echo "Install turnkey build deps:";
	@echo "    if already available in pool:";
	@echo "      fab-install --no-deps $O/root.patched plan/manual";
	@echo "    else:";
	@echo "      for package in plan/manual; cd package; build-deb";
	@echo "      copy debs to $O/root.patched and dpkg -i ...";
	@echo;
	@echo "Tip: copy generated buildroot to buildroots folder";
	@echo "    eg. rsync --delete -Hac -v $O/root.patched/ $(TARGET_RSYNC)";
endef

define root.patched/cleanup
        # kill stray processes
        fuser -k $O/root.patched || true
endef

