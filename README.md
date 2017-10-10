# PushSlacker
Foward any iOS Push Notifications to your Slack channel.

## Config
I've not prepared for PreferenceLoader so this tweak does NOT appear in Settings.app.
Please setup manually.

`/User/Library/Preferences/jp.nephy.pushslacker.plist`
```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>channel</key>
	<string>#YOUR-CHANNEL</string>
	<key>enable</key>
	<true/>
	<key>webhookUrl</key>
	<string>https://hooks.slack.com/services/YOUR/INCOMING/WEBHOOK_URL</string>
</dict>
</plist>
```
