<#
.SYNOPSIS
    Script to setup EDM.

.DESCRIPTION
    Script is designed to simplify EDM configuration as a task.
    
.NOTES
    Version 1.0
    Current version - 15.11.2023
#> 

<#
HISTORY
  2023-09-06    G.Berdzik 	- Initial version (used MPARR_Setup script as a base)

  2023-10-27	S.Zamorano	- New version using the original script as a base for EDM
  2023-11-13	S.Zamorano	- Manage some additional variables, and added comments to the functions 
  2023-11-15	S.Zamorano	- Initial release
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

#To validate that the script is executed with administrator rights
function CheckIfElevated
{
    $IsElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$IsElevated)
    {
        Write-Host "`nPlease start PowerShell as Administrator.`n" -ForegroundColor Yellow
        exit(1)
    }
}

#To validate that the PowerSHell version is 7 or newer
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

#To check previos validations
function CheckPrerequisites
{
    CheckIfElevated
    CheckPowerShellVersion
}

#function to get option number
function ReadNumber([int]$max, [string]$msg, [ref]$option)
{
    $selection = 0
    do 
    {
        $resp = Read-Host $msg
        try {
            $selection = [int]$resp
            if (($selection -gt $max) -or ($selection -lt 1))
            {
                $selection = 0
                throw 
            }            
        }
        catch {
            Write-Host "Please enter number between 1 and $max" -ForegroundColor DarkYellow 
            $selection = 0
        }

    } until ($selection -ne 0)
    $option.Value = $selection
}

#To obtain hostname, this is used to validate if the script is executed in the source machine or in a remote machine
function InitializeHostName
{
	$config = "$PSScriptRoot\EDMConfig.json"
	
	if (-not (Test-Path -Path $config))
    {
		Write-Host "Working on remote host." -ForegroundColor Red
		return
	}else 
	{
		$json = Get-Content -Raw -Path $config
		[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
		$EDMHostName = $config.EDMHostName
	}
	If ($EDMHostName -eq "Localhost")
	{
		$EDMHostName = hostname
		$config.EDMHostName = $EDMHostName
		WriteToJsonFile
	}
}

#To generate a pause after validate credentials
function TakeAPause
{
	$choices  = '&Continue'
	$decision = $Host.UI.PromptForChoice("", "`nDo you want to Continue? If you see an error above, validate your credentials.", $choices, 0)
	if ($decision -eq 0)
    {
		Set-Location $PSScriptRoot | cmd
		cls
		return
	}
}

#function to decrypt password
function DecryptSharedKey 
{
    param(
        [string] $encryptedKey
    )

    try {
        $secureKey = $encryptedKey | ConvertTo-SecureString -ErrorAction Stop  
    }
    catch {
        Write-Error "Workspace key: $($_.Exception.Message)"
        exit(1)
    }
    $BSTR =  [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    $plainKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $plainKey
}

#To validate the connection with EDM
function Connect2EDM
{
	$CONFIGFILE = "$PSScriptRoot\EDMConfig.json"
	if (-not (Test-Path -Path $CONFIGFILE))
	{
		$CONFIGFILE = "$PSScriptRoot\EDM_RemoteConfig.json"
	}
	
	$json = Get-Content -Raw -Path $CONFIGFILE
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$EncryptedKeys = $config.EncryptedKeys
	$EDMFolder = $config.EDMAppFolder
	$user = $config.User
	$SharedKey = $config.Password
	
	if ($EncryptedKeys -eq "True")
	{
		$SharedKey = DecryptSharedKey $SharedKey
		Set-Location $EDMFolder | cmd
		Clear-Host
		cls
		Write-Host "Validating connection to EDM..." -ForegroundColor Green
		.\EdmUploadAgent.exe /Authorize /Username $user /Password $SharedKey 
	}else{
		Set-Location $EDMFolder | cmd
		Clear-Host
		cls
		Write-Host "Validating connection to EDM..." -ForegroundColor Green
		.\EdmUploadAgent.exe /Authorize /Username $user /Password $SharedKey
	}
}

#To identify and set the paths used by EDM
function SelectEDMPaths
{
    cls
	
	$choices  = '&Yes', '&No'
	Write-Host "`n`n##########################################"
	Write-Host "`nThe current folder configuration for EDM is:"
	Write-Host "* EDM appplication location '$($config.EDMAppFolder)'."
	Write-Host "* EDM root folder '$($config.EDMrootFolder)'."
	Write-Host "* Hash folder location '$($config.HashFolder)'."
	Write-Host "* Schema data folder '$($config.SchemaFolder)'."
	Write-Host "* EDM support folder '$($config.EDMSupportFolder)'."
    $decision = $Host.UI.PromptForChoice("", "`nDo you want change the locations?", $choices, 1)
    if ($decision -eq 0)
    {
        [System.Reflection.Assembly]::Load("System.Windows.Forms") | Out-Null
                
		#Here you start selecting each folder
		
        $file = New-Object System.Windows.Forms.OpenFileDialog
		# Start selecting EMD Upload Agent location  
		$file.Title = "Select folder where EdmUploadAgent.exe is located"
        $file.InitialDirectory = 'ProgramFiles'
		$file.Filter = 'EDM App|EdmUploadAgent.exe'
        # main log directory
        if ($file.ShowDialog() -eq "OK")
        {
            $EDMDataPath = Split-Path -Parent $file.FileName
			$config.EDMAppFolder = $EDMDataPath + "\"
        }
		
		$folder = New-Object System.Windows.Forms.FolderBrowserDialog
		$folder.UseDescriptionForTitle = $true
		
        # EDM root folder
        $folder.Description = "Select the root folder for EDM scripts"
        $folder.rootFolder = 'ProgramFiles'
        if ($folder.ShowDialog() -eq "OK")
        {
            $config.EDMrootFolder = $folder.SelectedPath + "\"
        }
		
		# Hash data folder
        $folder.Description = "Select folder where Hash data will be located"
        $folder.rootFolder = 'Recent'
        $folder.InitialDirectory = $config.EDMrootFolder
        if ($folder.ShowDialog() -eq "OK")
        {
            $config.HashFolder = $folder.SelectedPath + "\"
        }
		
		# Schema data folder
        $folder.Description = "Select folder where Schema data will be located"
        $folder.rootFolder = 'Recent'
        $folder.InitialDirectory = $config.EDMrootFolder
        if ($folder.ShowDialog() -eq "OK")
        {
            $config.SchemaFolder = $folder.SelectedPath + "\"
        }
		
		# Support data folder
        $folder.Description = "Select folder where EDM support filers are located(Same support folder available with the original script)"
        $folder.rootFolder = 'Recent'
        $folder.InitialDirectory = $config.EDMrootFolder
        if ($folder.ShowDialog() -eq "OK")
        {
            $config.EDMSupportFolder = $folder.SelectedPath + "\"
        }
		
		cls
		Write-Host "`n###`t`tEDM folders configuration set up.`t`t####"
		Write-Host "`n`tEDM Application folder set to '$($config.EDMAppFolder)'."
		Write-Host "`tData root folder set to '$($config.EDMrootFolder)'."
		Write-Host "`tHash folder set to '$($config.HashFolder)'."
		Write-Host "`tSchema folder set to '$($config.SchemaFolder)'."
		Write-Host "`tSupport scripts folder set to '$($config.EDMSupportFolder)'."
		
		WriteToJsonFile
		Write-Host "`nPlase validate your folder selection, in case of changes you can execute at anytime." -ForegroundColor DarkYellow
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		
		cls
    }
}

#To identify and set the paths used by EDM in the remote server
function SelectEDMRemotePaths
{
	cls
	
	$config = "$PSScriptRoot\EDM_RemoteConfig.json"
	$json = Get-Content -Raw -Path $config
	[PSCustomObject]$RemoteConfig = ConvertFrom-Json -InputObject $json
	
	$choices  = '&Yes', '&No'
	Write-Host "`n`n##########################################"
	Write-Host "`nThe current configuration for EDM Remote activities is:"
	Write-Host "* EDM appplication location '$($RemoteConfig.EDMAppFolder)'."
	Write-Host "* EDM root folder '$($RemoteConfig.EDMrootFolder)'."
	Write-Host "* Hash folder location '$($RemoteConfig.HashFolder)'."
    $decision = $Host.UI.PromptForChoice("", "`nDo you want change the locations?", $choices, 0)
    if ($decision -eq 0)
    {
        [System.Reflection.Assembly]::Load("System.Windows.Forms") | Out-Null
                
		#Here you start selecting each folder
		
		# Start selecting first EDM App location
		$file = New-Object System.Windows.Forms.OpenFileDialog
		# Start selecting EMD Upload Agent location  
		$file.Title = "Select folder where EdmUploadAgent.exe is located"
        $file.InitialDirectory = 'ProgramFiles'
		$file.Filter = 'EDM App|EdmUploadAgent.exe'
        # main log directory
        if ($file.ShowDialog() -eq "OK")
        {
            $EDMDataPath = Split-Path -Parent $file.FileName
			$RemoteConfig.EDMAppFolder = $EDMDataPath + "\"
        }
		
		$folder = New-Object System.Windows.Forms.FolderBrowserDialog
		$folder.UseDescriptionForTitle = $true

        # EDM data root folder
        $folder.Description = "Select the root folder used by EDM scripts"
        $folder.rootFolder = 'ProgramFiles'
        if ($folder.ShowDialog() -eq "OK")
        {
            $RemoteConfig.EDMrootFolder = $folder.SelectedPath + "\"
        }
		
		# Hash data folder
        $folder.Description = "Select folder where Hash data will be located"
        $folder.rootFolder = 'Recent'
        $folder.InitialDirectory = $RemoteConfig.EDMrootFolder
        if ($folder.ShowDialog() -eq "OK")
        {
            $RemoteConfig.HashFolder = $folder.SelectedPath + "\"
        }
		
		Write-Host "`n###`t`tEDM folders configuration set up.`t`t####"
		Write-Host "`n* EDM Application folder set to '$($RemoteConfig.EDMAppFolder)'."
		Write-Host "* Data root folder set to '$($RemoteConfig.EDMrootFolder)'."
		Write-Host "* Hash folder set to '$($RemoteConfig.HashFolder)'."
		
		WriteToRemoteJsonFile
		Write-Host "`nPlase validate your folder selection, in case of changes you can execute at anytime." -ForegroundColor DarkYellow
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		
		cls
    }
}

#To get EDM credential in the source computer
function GetEDMUserCredentials
{
	cls
	
	$config = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $config
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	
	Write-Host "`n`n###`t`tAdd your credentials`t`t###"
	
	$Credential = $host.ui.PromptForCredential("Your credentials are needed", "Please validate that your user is part of EDM_DataUploaders group", "", "")
	$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Credential.Password)
	$config.Password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
	$config.User = $Credential.Username
	$config.EncryptedKeys = "False"
	
	WriteToJsonFile
	Write-Host "`n### The backup file can contains your credentials in clear text, take precautions ###" -ForegroundColor Red
	Write-Host -NoNewLine "`n`nTo back to the main menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	
	cls
}

#To get EDM credenatial in the remote computer
function GetEDMRemoteUserCredentials
{
	cls
	
	$config = "$PSScriptRoot\EDM_RemoteConfig.json"
	$json = Get-Content -Raw -Path $config
	[PSCustomObject]$RemoteConfig = ConvertFrom-Json -InputObject $json
	
	$Credential = $host.ui.PromptForCredential("Your credentials are needed", "Please validate that your user is part of EDM_DataUploaders group", "", "")
	$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Credential.Password)
	$RemoteConfig.Password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
	$RemoteConfig.User = $Credential.Username
	$RemoteConfig.EncryptedKeys = "False"
	
	WriteToRemoteJsonFile
	Write-Host "`n### The backup file can contains your credentials in clear text, take precautions ###" -ForegroundColor Red
	Write-Host -NoNewLine "`n`nTo back to the main menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	
	cls
}

