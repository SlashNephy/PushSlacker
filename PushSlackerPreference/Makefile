ARCHS = armv7 armv7s arm64
TARGET = iphone::10.2:9.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PushSlacker
PushSlacker_FILES = PushSlackerController.m
PushSlacker_INSTALL_PATH = /Library/PreferenceBundles
PushSlacker_FRAMEWORKS = UIKit Foundation
PushSlacker_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp PushSlacker.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PushSlacker.plist$(ECHO_END)
