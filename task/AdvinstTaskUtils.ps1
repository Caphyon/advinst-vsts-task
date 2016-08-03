# Detects the latest version of Advanced Installer installed on the agent 
Function Get-AdvinstComPath
{
  # Constants 
  Set-Variable advinstWowRegKeyPath -option Constant -value "HKLM:\SOFTWARE\Wow6432Node\Caphyon\Advanced Installer"
  Set-Variable advinstRegKeyPath -option Constant -value "HKLM:\SOFTWARE\Caphyon\Advanced Installer"
  Set-Variable advinstPathRegValue -Option Constant -value "Advanced Installer Path"
  Set-Variable advinstBinFolder -option Constant -value "bin\x86\AdvancedInstaller.com"
  
  # Search the Advanced Installer root path in in both redirected and non-redirected
  # hives.
  try 
  {
    $advinstRootPath = (Get-ItemProperty -Path $advinstWowRegKeyPath -Name $advinstPathRegValue).$advinstPathRegValue
  }
  catch [System.Management.Automation.ItemNotFoundException]
  {
    Write-Verbose -Verbose $_.Exception.Message
  }
  
  if ( [string]::IsNullOrWhitespace($advinstRootPath) )
  {
    $advinstRootPath = (Get-ItemProperty -Path advinstRegKeyPath -Name $advinstPathRegValue).$advinstPathRegValue
  }
  
  # Compute whole path
  $advinstComPath = Join-Path -Path $advinstRootPath -ChildPath $advinstBinFolder
  return $advinstComPath
}

Function Create-AicFile
{
  Param
  ( 
    [Parameter(Mandatory=$true)]
    [string]$aicPath,
    
    [Parameter(Mandatory=$true)]
    [string[]]$aicCommands
  )
  
  $aicFileContent = ";aic;"
  foreach ($token in $aicCommands) 
  {
    $aicFileContent += "`r`n"
    $aicFileContent += $token;
  }
  Write-Verbose -Verbose "aicFileContent = $aicFileContent"
  $aicFileContent | Out-File $aicPath -encoding Unicode -Append
}