#import <UIKit/UIKit.h>

// --- Preferences Variables ---
static BOOL enabled = NO; 

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
static NSInteger hapticStyle = 0; // 0=Light 1=Medium 2=Heavy 3=Soft 4=Rigid

// Helper function to safely read prefs via cfprefsd (Bypasses ALL sandboxes, including Native Apple Apps)
static NSInteger readIntegerPref(NSString *key, NSInteger fallback) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR("com.eolnmsuk.haptix"));
    if (value) {
        NSInteger result = [(__bridge NSNumber *)value integerValue];
        CFRelease(value);
        return result;
    }
    return fallback;
}

static BOOL readBoolPref(NSString *key, BOOL fallback) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, CFSTR("com.eolnmsuk.haptix"));
    if (value) {
        // CORRECTED LINE: Cast directly to NSNumber using __bridge
        BOOL result = [(__bridge NSNumber *)value boolValue];
        CFRelease(value);
        return result;
    }
    return fallback;
}

// --- Load Preferences ---
static void loadPrefs() {
    enabled = readBoolPref(@"enabled", NO);
    
    hookKeyboard = readBoolPref(@"hookKeyboard", YES);
    hookButtons = readBoolPref(@"hookButtons", YES);
    hookSwitches = readBoolPref(@"hookSwitches", YES);
    hookCells = readBoolPref(@"hookCells", YES);
    hookScrolling = readBoolPref(@"hookScrolling", NO);
    
    hookVolume = readBoolPref(@"hookVolume", YES);
    hookPower = readBoolPref(@"hookPower", YES);
    hookIcons = readBoolPref(@"hookIcons", YES);
    hookLockScreen = readBoolPref(@"hookLockScreen", YES);
    hookAppSwitcher = readBoolPref(@"hookAppSwitcher", YES);
    
    hapticStyle = readIntegerPref(@"hapticStyle", 0);

    // AltList storage model: top-level booleans keyed by bundle ID (not nested under "blacklistedApps").
    // The PSLinkListCell `key` field is a specifier identifier only; AltList writes each app directly
    // into the preferences domain, so readBoolPref(bundleID) is the correct lookup.
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleID) {
        isBlacklisted = readBoolPref(bundleID, NO);
    }
}

// --- Haptic Engine (UIImpactFeedbackGenerator) ---
static void triggerHaptic() {
    if (!enabled || isBlacklisted) return;

    // 50ms cooldown eliminates the "tick tick" double-fire glitch
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - lastHapticTime < 0.05) return;
    lastHapticTime = currentTime;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackStyle style;
        switch (hapticStyle) {
            case 1:  style = UIImpactFeedbackStyleMedium; break;
            case 2:  style = UIImpactFeedbackStyleHeavy;  break;
            case 3:  style = UIImpactFeedbackStyleSoft;   break;
            case 4:  style = UIImpactFeedbackStyleRigid;  break;
            default: style = UIImpactFeedbackStyleLight;  break;
        }
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
        [gen prepare];
        [gen impactOccurred];
    });
}

// ==========================================
// GROUP: UIKit (System-Wide Apps)
// ==========================================
%group UIKitHooks

%hook UIKeyboardImpl
- (void)playKeyClickSound {
    %orig;
    if (hookKeyboard) triggerHaptic();
}
- (void)autoDelete {
    %orig;
    if (hookKeyboard) triggerHaptic();
}
%end

%hook UIControl
- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    %orig;
    if (hookButtons) {
        UITouch *touch = [[event allTouches] anyObject];
        // Only trigger if it's a "Touch Up" event or a programmatic trigger, preventing double ticks
        if (!touch || touch.phase == UITouchPhaseEnded) {
            triggerHaptic();
        }
    }
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
- (void)setContentOffset:(CGPoint)arg1 {
    if (hookScrolling && !isBlacklisted && enabled && self.isDragging) {
        CGFloat topBound = -self.adjustedContentInset.top;
        CGFloat bottomBound = self.contentSize.height - self.bounds.size.height + self.adjustedContentInset.bottom;
        
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

%hook SBVolumeControl
- (void)increaseVolume { %orig; if (hookVolume) triggerHaptic(); }
- (void)decreaseVolume { %orig; if (hookVolume) triggerHaptic(); }
%end

%hook SBLockHardwareButton
- (void)singlePress { %orig; if (hookPower) triggerHaptic(); }
%end

%hook SBLockScreenManager
- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { %orig; if (hookLockScreen) triggerHaptic(); }
%end

%hook SBIconView
- (void)setHighlighted:(BOOL)highlighted { %orig; if (hookIcons && highlighted) triggerHaptic(); }
%end

%hook SBHomeGesturePanGestureRecognizer
- (void)setState:(long long)state {
    %orig;
    if (state == 1 && hookAppSwitcher) triggerHaptic();
}
%end

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