#To obtain datastores names previously created at the Microsoft Purview portal
function GetDataStores
{
	Connect2EDM | Out-Null
	
	$config = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $config
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	
	$EDMFolder = $config.EDMAppFolder
	Set-Location $EDMFolder | cmd
	
	$DataStores = .\EdmUploadAgent.exe /GetDataStore
	$DS = $DataStores | Where-Object { $_ -ne $DataStores[0] }
	$DS = $DS | Where-Object { $_ -ne $DS[0] }
	$DS = $DS | Where-Object { $_ -ne $DS[-1] }
	$tempFolder = $DS -replace '(\, ).*','$1'
	$tempFolder = $tempFolder -replace ', ',''
	
	foreach ($DStore in $tempFolder){$DataStoresEDM += @([pscustomobject]@{Name=$DStore})}
	
	Write-Host "`nGetting Data Stores..." -ForegroundColor Green
    $i = 1
    $DataStoresEDM = @($DataStoresEDM | ForEach-Object {$_ | Add-Member -Name "No" -MemberType NoteProperty -Value ($i++) -PassThru})
	
	#List all existing folders under Task Scheduler
    $DataStoresEDM | Select-Object No, Name | Out-Host
	
	# Select EDM datastore tasks
	Write-Host "In case the EDM Schema was recently created and is not listed, please stop the script with Ctrl+C and run it again.`n"
    $selection = 0
    ReadNumber -max ($i -1) -msg "Enter number corresponding to the DataStore name" -option ([ref]$selection)
    $config.DataStoreName = $DataStoresEDM[$selection - 1].Name
	
	Write-Host "`nData Store selected '$($config.DataStoreName)'" -ForegroundColor Green

	WriteToJsonFile

	Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	cls
}

#To obtain the schema file used to hash the data
function GetSchemaFile
{
	Connect2EDM | Out-Null
	
	$configfile = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $configfile
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$EDMDSName = $config.DataStoreName
	$SchemaFolder = $config.SchemaFolder
	
	$EDMFolder = $config.EDMAppFolder
	Set-Location $EDMFolder | cmd	
	
	if ($EDMDSName -eq "Not set")
	{
		Write-Host "Missing DataStore name." -ForegroundColor Red
		$choices  = '&Yes', '&No'
		$decision = $Host.UI.PromptForChoice("", "`nDo you want to select the data store?", $choices, 0)
		if ($decision -eq 0)
		{
			GetDataStores
			WriteToJsonFile
		}return
	}else{
		.\EdmUploadAgent.exe /SaveSchema /DataStoreName $config.DataStoreName /OutputDir $SchemaFolder
		$XMLfile = gci $SchemaFolder | sort LastWriteTime | select -last 1
		$config.SchemaFile = $XMLfile.Name
		
		Write-Host "`nThe schema file '$($config.SchemaFile)' related to the datastore '$($EDMDSName)' was copied at '$($SchemaFolder)'." -ForegroundColor Green
		
		WriteToJsonFile
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		
		cls
	}
}

#To validate the original data file with schema related to the datastore
function ValidateEDMData
{
	Connect2EDM | Out-Null
	
	$configfile = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $configfile
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	
	$EDMColumnSeparator = $config.ColumnSeparator
	$EDMFolder = $config.EDMAppFolder
	Set-Location $EDMFolder | cmd
	
	$choices  = '&Yes', '&No'
	Write-Host "`n`n##########################################"
	Write-Host "`nThe current data files for EDM is:"
	Write-Host "* '$($config.DataFile)'" -ForegroundColor Green
	
	$decision = $Host.UI.PromptForChoice("", "`nDo you want to change the file set?", $choices, 0)
	if ($decision -eq 0)
    {
        [System.Reflection.Assembly]::Load("System.Windows.Forms") | Out-Null
        $file = New-Object System.Windows.Forms.OpenFileDialog
		# Start selecting Data file location used for EDM 
		$file.Title = "Select folder where Data file is located"
        $file.InitialDirectory = 'MyComputer'
		$file.Filter = 'CSV format |*.CSV|TSV format|*.TSV|Tab format|*.TXT'
        # main log directory
        if ($file.ShowDialog() -eq "OK")
        {
            $config.DataFile = $file.FileName
			$EDMDataPath = $file.FileName
			$config.EDMDataFolder = (Get-Item $EDMDataPath).DirectoryName+"\"
			WriteToJsonFile
            Write-Host "`nYour data file location is set to '$($config.DataFile)'."
        }
	}
	
	$SchemaLocation = $config.SchemaFolder+$config.SchemaFile
	Write-Host "`nSchema location is '$($SchemaLocation)'." -ForegroundColor Green
	Write-Host "Column separator set to validate this data is '$($EDMColumnSeparator)'." -ForegroundColor Green
	Write-Host "If validation fail, check your current file and the column separator used. You can change the value at the main menu, option 1, and then option 9." -ForegroundColor Green
	
	if($EDMColumnSeparator -eq "Csv")
	{
		.\EdmUploadAgent.exe /ValidateData /DataFile $config.DataFile /Schema $SchemaLocation
	}else
	{
		.\EdmUploadAgent.exe /ValidateData /DataFile $config.DataFile /Schema $SchemaLocation /ColumnSeparator $EDMColumnSeparator
	}
	
	Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		
	cls
}

