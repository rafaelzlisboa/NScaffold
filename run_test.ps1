param($pathPatten='.\test*')
$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

trap {
    write-host "Error found: $_" -f red
    exit 1
}

$nuget = "$rootDir\tools\nuget\nuget.exe"
$pesterDir = "$rootDir\tools\Pester.2.0.4"

$pester = (Get-ChildItem "$pesterDir" pester.psm1 -recurse).FullName
$Error.clear()

$fixturesDir = "$rootDir\test\test-fixtures"

write-host "before import"
Import-Module $pester
write-host "after import"

$x = & Powershell -noprofile -NonInteractive -command {
    param($pester, $pathPatten, $fixturesDir)
    write-host "pester: $pester"
    write-host "before import"
    Import-Module $pester
    write-host "after import, before pester invoke"
    Invoke-Pester $pathPatten -EnableExit
    write-host "after pester invoke"
} -args $pester, $pathPatten, $fixturesDir

write-host "------------"
write-host $x
write-host "------------"
write-host $LASTEXITCODE
write-host "------------"

if ($LASTEXITCODE -ne 0) {
    throw "Job run powershell test failed."
}