param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    [Parameter(Mandatory=$true)]
    [string]$DatabaseNameRoot,
    [Parameter(Mandatory=$true)]
    [string]$WebDatabaseNameRoot,
    [string]$SlotName = "Staging"
)

. "$PSScriptRoot\..\Get-KuduUtility.ps1"

$contents = (Get-FileFromWebApp -ResourceGroupName $ResourceGroupName -WebAppName $AppServiceName -SlotName $SlotName -KuduPath "App_Config/ConnectionStrings.config") | Out-String
$db = Get-DatabaseNames -ResourceGroupName $ResourceGroupName -AppServiceName $AppServiceName -DatabaseNameRoot $DatabaseNameRoot -SlotName $SlotName
$contents = $contents.Replace("Catalog=$($db.ActiveDatabase);", "Catalog=$($db.InactiveDatabase);")
$db = Get-DatabaseNames -ResourceGroupName $ResourceGroupName -AppServiceName $AppServiceName -DatabaseNameRoot $WebDatabaseNameRoot -SlotName $SlotName
$contents = $contents.Replace("Catalog=$($db.ActiveDatabase);", "Catalog=$($db.InactiveDatabase);")

. "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
    Write-FileToWebApp -ResourceGroupName $ResourceGroupName -WebAppName $AppServiceName -FileContent $contents -SlotName $SlotName -KuduPath "App_Config/ConnectionStrings.config"
} -MaxAttempts 3 -SleepIntervalSeconds 5
