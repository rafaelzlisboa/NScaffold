$here = $MyInvocation.MyCommand.Path | Split-Path -Parent
. $here\website.fn.ns.ps1

Function Get-ReadyPagePath ($websiteName){
    Get-PhysicalPathForSite $websiteName "\ready.txt"
}
Function Remove-FromLoadBalancer($websiteName) {
    if(Test-Path "IIS:\Sites\$websiteName"){
        Trace-Progress "Remove-FromLoadBalancer for site $websiteName" {
            $readyPagePath = Get-ReadyPagePath $websiteName
            Remove-Item $readyPagePath
        }
    }
}
Function Add-ToLoadBalancer($websiteName) {
    Trace-Progress "Add-ToLoadBalancer for site $websiteName" {
        if(-not(Test-Path "IIS:\Sites\$websiteName")){
            throw "Site doesn't exist $websiteName"
        }
        $readyPagePath = Get-ReadyPagePath $websiteName
        if(-not (Test-Path $readyPagePath)){
            New-Item $readyPagePath -type File | Out-Null    
        }
    }
}
Function Test-SuspendedFromLoadBalancer($websiteName){
    Trace-Progress "Test-SuspendedFromLoadBalancer for site [$websiteName]" {
        if(-not(Test-Path "IIS:\Sites\$websiteName")) { return $true; }
        $readyPageUrl = Get-UrlForSite $websiteName "/ready.txt"
        -not (Test-UrlExisted $readyPageUrl)
    }
}
Function Assert-SuspendedFromLoadBalancer($websiteName) {
    if(-not (Test-SuspendedFromLoadBalancer $websiteName)) {
        throw "Website [$websiteName] is not suspended from load balancer!"
    }
}
Function Assert-AddedToLoadBalancer($websiteName){
    if(Test-SuspendedFromLoadBalancer $websiteName) {
        throw "Website [$websiteName] is suspended from load balancer!"
    }
}
