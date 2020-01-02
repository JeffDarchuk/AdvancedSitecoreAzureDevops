param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    [string]$AzureWebPrefix = "[APP SERVICE PREFIX]", #The prefix at the beginning of your cm/cd app services before the asset designation -cm-
    [string]$AzureResourceGroupPrefix = "[RESOURCE GROUP PREFIX]", #The prefix at the beginning of your resource group before the environment designation -dev-
    [string]$AzureSearchPrefix = "[AZURE SEARCH PREFIX]", #The prefix at the beginning of your Azure Search assets before the environment designation -dev-
    [string]$AzureFunctionPrefix = "[AZURE FUNCTION PREFIX]", #The prefix of your azure search function (see github documentation) before the environmetn designation -dev-
    [string]$Location = "West US",
    [string]$SlotName = "production",
    [string]$FunctionName = "AzureSearchReplicate"
)

. "$PSScriptRoot\..\..\Get-KuduUtility.ps1"

$FunctionWebApp = "$AzureFunctionPrefix-$Environment"
$resourceGroupName = "$AzureResourceGroupPrefix-$Environment"
$xconnectAzureSearchName = "$AzureSearchPrefix-xconnect-$Environment"
$xconnectSearchName = "$AzureWebPrefix-xc-search-$Environment"
$sourceSearchName = "$AzureSearchPrefix-$Environment"

$xconnectSearch = Get-AzureRmResource -ResourceGroupName $resourceGroupName -Name $xconnectAzureSearchName
if ($null -eq $xconnectSearch){
    . "$PSScriptRoot\..\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
        New-AzureRmSearchService -ResourceGroupName $resourceGroupName -Name $xconnectAzureSearchName -Sku "Standard" -Location $Location -PartitionCount 1 -ReplicaCount 1
    } -RetryScriptBlock {
        $xconnectSearch = Get-AzureRmResource -ResourceGroupName $resourceGroupName -Name $xconnectAzureSearchName
        if ($null -eq $xconnectSearch){
            $xconnectSearch = New-AzureRmSearchService -ResourceGroupName $resourceGroupName -Name $xconnectAzureSearchName -Sku "Standard" -Location $Location -PartitionCount 1 -ReplicaCount 1
        }
    }  -MaxAttempts 3 -SleepIntervalSeconds 30 -Verbose
    Start-Sleep -Seconds 15
    $online = Get-AzureRmSearchAdminKeyPair -ResourceGroupName $ResourceGroupName -ServiceName $xconnectAzureSearchName
    $search = Get-SearchNames -ResourceGroupName $ResourceGroupName -AppServiceName $xconnectSearchName -BeforeOfflineCreated
    $connectionString = "serviceUrl=https://$xconnectAzureSearchName.search.windows.net;indexName=xdb;apiKey=$($online.Primary)"
    . "$PSScriptRoot\..\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
        $contents = (Get-FileFromWebApp -resourceGroupName $ResourceGroupName -webAppName $xconnectSearchName -slotName $SlotName -kuduPath "App_Config/ConnectionStrings.config") | Out-String
        $contents = $contents.Replace($search.ActiveSearchConnectionString, $connectionString)
        Write-FileToWebApp -resourceGroupName $ResourceGroupName -webAppName $xconnectSearchName -fileContent $contents -slotName $SlotName -kuduPath "App_Config/ConnectionStrings.config"

    }  -MaxAttempts 3 -SleepIntervalSeconds 30 -Verbose
    . "$PSScriptRoot\..\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
        $contents2 = (Get-FileFromWebApp -resourceGroupName $ResourceGroupName -webAppName $xconnectSearchName -slotName $SlotName -kuduPath "App_Data/jobs/continuous/IndexWorker/App_Config/ConnectionStrings.config") | Out-String
        $contents2 = $contents2.Replace($search.ActiveSearchConnectionString, $connectionString)
        Write-FileToWebApp -resourceGroupName $ResourceGroupName -webAppName $xconnectSearchName -fileContent $contents2 -slotName $SlotName -kuduPath "App_Data/jobs/continuous/IndexWorker/App_Config/ConnectionStrings.config"

    }  -MaxAttempts 3 -SleepIntervalSeconds 30 -Verbose

    . "$PSScriptRoot\..\..\Invoke-AzureSearchCopy.ps1" `
        -ResourceGroupName $ResourceGroupName `
        -FunctionName $FunctionName `
        -FunctionWebApp $FunctionWebApp `
        -SourceSearch $sourceSearchName `
        -DestinationSearch $xconnectAzureSearchName `
        -Indexes @("xdb", "xdb-secondary")
}

