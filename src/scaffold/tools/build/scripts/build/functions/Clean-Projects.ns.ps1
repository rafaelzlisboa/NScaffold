Function Clean-Projects ($projectDirs) {
    $foldersToDelete = $projectDirs | 
        ? { Test-Path $_ } | 
        Get-ChildItem -include bin,obj -Recurse | 
        ? { $_.attributes -eq "Directory" } 
    $foldersToDelete| % { Remove-Item "$_\*" -Recurse -Force}
}
