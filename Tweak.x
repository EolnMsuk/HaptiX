#import <UIKit/UIKit.h>

// --- Preferences Variables ---
static BOOL enabled = NO;

// UIKit Triggers
static BOOL hookKeyboard  = YES;
static BOOL hookButtons   = YES;
static BOOL hookSwitches  = YES;
static BOOL hookCells     = YES;
static BOOL hookScrolling = NO;
static BOOL hookCallout   = YES;
static BOOL hookAlerts    = NO;

// Hardware & System Triggers (SpringBoard)
static BOOL hookVolume       = YES;
static BOOL hookPower        = YES;
static BOOL hookLockScreen   = YES;
static BOOL hookIcons        = YES;
static BOOL hookAppSwitcher  = YES;
static BOOL hookScreenshot   = NO;
static BOOL hookDisplayWake  = YES;
static BOOL hookCharger      = NO;
static BOOL hookRinger       = YES;
static BOOL hookReachability = YES;

// System UI Triggers (SpringBoard)
static BOOL hookFolders       = YES;
static BOOL hookSpotlight     = YES;
static BOOL hookSiri          = YES;
static BOOL hookControlCenter = YES;
static BOOL hookCCToggles     = YES;
static BOOL hookPowerDown     = YES;
static BOOL hookBiometric     = YES;
static BOOL hookHomeBar       = YES;
static BOOL hookPasscode      = YES;
static BOOL hookAppKill       = NO;
static BOOL hookCallStatus    = YES;
static BOOL hookLockSound     = NO;
static BOOL hookRespring      = NO;

// State management
static NSTimeInterval lastHapticTime = 0;
static BOOL isBlacklisted = NO;
static NSInteger hapticStyle = 4; // 0=Light 1=Medium 2=Heavy 3=Soft 4=Rigid

// Per-trigger style overrides; 0 = use global hapticStyle
// UIKit
static NSInteger style_hookKeyboard  = 0;
static NSInteger style_hookButtons   = 0;
static NSInteger style_hookSwitches  = 0;
static NSInteger style_hookCells     = 0;
static NSInteger style_hookScrolling = 0;
static NSInteger style_hookCallout   = 0;
static NSInteger style_hookAlerts    = 0;
// Hardware & System
static NSInteger style_hookVolume       = 0;
static NSInteger style_hookPower        = 0;
static NSInteger style_hookLockScreen   = 0;
static NSInteger style_hookIcons        = 0;
static NSInteger style_hookAppSwitcher  = 0;
static NSInteger style_hookScreenshot   = 0;
static NSInteger style_hookDisplayWake  = 0;
static NSInteger style_hookCharger      = 0;
static NSInteger style_hookRinger       = 0;
static NSInteger style_hookReachability = 0;
// System UI
static NSInteger style_hookFolders       = 0;
static NSInteger style_hookSpotlight     = 0;
static NSInteger style_hookSiri          = 0;
static NSInteger style_hookControlCenter = 0;
static NSInteger style_hookCCToggles     = 0;
static NSInteger style_hookPowerDown     = 0;
static NSInteger style_hookBiometric     = 0;
static NSInteger style_hookHomeBar       = 0;
static NSInteger style_hookPasscode      = 0;
static NSInteger style_hookAppKill       = 0;
static NSInteger style_hookCallStatus    = 0;
static NSInteger style_hookLockSound     = 0;
static NSInteger style_hookRespring      = 0;

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
        BOOL result = [(__bridge NSNumber *)value boolValue];
        CFRelease(value);
        return result;
    }
    return fallback;
}

