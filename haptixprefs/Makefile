TARGET := iphone:clang:16.5:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = haptixprefs

haptixprefs_FILES = HaptixPrefsRootListController.m
haptixprefs_FRAMEWORKS = UIKit
haptixprefs_PRIVATE_FRAMEWORKS = Preferences
haptixprefs_EXTRA_FRAMEWORKS = AltList
haptixprefs_INSTALL_PATH = /Library/PreferenceBundles

# Explicitly tell the compiler and linker to search the vendor folder
haptixprefs_CFLAGS = -fobjc-arc -F../vendor
haptixprefs_LDFLAGS = -F../vendor

include $(THEOS_MAKE_PATH)/bundle.mk
