#import <Foundation/Foundation.h>
#import "HaptixPrefsRootListController.h"

@implementation HaptixPrefsRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)resetSettings {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset HaptiX" 
                                                                   message:@"Are you sure you want to reset all HaptiX settings to their defaults?" 
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        // Delete preference file
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/jb/var/mobile/Library/Preferences/com.eolnmsuk.haptix.plist" error:nil];
        
        // Notify tweak to reload defaults
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.eolnmsuk.haptix/ReloadPrefs"), NULL, NULL, YES);
        
        // Visually reload the preference pane
        [self reloadSpecifiers];
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alert addAction:confirm];
    [alert addAction:cancel];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
