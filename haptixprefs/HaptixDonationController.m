// Adapted from ChoySee. See Resources/ChoySee-LICENSE.txt.
#import "HaptixDonationController.h"
#import "HaptixSettingsPresentation.h"
#import <dispatch/dispatch.h>

static NSString *const HaptixVenmoURL = @"https://venmo.com/EolnMsuk/";

@protocol HaptixBrowserConfiguration <NSObject>
@property (nonatomic) BOOL allowURLOverrides;
@end

@protocol HaptixBrowserWorkspace <NSObject>
+ (id<HaptixBrowserWorkspace>)defaultWorkspace;
- (void)openURL:(NSURL *)url configuration:(id)configuration
    completionHandler:(void (^)(NSDictionary *, NSError *))completion;
@end

static void HaptixShowBrowserError(UIViewController *controller, NSString *detail) {
    if (!HaptixCanPresent(controller)) return;
    NSString *message = [NSString stringWithFormat:@"%@\nVisit %@", detail, HaptixVenmoURL];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unable to Open Browser"
        message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [controller presentViewController:alert animated:YES completion:nil];
}

static void HaptixOpenVenmo(UIViewController *controller) {
    if (!HaptixCanPresent(controller)) return;

    Class<HaptixBrowserWorkspace> workspaceClass = (Class<HaptixBrowserWorkspace>)NSClassFromString(@"LSApplicationWorkspace");
    id<HaptixBrowserWorkspace> workspace = nil;
    if ([workspaceClass respondsToSelector:@selector(defaultWorkspace)]) {
        workspace = [workspaceClass defaultWorkspace];
    }
    id<HaptixBrowserConfiguration> configuration = [NSClassFromString(@"_LSOpenConfiguration") new];
    if (![configuration respondsToSelector:@selector(setAllowURLOverrides:)]
        || ![workspace respondsToSelector:@selector(openURL:configuration:completionHandler:)]) {
        HaptixShowBrowserError(controller, @"The default browser route is unavailable on this iOS version.");
        return;
    }

    // Disable universal-link overrides so the system opens the selected browser.
    configuration.allowURLOverrides = NO;
    __weak UIViewController *weakController = controller;
    [workspace openURL:[NSURL URLWithString:HaptixVenmoURL] configuration:configuration
        completionHandler:^(NSDictionary *result, NSError *error) {
            if (!error) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                HaptixShowBrowserError(weakController, @"The default browser could not open Venmo.");
            });
        }];
}

static NSArray<NSDictionary<NSString *, NSString *> *> *HaptixWallets(void) {
    static NSArray<NSDictionary<NSString *, NSString *> *> *wallets;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        wallets = @[
            @{@"coin": @"BTC", @"network": @"Bitcoin Network", @"address": @"31uHLpioo1TbxAmo9kM7rrKcLz3wvcoZaL"},
            @{@"coin": @"ETH", @"network": @"Ethereum Network", @"address": @"0x6060BEA4305BC4259bcF1db5eDbe756b7b74a895"},
            @{@"coin": @"USDT", @"network": @"Ethereum Network", @"address": @"0x17f0c9d7229E9A1Ad1cAccbfEe7979CF39F2301F"},
            @{@"coin": @"USDC", @"network": @"Ethereum Network", @"address": @"0xD69Dc2a18e64E071d096435dD6f9DdD52B10785c"},
            @{@"coin": @"RNDR / ERC-20", @"network": @"Ethereum Network", @"address": @"0x9cc3fCc3b41a31cDC07E33930F1d622c3ed690E9"},
            @{@"coin": @"LTC", @"network": @"Litecoin Network", @"address": @"MNWMWwueZBoQSd7Ms9meQ1cMfeY16BA7E1"},
            @{@"coin": @"SOL", @"network": @"Solana Network", @"address": @"H2ydj95396KRErC4nMtK5B2BAjobPTyUh7LpYBFSmFnP"},
            @{@"coin": @"BNB", @"network": @"BNB Smart Chain Network", @"address": @"0x314148b89744663ad9F1Fb8EA6862a62abf2fC93"}
        ];
    });
    return wallets;
}

@interface HaptixWalletCell : UITableViewCell
- (void)showWallet:(NSDictionary<NSString *, NSString *> *)wallet copied:(BOOL)copied;
- (void)showCoin:(NSString *)coin copied:(BOOL)copied;
@end

@implementation HaptixWalletCell {
    UILabel *_coinLabel;
    UILabel *_networkLabel;
    UILabel *_addressLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
    self = [super initWithStyle:style reuseIdentifier:identifier];
    if (!self) return nil;

    _coinLabel = [UILabel new];
    _networkLabel = [UILabel new];
    _addressLabel = [UILabel new];
    _coinLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _networkLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _addressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _coinLabel.textColor = UIColor.labelColor;
    _networkLabel.textColor = UIColor.secondaryLabelColor;
    _addressLabel.textColor = UIColor.labelColor;
    _addressLabel.lineBreakMode = NSLineBreakByCharWrapping;

    NSArray<UILabel *> *labels = @[_coinLabel, _networkLabel, _addressLabel];
    for (UILabel *label in labels) {
        label.numberOfLines = 0;
        label.adjustsFontForContentSizeCategory = YES;
    }
    UIStackView *details = [[UIStackView alloc] initWithArrangedSubviews:labels];
    details.axis = UILayoutConstraintAxisVertical;
    details.spacing = 4;
    details.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:details];

    UILayoutGuide *margins = self.contentView.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [details.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
        [details.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
        [details.topAnchor constraintEqualToAnchor:margins.topAnchor constant:4],
        [details.bottomAnchor constraintEqualToAnchor:margins.bottomAnchor constant:-4]
    ]];
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    self.accessibilityHint = @"Double-tap to copy this address.";
    return self;
}

