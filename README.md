
# Sitecore Advanced Azure Devops
Expanding Sitecore on azure with flexible and generic scripts.
![Happy bot](happybot.gif)
#### NOTE: All these scripts require a valid powershell Azure session to be connected and available
## General Support Scripts
#### Kudu Utility
##### Found [here](Get-KuduUtility.ps1)
A set of powershell functions to facilitate communication with App Services.  This forms the backbone of all the Azure App Service interactions that are required for these devops strategies.  
#### Script Retrying
##### Found [here](Invoke-ScriptWithRetry.ps1)
Azure has transient errors that simply need to be retried, this accomplishes giving things a few tries with custom failure validation for those cases where the script doesn't actually fail despite the reports from Azure.  A well set up execution of this strategy should give our scripts the best chance to succeed given the random instability of Azure in general.
## Blue/Green
### Usage guide [here](bluegreen)
In an Azure PaaS environment zero downtime deployments are a possibility.  By dynamically duplicating databases and rewiring app services we can fairly simply achieve this.
## Sitecore Services
### Usage guide [here](Services)
A collection of methods and tools to perform Sitecore services.  Most notably to reindex or publish remotely, however this model can be followed to perform most Sitecore based operations.
## XConnect 
### Usage guide [here](XConnect)
Deploy a basic XConnect artifact.  XConnect can be profoundly confusing to work with, here are some simple guildlines to be successful with it.