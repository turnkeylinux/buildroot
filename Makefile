RELEASE ?= debian/wheezy

default: root.patched

FAB_SHARE_PATH ?= /usr/share/fab
include $(FAB_SHARE_PATH)/product.mk

define root.patched/post
	@echo;
	@echo "Reminder: copy generated buildroot to buildroots folder";
	@echo "          eg. rsync --delete -Hac -v $O/root.patched/ /turnkey/fab/buildroots/$(shell basename $(RELEASE))/"
endef

