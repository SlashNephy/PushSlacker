#import <BulletinBoard/BBBulletin.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

BOOL PSEnable;
NSDictionary *PSPref;
NSURL *PSWebhookUrl;
NSString *PSChannel;
NSString *PSDeviceName;
BOOL PSIgnoreSlackNotification;
NSMutableDictionary *PSIconCache;

static void loadPSPref() {
	PSPref = [[NSDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/jp.nephy.pushslacker.plist"];

	PSWebhookUrl = [NSURL URLWithString:[PSPref objectForKey:@"webhookUrl"]];
	PSChannel = [PSPref objectForKey:@"channel"];
	PSIgnoreSlackNotification = [PSPref.allKeys containsObject:@"ignoreSlack"] && PSPref[@"ignoreSlack"] ? YES : NO;
	if (! [PSPref.allKeys containsObject:@"enable"] || PSWebhookUrl == nil || PSChannel == nil) {
		PSEnable = NO;
	} else if (PSPref[@"enable"]) {
		PSEnable = YES;
	} else {
		PSEnable = NO;
	}

	UIDevice *currentDevice = UIDevice.currentDevice;
	PSDeviceName = [NSString stringWithFormat:@"%@, %@ %@", currentDevice.name, currentDevice.systemName, currentDevice.systemVersion];

	PSIconCache = [NSMutableDictionary dictionary];
}

%group PSHook
%hook BBServer
- (void) _publishBulletinRequest:(BBBulletin*)bulletin forSectionID:(id)arg2 forDestinations:(unsigned long long)arg3 alwaysToLockScreen:(bool)arg4 {
	%orig;

	@try {
		NSString *bundleID = bulletin.sectionID;
		if (PSIgnoreSlackNotification && [bundleID isEqual:@"com.tinyspeck.chatlyio"]) {
			return;
		}

		SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleID];

		NSString *title = bulletin.title && ! [bulletin.title isEqual:@""] && ! [bulletin.title isEqual:app.displayName] ? [NSString stringWithFormat:@"%@ [%@]", bulletin.title, app.displayName] : app.displayName;
		NSString *message = bulletin.subtitle ? [NSString stringWithFormat:@"%@\n%@", bulletin.subtitle, bulletin.message] : bulletin.message;

		if (! [PSIconCache.allKeys containsObject:bundleID]) {
			@try {
				NSURL *storeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/JP/lookup?bundleId=%@", bundleID]];
				NSData *storeJsonData = [NSData dataWithContentsOfURL:storeUrl];

				NSDictionary *storeJson = [NSJSONSerialization JSONObjectWithData:storeJsonData options:0 error:nil];
				NSArray *results = [storeJson objectForKey:@"results"];
				if (results.count > 0) {
					NSDictionary *result = [results objectAtIndex:0];
					[PSIconCache setObject:[result objectForKey:@"artworkUrl60"] forKey:bundleID];
				} else {
					[PSIconCache setObject:[NSNull null] forKey:bundleID];
				}
			}
			@catch (NSException *exception) {
				NSLog(@"[PushSlacker] Error occured. Detail: %@", exception);
			}
		}

		NSMutableDictionary *payload = [NSMutableDictionary dictionary];
		[payload setObject:PSChannel forKey:@"channel"];
		[payload setObject:[NSString stringWithFormat:@"%@ (%@)", title, PSDeviceName] forKey:@"username"];
		[payload setObject:message forKey:@"text"];

		if ([PSIconCache.allKeys containsObject:bundleID] && PSIconCache[bundleID]) {
			[payload setObject:PSIconCache[bundleID] forKey:@"icon_url"];
		}

		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:PSWebhookUrl];
		[request setHTTPMethod:@"POST"];
		[request addValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:jsonData];

		NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {}];

		[postDataTask resume];
	}
	@catch (NSException *exception) {
		NSLog(@"[PushSlacker] Error occured. Detail: %@", exception);
	}
}
%end
%end

%ctor {
	loadPSPref();

	if (PSEnable) {
		%init(PSHook);
	}
}
