#import <BulletinBoard/BBBulletin.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

NSMutableDictionary *PSIconUrlCache;

#define PLIST_PATH @"/private/var/mobile/Library/Preferences/jp.nephy.pushslacker.plist"

inline bool getPrefBool(NSString *key) {
	return [[[NSDictionary dictionaryWithContentsOfFile:PLIST_PATH] valueForKey:key] boolValue];
}

inline NSString* getPrefString(NSString *key) {
	return [[[NSDictionary dictionaryWithContentsOfFile:PLIST_PATH] valueForKey:key] stringValue];
}

static NSString* lookupBundle(NSString *bundleId) {
    @autoreleasepool {
        @try {
            NSURL *storeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/JP/lookup?bundleId=%@", bundleId]];
            NSData *storeJsonData = [NSData dataWithContentsOfURL:storeUrl];
            NSDictionary *storeJson = [NSJSONSerialization JSONObjectWithData:storeJsonData options:0 error:nil];

            NSArray *results = [storeJson objectForKey:@"results"];
            if (results != nil && results.count > 0) {
                NSDictionary *result = [results objectAtIndex:0];

                return [result objectForKey:@"artworkUrl60"];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"[PushSlacker] Error: %@", exception);
        }

        return nil;
    }
}

static void sendSlackMessage(NSString *text, NSString *username, NSString *iconUrl) {
    @autoreleasepool {
        NSMutableDictionary *payload = [NSMutableDictionary dictionary];

        [payload setObject:text forKey:@"text"];
        [payload setObject:username forKey:@"username"];
        if (iconUrl != nil) {
            [payload setObject:iconUrl forKey:@"icon_url"];
        } else {
            [payload setObject:@":desktop_computer:" forKey:@"icon_emoji"];
        }

        NSString *PSChannel = getPrefString(@"channel");
        if (PSChannel == nil) {
            return;
        }

        [payload setObject:PSChannel forKey:@"channel"];

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

        NSString *PSUrl = getPrefString(@"url");
        if (PSUrl == nil) {
            return;
        }

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
}

%group Hook
%hook BBServer
- (void)_publishBulletinRequest:(BBBulletin *)bulletin forSectionID:(NSString *)sectionID forDestinations:(unsigned long long)arg3 {
	%orig;

    if (!getPrefBool(@"enable")) {
        return;
    }

    if (!sectionID) {
        return;
    }

    if ([sectionID compare:@"com.tinyspeck.chatlyio"] == NSOrderedSame && getPrefBool(@"ignoreSlack")) {
        return;
    }

    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        @try {
            NSString *title = bulletin.title;
            NSString *subtitle = bulletin.subtitle;
			NSString *message = bulletin.message;

            NSMutableString *text = [NSMutableString string];
            if (title) {
                [text appendString:[NSString stringWithFormat:@"%@\n", title]];
            }
            if (subtitle) {
                [text appendString:[NSString stringWithFormat:@"%@\n", subtitle]];
            }
            if (message) {
                [text appendString:[NSString stringWithFormat:@"```\n%@\n```", message]];
            }

            SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:sectionID];
            NSString *appName = app.displayName;

            UIDevice *currentDevice = UIDevice.currentDevice;
            NSString *deviceName = [NSString stringWithFormat:@"%@, %@ %@", currentDevice.name, currentDevice.systemName, currentDevice.systemVersion];

            NSString *username;
            if (appName) {
                username = [NSString stringWithFormat:@"%@ [%@]", appName, deviceName];
            } else {
                username = deviceName;
            }

            NSString *iconUrl = [PSIconUrlCache objectForKey:sectionID];
            if (iconUrl == nil) {
                iconUrl = lookupBundle(sectionID);

                if (iconUrl != nil) {
                    [PSIconUrlCache setObject:iconUrl forKey:sectionID];
                }
            }

            sendSlackMessage(text, username, iconUrl);
        }
        @catch (NSException *exception) {
            NSLog(@"[PushSlacker] Error: %@", exception);
        }
    }];
}
%end
%end

%ctor {
    PSIconUrlCache = [NSMutableDictionary dictionary];

    @autoreleasepool {
        %init(Hook);
    }
}
