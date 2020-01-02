
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    [switch]$DeleteActive = $false,
    [string]$SlotName = ""
)
. "$PSScriptRoot\..\..\Get-KuduUtility.ps1"

$search = Get-SearchNames -ResourceGroupName $ResourceGroupName -AppServiceName $AppServiceName -SlotName $SlotName 

if ($DeleteActive){
    Remove-AzureRmSearchService -ResourceGroupName $ResourceGroupName -Name $search.ActiveSearch -Force
}else{
    Remove-AzureRmSearchService -ResourceGroupName $ResourceGroupName -Name $search.InactiveSearch -Force
}