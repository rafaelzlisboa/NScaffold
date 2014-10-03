Function Stop-WebSiteDo($websiteName, [ScriptBlock] $scriptBlock){
    $pool = (Get-Item "IIS:\Sites\$webSiteName"| Select-Object applicationPool).applicationPool
    try{
        Stop-Website $webSiteName
        if((Get-WebAppPoolState $pool).value -ne 'Stopped'){
            Stop-WebAppPool $pool
        }

        & $scriptBlock
    } finally{
        Restart-WebAppPool $pool
        Start-Website $webSiteName
    }
}