// --- Load Preferences ---
static void loadPrefs() {
    enabled = readBoolPref(@"enabled", NO);

    // UIKit
    hookKeyboard  = readBoolPref(@"hookKeyboard",  YES);
    hookButtons   = readBoolPref(@"hookButtons",   YES);
    hookSwitches  = readBoolPref(@"hookSwitches",  YES);
    hookCells     = readBoolPref(@"hookCells",     YES);
    hookScrolling = readBoolPref(@"hookScrolling", NO);
    hookCallout   = readBoolPref(@"hookCallout",   YES);
    hookAlerts    = readBoolPref(@"hookAlerts",    NO);

    // Hardware & System
    hookVolume       = readBoolPref(@"hookVolume",       YES);
    hookPower        = readBoolPref(@"hookPower",        YES);
    hookLockScreen   = readBoolPref(@"hookLockScreen",   YES);
    hookIcons        = readBoolPref(@"hookIcons",        YES);
    hookAppSwitcher  = readBoolPref(@"hookAppSwitcher",  YES);
    hookScreenshot   = readBoolPref(@"hookScreenshot",   NO);
    hookDisplayWake  = readBoolPref(@"hookDisplayWake",  YES);
    hookCharger      = readBoolPref(@"hookCharger",      NO);
    hookRinger       = readBoolPref(@"hookRinger",       YES);
    hookReachability = readBoolPref(@"hookReachability", YES);

    // System UI
    hookFolders       = readBoolPref(@"hookFolders",       YES);
    hookSpotlight     = readBoolPref(@"hookSpotlight",     YES);
    hookSiri          = readBoolPref(@"hookSiri",          YES);
    hookControlCenter = readBoolPref(@"hookControlCenter", YES);
    hookCCToggles     = readBoolPref(@"hookCCToggles",     YES);
    hookPowerDown     = readBoolPref(@"hookPowerDown",     YES);
    hookBiometric     = readBoolPref(@"hookBiometric",     YES);
    hookHomeBar       = readBoolPref(@"hookHomeBar",       YES);
    hookPasscode      = readBoolPref(@"hookPasscode",      YES);
    hookAppKill       = readBoolPref(@"hookAppKill",       NO);
    hookCallStatus    = readBoolPref(@"hookCallStatus",    YES);
    hookLockSound     = readBoolPref(@"hookLockSound",     NO);
    hookRespring      = readBoolPref(@"hookRespring",      NO);

    hapticStyle = readIntegerPref(@"hapticStyle", 0);

    // Per-trigger style overrides — UIKit
    style_hookKeyboard  = readIntegerPref(@"style_hookKeyboard",  0);
    style_hookButtons   = readIntegerPref(@"style_hookButtons",   0);
    style_hookSwitches  = readIntegerPref(@"style_hookSwitches",  0);
    style_hookCells     = readIntegerPref(@"style_hookCells",     0);
    style_hookScrolling = readIntegerPref(@"style_hookScrolling", 0);
    style_hookCallout   = readIntegerPref(@"style_hookCallout",   0);
    style_hookAlerts    = readIntegerPref(@"style_hookAlerts",    0);

    // Per-trigger style overrides — Hardware & System
    style_hookVolume       = readIntegerPref(@"style_hookVolume",       0);
    style_hookPower        = readIntegerPref(@"style_hookPower",        0);
    style_hookLockScreen   = readIntegerPref(@"style_hookLockScreen",   0);
    style_hookIcons        = readIntegerPref(@"style_hookIcons",        0);
    style_hookAppSwitcher  = readIntegerPref(@"style_hookAppSwitcher",  0);
    style_hookScreenshot   = readIntegerPref(@"style_hookScreenshot",   0);
    style_hookDisplayWake  = readIntegerPref(@"style_hookDisplayWake",  0);
    style_hookCharger      = readIntegerPref(@"style_hookCharger",      0);
    style_hookRinger       = readIntegerPref(@"style_hookRinger",       0);
    style_hookReachability = readIntegerPref(@"style_hookReachability", 0);

    // Per-trigger style overrides — System UI
    style_hookFolders       = readIntegerPref(@"style_hookFolders",       0);
    style_hookSpotlight     = readIntegerPref(@"style_hookSpotlight",     0);
    style_hookSiri          = readIntegerPref(@"style_hookSiri",          0);
    style_hookControlCenter = readIntegerPref(@"style_hookControlCenter", 0);
    style_hookCCToggles     = readIntegerPref(@"style_hookCCToggles",     0);
    style_hookPowerDown     = readIntegerPref(@"style_hookPowerDown",     0);
    style_hookBiometric     = readIntegerPref(@"style_hookBiometric",     0);
    style_hookHomeBar       = readIntegerPref(@"style_hookHomeBar",       0);
    style_hookPasscode      = readIntegerPref(@"style_hookPasscode",      0);
    style_hookAppKill       = readIntegerPref(@"style_hookAppKill",       0);
    style_hookCallStatus    = readIntegerPref(@"style_hookCallStatus",    0);
    style_hookLockSound     = readIntegerPref(@"style_hookLockSound",     0);
    style_hookRespring      = readIntegerPref(@"style_hookRespring",      0);

    // AltList storage model: top-level booleans keyed by bundle ID (not nested under "blacklistedApps").
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleID) {
        isBlacklisted = readBoolPref(bundleID, NO);
    }
}

