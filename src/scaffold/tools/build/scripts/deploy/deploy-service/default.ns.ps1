param($packageRoot, $installArgs)

$executablePath = $installArgs.executablePath
$exeFile = Get-ChildItem $packageRoot -Recurse -Filter "$executablePath" | select -first 1 
$sourcePath = Split-Path $exeFile.FullName -Parent
$packageInfo = Get-PackageInfo $packageRoot
$packageInfo.Add("sourcePath", $sourcePath)
@{
    'packageInfo' = $packageInfo
    'installAction' = {
        param($config, $packageInfo, $installArgs)
        $sourcePath = $packageInfo.sourcePath
        $executablePath = $installArgs.executablePath
        $name = $config.ServiceName
        $installPath = $config.ServicePath
        $username = $config.UserName
        $password = $config.Password

        Stop-ServiceForcibly($name)

        if (Test-Path $installPath) {
            Remove-Item $installPath -Force -Recurse
        }

        Write-Host "Start to copy $sourcePath to $installPath" -f green
        Copy-Item $sourcePath $installPath -Recurse
        
        $serviceBinPath = "$installPath\$executablePath"
        $service = Get-Service -Name $name -ErrorAction SilentlyContinue
        if(-not $service){
            Write-Host "Create Service[$name] for $serviceBinPath"
            if(($username) -and ($password)) {
                $secpasswd = ConvertTo-SecureString "$password" -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential ("$username", $secpasswd)
                New-Service -Name $name -BinaryPathName "$serviceBinPath" -Description $name -DisplayName $name -StartupType Automatic -credential $credential
            } else {
                New-Service -Name $name -BinaryPathName "$serviceBinPath" -Description $name -DisplayName $name -StartupType Automatic
            }
            
        }else{
            $name = $service.Name
            Write-Host "Service[$name] already exists,change BinaryPathName to $serviceBinPath" -f green
            & SC.exe CONFIG $name binPath= "\`"$serviceBinPath\`""
            Set-Service $name -StartupType Automatic
        }

        Start-Service -Name $name

        if(-not ((Get-Service -Name $name).Status -eq "Running")){
            throw "Service[$name] is NOT running after installation."
        }
        Write-Host "Service started. " -f green
    }
}
