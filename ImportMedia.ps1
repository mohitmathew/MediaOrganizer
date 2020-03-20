$ErrorActionPreference = "Stop"
.$PSScriptRoot\common.ps1

<#
References
https://geoffhudik.com/tech/2018/06/28/picture-cleanup-photo-vs-image-part-1-powershell-core-image-metadata-and-resizing/
https://www.nuget.org/packages/MetadataExtractor/2.3.0
https://www.nuget.org/packages/XmpCore/
#>

function Get-MetaDir($metaDirs, $name) {
    $metaDirs | Where-Object { $_.Name -eq $name } | Select-Object -first 1
}
 
function ScanFolder($Path,$ScanOutput)
{
	LogToFile -str_lg_file $logPath -logstring "Discovering video and images please wait..."

	$files = get-childItem -path $Path -recurse -include ('*.jpg', '*.mov','*.jpeg','*.bmp','*.mp4','*.avi','*.wav','*.mpg','*.3gp') -Attributes !Directory+!System
	
	LogToFile -str_lg_file $logPath -logstring "$($files.count) files found. "
	
	$images = @() 
	
	for($i=0; $i -lt $files.count; $i++)
	{
		$file = $files[$i]
		
		if($file.length -gt 10240)#skip any junk file smaller than 10 kb.
		{
			#write-host $file
			$imgobj = getImageMetaData -imgFile $file
			
			$images+=$imgobj
		}
		else
		{
			$global:skippedFiles += $file.FullName
		}
		
		Write-Progress -Activity "Extracting Metadata. $i of $($files.count) : $($file.name)" -ID 1 -PercentComplete $(($i * 100)/$files.count)
	}
	
	Write-Progress -ID 1 -Completed -Activity "done" -PercentComplete 100
	
	$images | Export-csv -Path $ScanOutput -Encoding "UTF8" -NoTypeInformation -Force
	
	LogToFile -str_lg_file $logPath -logstring "Scan Completed."
	
}

function getImageMetaData($imgFile)
{
	$imageObj = @{}
	$imageObj["PATH"] = $imgFile
	$imageObj["FILE"] = $imgFile.Name
	$imageObj["HASH"] = $(Get-FileHash -Path $imgFile -Algorithm "MD5").Hash
	$imageObj["FOLDER"] = $imgFile.Directory.Name
	$imageObj["MAKE"] = $null
	$imageObj["MODEL"] = $null
	$imageObj["DATETAKEN"] = $null
	$imageObj["YEAR"] = $null
	$imageObj["MONTH"] = $null
	$imageObj["LAT"] = $null
	$imageObj["LON"] = $null
	$imageObj["COUNTRY"] = $null
	$imageObj["CITY"] = $null
	$imageObj["STATE"] = $null

	#<#
	try
	{
	#>
		$imageObj["DATETAKEN"] = $imgFile.LastWriteTime
	
		$metaDirs = [MetadataExtractor.ImageMetadataReader]::ReadMetadata($imgFile)
		
		<#
		foreach ($metaDir in $metaDirs) {
			foreach ($tag in $metaDir.Tags) {
				"$($metaDir.Name) - $($tag.Name) = $($tag.Description)"
			}
		}
		#>		
		 
		$exifSubDir = Get-MetaDir $metaDirs "Exif SubIFD"
		$gpsDir = Get-MetaDir $metaDirs "GPS"
		$exifIFDir = Get-MetaDir $metaDirs "Exif IFD0"
		
		if($gpsDir)
		{
			$geoloc = $gpsDir.getGeoLocation()
			if($geoloc)
			{
				$imageObj["LAT"] = $geoloc.Latitude
				$imageObj["LON"] = $geoloc.Longitude
			
			}
		}
		
		$imageObj["MAKE"] = $(Get-MetaDesc -dirObj $exifIFDir -tagName 'Make')
		$imageObj["MODEL"] = $(Get-MetaDesc -dirObj $exifIFDir -tagName 'Model')
		
		$dt = $(Get-MetaDesc -dirObj $exifSubDir -tagName 'Date/Time Original')
		if($dt)
		{
			$imageObj["DATETAKEN"] = [datetime]::ParseExact($dt,"yyyy:MM:dd HH:mm:ss", $null)
		}
	
	#<#
	}
	catch
	{
        #write-host $_.Exception.Message;
		#write-host "Failed...$imgFile" 
	}
	#>
	
	$imageObj["YEAR"] = $imageObj["DATETAKEN"].ToString("yyyy")
	$imageObj["MONTH"] = $imageObj["DATETAKEN"].ToString("MMMM")

	return [pscustomobject]$imageObj
}

