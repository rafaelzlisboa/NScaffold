$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = resolve-path "$here\..\.."
$fixturesTemplate = "$root\test\test-fixtures"
$testScript = "$root\src\scaffold\tools\build\scripts\deploy\deploy-website\health-check.ns.ps1"
function Get-UNCPath($path){    
    $drive = Split-Path -qualifier $path
    $logicalDisk = Gwmi Win32_LogicalDisk -filter "DriveType = 4 AND DeviceID = '$drive'"
    if($logicalDisk){
        $path.Replace($drive, $logicalDisk.ProviderName)
    }
    else {
        $path
    }
}

Function Assert-Throws([ScriptBlock] $scriptBlock){
    try{
        & $scriptBlock    
    }
    catch {
        return
    }
    throw "No exception throw, assertion failed. "
}

Function Assert-NotThrow([ScriptBlock] $scriptBlock){
    try{
        & $scriptBlock    
    }
    catch {
        throw  "Exception $_ throws, assertion failed. "
    }
}


Describe "Test-WebsiteMatch" {
    $testSiteName = "TestWebsiteMatchSite"
    $port = 1005
    $physicalPath = Get-UNCPath("$fixturesTemplate\healthchecksite")
    Import-Module WebAdministration

    Function InWebSite ([ScriptBlock] $scriptBlock){
        try {
            Remove-Website -Name $testSiteName -ErrorAction SilentlyContinue
            New-Website $testSiteName -Port $port -IPAddress "*" -physicalPath $physicalPath -Force
            & $scriptBlock
        }finally{
            Remove-Website -Name $testSiteName
        }
    }

    It "should continues if website matches with the artifact version" {
        InWebSite {
            Assert-NotThrow {& $testScript @{
                siteName= $testSiteName
                healthCheckPath = "/health.txt?check=all"
            } @{
                packageId = "MyPackageApi"
                version = "1.0.123.0"
            } -installAction {}}            

        }
    }
    It "should throw if website does NOT match with the artifact version" {
        InWebSite {
            Assert-Throws {
                & $testScript @{
                    siteName= $testSiteName
                    healthCheckPath = "/health.txt?check=all"
                } @{
                    packageId = "MyPackageApi"
                    version = "1.0.123.1"
                } -installAction {} 
            }
        }        
    }

    It "should not throw when the package matches with the health check page" {
        $content = @"
Name=packageId
Version=1.0.0.3603931
ServerName=DEV-107
Status=Success
"@        
        Set-Content "$physicalPath\tmp.txt" $content
        InWebSite {
            Assert-NotThrow {
                & $testScript @{
                    siteName= $testSiteName
                    healthCheckPath = "/tmp.txt?check=all"
                } @{
                    packageId = "packageId"
                    version = "1.0.0.3603931"
                } -installAction {} 
            }

        }
    }
    It "should throw when the package name mismatch" {
        $content = @"
Name=packageId1
Version=1.0.0.3603931
ServerName=DEV-107
Status=Success
"@ | Set-Content "$physicalPath\tmp.txt"
        InWebSite {
            Assert-Throws {
                & $testScript @{
                    siteName= $testSiteName
                    healthCheckPath = "/tmp.txt?check=all"
                } @{
                    packageId = "packageId"
                    version = "1.0.0.3603931"
                } -installAction {} 
            }

        }
    }

    It "should not throw when health page contains failures" {
        $content = @"
Name=packageId
Version=1.0.0.3603931
ServerName=DEV-107
Status=Success
DB=Failure
"@ | Set-Content "$physicalPath\tmp.txt"
        InWebSite {
            Assert-NotThrow {
                & $testScript @{
                    siteName= $testSiteName
                    healthCheckPath = "/tmp.txt?check=all"
                } @{
                    packageId = "packageId"
                    version = "1.0.0.3603931"
                } -installAction {} 
            }

        }
    }

    It "should throws when health page does not contain failures" {
        $content = @"
Name=packageId
Version=1.0.0.3603931
ServerName=DEV-107
Status=Success
DB=Success
"@ | Set-Content "$physicalPath\tmp.txt"
        InWebSite {
            Assert-NotThrow {
                & $testScript @{
                    siteName= $testSiteName
                    healthCheckPath = "/tmp.txt?check=all"
                } @{
                    packageId = "packageId"
                    version = "1.0.0.3603931"
                } -installAction {} 
            }

        }
    }
}
