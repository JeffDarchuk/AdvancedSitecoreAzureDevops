param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    [string[]]$Folders = @("App_Config")
)

. "$PSScriptRoot\..\Get-KuduUtility.ps1"

$existingSlot = Get-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot "Staging" -ErrorAction SilentlyContinue
if ($null -ne $existingSlot){
    throw "Unable to copy production slot to a new staging slot. This is most likely due to the fact that the environment is already in a blue/green initialized state. Roll back out of an initialized state before initializing again. If you're trying to deploy code updates to a blue/green environment that's already initialized you can deploy directly to the CM and CD environments and bypass initialization."
}

$slot = Get-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot "Production"
if ($null -eq $slot) {
    throw "Unable to get current production slot. Please verify the health of the app service."
}

. "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
    New-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot "Staging" -AppServicePlan $slot.ServerFarmId
} -RetryScriptBlock {
    # if it fails, wait 30 seconds, then retry; if it fails again, check for the slot and return if it exists, else retry
    try {
        New-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot "Staging" -AppServicePlan $slot.ServerFarmId
    } catch {
        $newSlot = Get-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot "Staging"
        if ($null -ne $newSlot) {
            return
        }
    }
} -MaxAttempts 3 -SleepIntervalSeconds 30

. "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
    Copy-AppServiceToStaging -ResourceGroupName $ResourceGroupName -WebAppName $AppServiceName -Folders $Folders
} -MaxAttempts 3 -SleepIntervalSeconds 30

. "$PSScriptRoot\..\Invoke-ScriptWithRetry.ps1" -ScriptBlock {
    Install-StockAppDataFolder -ResourceGroupName $ResourceGroupName -WebAppName $AppServiceName
} -MaxAttempts 3 -SleepIntervalSeconds 30
