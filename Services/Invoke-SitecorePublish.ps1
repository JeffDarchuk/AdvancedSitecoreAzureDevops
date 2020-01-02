param(
	[Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName
)
. "$PSScriptRoot\..\Get-KuduUtility.ps1"


$folderKey = -join ((97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
$accessKey = -join ((97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
(Get-Content "$PSScriptRoot\PublishManager.asmx").Replace("[TOKEN]", $accessKey) | Set-Content "$PSScriptRoot\tmp.asmx"
Write-FileFromPathToWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -slotName "" -filePath "$PSScriptRoot\tmp.asmx" -kuduPath "PublishManager/$folderKey/PublishManager.asmx"
Remove-Item "$PSScriptRoot\tmp.asmx" -Force
$site = Get-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
$webURI= "https://$($site.HostNames | Select-Object -Last 1)/PublishManager/$folderKey/PublishManager.asmx?WSDL"
try{
	for($i = 0; $i -lt 10; $i++){
		try{
			$proxy = New-WebServiceProxy -uri $webURI
			$proxy.Timeout = 230000
			$ready = $proxy.PublishAll($accessKey)

			if (-not $ready){
				throw "Unable to publish, check server logs for details."
			}
			Write-Host "Starting publish process and scanning for progress."
			for ($i = 0; $i -lt 180; $i++) {
				$done = $true
				$proxy.PublishStatus() | ForEach-Object {
					$done = $false
					write-host $_
				}
				write-host "***********  $($i * 20) Seconds **********"
				if ($done){
					Write-Host "Publish Completed."
					break
				}
				Start-Sleep -Seconds 20
				if ($i -eq 179){
					write-host "Sitecore Publish Timeout."
				}
			}
			break
		}
		catch{
			Start-Sleep -Seconds 30
			write-host "Error encountered, for attempt $i"
			write-host $_.Exception.GetType().FullName, $_.Exception.Message
		}
	}
}finally{
	Write-Host "Removing Sitecore Publish service"
	Remove-FileFromWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -slotName "" -kuduPath "PublishManager/$folderKey/PublishManager.asmx"
	Remove-FileFromWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -slotName "" -kuduPath "PublishManager/$folderKey"
}
