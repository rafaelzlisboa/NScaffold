Function Test-PackageExists($package, $version, $nugetRepo){
    Write-Host "$nuget list $package -source $nugetRepo"
    $allVersions = & $nuget list $package -source $nugetRepo -AllVersions 
    if($allVersions -match "^$package $version$"){
        $true
    }else{
        $false
    }
}

Function Assert-PackagesInRepo($nugetRepo, $apps){
    $apps | %{
        $package = $_.package
        $version = $_.version
        "$package $version"
    } | sort| Get-Unique| % {
        $package, $version = $_ -split " "
        if(-not (Test-PackageExists $package $version $nugetRepo)){
            throw "Package[$package] with version[$version] not found in repository[$nugetRepo]"
        }
    }
}
