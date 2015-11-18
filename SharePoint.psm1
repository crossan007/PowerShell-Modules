Function Write-Log{
Param($line)
$line | Out-File "c:\t\log.txt" -append
}

Function Process-Manifest{
<#
.SYNOPSIS
Processes the XML  contained in an Export-SPWeb Manifest*.xml file

.DESCRIPTION
Iterates through each XML SPFile object in the Manifest XML, and copies the corresponding .dat file to the files respective lcation in the filesystem.

This function expects a "t" folder to be present and writable on the c:\ drive.

#>
Param($manifest)

	$manifest.SPObjects.SPObject| ?{$_.ObjectType -eq "SPFile"} | foreach-object{
	$src = $_.File.FileValue
	$dest= "c:\t\$($_.ParentWebURL)\$($_.File.URL)"
	$destPath = Split-Path $dest
	if (Test-Path $destPath)
	{
	}
	else
	{
		New-Item -Path $destPath -ItemType Directory
	}
	Write-Log "Copying $src to $dest" 
	Copy-Item  $src $dest -Force
	} 
}

Function Process-ExtractedCWP{
<#
.SYNOPSIS 
Process the directory of an uncompressed SharePoint Web Backup 

.DESCRIPTION
The SharePoint site backup is Generated by Export-SPWeb -NoFileCompression command. 
This function should be called from within the backup directory.  
This function expects a "t" folder to be present on the c: drive
#>

	Get-ChildItem -Filter "Manif*" | Foreach-Object{
		Write-Log "Processing $_"
		[xml]$Manifest=Get-Content $_
		Process-Manifest -Manifest $Manifest
	}
}