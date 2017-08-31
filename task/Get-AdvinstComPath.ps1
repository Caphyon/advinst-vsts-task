Function Get-AdvinstComPath {

  [CmdletBinding()]
  param()
  
  # Constants 
  Set-Variable advinstWowRegKeyPath -option Constant -value "HKLM:\SOFTWARE\Wow6432Node\Caphyon\Advanced Installer"
  Set-Variable advinstRegKeyPath -option Constant -value "HKLM:\SOFTWARE\Caphyon\Advanced Installer"
  Set-Variable advinstPathRegValue -Option Constant -value "Advanced Installer Path"
  Set-Variable advinstBinFolder -option Constant -value "bin\x86\AdvancedInstaller.com"
  Set-Variable advinstTool  -option Constant -value "AdvancedInstaller.com"
  
  Trace-VstsEnteringInvocation $MyInvocation

  # Search the Advanced Installer root path in in both redirected and non-redirected
  # hives.
  $advinstRootPath = $null
  try {
    $advinstRootPath = (Get-ItemProperty -Path $advinstWowRegKeyPath -Name $advinstPathRegValue).$advinstPathRegValue
    if ( [string]::IsNullOrWhitespace($advinstRootPath) ) {
      $advinstRootPath = (Get-ItemProperty -Path advinstRegKeyPath -Name $advinstPathRegValue).$advinstPathRegValue
    }
  }
  catch {
    Write-VstsTaskDebug -Verbose $_.Exception.Message
  }
  
  # Compute whole path from the registry.
  if ($advinstRootPath)
  {
    $advinstComPath = Join-Path -Path $advinstRootPath -ChildPath $advinstBinFolder
    if ( Test-Path -Path $advinstComPath ) {
      return $advinstComPath
    }
  }

  # Advanced Installer si not installed on the system. Check for the exe in PATH.
  if ( Get-Command -Name $advinstTool ) {
    return $advinstTool
  } 
  
  # Advanced Installer tool cannot be found 
  Trace-VstsLeavingInvocation $MyInvocation
  return $null
}
