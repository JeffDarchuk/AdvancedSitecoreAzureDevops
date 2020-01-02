param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    [string]$SlotName = "Staging"
)
. "$PSScriptRoot\..\..\Get-KuduUtility.ps1"
$contents = (Get-FileFromWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -slotName $SlotName -kuduPath "App_Config/ConnectionStrings.config") | Out-String
$search = Get-SearchNames -ResourceGroupName $ResourceGroupName -AppServiceName $AppServiceName -SlotName $SlotName

$contents = $contents.Replace($search.ActiveSearchConnectionString, $search.InactiveSearchConnectionString)
Write-FileToWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -fileContent $contents -slotName $SlotName -kuduPath "App_Config/ConnectionStrings.config"
