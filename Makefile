include theos/makefiles/common.mk

TWEAK_NAME = YouFadeMeUp
YouFadeMeUp_FILES = Tweak.xm
YouFadeMeUp_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
