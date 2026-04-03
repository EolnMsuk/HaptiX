#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <rootless.h> // REQUIRED to find dynamic RootHide paths!

// Preference variables
static BOOL enabled = YES;
static NSInteger feedbackStyle = 1; 
static BOOL hookKeyboard = YES;
static BOOL hookButtons = YES;
static BOOL hookScrolling = NO;

// Cooldown to prevent "double vibration" stuttering
static NSTimeInterval lastHapticTime = 0;

static void loadPrefs() {
    // Dynamically resolves the path regardless of RootHide randomizations
    NSDictionary *prefs = [[NSDicNSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:ROOT_PATH_NS(@"/var/mobile/Library/Preferences/com.eolnmsuk.haptix.plist")];tionary alloc] initWithContentsOfFile:ROOT_PATH_NS("/var/mobile/Library/Preferences/com.eolnmsuk.haptix.plist")];
    
    if (prefs) {
        enabled = [prefs[@"enabled"] boolValue];
        feedbackStyle = [prefs[@"feedbackStyle"] integerValue];
        hookKeyboard = [prefs[@"hookKeyboard"] ? prefs[@"hookKeyboard"] : @YES boolValue];
        hookButtons = [prefs[@"hookButtons"] ? prefs[@"hookButtons"] : @YES boolValue];
        hookScrolling = [prefs[@"hookScrolling"] ? prefs[@"hookScrolling"] : @NO boolValue];
    }
}

static void triggerHaptic() {
    if (!enabled) return;
    
    // 50ms time gate: prevents the Taptic Engine from rattling if two events fire simultaneously
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - lastHapticTime < 0.05) return; 
    lastHapticTime = currentTime;
    
    UIImpactFeedbackStyle style = UIImpactFeedbackStyleMedium;
    switch (feedbackStyle) {
        case 0: style = UIImpactFeedbackStyleLight; break;
        case 1: style = UIImpactFeedbackStyleMedium; break;
        case 2: style = UIImpactFeedbackStyleHeavy; break;
        case 3: style = UIImpactFeedbackStyleSoft; break;   // Great for subtle UI shifts
        case 4: style = UIImpactFeedbackStyleRigid; break;  // Great for mechanical keyboard feels
    }
    
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [generator prepare];
    [generator impactOccurred];
}

// 1. Keyboard Injection
%hook UIKeyboardImpl
- (void)insertText:(id)arg1 {
    %orig;
    if (hookKeyboard) triggerHaptic();
}
- (void)deleteBackward {
    %orig;
    if (hookKeyboard) triggerHaptic();
}
%end

// 2. Button Injection
%hook UIControl
- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    %orig;
    if (hookButtons) triggerHaptic();
}
%end

// 3. Scrolling Injection (Fires slightly when momentum stops)
%hook UIScrollView
- (void)_scrollViewDidEndDecelerating {
    %orig;
    if (hookScrolling) triggerHaptic();
}
%end

// Initialization & Preference listener
%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), 
        NULL, 
        (CFNotificationCallback)loadPrefs, 
        CFSTR("com.eolnmsuk.haptix/ReloadPrefs"), 
        NULL, 
        CFNotificationSuspensionBehaviorCoalesce
    );
}
