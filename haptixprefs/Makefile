THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:16.5:14.5
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = haptixprefs

haptixprefs_FILES = HaptixPrefsRootListController.m
haptixprefs_FRAMEWORKS = UIKit
haptixprefs_PRIVATE_FRAMEWORKS = Preferences
haptixprefs_INSTALL_PATH = /Library/PreferenceBundles
haptixprefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
