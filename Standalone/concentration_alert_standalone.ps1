####################### Concentration Alert ###########################
# Name: Concentration Alert - Standalone Version                      #
# Desc: Sends Discord Notification when Concentraion is close to full #
# Author: Ninthwalker (Echellon)                                      #
# Instructions: https://github.com/ninthwalker/ConcentraionAlert      #
# Last Updated: 20AUG2024                                             #
# Version: 1.0.0                                                      #
#######################################################################

########################### CHANGE LOG ################################
## 1.0.0                                                              #
# Initial App release                                                 #
#######################################################################
 
######################### NOTES FOR USER ##############################
# Used with concentraion_alert_standalone_settings.txt                #
# Used in conjunction with this Addon:                                # 
#   https://curseforge.com/wow/addons/concentrationalert              #
# Join the Concentration Alert discord:                               #
#   https://discord.com/invite/gjjA8M8KX8                             #
# What this does:                                                     #
# Creates a scheduled task on your computer that will use your wow    # 
#  concentration data to send you discord alerts when close to full   #
#######################################################################

#######################################################################
########           Do not Modify anything below this           ########
#######################################################################

#check task to see what gui to show at start
param ([switch]$runFromTask)
if (!$runFromTask) {$canToast = $True}

# Current Concentration interval
$conMath = 0.1736111111111111 # per minute. Seconds for 0 to 1000 currently = 345600, which equals 0.17361 (with a line over it) per 60 seconds
# script version
$version = "v1.0.0"

# paths of this script
$scriptDir = $PSScriptRoot
$scriptPath = $PSCommandPath
if (!$scriptDir) {$scriptDir = (Get-Location).path}
if (!$scriptPath) {($scriptPath = "$(Get-Location)\concentration_alert_standalone.ps1")}
$conPath = "$scriptDir\conInfo.csv"

$taskName = "WoW Concentration Alert"
$taskArgs =  @"
vbscript:Execute("CreateObject(""WScript.Shell"").Run ""powershell -ExecutionPolicy Bypass & '$scriptPath' -runFromTask"", 0:close")
"@

Function New-Check {
    try {
        $script:task = (get-ScheduledTask -TaskName $taskName -ErrorAction Stop).actions.arguments
        $script:checkTask = $True
    } catch {
        $script:checkTask = $False
    }
}

if ($canToast) {
    #check task
    New-Check
    if ($checkTask) {
        if ($task -ne $taskArgs) {
            # task settings are bad. Show install button
            $gui = "install"
        } elseif ($task -eq $taskArgs) {
            # task is good, show uninstall button
            $gui = "uninstall"
        }
    } else {
        # no task found, show install button
        $gui = "install" 
    }
}

# toast notifications - only shown when this is run manually or from shortcut to help with debugging/status
Function New-PopUp {

    param ([string]$msg, [string]$icon)

    $notify = new-object system.windows.forms.notifyicon
    $notify.BalloonTipTitle = "WoW Concentration Alert"
    $notify.icon = [System.Drawing.SystemIcons]::Information
    $notify.visible = $true
    $notify.showballoontip(10,'WoW Concentration Alert',$msg,[system.windows.forms.tooltipicon]::$icon)
}

# discord
function Send-Discord {

    Param(
        [String]$title,
        [String]$color,
        [String]$icon,
        [String]$msg,
        [String]$footer,
        [String]$link,
        [String]$discordWebhook
    )

    #Create embed object, also adding thumbnail
    
    $embedObject = [PSCustomObject]@{
        embeds = @([ordered]@{
            title       = $title
            description = $msg
            color       = $color
            url         = $link
            thumbnail   = @{ url = $icon }
            footer      = @{
                text = $footer
                icon_url = 'https://raw.githubusercontent.com/ninthwalker/github/main/img/wowcdnotifier/world-of-warcraft.png'
            } 
        })
    } | ConvertTo-Json -Depth 4

    #Send over payload, converting it to JSON
    Invoke-RestMethod -Uri $discordWebhook -Body $embedObject -Method Post -ContentType 'application/json'
}

