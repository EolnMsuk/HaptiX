#import <Foundation/Foundation.h>
#import "HaptixPrefsRootListController.h"

@implementation HaptixPrefsRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

@end