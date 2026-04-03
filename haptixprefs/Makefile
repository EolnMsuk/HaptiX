THEOS_PACKAGE_SCHEME = roothide
TARGET := iphone:clang:14.5:15.0
ARCHS = arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = haptixprefs

haptixprefs_FILES = HaptixPrefsRootListController.m
haptixprefs_FRAMEWORKS = UIKit
haptixprefs_PRIVATE_FRAMEWORKS = Preferences
haptixprefs_INSTALL_PATH = /Library/PreferenceBundles
haptixprefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
