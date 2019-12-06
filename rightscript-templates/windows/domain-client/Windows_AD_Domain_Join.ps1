# ---
# RightScript Name: Windows AD Domin Join
# Description: This script will join the server to the domain.  Review required INPUTS
#   before executing.
# Inputs:
#   AD_NEW_SERVER_NAME:
#     Category: System
#     Input Type: single
#     Required: true
#     Advanced: false
#   AD_OU_NAME:
#     Category: System
#     Input Type: single
#     Required: false
#     Advanced: false
#   AD_ADMIN_PASSWORD:
#     Category: System
#     Description: AD Admin password
#     Input Type: single
#     Required: true
#     Advanced: false
#   AD_ADMIN_USERNAME:
#     Category: System
#     Description: User that has the ability to add and remove computers from the domain
#     Input Type: single
#     Required: true
#     Advanced: false
#   AD_DOMAIN_NAME:
#     Category: System
#     Description: Domain name
#     Input Type: single
#     Required: true
#     Advanced: false
#   COMPUTER_DESCRIPTION:
#     Category: System
#     Description: Computer description
#     Input Type: single
#     Required: false
#     Advanced: false
# Attachments: []
# ...
$errorActionPreference = 'stop'
$ComputerDomain = Get-WmiObject Win32_Computersystem | Select-Object -ExpandProperty Domain

$AD_Secure_Password = ConvertTo-SecureString $ENV:AD_ADMIN_PASSWORD -AsPlainText -Force
$AD_Credential = New-Object System.Management.Automation.PSCredential $ENV:AD_ADMIN_USERNAME,$AD_Secure_Password

$IsJoined = $ComputerDomain -match $ENV:AD_DOMAIN_NAME
$IsRenamed = $($ENV:COMPUTERNAME) -match $($ENV:AD_NEW_SERVER_NAME)

$reboot = 0

# Test to see if this is a comment
#############
# Functions
#############
function Test-RegistryValueExists {
    param (  
      [parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]$Path,  
      [parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]$Value
    )  
    try {  
    Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
      return $true
    }
    
    catch {
      return $false
    }
    
  }
function Add-InstanceTag() {
    param (
        [string]$Tag
    )

    $currentTags = (rsc --rl10 cm15 by_resource /api/tags/by_resource "resource_hrefs[]=$ENV:RS_SELF_HREF" | ConvertFrom-Json).tags | Select-Object -ExpandProperty name

    if(!($currentTags -contains $Tag)) {
        # Use the RL10 proxy to access the api
        try {
            rsc --rl10 cm15 multi_add /api/tags/multi_add "resource_hrefs[]=$ENV:RS_SELF_HREF" "tags[]=$Tag"
            Write-Output "Tag set: $Tag"
        }
        catch {
          Write-Output "ERROR! Problem settings tag: $Tag"
        }
    }
    else {
        Write-Output "Tag is already set[$Tag]. Skipping!"
    }

}

##################
if($ENV:COMPUTER_DESCRIPTION) {
    Write-Output "JOIN_DOMAIN:  Setting Computer Description"
    $OS = Get-WmiObject -Class Win32_OperatingSystem
    $OS.Description = $ENV:COMPUTER_DESCRIPTION
    $OS.Put() | Out-Null
}

if ($ENV:AD_NEW_SERVER_NAME.length -ge 1) {
    if ($IsRenamed) {
        Write-Output "JOIN_DOMAIN:  $($ENV:COMPUTERNAME) is already $($ENV:AD_NEW_SERVER_NAME)."
    }
    else {
        if($ENV:COMPUTER_DESCRIPTION) {
            Write-Output "JOIN_DOMAIN:  Setting Computer Description"
            $OS = Get-WmiObject -Class Win32_OperatingSystem
            $OS.Description = $ENV:COMPUTER_DESCRIPTION
            $OS.Put() | Out-Null
        }

        Write-Output "JOIN_DOMAIN:  Renaming $($ENV:COMPUTERNAME) to $($ENV:AD_NEW_SERVER_NAME)."

        if ($IsJoined) {
            $Rename = Rename-Computer -NewName $($ENV:AD_NEW_SERVER_NAME) -DomainCredential $AD_Credential -PassThru
        }
        else {
            $Rename = Rename-Computer -NewName $($ENV:AD_NEW_SERVER_NAME) -PassThru
        }

        $Renamed = $Rename.HasSucceeded

        if ($Renamed) {
            Write-Output "JOIN_DOMAIN:  $($ENV:COMPUTERNAME) has been renamed to $($ENV:AD_NEW_SERVER_NAME)."
            Write-Output "JOIN_DOMAIN:  Continuing to joing the domain."
        }
        else {
            Write-Output "JOIN_DOMAIN:  $($ENV:COMPUTERNAME) was not renamed.  Exiting script"
            Write-Output "JOIN_DOMAIN:  $($_.Exception.Message)"
            Exit 1
        }
    }
}

