#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// --- Preferences Variables ---
static BOOL enabled = YES;
static NSInteger globalStyle = 1; 
static BOOL boostMode = NO;

// UIKit Triggers
static BOOL hookKeyboard = YES;
static BOOL hookButtons = YES;
static BOOL hookSwitches = YES;
static BOOL hookCells = YES;
static BOOL hookScrolling = NO;

// SpringBoard Triggers
static BOOL hookVolume = YES;
static BOOL hookPower = YES;
static BOOL hookIcons = YES;
static BOOL hookLockScreen = YES;
static BOOL hookAppSwitcher = YES;

// State management
static NSTimeInterval lastHapticTime = 0;
static BOOL isBlacklisted = NO;

// --- Load Preferences ---
static void loadPrefs() {
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.eolnmsuk.haptix.plist"];
    
    if (prefs) {
        enabled = [prefs[@"enabled"] ?: @YES boolValue];
        globalStyle = [prefs[@"globalStyle"] ?: @1 integerValue];
        boostMode = [prefs[@"boostMode"] ?: @NO boolValue];
        
        hookKeyboard = [prefs[@"hookKeyboard"] ?: @YES boolValue];
        hookButtons = [prefs[@"hookButtons"] ?: @YES boolValue];
        hookSwitches = [prefs[@"hookSwitches"] ?: @YES boolValue];
        hookCells = [prefs[@"hookCells"] ?: @YES boolValue];
        hookScrolling = [prefs[@"hookScrolling"] ?: @NO boolValue];
        
        hookVolume = [prefs[@"hookVolume"] ?: @YES boolValue];
        hookPower = [prefs[@"hookPower"] ?: @YES boolValue];
        hookIcons = [prefs[@"hookIcons"] ?: @YES boolValue];
        hookLockScreen = [prefs[@"hookLockScreen"] ?: @YES boolValue];
        hookAppSwitcher = [prefs[@"hookAppSwitcher"] ?: @YES boolValue];
        
        // AltList saves the bundle ID as a boolean key directly in the plist
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleID) {
            isBlacklisted = [prefs[bundleID] boolValue];
        }
    }
}

// --- Haptic Engine ---
static void triggerHaptic() {
    if (!enabled || isBlacklisted) return;
    
    // Cooldown to prevent stuttering
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - lastHapticTime < 0.04) return; 
    lastHapticTime = currentTime;
    
    // OVERDRIVE or RIGID bypass standard generation for instant hardware snap
    if (boostMode || globalStyle == 3) {
        AudioServicesPlaySystemSound(boostMode ? 1521 : 1520); // 1520 = Pop (Rigid), 1521 = Vibrate (Overdrive)
        return;
    }
    
    UIImpactFeedbackStyle style = UIImpactFeedbackStyleMedium;
    switch (globalStyle) {
        case 0: style = UIImpactFeedbackStyleSoft; break;
        case 1: style = UIImpactFeedbackStyleMedium; break;
        case 2: style = UIImpactFeedbackStyleHeavy; break;
    }
    
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
    [generator prepare];
    [generator impactOccurred];
}

// ==========================================
// GROUP: UIKit (System-Wide Apps)
// ==========================================
%group UIKitHooks

%hook UIKeyboardImpl
- (void)insertText:(id)arg1 {
    %orig;
    if (hookKeyboard) triggerHaptic();
}
- (void)deleteBackward {
    %orig;
    if (hookKeyboard) triggerHaptic();
}
// Catches the continuous hold-to-delete action
- (void)autoDelete {
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

%hook UISwitch
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    %orig;
    if (hookSwitches) triggerHaptic();
}
%end

%hook UITableViewCell
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    %orig;
    if (hookCells && selected) triggerHaptic();
}
%end

%hook UIScrollView
// Hooking setContentOffset catches the exact frame it hits the boundary
- (void)setContentOffset:(CGPoint)arg1 {
    if (hookScrolling && !isBlacklisted && enabled && self.isDragging) {
        CGFloat topBound = -self.adjustedContentInset.top;
        CGFloat bottomBound = self.contentSize.height - self.bounds.size.height + self.adjustedContentInset.bottom;
        
        // Calculate if we were inside bounds on the last frame, but are out of bounds on this frame
        BOOL wasInBoundsY = (self.contentOffset.y > topBound && self.contentOffset.y < bottomBound);
        BOOL isOutOfBoundsY = (arg1.y <= topBound || arg1.y >= bottomBound);
        
        if (wasInBoundsY && isOutOfBoundsY) {
            triggerHaptic();
        }
    }
    %orig;
}
%end

%end // UIKitHooks

// ==========================================
// GROUP: SpringBoard (Homescreen/Hardware)
// ==========================================
%group SpringBoardHooks

// Hardware Volume Buttons
%hook SBVolumeControl
- (void)increaseVolume { %orig; if (hookVolume) triggerHaptic(); }
- (void)decreaseVolume { %orig; if (hookVolume) triggerHaptic(); }
%end

// Hardware Power Button
%hook SBLockHardwareButton
- (void)singlePress { %orig; if (hookPower) triggerHaptic(); }
%end

// Lock/Unlock events
%hook SBLockScreenManager
- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { %orig; if (hookLockScreen) triggerHaptic(); }
%end

// Homescreen Icons
%hook SBIconView
- (void)setHighlighted:(BOOL)highlighted { %orig; if (hookIcons && highlighted) triggerHaptic(); }
%end

// Start of Home/App Switcher Swipe
%hook SBHomeGesturePanGestureRecognizer
- (void)setState:(long long)state {
    %orig;
    if (state == 1 /* UIGestureRecognizerStateBegan */ && hookAppSwitcher) {
        triggerHaptic();
    }
}
%end

// App Switcher internal actions (Closing apps, swiping to other apps)
%hook SBFluidSwitcherViewController
- (void)layoutStateTransitionCoordinator:(id)arg1 transitionDidBeginWithTransitionContext:(id)arg2 {
    %orig;
    if (hookAppSwitcher) triggerHaptic();
}
%end

%end // SpringBoardHooks

// ==========================================
// CONSTRUCTOR
// ==========================================
%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.eolnmsuk.haptix/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    %init(UIKitHooks);
    
    if ([bundleId isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoardHooks);
    }
}
