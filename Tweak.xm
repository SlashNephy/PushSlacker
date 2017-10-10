#import <BulletinBoard/BBBulletin.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

UIDevice* currentDevice = UIDevice.currentDevice;
NSString* deviceModel = currentDevice.model;
NSString* deviceVersion = currentDevice.systemVersion;

NSDictionary *PSPref = [[NSDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/jp.nephy.pushslacker.plist"];
NSString *PSWebhookUrl = [PSPref objectForKey:@"webhookUrl"];
NSString *PSChannel = [PSPref objectForKey:@"channel"];
BOOL PSEnable = (! [PSPref.allKeys containsObject:@"enable"] || PSWebhookUrl == nil || PSChannel == nil) ? NO : (PSPref[@"enable"] ? YES : NO);

%group PSHook
%hook BBServer
- (void)_publishBulletinRequest:(BBBulletin*)bulletin forSectionID:(id)arg2 forDestinations:(unsigned long long)arg3 alwaysToLockScreen:(bool)arg4
{
	if (PSEnable) {
		SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bulletin.sectionID];
		NSString *title = bulletin.title ? [NSString stringWithFormat:@"%@ [%@]", bulletin.title, app.displayName] : app.displayName;
		NSString *message = bulletin.subtitle ? [NSString stringWithFormat:@"%@\n%@", bulletin.subtitle, bulletin.message] : bulletin.message;

		NSURL *url = [NSURL URLWithString:PSWebhookUrl];
		NSDictionary *payload = @{
			@"channel": PSChannel,
			@"username": [NSString stringWithFormat:@"%@ (%@, iOS %@)", title, deviceModel, deviceVersion],
			@"text": message
		};

		NSError *jsonError;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jsonError];

		@try {
			NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
			NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
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

	return %orig;
}
%end
%end

%ctor {
	%init(PSHook);
}
