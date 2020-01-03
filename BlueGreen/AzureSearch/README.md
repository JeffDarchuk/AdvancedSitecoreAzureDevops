# Search Service Replication
This process will focus on Azure Search as a medium, however the same concepts will work for Solr.  This method heavily utilizes my solution for Azure Search replication using an Azure Function found [HERE](https://jeffdarchuk.com/2019/08/13/azure-search-replication/)
![Blue/Green model](https://jeffdarchuk.files.wordpress.com/2018/11/sitecore-9-blue-green-model.png?w=776)
## Azure Search Distribution

 1. Copy the Azure search instance. [**Copy-AzureSearchRewireCM.ps1**](Copy-AzureSearchRewireCM.ps1) This will create a new Azure Search instance, rewire your CM environment to utilize it, and use the Azure Search replication Azure Function to copy over all the contents of the Search.
 2. (OPTIONAL, one time) Separate out XConnect into it's own Azure Search instance to avoid contact losses. [**Copy-AzureSearchRewireXconnect.ps1**](Copy-AzureSearchRewireXconnect.ps1) This will create a new Azure Search, rewire all app services that use the XDB search cores, and use the Azure Search replication Azure Function to copy over all the existing contact data.  Note that this script has logic to ensure that it doesn't run if it doesn't need to so that you can have it execute as part of your release pipeline for new environments.
 3. Switch your CD staging slots to use the new Azure Search [**Switch-ActiveAzureSearch.ps1**](Switch-ActiveAzureSearch.ps1)
 4. Remove your auxiliary Azure search [**Remove-ActiveAzureSearch.ps1**](Remove-ActiveAzureSearch.ps1)
