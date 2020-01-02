function Get-AzureRmWebAppPublishingCredentials($resourceGroupName, $webAppName, $slotName = $null){
	if ([string]::IsNullOrWhiteSpace($slotName) -or $slotName.ToLower() -eq "production"){
		$resourceType = "Microsoft.Web/sites/config"
		$resourceName = "$webAppName/publishingcredentials"
	}
	else{
		$resourceType = "Microsoft.Web/sites/slots/config"
		$resourceName = "$webAppName/$slotName/publishingcredentials"
	}
	$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
    	return $publishingCredentials
}

function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $webAppName, $slotName = $null){
    $publishingCredentials = Get-AzureRmWebAppPublishingCredentials $resourceGroupName $webAppName $slotName
    $ret = @{}
    $ret.header = ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
    $ret.url = $publishingCredentials.Properties.scmUri
    return $ret
}

function Get-FileFromWebApp($resourceGroupName, $webAppName, $slotName = "", $kuduPath){
    $KuduAuth = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName $slotName
    $kuduApiAuthorisationToken = $KuduAuth.header
    $kuduApiUrl = $KuduAuth.url + "/api/vfs/site/wwwroot/$kuduPath"

    Write-Host " Downloading File from WebApp. Source: '$kuduApiUrl'." -ForegroundColor DarkGray
    $tmpPath = "$($env:TEMP)\$([guid]::NewGuid()).xml"
    $null = Invoke-RestMethod -Uri $kuduApiUrl `
                        -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                        -Method GET `
                        -ContentType "multipart/form-data" `
                        -OutFile $tmpPath
    $ret = Get-Content $tmpPath | Out-String
    Remove-Item $tmpPath -Force
    return $ret
}

function Write-FileToWebApp($resourceGroupName, $webAppName, $slotName = "", $fileContent, $kuduPath){
    $KuduAuth = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName $slotName
    $kuduApiAuthorisationToken = $KuduAuth.header
    $kuduApiUrl = $KuduAuth.url + "/api/vfs/site/wwwroot/$kuduPath"

    Write-Host " Writing File to WebApp. Destination: '$kuduApiUrl'." -ForegroundColor DarkGray

    Invoke-RestMethod -Uri $kuduApiUrl `
                        -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                        -Method Put `
                        -ContentType "multipart/form-data"`
                        -Body $fileContent
}
function Write-FileFromPathToWebApp($resourceGroupName, $webAppName, $slotName = "", $filePath, $kuduPath){
    $KuduAuth = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName $slotName
    $kuduApiAuthorisationToken = $KuduAuth.header
    $kuduApiUrl = $KuduAuth.url + "/api/vfs/site/wwwroot/$kuduPath"

    Write-Host " Writing File to WebApp. Destination: '$kuduApiUrl'." -ForegroundColor DarkGray

    Invoke-RestMethod -Uri $kuduApiUrl `
                        -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                        -Method Put `
                        -ContentType "multipart/form-data"`
                        -InFile $filePath
}

function Write-ZipToWebApp($resourceGroupName, $webAppName, $slotName = "", $zipFile, $kuduPath){
    $KuduAuth = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName $slotName
    $kuduApiAuthorisationToken = $KuduAuth.header
    $kuduApiUrl = $KuduAuth.url + "/api/zip/site/wwwroot/$kuduPath"

    Write-Host " Writing Zip to WebApp. Destination: '$kuduApiUrl'." -ForegroundColor DarkGray

    Invoke-RestMethod -Uri $kuduApiUrl `
                        -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                        -Method Put `
                        -ContentType "multipart/form-data"`
                        -InFile $zipFile
}
function Remove-FileFromWebApp($resourceGroupName, $webAppName, $slotName = "", $kuduPath){
    $KuduAuth = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName $slotName
    $kuduApiAuthorisationToken = $KuduAuth.header
    $kuduApiUrl = $KuduAuth.url + "/api/vfs/site/wwwroot/$kuduPath"

    Write-Host " Writing File to WebApp. Destination: '$kuduApiUrl'." -ForegroundColor DarkGray

    Invoke-RestMethod -Uri $kuduApiUrl `
                        -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                        -Method Delete `
                        -ContentType "multipart/form-data"
}