#To create the hash from the original data file
function EDMHashCreation
{
	Connect2EDM | Out-Null
	$configfile = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $configfile
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$HashFolder = $config.HashFolder
	
	$EDMFolder = $config.EDMAppFolder
	Set-Location $EDMFolder | cmd
	
	$EDMData = $config.DataFile
	$EDMHash = $config.HashFolder
	$EDMSchema = $config.SchemaFolder+$config.SchemaFile
	$EDMBadLinesPercentage = $config.BadLinesPercentage
	$EDMColumnSeparator = $config.ColumnSeparator
	
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
	
	WriteToJsonFile
	
	Write-Host "`nHash and Salt files created at:" -ForegroundColor Green
	Write-Host "* Schema file '$($config.HashFolder)'." -ForegroundColor Green
	
	Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		
	cls
}

#To upalod the hash data created
function EDMHashUpload
{
	Connect2EDM | Out-Null
	
	$configfile = "$PSScriptRoot\EDMConfig.json"
	If (-not (Test-Path -Path $configfile))
	{
		$configfile = "$PSScriptRoot\EDM_RemoteConfig.json"
	}
	$json = Get-Content -Raw -Path $configfile
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	
	$EDMDSName = $config.DataStoreName
	$HashName = $config.HashFolder+$config.HashFile
	
	$EDMFolder = $config.EDMAppFolder
	Set-Location $EDMFolder | cmd	
	
	.\EdmUploadAgent.exe /UploadHash /DataStoreName $EDMDSName /HashFile $HashName
	Write-Host "`nHash is uploading, you can validate the state in the -EDM Hash Upload Status- menu" -ForegroundColor Green
	Write-Host "`nREMEMBER: You can update your EDM data only 5 times per day." -ForegroundColor RED
	
	Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	cls
}

#To request the status related to the hash uploaded
function EDMUploadStatus
{
	Connect2EDM | Out-Null
	
	$configfile = "$PSScriptRoot\EDMConfig.json"
	If (-not (Test-Path -Path $configfile))
	{
		$configfile = "$PSScriptRoot\EDM_RemoteConfig.json"
	}
	$json = Get-Content -Raw -Path $configfile
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$DSName = $config.DataStoreName
	
	$EDMFolder = $config.EDMAppFolder
	Set-Location $EDMFolder | cmd
	Clear-Host
	
	cls
	Write-Host "`nChecking the Hash upload status" -ForegroundColor Green
	.\EdmUploadAgent.exe /GetSession /DataStoreName employeesdataschema
	
	Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	cls
}

#To copy the information needed to the remote server
function EDMCopyDataNeeded
{
	Clear-Host
	cls
	CreateRemoteConfigFile
	$configfile = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $configfile
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$HashData = $config.HashFolder
	$HashData = $HashData+"*.Edm*"
	$SupportScripts = $config.EDMSupportFolder
	$SupportScripts = $SupportScripts+"EDM_*"
	$Destination = $config.EDMremoteFolder
	$HashDestination = "$Destination"+"Hash\"

	$EDMScripts = "$PSScriptRoot\EDM_*"
	
	#Here we ned to select the destination folder
	$choices  = '&Yes', '&No'
	Write-Host "`n`n##########################################"
	Write-Host "`nThe current configuration for remote folder for hash EDM is:"
	Write-Host "EDM remote path '$($config.EDMremoteFolder)'."
	Write-Host "REMEMBER: Is recommended to do this copy to an empty folder." -ForegroundColor DarkYellow
	Write-Host "`n##########################################"

    $decision = $Host.UI.PromptForChoice("", "`nDo you want change the locations?", $choices, 1)
    if ($decision -eq 0)
    {
        [System.Reflection.Assembly]::Load("System.Windows.Forms") | Out-Null
        $folder = New-Object System.Windows.Forms.FolderBrowserDialog
		$folder.UseDescriptionForTitle = $true
        
		#Here you start selecting each folder
		# Start selecting first EDM remote location
		$folder.Description = "Select folder where Hash data will be copied"
        $folder.rootFolder = 'ProgramFiles'
        # main log directory
        if ($folder.ShowDialog() -eq "OK")
        {
            $config.EDMremoteFolder = $folder.SelectedPath + "\"
			$Destination = $config.EDMremoteFolder
            Write-Host "`nEDM App folder set to '$($config.EDMremoteFolder)'."
			WriteToJsonFile
        }
	}
	
	Write-Host "`n###################################################" -ForegroundColor Red
	Write-Host "These files will be copied to '$($Destination)'." -ForegroundColor Green
	Write-Host "`n`tHash and Salt files located at '$($config.HashFolder)' " -ForegroundColor Green
	Write-Host "`tEDM_RemoteConfig.json file (Password was decrypted)  " -ForegroundColor Green
	Write-Host "`tThis EDM_Setup file " -ForegroundColor Green
	Write-Host "`tSupport script for upload task " -ForegroundColor Green
	Write-Host "`n###################################################" -ForegroundColor Red
	
	New-Item -ItemType Directory -Force -Path $HashDestination | Out-Null
	Copy-Item $HashData $HashDestination -recurse -force
	Copy-Item $EDMScripts $Destination -recurse -force
	Copy-Item $SupportScripts $Destination -recurse -force	
	
	Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	cls
}

#To initialize the configuration file used to collect all the settings needed
function InitializeEDMConfigFile
{
	# read config file
    $configfile = "$PSScriptRoot\EDMConfig.json" 
	
	if (-not (Test-Path -Path $configfile))
    {
		$config = [ordered]@{
		EncryptedKeys =  "False"
		SchemaFile = "Not set"
		Password = ""
		User = ""
		HashFile = "Not set"
		DataFile = "Not set"
		BadLinesPercentage = "5"
		ColumnSeparator = "Csv"
		DataStoreName = "Not set"
		EDMAppFolder = "c:\Program Files\Microsoft\EdmUploadAgent\"
		EDMrootFolder = "C:\EDM\"
		HashFolder = "C:\EDM\Hash\"
		SchemaFolder = "C:\EDM\Schemas\"
		EDMremoteFolder = "\\localhost\c$\"
		EDMSupportFolder = "C:\EDM\Support\"
		EDMDataFolder = "C:\EDM\Data\"
		EDMHostName = "Localhost"
		}
		return $config
    }else
	{
		$json = Get-Content -Raw -Path $configfile
		[PSCustomObject]$configfile = ConvertFrom-Json -InputObject $json
	
		$config = [ordered]@{
		EncryptedKeys = "$($configfile.EncryptedKeys)"
		SchemaFile = "$($configfile.SchemaFile)"
		Password = "$($configfile.Password)"
		User = "$($configfile.User)"
		HashFile = "$($configfile.HashFile)"
		DataFile = "$($configfile.DataFile)"
		BadLinesPercentage = "$($configfile.BadLinesPercentage)"
		ColumnSeparator = "$($configfile.ColumnSeparator)"
		DataStoreName = "$($configfile.DataStoreName)"
		EDMAppFolder = "$($configfile.EDMAppFolder)"
		EDMrootFolder = "$($configfile.EDMrootFolder)"
		HashFolder = "$($configfile.HashFolder)"
		SchemaFolder = "$($configfile.SchemaFolder)"
		EDMremoteFolder = "$($configfile.EDMremoteFolder)"
		EDMSupportFolder = "$($configfile.EDMSupportFolder)"
		EDMDataFolder = "$($configfile.EDMDataFolder)"
		EDMHostName = "$($configfile.EDMHostName)"
		}
		return $config
	}
}

