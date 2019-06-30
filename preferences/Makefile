TARGET = iphone:clang:9.2
ARCHS = armv7s arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ProperLockGestures
$(BUNDLE_NAME)_FILES = PLGRootListController.m ../../TwitterStuff/Prompt.m
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_FRAMEWORKS = UIKit
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ProperLockGestures.plist$(ECHO_END)
