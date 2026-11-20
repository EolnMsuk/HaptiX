#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#import <mach-o/dyld.h>
#import "HaptixDonationController.h"
#import "HaptixPrefsRootListController.h"
#import "HaptixSettingsPresentation.h"
#import "HaptixUpdateChecker.h"

@interface HaptixAdvancedListController : PSListController
@end

@implementation HaptixAdvancedListController
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Advanced" target:self];
    }
    return _specifiers;
}
@end

@interface HaptixPrefsRootListController ()
@property (nonatomic, strong) UIImageView *bannerImageView;
@property (nonatomic) BOOL updateCheckInProgress;
@property (nonatomic) BOOL showUpdateResult;
@end

static NSBundle *HaptixPrefsBundle(void) {
    return [NSBundle bundleForClass:HaptixPrefsRootListController.class];
}

static NSString *HaptixInstalledVersion(void) {
    return [HaptixPrefsBundle() objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

// The Other group uses code adapted from ChoySee. See Resources/ChoySee-LICENSE.txt.
static NSString *const HaptixUpdatesSpecifierID = @"CheckUpdates";
static NSString *const HaptixDonateSpecifierID = @"Donate";

static UIImage *HaptixRenderRowIcon(CGSize imageSize, void (^draw)(CGRect)) {
    CGSize canvasSize = CGSizeMake(29, 29);
    CGRect bounds = CGRectMake((canvasSize.width - imageSize.width) / 2,
                               (canvasSize.height - imageSize.height) / 2,
                               imageSize.width, imageSize.height);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:canvasSize];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        draw(bounds);
    }];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

static UIImage *HaptixUpdatesIcon(void) {
    static UIImage *icon;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSAttributedString *emoji = [[NSAttributedString alloc] initWithString:@"🔄"
            attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:20]}];
        icon = HaptixRenderRowIcon(emoji.size, ^(CGRect bounds) {
            [emoji drawAtPoint:bounds.origin];
        });
    });
    return icon;
}

static UIImage *HaptixDonateIcon(UITraitCollection *traits) {
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:22];
    UIImage *coin = [UIImage systemImageNamed:@"dollarsign.circle.fill" withConfiguration:configuration];
    if (coin) {
        UIColor *orange = [UIColor.systemOrangeColor resolvedColorWithTraitCollection:traits];
        UIImage *tintedCoin = [coin imageWithTintColor:orange renderingMode:UIImageRenderingModeAlwaysOriginal];
        return HaptixRenderRowIcon(tintedCoin.size, ^(CGRect bounds) {
            [tintedCoin drawInRect:bounds];
        });
    }

    UIImage *fallback = [UIImage imageNamed:@"Donate" inBundle:HaptixPrefsBundle() compatibleWithTraitCollection:traits];
    return [fallback imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

@interface HaptixDonateTableCell : PSTableCell
@end

@implementation HaptixDonateTableCell
- (void)layoutSubviews {
    [super layoutSubviews];
    UIColor *green = UIColor.systemGreenColor;
    self.textLabel.textColor = green;
    self.textLabel.highlightedTextColor = green;
}
@end

static NSString *HXDetectJailbreakEnvironment(void) {
#if defined(HAPTIX_NATIVE_ROOTHIDE)
    return @"RootHide";
#else
    // Check older RootHide installations before treating /var/jb as rootless.
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb/.installed_roothide"]) {
        return @"roothide";
    }

    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "roothide")) {
            return @"roothide";
        }
    }

    // Rootless (Dopamine 2, palera1n rootless): /var/jb exists as a symlink to the
    // jailbreak mount. On Dopamine, NSBundle resolves the symlink so the bundle path
    // does NOT start with "/var/jb" — checking directory existence is the reliable test.
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb"]) {
        return @"Rootless";
    }

    return @"Rootful";
#endif
}

