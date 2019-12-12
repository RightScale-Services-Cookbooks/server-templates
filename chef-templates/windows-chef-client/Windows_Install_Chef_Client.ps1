# ---
# RightScript Name: Windows Install Chef Client
# Description: Install Chef Client - Rightscale, All Rights Reserved.  Revision by Matt Hedges, Datacenter Architect, Flair Data Systems.  
# Inputs:
#   CHEF_CLIENT_PROJECT:
#     Category: CHEF
#     Description: 'Defines the Omnitruck project base product to install.  Default is chef.'
#     Input Type: single
#     Required: true
#     Advanced: false
#     Default: text:chef
#   CHEF_CLIENT_CHANNEL:
#     Category: CHEF
#     Description: 'Defines the Omnitruck project base channel to use for the installation.  Default is stable.'
#     Input Type: single
#     Required: true
#     Advanced: true
#     Default: text:stable
#     Possible Values:
#      - text:current
#      - text:stable
#      - text:unstable
#   CHEF_CLIENT_ARCHITECTURE:
#     Category: CHEF
#     Description: 'Defines the Omnitruck architecture for the installation.  Default is auto.'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:auto
#     Possible Values:
#      - text:auto
#      - text:i386
#      - text:x86_64
#   CHEF_CLIENT_DAEMON:
#     Category: CHEF
#     Description: 'Defines the Omnitruck daemon configuration for the installation.  Default is auto.'
#     Input Type: single
#     Required: false
#     Advanced: true
#     Default: text:auto
#     Possible Values: 
#      - text:auto
#      - text:service
#      - text:task
# Attachments: []
# ...

# Powershell RightScript to install chef client

# Stop and fail script when a command fails.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
Param()

$errorActionPreference = "Stop"

if (test-path C:\opscode -PathType Container) {
  Write-Output "*** Directory C:\opscode already exists, skipping install..."
  exit 0
}

$chefDir="C:\chef"
if (test-path $chefDir -PathType Container) {
  Write-Output "*** Directory $chefDir already exists, skipping install..."
  exit 0
}
else {
  Write-Output "*** Creating $chefDir ..."
  New-Item $chefDir -type directory | Out-Null
}

Write-Output("*** Installing chef client msi and waiting for the prompt")
. { Invoke-WebRequest -UseBasicParsing https://omnitruck.chef.io/install.ps1 } | Invoke-Expression; Install-Project $env:CHEF_CLIENT_PROJECT -channel $env:CHEF_CLIENT_CHANNEL -architecture $env:CHEF_CLIENT_ARCHITECTURE -daemon $env:CHEF_CLIENT_DAEMON
