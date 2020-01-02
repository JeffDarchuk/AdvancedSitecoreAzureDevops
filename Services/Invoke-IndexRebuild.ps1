param(
	[Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
	[string]$AppServiceName
)
. "$PSScriptRoot\..\Get-KuduUtility.ps1"

$folderKey = -join ((97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
$accessKey = -join ((97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
(Get-Content "$PSScriptRoot\SearchManager.asmx").Replace("[TOKEN]", $AccessKey) | Set-Content "$PSScriptRoot\tmp.asmx"
Write-FileFromPathToWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -slotName "" -filePath "$PSScriptRoot\tmp.asmx" -kuduPath "SearchManager/$FolderKey/SearchManager.asmx"
Remove-Item "$PSScriptRoot\tmp.asmx" -Force
$site = Get-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
$webURI= "https://$($site.HostNames | Select-Object -Last 1)/SearchManager/$FolderKey/SearchManager.asmx?WSDL"
for($i = 0; $i -lt 10; $i++){
	try{
		write-host "Attempting to read from $webURI"
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		$proxy = New-WebServiceProxy -uri $webURI
		$proxy.Timeout = 230000
		$ready = $proxy.RebuildIndexes($AccessKey)
		write-host "Index rebuild started"
		if (-not $ready){
			throw "Unable to Index Rebuild, check server logs for details."
		}
		if (-not $Async){
			Write-Host "Starting Index Rebuild process and scanning for progress."
			for ($i = 0; $i -lt 180; $i++) {
				$done = $true
				$proxy.RebuildStatus() | ForEach-Object {
					$done = $false
					write-host $_
				}
				write-host "***********  $($i * 20) Seconds **********"
				if ($done){
					Write-Host "Index Rebuild Completed."
					break
				}
				Start-Sleep -Seconds 20
				if ($i -eq 179){
					write-host "Sitecore Index Rebuild Timeout."
				}
			}
		}
		break
	}
	catch{
		Start-Sleep -Seconds 30
		write-host "Error encountered, for attempt $i"
		write-host $_.Exception.GetType().FullName, $_.Exception.Message
	}finally{
		Write-Host "Removing Sitecore Publish service"
		Remove-FileFromWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -slotName "" -kuduPath "SearchManager/$folderKey/SearchManager.asmx"
		Remove-FileFromWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -slotName "" -kuduPath "SearchManager/$folderKey"
	}
}
