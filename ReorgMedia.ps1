$ErrorActionPreference = "Stop"
.$PSScriptRoot\common.ps1

cls

$CleanMediaPath = "$PSScriptRoot\ManagedMedia"
$SettingFile = "$PSScriptRoot\setting.xml"
$OrganizeBy = getSettingValue -SettingFile $SettingFile -Name "OrganizeBy"

write-host "Reorganizing $CleanMediaPath as $OrganizeBy"

$ManagedMediaMetadata = "$CleanMediaPath\ManagedMedia.csv"



$ManagedFiles = import-csv -path $ManagedMediaMetadata -Encoding "UTF8"

for($i=0; $i -lt $ManagedFiles.count; $i++)
{
	$filerecord = $ManagedFiles[$i]
	
	$src = $filerecord.PATH
	
	$dstFolder = "$CleanMediaPath\$OrganizeBy"
	$dstFolder = ReplaceVariables -strVal $dstFolder -filerecord $filerecord
	
	$dst =  "$dstFolder\" + $filerecord.FILE
	
	
	$filerecord.PATH = $dst
	
	if(Test-Path -Path $src)
	{
		New-Item -Path $dstFolder -ItemType "directory" -Force | out-null
		move-item -Path $src -destination $dst -force
	}
	
	Write-Progress -Activity "Reorganizing files please wait.. $i of $($ManagedFiles.count) : $($filerecord.FILE)" -ID 1 -PercentComplete $(($i * 100)/$ManagedFiles.count)
}

Write-Progress -ID 1 -Completed -Activity "done" -PercentComplete 100

$ManagedFiles | Export-csv -Path $ManagedMediaMetadata -Encoding "UTF8" -NoTypeInformation -Force

write-host "Cleaning empty folders after re organizing"

removeEmptyDirs -strFldr $CleanMediaPath

write-host "Reorganizing Completed!"


