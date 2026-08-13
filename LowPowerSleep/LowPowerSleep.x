#import "LowPowerSleep.h"

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:nsDomainString];
    enabled = (enabledValue) ? [enabledValue boolValue] : YES;
}

// iOS 16.6 diagnostic build: deliberately no Low Power Mode API calls.
// This isolates SpringBoard hook/injection compatibility from the LPM API.

%hook SBSleepWakeHardwareButtonInteraction
- (void)_playLockSound {
    %orig;
}
%end

%hook SBCoverSheetPrimarySlidingViewController
- (void)viewWillDisappear:(BOOL)arg1 {
    %orig;
}
%end

%ctor {
    notificationCallback(NULL, NULL, NULL, NULL, NULL);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)nsNotificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);
}
