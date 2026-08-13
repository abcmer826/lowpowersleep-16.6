ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard
export DEBUG = 0
export FINALPACKAGE = 1

# Default to Rootless. The GitHub Actions workflow overrides this for each build.
export THEOS_PACKAGE_SCHEME ?= rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LowPowerSleep

LowPowerSleep_FILES = LowPowerSleep.x
LowPowerSleep_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
