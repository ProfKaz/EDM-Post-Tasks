# EDM Post Tasks (EDM PT)
## Solution to help to simplify all the post tasks related to Exact Data Match.

After you create your EDM schema at the Purview Portal, in accordance with this [documentation](https://learn.microsoft.com/en-us/purview/sit-create-edm-sit-unified-ux-schema-rule-package), you may also watch this recorded session about [Sensitive Information Types(SITs), Custom SITs and Exact Data Match](https://youtu.be/Ynf9kyMAog4) where all the steps are explained in details.

After the Schema was created, and wait around 30 minutes, the schema will be available to be used through [EDM Upload Agent](https://go.microsoft.com/fwlink/?linkid=2088639) (This link download the version for commercial Tenants), all the clients can be found in this [link](https://learn.microsoft.com/en-us/purview/sit-get-started-exact-data-match-hash-upload#links-to-edm-upload-agent-by-subscription-type), several tasks are required to execute accordin to the next image.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/aaa29ede-71ba-43ba-a539-d530a150f336"></p>
<p align="center">EDM Post tasks overview</p>

The tasks related are:
1. Create EDM schema at [Purview Portal](https://compliance.microsoft.com).
2. Connect and validate the connection using EdmUploadAgent.exe /Authorize (your user needs to be part of EDM_DataUploaders security group).
3. Request the schema file using the datastore name collected from the 1st step.
4. You need to export your database to a file in Csv(comma sepparated), or Pipe '|', or Tab '{Tab]' format.
5. You need have access to the previous file from the computer where the EDMUpload Agent is installed.
6. Validate the file from the step number 4 with the schema file generated on the step 3.
7. Create a hash from the data file generated  at the point 4.
8. We can have 2 options:
   - Upload the data directly to your Microsoft 365 Tenant, or
   - Copy the data to a remote server to Upload the hash from another computer wihtout access to the original data.
9. Upload your data from a remote server.

After we install EDM Upload Agent, normally installed at **C:\Program Files\Microsoft\EdmUploadAgent**, at the moment to execute we can see several commands that can be used. Those commands permit us to do all the previous designated tasks.
<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/0aca2c0d-d25c-43c5-acd4-79d62fba3974"></p>
<p align="center">EDM Upload Agent</p>

Use this application can be a real challenge and more if we want to automate those tasks, in that order of ideas with EDM PT solution we can simplify all those tasks.

## What we can do with EDM PT?
With EDM PT we can cover all the tasks that appears in the image "EDM Post tasks overview", these tasks are:
1. Set a configuration file with all the information needed to execute EDM PT, including credentials to automate this activity.
2. We can encrypt the credentials.
3. We can sign the scripts, in some organizations is not allowed the option **"Set-ExecutionPolicy"** set a **"Bypass"**, and at least is required set to **"RemoteSigned"**. This option permit to reuse a digital certificate for _Code Signing_, or create a new one self signed.
4. Connect to EDM to validate the connection.
5. Set other variables like **"AllowedBadLinesPercentage"** or **"ColumnSeparator"** the last one used to identify if your data is separated by comma, pipe or Tab.
6. Get all the _datastores_ names available in your Tenant.
7. Get the _schema_ file associated to the previous _datastore_.
8. Set the location from your original data and validate if that match with the schema created at the Purview Portal.
9. Create the **Hash file** for that data.
10. Upload the **Hash file** to your Microsoft 365 Tenant.
11. Check the progress status for the previous activity.
12. Copy the data needed to a remote server, to execute upload process from a remote machine.
13. At the remote machine we can do:
  * Review the configuration at the remote server and make some changes if that is required.
  * Permit to change the credentials used.
  * Encrypt the password
  * Sign the scripts
  * Upload the **Hash file** to your Microsoft 365 Tenant
  * Check the progress status for the upload process
14. The tasks that can be automate, using task scheduler, are:
  * Create the **Hash file** if the **Data file** is a new one.
  * Upload the **Hash file** if this file is a new one.
  * Copy the **Hash file** to the remote server if this file is a new one.
  * Upload the **Hash file** from the remote server if this file is a new one.

(EDM PT solution compare the _Last Write Time_ for each file to compare and see if we are working with a new file, or not, this validation is do it because you can do a EDM refresh only 5 times per day)

**__[Next Step - Start using it](About_EDMPT_Solution.md)__**


