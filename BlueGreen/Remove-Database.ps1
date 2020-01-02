param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    [Parameter(Mandatory=$true)]
    [string]$SqlServerName,
    [Parameter(Mandatory=$true)]
    [string]$WebDatabaseNameRoot,
    [switch]$DeleteActive = $false,
    [string]$SlotName = ""
)

. "$PSScriptRoot\..\Get-KuduUtility.ps1"

$db = Get-DatabaseNames -ResourceGroupName $ResourceGroupName -AppServiceName $AppServiceName -DatabaseNameRoot $WebDatabaseNameRoot -SlotName $SlotName

if ($DeleteActive) {
    . "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
        Remove-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.ActiveDatabase -Force
    } -RetryScriptBlock {
        # if it fails, try to get the database, if null, return, else retry
        $activeDatabase = Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.ActiveDatabase
        if ($null -eq $activeDatabase) {
            return
        } else {
            Remove-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.ActiveDatabase -Force
        }
    } -MaxAttempts 3 -SleepIntervalSeconds 30
} else {
    . "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
        Remove-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.InactiveDatabase -Force
    } -RetryScriptBlock {
        # if it fails, try to get the database, if null, return, else retry
        $inactiveDatabase = Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.InactiveDatabase
        if ($null -eq $inactiveDatabase) {
            return
        } else {
            Remove-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.InactiveDatabase -Force
        }
    } -MaxAttempts 3 -SleepIntervalSeconds 30
}

if ($DeleteActive) {
    . "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
        Remove-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.ActiveDatabase -Force
    } -RetryScriptBlock {
        # if it fails, try to get the database, if null, return, else retry
        $activeDatabase = Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.ActiveDatabase
        if ($null -eq $activeDatabase) {
            return
        } else {
            Remove-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.ActiveDatabase -Force
        }
    } -MaxAttempts 3 -SleepIntervalSeconds 30
} else {
    . "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
        Remove-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.InactiveDatabase -Force
    } -RetryScriptBlock {
        # if it fails, try to get the database, if null, return, else retry
        $inactiveDatabase = Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.InactiveDatabase
        if ($null -eq $inactiveDatabase) {
            return
        } else {
            Remove-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $SqlServerName -DatabaseName $db.InactiveDatabase -Force
        }
    } -MaxAttempts 3 -SleepIntervalSeconds 30
}