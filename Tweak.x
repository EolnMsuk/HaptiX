#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// Preference variables
static BOOL enabled = YES;
static NSInteger feedbackStyle = 1; 
static BOOL hookKeyboard = YES;
static BOOL hookButtons = YES;
static BOOL hookScrolling = NO;

// Cooldown to prevent "double vibration" stuttering
static NSTimeInterval lastHapticTime = 0;

static void loadPrefs() {
    // Standard Rootless path. The RootHide Patcher will automatically translate this!
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.eolnmsuk.haptix.plist"];
    
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
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - lastHapticTime < 0.05) return; 
    lastHapticTime = currentTime;
    
    UIImpactFeedbackStyle style = UIImpactFeedbackStyleMedium;
    switch (feedbackStyle) {
        case 0: style = UIImpactFeedbackStyleLight; break;
        case 1: style = UIImpactFeedbackStyleMedium; break;
        case 2: style = UIImpactFeedbackStyleHeavy; break;
        case 3: style = UIImpactFeedbackStyleSoft; break;   
        case 4: style = UIImpactFeedbackStyleRigid; break;  
    }
    
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [generator prepare];
    [generator impactOccurred];
}

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

%hook UIControl
- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    %orig;
    if (hookButtons) triggerHaptic();
}
%end

%hook UIScrollView
- (void)_scrollViewDidEndDecelerating {
    %orig;
    if (hookScrolling) triggerHaptic();
}
%end

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
