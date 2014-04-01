param($pathPatten='.\test*')
$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

trap {
    write-host "Error found: $_" -f red
    exit 1
}

$nuget = "$rootDir\tools\nuget\nuget.exe"
$pesterDir = "$rootDir\tools\Pester.2.0.4"

$pesterScript = (Get-ChildItem "$pesterDir" pester.psm1 -recurse).FullName
$Error.clear()

$fixturesDir = "$rootDir\test\test-fixtures"


# Import-Module $pester
# Invoke-Pester $pathPatten -OutputXml "tmp\test-result.xml" -EnableExit 


& Powershell -noprofile -NonInteractive -command {
    param($pester, $pathPatten, $fixturesDir)
    write-host "before import"
    Import-Module $pesterScript
    write-host "after import, before pester invoke"
    Invoke-Pester $pathPatten -EnableExit
    write-host "after pester invoke"
} -args $pesterScript, $pathPatten, $fixturesDir | Out-Default

if ($LASTEXITCODE -ne 0) {
    throw "Job run powershell test failed."
}