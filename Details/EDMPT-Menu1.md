# Menu 1 - Initial Setup for EDM - Explained

> [!NOTE]
> Page under construction please back soon.

This is the main menu that we need to set, to start using EDMPT, in this one, the same script will start fullfil the file EDMConfig.json that contains all the info that we will need during all the process. 

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/ba857e59-e482-46c5-bf57-7c33e85e141c"></p>
<p align="center">1 - Initial Setup for EDM</p>

## [1] - Folder selection for EDM (principal folders used)

To use EDMPT is required set different folders, is recommended to have separate folders for **"Hash"** data and **"Schema"**, the **"Root"** folder needs to contains the previous 2, and the first folder required is where was EDMUploadAgent was installed, normally by default is located at __C:\Program Files\Microsoft\EdmUploadAgent\__ .
You will have the option to maintain the values, or change.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/07242ab3-e710-48e7-8390-827ff9508570"></p>
<p align="center">1 - Folder selection - default values</p>

At the case that you decide to change the values the same script will be prompt to select these folders:
* EDMAppFolder : Where EDMUploadAgent.exe is located.
* EDMrootFolder : Where EDM_Setup.ps1 will be executed, is recommended to have a dedicated folder.
* HashFolder : Where the hashed data will be copied.
* SchemaFolder : Where the schema file will be located, this schema is a XML file returned from the datastore selected.
* EDMSupportFolder : Where the support folder is located, this support folder contains 4 scripts used to build the tasks to automate some activities through use task scheduler. This folder with the scripts are available on the same repository to be donwloaded.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/4eaaa2c5-f236-446c-ade0-0918c11b9ca5"></p>
<p align="center">1 - Folder selection</p>

After the folders are selected the **new Paths** will be displayed, please check, and if you need to change the default folder you can run the script and the menu 1 from this submenu to change the value at any time.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/e4a38bcf-1e93-4485-a8f0-07d06855d1c7"></p>
<p align="center">1 - Folder post selection</p>

These folder will be updated at EMConfig.json file, values can be change manually at file level, but use the EDM_Setup.ps1 script simplify the activity.

## [2] - Get credentials for connection

You will be prompted to add your credentials, or the user used to upload the **hashed data** to your Microsoft 365 Tenant.
> [!IMPORTANT]
> The user used in this step needs to be part of a previously security group created in your Tenant with the name EDM_DataUploaders.


**__To back to the main text related to EDM PT execution you can press [here](../About_EDMPT_Solution.md)__**
