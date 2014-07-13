Function Update-XmlFileContent($fullName, [ScriptBlock] $update){	
	$_ = [xml](Get-Content $fullName)
	& $update
	$_.Save($fullName)
}
