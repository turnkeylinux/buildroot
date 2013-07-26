default: root.patched

FAB_SHARE_PATH ?= /usr/share/fab
include $(FAB_SHARE_PATH)/product.mk

define root.patched/cleanup
        # kill stray processes
        fuser -k $O/root.patched || true
endef

