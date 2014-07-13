# this script should be invoked under the root directory of the package. 
param([Parameter(Position = 0, Mandatory = $true, ParameterSetName = "configFile")]
    [string]$configFile, 
    [Parameter(Position = 0, Mandatory = $true, ParameterSetName = "configObject")]
    [hashtable]$configObject, 
    [string]$type,
    [string]$packageRoot = (Get-Location).ProviderPath, 
    $features=@(),     
    [ScriptBlock] $applyConfig,
    [hashtable]$installArgs)

trap {
    throw $_
}

$root = $MyInvocation.MyCommand.Path | Split-Path -Parent
# include libs
if(-not $libsRoot) {
    $libsRoot = "$root\libs"
}
Get-ChildItem $libsRoot -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }

. PS-Require "$root\functions"


$featuresFolder = "$root\deploy-$type"

$defaultFeatureScript = Get-FeatureScript "default" $featuresFolder
if (-not $defaultFeatureScript) {
    throw "There's no default script for deploying [$type]. "
}
. PS-Require "$featuresFolder\functions"
$defaultFeature = & $defaultFeatureScript $packageRoot $installArgs

$packageInfo = $defaultFeature.packageInfo

# get config
if($PsCmdlet.ParameterSetName -eq 'configFile') {
    $config = Import-Config $configFile | 
        Patch-Config -patch (Generate-PackageConfig $packageInfo)
} elseif ($PsCmdlet.ParameterSetName -eq 'configObject') {
    $config = $configObject | 
        Patch-Config -patch (Generate-PackageConfig $packageInfo)
} else {
    $config = Generate-PackageConfig $packageInfo
}

if($applyConfig){
    & $applyConfig $config $packageInfo | Out-Default
}

$installClosure = Make-Closure $defaultFeature.installAction $config, $packageInfo, $installArgs
foreach ($feature in $features){
    $featureScript = Get-FeatureScript $feature $featuresFolder
    if($featureScript){
        $installClosure = Make-Closure { 
            param($scriptFile, $c)
            & "$scriptFile" $config $packageInfo $installArgs {Run-Closure $c}
        } "$featureScript", $installClosure
    }
}

Run-Closure $installClosure | Out-Default

if ($defaultFeature.export) {
    & $defaultFeature.export $config $packageInfo $installArgs
}
