# https://www.powershellmagazine.com/2015/10/12/powershell-tools-for-the-advanced-use-cases-part-1/
try {
  Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
}
catch {
   Write-Error -Message $_
   exit 1
}

try {
    $rules = Get-ScriptAnalyzerRule -Severity Warning,Error -ErrorAction Stop
    $results = Invoke-ScriptAnalyzer -Path $Args[0] -IncludeRule $rules.RuleName -Recurse -ErrorAction Stop
    $results
}
catch {
    Write-Error -Message $_
    exit 1
}
if ($results.Count -gt 0) {
    Write-Output "Analysis of your code threw $($results.Count) warnings or errors. Please go back and check your code."
    exit 1
}
else {
    Write-Output 'Awesome code! No issues found!'
}