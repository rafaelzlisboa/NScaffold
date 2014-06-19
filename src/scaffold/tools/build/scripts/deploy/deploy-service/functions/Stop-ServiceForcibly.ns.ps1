Function Stop-ServiceForcibly($name){
    $waitingTimeSpan = New-TimeSpan -Minutes 5
    $service = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($service){
        if($service.Status -eq "Running") {
            $service.Stop()
        }
        try {
            $service.WaitForStatus("Stopped", $waitingTimeSpan)
            $wmiObj = Get-WmiObject Win32_Service -Filter "Name='$name'"
            if ($wmiObj.ProcessId -ne 0) {
                throw "Service is stopped, but process still running. "
            }
        } catch [System.ServiceProcess.TimeoutException]{
            Write-Host "Cannot stop service $name. Start to kill it." 
            $wmiObj = Get-WmiObject Win32_Service -Filter "Name='$name'"
            if ($wmiObj.ProcessId -ne 0) {
                $process = Get-Process -Id $wmiObj.ProcessId -ErrorAction SilentlyContinue
                if ($process) {
                    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
                    $exited = $process.WaitForExit(10000)
                    if (-not $exited) {
                        throw "Process cannot be killed. Stop service failed. "
                    }
                }
            }
        }   
        catch {
            throw $_
        }         
    }    
}
