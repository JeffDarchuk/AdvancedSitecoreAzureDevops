param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    [string]$SlotName = "",
    [string]$AzureWebPrefix = "[APP SERVICE PREFIX]", #The prefix at the beginning of your cm/cd app services before the asset designation -cm-
    [string]$AzureResourceGroupPrefix = "[RESOURCE GROUP PREFIX]", #The prefix at the beginning of your resource group before the environment designation -dev-
    [string]$AzureSearchPrefix = "[AZURE SEARCH PREFIX]", #The prefix at the beginning of your Azure Search assets before the environment designation -dev-
    [string]$AzureFunctionPrefix = "[AZURE FUNCTION PREFIX]" #The prefix of your azure search function (see github documentation) before the environmetn designation -dev-
)
$resourceGroupName = "$AzureResourceGroupPrefix-$Environment"
$cmAppServiceName = "$AzureWebPrefix-cm-$Environment"
$cdAppServiceName = "$AzureWebPrefix-cd-$Environment"
$functionAppName = "$AzureFunctionPrefix-$Environment"

. "$PSScriptRoot\..\..\Get-KuduUtility.ps1"

write-host "Identifying active Search Instance"
$search = Get-SearchNames -resourceGroupName $resourceGroupName -appServiceName $cdAppServiceName -SlotName $SlotName -BeforeOfflineCreated


$tst = Get-AzureRmSearchService -Name $search.InactiveSearch -resourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if ($null -ne $tst){
    throw "Unable to copy Search Service when the CM environment is referencing $($search.ActiveSearch) and $($search.InactiveSearch) already exist.  Make sure that both the tenant CD AND the CM environment are using the same database before this operation and delete the unused database and try again."
}
$tst =Get-AzureRmSearchService -Name $search.ActiveSearch -resourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
write-host "Copying Search Service $($search.ActiveSearch) to $($search.InactiveSearch)"
$parameters = @{
    resourceGroupName = $resourceGroupName
    Name = $search.InactiveSearch
    Sku = $tst.Sku
    Location = $tst.Location
    PartitionCount = $tst.PartitionCount
    ReplicaCount = $tst.ReplicaCount
    HostingMode = $tst.HostingMode
}
. "$PSScriptRoot\..\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
    New-AzureRmSearchService @parameters
} -RetryScriptBlock {
    $tst = Get-AzureRmSearchService -Name $search.InactiveSearch -resourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
    if($null -eq $tst){
        New-AzureRmSearchService @parameters
    }
}  -MaxAttempts 3 -SleepIntervalSeconds 30 -Verbose

$search = Get-SearchNames -resourceGroupName $resourceGroupName -appServiceName $cdAppServiceName -SlotName $SlotName 
Start-Sleep -Seconds 45
Write-Host "Replacing connection string on CM with inactive search connection"
$contents = (Get-FileFromWebApp -resourceGroupName $resourceGroupName -webAppName $cmAppServiceName -slotName $SlotName -kuduPath "App_Config/ConnectionStrings.config") | Out-String
$contents = $contents.Replace($search.ActiveSearchConnectionString, $search.InactiveSearchConnectionString)
. "$PSScriptRoot\..\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
    Write-FileToWebApp -resourceGroupName $resourceGroupName -webAppName $cmAppServiceName -fileContent $contents -slotName $SlotName -kuduPath "App_Config/ConnectionStrings.config"
}  -MaxAttempts 3 -SleepIntervalSeconds 30 -Verbose
. "$PSScriptRoot\..\..\Invoke-AzureSearchCopy.ps1" `
            -resourceGroupName $resourceGroupName `
            -FunctionName "AzureSearchReplicate" `
            -FunctionWebApp $functionAppName `
            -SourceSearch $search.ActiveSearch `
            -DestinationSearch $search.InactiveSearch
