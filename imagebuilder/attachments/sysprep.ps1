"& $Env:SystemRoot\System32\Sysprep\Sysprep.exe /oobe /generalize /quiet; echo Sysprep Exit Code is $errorlevel"
Write-Output "Powershell Exit Code is $LastExitCode, $?"