function Get-MetaDesc($dirObj, $tagName) 
{
	$Val = $null
    if ($dirObj) 
	{ 
		$tag = $dirObj.Tags | Where-Object { $_.Name -eq $tagName }
		if($tag)
		{
			$Val = $tag.Description
		}
	}
	return $Val
}

function ProcessScannedData($scanOutput, $CleanMediaPath, $OrganizeBy)
{
	$ManagedMediaMetadata = "$CleanMediaPath\ManagedMedia.csv"
	
	$files = import-csv -path $scanOutput -Encoding "UTF8"
	
	$MediaHashes = @()
	$ManagedFiles = @()
	
	if(test-Path -path $ManagedMediaMetadata)
	{
		$ManagedFiles = import-csv -path $ManagedMediaMetadata -Encoding "UTF8"
		
		foreach($fileRec in $ManagedFiles)
		{
			if(-not $MediaHashes.contains($fileRec.HASH))
			{
				$MediaHashes += $fileRec.HASH
			}
		}
	}
	
	for($i=0; $i -lt $files.count; $i++)
	{
		$filerecord = $files[$i]
		
		if($MediaHashes.contains($filerecord.HASH))
		{
			$global:skippedFiles += $filerecord.PATH
			$lSize = (get-item -path $filerecord.PATH).length
			$global:SavedSpace += $lSize

		}
		else
		{
			$strDST = "$CleanMediaPath\$OrganizeBy\"
			
			$strDST = ReplaceVariables -strVal $strDST -filerecord $filerecord
			New-Item -Path $strDST -ItemType "directory" -Force | out-null

			$strDST = $strDST + $filerecord.FILE
			Copy-Item -Path $filerecord.PATH -Destination $strDST -Force
		
			$MediaHashes += $filerecord.HASH
			
			$newRecord = clonePSObject -obj $filerecord
			#write-host $newRecord
			$newRecord.PATH = $strDST
			$ManagedFiles+= $newRecord
			
			$global:ImportCount++
		}
		
		Write-Progress -Activity "Importing media. $i of $($files.count) : $($filerecord.FILE)" -ID 1 -PercentComplete $(($i * 100)/$files.count)
		
		
	}
	
	Write-Progress -ID 1 -Completed -Activity "done" -PercentComplete 100

	$ManagedFiles | Export-csv -Path $ManagedMediaMetadata -Encoding "UTF8" -NoTypeInformation -Force

}


cls
Add-Type -Path "$PSScriptRoot/bin/MetadataExtractor.dll"
Add-Type -Path "$PSScriptRoot/bin/XmpCore.dll"

$logPath = "$PSScriptRoot\scan.log"
$scanRoot = Select-FolderBrowse -prompt "Select source folder to Import" -PathSuggestion "C:\backup\Pictures\"

$scanOutput = $PSScriptRoot + "\scanoutput.csv"


$CleanMediaPath = "$PSScriptRoot\ManagedMedia"
$SettingFile = "$PSScriptRoot\setting.xml"

$OrganizeBy = getSettingValue -SettingFile $SettingFile -Name "OrganizeBy"


$global:skippedFiles =@()
$global:SavedSpace =0
$global:ImportCount =0

$sw = [Diagnostics.Stopwatch]::StartNew()

LogToFile -str_lg_file $logPath -logstring "Scanning folder $scanRoot" -banner $true 

ScanFolder -Path $scanRoot -ScanOutput $scanOutput

LogToFile -str_lg_file $logPath -logstring "Importing to $CleanMediaPath and organizing by $OrganizeBy"

ProcessScannedData -scanOutput $scanOutput -CleanMediaPath $CleanMediaPath -OrganizeBy $OrganizeBy


foreach($skpFile in $global:skippedFiles)
{
	LogToFile -str_lg_file $logPath -logstring "Skipped File : $skpFile" -display $false
}

LogToFile -str_lg_file $logPath -logstring "Imported $($global:ImportCount) files. Skipped $($global:skippedFiles.count) Duplicates/Unwanted files. Saved $(Get-FiendlySize -size $global:SavedSpace)" -banner $true

$sw.Stop()

$TimeTaken = $sw.Elapsed.ToString("hh\:mm\:ss")

LogToFile -str_lg_file $logPath -logstring "Completed in $TimeTaken" 

