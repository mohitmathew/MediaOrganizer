
function ReplaceVariables($strVal, $filerecord)
{
    $filerecord | Get-Member -MemberType *Property | % {
		$key = $_.name
		$val = $filerecord.($_.name)
		
		if (([string]::IsNullOrEmpty($val)))
		{
			$val = "Unknown"
		}
		$val = $val.trim()
		
		$strVal = $strVal.replace('{' + $key  + '}', $val)
    }
	
	return $strVal
}

Function Select-FolderBrowse([string] $prompt, [string] $PathSuggestion = "")
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    write-host "$prompt : " -NoNewline

    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = $prompt
    if($PathSuggestion -ne "")
    {
        $FolderBrowser.SelectedPath = $PathSuggestion
    }

    $retval  = $FolderBrowser.ShowDialog()

    If($retval -ne "OK")
    {
        throw "Folder not selected!!!"        
    }

    write-host $FolderBrowser.SelectedPath

    return $FolderBrowser.SelectedPath   
}

Function LogToFile
{
   Param ([string]$str_lg_file, [string]$logstring, [bool]$display = $true, [bool] $banner = $false )

	
   if($banner)
   {
		$bnrstr =  "`n============================================================================="
		write-host $bnrstr
		Add-content $str_lg_file -value $bnrstr -Encoding Unicode
   }
   
   $logstring = (Get-Date -format "yyyy/MM/dd HH:mm:ss") + " :: " + $logstring
   if($display)
   {
        Write-Host  $logstring
   }

   Add-content $str_lg_file -value $logstring -Encoding Unicode
   
   if($banner)
   {
		$bnrstr =  "============================================================================="
		write-host $bnrstr
		Add-content $str_lg_file -value $bnrstr -Encoding Unicode
   }

}

function clonePSObject($obj)
{
	$objnew = New-Object PsObject
	$obj.psobject.properties | % {
		$objnew | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
	}
	return $objnew
}


function Get-FiendlySize($size)
{
    If     ($size -gt 1TB) {return [string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {return [string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {return [string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {return [string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -ge 0)   {return [string]::Format("{0:0.00} B", $size)}
    Else                   {return ""}

}

function removeEmptyDirs($strFldr)
{
	do {
	  $dirs = gci $strFldr -directory -recurse | Where { (gci $_.fullName).count -eq 0 } | select -expandproperty FullName
	  $dirs | Foreach-Object { Remove-Item $_ }
	} while ($dirs.count -gt 0)
}

function getSettingValue($SettingFile, $Name)
{
	$xmSetting = $null
	if(test-path -path $SettingFile)
	{
		$xmSetting = [xml](get-content -path $SettingFile)
	}
	else
	{
		$xmSetting = [xml]("<Setting OrganizeBy='{YEAR}\{MONTH}\{FOLDER}' ></Setting>")
	}
	
	return $xmSetting.Setting.getAttribute($Name)
	
}
