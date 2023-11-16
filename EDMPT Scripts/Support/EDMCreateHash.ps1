<#
.SYNOPSIS
    Script to Create a Hash used on EDM from data file.

.DESCRIPTION
    Script is designed to simplify EDM configuration as a task.
	Create locally the hash only if a new file is detected
    
.NOTES
    Version 1.0
    Current version - 15.11.2023
#> 

<#
HISTORY
  2023-10-27	S.Zamorano	- Initial script to create Hash locally
  2023-11-15	S.Zamorano	- First release
#>

#------------------------------------------------------------------------------  
#  
#   
# This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
# THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
# We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code 
# form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in 
# which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is 
# embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
# including attorneys fees, that arise or result from the use or distribution of the Sample Code.
#  
#------------------------------------------------------------------------------ 

function CheckPowerShellVersion
{
    # Check PowerShell version
    Write-Host "`nChecking PowerShell version... " -NoNewline
    if ($Host.Version.Major -gt 5)
    {
        Write-Host "Passed" -ForegroundColor Green
    }
    else
    {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "`tCurrent version is $($Host.Version). PowerShell version 7 or newer is required."
        exit(1)
    }
}

function CheckPrerequisites
{
    CheckPowerShellVersion
}

function HashDate
{
	$configfile = "$PSScriptRoot\..\EDMConfig.json"
	$json = Get-Content -Raw -Path $configfile
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$OutputPath = $config.EDMSupportFolder
	$EDMDataFolder = $config.EDMDataFolder
	$EDMColumnSeparator = $config.ColumnSeparator
	
	$EDMData = $config.DataFile
	$EDMExtension = Split-Path -Extension $EDMData
	$EDMFilterExtension = "*"+$EDMExtension
	
	$EDMDataFile = gci $EDMDataFolder -Filter $EDMFilterExtension | sort LastWriteTime | select -last 1
	
	$timestampFile = "$OutputPath"+"CreateHash_timestamp.json"
	# read LastWriteTime from the file
	if (-not (Test-Path -Path $timestampFile))
	{
		# if file not present create new value
		$timestamp = $EDMDataFile.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss")
		$timestamp = [DateTime]$timestamp
		$Hashtimestamp = $timestamp.AddDays(-1)
		$Hashtimestamp = $Hashtimestamp.ToString("yyyy-MM-ddTHH:mm:ss")
	}else{
		$json = Get-Content -Raw -Path $timestampFile
		[PSCustomObject]$timestamp = ConvertFrom-Json -InputObject $json
		$Hashtimestamp = $timestamp.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss")
	}
	$Hashtimestamp = @{"LastWriteTime" = $Hashtimestamp}
	ConvertTo-Json -InputObject $Hashtimestamp | Out-File -FilePath $timestampFile -Force
}

function CreateHash
{
	CheckPrerequisites
	HashDate
	$configfile = "$PSScriptRoot\..\EDMConfig.json"
	$json = Get-Content -Raw -Path $configfile
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$EDMDataFolder = $config.EDMDataFolder
	$OutputPath = $config.EDMSupportFolder
	$EDMData = $config.DataFile
	$EDMHash = $config.HashFolder
	$EDMSchema = $config.SchemaFolder+$config.SchemaFile
	$EDMFolder = $config.EDMAppFolder
	$EDMBadLinesPercentage = $config.BadLinesPercentage
	$EDMColumnSeparator = $config.ColumnSeparator
	$EDMExtension = Split-Path -Extension $EDMData
	$EDMFilterExtension = "*"+$EDMExtension
	
	$timestampFile = "$OutputPath"+"CreateHash_timestamp.json"
	$jsonHash = Get-Content -Raw -Path $timestampFile
	[PSCustomObject]$timestamp = ConvertFrom-Json -InputObject $jsonHash
	$Hashtimestamp = $timestamp.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss")
	#Write-Host "Hashtimestamp '$($Hashtimestamp)'." -ForegroundColor Green
	$Datafile = gci $EDMDataFolder -Filter $EDMFilterExtension | sort LastWriteTime | select -last 1
	$HashfileTime = $Datafile.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss")
	#Write-Host "Hashfile '$($Hashfile.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss"))'." -ForegroundColor Green
	
	if($HashfileTime -eq $Hashtimestamp)
	{
		Write-Host "Data file is still the same, nothing was copied." -ForegroundColor DarkYellow
	}else{
		Set-Location $EDMFolder | cmd
		If($EDMColumnSeparator -eq 'Csv')
		{
			.\EdmUploadAgent.exe /CreateHash /DataFile $EDMData /HashLocation $EDMHash /Schema $EDMSchema  /AllowedBadLinesPercentage $EDMBadLinesPercentage
			$Hashfile = gci $HashFolder -Filter *.edmhash | sort LastWriteTime | select -last 1
			$config.HashFile = $Hashfile.Name
		}else
		{
			.\EdmUploadAgent.exe /CreateHash /DataFile $EDMData /HashLocation $EDMHash /Schema $EDMSchema  /AllowedBadLinesPercentage $EDMBadLinesPercentage /ColumnSeparator $EDMColumnSeparator 
			$Hashfile = gci $HashFolder -Filter *.edmhash | sort LastWriteTime | select -last 1
			$config.HashFile = $Hashfile.Name
		}
		
		Write-Host "Create hash completed." -ForegroundColor Green
		$HashfileTime = @{"LastWriteTime" = $HashfileTime}
		ConvertTo-Json -InputObject $HashfileTime | Out-File -FilePath $timestampFile -Force
		Set-Location $OutputPath | cmd
	}
	
}

CreateHash