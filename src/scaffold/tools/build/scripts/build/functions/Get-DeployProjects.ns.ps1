Function Get-DeployProjects ($dirs, [ScriptBlock] $filter = {$true} ){
    $dirs | Get-ChildItem -include *.nuspec -Recurse | ? $filter | % { Get-ChildItem $_.Directory -filter *.csproj } 
}