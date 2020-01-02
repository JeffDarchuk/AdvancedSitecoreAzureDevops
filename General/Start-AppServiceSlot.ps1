param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    [string]$SlotName = "production"
)
Start-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName