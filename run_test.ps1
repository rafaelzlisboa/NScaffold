param($pathPatten='.\test*')
$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

trap {
    write-host "Error found: $_" -f red
    exit 1
}

$nuget = "$rootDir\tools\nuget\nuget.exe"
& $nuget install pester -version "2.0.3" -nocache -OutputDirectory "$rootDir\tools"
$pesterDir = "$rootDir\tools\Pester.2.0.3"

$pester = (Get-ChildItem "$pesterDir" pester.psm1 -recurse).FullName
$Error.clear()

$fixturesDir = "$rootDir\test\test-fixtures"

& Powershell -noprofile -NonInteractive -command {
    param($pester, $pathPatten, $fixturesDir)
    Import-Module $pester
    Invoke-Pester $pathPatten -EnableExit
} -args $pester, $pathPatten, $fixturesDir

if ($LASTEXITCODE -ne 0) {
    throw "Job run powershell test failed."
}