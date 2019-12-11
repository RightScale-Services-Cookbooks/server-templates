# ---
# RightScript Name: Windows Install Powershell 6
# Description: Check whether a RightLink upgrade is available and perform the upgrade.
# Inputs:{}
# Attachments: []
# ...
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
Param()

$errorActionPreference = 'stop'

Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet -AddExplorerContextMenu"