# About EDM PT Solution
## Let´s go through the menus

When EDM_Setup.ps1 is executed the first time a file called EDMConfig.json will be created, all the configuration used by EDM will be added to this file.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/73902c38-4bb4-4713-af47-8e19746891c9"></p>
<p align="center">Initial EDMCOnfig.json file</p>

This configuration file will be populated during you go through the different menus.

EDM PT solution is built with some menus that permit to group the different activities.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/53c2ca9b-35cc-4972-b84c-bda1578327a3"></p>
<p align="center">EDM PT main menu</p>

Those menus will be explain next.

## 1 - Initial Setup for EDM
This first menu permit to set all the initial configuration required to execute the solution.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/02ced46f-074b-4424-a798-8a28672b0837"></p>
<p align="center">1 - Initial Setup for EDM</p>

In this section we will do:
1. [1]Configure the path for different folders used by EDMPT.
  * EDMAppFolder : Folder where EDM Upload Agent was installed.
  * EDMrootFolder : Where all the folders used by EDM and scripts will be located.
  * HashFolder : Where the **Hash file** will be located.
  * SchemaFolder : Where the **Schema file** will be located.
2. [2]Get credentials to connect to EDM Service(_User needs to be part of EDM_DataUploaders security group_).
3. [3]Encrypt passwords, this menu hash the password using the local machine and the user logged.
4. [4]Connect to EDM, permit to validate the current configuration and see if the connection is correctly set with the EDM service.
5. [9]Optional configuration for EDM, by default exist 2 attributes that are optional **AllowedBadLinesPercentage** and **ColumnSeparator**, in this menu this values can be set.

## 2 - Generate EDM Hash & upload
This 2<sup>nd</sup> menu permit to generate all the tasks to collect all the additional information needed to set the **Datastore**, to get the **Schema file**, to set the **Path** and the **Data file**. With the previous information the **Hash file** can be created and uploaded to your Microsoft 365 Tenant.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/df3f91da-0a3c-467a-bf83-c0a225b9cdaa"></p>
<p align="center">2 - Generate EDM Hash & upload</p>
