# ---
# RightScript Name: RL10 Enable and Run Windows Update
# Description: Check whether a RightLink upgrade is available and perform the upgrade.
# Inputs: {}
# Attachments: []
# ...

$errorActionPreference = 'stop'
$WuaClient = "C:\Windows\System32\wuauclt.exe"
$UsoClient = "C:\Windows\System32\UsoClient.exe"

function Invoke-WuaClient{
  Write-Output "Running WuaClient"
  Start-Process -FilePath $WuaClient -RedirectStandardOutput stdout.txt -RedirectStandardError stderr.txt -Wait -ArgumentList '/DetectNow','/UpdateNow'
  Get-Content stdout.txt
  Get-Content stderr.txt
}

function Invoke-UsoClient{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [string]$switch
  )
  Write-Output "Running UsoClient with Switch:"$switch
  Start-Process -FilePath $UsoClient -RedirectStandardOutput stdout.txt -RedirectStandardError stderr.txt -Wait -ArgumentList $switch
  Get-Content stdout.txt
  Get-Content stderr.txt
}

function Start-UsoClient{
  Invoke-UsoClient "startscan"
  Invoke-UsoClient "startdownload"
  Invoke-UsoClient "startinstall"
}

switch($PSVersionTable.PSVersion.Major){
  4 {
    if (Test-Path $WuaClient){
      Invoke-WuaClient
    } elseif (Test-Path $UsoClient){
      Start-UsoClient
    } else {
      Write-Output "No Update Clients Found"
      exit 1
    }
  }
  5 {
    if (Test-Path $WuaClient){
      Invoke-WuaClient
    } elseif (Test-Path $UsoClient){
      Start-UsoClient
    } else {
      Write-Output "No Update Clients Found"
      exit 1
    }
  }
  6 {
      Install-Module -Force -SkipPublisherCheck -Scope CurrentUser -Name PSWindowsUpdate
      Get-WindowsUpdate
      Install-WindowsUpdate
  }
}