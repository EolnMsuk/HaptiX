#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HaptixPrefsRootListController.h"

@interface HaptixPrefsRootListController ()
@property (nonatomic, strong) UIImageView *bannerImageView;
@end

static NSString *HXDetectJailbreakEnvironment(void) {
    NSString *bundlePath = [[NSBundle bundleForClass:NSClassFromString(@"HaptixPrefsRootListController")] bundlePath];
    if ([bundlePath hasPrefix:@"/var/jb"]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb/.installed_roothide"]) {
            return @"RootHide";
        }
        return @"Rootless";
    }
    return @"Rootful";
}

@implementation HaptixPrefsRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
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
    if (!_bannerImageView) return;
    if (![self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) return;

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    BOOL isDark = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    NSString *path = [bundle pathForResource:(isDark ? @"banner" : @"banner2") ofType:@"png"];
    UIImage *image = path ? [UIImage imageWithContentsOfFile:path] : nil;
    if (image) _bannerImageView.image = image;
}

- (UIView *)buildFooterView {
    NSString *version = [[NSBundle bundleForClass:[self class]]
                          objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
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

- (void)openGitHub {
    NSURL *url = [NSURL URLWithString:@"https://github.com/EolnMsuk/HaptiX"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)openDonate {
    NSURL *url = [NSURL URLWithString:@"https://venmo.com/user/EolnMsuk"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
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
        CFPreferencesSetAppValue(CFSTR("enabled"),         kCFBooleanFalse,            domain);
        CFPreferencesSetAppValue(CFSTR("hookKeyboard"),    kCFBooleanTrue,             domain);
        CFPreferencesSetAppValue(CFSTR("hookButtons"),     kCFBooleanTrue,             domain);
        CFPreferencesSetAppValue(CFSTR("hookSwitches"),    kCFBooleanTrue,             domain);
        CFPreferencesSetAppValue(CFSTR("hookCells"),       kCFBooleanTrue,             domain);
        CFPreferencesSetAppValue(CFSTR("hookScrolling"),   kCFBooleanFalse,            domain);
        CFPreferencesSetAppValue(CFSTR("hookVolume"),      kCFBooleanTrue,             domain);
        CFPreferencesSetAppValue(CFSTR("hookPower"),       kCFBooleanTrue,             domain);
        CFPreferencesSetAppValue(CFSTR("hookIcons"),       kCFBooleanTrue,             domain);
        CFPreferencesSetAppValue(CFSTR("hookLockScreen"),  kCFBooleanTrue,             domain);
        CFPreferencesSetAppValue(CFSTR("hookAppSwitcher"), kCFBooleanTrue,             domain);
        CFPreferencesSetAppValue(CFSTR("hapticStyle"),     (__bridge CFNumberRef)@(0), domain);

        CFPreferencesSetAppValue(CFSTR("style_hookKeyboard"),    (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookButtons"),     (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookSwitches"),    (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookCells"),       (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookScrolling"),   (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookVolume"),      (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookPower"),       (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookLockScreen"),  (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookIcons"),       (__bridge CFNumberRef)@(0), domain);
        CFPreferencesSetAppValue(CFSTR("style_hookAppSwitcher"), (__bridge CFNumberRef)@(0), domain);

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
