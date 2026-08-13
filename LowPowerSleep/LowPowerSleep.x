#import "LowPowerSleep.h"
#import <objc/message.h>
#import <dlfcn.h>

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:nsDomainString];
    enabled = (enabledValue) ? [enabledValue boolValue] : YES;
}

static _PMLowPowerMode *LPSLowPowerMode(void) {
    Class cls = NSClassFromString(@"_PMLowPowerMode");
    if (!cls) {
        // SpringBoard does not necessarily load LowPowerMode.framework before the tweak.
        dlopen("/System/Library/PrivateFrameworks/LowPowerMode.framework/LowPowerMode", RTLD_LAZY | RTLD_LOCAL);
        cls = NSClassFromString(@"_PMLowPowerMode");
    }
    if (!cls || ![cls respondsToSelector:@selector(sharedInstance)]) {
        NSLog(@"[LowPowerSleep] _PMLowPowerMode is unavailable");
        return nil;
    }
    id instance = [cls sharedInstance];
    if (!instance) {
        NSLog(@"[LowPowerSleep] _PMLowPowerMode sharedInstance returned nil");
        return nil;
    }
    return instance;
}

static BOOL LPSGetPowerMode(_PMLowPowerMode *lowPowerMode) {
    if (!lowPowerMode || ![lowPowerMode respondsToSelector:@selector(getPowerMode)]) {
        return NO;
    }
    return [lowPowerMode getPowerMode] == 1;
}

static BOOL LPSSetPowerMode(_PMLowPowerMode *lowPowerMode, BOOL enabledMode) {
    if (!lowPowerMode) {
        return NO;
    }

    SEL twoArg = @selector(setPowerMode:fromSource:);
    if ([lowPowerMode respondsToSelector:twoArg]) {
        ((void (*)(id, SEL, NSInteger, id))objc_msgSend)(lowPowerMode, twoArg, enabledMode ? 1 : 0, @"SpringBoard");
        return YES;
    }

    SEL threeArg = @selector(setPowerMode:fromSource:withCompletion:);
    if ([lowPowerMode respondsToSelector:threeArg]) {
        void (^completion)(BOOL) = ^(BOOL success) {
            NSLog(@"[LowPowerSleep] setPowerMode=%d completion=%d", enabledMode, success);
        };
        ((void (*)(id, SEL, NSInteger, id, id))objc_msgSend)(lowPowerMode, threeArg, enabledMode ? 1 : 0, @"SpringBoard", completion);
        return YES;
    }

    NSLog(@"[LowPowerSleep] no supported setPowerMode selector");
    return NO;
}

%hook SBSleepWakeHardwareButtonInteraction
- (void)_playLockSound {
    %orig;

    if (!enabled) {
        return;
    }

    if ([[%c(SBLockScreenManager) sharedInstance] isUILocked]) {
        return;
    }

    _PMLowPowerMode *lowPowerMode = LPSLowPowerMode();
    if (!lowPowerMode) {
        return;
    }

    if (LPSGetPowerMode(lowPowerMode)) {
        is_LPM_on_before = YES;
        NSLog(@"[LowPowerSleep] LPM was already enabled");
    } else {
        is_LPM_on_before = NO;
        LPSSetPowerMode(lowPowerMode, YES);
        NSLog(@"[LowPowerSleep] requested LPM enable");
    }
}
%end

%hook SBCoverSheetPrimarySlidingViewController
- (void)viewWillDisappear:(BOOL)arg1 {
    %orig;

    if (!enabled) {
        return;
    }

    if ([[%c(SBCoverSheetPresentationManager) sharedInstance] hasBeenDismissedSinceKeybagLock]) {
        return;
    }

    if (is_LPM_on_before) {
        return;
    }

    _PMLowPowerMode *lowPowerMode = LPSLowPowerMode();
    if (lowPowerMode) {
        LPSSetPowerMode(lowPowerMode, NO);
        NSLog(@"[LowPowerSleep] requested LPM disable");
    }
}
%end

%ctor {
    notificationCallback(NULL, NULL, NULL, NULL, NULL);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)nsNotificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);
}
