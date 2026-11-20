// Adapted from ChoySee. See Resources/ChoySee-LICENSE.txt.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HaptixUpdateCompletion)(NSString * _Nullable tag,
    NSURL * _Nullable newerReleaseURL, NSString * _Nullable failureMessage);

@interface HaptixUpdateChecker : NSObject
// Called by the Updates action. Completion runs on the main thread.
+ (void)checkInstalledVersion:(nullable NSString *)version completion:(HaptixUpdateCompletion)completion;
@end

NS_ASSUME_NONNULL_END