@implementation HaptixPrefsRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self bundle:HaptixPrefsBundle()];
        for (PSSpecifier *specifier in _specifiers) {
            if ([specifier.identifier isEqualToString:HaptixUpdatesSpecifierID]) {
                [specifier setProperty:HaptixUpdatesIcon() forKey:@"iconImage"];
                [specifier setProperty:@(!self.updateCheckInProgress) forKey:@"enabled"];
            } else if ([specifier.identifier isEqualToString:HaptixDonateSpecifierID]) {
                [specifier setProperty:HaptixDonateTableCell.class forKey:@"cellClass"];
                [specifier setProperty:HaptixDonateIcon(self.traitCollection) forKey:@"iconImage"];
            }
        }
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSBundle *bundle = HaptixPrefsBundle();
    BOOL isDark = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    NSString *path = [bundle pathForResource:(isDark ? @"banner" : @"banner2") ofType:@"png"];
    UIImage *image = path ? [UIImage imageWithContentsOfFile:path] : nil;
    if (!image) return;

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = (image.size.width > 0)
        ? floorf(screenWidth * image.size.height / image.size.width)
        : 150.0f;

    _bannerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, height)];
    _bannerImageView.image = image;
    _bannerImageView.contentMode = UIViewContentModeScaleAspectFit;
    _bannerImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.table.tableHeaderView = _bannerImageView;
    self.table.tableFooterView = [self buildFooterView];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (![self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) return;

    if (_specifiers) {
        PSSpecifier *row = [self specifierForID:HaptixDonateSpecifierID];
        [row setProperty:HaptixDonateIcon(self.traitCollection) forKey:@"iconImage"];
        if (row && self.isViewLoaded) [self reloadSpecifier:row];
    }

    if (!_bannerImageView) return;
    NSBundle *bundle = HaptixPrefsBundle();
    BOOL isDark = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    NSString *path = [bundle pathForResource:(isDark ? @"banner" : @"banner2") ofType:@"png"];
    UIImage *image = path ? [UIImage imageWithContentsOfFile:path] : nil;
    if (image) _bannerImageView.image = image;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *text = cell.textLabel.text;
    if ([text isEqualToString:@"Reset Settings to Default"]) {
        cell.textLabel.textColor = [UIColor systemRedColor];
    }
}

- (UIView *)buildFooterView {
    NSString *version = HaptixInstalledVersion() ?: @"?";
    NSString *iosVersion = [[UIDevice currentDevice] systemVersion];
    NSString *env = HXDetectJailbreakEnvironment();

    NSString *text = [NSString stringWithFormat:@"HaptiX v%@ (iOS %@ %@)", version, iosVersion, env];

    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    label.textColor = [UIColor secondaryLabelColor];
    label.numberOfLines = 1;
    label.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    [container addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
        [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:container.leadingAnchor constant:16],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:container.trailingAnchor constant:-16],
    ]];
    return container;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.showUpdateResult = NO;
}

- (void)setUpdateCheckInProgress:(BOOL)inProgress {
    _updateCheckInProgress = inProgress;
    PSSpecifier *row = [self specifierForID:HaptixUpdatesSpecifierID];
    [row setProperty:@(!inProgress) forKey:@"enabled"];
    if (row && self.isViewLoaded) [self reloadSpecifier:row];
}

