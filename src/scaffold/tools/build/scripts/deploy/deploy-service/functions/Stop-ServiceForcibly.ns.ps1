Function Stop-ServiceForcibly($name){
    $waitingTimeSpan = New-TimeSpan -Minutes 5
    $service = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($service){
        if($service.Status -eq "Started") {
            $service.Stop()
        }
        try {
            $service.WaitForStatus("Stopped", $waitingTimeSpan)
        } catch [System.ServiceProcess.TimeoutException]{
            Write-Host "Cannot stop service $name. Start to kill it." 
            $wmiObj = Get-WmiObject Win32_Service -Filter "Name='$name'"
            if ($wmiObj.ProcessId -ne 0) {
                Stop-Process -Id $wmiObj.ProcessId -Force
                $exited = (Get-Process -Id $wmiObj.ProcessId).WaitForExit(10000)
                if (-not $exited) {
                    throw "Process cannot be killed. Stop service failed. "
                }
            }                
        }   
        catch {
            throw $_
        }         
    }    
}
