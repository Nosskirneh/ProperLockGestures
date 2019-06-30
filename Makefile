TARGET = iphone:clang:9.2
ARCHS = armv7s arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ProperLockGestures
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
