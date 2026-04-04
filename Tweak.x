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

// Generator caching to prevent delay/memory leaks
static UIImpactFeedbackGenerator *hapticGenerator = nil;
static NSInteger currentLoadedStyle = -1;

// --- Load Preferences ---
static void loadPrefs() {
    // NSUserDefaults initWithSuiteName safely bypasses app sandboxes!
    NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.eolnmsuk.haptix"];
    
    if (prefs) {
        enabled = [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES;
        globalStyle = [prefs objectForKey:@"globalStyle"] ? [[prefs objectForKey:@"globalStyle"] integerValue] : 1;
        boostMode = [prefs objectForKey:@"boostMode"] ? [[prefs objectForKey:@"boostMode"] boolValue] : NO;
        
        hookKeyboard = [prefs objectForKey:@"hookKeyboard"] ? [[prefs objectForKey:@"hookKeyboard"] boolValue] : YES;
        hookButtons = [prefs objectForKey:@"hookButtons"] ? [[prefs objectForKey:@"hookButtons"] boolValue] : YES;
        hookSwitches = [prefs objectForKey:@"hookSwitches"] ? [[prefs objectForKey:@"hookSwitches"] boolValue] : YES;
        hookCells = [prefs objectForKey:@"hookCells"] ? [[prefs objectForKey:@"hookCells"] boolValue] : YES;
        hookScrolling = [prefs objectForKey:@"hookScrolling"] ? [[prefs objectForKey:@"hookScrolling"] boolValue] : NO;
        
        hookVolume = [prefs objectForKey:@"hookVolume"] ? [[prefs objectForKey:@"hookVolume"] boolValue] : YES;
        hookPower = [prefs objectForKey:@"hookPower"] ? [[prefs objectForKey:@"hookPower"] boolValue] : YES;
        hookIcons = [prefs objectForKey:@"hookIcons"] ? [[prefs objectForKey:@"hookIcons"] boolValue] : YES;
        hookLockScreen = [prefs objectForKey:@"hookLockScreen"] ? [[prefs objectForKey:@"hookLockScreen"] boolValue] : YES;
        hookAppSwitcher = [prefs objectForKey:@"hookAppSwitcher"] ? [[prefs objectForKey:@"hookAppSwitcher"] boolValue] : YES;
        
        // AltList check
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleID) {
            isBlacklisted = [[prefs objectForKey:bundleID] boolValue];
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
        AudioServicesPlaySystemSound(boostMode ? 1521 : 1520);
        return;
    }
    
    // Force UIImpactFeedbackGenerator onto the main thread to prevent silent drops
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackStyle style = UIImpactFeedbackStyleMedium;
        switch (globalStyle) {
            case 0: style = UIImpactFeedbackStyleSoft; break;
            case 1: style = UIImpactFeedbackStyleMedium; break;
            case 2: style = UIImpactFeedbackStyleHeavy; break;
        }
        
        // Cache the generator to eliminate startup latency, update only if user changed settings
        if (!hapticGenerator || currentLoadedStyle != globalStyle) {
            hapticGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
            currentLoadedStyle = globalStyle;
        }
        
        [hapticGenerator prepare];
        [hapticGenerator impactOccurred];
    });
}

// ==========================================
// GROUP: UIKit (System-Wide Apps)
// ==========================================
%group UIKitHooks

%hook UIKeyboardImpl
// Hooks the actual sound generation of the keyboard, capturing 100% of physical/virtual taps
- (void)playKeyClickSound {
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