#To initialize the remote configuratio file used by the remote server
function InitializeEDMRemoteConfigFile
{
	# read config file
    $configfile = "$PSScriptRoot\EDMConfig.json" 
	
	if (-not (Test-Path -Path $configfile))
    {
		$config = [ordered]@{
		EncryptedKeys =  "False"
		Password = ""
		User = ""
		HashFile = "Not set"
		DataStoreName = "Not set"
		EDMAppFolder = "c:\Program Files\Microsoft\EdmUploadAgent\"
		EDMrootFolder = "C:\EDM data\"
		HashFolder = "C:\EDM data\Hash\"
		EDMHostName = "Localhost"
		}
		return $config
    }else
	{
		$json = Get-Content -Raw -Path $configfile
		[PSCustomObject]$configfile = ConvertFrom-Json -InputObject $json
		$EncryptedKeys = $configfile.EncryptedKeys
		$SharedKey = $configfile.Password
	
		if ($EncryptedKeys -eq "True")
		{
			$SharedKey = DecryptSharedKey $SharedKey 
		}
	
		$config = [ordered]@{
		EncryptedKeys = "False"
		Password = "$($SharedKey)"
		User = "$($configfile.User)"
		HashFile = "$($configfile.HashFile)"
		DataStoreName = "$($configfile.DataStoreName)"
		EDMAppFolder = "$($configfile.EDMAppFolder)"
		EDMrootFolder = "$($configfile.EDMrootFolder)"
		HashFolder = "$($configfile.HashFolder)"
		EDMHostName = "$($configfile.EDMHostName)"
		}
		return $config
	}
}

#To write configuration data to json file
function WriteToJsonFile
{
	if (Test-Path "$PSScriptRoot\EDMConfig.json")
    {
        $date = Get-Date -Format "yyyyMMddHHmmss"
        Move-Item "$PSScriptRoot\EDMConfig.json" "$PSScriptRoot\bck_EDMConfig_$date.json"
        Write-Host "`nThe old config file moved to 'bck_EDMConfig_$date.json'"
    }
    $config | ConvertTo-Json | Out-File "$PSScriptRoot\EDMConfig.json"
    Write-Host "Setup completed. New config file was created." -ForegroundColor Green
}

#To write configuration data to json file used at the remote server
function WriteToRemoteJsonFile
{
	if (Test-Path "$PSScriptRoot\EDM_RemoteConfig.json")
    {
        $date = Get-Date -Format "yyyyMMddHHmmss"
        Move-Item "$PSScriptRoot\EDM_RemoteConfig.json" "$PSScriptRoot\bck_EDM_RemoteConfig_$date.json"
        Write-Host "`nThe old config file moved to 'bck_EDM_RemoteConfig_$date.json'"
    }
	$RemoteConfig | ConvertTo-Json | Out-File "$PSScriptRoot\EDM_RemoteConfig.json"
    Write-Host "Setup completed. New config file was created." -ForegroundColor Green
}

#To create the configuration file that will be used remotely
function CreateRemoteConfigFile
{
	$RemoteConfig = InitializeEDMRemoteConfigFile
	WriteToRemoteJsonFile
}

#To define and/or create the folder used in the Task Scheduler
function CreateScheduledTaskFolder
{
	param([string]$taskFolder)
	
	#Main interface to select folder
	Write-Host "`n`n----------------------------------------------------------------------------------------" -ForegroundColor Yellow
	Write-Host "`n Please be aware that this list of Task Scheduler folder don't show empty folders." -ForegroundColor Red
	Write-Host "`n----------------------------------------------------------------------------------------" -ForegroundColor Yellow
	
	# Generate a unique list of parent folders under task scheduler
	$TSFolder = Get-ScheduledTask
	$uniqueTaskFolder = $TSFolder.TaskPath | Select-Object -Unique
	$tempFolder = $uniqueTaskFolder -replace '^\\(\w+)\\.*?.*','$1'
	$listTaskFolders = $tempFolder | Select-Object -Unique
	foreach ($folder in $listTaskFolders){$SchedulerTaskFolders += @([pscustomobject]@{Name=$folder})}
	
	Write-Host "`nGetting Folders..." -ForegroundColor Green
    $i = 1
    $SchedulerTaskFolders = @($SchedulerTaskFolders | ForEach-Object {$_ | Add-Member -Name "No" -MemberType NoteProperty -Value ($i++) -PassThru})
    
	#List all existing folders under Task Scheduler
    $SchedulerTaskFolders | Select-Object No, Name | Out-Host
	
	# Default folder for EDM tasks
    $EDMTSFolder = "EDM"
	$taskFolder = "\"+$EDMTSFolder+"\"
	$choices  = '&Proceed', '&Change', '&Existing'
	Write-Host "Please consider if you want to use the default location you need select Existing and the option 1." -ForegroundColor Yellow
    $decision = $Host.UI.PromptForChoice("", "Default task Scheduler Folder is '$EDMTSFolder'. Do you want to Proceed, Change the name or use Existing one?", $choices, 0)
    if ($decision -eq 1)
    {
        $ok = $false
        do 
        {
            $newName = Read-Host "Please enter the new name for the Task Scheduler folder"
        }
        until ($newName -ne "")
        $taskFolder = "\"+$newName+"\"
		Write-Host "The name selected for the folder under Task Scheduler is $newName." -ForegroundColor Green
		return $taskFolder
    }if ($decision -eq 0)
	{
		Write-Host "Using the default folder $EDMTSFolder." -ForegroundColor Green
		return $taskFolder
	}else
	{
		$selection = 0
		ReadNumber -max ($i -1) -msg "Enter number corresponding to the current folder in the Task Scheduler" -option ([ref]$selection) 
		$value = $selection - 1
		$EDMTSFolder = $SchedulerTaskFolders[$value].Name
		$taskFolder = "\"+$SchedulerTaskFolders[$value].Name+"\"
		Write-Host "Folder selected for this task $EDMTSFolder " -ForegroundColor Green
		return $taskFolder
	}
	
}

#To create a task on taskscheduler to upload the Hash locally
function CreateEDMHashUploadScheduledTask
{
	# EDM task script
    $taskName = "EDM-HashUpload"
	
	# Call function to set a folder for the task on Task Scheduler
	$taskFolder = CreateScheduledTaskFolder
	
	$config = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $config
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$EDMSupportFolder = $config.EDMSupportFolder
	
	# Task execution
    $validDays = 1
    $choices  = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice("", "The task on task scheduler will be set for '$($validDays)' day(s), do you want to change?", $choices, 1)
	Write-Host "`nYou can change later in the task '$($taskName)' under Task Scheduler`n" -ForegroundColor Yellow
    if ($decision -eq 0)
    {
        ReadNumber -max 31 -msg "Enter number of days (Between 1 to 31). Remember check the retention period in your workspace in Logs Analtytics." -option ([ref]$validDays)
    }

    # calculate date
    $dt = Get-Date 
    $reminder = $dt.Day % $validDays
    $dt = $dt.AddDays(-$reminder)
    $startTime = [datetime]::new($dt.Year, $dt.Month, $dt.Day, $dt.Hour, $dt.Minute, 0)

    #create task
    $trigger = New-ScheduledTaskTrigger -Once -At $startTime -RepetitionInterval (New-TimeSpan -Days $validDays)
    $action = New-ScheduledTaskAction -Execute "`"$PSHOME\pwsh.exe`"" -Argument ".\EDMHashUpload.ps1" -WorkingDirectory $EDMSupportFolder
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries `
         -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1)

    if (Get-ScheduledTask -TaskName $taskName -TaskPath $taskFolder -ErrorAction SilentlyContinue) 
    {
        Write-Host "`nScheduled task named '$taskName' already exists.`n" -ForegroundColor Yellow
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		cls
    }
    else 
    {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings `
        -RunLevel Highest -TaskPath $taskFolder -ErrorAction Stop | Out-Null
        Write-Host "`nScheduled task named '$taskName' was created.`nFor security reasons you have to specify run as account manually.`n" -ForegroundColor Yellow
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		cls
    }
}

