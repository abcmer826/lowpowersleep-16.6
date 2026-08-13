#import <Foundation/Foundation.h>

bool is_LPM_on_before;

@interface _PMLowPowerMode : NSObject
+ (instancetype)sharedInstance;
- (NSInteger)getPowerMode;
- (void)setPowerMode:(NSInteger)powerMode fromSource:(NSString *)source;
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
