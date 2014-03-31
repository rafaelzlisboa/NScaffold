$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$nuget = "$rootDir\tools\nuget\nuget.exe"
& $nuget install pester -version "2.0.4" -nocache -OutputDirectory "$rootDir\tools"