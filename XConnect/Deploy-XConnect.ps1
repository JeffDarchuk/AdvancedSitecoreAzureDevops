Param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    [Parameter(Mandatory=$true)]
    [string]$AppServiceType,
    [string]$AppServicePrefix = "[APP SERVICE PREFIX]", #The prefix at the beginning of your cm/cd app services before the asset designation -cm-
    [string]$SlotName = "staging",
    [switch]$Xml,
    [switch]$Model,
    [switch]$Bin
)
. "$PSScriptRoot\..\Get-KuduUtility.ps1"

$AppServiceName = "$AppServicePrefix-$AppServiceType-$Environment"
$ArtifactPath = (Resolve-Path "$PSScriptRoot\..\").Path
if ($Xml){
    write-host "Writing Xml config files"
    Get-ChildItem "$ArtifactPath\xml" | ForEach-Object {
        Write-FileFromPathToWebApp `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $AppServiceName `
            -SlotName $SlotName `
            -FilePath $_.FullName `
            -KuduPath "\App_data\config\sitecore\XConnect\$($_.Name)"
        if ($AppServiceName -like "*ma-ops*"){
            Write-FileFromPathToWebApp `
                -ResourceGroupName $ResourceGroupName `
                -WebAppName $AppServiceName `
                -SlotName $SlotName `
                -FilePath $_.FullName `
                -KuduPath "\App_data\jobs\continuous\AutomationEngine\App_Data\Config\sitecore\XConnect\$($_.Name)"
        }
    }
}
if ($Model){
    write-host "Writing Model json files"
    Get-ChildItem "$ArtifactPath\model" | ForEach-Object {
        Write-FileFromPathToWebApp `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $AppServiceName `
            -SlotName $SlotName `
            -FilePath $_.FullName `
            -KuduPath "\App_data\Models\$($_.Name)"
        if ($AppServiceName -like "*xc-search*"){
            Write-FileFromPathToWebApp `
                -ResourceGroupName $ResourceGroupName `
                -WebAppName $AppServiceName `
                -SlotName $SlotName `
                -FilePath $_.FullName `
                -KuduPath "\App_data\jobs\continuous\IndexWorker\App_Data\Models\$($_.Name)"
            
        }
    }
}
if ($bin){
    write-host "Writing binary files"
    Get-ChildItem "$ArtifactPath\bin" | ForEach-Object {
        Write-FileFromPathToWebApp `
            -ResourceGroupName $ResourceGroupName `
            -WebAppName $AppServiceName `
            -SlotName $SlotName `
            -FilePath $_.FullName `
            -KuduPath "\bin\$($_.Name)"
        if ($AppServiceName -like "*xc-search*"){
            Write-FileFromPathToWebApp `
                -ResourceGroupName $ResourceGroupName `
                -WebAppName $AppServiceName `
                -SlotName $SlotName `
                -FilePath $_.FullName `
                -KuduPath "\App_data\jobs\continuous\IndexWorker\$($_.Name)"
        }
        if ($AppServiceName -like "*ma-ops*"){
            Write-FileFromPathToWebApp `
                -ResourceGroupName $ResourceGroupName `
                -WebAppName $AppServiceName `
                -SlotName $SlotName `
                -FilePath $_.FullName `
                -KuduPath "\App_data\jobs\continuous\AutomationEngine\$($_.Name)"
        }
    }
}