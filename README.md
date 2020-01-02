
# Sitecore Advanced Azure Devops
Expanding Sitecore on azure with flexible and generic scripts.
NOTE: All these scripts require a valid powershell Azure session to be connected and available
## Kudu Utility
Found [here](Get-KuduUtility.ps1)
A set of powershell functions to facilitate communication with App Services
## Script Retrying
Found [here](Invoke-ScriptWithRetry.ps1)
Azure has transient errors that simply need to be retried, this accomplishes giving things a few tries with custom failure validation for those cases where the script doesn't actually fail despite the reports from azure
## Blue/Green
Usage guide [here](bluegreen/README.md)
In an Azure PaaS environment zero downtime deployments are a possibility
## Sitecore Services
Usage guide [here](Services/README.md)
A collection of methods and tools to perform Sitecore services
## XConnect 
Usage guide [here](XConnect.README.md)
Deploy a basic XConnect artifact