$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."

. "$root\src-libs\functions\Install-NuPackage.ns.ps1"

Describe "Install-NuPackage" {
    $packageName = "Test.Package"    
    $workingDir = "$TestDrive\deployment_package"
    $nuget = "$root\tools\nuget\NuGet.exe"
    $nugetSource = "$TestDrive\nugetRepo"
    New-Item $nugetSource -type directory | Out-Null
    & $nuget pack "$fixturesDir\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.0 -o $nugetSource
    & $nuget pack "$fixturesDir\package_source\test_package.nuspec" -NoPackageAnalysis -Version 0.9 -o $nugetSource

    It "should install the package with the latest version." {
        $packageRoot = Install-NuPackage $packageName $workingDir
        $packageRoot | should be "$workingDir\$packageName.1.0"
        "$packageRoot\config.ini" | should exist
    }  

    It "should install the package with the spec version." {
        $packageRoot = Install-NuPackage $packageName $workingDir "0.9"
        $packageRoot | should be "$workingDir\$packageName.0.9"
        "$packageRoot\config.ini" | should exist
    } 

    It "should install the package and run the block." {
        $fileCreateByBlock = "$TestDrive\block.ini"
        $packageRoot = Install-NuPackage $packageName $workingDir "1.0" {
           New-Item -type file -path $fileCreateByBlock
        }
        $packageRoot | should be "$workingDir\$packageName.1.0"
        "$packageRoot\config.ini" | should exist
        $fileCreateByBlock | should exist
    }
    It "should throw error if install failed." {
        {
            Install-NuPackage "noSuchPackage" $workingDir "0.9"
        } | should throw
    }
}