include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ProperLockGestures
ProperLockGestures_FILES = ProperLockGesturesRootListController.m
ProperLockGestures_INSTALL_PATH = /Library/PreferenceBundles
ProperLockGestures_FRAMEWORKS = UIKit
ProperLockGestures_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ProperLockGestures.plist$(ECHO_END)
