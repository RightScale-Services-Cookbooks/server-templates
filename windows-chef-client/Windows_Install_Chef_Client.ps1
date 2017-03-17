# ---
# RightScript Name: Windows Install Chef Client
# Description: Install Chef Client
# Inputs: {}
# Attachments: []
# ...
# Powershell RightScript to install chef client

# Stop and fail script when a command fails.
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
. { Invoke-WebRequest -UseBasicParsing https://omnitruck.chef.io/install.ps1 } | Invoke-Expression; install
