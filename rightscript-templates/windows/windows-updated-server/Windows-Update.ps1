# ---
# RightScript Name: RL10 Enable and Run Windows Update
# Description: Runs Windows Update Client
# Inputs: {}
# Attachments: 
# - PSWindowsUpdate.zip
# ...

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
Param()

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

function Expand-ZIPFile {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$File, 
      [Parameter(Mandatory=$true)]
      [string]$Destination
      )

  $shell = New-Object -com shell.application
  $zip = $shell.NameSpace($file)
  foreach($item in $zip.items()) {
      $shell.Namespace($destination).copyhere($item)
  }
}
function Set-WindowsUpdate{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [string]$value
  )
  # 1 - Disable
  # 4 - Enable
  net stop wuauserv
  $Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
  New-ItemProperty -Path $Key -Name "AUOptions" -Value $value -PropertyType "DWord" -Force -Confirm:$false
  Set-ItemProperty -Path $Key -Name "AUOptions" -Value $value -Force -Confirm:$false
  New-ItemProperty -Path $Key -Name "CachedAUOptions" -Value $value -PropertyType "DWord" -Force -Confirm:$false
  Set-ItemProperty -Path $Key -Name "CachedAUOptions" -Value $value -Force -Confirm:$false
  net start wuauserv
}

switch($PSVersionTable.PSVersion.Major){
  4 {
    Set-WindowsUpdate 4
    $psFile = Join-Path -Path $env:RS_ATTACH_DIR -ChildPath 'PSWindowsUpdate.zip'
    Write-Output $psFile
    Expand-ZIPFile -File $psFile -Destination "c:\Windows\System32\WindowsPowerShell\v1.0\Modules"
    Import-Module PSWindowsUpdate
    Get-WUInstall -Verbose -IgnoreUserInput -AcceptAll -AutoReboot
    Set-WindowsUpdate 1
  }
  5 {
    Set-WindowsUpdate 4
    Install-PackageProvider NuGet -Force
    Import-PackageProvider NuGet -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Force -SkipPublisherCheck -Scope CurrentUser -Name PSWindowsUpdate
    Import-Module PSWindowsUpdate
    Get-WindowsUpdate -AcceptAll -AutoReboot -Download -Install -Verbose
    Set-WindowsUpdate 1
  }
  6 {
      Install-Module -Force -SkipPublisherCheck -Scope CurrentUser -Name PSWindowsUpdate
      Import-Module PSWindowsUpdate
      Get-WindowsUpdate -AcceptAll -AutoReboot -Download -Install -Verbose
  }
}
