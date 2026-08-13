#import "LowPowerSleep.h"

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:nsDomainString];
    enabled = (enabledValue) ? [enabledValue boolValue] : YES;
}

%hook SBSleepWakeHardwareButtonInteraction
- (void)_playLockSound {
    %orig;

    if (enabled) {
        if ([[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
            // Preserve the author's original behavior: do nothing if already locked.
        } else {
            if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
                is_LPM_on_before = YES;
            } else {
                // iOS 15+: _CDBatterySaver was replaced by _PMLowPowerMode.
                // Use the documented two-argument selector; do not use the
                // completion variant or manually dlopen the private framework.
                _PMLowPowerMode *lowPowerMode = [%c(_PMLowPowerMode) sharedInstance];
                if (lowPowerMode) {
                    [lowPowerMode setPowerMode:1 fromSource:@"SpringBoard"];
                }
                is_LPM_on_before = NO;
            }
        }
    }
}
%end

%hook SBCoverSheetPrimarySlidingViewController
- (void)viewWillDisappear:(BOOL)arg1 {
    %orig;

    if (enabled) {
        if ([[%c(SBCoverSheetPresentationManager) sharedInstance] hasBeenDismissedSinceKeybagLock]) {
            // Preserve the author's original behavior.
        } else {
            if (is_LPM_on_before == YES) {
                // Low Power Mode was already enabled before locking; leave it on.
            } else {
                _PMLowPowerMode *lowPowerMode = [%c(_PMLowPowerMode) sharedInstance];
                if (lowPowerMode) {
                    [lowPowerMode setPowerMode:0 fromSource:@"SpringBoard"];
                }
            }
        }
    }
}
%end

%ctor {
    notificationCallback(NULL, NULL, NULL, NULL, NULL);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)nsNotificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);
}
