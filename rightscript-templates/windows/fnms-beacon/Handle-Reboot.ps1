function Set-Reboot {
  if ( Get-Reboot ){
    return $true
  } else {
    New-Item -Path "c:\\.reboot-needed"
    return $true
  }
}
function Get-Reboot {
  if ( Test-Path -Path "c:\\.reboot-needed" ) {
    return $true
  } else {
    return $false
  }
}
function Get-Rebooted {
  if (Test-Path -Path "c:\\.rebooted"){
    return $true
  } else {
    return $false
  }
}
function Invoke-Reboot {
  # Reboot during boot sequence - http://docs.rightscale.com/rl10/reference/10.6.0/rl10_script_execution.html#background-decommission-runlist
  if (Get-Reboot) {
    New-Item -Path "c:\\.rebooted"
    Restart-Computer -Force -AsJob
    try { Start-Sleep 60 } finally { Start-Sleep 60 }
  } else {
    return $true
  }
}
