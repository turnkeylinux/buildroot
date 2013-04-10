RELEASE ?= debian/squeeze

default: root.patched

FAB_SHARE_PATH ?= /usr/share/fab
include $(FAB_SHARE_PATH)/product.mk

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
	@echo "    eg. rsync --delete -Hac -v $O/root.patched/ $(FAB_PATH)/buildroots/$(shell basename $(RELEASE))-$(FAB_ARCH)/";
endef

