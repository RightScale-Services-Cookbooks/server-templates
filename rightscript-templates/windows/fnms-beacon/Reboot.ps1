# ---
# RightScript Name: RL10 Handle Reboot
# Description: Runs Windows Update Client
# Inputs: {}
# Attachments:
# - Handle-Reboot.ps1
# ...

.\Handle-Reboot.ps1

if (Get-Rebooted){
  return $true
} else {
  Invoke-Reboot
}