// --- Haptic Engine (UIImpactFeedbackGenerator) ---
static void triggerHapticWithOverride(NSInteger overrideStyle) {
    if (!enabled || isBlacklisted) return;

    // 50ms cooldown eliminates double-fire from rapid sequential events
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime - lastHapticTime < 0.05) return;
    lastHapticTime = currentTime;

    // 0 = use global; 1–5 = per-trigger override (shifted by 1 to match UIImpactFeedbackStyle)
    NSInteger effectiveStyle = (overrideStyle > 0) ? (overrideStyle - 1) : hapticStyle;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackStyle style;
        switch (effectiveStyle) {
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
    if (hookKeyboard) triggerHapticWithOverride(style_hookKeyboard);
}
- (void)autoDelete {
    %orig;
    if (hookKeyboard) triggerHapticWithOverride(style_hookKeyboard);
}
%end

%hook UIControl
- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    %orig;
    if (hookButtons) {
        UITouch *touch = [[event allTouches] anyObject];
        // Only trigger on Touch Up or programmatic (no touch), preventing double ticks
        if (!touch || touch.phase == UITouchPhaseEnded) {
            triggerHapticWithOverride(style_hookButtons);
        }
    }
}
%end

%hook UISwitch
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    %orig;
    if (hookSwitches) triggerHapticWithOverride(style_hookSwitches);
}
%end

%hook UITableViewCell
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    %orig;
    if (hookCells && selected) triggerHapticWithOverride(style_hookCells);
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
            triggerHapticWithOverride(style_hookScrolling);
        }
    }
    %orig;
}
%end

// Text selection callout (Cut / Copy / Paste / etc.)
%hook UICalloutBar
- (void)buttonPressed:(id)sender {
    %orig;
    if (hookCallout) triggerHapticWithOverride(style_hookCallout);
}
%end

// UIAlertController appearance (action sheets and alerts)
%hook UIAlertController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (hookAlerts) triggerHapticWithOverride(style_hookAlerts);
}
%end

%end // UIKitHooks

// ==========================================
// GROUP: SpringBoard (Homescreen/Hardware/System UI)
// ==========================================
%group SpringBoardHooks

// --- Hardware & System (existing) ---

%hook SBVolumeControl
- (void)increaseVolume { %orig; if (hookVolume) triggerHapticWithOverride(style_hookVolume); }
- (void)decreaseVolume { %orig; if (hookVolume) triggerHapticWithOverride(style_hookVolume); }
%end

%hook SBLockHardwareButton
- (void)singlePress { %orig; if (hookPower) triggerHapticWithOverride(style_hookPower); }
%end

%hook SBLockScreenManager
- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 {
    %orig;
    if (hookLockScreen) triggerHapticWithOverride(style_hookLockScreen);
}
%end

%hook SBIconView
- (void)setHighlighted:(BOOL)highlighted {
    %orig;
    if (hookIcons && highlighted) triggerHapticWithOverride(style_hookIcons);
}
%end

%hook SBHomeGesturePanGestureRecognizer
- (void)setState:(long long)state {
    %orig;
    if (state == 1 && hookAppSwitcher) triggerHapticWithOverride(style_hookAppSwitcher);
}
%end

%hook SBFluidSwitcherViewController
- (void)layoutStateTransitionCoordinator:(id)arg1 transitionDidBeginWithTransitionContext:(id)arg2 {
    %orig;
    if (hookAppSwitcher) triggerHapticWithOverride(style_hookAppSwitcher);
}
%end

// --- Hardware & System (new) ---

// Screenshot capture
%hook SSScreenCapturer
- (void)captureScreenshot {
    %orig;
    if (hookScreenshot) triggerHapticWithOverride(style_hookScreenshot);
}
%end

