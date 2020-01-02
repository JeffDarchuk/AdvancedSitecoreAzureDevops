# Sitecore Services
Remotely perform operations on Sitecore based from powershell.
#### Rebuild search indexes
#### Publish the site
## Modual webservices
To perform operations a basic process is followed

 1. Temporarilly modify the ASMX file with a GUID for folder and a GUID for an access key
 2. Copy modified ASMX file to the temp folder on the App Service using Kudu
 3. Execute ASMX service via Powershell
 4. Remove ASMX file when operation is completed

This concept allows us to secure endpoints in multiple ways while the operation is running while completely removing any possible attack vectors after the operation is done.
## Examples
Rebuild the search index for the dev environment
```powershell
Invoke-IndexRebuild.ps1 -ResourceGroupName "MyResourceGroup" -AppServiceName "MyPrefix-cm-dev"
```
Publish content to all targets for the dev environment
```powershell
Invoke-SitecorePublish.ps1 -ResourceGroupName "MyResourceGroup" -AppServiceName "MyPrefix-cm-dev"
```