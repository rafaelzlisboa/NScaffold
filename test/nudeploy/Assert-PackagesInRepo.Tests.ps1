$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = resolve-path "$here\..\.."

. $root\src\nudeploy\tools\functions\Assert-PackagesInRepo.ps1
Describe "Assert-PackagesInRepo" {
    $nuget = "$root\tools\nuget\NuGet.exe"
    $nugetRepo = "$TestDrive\nugetRepo"
    
    New-Item $nugetRepo -type directory

    & $nuget pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -Version "0.0.1" -o $nugetRepo
    & $nuget pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -Version "0.0.2" -o $nugetRepo

    It "should return quietly when given package is in the repository" {
        $apps = @(
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0.1"
                },
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0.2"
                },
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0.1"
                }
            )
        { Assert-PackagesInRepo $nugetRepo $apps } | should not throw
    }

    It "should throw exception when 1 of the given package is not in the repository" {
        $apps = @(
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0.1"
                },
                @{
                    "package" = "package_not_exist"
                    "version" = "0.0.1"
                }
            )
        { Assert-PackagesInRepo $nugetRepo $apps } | should throw
    }
    It "should throw exception when version doesn't match exactly" {
        $apps = @(
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0"
                }
            )
        { Assert-PackagesInRepo $nugetRepo $apps } | should throw
    }
}