// Display wake (screen turns on)
%hook SBBacklightController
- (void)turnOnScreenFullyWithBacklightSource:(int)arg1 {
    %orig;
    if (hookDisplayWake) triggerHapticWithOverride(style_hookDisplayWake);
}
%end

// Reachability gesture and charger connect/disconnect share SBUIController
%hook SBUIController
- (void)handleWillBeginReachabilityAnimation {
    %orig;
    if (hookReachability) triggerHapticWithOverride(style_hookReachability);
}
- (void)ACPowerChanged {
    %orig;
    if (hookCharger) triggerHapticWithOverride(style_hookCharger);
}
%end

// Ringer toggle and respring share SpringBoard class
%hook SpringBoard
- (void)_ringerChanged {
    %orig;
    if (hookRinger) triggerHapticWithOverride(style_hookRinger);
}
// Fires once at SpringBoard launch — used to haptic-confirm a respring completed
- (void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    if (hookRespring) triggerHapticWithOverride(style_hookRespring);
}
%end

// --- System UI (new) ---

// Folder open and close
%hook SBFolderController
- (void)openFolder {
    %orig;
    if (hookFolders) triggerHapticWithOverride(style_hookFolders);
}
- (void)closeFolder {
    %orig;
    if (hookFolders) triggerHapticWithOverride(style_hookFolders);
}
%end

// Spotlight / Search reveal
%hook SBSearchScrollView
- (void)setSearchVisible:(BOOL)visible animated:(BOOL)animated {
    %orig;
    if (visible && hookSpotlight) triggerHapticWithOverride(style_hookSpotlight);
}
%end

// Siri activation overlay
%hook SiriUISiriStatusView
- (void)didMoveToWindow {
    %orig;
    if (((UIView *)self).window && hookSiri) triggerHapticWithOverride(style_hookSiri);
}
%end

// Control Center presentation
%hook SBControlCenterController
- (void)_willPresent {
    %orig;
    if (hookControlCenter) triggerHapticWithOverride(style_hookControlCenter);
}
%end

// Control Center toggle buttons
%hook CCUILabeledRoundButton
- (void)setHighlighted:(BOOL)highlighted {
    %orig;
    if (hookCCToggles && highlighted) triggerHapticWithOverride(style_hookCCToggles);
}
%end

// Control Center module buttons (brightness, volume sliders in CC)
%hook CCUIButtonModuleView
- (void)setHighlighted:(BOOL)highlighted {
    %orig;
    if (hookCCToggles && highlighted) triggerHapticWithOverride(style_hookCCToggles);
}
%end

// Power-down / SOS slider appearing
%hook SBPowerDownViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (hookPowerDown) triggerHapticWithOverride(style_hookPowerDown);
}
%end

// Home bar / fluid switcher gesture beginning
%hook SBFluidSwitcherGestureManager
- (void)_handleGestureBeganWithGestureRecognizer:(id)recognizer {
    %orig;
    if (hookHomeBar) triggerHapticWithOverride(style_hookHomeBar);
}
%end

// Biometric authentication success (Face ID / Touch ID)
%hook SBDashBoardLockScreenEnvironment
- (void)setAuthenticated:(BOOL)authenticated {
    %orig;
    if (hookBiometric && authenticated) triggerHapticWithOverride(style_hookBiometric);
}
%end

// Lock sound (physical lock button — separate from lockUIFromSource:)
%hook SBSleepWakeHardwareButtonInteraction
- (void)_playLockSound {
    %orig;
    if (hookLockSound) triggerHapticWithOverride(style_hookLockSound);
}
%end

// Passcode keypad key press
%hook SBUIPasscodeLockViewBase
- (void)_sendDelegateKeypadKeyDown {
    %orig;
    if (hookPasscode) triggerHapticWithOverride(style_hookPasscode);
}
%end

// App termination / kill
%hook SBApplication
- (void)_didExitWithContext:(id)arg1 {
    %orig;
    if (hookAppKill) triggerHapticWithOverride(style_hookAppKill);
}
%end

// Phone / FaceTime call status change
%hook TUCall
- (void)_handleStatusChange {
    %orig;
    if (hookCallStatus) triggerHapticWithOverride(style_hookCallStatus);
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