Function Start-Debug {
    #start powershell {& $scriptPath -noprofile -noexit -ExecutionPolicy Bypass}
    $argList = "-noprofile -noexit -ExecutionPolicy Bypass -file `"$scriptPath`""
    Start-Process powershell -argumentlist $argList
}

# ConcentrationAlert funcion
Function Start-WoWConcentrationAlert {

    if ($canToast) {
        # Disable buttons and clear status
        $button_install.Enabled = $False
        $label_status.ForeColor = "#ffff00"
        $label_status.text = "Installing .."
        $label_status.Refresh()
        Start-Sleep -Seconds 1
    }

    # create scheduled task if it does not exist
    # uses this code to create the task for you:
    Function New-CdTask {
        if ($set.interval -eq $True) {
            $taskIntervalTime = $set.intervalTime
        } else {
            $taskIntervalTime = $set.alertTime
        }
        $taskInterval = (New-TimeSpan -Minutes $taskIntervalTime)
        $taskTrigger  = New-ScheduledTaskTrigger -Once -At 00:00 -RepetitionInterval $taskInterval
        $taskAction   = New-ScheduledTaskAction -Execute 'mshta' -Argument $taskArgs
        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Description "Sends a discord alert for WoW Concentration"
    }

    # Import settings
    Function Get-Settings ([string]$fileName) {
        $data = New-Object PSCustomObject
        switch -regex -file $fileName {
            "^\s*([^#]+?)\s*=\s*(.*)" { # recognize a property
                $name,$value = $matches[1..2]
                $data | Add-Member -Type NoteProperty -Name $name -Value $value
            }
        }
        $data
    }

    if (Test-Path $scriptDir\concentration_alert_standalone_settings.txt) {
        $set = Get-Settings $scriptDir\concentration_alert_standalone_settings.txt
    } else {
        if ($canToast) {
            New-PopUp -msg "Couldn't find settings file. Please check settings!" -icon "Warning"
            $label_status.ForeColor = "#ffff00"
            $label_status.text = "Couldn't find settings file.`r`nPlease Check settings and try again."
            $label_status.Refresh()
            $button_install.Enabled = $True
        }
        Return
    }

    if ($set.realmNames -like '*,*') { $set.realmNames = $set.realmNames.Split(',') }
    if ($set.charNames -like '*,*') { $set.charNames = $set.charNames.Split(',') }

    # verify settings before moving on
    $settingsCheck = $set.PSObject.Properties | % { if ($_.value -eq "") {$_.name} }
    if ($settingsCheck) {
        if ($canToast) {
            New-PopUp -msg "Missing Settings! Please fix $settingsCheck" -icon "Warning"
            $label_status.ForeColor = "#ffff00"
            $label_status.text = "Missing Settings! Please fix:`r`n$settingsCheck"
            $label_status.Refresh()
            $button_install.Enabled = $True
        }
        Return
    }

    # only run this section if its NOT being run from the scheduled task. sets up the scheduled task
    if ($canToast) {

        #check task
        New-Check
        if ($checkTask) {
    
            if ($task -ne $taskArgs) {
                # task path is bad, delete and re-create
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                Start-Sleep -Seconds 1
                New-CdTask
                Start-Sleep -Seconds 1
                New-Check
                if ( ($checkTask -eq $taskArgs) -and $canToast) {
                    New-PopUp -msg "Install completed successfully. Have fun!" -icon "Info"
                    $goodInstall = $True
                    $label_status.ForeColor = "#7CFC00"
                    $label_status.text = "Install completed successfully.`r`nHave fun!"
                    $label_status.Refresh()
                }
                elseif ($canToast) {
                    New-PopUp -msg "INSTALL FAILED! Join the discord for help" -icon "Warning"
                    $label_status.ForeColor = "#ff0000"
                    $label_status.text = "Install Failed!!.`r`nClick the discord link below for help."
                    $label_status.Refresh()
                    $button_install.Enabled = $True
                }

            } elseif ( ($task -eq $taskArgs) -and $canToast) {
                # already configured correctly
                New-PopUp -msg "Install was already completed. Everything looks good, have fun!" -icon "Info"
                $goodInstall = $True
                $label_status.ForeColor = "#7CFC00"
                $label_status.text = "Install was already completed.`r`nEverything looks good, have fun!"
                $label_status.Refresh()
            }
        } else {
            New-CdTask
            Start-Sleep -Seconds 1
            New-Check
            Start-Sleep -Seconds 1
            if ( ($task -eq $taskArgs) -and $canToast ) {
                New-PopUp -msg "Install completed successfully. Have fun!" -icon "Info"
                $goodInstall = $True
                $label_status.ForeColor = "#7CFC00"
                $label_status.text = "Install completed successfully.`r`nHave fun!"
                $label_status.Refresh()
            }
            elseif ($canToast) {
                New-PopUp -msg "Install Failed! Join the discord for help" -icon "Warning"
                $label_status.ForeColor = "ff0000"
                $label_status.text = "Install Failed!`r`nClick the Discord link below for help."
                $label_status.Refresh()
                $button_install.Enabled = $True
            }
        }
    }

    # cd mappings
    # https://wowpedia.fandom.com/wiki/TradeSkillLineID
    $profName = @('alchemy','tailoring','engineering','enchanting','jewelcrafting','inscription','leatherworking','blacksmithing')
    $profID   = @(2823,2831,2827,2825,2829,2828,2830,2822)
    $baseUrl  = "https://render.worldofwarcraft.com/us/icons/56/"
    $map = for ($i = 0; $i -lt $profName.count; $i++) {
        [pscustomobject]@{
            ID   = $profID[$i]
            Name = $profName[$i]
            Icon = $baseUrl + 'ui_profession_' + $profName[$i] + ".jpg"
        }
    }

    # addon data
    $conInfo = @()
    $addonData = Get-Content -Raw $set.addonLuaPath

    if ($set.charNames -ne "all") {
        $set.charNames = $set.charNames | select -Unique

        foreach ($server in $set.realmNames) {

            foreach ($toon in $set.charNames) {

                #$filter = $waData -match ''+$toon+'_'+$server+'.*,'
                $filter = Select-String -Pattern "\[`"$($toon)_$server.*," -InputObject $addonData -AllMatches | % {$_.matches}

                if ($filter) {
                    $filter | Foreach {
                        $split = $_.Value.split('"')
                        $Id = $split[1].Split('_')[2]

                        $mapMatch = $map | ? {$_.ID -eq $Id}
                        # add expiration info into PS object
                        $conInfo += [psCustomObject]@{
                            'name' = $split[3].Split(' ')[0]
                            'id'   = $Id
                            'conAmount' = $split[3].Split('_')[1]
                            'time' = ([datetimeoffset]::FromUnixTimeSeconds($split[3].Split('_')[2])).UtcDateTime
                            'realm' = $split[1].Split('_')[1]
                            'char' = $split[1].Split('_')[0]
                            'icon' = $mapMatch.Icon
                            'link' = "https://www.wowhead.com/skill=" + $ID
                            'alertTime' = $set.alertTime
                            'interval' = $set.interval
                            'intervalTime' = $set.intervalTime
                            'keepBuggingMe' = $set.keepBuggingMe
                            'discordWebhook' = $set.discordWebhook
                            'timeOffset' = ([datetimeoffset]::now).Offset.Hours
                        }
                    }
                }
            } 
        }
    } else {
        # get em all
        $filter = Select-String -Pattern '\[\".*,' -InputObject $addonData -AllMatches | % {$_.matches}
        if ($filter) {
            $filter | Foreach {
                $split = $_.Value.split('"')
                $Id = $split[1].Split('_')[2]

                $mapMatch = $map | ? {$_.ID -eq $Id}
                # add expiration info into PS object
                $conInfo += [psCustomObject]@{
                    'name' = $split[3].Split(' ')[0]
                    'id'   = $Id
                    'conAmount' = $split[3].Split('_')[1]
                    'time' = ([datetimeoffset]::FromUnixTimeSeconds($split[3].Split('_')[2])).UtcDateTime
                    'realm' = $split[1].Split('_')[1]
                    'char' = $split[1].Split('_')[0]
                    'icon' = $mapMatch.Icon
                    'link' = "https://www.wowhead.com/skill=" + $ID
                    'alertTime' = $set.alertTime
                    'interval' = $set.interval
                    'intervalTime' = $set.intervalTime
                    'keepBuggingMe' = $set.keepBuggingMe
                    'discordWebhook' = $set.discordWebhook
                    'timeOffset' = ([datetimeoffset]::now).Offset.Hours
                }
            }
        }
    }

    if ($conInfo) {

        # get current time
        $timeNow = ((Get-Date).ToUniversalTime())
        
        # determine if concentration is coming up. Alert if it is less than the $alertTime
        foreach ($i in $conInfo) {

            # rate limit
            Start-Sleep -Seconds 1
            # allows the script to continue to alert even after it is off CD. 
            if ($i.keepBuggingMe -eq $True) {$bugMe = -1440} else {$bugMe = 0} # 1 days, don't bug them longer than that. lol

            $i.conAmount = [int]$i.conAmount
            if ($i.conAmount -lt 1000) {
                $minutesTillFull = ((1000 - $i.conAmount) / $conMath )
                $concentrationFullDate = ([DateTime]$i.time).AddMinutes($minutesTillFull)
                $diff = $concentrationFullDate - $timeNow
                $localTime = $concentrationFullDate.AddHours($i.timeOffset)
                $currentConAmount = [Math]::Round($i.conAmount + (($timeNow - $i.time).TotalMinutes * $conMath))
                $maxed = $False
            } else {
                $maxed = $True
            }

            if ( ($diff.TotalMinutes -ge $bugMe) -and ($diff.TotalMinutes -le $i.alertTime) -and ($maxed -eq $False)) {
                # Send discord alert. Less than $alertTime until CD is ready! Also need to check if there is no time or its off cd type situation. -UFormat %r if we just want the time and not date. Time is UTC now to use UTC from remote computer.
                # newline also works with: $(0x0A -as [char])
                if ( ($i.keepBuggingMe -eq $True) -and ($diff -le 0) -and ($i.interval -eq $True) ) {
                    Send-Discord -discordWebhook $set.discordWebhook -icon $i.Icon -title "$($i.name) Concentration is full!" -color "15548997" -msg "**Time is money, friend!** `
                    **Current Concentration:** 1000 `
                    **Was full at:** $(Get-Date $localTime -F g)" -link $i.link -footer "$($i.char) | $($i.Realm)"
                } elseif ($diff -ge 0) {
                    Send-Discord -discordWebhook $set.discordWebhook -icon $i.Icon -title "$($i.name) Concentration is almost full!" -color "16776960" -msg "**Current concentration:** $($currentConAmount) `
                    **Time until full:** $( if($diff.days -gt 0) {"$($diff.days)d "}) $( if($diff.hours -gt 0) {"$($diff.hours)h "}) $( if($diff.minutes -gt 0) {"$($diff.minutes)m"}) $( if(($diff.minutes -le 0) -and ($diff.hours -le 0) -and ($diff.days -le 0)){"$($diff.seconds)s"}) `
                    **Full at:** $(Get-Date $localTime -F g)" -link $i.link -footer "$($i.char) | $($i.Realm)"
                }
            }
            else {
                # Don't alert yet
            }

        }
    }
}
# run it if from task
if ($runFromTask) {Start-WowConcentrationAlert}

# remove task
Function Remove-WoWConcentrationAlert {

    # Disable buttons and clear status
    $button_uninstall.Enabled = $False
    $label_status.ForeColor = "#ffff00"
    $label_status.text = "Uninstalling .."
    $label_status.Refresh()
    Start-Sleep -Seconds 1

    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Start-Sleep -Seconds 1
    New-Check
    if ($checkTask -and $canToast) {
        New-PopUp -msg "Uninstall Failed. Please manually check and remove scheduled task" -icon "Warning"
            $label_status.ForeColor = "ff0000"
            $label_status.text = "Uninstall Failed!`r`nPlease manually check and remove scheduled task."
            $label_status.Refresh()
            $button_uninstall.Enabled = $True
    }
    elseif (!$checkTask -and $canToast) {
        New-PopUp -msg "Uninstall completed! Scheduled task has been removed" -icon "Info"
        $label_status.ForeColor = "#7CFC00"
        $label_status.text = "Uninstall completed!`r`nScheduled task has been removed."
        $label_status.Refresh()
    }
    Return
}

if ($canToast) {
    # Form section
    Add-Type -AssemblyName System.Windows.Forms, PresentationFramework, PresentationCore, WindowsBase, System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    # built-in logo
    # To convert use: [Convert]::ToBase64String((Get-Content -Path .\image.png -Encoding Byte))
    $WotlkLogoBase64Img  = "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"
    $WotlkIconBase64Img  = "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"

    # decode base64 images
    function DecodeBase64Image {
        param ([Parameter(Mandatory=$true)][String]$ImageBase64)
        $ObjBitmapImage = New-Object System.Windows.Media.Imaging.BitmapImage #Provides a specialized BitmapSource that is optimized for loading images using Extensible Application Markup Language (XAML).
        $ObjBitmapImage.BeginInit() #Signals the start of the BitmapImage initialization.
        $ObjBitmapImage.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($ImageBase64) #Creates a stream whose backing store is memory.
        $ObjBitmapImage.EndInit() #Signals the end of the BitmapImage initialization.
        $ObjBitmapImage.Freeze() #Makes the current object unmodifiable and sets its IsFrozen property to true.
        $ObjBitmapImage
    }

    #images
    $wotlkImgDecoded = DecodeBase64Image -ImageBase64 $WotlkLogoBase64Img
    $logo = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($wotlkImgDecoded.StreamSource)

    # built-in Icon
    $iconBase64      = $WotlkIconBase64Img
    $iconBytes       = [Convert]::FromBase64String($IconBase64)
    $stream          = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
    $stream.Write($iconBytes, 0, $iconBytes.Length);

    # main form
    $form                           = New-Object System.Windows.Forms.Form
    $form.Text                      ='WoW Concentration Alert'
    $form.Width                     = 300
    $form.Height                    = 180
    $form.AutoSize                  = $True
    $form.MaximizeBox               = $False
    $form.BackColor                 = "#4a4a4a"
    $form.TopMost                   = $False
    $form.StartPosition             = 'CenterScreen'
    $form.FormBorderStyle           = "FixedDialog"
    $form.MinimizeBox               = $False
    $form.Icon                      = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())

    # install Button
    $button_install                   = New-Object system.Windows.Forms.Button
    $button_install.BackColor         = "#f5a623"
    $button_install.text              = "Install"
    $button_install.width             = 120
    $button_install.height            = 50
    $button_install.location          = New-Object System.Drawing.Point(85,15)
    $button_install.Font              = 'Microsoft Sans Serif,11,style=Bold'
    $button_install.FlatStyle         = "Flat"
    if ($gui -eq "install") {$button_install.Enabled = $True} else{$button_install.Enabled = $False}
    if ($gui -eq "install") {$button_install.Visible = $True} else{$button_install.Visible = $False}

    # uninstall Button
    $button_uninstall                    = New-Object system.Windows.Forms.Button
    $button_uninstall.BackColor          = "#f5a623"
    $button_uninstall.ForeColor          = "#FF0000"
    $button_uninstall.text               = "Uninstall"
    $button_uninstall.width              = 120
    $button_uninstall.height             = 50
    $button_uninstall.location           = New-Object System.Drawing.Point(85,15)
    $button_uninstall.Font               = 'Microsoft Sans Serif,11,style=Bold'
    $button_uninstall.FlatStyle          = "Flat"
    if ($gui -eq "uninstall") {$button_uninstall.Enabled = $True} else{$button_uninstall.Enabled = $False}
    if ($gui -eq "uninstall") {$button_uninstall.Visible = $True} else{$button_uninstall.Visible = $False}

    # Status label
    $label_status                   = New-Object system.Windows.Forms.Label
    $label_status.text              = ""
    $label_status.AutoSize          = $True
    $label_status.width             = 30
    $label_status.height            = 20
    $label_status.location          = New-Object System.Drawing.Point(5,75)
    $label_status.Font              = 'Microsoft Sans Serif,10,style=Bold'
    $label_status.ForeColor         = "#7CFC00"

    # version link
    $label_version            = New-Object system.Windows.Forms.LinkLabel
    $label_version.text       = $version
    $label_version.AutoSize   = $True
    $label_version.width      = 30
    $label_version.height     = 20
    $label_version.location   = New-Object System.Drawing.Point(5,132)
    $label_version.Font       = 'Microsoft Sans Serif,9,'
    $label_version.ForeColor  = "#00ff00"
    $label_version.LinkColor  = "#f5a623"
    $label_version.ActiveLinkColor = "#f5a623"
    $label_version.add_Click({[system.Diagnostics.Process]::start("https://github.com/ninthwalker/ConcentrationAlert")})

    # Help link
    $label_help                     = New-Object system.Windows.Forms.LinkLabel
    $label_help.text                = "Get Help (Discord)"
    $label_help.AutoSize            = $true
    $label_help.width               = 80
    $label_help.height              = 30
    $label_help.location            = New-Object System.Drawing.Point(185,132)
    $label_help.Font                = 'Microsoft Sans Serif,9'
    $label_help.ForeColor           = "#00ff00"
    $label_help.LinkColor           = "#f5a623"
    $label_help.ActiveLinkColor     = "#f5a623"
    $label_help.add_Click({[system.Diagnostics.Process]::start("https://discord.com/invite/gjjA8M8KX8")})

    # debug text
    $label_debug            = New-Object system.Windows.Forms.LinkLabel
    $label_debug.text       = "Debug"
    $label_debug.AutoSize   = $True
    $label_debug.width      = 30
    $label_debug.height     = 20
    $label_debug.location   = New-Object System.Drawing.Point(85,132)
    $label_debug.Font       = 'Microsoft Sans Serif,9,'
    $label_debug.ForeColor  = "#00ff00"
    $label_debug.LinkColor  = "#f5a623"
    $label_debug.ActiveLinkColor = "#f5a623"

    $pictureBox_logo                 = New-Object system.Windows.Forms.PictureBox
    $pictureBox_logo.width           = 80
    $pictureBox_logo.height          = 80
    $pictureBox_logo.location        = New-Object System.Drawing.Point(20,16)
    $pictureBox_logo.image           = $logo
    $pictureBox_logo.SizeMode        = [System.Windows.Forms.PictureBoxSizeMode]::normal

    # add all controls
    $form.Controls.AddRange(($button_install,$button_uninstall,$label_status,$label_version,$label_help,$label_debug,$pictureBox_logo))

    # Button methods
    $button_install.Add_Click({Start-WowConcentrationAlert})
    $button_uninstall.Add_Click({Remove-WoWConcentrationAlert})
    $label_debug.add_Click({
        Start-Debug
        $form.Dispose()
    })

    # show the forms
    $form.ShowDialog()

    # close the forms
    $form.Dispose()
}
