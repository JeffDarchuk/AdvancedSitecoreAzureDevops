# Blue/Green deployments in Sitecore
![Blue/Green model](https://jeffdarchuk.files.wordpress.com/2018/11/sitecore-9-blue-green-model.png?w=776)
## Executing this model as follows
1. Copy CM PRODUCTION slot to STAGING [**Copy-ProductionSlotToStaging.ps1**](Copy-ProductionSlotToStaging.ps1).  This doesn't copy EVERYTHING, only licenses and App_Config.  The rest is expected to be handled by your build/release pipelines. This is for backup purposes only, specifically for rapid rollback capabilities
2. Make copies of all the web databases and rewire CM [**Copy-WebDatabaseReqireCM.ps1**](Copy-WebDatabaseReqireCM.ps1)
3. Build new SOLR (or any search) and rewire CM [_See Azure Search Subsection_](AzureSearch)
4. Rebuild Search Indexes  [_See Azure Search Subsection_](AzureSearch)
5. Copy CD PRODUCTION slot to STAGING [**Copy-ProductionSlotToStaging.ps1**](Copy-ProductionSlotToStaging.ps1). Doesn't copy EVERYTHING, only licenses and App_Config.  The rest is expected to be handled by your build/release pipelines.
6. Rewire CD Staging slots to use the new databases [**Switch-ActiveDatabase.ps1**](Switch-ActiveDatabase.ps1)
7. Deploy Normally to your CM environment and deploy to the STAGING slot for CD environments. At this point any changes to content and publishes are going to be delivered to the STAGING slot environments.  If you're not replicating your search indexes a publishing freeze is recommended as the mismatched content could cause issues between your STAGING and PRODUCTION slots.
8. Test environment
9. Swap STAGING slot to PRODUCTION slot [**Switch-DeploymentSlot.ps1**](Switch-DeploymentSlot.ps1) (in the general folder)
10. Remove STAGING slots after a successful deployment [**Remove-DeploymentSlot.ps1**](Remove-DeploymentSlot.ps1)
11. Remove old databases [**Remove-Database.ps1**](Remove-Database.ps1)
12. Remove old search [_See Azure Search Subsection_](AzureSearch) 