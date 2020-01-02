param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$FunctionName,
    [Parameter(Mandatory=$true)]
    [string]$FunctionWebApp,
    [Parameter(Mandatory=$true)]
    [string]$SourceSearch,
    [Parameter(Mandatory=$true)]
    [string]$DestinationSearch,
    [string[]]$Indexes = @()
)

. "$PSScriptRoot\..\Get-KuduUtility.ps1"
$source = Get-AzureRmSearchAdminKeyPair -ResourceGroupName $ResourceGroupName -ServiceName $SourceSearch
$destination = Get-AzureRmSearchAdminKeyPair -ResourceGroupName $ResourceGroupName -ServiceName $DestinationSearch

$SourceSearchKey = $source.Primary
$DestinationSearchKey = $destination.Primary

$body = @{
	"source"=$SourceSearch
	"sourceKey"=$SourceSearchKey
	"destination"=$DestinationSearch
    "destinationKey"=$DestinationSearchKey
    "indexes"=$Indexes
} | ConvertTo-Json
$url = Get-AzureFunctionTriggerUrl -ResourceGroupName $ResourceGroupName -Function $FunctionName -WebAppName $FunctionWebApp
Invoke-WebRequest -Uri $url -Body $body -Method Post