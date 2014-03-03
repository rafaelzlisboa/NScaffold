$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = resolve-path "$here\..\.."
. "$root\src\nudeploy\tools\functions\Copy-FileRemote.ps1"

Describe "Copy-FileRemote" {
    It "should copy a file to a remote non-existed folder" {
        $source = "$here\Copy-FileRemote.Tests.ps1"
        $randomNumber = [System.DateTime]::Now.Ticks
        $not_existed_folder = "$TestDrive\not\existe\f$randomNumber"
        $dest = "$not_existed_folder\1.dat"

        $not_existed_folder | should not exist

        Copy-FileRemote "localhost" $source $dest
        $dest | should exist
    }
    
    It "should copy a file by overwrite existing file" {
        $source = "$here\Copy-FileRemote.Tests.ps1"
        $randomNumber = [System.DateTime]::Now.Ticks
        $dest = "$TestDrive\Copy-FileRemote-target.dat"
        Set-Content -Value 1 $dest

        Copy-FileRemote "localhost" $source $dest
        $dest | should exist

        (Get-Item $dest).length | should not be 1
    }
}

