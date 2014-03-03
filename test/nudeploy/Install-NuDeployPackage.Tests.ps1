$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
$nuget = "$root\tools\nuget\NuGet.exe"
$fixturesDir = $fixturesDir
$fixtures = "$TestDrive\test-fixtures"
$nugetRepo = "$fixtures\nugetRepo"
$workingDir = "$fixtures\workingDir"
$nuDeployPackageName = "NScaffold.NuDeploy"
$packageName = "Test.Package"

$configFile = "$fixtures\config\app-configs\Test.Package.ini"
. "$root\src-libs\functions\Import-Config.ns.ps1"

Describe "Install-NuDeployPackage" {
    Remove-Item -Force -Recurse $fixtures -ErrorAction SilentlyContinue |Out-Null
    Copy-Item $fixturesDir $fixtures -Recurse

    & $nuget pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -o $nugetRepo
    & $nuget install $nuDeployPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    $nuDeployDir = Get-ChildItem $workingDir | ? {$_.Name -like "$nuDeployPackageName.*"} | Select-Object -First 1
    Import-Module "$($nuDeployDir.FullName)\tools\nudeploy.psm1" -Force

    & $nuget pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.0 -o $nugetRepo
    & $nuget pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 0.9 -o $nugetRepo

    It "should deploy the package and run install.ps1." {
        Install-NuDeployPackage -packageId $packageName -source $nugetRepo -workingDir $workingDir
        $packageVersion = "1.0"
        $packageRoot = "$workingDir\$packageName.$packageVersion"
        $deploymentConfigFile = "$packageRoot\deployment.config.ini"
        $config = Import-Config $deploymentConfigFile
        $config.DatabaseName | should be "MyPackage-local"
        "$packageRoot\features.txt" | should exist
        Get-Content "$packageRoot\features.txt"| should be "default"
    }

    It "should deploy the latest package all spec." {
        $features = @("renew", "load-balancer")
        Install-NuDeployPackage -packageId $packageName -version 0.9  -source $nugetRepo -workingDir $workingDir -config $configFile -features $features
        $packageRoot = "$workingDir\$packageName.0.9"
        $deploymentConfigFile = "$packageRoot\deployment.config.ini"
        $config = Import-Config $deploymentConfigFile
		$config.DatabaseName | should be "[MyPackageDatabaseName]-[ENV]"
        Get-Content "$packageRoot\features.txt" | should be $features
    }

    It "should deploy the package and ignore install.ps1." {
        & $nuget pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.1 -o $nugetRepo
        Install-NuDeployPackage -packageId $packageName -source $nugetRepo -workingDir $workingDir -ignoreInstall
        $packageVersion = "1.1"
        $packageRoot = "$workingDir\$packageName.1.1"
        "$packageRoot\deployment.config.ini" | should not exist
    }

    It "should throw exception if specified config file is missing" {
        Add-Content "$fixtures\package_source\config.ini" -value "`nExtraConfig = whatever"
        Get-Content "$fixtures\package_source\config.ini" | write-host -f yellow
        & $nuget pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.2 -o $nugetRepo
        { Install-NuDeployPackage -packageId $packageName -version 1.2 -source $nugetRepo -workingDir $workingDir -config $configFile } |
            should throw        
    }
}