#To create a task on taskscheduler to upload the Hash on the remote server
function CreateEDMRemoteHashUploadScheduledTask
{
	# EDM remote task script
    $taskName = "EDM-RemoteHashUpload"
	
	# Call function to set a folder for the task on Task Scheduler
	$taskFolder = CreateScheduledTaskFolder
	
	$config = "$PSScriptRoot\EDM_RemoteConfig.json"
	$json = Get-Content -Raw -Path $config
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	
	# Task execution
    $validDays = 1
    $choices  = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice("", "The task on task scheduler will be set for '$($validDays)' day(s), do you want to change?", $choices, 1)
	Write-Host "`nYou can change later in the task '$($taskName)' under Task Scheduler`n" -ForegroundColor Yellow
    if ($decision -eq 0)
    {
        ReadNumber -max 31 -msg "Enter number of days (Between 1 to 31). Remember check the retention period in your workspace in Logs Analtytics." -option ([ref]$validDays)
    }

    # calculate date
    $dt = Get-Date 
    $reminder = $dt.Day % $validDays
    $dt = $dt.AddDays(-$reminder)
    $startTime = [datetime]::new($dt.Year, $dt.Month, $dt.Day, $dt.Hour, $dt.Minute, 0)

    #create task
    $trigger = New-ScheduledTaskTrigger -Once -At $startTime -RepetitionInterval (New-TimeSpan -Days $validDays)
    $action = New-ScheduledTaskAction -Execute "`"$PSHOME\pwsh.exe`"" -Argument ".\EDM_RemoteHashUpload.ps1" -WorkingDirectory $PSScriptRoot
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries `
         -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1)

    if (Get-ScheduledTask -TaskName $taskName -TaskPath $taskFolder -ErrorAction SilentlyContinue) 
    {
        Write-Host "`nScheduled task named '$taskName' already exists.`n" -ForegroundColor Yellow
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		cls
    }
    else 
    {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings `
        -RunLevel Highest -TaskPath $taskFolder -ErrorAction Stop | Out-Null
        Write-Host "`nScheduled task named '$taskName' was created.`nFor security reasons you have to specify run as account manually.`n" -ForegroundColor Yellow
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		cls
    }
}

#To create a task on taskscheduler to hast the original data
function CreateEDMHashCreateScheduledTask
{
	# EDM script
    $taskName = "EDM-CreateHash"
	
	# Call function to set a folder for the task on Task Scheduler
	$taskFolder = CreateScheduledTaskFolder
	
	$config = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $config
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$EDMSupportFolder = $config.EDMSupportFolder
	
	# Task execution
    $validDays = 1
    $choices  = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice("", "The task on task scheduler will be set for '$($validDays)' day(s), do you want to change?", $choices, 1)
	Write-Host "`nYou can change later in the task '$($taskName)' under Task Scheduler`n" -ForegroundColor Yellow
    if ($decision -eq 0)
    {
        ReadNumber -max 31 -msg "Enter number of days (Between 1 to 31). Remember check the retention period in your workspace in Logs Analtytics." -option ([ref]$validDays)
    }

    # calculate date
    $dt = Get-Date 
    $reminder = $dt.Day % $validDays
    $dt = $dt.AddDays(-$reminder)
    $startTime = [datetime]::new($dt.Year, $dt.Month, $dt.Day, $dt.Hour, $dt.Minute, 0)

    #create task
    $trigger = New-ScheduledTaskTrigger -Once -At $startTime -RepetitionInterval (New-TimeSpan -Days $validDays)
    $action = New-ScheduledTaskAction -Execute "`"$PSHOME\pwsh.exe`"" -Argument ".\EDMCreateHash.ps1" -WorkingDirectory $EDMSupportFolder
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries `
         -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1)

    if (Get-ScheduledTask -TaskName $taskName -TaskPath $taskFolder -ErrorAction SilentlyContinue) 
    {
        Write-Host "`nScheduled task named '$taskName' already exists.`n" -ForegroundColor Yellow
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		cls
    }
    else 
    {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings `
        -RunLevel Highest -TaskPath $taskFolder -ErrorAction Stop | Out-Null
        Write-Host "`nScheduled task named '$taskName' was created.`nFor security reasons you have to specify run as account manually.`n" -ForegroundColor Yellow
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		cls
    }
}

#To create a task on taskscheduler to copy the hast to a remote server
function CreateEDMHashCopyScheduledTask
{
	# EDM Hash copy
    $taskName = "EDM-CopyHashToRemoteServer"
	
	# Call function to set a folder for the task on Task Scheduler
	$taskFolder = CreateScheduledTaskFolder
	
	$config = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $config
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	$EDMSupportFolder = $config.EDMSupportFolder
	
	# Task execution
    $validDays = 1
    $choices  = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice("", "The task on task scheduler will be set for '$($validDays)' day(s), do you want to change?", $choices, 1)
	Write-Host "`nYou can change later in the task '$($taskName)' under Task Scheduler`n" -ForegroundColor Yellow
    if ($decision -eq 0)
    {
        ReadNumber -max 31 -msg "Enter number of days (Between 1 to 31). Remember check the retention period in your workspace in Logs Analtytics." -option ([ref]$validDays)
    }

    # calculate date
    $dt = Get-Date 
    $reminder = $dt.Day % $validDays
    $dt = $dt.AddDays(-$reminder)
    $startTime = [datetime]::new($dt.Year, $dt.Month, $dt.Day, $dt.Hour, $dt.Minute, 0)

    #create task
    $trigger = New-ScheduledTaskTrigger -Once -At $startTime -RepetitionInterval (New-TimeSpan -Days $validDays)
    $action = New-ScheduledTaskAction -Execute "`"$PSHOME\pwsh.exe`"" -Argument ".\EDMCopyHash.ps1" -WorkingDirectory $EDMSupportFolder
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries `
         -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1)

    if (Get-ScheduledTask -TaskName $taskName -TaskPath $taskFolder -ErrorAction SilentlyContinue) 
    {
        Write-Host "`nScheduled task named '$taskName' already exists.`n" -ForegroundColor Yellow
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		cls
    }
    else 
    {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings `
        -RunLevel Highest -TaskPath $taskFolder -ErrorAction Stop | Out-Null
        Write-Host "`nScheduled task named '$taskName' was created.`nFor security reasons you have to specify run as account manually.`n" -ForegroundColor Yellow
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		cls
    }
}

