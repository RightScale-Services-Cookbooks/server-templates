# ---
# RightScript Name: RL10 Enable TLS 1.2 Protocol
# Description: Runs Windows Update Client
# Inputs: {}
# Attachments:
# - Handle-Reboot.ps1
# ...

$errorActionPreference = 'stop'

# https://github.com/adbertram/Random-PowerShell-Work/blob/master/Random%20Stuff/Test-PendingReboot.ps1
function Test-RegistryKey {
  [OutputType('bool')]
  [CmdletBinding()]
  param
  (
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]$Key
  )

  $ErrorActionPreference = 'Stop'

  if (Get-Item -Path $Key -ErrorAction Ignore) {
      $true
  }
}
if ( Test-RegistryKey "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2" )
{
  Write-Output "Key Found"
} else {
  New-Item -Path "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols" -Name "TLS 1.2"
}
if ( Test-RegistryKey "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client")
{  
  Write-Output "Key Found"
} else {
  New-Item -Path "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2" -Name "Client"
}
if ( Test-RegistryKey "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server")
{
  Write-Output "Key Found"
} else {
  New-Item -Path "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2" -Name "Server"
}

Set-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" `
  -Type DWord `
  -Name "Enabled" `
  -Value "00000001"

Set-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" `
  -Type DWord `
  -Name "DisabledByDefault" `
  -Value "00000000"

Set-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" `
  -Type DWord `
  -Name "Enabled" `
  -Value "00000001"

Set-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" `
  -Type DWord `
  -Name "DisabledByDefault" `
  -Value "00000001"

Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319" `
  -Type DWord `
  -Value "1" `
  -Name "SchUseStrongCrypto"

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319" `
  -Type DWord `
  -Value "1" `
  -Name "SchUseStrongCrypto"

. $env:RS_ATTACH_DIR\Handle-Reboot.ps1
Set-Reboot