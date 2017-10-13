#import <BulletinBoard/BBBulletin.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>

BOOL PSEnable;
NSDictionary *PSPref;
NSString *PSWebhookUrl;
NSString *PSChannel;
NSString *PSDeviceName;
BOOL PSIgnoreSlackNotification;

static void loadPSPref() {
	PSPref = [[NSDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/jp.nephy.pushslacker.plist"];

	PSWebhookUrl = [PSPref objectForKey:@"webhookUrl"];
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
}

%group PSHook
%hook BBServer
- (void) _publishBulletinRequest:(BBBulletin*)bulletin forSectionID:(id)arg2 forDestinations:(unsigned long long)arg3 alwaysToLockScreen:(bool)arg4 {
	%orig;

	@try {
		if (PSIgnoreSlackNotification && [bulletin.sectionID isEqual:@"com.tinyspeck.chatlyio"]) {
			return;
		}

		SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bulletin.sectionID];
		NSString *title = bulletin.title ? [NSString stringWithFormat:@"%@ [%@]", bulletin.title, app.displayName] : app.displayName;
		NSString *message = bulletin.subtitle ? [NSString stringWithFormat:@"%@\n%@", bulletin.subtitle, bulletin.message] : bulletin.message;

		NSURL *url = [NSURL URLWithString:PSWebhookUrl];
		NSDictionary *payload = @{
			@"channel": PSChannel,
			@"username": [NSString stringWithFormat:@"%@ (%@)", title, PSDeviceName],
			@"text": message
		};

		NSError *jsonError;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jsonError];

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
%end
%end

%ctor {
	loadPSPref();

	if (PSEnable) {
		%init(PSHook);
	}
}