- (void)presentUpdateResultForVersion:(NSString *)installedVersion tag:(NSString *)tag
                     newerReleaseURL:(NSURL *)url failure:(NSString *)failure {
    NSString *title = failure ? @"Update Check Failed" : (url ? @"Update Available" : @"Up to Date");
    NSString *message = failure ?: [NSString stringWithFormat:@"Installed version %@\nLatest stable release %@",
                                    installedVersion, tag];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    if (url) {
        [alert addAction:[UIAlertAction actionWithTitle:@"View Release" style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *action) {
                [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
            }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:(url ? @"Cancel" : @"OK")
                                             style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)checkForUpdates {
    if (self.updateCheckInProgress || !HaptixCanPresent(self)) return;
    self.updateCheckInProgress = YES;
    self.showUpdateResult = YES;

    NSString *version = HaptixInstalledVersion();
    __weak HaptixPrefsRootListController *weakSelf = self;
    [HaptixUpdateChecker checkInstalledVersion:version completion:^(NSString *tag, NSURL *url, NSString *failure) {
        HaptixPrefsRootListController *controller = weakSelf;
        controller.updateCheckInProgress = NO;
        if (controller.showUpdateResult && HaptixCanPresent(controller)) {
            [controller presentUpdateResultForVersion:version tag:tag newerReleaseURL:url failure:failure];
        }
        controller.showUpdateResult = NO;
    }];
}

- (void)openGitHub {
    NSURL *url = [NSURL URLWithString:@"https://github.com/EolnMsuk/HaptiX"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)openReddit {
    NSURL *url = [NSURL URLWithString:@"https://www.reddit.com/user/EolnMsuk4334/"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)presentDonationMenu {
    PSSpecifier *row = [self specifierForID:HaptixDonateSpecifierID];
    NSIndexPath *path = row ? [self indexPathForSpecifier:row] : nil;
    UIView *anchor = path ? [self.table cellForRowAtIndexPath:path] : nil;
    HaptixPresentDonationMenu(self, anchor);
}

- (void)resetSettings {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset HaptiX"
                                                                   message:@"Are you sure you want to reset all HaptiX settings to their defaults?"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        CFStringRef domain = CFSTR("com.eolnmsuk.haptix");

        // Delete all existing keys first (clears blacklist bundle-ID entries and any stale keys).
        CFArrayRef keys = CFPreferencesCopyKeyList(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if (keys) {
            for (CFIndex i = 0, count = CFArrayGetCount(keys); i < count; i++) {
                CFPreferencesSetAppValue(CFArrayGetValueAtIndex(keys, i), NULL, domain);
            }
            CFRelease(keys);
        }

        // Write explicit defaults for every known key. A deletion alone does not trigger
        // cfprefsd's per-process cache invalidation in long-running remote processes
        // (e.g. SpringBoard); an explicit write always does.
        // Global
        CFPreferencesSetAppValue(CFSTR("enabled"),          kCFBooleanFalse,            domain);
        CFPreferencesSetAppValue(CFSTR("hapticStyle"),      (__bridge CFNumberRef)@(4), domain);

        // UIKit triggers
        CFPreferencesSetAppValue(CFSTR("hookKeyboard"),     kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookButtons"),      kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookSwitches"),     kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookCells"),        kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookScrolling"),    kCFBooleanFalse, domain);
        CFPreferencesSetAppValue(CFSTR("hookCallout"),      kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookAlerts"),       kCFBooleanFalse, domain);

        // Hardware & System triggers
        CFPreferencesSetAppValue(CFSTR("hookVolume"),       kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookPower"),        kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookLockScreen"),   kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookIcons"),        kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookAppSwitcher"),  kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookScreenshot"),   kCFBooleanFalse, domain);
        CFPreferencesSetAppValue(CFSTR("hookDisplayWake"),  kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookCharger"),      kCFBooleanFalse, domain);
        CFPreferencesSetAppValue(CFSTR("hookRinger"),       kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookReachability"), kCFBooleanTrue,  domain);

        // System UI triggers
        CFPreferencesSetAppValue(CFSTR("hookFolders"),       kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookSpotlight"),     kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookSiri"),          kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookControlCenter"), kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookCCToggles"),     kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookPowerDown"),     kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookBiometric"),     kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookHomeBar"),       kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookPasscode"),      kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookAppKill"),       kCFBooleanFalse, domain);
        CFPreferencesSetAppValue(CFSTR("hookCallStatus"),    kCFBooleanTrue,  domain);
        CFPreferencesSetAppValue(CFSTR("hookLockSound"),     kCFBooleanFalse, domain);
        CFPreferencesSetAppValue(CFSTR("hookRespring"),      kCFBooleanFalse, domain);

        // Per-trigger style overrides (0 = Use Global)
        CFPreferencesSetAppValue(CFSTR("style_hookKeyboard"),     (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookButtons"),      (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookSwitches"),     (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookCells"),        (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookScrolling"),    (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookCallout"),      (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookAlerts"),       (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookVolume"),       (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookPower"),        (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookLockScreen"),   (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookIcons"),        (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookAppSwitcher"),  (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookScreenshot"),   (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookDisplayWake"),  (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookCharger"),      (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookRinger"),       (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookReachability"), (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookFolders"),       (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookSpotlight"),     (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookSiri"),          (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookControlCenter"), (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookCCToggles"),     (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookPowerDown"),     (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookBiometric"),     (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookHomeBar"),       (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookPasscode"),      (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookAppKill"),       (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookCallStatus"),    (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookLockSound"),     (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookRespring"),      (__bridge CFNumberRef)@(0), domain);

        CFPreferencesAppSynchronize(domain);

        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             CFSTR("com.eolnmsuk.haptix/ReloadPrefs"),
                                             NULL, NULL, YES);
        [self reloadSpecifiers];
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alert addAction:confirm];
    [alert addAction:cancel];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
