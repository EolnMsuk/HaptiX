TARGET := iphone:clang:16.5:13.0
THEOS_PACKAGE_SCHEME ?= rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = haptixprefs

haptixprefs_FILES = HaptixPrefsRootListController.m
haptixprefs_FRAMEWORKS = UIKit
haptixprefs_PRIVATE_FRAMEWORKS = Preferences
haptixprefs_EXTRA_FRAMEWORKS = AltList
haptixprefs_INSTALL_PATH = /Library/PreferenceBundles

ALTLIST_FRAMEWORK_SEARCH_PATH ?= ../vendor

haptixprefs_CFLAGS = -fobjc-arc -F$(ALTLIST_FRAMEWORK_SEARCH_PATH)
haptixprefs_LDFLAGS = -F$(ALTLIST_FRAMEWORK_SEARCH_PATH)

include $(THEOS_MAKE_PATH)/bundle.mk
