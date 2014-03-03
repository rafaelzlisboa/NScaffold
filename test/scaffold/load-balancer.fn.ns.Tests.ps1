$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
$tmp = "$root\tmp"
New-Item $tmp -Type Directory -ErrorAction SilentlyContinue|out-default
$tmp = resolve-path $tmp
$fixtures = "$TestDrive\test-fixtures"
. "$root\src\scaffold\tools\build\scripts\deploy\deploy-website\load-balancer.fn.ns.ps1"


Function Cleanup($siteName){
    if(Test-Path "IIS://$siteName"){
        Remove-Website -Name $siteName# -ErrorAction SilentlyContinue       
    }        
    write-host "after remove $siteName" -f cyan
}

Describe "Get-UrlForSite" {
    $siteName = "GetUrlForSite"
    $siteDir = "C:"
    $testFileName = "/test.txt"
    $port = 1001
    It "should return the url of the given local site" {
        write-host "before $siteName" -f cyan
        Cleanup $siteName
        write-host "after1" -f cyan
        New-Website -Name $siteName -IPAddress "*" -port $port -PhysicalPath $siteDir -force
        write-host "after2" -f cyan
        $url = Get-UrlForSite $siteName $testFileName
        
        $url | should be "http://localhost:$port$testFileName"
        Cleanup $siteName
    }

    It "should return the url of the given site with ip" {        
        Cleanup $siteName
        $ip = "127.0.0.1"        
        New-Website -Name $siteName -IPAddress $ip -port $port -PhysicalPath $siteDir -force
        $url = Get-UrlForSite $siteName $testFileName
        
        $url | should be "http://$($ip):$port$testFileName"
        Cleanup $siteName
    }

    It "should return the url of the given site with host header" {
        Cleanup $siteName
        $ip = "127.0.0.1"
        $hostHeader = "a.com"
        New-Website -Name $siteName -IPAddress $ip -port $port -PhysicalPath $siteDir -HostHeader $hostHeader -force

        $url = Get-UrlForSite $siteName $testFileName
        
        $url| should be "http://$($hostHeader):$port$testFileName"
        Cleanup $siteName
    }
}


Describe "Get-PhysicalPathForSite" {
    $siteName = "GetUrlForSite"
    $siteDir = "C:"
    $testFileName = "\test.txt"
    It "should return the url of the given local site" {
        Cleanup $siteName
        New-Website -Name $siteName -port 1002 -PhysicalPath $siteDir -force

        $url = Get-PhysicalPathForSite $siteName $testFileName
        
        $url | should be "$siteDir\$testFileName"
        Cleanup $siteName
    }
}

Describe "Remove-FromLoadBalancer" {
    $siteName = "RemoveLBSite"
    $siteDir = "$fixtures\RemoveFromLoadBalancerSite"
    $readyFilePath = "$siteDir\ready.txt"
    mkdir $siteDir -ErrorAction SilentlyContinue|Out-Null
    New-Item -type file $readyFilePath -ErrorAction SilentlyContinue|Out-Null
    Cleanup $siteName
    New-Website -Name $siteName -port 1002 -PhysicalPath $siteDir -force
    It "should delete ready.txt from the site's folder" {
        $readyFilePath | should exist
        Remove-FromLoadBalancer $siteName
        $readyFilePath | should not exist
    }
    Cleanup $siteName
}

Describe "Add-ToLoadBalancer" {
    $siteName = "AddToLoadBalancer"
    $siteDir = "$fixtures\AddToLoadBalancer"
    $readyFilePath = "$siteDir\ready.txt"
    mkdir $siteDir -ErrorAction SilentlyContinue|Out-Null
    Cleanup $siteName
    New-Website -Name $siteName -port 1003 -PhysicalPath $siteDir -force
    It "should delete ready.txt from the site's folder" {
        $readyFilePath | should not exist
        Add-ToLoadBalancer $siteName
        $readyFilePath | should exist
    }
    Cleanup $siteName
}

Describe "Test-SuspendedFromLoadBalancer" {
    $siteName = "TestSuspendedFromLB"
    $siteDir = "$tmp\TestSuspendedFromLB"
    mkdir $siteDir -ErrorAction SilentlyContinue|Out-Null
    Cleanup $siteName
    New-Website -Name $siteName -port 1004 -PhysicalPath $siteDir -force
    It "should return true when removed from load balancer" {
        Add-ToLoadBalancer $siteName
        $suspended = Test-SuspendedFromLoadBalancer $siteName

        Remove-FromLoadBalancer $siteName
        $suspended = Test-SuspendedFromLoadBalancer $siteName
        Test-SuspendedFromLoadBalancer $siteName | should be $true
    }
    Cleanup $siteName

    It "should return true when there's no site" {
        Test-SuspendedFromLoadBalancer "non-exist-site" | should be $true
    }
}

