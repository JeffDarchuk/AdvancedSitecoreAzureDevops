param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    [string]$SlotName = "Staging"
)

Switch-AzureRmWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -DestinationSlotName "Production" -SourceSlotName $SlotName