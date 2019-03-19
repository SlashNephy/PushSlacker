ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PushSlacker
PushSlacker_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += PushSlackerPreference
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
