Function Write-AicFile {
  [CmdletBinding()]
  Param
  ( 
    [Parameter(Mandatory = $true)]
    [string]$aicPath,
    
    [Parameter(Mandatory = $true)]
    [string[]]$aicCommands
  )
   
  Trace-VstsEnteringInvocation $MyInvocation
  
  $aicFileContent = ";aic;"
  foreach ($token in $aicCommands) {
    $aicFileContent += "`r`n"
    $aicFileContent += $token;
  }
  Write-VstsTaskVerbose "aicFileContent = $aicFileContent"
  $aicFileContent | Out-File $aicPath -encoding Unicode -Append
  
  Trace-VstsLeavingInvocation $MyInvocation
}