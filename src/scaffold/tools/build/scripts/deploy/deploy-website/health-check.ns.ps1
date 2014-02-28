param($config, $packageInfo, $installArgs, [ScriptBlock] $installAction)

$here = $MyInvocation.MyCommand.Path | Split-Path -Parent
. $here\website.fn.ns.ps1

& $installAction

Function Get-HealthCheckUrl($webSiteName, $healthCheckPath){
    if(-not $healthCheckPath){
        $healthCheckPath = "/health?check=all"
    }
    Get-UrlForSite $webSiteName $healthCheckPath
}

Function Test-MatchPackage($healthCheckPage, $packageInfo){
    $artifactMatch = $healthCheckPage -match "Name=$($packageInfo.packageId)\W"
    $versionMatch = $healthCheckPage -match "Version=$($packageInfo.version)\W"
    if(-not ($artifactMatch -and $versionMatch)){
        $false
    } else {
        if($healthCheckPage -match ".+=Failure\s*") {
            Write-Warning "Health page reported there are some failures after the deployment!"
        }
        $true
    }
}
Function Test-WebsiteMatch($config, $packageInfo){
    Write-Host "Source Package [ $($packageInfo.packageId) : $($packageInfo.version) ]"
    $webSiteName = $config.siteName
    $healthCheckPath = $config.healthCheckPath
    if(-not(Test-Path "IIS:\Sites\$websiteName")) {
        $false
    } else {
        $healthCheckUrl = Get-HealthCheckUrl $webSiteName $healthCheckPath
        Write-Host "Target HealthCheckUrl: [$healthCheckUrl]"
        $healthCheckPage = Get-UrlContent $healthCheckUrl
        Write-Host "HealthCheckPage `n$healthCheckPage"
        Test-MatchPackage $healthCheckPage $packageInfo
    }
}

if(-not (Test-WebsiteMatch $config $packageInfo)){
    throw "Site [$($config.siteName)] doesn't match package [$($packageInfo.packageId) $($packageInfo.version)]"
}
