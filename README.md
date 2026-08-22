# ConcentrationAlert
### Addon and Desktop app for World of Warcraft

Records the new Crafting Concentration (added in The War Within Expansion) for all characters that have the addon enabled. This data is then used for the Desktop App to send notifications via Discord/Windows when your concentration is close to full. Reminds you to log in to characters to utilize the Concentration without wasting any of it.

There is minimal configuration for this addon. It will record/update current crafting concentration whenever you open your crafting window or use concentration when crafting.

There is one slash command to utilize if you want to erase all saved concentration data. Note that this will erase all concentration data for all characters.
/conalertresetall

## Install Instructions:

#### Addon
   1. Install The Addon from Curseforge, using your preferred addon manager or manually.

#### Desktop App
   1. Download Files in [Standalone](Standalone/) to your computer.
   2. If needed unblock and then unzip to the location of your choice.
   3. Click the shortcut link to launch
   4. Open the settings menu and update the Lua File path and discord path. Update additional options as needed.
   5. Click install

#### Desktop App Settings
See Examples and if you have any questions, pop in the Discord Server here: https://discord.com/invite/gjjA8M8KX8

### [REALM SETTINGS]  
#### Addon Lua Path  
Enter the full path to the ConcentrationAlert.lua file on your computer normally under: C:\Program Files (x86)\World of Warcraft\_classic_\WTF\Account\<ACCOUNT_NAME>\SavedVariables\ConcentrationAlert.lua  

#### Realm Names
Enter in the realm name(s) to check. Add more with a comma separating the server names. No spaces. ie: Tichondrius,Area 52,etc. Enter 'all' for all realms.  
Realm Names = Tichondius  

#### Character Names
Enter in the character name(s) to check for cooldowns Only enter each character name once. ie: if you have a character named 'Joe' on realm1 and realm2 to check, only list 'Joe' once below. e.g. for one char: Batman  

For multiple char's, separate them with a comma. No Spaces. ie: Batman,Superman,ImAnAltaholic  

Alternatively, if you want to alert on all characters on all realms, enter in the word 'all' instead of specific character names.  
Character Names  = Batman,Superman  

### [DISCORD SETTINGS]
#### Discord webhook
Set up your own discord server and channel and create a webhook for it.  
Discord Webhook = https://discord&#8203;.com/api/webhooks/your webhook here  

### [ALERT SETTINGS]
#### Alert Time
Enter time (in minutes) for how long before your concentration is full to start alerting you. Defailt is to alert 3 hrs before your concentration is full (180 min)  
Alert Time = 180  

#### Repeated Alerts Interval
How often do you want to keep being alerted? If 'Send Repeated Alerts' is checked (see below), then this value is used for how often to keep alerting you. (In minutes, lowest value is 10, and maximum would be the 'Alert Time' you set above)  
e.g. If 'Alert Time' is set to 180 (3hrs) and you set this to 60 (1hr), you would receive an alert 3hrs before, then every hour after. Requires 'Send Repeated Alerts' to be checked  

#### Send Repeated Alerts
Checking this will use the 'Repeated Alerts Interval' (See Below) to keep sending you alerts at that interval.  

#### Keep Bugging Me
Continous alerting. Checking this will keep sending you alerts at the 'Repeated Alerts Interval' time, even after your concentration is full. Will keep bugging you for each interval up to one day after concentration is full.  
This requires that 'Repeated Alerts Interval' is checked as well.