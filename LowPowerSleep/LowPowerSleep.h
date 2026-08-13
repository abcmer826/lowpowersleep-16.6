#import <Foundation/Foundation.h>

bool is_LPM_on_before;

// iOS 15+
// LowPowerMode.framework replaces _CDBatterySaver.
@interface _PMLowPowerMode : NSObject
+ (id)sharedInstance;
- (NSInteger)getPowerMode;
- (void)setPowerMode:(NSInteger)arg0 fromSource:(id)arg1;
@end

@interface SBLockScreenManager : NSObject
-(BOOL)isUIUnlocking;
-(BOOL)isUILocked;
+(SBLockScreenManager *)sharedInstance;
@end

@interface SBCoverSheetPresentationManager : NSObject
+(id)sharedInstance;
-(BOOL)hasBeenDismissedSinceKeybagLock;
@end

@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

static NSString * nsDomainString = @"com.hoangdus.lowpowersleep";
static NSString * nsNotificationString = @"com.hoangdus.lowpowersleep/preferences.changed";
static BOOL enabled;
