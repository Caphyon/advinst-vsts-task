Function Get-AdvinstComPath {

  [CmdletBinding()]
  param()
  
  # Constants 
  Set-Variable advinstWowRegKeyPath -option Constant -value "HKLM:\SOFTWARE\Wow6432Node\Caphyon\Advanced Installer"
  Set-Variable advinstRegKeyPath -option Constant -value "HKLM:\SOFTWARE\Caphyon\Advanced Installer"
  Set-Variable advinstPathRegValue -Option Constant -value "Advanced Installer Path"
  Set-Variable advinstBinFolder -option Constant -value "bin\x86\AdvancedInstaller.com"
  
  Trace-VstsEnteringInvocation $MyInvocation

  # Search the Advanced Installer root path in in both redirected and non-redirected
  # hives.
  try {
    $advinstRootPath = (Get-ItemProperty -Path $advinstWowRegKeyPath -Name $advinstPathRegValue).$advinstPathRegValue
    if ( [string]::IsNullOrWhitespace($advinstRootPath) ) {
      $advinstRootPath = (Get-ItemProperty -Path advinstRegKeyPath -Name $advinstPathRegValue).$advinstPathRegValue
    }
  
    # Compute whole path
    $advinstComPath = Join-Path -Path $advinstRootPath -ChildPath $advinstBinFolder
    return $advinstComPath
  }
  catch [System.Management.Automation.ItemNotFoundException] {
    Write-VstsTaskError -Verbose $_.Exception.Message
  }
  finally {
    Trace-VstsLeavingInvocation $MyInvocation
  }
}