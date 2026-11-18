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

ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
haptixprefs_CFLAGS += -DHAPTIX_NATIVE_ROOTHIDE=1
endif

# Modern rootful AltList uses an @rpath install name.
ifeq ($(THEOS_PACKAGE_SCHEME),)
haptixprefs_LDFLAGS += -Wl,-rpath,/Library/Frameworks
endif

include $(THEOS_MAKE_PATH)/bundle.mk
