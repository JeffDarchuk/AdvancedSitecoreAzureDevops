param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$CMAppServiceName,
    [Parameter(Mandatory=$true)]
    [string]$CDAppServiceName,
    [string]$SlotName = "",
    [Parameter(Mandatory=$true)]
    [string]$DatabaseNameRoot,
    [Parameter(Mandatory=$true)]
    [string]$SqlServerName,
    [Parameter(Mandatory=$true)]
    [string]$TenantName
)

. "$PSScriptRoot\..\Get-KuduUtility.ps1"

$contents = (Get-FileFromWebApp -ResourceGroupName $ResourceGroupName -WebAppName $CMAppServiceName -SlotName $SlotName -KuduPath "App_Config/ConnectionStrings.config") | Out-String
$db = Get-DatabaseNames -ResourceGroupName $ResourceGroupName -AppServiceName $CDAppServiceName -DatabaseNameRoot $DatabaseNameRoot -SlotName $SlotName
$contents = $contents.Replace("Catalog=$($db.ActiveDatabase);", "Catalog=$($db.InactiveDatabase);")

$tst = Get-AzureRmSqlDatabase -DatabaseName $db.InactiveDatabase -ServerName $SqlServerName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -ne $tst) {
    throw "Unable to copy database when the CM environment is referencing $($db.ActiveDatabase) and $($db.InactiveDatabase) already exist. Make sure that both the tenant CD AND the CM environment are using the same database before this operation and delete the unused database and try again."
}

$tst = Get-AzureRmSqlDatabase -DatabaseName $db.ActiveDatabase -ServerName $SqlServerName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

$parameters = @{
    ResourceGroupName = $ResourceGroupName
    DatabaseName = $db.ActiveDatabase
    ServerName = $SqlServerName
    CopyResourceGroupName = $ResourceGroupName
    CopyServerName = $SqlServerName
    CopyDatabaseName = $db.InactiveDatabase
}
if (-not [string]::IsNullOrWhitespace($tst.ElasticPoolName)) {
    $parameters["ElasticPoolName"] = $tst.ElasticPoolName
}

Write-host "Copying database $($db.ActiveDatabase) to $($db.InactiveDatabase)"

. "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
    New-AzureRmSqlDatabaseCopy @parameters
} -RetryScriptBlock {
    # if it fails, wait 30 seconds, then retry; if it fails again, check for the new database copy and return if it exists, else retry
    try {
        New-AzureRmSqlDatabaseCopy @parameters
    } catch {
        $databaseCopy = Get-AzureRmSqlDatabase -ResourceGroupName $parameters["CopyResourceGroupName"] -ServerName $parameters["CopyServerName"] -DatabaseName $parameters["CopyDatabaseName"]
        if ($null -ne $databaseCopy) {
            return
        }
    }
} -MaxAttempts 3 -SleepIntervalSeconds 30

. "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
    Write-FileToWebApp -ResourceGroupName $ResourceGroupName -WebAppName $CMAppServiceName -FileContent $contents -SlotName $SlotName -KuduPath "App_Config/ConnectionStrings.config"
} -MaxAttempts 3 -SleepIntervalSeconds 5 -Verbose
