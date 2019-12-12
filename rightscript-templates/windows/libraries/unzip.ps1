#https://www.howtogeek.com/tips/how-to-extract-zip-files-using-powershell/
function Expand-ZIPFile {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory=$true)]
      [string]$File, 
      [Parameter(Mandatory=$true)]
      [string]$Destination
      )

  $shell = New-Object -com shell.application
  $zip = $shell.NameSpace($file)
  foreach($item in $zip.items()) {
      $shell.Namespace($destination).copyhere($item)
  }
}