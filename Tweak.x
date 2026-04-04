#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#define PLIST_PATH @"/var/jb/var/mobile/Library/Preferences/com.eolnmsuk.haptix.plist"

// --- Preferences Variables ---
static BOOL enabled = NO; // DEFAULT OFF PER REQUEST
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
    // Reading directly from the rootless path. 
    // Rootless sandbox explicitly allows this, whereas NSUserDefaults blocked 3rd party apps!
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
    
    if (prefs) {
        enabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : NO; 
        globalStyle = prefs[@"globalStyle"] ? [prefs[@"globalStyle"] integerValue] : 1;
        boostMode = prefs[@"boostMode"] ? [prefs[@"boostMode"] boolValue] : NO;
        
        hookKeyboard = prefs[@"hookKeyboard"] ? [prefs[@"hookKeyboard"] boolValue] : YES;
        hookButtons = prefs[@"hookButtons"] ? [prefs[@"hookButtons"] boolValue] : YES;
        hookSwitches = prefs[@"hookSwitches"] ? [prefs[@"hookSwitches"] boolValue] : YES;
        hookCells = prefs[@"hookCells"] ? [prefs[@"hookCells"] boolValue] : YES;
        hookScrolling = prefs[@"hookScrolling"] ? [prefs[@"hookScrolling"] boolValue] : NO;
        
        hookVolume = prefs[@"hookVolume"] ? [prefs[@"hookVolume"] boolValue] : YES;
        hookPower = prefs[@"hookPower"] ? [prefs[@"hookPower"] boolValue] : YES;
        hookIcons = prefs[@"hookIcons"] ? [prefs[@"hookIcons"] boolValue] : YES;
        hookLockScreen = prefs[@"hookLockScreen"] ? [prefs[@"hookLockScreen"] boolValue] : YES;
        hookAppSwitcher = prefs[@"hookAppSwitcher"] ? [prefs[@"hookAppSwitcher"] boolValue] : YES;
        
        // AltList check
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleID) {
            isBlacklisted = prefs[bundleID] ? [prefs[bundleID] boolValue] : NO;
        }
    } else {
        // Safe defaults if file is completely wiped
        enabled = NO; 
        globalStyle = 1;
        boostMode = NO;
        isBlacklisted = NO;
    }
}

// --- Haptic Engine ---
static void triggerHaptic() {
    if (!enabled || isBlacklisted) return;
    
    // Cooldown to prevent stuttering
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - lastHapticTime < 0.04) return; 
    lastHapticTime = currentTime;
    
    // Must run on main thread so 3rd party apps don't drop the vibration
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (boostMode) {
            // Overdrive (1521 is a heavy multi-pulse hardware vibration)
            AudioServicesPlaySystemSound(1521); 
            return;
        }
        
        if (globalStyle == 3) {
            // RIGID PROFILE: Bypasses standard generator for instant hardware 'Pop' (1520)
            AudioServicesPlaySystemSound(1520);
            return;
        }
        
        // ALL standard profiles now use the 'Rigid' style for a sharp, clicky feel, 
        // we just scale the physical intensity of it.
        CGFloat intensity = 0.5;
        if (globalStyle == 0) intensity = 0.4;      // Soft
        else if (globalStyle == 1) intensity = 0.7; // Med
        else if (globalStyle == 2) intensity = 1.0; // Hard
        
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
        [generator prepare];
        [generator impactOccurredWithIntensity:intensity];
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
