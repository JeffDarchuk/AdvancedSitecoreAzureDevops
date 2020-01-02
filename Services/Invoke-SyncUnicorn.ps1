Param(
  [Parameter(Mandatory=$true)]
  [string]$UnicornModulePath,

  [Parameter(Mandatory=$true)]
  [string]$ControlPanelUrl,

  [Parameter(Mandatory=$true)]
  [string]$SharedSecret
)

Import-Module "$UnicornModulePath"
for($i = 0; $i -lt 10; $i++){
  try{
    Sync-Unicorn -ControlPanelUrl "$ControlPanelUrl" -SharedSecret "$SharedSecret"
    break
  }catch{
    Start-Sleep -Seconds 30
    write-host "Error encountered, for attempt $i"
    write-host $_.Exception.GetType().FullName, $_.Exception.Message
  }
}
