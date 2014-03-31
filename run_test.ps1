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

$x = & Powershell -noprofile -NonInteractive -command {
    param($pester, $pathPatten, $fixturesDir)
    write-host "pester: $pester"
    Import-Module $pester
    Invoke-Pester $pathPatten -EnableExit
} -args $pester, $pathPatten, $fixturesDir

write-host "aaa"
write-host "$x"
write-host $LASTEXITCODE
write-host "bbb"

if ($LASTEXITCODE -ne 0) {
    throw "Job run powershell test failed."
}