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

mkdir -Force "$rootDir\tmp"
powershell -Command "Import-Module $pesterScript; Invoke-Pester $pathPatten -OutputXml '$rootDir\tmp\test-result.xml' -EnableExit"


# & Powershell -noprofile -NonInteractive -command {
#     param($pester, $pathPatten, $fixturesDir)
#     Import-Module $pesterScript
#     Invoke-Pester $pathPatten -EnableExit
# } -args $pesterScript, $pathPatten, $fixturesDir

if ($LASTEXITCODE -ne 0) {
    throw "Job run powershell test failed."
}