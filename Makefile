ARCHS = armv7 arm64
TARGET = iphone::10.2:9.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PushSlacker
PushSlacker_FILES = Tweak.xm
#SUBPROJECTS += PushSlackerPreference

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
