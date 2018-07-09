ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PushSlacker
PushSlacker_FILES = Tweak.xm
SUBPROJECTS += PushSlackerPreference

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
