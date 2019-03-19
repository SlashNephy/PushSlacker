ARCHS = arm64

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PushSlackerPreference
PushSlackerPreference_FILES = PushSlackerRootListController.m
PushSlackerPreference_INSTALL_PATH = /Library/PreferenceBundles
PushSlackerPreference_FRAMEWORKS = UIKit
PushSlackerPreference_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp PushSlacker.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PushSlackerPreference.plist$(ECHO_END)
