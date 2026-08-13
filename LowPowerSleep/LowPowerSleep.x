#import "LowPowerSleep.h"

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:nsDomainString];
    enabled = (enabledValue) ? [enabledValue boolValue] : YES;
}

static BOOL lpmIsEnabled(void) {
    Class cls = %c(_PMLowPowerMode);
    if (!cls || ![cls respondsToSelector:@selector(sharedInstance)]) {
        return [[NSProcessInfo processInfo] isLowPowerModeEnabled];
    }

    id lpm = [cls sharedInstance];
    if (!lpm || ![lpm respondsToSelector:@selector(getPowerMode)]) {
        return [[NSProcessInfo processInfo] isLowPowerModeEnabled];
    }

    return [lpm getPowerMode] == 1;
}

static void setLPM(BOOL enabledValue) {
    Class cls = %c(_PMLowPowerMode);
    if (!cls || ![cls respondsToSelector:@selector(sharedInstance)]) {
        return;
    }

    id lpm = [cls sharedInstance];
    SEL setSelector = @selector(setPowerMode:fromSource:);
    if (!lpm || ![lpm respondsToSelector:setSelector]) {
        return;
    }

    // Do not change Low Power Mode synchronously from SpringBoard's lock/unlock
    // transition callbacks. On iOS 16 this can re-enter the lock transaction.
    [lpm setPowerMode:enabledValue ? 1 : 0 fromSource:@"SpringBoard"];
}

%hook SBSleepWakeHardwareButtonInteraction
- (void)_playLockSound {
    %orig;

    if (enabled) {
        Class lockManagerClass = %c(SBLockScreenManager);
        id lockManager = lockManagerClass ? [lockManagerClass sharedInstance] : nil;
        BOOL isLocked = lockManager && [lockManager respondsToSelector:@selector(isUILocked)]
            ? [lockManager isUILocked] : NO;

        if (!isLocked) {
            is_LPM_on_before = lpmIsEnabled();
            if (!is_LPM_on_before) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (enabled) {
                        setLPM(YES);
                    }
                });
            }
        }
    }
}
%end

%hook SBCoverSheetPrimarySlidingViewController
- (void)viewWillDisappear:(BOOL)arg1 {
    %orig;

    if (enabled) {
        Class presentationManagerClass = %c(SBCoverSheetPresentationManager);
        id presentationManager = presentationManagerClass ? [presentationManagerClass sharedInstance] : nil;
        BOOL dismissedSinceKeybagLock = presentationManager && [presentationManager respondsToSelector:@selector(hasBeenDismissedSinceKeybagLock)]
            ? [presentationManager hasBeenDismissedSinceKeybagLock] : NO;

        if (!dismissedSinceKeybagLock && !is_LPM_on_before) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (enabled) {
                    setLPM(NO);
                }
            });
        }
    }
}
%end

%ctor {
    notificationCallback(NULL, NULL, NULL, NULL, NULL);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)nsNotificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);
}
