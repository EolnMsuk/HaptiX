THEOS_PACKAGE_SCHEME = roothide
TARGET := iphone:clang:14.5:15.0
ARCHS = arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HaptiX

HaptiX_FILES = Tweak.x
HaptiX_CFLAGS = -fobjc-arc
HaptiX_FRAMEWORKS = UIKit AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += haptixprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
