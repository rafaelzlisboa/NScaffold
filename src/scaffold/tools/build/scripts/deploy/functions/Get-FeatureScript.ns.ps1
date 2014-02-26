Function Get-FeatureScript($feature, $featuresFolder){
    if (Test-Path "$featuresFolder\$feature.ns.ps1") {
        "$featuresFolder\$feature.ns.ps1"
    } elseif (Test-Path "$featuresFolder\$feature.ps1"){
        "$featuresFolder\$feature.ps1"
    }
}