function Install-StockAppDataFolder($resourceGroupName, $webAppName){
    $KuduAuth = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName
    $kuduApiAuthorisationToken = $KuduAuth.header
    $KuduStagingAuth = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName "Staging"
    $kuduStagingApiAuthorisationToken = $KuduStagingAuth.header

    $kuduStagingApiFolderUrl = $KuduStagingAuth.url + "/api/zip/site/wwwroot/"
    Invoke-RestMethod -Uri $kuduStagingApiFolderUrl `
        -Headers @{"Authorization"=$kuduStagingApiAuthorisationToken;"If-Match"="*"} `
        -Method PUT `
        -ContentType "multipart/form-data" `
        -InFile "$PSScriptRoot/stockApp_Data.zip"
    #need a sleep due to a race condition if this folder is utilized too quickly after creating
    Start-Sleep -Seconds 2

    $kudulicenseUrl = $KuduAuth.url + "/api/vfs/site/wwwroot/App_Data/license.xml"
    $tmpPath = "$($env:TEMP)\$([guid]::NewGuid()).xml"
    try{
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add('Authorization', $kuduApiAuthorisationToken)
        $WebClient.Headers.Add('ContentType', 'multipart/form-data')

        $WebClient.DownloadFile($kudulicenseUrl, $tmpPath)

        $kudulicenseUrl = $KuduStagingAuth.url + "/api/vfs/site/wwwroot/App_Data/license.xml"
        Invoke-RestMethod -Uri $kudulicenseUrl `
            -Headers @{"Authorization"=$kuduStagingApiAuthorisationToken;"If-Match"="*"} `
            -Method PUT `
            -ContentType "multipart/form-data" `
            -InFile $tmpPath
    }finally{
        if (Test-Path $tmpPath){
            Remove-Item $tmpPath
        }
    }

}
function Copy-AppServiceToStaging($resourceGroupName, $webAppName, $folders = @("App_Config")){
    $KuduAuth = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName
    $kuduApiAuthorisationToken = $KuduAuth.header
    $KuduStagingAuth = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName "Staging"
    $kuduStagingApiAuthorisationToken = $KuduStagingAuth.header
    $folders | ForEach-Object {
        $kuduConfigApiUrl = $KuduAuth.url + "/api/zip/site/wwwroot/$_/"
        $tmpPath = "$($env:TEMP)\$([guid]::NewGuid()).zip"
        try{
            $WebClient = New-Object System.Net.WebClient
            $WebClient.Headers.Add('Authorization', $kuduApiAuthorisationToken)
            $WebClient.Headers.Add('ContentType', 'multipart/form-data')

            $WebClient.DownloadFile($kuduConfigApiUrl, $tmpPath)

            $kuduConfigApiUrl = $KuduStagingAuth.url + "/api/zip/site/wwwroot/$_/"
            $kuduApiFolderUrl = $KuduStagingAuth.url + "/api/vfs/site/wwwroot/$_/"
            Invoke-RestMethod -Uri $kuduApiFolderUrl `
                -Headers @{"Authorization"=$kuduStagingApiAuthorisationToken;"If-Match"="*"} `
                -Method PUT `
                -ContentType "multipart/form-data"
            #need a sleep due to a race condition if this folder is utilized too quickly after creating
            Start-Sleep -Seconds 2
            Invoke-RestMethod -Uri $kuduConfigApiUrl `
                -Headers @{"Authorization"=$kuduStagingApiAuthorisationToken;"If-Match"="*"} `
                -Method PUT `
                -ContentType "multipart/form-data" `
                -InFile $tmpPath
        }finally{
            if (Test-Path $tmpPath){
                Remove-Item $tmpPath
            }
        }
    }
}
function Get-DatabaseNames{
	param(
		[Parameter(Mandatory = $true)]
		[string]$ResourceGroupName,
		[Parameter(Mandatory = $true)]
		[string]$AppServiceName,
		[Parameter(Mandatory = $true)]
		[string]$DatabaseNameRoot,
		[string]$SlotName = ""
		
	)
	$contents = (Get-FileFromWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -slotName $SlotName -kuduPath "App_Config/ConnectionStrings.config") | Out-String
	if ($contents.Contains("$DatabaseNameRoot-2")){
		$ret = @{
			InactiveDatabase = $DatabaseNameRoot
			ActiveDatabase = $DatabaseNameRoot + '-2'
		}
	}elseif ($contents.Contains("$DatabaseNameRoot")){
		$ret = @{
			InactiveDatabase = $DatabaseNameRoot + '-2'
			ActiveDatabase = $DatabaseNameRoot
		}
	}else{
        throw "unable to find $DatabaseNameRoot OR $DatabaseNameRoot-2"
    }
	return $ret
}

function Get-SearchNames{
	param(
		[Parameter(Mandatory = $true)]
		[string]$ResourceGroupName,
		[Parameter(Mandatory = $true)]
		[string]$AppServiceName,
		[string]$SlotName = "",
        [switch]$BeforeOfflineCreated = $false
		
	)
	$contents = (Get-FileFromWebApp -resourceGroupName $ResourceGroupName -webAppName $AppServiceName -slotName $SlotName -kuduPath "App_Config/ConnectionStrings.config") | Out-String
    $start = $contents.IndexOf("cloud.search")
    if ($start -eq -1){
        $start = $contents.IndexOf("collection.search")
        if ($start -eq -1){
            throw "unable to find cloud.search or collection.search connection string"
        }
        $start = $start + "collection.search".length + 1
    }else{
        $start = $start + "cloud.search".length + 1
    }

    $start = $contents.IndexOf("`"", $start) + 1
    $end = $contents.indexOf("`"", $start)
    $ret = @{
        ActiveSearchConnectionString = $contents.Substring($start, $end - $start)
    }    
    if ($ret.ActiveSearchConnectionString.contains("-2.search.windows.net")){
		$ret.InactiveSearchConnectionString = $ret.ActiveSearchConnectionString.Replace("-2.search.windows.net",".search.windows.net")
	}else {
        $ret.InactiveSearchConnectionString = $ret.ActiveSearchConnectionString.Replace(".search.windows.net","-2.search.windows.net")
    }
    $start = $ret.ActiveSearchConnectionString.indexOf("serviceUrl=https://")+20
    $end = $ret.ActiveSearchConnectionString.indexOf(".search.windows.net")
    $ret.ActiveSearch = $ret.ActiveSearchConnectionString.substring($start, $end - $start)
    $start = $ret.InactiveSearchConnectionString.indexOf("serviceUrl=https://")+20
    $end = $ret.InactiveSearchConnectionString.indexOf(".search.windows.net")
    $ret.InactiveSearch = $ret.InactiveSearchConnectionString.substring($start, $end - $start)
    if ($false -eq $BeforeOfflineCreated){

        $online = Get-AzureRmSearchAdminKeyPair -ResourceGroupName $ResourceGroupName -ServiceName $ret.ActiveSearch
        $offline = Get-AzureRmSearchAdminKeyPair -ResourceGroupName $ResourceGroupName -ServiceName $ret.InactiveSearch
        $ret.InactiveSearchConnectionString = $ret.InactiveSearchConnectionString.replace($online.Primary, $offline.Primary)
    }

	return $ret
}
function Get-AzureFunctionTriggerUrl{
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]$Function,
        [Parameter(Mandatory = $true)]
        [string]$WebAppName
    )
    $KuduAuth = Get-KuduApiAuthorisationHeaderValue $ResourceGroupName $WebAppName
    $kuduApiAuthorisationToken = $KuduAuth.header

    $apiUrl = "https://$webAppName.scm.azurewebsites.net/api/functions/admin/masterkey"
    $result = Invoke-RestMethod -Uri $apiUrl -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} 
    return "http://$webAppName.azurewebsites.net/api/$($Function)?code=$($result.MasterKey)"
}