#To sign the scripts used in this solution, using a self signed or a 3rd party certificate
function SelfSignScripts
{
	#Menu for self signed or use an own certificate
	<#
	.NOTES
	EDM scripts can request change your Execution Policy to bypass to be executed, using PS:\> Set-ExecutionPolicy -ExecutionPolicy bypass.
	In some organizations for security concerns this cannot be set, and the script need to be digital signed.
	This function permit to use a self-signed certificate or use an external one. 
	BE AWARE : The external certificate needs to be for a CODE SIGNING is not a coomon SSL certificate.
	#>
	
	Write-Host "`n`n----------------------------------------------------------------------------------------" -ForegroundColor Yellow
	Write-Host "`nThis option will be digital sign all EDM scripts." -ForegroundColor DarkYellow
	Write-Host "The certificate used is the kind of CodeSigning not a SSL certificate" -ForegroundColor DarkYellow
	Write-Host "If you choose to select your own certificate be aware of this." -ForegroundColor DarkYellow
	Write-Host "`n----------------------------------------------------------------------------------------" -ForegroundColor Yellow
	Write-Host "`n`n" 
	
	# Decide if you want to progress or not
	$choices  = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice("", "Do you want to proceed with the digital signature for all the scripts?", $choices, 1)
	if ($decision -eq 1)
	{
		Write-Host "`nYou decide don't proceed with the digital signature." -ForegroundColor DarkYellow
		Write-Host "Remember to use EDM scripts set permissions with Administrator rigths on Powershel using:." -ForegroundColor DarkYellow
		Write-Host "`nSet-ExecutionPolicy -ExecutionPolicy bypass." -ForegroundColor Green
	} else
	{
		
		#Review if some certificate was installed previously
		Write-Host "`nGetting Code Signing certificates..." -ForegroundColor Green
		$i = 1
		$certificates = @(Get-ChildItem Cert:\CurrentUser\My | Where-Object {$_.EnhancedKeyUsageList -like "*Code Signing*"}| Select-Object Subject, Thumbprint, NotBefore, NotAfter | ForEach-Object {$_ | Add-Member -Name "No" -MemberType NoteProperty -Value ($i++) -PassThru})
		$certificates | Format-Table No, Subject, Thumbprint, NotBefore, NotAfter | Out-Host
		
		if ($certificates.Count -eq 0)
		{
			Write-Host "`nNo certificates for Code Signing was found." -ForegroundColor Red
			Write-Host "Proceeding to create one..."
			Write-Host "This can take a minute and a pop-up will appear, please accept to install the certificate."
			Write-Host "After finish you'll be forwarded to the initial Certificate menu."
			CreateCodeSigningCertificate
			SelfSignScripts
		} else{
			$selection = 0
			ReadNumber -max ($i -1) -msg "Enter number corresponding to the certificate to use" -option ([ref]$selection)
			#Obtain certificate from local store
			$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object {$_.Thumbprint -eq $certificates[$selection - 1].Thumbprint}
			
			#Sign EDM Scripts
			$config = "$PSScriptRoot\EDMConfig.json"
			if(-not (Test-Path -Path $config))
			{
				$config = "$PSScriptRoot\EDM_RemoteConfig.json"
				$json = Get-Content -Raw -Path $config
				[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
				$EDMrootFolder = $config.EDMrootFolder+"EDM*.ps1"
				
				$files = Get-ChildItem -Path $EDMrootFolder
				foreach($file in $files)
				{
					Write-Host "`Signing..."
					Write-Host "$($file.Name)" -ForegroundColor Green
					Set-AuthenticodeSignature -FilePath ".\$($file.Name)" -Certificate $cert
				}
				
			}else
			{
			$json = Get-Content -Raw -Path $config
			[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
			$EDMrootFolder = $config.EDMrootFolder+"EDM*.ps1"
			$EDMrootFolder2Sign = $config.EDMSupportFolder
			$EDMSupportFolder = $config.EDMSupportFolder+"EDM*.ps1"
			
			$files = Get-ChildItem -Path $EDMrootFolder
			$SupportFiles = Get-ChildItem -Path $EDMSupportFolder
			
			foreach($file in $files)
			{
				Write-Host "`Signing..."
				Write-Host "$($file.Name)" -ForegroundColor Green
				Set-AuthenticodeSignature -FilePath ".\$($file.Name)" -Certificate $cert
			}
			foreach($SupportFile in $SupportFiles)
			{
				Write-Host "`Signing..."
				$FileName = $SupportFile.Name
				$File2Sign = $EDMrootFolder2Sign+$FileName
				Write-Host "$($File2Sign)" -ForegroundColor Green
				Set-AuthenticodeSignature -FilePath $File2Sign -Certificate $cert
			}
			}
		}
	}
	
	Write-Host "`nYou can back to this menu at anytime to sign the scripts." -ForegroundColor DarkYellow
	Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		
	cls
}

#To create a self signed certificate to sign the scripts
function CreateCodeSigningCertificate
{
	#CMDLET to create certificate
	$EDMcert = New-SelfSignedCertificate -Subject "CN=EDM PowerShell Code Signing Cert" -Type "CodeSigning" -CertStoreLocation "Cert:\CurrentUser\My" -HashAlgorithm "sha256"
		
	### Add Self Signed certificate as a trusted publisher (details here https://adamtheautomator.com/how-to-sign-powershell-script/)
		
		# Add the self-signed Authenticode certificate to the computer's root certificate store.
		## Create an object to represent the CurrentUser\Root certificate store.
		$rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("Root","CurrentUser")
		## Open the root certificate store for reading and writing.
		$rootStore.Open("ReadWrite")
		## Add the certificate stored in the $authenticode variable.
		$rootStore.Add($EDMcert)
		## Close the root certificate store.
		$rootStore.Close()
			 
		# Add the self-signed Authenticode certificate to the computer's trusted publishers certificate store.
		## Create an object to represent the CurrentUser\TrustedPublisher certificate store.
		$publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher","CurrentUser")
		## Open the TrustedPublisher certificate store for reading and writing.
		$publisherStore.Open("ReadWrite")
		## Add the certificate stored in the $authenticode variable.
		$publisherStore.Add($EDMcert)
		## Close the TrustedPublisher certificate store.
		$publisherStore.Close()	
}

#To encrypt the password stored in the EDM configuration file
function EncryptPasswords
{
    # read config file
    $CONFIGFILE = "$PSScriptRoot\EDMConfig.json"  
    if (-not (Test-Path -Path $CONFIGFILE))
    {
        Write-Host "`nMissing config file '$CONFIGFILE'." -ForegroundColor Yellow
        return
    }
    $json = Get-Content -Raw -Path $CONFIGFILE
    [PSCustomObject]$config = ConvertFrom-Json -InputObject $json
    $EncryptedKeys = $config.EncryptedKeys

    # check if already encrypted
    if ($EncryptedKeys -eq "True")
    {
        Write-Host "`nAccording to the configuration settings (EncryptedKeys: True), passwords are already encrypted." -ForegroundColor Yellow
        Write-Host "No actions taken."
        return
    }

    # encrypt secrets
    $ClientSecretValue = $config.Password

    $ClientSecretValue = $ClientSecretValue | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString

    # write results to the file
    $config.EncryptedKeys = "True"
    $config.Password = $ClientSecretValue

    $date = Get-Date -Format "yyyyMMddHHmmss"
    Move-Item "EDMConfig.json" "bck_EDMConfig_$date.json"
    Write-Host "`nPasswords encrypted."
    Write-Host "The old config file moved to 'bck_EDMConfig_$date.json'" -ForegroundColor Green
    $config | ConvertTo-Json | Out-File $CONFIGFILE

    Write-Host "Warning!" -ForegroundColor Yellow
    Write-Host "Please note that encrypted passwords can be decrypted only on this machine, using the same account." -ForegroundColor Yellow
	
	Write-Host "`n### The backup file contains your credentials in clear text, take precautions ###" -ForegroundColor Red
	Write-Host -NoNewLine "`n`nTo back to the main menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	
	cls
}

#To encrypt the password stored st the remote server
function EncryptRemotePasswords
{
    # read config file
    $CONFIGFILE = "$PSScriptRoot\EDM_RemoteConfig.json"  
    if (-not (Test-Path -Path $CONFIGFILE))
    {
        Write-Host "`nMissing config file '$CONFIGFILE'." -ForegroundColor Yellow
        return
    }
    $json = Get-Content -Raw -Path $CONFIGFILE
    [PSCustomObject]$RemoteConfig = ConvertFrom-Json -InputObject $json
    $EncryptedKeys = $RemoteConfig.EncryptedKeys

    # check if already encrypted
    if ($EncryptedKeys -eq "True")
    {
        Write-Host "`nAccording to the configuration settings (EncryptedKeys: True), passwords are already encrypted." -ForegroundColor Yellow
        Write-Host "No actions taken."
        return
    }

    # encrypt secrets
    $ClientSecretValue = $RemoteConfig.Password

    $ClientSecretValue = $ClientSecretValue | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString

    # write results to the file
    $RemoteConfig.EncryptedKeys = "True"
    $RemoteConfig.Password = $ClientSecretValue

    $date = Get-Date -Format "yyyyMMddHHmmss"
    Move-Item "EDM_RemoteConfig.json" "bck_EDM_RemoteConfig_$date.json"
    Write-Host "`nPasswords encrypted."
    Write-Host "The old config file moved to 'EDMConfig_$date.json'" -ForegroundColor Green
    $RemoteConfig | ConvertTo-Json | Out-File $CONFIGFILE

    Write-Host "Warning!" -ForegroundColor Yellow
    Write-Host "Please note that encrypted passwords can be decrypted only on this machine, using the same account." -ForegroundColor Yellow
	
	Write-Host "`n### The backup file contains your credentials in clear text, take precautions ###" -ForegroundColor Red
	Write-Host -NoNewLine "`n`nTo back to the main menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	
	cls
}

#To set the parameters AllowedBadLinesPercentage, by default is set to 5, and ColumnSeparator, by default works with CSV
function EDMAdditionalConfiguration
{
	cls
	
	$config = "$PSScriptRoot\EDMConfig.json"
	$json = Get-Content -Raw -Path $config
	[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
	
	$EDMFolder = $config.EDMAppFolder
	Set-Location $EDMFolder | cmd
	
	write-host "`n##########################################################################################"
	write-host "`nThe current configuration for Allow Bad Lines Percentage attribute is '$($config.BadLinesPercentage)'" -ForegroundColor Green
	write-host "The current configuration for Column Separator is set to '$($config.ColumnSeparator)'" -ForegroundColor Green
	write-host "`n##########################################################################################"
	
	# Decide if you want to progress or not
	$choices  = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice("", "`nDo you want to change these values?", $choices, 1)
	if ($decision -eq 1)
	{
		Write-Host "`nYou have decided not to change the setting values." -ForegroundColor DarkYellow
		Write-Host "These values are used to hash the data and upload the data to your M365 Teanant." -ForegroundColor DarkYellow
		Write-Host "Values are set to AllowedBadLinesPercentage '$($config.BadLinesPercentage)' and ColumnSeparator to '$($config.ColumnSeparator)'." -ForegroundColor DarkYellow
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		return
	}else
	{
		cls
		write-host "`n##########################################################################################"
		write-host "`nThe current configuration that you will change are:"
		write-host "`n`tAllowBadLinesPercentage is set to: '$($config.BadLinesPercentage)'"
		write-host "`tColumnSeparator is set to: '$($config.ColumnSeparator)'"
		write-host "`n##########################################################################################"
		
		# Set value for AllowBadLinesPercentage
		$BadLinesPercentage = $config.BadLinesPercentage
		$choices  = '&Yes', '&No'
		$decision = $Host.UI.PromptForChoice("", "`nAllowedBadLinesPercentage is set to '$($BadLinesPercentage)', do you want to change?", $choices, 1)
		if ($decision -eq 0)
		{
			ReadNumber -max 50 -msg "Enter the percentage of allowed bad lines from your data file (Between 1 to 50)" -option ([ref]$BadLinesPercentage)
			$config.BadLinesPercentage = $BadLinesPercentage
			write-host "`nAllowBadLinesPercentage is set to: '$($config.BadLinesPercentage)'" -ForegroundColor Green
		}else
		{
			write-host "`nYou decide not change the value AllowBadLinesPercentage that is set to: '$($config.BadLinesPercentage)'" -ForegroundColor DarkYellow
		}
		
		# Set value for ColumnSeparator
		$ColumnSeparator = $config.ColumnSeparator
		$choices  = '&Tab','&Pipe','&Csv','&No'
		$decision = $Host.UI.PromptForChoice("", "`nColumnSeparator is set to '$($ColumnSeparator)', do you want to change?", $choices, 3)
		if ($decision -eq 0)
		{
			$ColumnSeparator = "{Tab}"
			$config.ColumnSeparator = $ColumnSeparator
			write-host "`nColumnSeparator is set to: '$($config.ColumnSeparator)'" -ForegroundColor Green
		}elseif($decision -eq 1)
		{
			$ColumnSeparator = "|"
			$config.ColumnSeparator = $ColumnSeparator
			write-host "`nColumnSeparator is set to: '$($config.ColumnSeparator)'" -ForegroundColor Green
		}elseif($decision -eq 2)
		{
			$ColumnSeparator = "Csv"
			$config.ColumnSeparator = $ColumnSeparator
			write-host "`nColumnSeparator is set to: '$($config.ColumnSeparator)'" -ForegroundColor Green
		}else
		{
			write-host "`nYou decide not change the value ColumnSeparator that is set to: '$($config.ColumnSeparator)'" -ForegroundColor DarkYellow
			
		}
		
		
	}
		Start-Sleep -s 2
		
		cls
		write-host "`n##########################################################################################"
		write-host "`nThe new configuration is set to:"
		write-host "`n`tAllowBadLinesPercentage is set to: '$($config.BadLinesPercentage)'" -ForegroundColor DarkGreen
		write-host "`tColumnSeparator is set to: '$($config.ColumnSeparator)'" -ForegroundColor DarkGreen
		write-host "`n##########################################################################################"
		
		WriteToJsonFile
		
		Write-Host -NoNewLine "`n`nTo back to the previous menu, please press any key." -ForegroundColor DarkCyan
		$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		cls	
}

#Menu number 1 to set the initial configuration
function SubMenuInitialization
{
	Clear-Host
	cls
	
	Write-Host "`n`n----------------------------------------------------------------------------------------"
	Write-Host "`nWelcome to the Initilization Menu!" -ForegroundColor Blue
	Write-Host "This is a first configuration about folders, credentials, encrypt password, validate the EDM Connection and set some additional configuration" -ForegroundColor Blue
	$choice = 1
	while ($choice -ne "0")
	{
		$config = "$PSScriptRoot\EDMConfig.json"
		$json = Get-Content -Raw -Path $config
		[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
		Write-Host "`n----------------------------------------------------------------------------------------"
		Write-Host "`n###`t1 - Initial Setup for EDM`t###" -ForegroundColor Blue
		Write-Host "`nWhat do you want to do?"
		Write-Host "`t[1] - Folder selection for EDM (principal folders used)"
		Write-Host "`t[2] - Get credentials for connection"	
		Write-Host "`t[3] - Encrypt passwords"
		Write-Host "`t[4] - Connect to EDM service"
		Write-Host "`t[9] - Optional configuration for EDM (Bad lines percentage '$($config.BadLinesPercentage)' and Column Separator '$($config.ColumnSeparator)' by default)"
		Write-Host "`t[0] - Back to main menu"
		Write-Host "`n"
		Write-Host "`nPlease choose option:"
		
		$choice = ([System.Console]::ReadKey($true)).KeyChar
		switch ($choice) {
        "1" {SelectEDMPaths; break}
		"2" {GetEDMUserCredentials; break}
		"3" {EncryptPasswords; break}
		"4" {
				Connect2EDM
				TakeAPause
				break
			}
		"9" {EDMAdditionalConfiguration; break}
		"0" {cls;return}
		}
	
	}
}

#Menu number 2 to hash the data and upload the data
function SubMenuEDMGeneration
{
	Clear-Host
	cls
	
	Write-Host "`n`n----------------------------------------------------------------------------------------"
	Write-Host "`nWelcome to the EDM Generation Menu!" -ForegroundColor DarkYellow
	Write-Host "This is the 2nd step to set DataStore name, get the Schema file, select your data and hash the data." -ForegroundColor DarkYellow
	$choice = 1
	while ($choice -ne "0")
	{
		Write-Host "`n----------------------------------------------------------------------------------------"
		Write-Host "`n###`t2 - Generate EDM Hash & upload`t###" -ForegroundColor DarkYellow
		Write-Host "`nWhat do you want to do?"
		Write-Host "`t[1] - Get EDM datastores"
		Write-Host "`t[2] - Get Schema file"
		Write-Host "`t[3] - Set and validate EDM data"
		Write-Host "`t[4] - Create Hash for your data"
		Write-Host "--- Before you continue, if you want to use another server to upload your data please select menu 3 on the main menu---" -ForegroundColor Magenta
		Write-Host "`t[5] - Upload Hash data"
		Write-Host "`t[6] - EDM Hash upload status"
		Write-Host "`t[7] - Create task to create Hash files"
		Write-Host "`t[8] - Create task to upload Hash to Microsoft 365"
		Write-Host "`t[0] - Back to main menu"
		Write-Host "`n"
		Write-Host "`nPlease choose option:"
		
		$choice = ([System.Console]::ReadKey($true)).KeyChar
		switch ($choice) {
        "1" {GetDataStores;break}
		"2" {GetSchemaFile; break}
		"3" {ValidateEDMData; break}
		"4" {EDMHashCreation; break}
		"5" {EDMHashUpload; break}
		"6" {EDMUploadStatus; break}
		"7" {CreateEDMHashCreateScheduledTask; break}
		"8" {CreateEDMHashUploadScheduledTask; break}
		"0" {cls;return}
		}
	
	}	
}

#Menu number 3 copy hash and configuration files to a remote server
function SubMenuRemoteUpload
{
	Clear-Host
	cls
	
	Write-Host "`n`n----------------------------------------------------------------------------------------"
	Write-Host "`nEDM for remote upload menu" -ForegroundColor Magenta
	Write-Host "If you want to upload from another server this menu is for that." -ForegroundColor Magenta
	$choice = 1
	while ($choice -ne "0")
	{
		Write-Host "`n----------------------------------------------------------------------------------------"
		Write-Host "`n###`t3 - Copy files needed and Hash to a remote server`t###" -ForegroundColor Magenta
		Write-Host "`nWhat do you want to do?"
		Write-Host "`t[1] - Copy the data needed to a remote server"
		Write-Host "`t[2] - Create a task to copy Hash data daily"
		Write-Host "`t[0] - Back to main menu"
		Write-Host "`n"
		Write-Host "`nPlease choose option:"
		
		$choice = ([System.Console]::ReadKey($true)).KeyChar
		switch ($choice) {
		"1" {EDMCopyDataNeeded; break}
		"2" {CreateEDMHashCopyScheduledTask; break}
		"0" {cls;return}
		}
	
	}
}

#Menu number 4 activities on the remote server
function SubMenuRemoteConfig
{
	Clear-Host
	cls
	
	Write-Host "`n`n----------------------------------------------------------------------------------------" -ForegroundColor DarkRed
	Write-Host "`n`t`tWelcome to Remote Menu!"
	Write-Host "`nThis menu is to be used only on the remote server used to upload hash data to Microsoft 365" 
	Write-Host "Used only if you are using a 2nd Server to upload Hash data" 
	$choice = 1
	while ($choice -ne "0")
	{
		Write-Host "`n----------------------------------------------------------------------------------------" -ForegroundColor DarkRed
		Write-Host "`n###`t4 - Remote server activities`t###" -ForegroundColor DarkRed
		Write-Host "`nWhat do you want to do?"
		Write-Host "`t[1] - Please validate your new folders."
		Write-Host "`t[2] - Sign the scripts again."
		Write-Host "`t[3] - Change credentials, only if you want to use another account."
		Write-Host "`t[4] - Encrypt password."
		Write-Host "`t[5] - Upload Hash to Microsoft 365."
		Write-Host "`t[6] - Check Hash upload status."
		Write-Host "`t[7] - Create a task to upload Hash to Microsoft 365."
		Write-Host "`t[0] - Back to main menu"
		Write-Host "`n"
		Write-Host "`nPlease choose option:"
		
		$choice = ([System.Console]::ReadKey($true)).KeyChar
		switch ($choice) {
		"1" {SelectEDMRemotePaths; break}
		"2" {SelfSignScripts; break}
		"3" {GetEDMRemoteUserCredentials; break}
		"4" {EncryptRemotePasswords; break}
		"5" {EDMHashUpload; break}
		"6" {EDMUploadStatus; break}
		"7" {CreateEDMRemoteHashUploadScheduledTask; break}
		"0" {cls;return}
		}
	
	}
}

#Menu number 9 activities on the remote server
function SubMenuSupportingElements
{
	Clear-Host
	cls
	
	Write-Host "`n`n----------------------------------------------------------------------------------------"
	Write-Host "`nWelcome to Support element Menu!" -ForegroundColor Gray
	Write-Host "Here you can sign the scripts" -ForegroundColor Gray
	$choice = 1
	while ($choice -ne "0")
	{
		Write-Host "`n----------------------------------------------------------------------------------------"
		Write-Host "`n###`t9 - Supporting elements`t###" -ForegroundColor Gray
		Write-Host "`nWhat do you want to do?"
		Write-Host "`t[1] - Sign EDM scripts"
		Write-Host "`t[0] - Back to main menu"
		Write-Host "`n"
		Write-Host "`nPlease choose option:"
		
		$choice = ([System.Console]::ReadKey($true)).KeyChar
		switch ($choice) {
		"1" {SelfSignScripts; break}
		"0" {cls;return}
		}
	
	}
}

#Menu number 8 about this script
function AboutThisScript
{
	cls
	
	Write-Host "`n`n########################################################################################" -ForegroundColor Cyan
	Write-Host "`n`t`tAbout EDM setup script." -ForegroundColor DarkCyan
	Write-Host "`nSOURCE SCRIPT:" -ForegroundColor DarkGreen -NoNewline
	Write-Host "https://aka.ms/EDMPostTasks"
	Write-Host "About EDM :" -ForegroundColor DarkGreen -NoNewline
	Write-Host "https://learn.microsoft.com/en-us/purview/sit-get-started-exact-data-match-based-sits-overview"
	Write-Host "`nThis script is thought to help in all the steps where the EDM Upload Agent is required."
	Write-Host "Normally the post tasks related to EDM, associated to this app are:"	
	Write-Host "`n`tA. Validate the connection"
	Write-Host "`tB. Validate the datastores available"
	Write-Host "`tC. Request the XML schema file assocaited to the datastore"
	Write-Host "`tD. Hash the data to be uploaded"
	Write-Host "`tE. Upload the hashed data"
	Write-Host "`tF. Check the progress"
	Write-Host "`nThose are the common tasks, but for some cases is required to copy the hash file to a remote server to upload to Microsoft 365, avoiding have original file on the same server used to upload the data."
	Write-Host "This script permit to facilite that task, generating a task to hash first, then other task to move the hash to a remote server."
	Write-Host "At the remote server we can create a task to upload that data to Microsoft 365."
	Write-Host "`n########################################################################################" -ForegroundColor Cyan
	Write-Host "`n`nIf you want to know about the author, this is my LinkedIn profile https://www.linkedin.com/in/profesorkaz/"
	Write-Host -NoNewLine "`n`nTo back to the main menu, please press any key." -ForegroundColor DarkCyan
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	
	cls
	return
}

############
# Main code
############
function MainMenu
{
	Clear-Host
	cls
	Write-Host "`nRunning prerequisites check..."
	CheckPrerequisites

	$configfile = "$PSScriptRoot\EDM_RemoteConfig.json"
	if (-not (Test-Path -Path $configfile))
	{
		$config = "$PSScriptRoot\EDMConfig.json"
		if (-not (Test-Path -Path $config))
		{
			$config = InitializeEDMConfigFile
			WriteToJsonFile
			Start-Sleep -s 1
			InitializeHostName
		}
	}

	Write-Host "`n`n----------------------------------------------------------------------------------------"
	Write-Host "`nWelcome to the EDM setup script!" -ForegroundColor Green
	Write-Host "Script allows to automatically execute setup steps." -ForegroundColor Green
	Write-Host "`n----------------------------------------------------------------------------------------"

	### Validate hostname
	$config = "$PSScriptRoot\EDMConfig.json"
	$config2 = "$PSScriptRoot\EDMConfig.json"

	if (-not (Test-Path -Path $config))
	{
		$config = "$PSScriptRoot\EDM_RemoteConfig.json"
		$json = Get-Content -Raw -Path $config
		[PSCustomObject]$RemoteConfig = ConvertFrom-Json -InputObject $json
		$EDMHostName = $RemoteConfig.EDMHostName
		$EDMHostExecuting = hostname
	}else
	{
		$json = Get-Content -Raw -Path $config
		[PSCustomObject]$config = ConvertFrom-Json -InputObject $json
		$EDMHostName = $config.EDMHostName
		$EDMHostExecuting = hostname
	}


	If($EDMHostName -ne $EDMHostExecuting)
	{
		Write-Host "`n####################################################################################" -ForegroundColor Red
		Write-Host "`nYou are executing in a remote server" -ForegroundColor DarkCyan
		Write-Host "Work with the menu 4 (Remote server activities) " -ForegroundColor DarkCyan
		Write-Host "`n####################################################################################" -ForegroundColor Red
	}

	$choice = 1
	while ($choice -ne "0")
	{
		Write-Host "`n###`t`tMain Menu`t`t###" -ForegroundColor Green
		Write-Host "`nWhat do you want to do?"
		Write-Host "`t[1] - Initial Setup for EDM"
		Write-Host "`t[2] - Generate EDM Hash & upload"
		Write-Host "`t[3] - Copy files needed and Hash to a remote server"
		if (-not (Test-Path -Path $config2))
		{
			Write-Host "`t[4] - Remote server activities" -ForegroundColor Green
		}else
		{
			Write-Host "`t[4] - Remote server activities"
		}
		Write-Host "`t[8] - About this Script"
		Write-Host "`t[9] - Supporting elements"
		Write-Host "`t[0] - Exit"
		Write-Host "`n"
		Write-Host "`nPlease choose option:"

		$choice = ([System.Console]::ReadKey($true)).KeyChar
		switch ($choice) {
			"1" {SubMenuInitialization;break}
			"2" {SubMenuEDMGeneration;break}
			"3" {SubMenuRemoteUpload;break}
			"4" {SubMenuRemoteConfig;break}
			"8" {AboutThisScript;break}
			"9" {SubMenuSupportingElements; break}
			"0" {
					$OriginalPath = $PSScriptRoot
					Set-Location $OriginalPath | cmd
				exit}
		}
	}
}
MainMenu