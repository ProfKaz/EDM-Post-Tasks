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

In this section we will do:
1. [1]Get EDM datastores, the script connect to the Purview Portal to show all the datastores available and permit select the right one.
2. [2]Get the **"Schema file"** based on the datastore selected.
3. [3]Set and validate EDM data, the data folder is set where the real data is located.
4. [4]Create the **"Hash file"** for your real data.
5. [5]Upload the **"Hash file"** that contains the hashed data that will be uploaded to your Microsoft 365 Tenant.
6. [6]EDM Hash upload status, permit to check the status progress.
7. [7]Create a task under task scheduler to create Hash files.
8. [8]Create a task under task scheduler to upload the Hashed data to your Microsoft 365 Tenant.

## 3 - Copy files needed and Hash to a remote server

This 3<sup>rd</sup> menu permit to copy the files needed to execute EDM PT in a remote server to upload the data hashed to your Microsoft 365 Tenant.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/2d624338-35b4-4fbb-a456-b985fbf47281"></p>
<p align="center">3 - Copy files needed and Hash to a remote server</p>

In this section we will do:
1. [1]Copy the data needed to a remote server, a new configuration file is created with the minimal configuration needed to execute EDM PT in the remote server, the scripts required and the Hash files.
2. [2]Create a task under task scheduler to copy Hashed data daily.

## 4 - Remote server activities

This last menu related to EDM tasks is to be used in a remote server, and helps to set the activities related to only upload the hashed data.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/05560a22-3f32-4e71-995f-a27d02e10172"></p>
<p align="center">4 - Remote server activities</p>

In this section we will do:
1. [1]Please validate your new folders, validate the path used in the remote server.
  * EDMAppFolder : Folder where EDM Upload Agent was installed.
  * EDMrootFolder : Where all the folders used by EDM and scripts will be located.
  * HashFolder : Where the **Hash file** will be located.
2. [2]Sign the scripts again, you can sign the script to be used under **Set-ExecutionPolicy** set as **RemoteSigned**.
3. [3]Change credentials, only if you want to use another account.
4. [4]Encrypt password, the remote config file created contains the password in clear text and is required to encrypt again(This is because the hash used the machine ID and the logged user, for that reason in unencrypted when is copying from the previous server).
5. [5]Upload your Hashed data to your Microsoft 365 Tenant.
6. [6]Check Hash upload status.
7. [7]Create a task, under task scheduler, to upload your Hashed data to your Microsoft 365 Tenant.

## 8 - About this Script

This section is only to explain in general this solution and give information about the [Author](https://www.linkedin.com/in/profesorkaz/)

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/06881595-a86f-4b19-b3a7-28efdced3429"></p>
<p align="center">8 - About this Script</p>

## 9 - Supporting elements

This last section is related to Sign the scripts, in several places is not allowed execute scripts that are not digital signed, this menu permit to sign the scripts resuing a pre installed certificate, or permit to create a new one self signed.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/d61ae9d1-d98a-4752-8970-8bf48998b22b"></p>
<p align="center">9 - Supporting elements</p>

