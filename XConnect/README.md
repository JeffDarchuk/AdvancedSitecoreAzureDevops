# Sitecore XConnect deployment

XConnect deployable files come in three forms

 1. XML configuration files
 2. JSON model files
 3. DLL files that contain your facet pocos

In this example we'll assume that you have an artifact generated that has 3 folders in the root, one for each type of file

 1. \xml
 2. \model
 3. \bin

in the file *Depoy-XConnect.ps1* there are switches to control what type of files are being deployed
NOTE: replace *_[APP SERVICE PREFIX]_* with the prefix of your Azure environment.  This is the value that all app service assets share in your environment.
### Kudu
This works by leverating kudu to deploy files directly from your artifact.  Note that the removal of newly replaced or renamed files isn't handled by this script and will need to be handled in some other way.
### Examples
Deploy files to XConnect Search app service on the dev environment
```powershell
	Deploy-XConnect.ps1 -ResourceGroup "myResourceGroup" -Environment "dev" -AppServiceType "xc-search" -Xml -Model -Bin
```
Deploy files to XConnect Collect app service on the stg environment
```powershell
	Deploy-XConnect.ps1 -ResourceGroup "myResourceGroup" -Environment "stg" -AppServiceType "xc-collect" -Xml -Model -Bin
```