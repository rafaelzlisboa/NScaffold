$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
. "$root\src-libs\functions\Install-NuPackage.ns.ps1"
. "$root\src-libs\functions\Import-Config.ns.ps1"

Describe "Install-NudeployEnv" {

    $nodeDeployRoot = "$TestDrive\deployment_root"

    $nugetRepo = "$TestDrive\nugetRepo"
    New-Item $nugetRepo -type Directory -Force
    $workingDir = "$TestDrive\workingDir"
    $nuget = "$root\tools\nuget\NuGet.exe"
    $nugetSource = $nugetRepo

    & $nuget pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -Version "1.0" -o $nugetRepo -NoPackageAnalysis
    Install-NuPackage -package "NScaffold.NuDeploy" -workingDir $workingDir -version "1.0" -postInstall {
        param($packageDir)
        $nudeployModule = Get-ChildItem $packageDir "nudeploy.psm1" -recurse
        Import-Module $nudeployModule.FullName -Force
    }

    Context "normal package" {
        & $nuget pack "$fixturesDir\package_source\test_package.nuspec" -NoPackageAnalysis -Version "1.0" -o $nugetRepo
        It "should deploy the package on the host specified in env config with correct package configurations with no spec param" {
            $envConfigFile = "$fixturesDir\config\env.config.ps1"
            [object[]]$appsConfig = Install-NudeployEnv $envConfigFile
            $packageRoot = "$nodeDeployRoot\Test.Package\Test.Package.1.0"
            
            $packageRoot | should exist

            $deploymentConfigFile = "$packageRoot\deployment.config.ini"
            $deploymentConfigFile | should exist
            $config = Import-Config $deploymentConfigFile
            $config.Count | should  be 9
            $config.DatabaseName | should be "MyPackage-int"
            $config.AppPoolPassword | should be "password"
            $config.DataSource | should be "localhost"
            $config.WebsiteName | should be "MyService-int"
            $config.WebsitePort | should be "8888"
            $config.PhysicalPath | should be 'C:\IIS\MyService-int'
            $config.AppPoolName | should be "MyService-int"
            $config.AppPoolUser | should be "MyService-int"
            $config.AppName | should be "MyService"

            $features = Get-Content "$packageRoot\features.txt"
            write-host $features
            $features | should be @("a", "b")
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
    Context "others" {
        It "should stop deployment when exception is thrown when installing a package" {
            $envConfigFile = "$fixturesDir\config\env.config.ps1"
            & $nuget pack "$fixturesDir\package_source_with_error_exitcode\test_package.nuspec" -NoPackageAnalysis -Version "1.0" -o $nugetRepo
            $errorCode = 10
            {Install-NudeployEnv $envConfigFile} | should throw
        }

        It "should stop deployment when exception is thrown when installing a package" {
            $envConfigFile = "$fixturesDir\config\env.config.ps1"
            & $nuget pack "$fixturesDir\package_source_exception\test_package.nuspec" -NoPackageAnalysis -Version "1.0" -o $nugetRepo
            { Install-NudeployEnv $envConfigFile } | should throw
        }
    }

}

Describe "others1" {

    $nodeDeployRoot = "$TestDrive\deployment_root"
    
    $nugetRepo = "$TestDrive\nugetRepo"
    New-Item $nugetRepo -type Directory -Force
    $workingDir = "$TestDrive\workingDir"
    $nuget = "$root\tools\nuget\NuGet.exe"
    $nugetSource = $nugetRepo

    & $nuget pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -Version "1.0" -o $nugetRepo -NoPackageAnalysis
    Install-NuPackage -package "NScaffold.NuDeploy" -workingDir $workingDir -version "1.0" -postInstall {
        param($packageDir)
        $nudeployModule = Get-ChildItem $packageDir "nudeploy.psm1" -recurse
        Import-Module $nudeployModule.FullName -Force
    }


    It "should deploy the package on the host specified in env config with correct package configurations with spec param" {
        Remove-Item "$nugetRepo\*.*" -Force -Recurse
        & $nuget pack "$fixturesDir\package_source\test_package.nuspec" -NoPackageAnalysis -Version "1.0" -o $nugetRepo
        & $nuget pack "$fixturesDir\package_source\test_package.nuspec" -NoPackageAnalysis -Version "0.9" -o $nugetRepo

        $envConfigFile = "$fixturesDir\config_simple\env.config.ps1"
        $vesrionSpecFile = "$fixturesDir\versionSpec.ini"

        Install-NudeployEnv -envPath $envConfigFile -versionSpec $vesrionSpecFile -nugetRepoSource $nugetRepo

        $packageRoot = "$nodeDeployRoot\Test.Package\Test.Package.0.9"
        $packageRoot | should exist

        $config = Import-Config "$packageRoot\deployment.config.ini"
        $config.DataSource | should be "localhost1"
        $config.DatabaseName | should be "MyPackage-local1"
        $config.WebsiteName | should be "MyService-local1"
        $config.WebsitePort | should be "80791"
        $config.AppPoolName | should be "MyService-local1"
        $config.AppPoolUser | should be "MyService-local1"
        $config.AppPoolPassword | should be "password1"
        $config.PhysicalPath | should be "C:\IIS\MyService-local1"
    }

    It "should deploy the package on the host specified in env config with correct package configurations with multi-package" {
        Remove-Item "$nugetRepo\*.*" -Force -Recurse
        & $nuget pack "$fixturesDir\package_source\test_package.nuspec" -NoPackageAnalysis -Version "2.0" -o $nugetRepo
        & $nuget pack "$fixturesDir\package_source_multiple\test_package_multiple.nuspec" -NoPackageAnalysis -Version "2.1" -o $nugetRepo
        $envConfigFile = "$fixturesDir\config_multiple\env.config.ps1"

        Install-NudeployEnv $envConfigFile
        "$nodeDeployRoot\Test.Package\Test.Package.2.0" | should exist
        "$nodeDeployRoot\Test.Package.Multiple\Test.Package.Multiple.2.1" | should exist
    }
}
