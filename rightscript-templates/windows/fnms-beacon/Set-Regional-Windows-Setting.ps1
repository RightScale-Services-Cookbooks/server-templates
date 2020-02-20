# ---
# RightScript Name: RL10 Set System Locale
# Description: Runs Windows Update Client
# Inputs: {}
# Attachments: []
# ...

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
Param()

$errorActionPreference = 'stop'

Set-Culture en-US
Set-WinSystemLocale -SystemLocale en-US
Set-WinUILanguageOverride -Language en-US
Set-WinUserLanguageList en-US -Force
Set-WinHomeLocation -GeoId 244

. \Handle-Reboot.ps1
Set-Reboot