#import <Foundation/NSTask.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>

#define PSPrefPath @"/private/var/mobile/Library/Preferences/jp.nephy.pushslacker.plist"

@interface PushSlackerController : PSListController
@end

@interface SpringBoard : UIApplication
- (void)_relaunchSpringBoardNow;
@end

@implementation PushSlackerController
- (NSArray *)specifiers {
	if (! _specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}
	return _specifiers;
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *fitpusherSettings = [NSDictionary dictionaryWithContentsOfFile:PSPrefPath];
	if (!fitpusherSettings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return fitpusherSettings[specifier.properties[@"key"]];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PSPrefPath]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:PSPrefPath atomically:YES];
}

- (void)kill {
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:[NSArray arrayWithObjects:@"-9", @"SpringBoard", nil]];
}
@end