- (void)showWallet:(NSDictionary<NSString *, NSString *> *)wallet copied:(BOOL)copied {
    NSString *coin = wallet[@"coin"];
    [self showCoin:coin copied:copied];
    _networkLabel.text = wallet[@"network"];
    _addressLabel.text = wallet[@"address"];
    self.accessibilityLabel = [@[coin, _networkLabel.text, _addressLabel.text] componentsJoinedByString:@", "];
}

- (void)showCoin:(NSString *)coin copied:(BOOL)copied {
    _coinLabel.text = copied ? [NSString stringWithFormat:@"%@ · Copied", coin] : coin;
    self.accessibilityValue = copied ? @"Copied" : nil;
}
@end

@interface HaptixDonationController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@implementation HaptixDonationController {
    UITableView *_walletTable;
    NSMutableDictionary<NSIndexPath *, NSObject *> *_copyTokens;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Crypto Wallets";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    _copyTokens = [NSMutableDictionary dictionary];

    _walletTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _walletTable.backgroundColor = self.view.backgroundColor;
    _walletTable.translatesAutoresizingMaskIntoConstraints = NO;
    _walletTable.rowHeight = UITableViewAutomaticDimension;
    _walletTable.estimatedRowHeight = 120;
    _walletTable.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [_walletTable registerClass:HaptixWalletCell.class forCellReuseIdentifier:@"Wallet"];
    _walletTable.dataSource = self;
    _walletTable.delegate = self;
    [self.view addSubview:_walletTable];

    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
    cancel.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cancel.titleLabel.adjustsFontForContentSizeCategory = YES;
    cancel.translatesAutoresizingMaskIntoConstraints = NO;
    [cancel addTarget:self action:@selector(closeWallets) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancel];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_walletTable.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [_walletTable.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        [_walletTable.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [_walletTable.bottomAnchor constraintEqualToAnchor:cancel.topAnchor],
        [cancel.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:16],
        [cancel.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-16],
        [cancel.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-8],
        [cancel.heightAnchor constraintGreaterThanOrEqualToConstant:44]
    ]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return HaptixWallets().count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    HaptixWalletCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Wallet" forIndexPath:path];
    [cell showWallet:HaptixWallets()[path.row] copied:(_copyTokens[path] != nil)];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    NSDictionary<NSString *, NSString *> *wallet = HaptixWallets()[path.row];
    NSString *coin = wallet[@"coin"];
    UIPasteboard.generalPasteboard.string = wallet[@"address"];

    NSObject *token = [NSObject new];
    _copyTokens[path] = token;
    HaptixWalletCell *cell = (HaptixWalletCell *)[tableView cellForRowAtIndexPath:path];
    [cell showCoin:coin copied:YES];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
        [NSString stringWithFormat:@"%@ address copied", coin]);

    __weak HaptixDonationController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        HaptixDonationController *controller = weakSelf;
        if (!controller || controller->_copyTokens[path] != token) return;
        [controller->_copyTokens removeObjectForKey:path];
        HaptixWalletCell *visibleCell = (HaptixWalletCell *)[controller->_walletTable cellForRowAtIndexPath:path];
        [visibleCell showCoin:coin copied:NO];
    });
}

- (void)closeWallets {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

static void HaptixAfterDonationSheet(UIAlertController *sheet, dispatch_block_t nextAction) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (sheet.isBeingDismissed && [sheet.transitionCoordinator animateAlongsideTransition:nil
            completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                if (!context.isCancelled) nextAction();
            }]) return;
        if (sheet.presentingViewController) {
            [sheet dismissViewControllerAnimated:YES completion:nextAction];
        } else {
            nextAction();
        }
    });
}

void HaptixPresentDonationMenu(UIViewController *controller, UIView *anchor) {
    NSCAssert(NSThread.isMainThread, @"The donation menu must be presented on the main thread");
    if (!HaptixCanPresent(controller)) return;

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"💸 Donate"
        message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak UIViewController *weakController = controller;
    __weak UIAlertController *weakSheet = sheet;
    [sheet addAction:[UIAlertAction actionWithTitle:@"Venmo" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
            HaptixAfterDonationSheet(weakSheet, ^{ HaptixOpenVenmo(weakController); });
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Crypto" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
            HaptixAfterDonationSheet(weakSheet, ^{
                UIViewController *presenter = weakController;
                if (!HaptixCanPresent(presenter)) return;
                UINavigationController *wallets = [[UINavigationController alloc]
                    initWithRootViewController:[HaptixDonationController new]];
                wallets.modalPresentationStyle = UIModalPresentationFormSheet;
                wallets.preferredContentSize = CGSizeMake(500, 640);
                [presenter presentViewController:wallets animated:YES completion:nil];
            });
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (anchor && anchor.window == controller.view.window) {
        popover.sourceView = anchor;
        popover.sourceRect = anchor.bounds;
    } else {
        popover.sourceView = controller.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(controller.view.bounds), CGRectGetMidY(controller.view.bounds), 1, 1);
    }
    [controller presentViewController:sheet animated:YES completion:nil];
}
