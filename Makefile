TARGET := iphone:clang:16.5:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HaptiX

HaptiX_FILES = Tweak.x
HaptiX_CFLAGS = -fobjc-arc
HaptiX_FRAMEWORKS = UIKit AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += haptixprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

# The "Magic" part that forces PreferenceLoader to see the settings menu
internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp haptixprefs/entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/HaptiX.plist$(ECHO_END)