if ($IsJoined) {
    Write-Output "JOIN_DOMAIN:  $($ENV:COMPUTERNAME) is already part of $($ENV:AD_DOMAIN_NAME)."
    Write-Output "JOIN_DOMAIN:  No work to do."
}
else {
    
    $IsKMSHardCoded = Test-RegistryValueExists -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" -Value "KeyManagementServiceName"
    if($true -eq $IsKMSHardCoded){
        #Remove the HardCoded MicrosoftKMS Servers from the registry
        try{
            Write-Output "JOIN_DOMAIN: Remove the HardCoded MicrosoftKMS Servers from the registry"
            Write-Output "JOIN_DOMAIN: Removing Registry Key [KeyManagementServiceName] located at HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
            Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" -Name "KeyManagementServiceName"
            Write-Output "JOIN_DOMAIN: Removing Registry Key [KeyManagementServicePort] located at HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
            Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" -Name "KeyManagementServicePort"
        }
        catch{
            Write-Error -Message "Error removing hardcoded KMS servers from the registry.  Throwing this error rather than allowing it to continue"
        }
    }
    
    Write-Output "JOIN_DOMAIN:  $($ENV:COMPUTERNAME) is not part of $($ENV:AD_DOMAIN_NAME)."
    Write-Output "JOIN_DOMAIN:  Joining $($ENV:COMPUTERNAME) to $($ENV:AD_DOMAIN_NAME)."
    
    Write-Output "JOIN_DOMAIN:  Determining Domain Controller to use..."
    $dcs = Resolve-DNSName $($ENV:AD_DOMAIN_NAME) | Select-Object -ExpandProperty IPAddress
    Write-Output "domainControllers $dcs"
    $domainControllers = @()
    foreach ($dc in $dcs) {
        if(Test-Connection $dc -Count 3 -Quiet) {
            $responseTime = (Test-Connection $dc -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ResponseTime) | Measure-Object -Average | Select-Object -ExpandProperty Average
            $domainControllers += [PSCustomObject]@{
                IP = $dc
                Time = $responseTime
            }
        }
    }
    $theDC = $domainControllers | Select-Object -First 1
    $dcFQDN = ([system.net.dns]::GetHostByAddress($($theDC.IP))).hostname
    Write-Output "JOIN_DOMAIN: $dcFQDN ( IP: $($theDC.IP) )"

    if ($Renamed) {
        if($ENV:AD_OU_NAME) {
        #OU specified
        $Join = Add-Computer -DomainName $($ENV:AD_DOMAIN_NAME) -OUPath $($ENV:AD_OU_NAME) -Server $dcFQDN -Credential $AD_Credential -Options AccountCreate,JoinWithNewName -Force -PassThru
        }
        else {
        #OU not specified
        $Join = Add-Computer -DomainName $($ENV:AD_DOMAIN_NAME) -Credential $AD_Credential -Server $dcFQDN -Options AccountCreate,JoinWithNewName -Force -PassThru
        }
    }
    else {
        if($ENV:AD_OU_NAME) {
        #OU specified
        $Join = Add-Computer -DomainName $($ENV:AD_DOMAIN_NAME) -OUPath $($ENV:AD_OU_NAME) -Server $dcFQDN -Credential $AD_Credential -Force -PassThru
        }
        else {
        #OU not specified
        $Join = Add-Computer -DomainName $($ENV:AD_DOMAIN_NAME) -Credential $AD_Credential -Server $dcFQDN -Force -PassThru
        }
    }

    $Joined = $Join.HasSucceeded
    if ($Joined) {
        Write-Output "JOIN_DOMAIN:  $($ENV:COMPUTERNAME) has joined $($ENV:AD_DOMAIN_NAME)."
       
        #Set reboot flag
        $reboot++
        Add-InstanceTag -Tag "rs_ad:domain=$($ENV:AD_DOMAIN_NAME)"
    }
    else {
        Write-Output "JOIN_DOMAIN:  $($ENV:COMPUTERNAME) was not joined to $($ENV:AD_DOMAIN_NAME)."
        Write-Output "JOIN_DOMAIN:  $($_.Exception.Message)"
    }
}

if ($Renamed -and !$Joined) {
    Write-Output "JOIN_DOMAIN:  $($ENV:COMPUTERNAME) was renamed, but not rejoined to the domain. Rebooting to finalize the rename."
    #Set reboot flag
    $reboot++
}

if($reboot -gt 0) {
    Write-Output "JOIN_DOMAIN:  Rebooting."  
    # Reboot during boot sequence - http://docs.rightscale.com/rl10/reference/10.6.0/rl10_script_execution.html#background-decommission-runlist
    Restart-Computer -Force -AsJob
    try { Start-Sleep 60 } finally { Start-Sleep 60 }
}
