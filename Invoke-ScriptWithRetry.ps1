param(
  [Parameter(Mandatory = $true)]
  [scriptblock]$ScriptBlock,
  [Parameter(Mandatory = $false)]
  [scriptblock]$RetryScriptBlock,
  [Parameter(Mandatory = $false)]
  [int]$MaxAttempts = 3,
  [Parameter(Mandatory = $false)]
  [int]$SleepIntervalSeconds = 30
)
begin {
  $count = 0
}
process {
  do {
    $count++
    try {
      if ($count -gt 1) {
        # retry
        if ($RetryScriptBlock) { 
          Write-Host "Invoking retry script block (attempt $count/$MaxAttempts):"
          Write-Host $RetryScriptBlock
          $RetryScriptBlock.Invoke()
          return
        } else {
          Write-Host "Retrying invocation of script block (attempt $count/$MaxAttempts):"
          Write-Host $ScriptBlock
          $ScriptBlock.Invoke()
          return
        }
      }
      # initial
      Write-Host "Running script block (attempt $count/$MaxAttempts):"
      Write-Host $ScriptBlock
      $ScriptBlock.Invoke()
      return
    }
    catch {
      Write-Host "Error attempting to run script block!" -ForegroundColor Red
      Write-Host  $_.Exception -ForegroundColor Red
      if ($count -lt $MaxAttempts) {
        Write-Host "Waiting $SleepIntervalSeconds second(s) before retrying..."
        Start-Sleep -Seconds $SleepIntervalSeconds
      }
    }
  } while ($count -lt $MaxAttempts)
  throw "Maximum attempts exhausted. ($MaxAttempts)"
}