// Adapted from ChoySee. See Resources/ChoySee-LICENSE.txt.
#import "HaptixUpdateChecker.h"
#import <dispatch/dispatch.h>

static NSString *const HaptixLatestReleaseEndpoint = @"https://api.github.com/repos/EolnMsuk/HaptiX/releases/latest";
static NSString *const HaptixReleasePagePrefix = @"https://github.com/EolnMsuk/HaptiX/releases/tag/";
static const NSUInteger HaptixReleaseResponseLimit = 64 * 1024;

static NSArray<NSString *> *HaptixVersionParts(NSString *version) {
    if (![version isKindOfClass:NSString.class] || version.length > 128) return nil;
    static NSRegularExpression *pattern;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        pattern = [NSRegularExpression regularExpressionWithPattern:
            @"\\Av?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(?:-b[0-9]+)?\\z"
            options:0 error:NULL];
    });
    NSTextCheckingResult *match = [pattern firstMatchInString:version options:0 range:NSMakeRange(0, version.length)];
    if (!match) return nil;
    return @[[version substringWithRange:[match rangeAtIndex:1]],
             [version substringWithRange:[match rangeAtIndex:2]],
             [version substringWithRange:[match rangeAtIndex:3]]];
}

static BOOL HaptixVersionIsNewer(NSArray<NSString *> *remote, NSArray<NSString *> *installed) {
    // The components have no leading zeroes, so this comparison avoids integer overflow.
    for (NSUInteger index = 0; index < remote.count; index++) {
        NSString *remotePart = remote[index];
        NSString *installedPart = installed[index];
        if (remotePart.length != installedPart.length) return remotePart.length > installedPart.length;
        NSComparisonResult order = [remotePart compare:installedPart options:NSLiteralSearch];
        if (order != NSOrderedSame) return order == NSOrderedDescending;
    }
    return NO;
}

static BOOL HaptixIsJSONFalse(id value) {
    return [value isKindOfClass:NSNumber.class]
        && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()
        && ![value boolValue];
}

@interface HaptixUpdateChecker () <NSURLSessionDataDelegate>
@end

@implementation HaptixUpdateChecker {
    NSURLSession *_session;
    NSURLSessionDataTask *_task;
    NSMutableData *_responseData;
    NSArray<NSString *> *_installedParts;
    NSMutableArray<HaptixUpdateCompletion> *_completions;
    NSString *_failureMessage;
}

+ (void)checkInstalledVersion:(NSString *)version completion:(HaptixUpdateCompletion)completion {
    NSAssert(NSThread.isMainThread, @"Updates must be requested from Settings on the main thread");
    static HaptixUpdateChecker *checker;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ checker = [HaptixUpdateChecker new]; });
    [checker startCheckForVersion:version completion:completion];
}

- (void)startCheckForVersion:(NSString *)version completion:(HaptixUpdateCompletion)completion {
    if (_task) {
        [_completions addObject:[completion copy]];
        return;
    }
    _installedParts = HaptixVersionParts(version);
    if (!_installedParts) {
        completion(nil, nil, @"HaptiX could not read its installed version.");
        return;
    }

    NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    configuration.timeoutIntervalForRequest = 15;
    configuration.timeoutIntervalForResource = 20;
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    configuration.URLCache = nil;
    configuration.HTTPCookieStorage = nil;
    configuration.HTTPShouldSetCookies = NO;
    configuration.URLCredentialStorage = nil;
    // Main-queue delegates serialize the bounded response and keep Settings updates on the main thread.
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:NSOperationQueue.mainQueue];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:HaptixLatestReleaseEndpoint]];
    [request setValue:@"application/vnd.github+json" forHTTPHeaderField:@"Accept"];
    [request setValue:[@"HaptiX-Preferences/" stringByAppendingString:version] forHTTPHeaderField:@"User-Agent"];
    _responseData = [NSMutableData data];
    _completions = [NSMutableArray arrayWithObject:[completion copy]];
    _task = [_session dataTaskWithRequest:request];
    [_task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request
    completionHandler:(void (^)(NSURLRequest *))completionHandler {
    if (task == _task) _failureMessage = @"GitHub redirected the release request.";
    completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task
    didReceiveResponse:(NSURLResponse *)response
    completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if (task != _task || _failureMessage) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
    if (![http isKindOfClass:NSHTTPURLResponse.class]
        || ![http.URL.absoluteString isEqualToString:HaptixLatestReleaseEndpoint]) {
        _failureMessage = @"GitHub did not return a valid release response for HaptiX.";
    } else if (http.statusCode == 404) {
        _failureMessage = @"HaptiX has no published stable release on GitHub.";
    } else if (http.statusCode != 200) {
        _failureMessage = [NSString stringWithFormat:@"GitHub returned HTTP %ld. Try again later.", (long)http.statusCode];
    } else if (http.expectedContentLength > (int64_t)HaptixReleaseResponseLimit) {
        _failureMessage = @"GitHub returned too much release data.";
    }
    completionHandler(_failureMessage ? NSURLSessionResponseCancel : NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data {
    if (task != _task || _failureMessage) return;
    if (data.length > HaptixReleaseResponseLimit - _responseData.length) {
        _failureMessage = @"GitHub returned too much release data.";
        [task cancel];
        return;
    }
    [_responseData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (task != _task) return;
    NSString *tag = nil;
    NSURL *newerReleaseURL = nil;
    NSString *failure = _failureMessage;
    if (!failure && error) {
        failure = [NSString stringWithFormat:@"Unable to reach GitHub. %@", error.localizedDescription];
    }
    if (!failure) {
        id parsed = [NSJSONSerialization JSONObjectWithData:_responseData options:0 error:NULL];
        NSDictionary *release = [parsed isKindOfClass:NSDictionary.class] ? parsed : nil;
        NSString *candidateTag = release[@"tag_name"];
        NSArray<NSString *> *remoteParts = HaptixVersionParts(candidateTag);
        NSString *expectedURL = remoteParts ? [HaptixReleasePagePrefix stringByAppendingString:candidateTag] : nil;
        id link = release[@"html_url"];
        if (!remoteParts || !HaptixIsJSONFalse(release[@"draft"]) || !HaptixIsJSONFalse(release[@"prerelease"])
            || ![link isKindOfClass:NSString.class] || ![link isEqualToString:expectedURL]) {
            failure = @"GitHub did not return valid stable release information for HaptiX.";
        } else {
            tag = candidateTag;
            if (HaptixVersionIsNewer(remoteParts, _installedParts)) {
                newerReleaseURL = [NSURL URLWithString:expectedURL];
            }
        }
    }
    NSArray<HaptixUpdateCompletion> *completions = _completions;
    [session finishTasksAndInvalidate];
    _session = nil;
    _task = nil;
    _completions = nil;
    _responseData = nil;
    _installedParts = nil;
    _failureMessage = nil;
    for (HaptixUpdateCompletion completion in completions) {
        completion(tag, newerReleaseURL, failure);
    }
}
@end
