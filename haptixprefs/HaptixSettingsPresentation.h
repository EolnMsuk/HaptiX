// Adapted from ChoySee. See Resources/ChoySee-LICENSE.txt.
#import <UIKit/UIKit.h>

static inline BOOL HaptixCanPresent(UIViewController *controller) {
    UIWindow *window = controller.viewIfLoaded.window;
    UINavigationController *navigation = controller.navigationController;
    if (!window || window.hidden || controller.presentedViewController
        || controller.isBeingDismissed || controller.isMovingFromParentViewController
        || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return NO;
    if (navigation && (navigation.topViewController != controller
        || navigation.presentedViewController || navigation.isBeingDismissed)) return NO;
    UIWindowScene *scene = window.windowScene;
    return !scene || scene.activationState == UISceneActivationStateForegroundActive;
}
