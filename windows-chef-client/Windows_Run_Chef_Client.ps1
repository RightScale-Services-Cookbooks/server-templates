# ---
# RightScript Name: Windows Run Chef Client
# Description: Run Chef Client
# Inputs:
#   CHEF_CLIENT_ENVIRONMENT:
#     Category: CHEF
#     Description: 'Specify the environment type for the Chef Client configuration file.
#       Example: development'
#     Input Type: single
#     Required: false
#     Advanced: false
#     Default: text:_default
#   CHEF_CLIENT_ROLES:
#     Category: CHEF
#     Description: 'Comma-separated list of roles which will be applied to this instance.
#       The Chef Client will execute the roles in the order specified here. Example:
#       webserver, monitoring'
#     Input Type: single
#     Required: false
#     Advanced: false
#   CHEF_CLIENT_RUNLIST:
#     Category: CHEF
#     Description: 'A string used to set the permanent run_list for chef-client. If
#       set, this overrides chef/client/roles. Example: recipe[ntp::default], recipe[apache2],
#       role[foobar]'
#     Input Type: single
#     Required: false
#     Advanced: false
#   CHEF_CLIENT_NODE_NAME:
#     Category: CHEF
#     Description: 'Name which will be used to authenticate the Chef Client on the remote
#       Chef Server. If nothing is specified, the instance FQDN will be used. Example:
#       chef-client-host1'
#     Input Type: single
#     Required: false
#     Advanced: false
#   CHEF_CLIENT_COMPANY:
#     Category: CHEF
#     Description: 'Company name to be set in the Client configuration file. This attribute
#       is applicable for Opscode Hosted Chef Server. The company name specified in
#       both the Server and the Client configuration file must match. Example: MyCompany'
#     Input Type: single
#     Required: false
#     Advanced: true
# Attachments: []
# ...
# Powershell RightScript to install chef client

# Stop and fail script when a command fails.
$errorActionPreference = "Stop"

######## INPUT validation ############
if (!$env:CHEF_CLIENT_NODE_NAME) {
  $env:CHEF_CLIENT_NODE_NAME=${env:computername}
  Write-Output("*** Input CHEF_CLIENT_NODE_NAME is undefined, using: $env:CHEF_CLIENT_NODE_NAME")
}
if ($env:CHEF_CLIENT_NODE_NAME -notmatch "^[\w -:\.]+$") {
  throw "*** ERROR: Input CHEF_CLIENT_NODE_NAME($env:CHEF_CLIENT_NODE_NAME) is invalid, aborting..."
}

$finalRunList=@()

if ($env:CHEF_CLIENT_ROLES) {
  foreach($role in $env:CHEF_CLIENT_ROLES.Split(',')) {
    $finalRunList+='"role['+$role.trim()+']"'
  }
}

if ($env:CHEF_CLIENT_RUNLIST) {
  foreach($runListItem in $env:CHEF_CLIENT_RUNLIST.Split(',')) {
    $finalRunList+='"'+$runListItem.trim()+'"'
  }
}

$finalRunListString=[string]::join(',',$finalRunList)

Write-Output("*** Creating $(join-path $chefDir 'runlist.json')")
echo @"
/*
# Managed by RightScale
# DO NOT EDIT BY HAND
#*/
{
  "name": "$env:CHEF_CLIENT_NODE_NAME",
  "normal": {
    "company": "$env:CHEF_CLIENT_COMPANY",
    "tags": [
    ]
  },
  "chef_environment": "$env:CHEF_CLIENT_ENVIRONMENT",
  "run_list": [$finalRunListString]
}
"@ | out-file -encoding 'ASCII' $(join-path $chefDir 'runlist.json')

if(!(Test-Path "C:\opscode\chef\embedded\bin\ruby.exe")) {
 throw "*** ERROR: Ruby.exe is missing!"
}
elseif (!(Test-Path "C:\opscode\chef\bin\chef-client")) {
  throw "*** ERROR: Chef-Client is missing!"
}
else {
  Write-Output("*** Executing chef-client")
  Start-Process -FilePath 'C:\opscode\chef\embedded\bin\ruby.exe' -ArgumentList 'C:\opscode\chef\bin\chef-client','--json-attributes C:\chef\runlist.json' -Wait
}
