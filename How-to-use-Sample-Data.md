# How to use Sample Data

In this same site you will find a [Sample data](Sample%20data/) folder that contains some files that can be used to test EDM and EDM PT solution.

The files available are:
1. Employees DB.xlsx : Excel file that contains the sample of the "DB" used, this file is used to explain the primary elements used and the general configuration for the EDM Schema creation at Purview Portal.
2. Employees DB - Tab.txt : Same DB exported as Tab separated.
3. Employees DB - Csv.csv : Same DB exported as Csv, or comma separated.
4. Employees DB - pipe.tsv : Same DB exported as Pipe separated.

## The Employee DB file

This Employee DB was created using the script **mip-testharness.ps1** available at the Microsoft 365 Admin Center portal, used to create the testing data to build each column show in the image below.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/59ba5ac6-2248-494b-a6f4-df936d0ccb51"></p>
<p align="center">Employee DB - Sample data</p>

This database contains 16 columns that corresponds to:
1. **SSN** *
2. SSNIssueDate
3. **TIN** *
4. TINIssueDate
5. Bank
6. DebitAccount
7. Title
8. FirstName
9. LastName
10. FullName
11. Brand
12. CCNumber
13. CVV
14. CCExp
15. **PhoneNumber** *
16. City

Columns SSN, TIN and PhoneNumber were used as a Primary Element.

<p align="center">
<img src="https://github.com/ProfKaz/EDM-Post-Tasks/assets/44684110/7021957c-bcf1-4124-b89c-2aeed0ee88a6"></p>
<p align="center">EDM Classifier configuration</p>

How was build this report step by step, you can see the recorded session for this past Webinar about [Sensitive Information Types, Custom SITs and EDM](https://youtu.be/Ynf9kyMAog4).

## About the files used for hash.

