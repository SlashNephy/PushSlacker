#import <BulletinBoard/BBBulletin.h>
#import <BulletinBoard/BBBulletinRequest.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

NSString *PSUrl;
NSString *PSChannel;
BOOL PSIgnoreSlackNotification;

// NSMutableDictionary *PSIconUrlCache;
NSOperationQueue *PSQueue;

%group Hook
%hook BBServer
- (void) _publishBulletinRequest:(id)arg1 forSectionID:(id)arg2 forDestinations:(unsigned long long)arg3 alwaysToLockScreen:(bool)arg4 {
    %orig;

    if ([NSStringFromClass([arg1 class]) compare:@"BBBulletinRequest"] != NSOrderedSame || ! [arg2 isKindOfClass:[NSString class]]) {
        %log;
        return;
    }

    NSString *bundleID = (NSString *)arg2;
    if (PSIgnoreSlackNotification && [bundleID compare:@"com.tinyspeck.chatlyio"] == NSOrderedSame) {
        return;
    }

    [PSQueue addOperationWithBlock:^{
        @try {
            BBBulletinRequest *bulletin = (BBBulletinRequest *)arg1;
            SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleID];

            UIDevice *currentDevice = UIDevice.currentDevice;
            NSString *deviceName = [NSString stringWithFormat:@"%@, %@ %@", currentDevice.name, currentDevice.systemName, currentDevice.systemVersion];
            NSString *username = [NSString stringWithFormat:@"%@ [%@]", app.displayName, deviceName];

            NSMutableString *text = [NSMutableString string];
            if (bulletin.title) {
                [text appendString:[NSString stringWithFormat:@"%@\n", bulletin.title]];
            }
            if (bulletin.subtitle) {
                [text appendString:[NSString stringWithFormat:@"%@\n", bulletin.subtitle]];
            }
            [text appendString:[NSString stringWithFormat:@"```\n%@\n```", bulletin.message]];

            NSString *iconUrl = nil;
            // NSString *iconUrl = (NSString *)[PSIconUrlCache objectForKey:bundleID];
            // if (iconUrl == nil) {
                @try {
                    NSURL *storeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/JP/lookup?bundleId=%@", bundleID]];
                    NSData *storeJsonData = [NSData dataWithContentsOfURL:storeUrl];
                    NSDictionary *storeJson = [NSJSONSerialization JSONObjectWithData:storeJsonData options:0 error:nil];
            
                    NSArray *results = [storeJson objectForKey:@"results"];
                    if (results != nil && results.count > 0) {
                        NSDictionary *result = [results objectAtIndex:0];
                        iconUrl = [result objectForKey:@"artworkUrl60"];
                        // [PSIconUrlCache setObject:iconUrl forKey:bundleID];
                    }
                }
                @catch (NSException *exception) {}
            // }

            NSMutableDictionary *payload = [NSMutableDictionary dictionary];
            [payload setObject:PSChannel forKey:@"channel"];
            [payload setObject:username forKey:@"username"];
            [payload setObject:text forKey:@"text"];
            if (iconUrl != nil) {
                [payload setObject:iconUrl forKey:@"icon_url"];
            } else {
                [payload setObject:@":desktop_computer:" forKey:@"icon_emoji"];
            }

            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setHTTPMethod:@"POST"];
            [request setURL:[NSURL URLWithString:PSUrl]];
            [request addValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:jsonData];

            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {}];
            [task resume];
        }
        @catch (NSException *exception) {
            NSLog(@"[PushSlacker] Error: %@", exception);
        }
    }];
}
%end
%end

%ctor {
    NSDictionary *PSPref = [[NSDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/jp.nephy.pushslacker.plist"];

    BOOL PSEnable = [PSPref objectForKey:@"enable"] ? YES : NO;
    PSUrl = [PSPref objectForKey:@"url"];
    PSChannel = [PSPref objectForKey:@"channel"];
    PSIgnoreSlackNotification = [PSPref objectForKey:@"ignoreSlack"] ? YES : NO;

    if (PSEnable && PSUrl != nil && PSChannel != nil) {
        // PSIconUrlCache = [NSMutableDictionary dictionary];
        PSQueue = [[NSOperationQueue alloc] init];

        %init(Hook);
    }
}
