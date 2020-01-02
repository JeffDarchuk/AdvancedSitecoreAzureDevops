param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    [string]$SlotName = "Staging"
)

. "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
    Remove-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName -Force
} -RetryScriptBlock {
    # if it fails, try to get the slot, if null, return, else retry
    $slot = Get-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName
    if ($null -eq $slot) {
        return
    } else {
        Remove-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName -Force
    }
} -MaxAttempts 3 -SleepIntervalSeconds 30
