[CmdletBinding()]
param ()

Trace-VstsEnteringInvocation $MyInvocation
# Force errors to be "terminating" errors. Otherwise, control
# will not transfer to the catch block.
$defaultErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"
$advinstCommandsFile = $null;

try {

  # Get the inputs.
  $aipPath = Get-VstsInput -Name AipPath -Require
  $aipBuild = Get-VstsInput -Name AipBuild
  $aipPackageName = Get-VstsInput -Name AipPackageName
  $aipOutputFolder = Get-VstsInput -Name AipOutputFolder
  $aipExtraCommands = Get-VstsInput -Name AipExtraCommands
  $aipResetDigSign = Get-VstsInput -Name AipResetDigSign -AsBool

  # Display input parameters 
  Write-VstsTaskVerbose "Starting Advanced Installer build step."
  Write-VstsTaskVerbose "aipPath = $aipPath"
  Write-VstsTaskVerbose "aipBuild = $aipBuild"
  Write-VstsTaskVerbose "aipPackageName = $aipPackageName"
  Write-VstsTaskVerbose "aipOutputFolder = $aipOutputFolder"
  Write-VstsTaskVerbose "aipExtraCommands = $aipExtraCommands"
  Write-VstsTaskVerbose "aipResetDigSign = $aipResetDigSign"

  # Import helper scripts
  . $PSScriptRoot\Get-AdvinstComPath.ps1
  . $PSScriptRoot\Write-AicFile.ps1

  # Validate "aipPath" input parameter.
  if ([string]::IsNullOrWhitespace($aipPath) -or !(Test-Path $aipPath) ) {
    throw (Get-LocalizedString -Key "The project file (AIP) not found at: $aipPath.")
  }

  # Validate output package name
  if ( ![string]::IsNullOrWhitespace($aipPackageName) -and [string]::IsNullOrWhitespace($aipBuild)) {
    throw (Get-LocalizedString -Key "Using a package output name requires a build to be specified")
  }

  # Validate output folder path
  if ( ![string]::IsNullOrWhitespace($aipOutputFolder) -and [string]::IsNullOrWhitespace($aipBuild)) {
    throw (Get-LocalizedString -Key "Using a package output folder requires a build to be specified")
  }

  $advinstComPath = Get-AdvinstComPath
  Write-VstsTaskVerbose "advinstComPath = $advinstComPath"

  # Compute the command switches
  $advinstCommands = @()
  if ( ![string]::IsNullOrWhitespace($aipPackageName) ) {
    $advinstCommands += [string]::Format("SetPackageName ""{0}"" -buildname ""{1}""", $aipPackageName, $aipBuild)
  }

  if ( ![string]::IsNullOrWhitespace($aipOutputFolder) ) {
    $advinstCommands += [string]::Format("SetOutputLocation -buildname ""{0}"" -path ""{1}""", $aipBuild, $aipOutputFolder)
  }

  if ( $aipResetDigSign -eq "true" ) {
    $advinstCommands += "ResetSig"
  }

  if ( ![string]::IsNullOrWhitespace($aipExtraCommands) ) {
    $extraCommandsTokens = $aipExtraCommands.Split("`r`n")
    foreach ($token in $extraCommandsTokens) {
      $advinstCommands += $token;
    }
  }

  if ( [string]::IsNullOrWhitespace($aipBuild) ) {
    $advinstCommands += "Build"
  }
  else {
    $advinstCommands += [string]::Format("Build -buildslist ""{0}""", $aipBuild)
  }

  # Create the Advanced Installer commands file.
  $advinstCommandsFile = [System.IO.Path]::GetTempFileName()
  Write-VstsTaskVerbose "advinstCommandsFile = $advinstCommandsFile"
  Create-AicFile -aicPath $advinstCommandsFile -aicCommands $advinstCommands
  Write-VstsTaskVerbose "advinstCommands = $advinstCommands"

  # Execute commands file 
  $advinstComArguments = [string]::Format("/execute ""{0}"" ""{1}""", $aipPath, $advinstCommandsFile)
  Write-Host "Executing Advanced Installer..."
  Invoke-VstsTool -FileName $advinstComPath -Arguments $advinstComArguments -RequireExitCodeZero

}
catch {
  throw (Get-LocalizedString -Key "Failed to execute Advanced Installer")
}
finally {
  $ErrorActionPreference = $defaultErrorActionPreference
  if (Test-Path $advinstCommandsFile) {
    Remove-Item $advinstCommandsFile
  }
  Trace-VstsLeavingInvocation $MyInvocation
  Write-VstsTaskVerbose "Finished Advanced Installer build step."
}