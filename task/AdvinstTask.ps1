[CmdletBinding()]
param ()

Trace-VstsEnteringInvocation $MyInvocation
# Force errors to be "terminating" errors. Otherwise, control
# will not transfer to the catch block.
$defaultErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"
$advinstCommandsFile = $null;

try {
  
  Import-VstsLocStrings "$PSScriptRoot\task.json"

  # Get the inputs.
  $aipPath = Get-VstsInput -Name AipPath -Require
  $aipBuild = Get-VstsInput -Name AipBuild
  $aipPackageName = Get-VstsInput -Name AipPackageName
  $aipOutputFolder = Get-VstsInput -Name AipOutputFolder
  # If you do not set a value, or set a value then remove your setting when you edit a build, 
  # then you don’t get an empty string.You get the path to the BUILD_SOURCESDIRECTORY e.g. c:\agent\_work\3\s
  # Reset this value to use it as needed.
  if ($aipOutputFolder -eq $Env:BUILD_SOURCESDIRECTORY ) {
    Write-VstsTaskDebug -Verbose "Reset AipOutputFolder. OLD:$aipOutputFolder NEW:(empty)." 
    $aipOutputFolder = ""
  }
  $aipExtraCommands = Get-VstsInput -Name AipExtraCommands
  $aipResetDigSign = Get-VstsInput -Name AipResetDigSign -AsBool

  Write-VstsTaskVerbose(Get-VstsLocString -Key AI_StartTaskLog) -AsOutput

  # Display input parameters 
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
  Assert-VstsPath -LiteralPath $aipPath

  # Validate output package name
  if ( ![string]::IsNullOrEmpty($aipPackageName) -and [string]::IsNullOrWhitespace($aipBuild)) {
    throw (Get-VstsLocString -Key AI_BuildReqName)
  }

  # Validate output folder path
  if ( ![string]::IsNullOrEmpty($aipOutputFolder) -and [string]::IsNullOrWhitespace($aipBuild)) {
    throw (Get-VstsLocString -Key AI_BuildReqFolder)
  }

  # Validate the Advanced Installer command line tool path.
  $advinstComPath = Get-AdvinstComPath
  Write-VstsTaskVerbose "advinstComPath = $advinstComPath"
  if ( [string]::IsNullOrEmpty($advinstComPath) ) {
    throw (Get-VstsLocString -Key AI_AdvinstNotFoundErr);
  }
  
  # Compute the command switches
  $advinstCommands = @()
  if ( ![string]::IsNullOrEmpty($aipPackageName) ) {
    $advinstCommands += [string]::Format("SetPackageName ""{0}"" -buildname ""{1}""", $aipPackageName, $aipBuild)
  }

  if ( ![string]::IsNullOrEmpty($aipOutputFolder) ) {
    $advinstCommands += [string]::Format("SetOutputLocation -buildname ""{0}"" -path ""{1}""", $aipBuild, $aipOutputFolder)
  }

  if ( $aipResetDigSign -eq "true" ) {
    $advinstCommands += "ResetSig"
  }

  if ( ![string]::IsNullOrEmpty($aipExtraCommands) ) {
    $extraCommandsTokens = $aipExtraCommands.Split("`r`n")
    foreach ($token in $extraCommandsTokens) {
      $advinstCommands += $token;
    }
  }

  if ( [string]::IsNullOrEmpty($aipBuild) ) {
    $advinstCommands += "Build"
  }
  else {
    $advinstCommands += [string]::Format("Build -buildslist ""{0}""", $aipBuild)
  }

  # Create the Advanced Installer commands file.
  $advinstCommandsFile = [System.IO.Path]::GetTempFileName()
  Write-VstsTaskVerbose "advinstCommandsFile = $advinstCommandsFile"
  Write-AicFile -aicPath $advinstCommandsFile -aicCommands $advinstCommands
  Write-VstsTaskVerbose "advinstCommands = $advinstCommands"

  # Execute commands file 
  $advinstComArguments = [string]::Format("/execute ""{0}"" ""{1}""", $aipPath, $advinstCommandsFile)
  Write-VstsTaskVerbose(Get-VstsLocString -Key AI_StartExeLog) -AsOutput
  Invoke-VstsTool -FileName $advinstComPath -Arguments $advinstComArguments -RequireExitCodeZero
}
catch {
  $errorMessage = $_.Exception.Message
  Write-VstsTaskError (Get-VstsLocString -Key AI_ExecFailedErr -ArgumentList $errorMessage)
  Write-VstsSetResult -Result "Failed" -Message (Get-VstsLocString -Key AI_ExecFailedErr -ArgumentList $errorMessage)
}
finally {
  $ErrorActionPreference = $defaultErrorActionPreference
  if ( $advinstCommandsFile -and (Test-Path $advinstCommandsFile) ) {
    Remove-Item $advinstCommandsFile
  }
  Trace-VstsLeavingInvocation $MyInvocation
  Write-VstsTaskVerbose (Get-VstsLocString -Key AI_FinishTaskLog) -AsOutput
}
