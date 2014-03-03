$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
. "$root\src-libs\functions\Install-NuPackage.ns.ps1"

Describe "Install-NudeployEnv with DryRun" {

    $nugetRepo = "$TestDrive\nugetRepo"
    New-Item $nugetRepo -type Directory -Force
    $workingDir = "$TestDrive\workingDir"
    $nuget = "$root\tools\nuget\NuGet.exe"

    & $nuget pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -Version "1.0" -o $nugetRepo -NoPackageAnalysis
    $nugetSource = $nugetRepo
    $nodeDeployRoot = "$TestDrive\deployment_root"

    Install-NuPackage -package "NScaffold.NuDeploy" -workingDir $workingDir -version "1.0" -postInstall {
        param($packageDir)
        $nudeployModule = Get-ChildItem $packageDir "nudeploy.psm1" -recurse
        Import-Module $nudeployModule.FullName -Force
    }

    & $nuget pack "$fixturesDir\package_source\test_package.nuspec" -NoPackageAnalysis -Version "1.0" -o $nugetRepo

    It "should not deploy the package" {
        $envConfigFile = "$fixturesDir\config\env.config.ps1"
        [object[]]$appsConfig = Install-NudeployEnv -DryRun $envConfigFile
        $packageRoot = "$nodeDeployRoot\Test.Package\Test.Package.1.0"
        "$packageRoot\fileGeneratedByInstall.txt" | should not exist
    }

    It "should stop deployment when exception is thrown when config miss item" {
        $envConfigFile = "$fixturesDir\config_miss_config_item\env.config.ps1"
        { Install-NudeployEnv $envConfigFile } | should throw
    }

    It "should not deploy packages that have been deployed" {
        $envConfigFile = "$fixturesDir\config\env.config.ps1"
        
        Install-NudeployEnv $envConfigFile        
        Remove-Item $nodeDeployRoot -recurse
        mkdir $nodeDeployRoot
        Install-NudeployEnv $envConfigFile
        "$nodeDeployRoot\Test.Package\Test.Package.1.0" | should not exist
    }
}