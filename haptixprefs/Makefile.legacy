TARGET ?= iphone:clang:16.5:13.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = haptixprefs

haptixprefs_FILES = HaptixPrefsRootListController.m
haptixprefs_FRAMEWORKS = UIKit
haptixprefs_PRIVATE_FRAMEWORKS = Preferences
haptixprefs_EXTRA_FRAMEWORKS = AltList
haptixprefs_INSTALL_PATH = /Library/PreferenceBundles

haptixprefs_CFLAGS = -fobjc-arc -F$(THEOS_PROJECT_DIR)/vendor
haptixprefs_LDFLAGS = -F$(THEOS_PROJECT_DIR)/vendor

include $(THEOS_MAKE_PATH)/bundle.mk
