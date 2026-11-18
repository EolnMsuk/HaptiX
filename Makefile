export ARCHS ?= arm64 arm64e
export TARGET ?= iphone:clang:16.5:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HaptiX

HaptiX_FILES = Tweak.x
HaptiX_CFLAGS = -fobjc-arc
HaptiX_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += haptixprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
