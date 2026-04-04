#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// --- Preferences Variables ---
static BOOL enabled = YES;
static NSInteger globalStyle = 1; 
static BOOL boostMode = NO;
static NSString *blacklistedApps = @"";

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
        blacklistedApps = prefs[@"blacklistedApps"] ?: @"";
        
        hookKeyboard = [prefs[@"hookKeyboard"] ?: @YES boolValue];
        hookButtons = [prefs[@"hookButtons"] ?: @YES boolValue];
        hookSwitches = [prefs[@"hookSwitches"] ?: @YES boolValue];
        hookCells = [prefs[@"hookCells"] ?: @YES boolValue];
        hookScrolling = [prefs[@"hookScrolling"] ?: @NO boolValue];
        
        hookVolume = [prefs[@"hookVolume"] ?: @YES boolValue];
        hookPower = [prefs[@"hookPower"] ?: @YES boolValue];
        hookIcons = [prefs[@"hookIcons"] ?: @YES boolValue];
        hookLockScreen = [prefs[@"hookLockScreen"] ?: @YES boolValue];
    }
    
    // Check if current app is blacklisted
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleID) {
        NSArray *bList = [blacklistedApps componentsSeparatedByString:@","];
        isBlacklisted = [bList containsObject:bundleID];
    }
}

// --- Haptic Engine ---
static void triggerHaptic() {
    if (!enabled || isBlacklisted) return;
    
    // Cooldown to prevent stuttering
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - lastHapticTime < 0.04) return; 
    lastHapticTime = currentTime;
    
    if (boostMode) {
        // OVERDRIVE: Bypasses UIImpactFeedbackGenerator for raw system vibration
        AudioServicesPlaySystemSound(1520); // 1520 = Strong Pop, 1521 = 3 Pulse
        return;
    }
    
    UIImpactFeedbackStyle style = UIImpactFeedbackStyleMedium;
    switch (globalStyle) {
        case 0: style = UIImpactFeedbackStyleLight; break;
        case 1: style = UIImpactFeedbackStyleMedium; break;
        case 2: style = UIImpactFeedbackStyleHeavy; break;
        case 3: style = UIImpactFeedbackStyleSoft; break;
        case 4: style = UIImpactFeedbackStyleRigid; break;  
    }
    
    if (@available(iOS 13.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
        [generator prepare];
        [generator impactOccurredWithIntensity:1.0]; // Max standard intensity
    } else {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
        [generator prepare];
        [generator impactOccurred];
    }
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

%hook UICollectionViewCell
- (void)setSelected:(BOOL)selected {
    %orig;
    if (hookCells && selected) triggerHaptic();
}
%end

%hook UIScrollView
- (void)_scrollViewDidEndDecelerating {
    %orig;
    if (hookScrolling) triggerHaptic();
}
%end

%end // UIKitHooks

// ==========================================
// GROUP: SpringBoard (Homescreen/Hardware)
// ==========================================
%group SpringBoardHooks

// Hardware Volume Buttons
%hook SBVolumeControl
- (void)increaseVolume {
    %orig;
    if (hookVolume) triggerHaptic();
}
- (void)decreaseVolume {
    %orig;
    if (hookVolume) triggerHaptic();
}
%end

// Hardware Power Button
%hook SBLockHardwareButton
- (void)singlePress {
    %orig;
    if (hookPower) triggerHaptic();
}
%end

// Lock/Unlock events
%hook SBLockScreenManager
- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 {
    %orig;
    if (hookLockScreen) triggerHaptic();
}
%end

// Homescreen Icons
%hook SBIconView
- (void)setHighlighted:(BOOL)highlighted {
    %orig;
    if (hookIcons && highlighted) triggerHaptic();
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
    
    // Only init SpringBoard hooks if we are actually inside SpringBoard
    if ([bundleId isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoardHooks);
    }
}
