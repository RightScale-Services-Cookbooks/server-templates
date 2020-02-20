# ---
# RightScript Name: RL10 Install Microsoft Access Database Engine
# Description: Runs Windows Update Client
# Inputs: {}
# Attachments: []
# ...

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
Param()

$errorActionPreference = 'stop'

Invoke-WebRequest -Uri "https://s3.amazonaws.com/fnms-services-installers/AccessDatabaseEngine.exe" -OutFile "c:\AccessDatabaseEngine.exe"
Start-Process -FilePath "c:\AccessDatabaseEngine.exe" -ArgumentList "/quiet" -Wait