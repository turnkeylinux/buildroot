RELEASE ?= debian/squeeze

default: root.patched

FAB_SHARE_PATH ?= /usr/share/fab
include $(FAB_SHARE_PATH)/product.mk

define root.patched/post
	@echo;
	@echo "Reminder: install turnkey build deps if available";
	@echo "    eg. fab-install --no-deps $O/root.patched plan/manual";
	@echo;
	@echo "Reminder: copy generated buildroot to buildroots folder";
	@echo "    eg. rsync --delete -Hac -v $O/root.patched/ $(FAB_PATH)/buildroots/$(shell basename $(RELEASE))-$(FAB_ARCH)/";
endef

