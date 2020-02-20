# ---
# RightScript Name: RL10 Configure Beacon For Proxy
# Description: Configure Beacon For Proxy
# Inputs:
#   BEACON_PROXY:
#     Category: Beacon
#     Description: Proxy Server
#     Input Type: single
#     Required: false
#     Advanced: false
# Attachments: []
# ...

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
Param()

$errorActionPreference = 'stop'

if ( $null -ne $env:BEACON_PROXY ){
  $https_url = "https://" + $env:BEACON_PROXY
  $http_url = "http://" + $env:BEACON_PROXY

  Set-ItemProperty -Path "HKLM:SOFTWARE\Wow6432Node\ManageSoft Corp\ManageSoft\Common" `
    -Type String `
    -Name "https_proxy" `
    -Value $https_url

  Set-ItemProperty -Path "HKLM:SOFTWARE\Wow6432Node\ManageSoft Corp\ManageSoft\Common\DownloadSettings\ReplicatorParent" `
    -Type String `
    -Name "proxy" `
    -Value $https_url

  Set-ItemProperty -Path "HKLM:SOFTWARE\Wow6432Node\ManageSoft Corp\ManageSoft\Common\UploadSettings\ReplicatorParent" `
    -Type String `
    -Name "proxy" `
    -Value $https_url

  Set-ItemProperty -Path "HKLM:SOFTWARE\Wow6432Node\ManageSoft Corp\ManageSoft\Launcher\CurrentVersion" `
    -Type String `
    -Name "https_proxy" `
    -Value $http_url
}
