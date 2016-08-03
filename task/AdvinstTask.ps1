param (
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$aipPath,
    [string]$aipBuild,
    [string]$aipPackageName,
    [string]$aipOutputFolder,   
    [string]$aipExtraCommands,
    [string]$aipResetDigSign
)
 

# Display input parameters 
Write-Verbose -Verbose "Starting Advanced Installer build step."
Write-Verbose -Verbose "aipPath = $aipPath"
Write-Verbose -Verbose "aipBuild = $aipBuild"
Write-Verbose -Verbose "aipPackageName = $aipPackageName"
Write-Verbose -Verbose "aipOutputFolder = $aipOutputFolder"
Write-Verbose -Verbose "aipExtraCommands = $aipExtraCommands"
Write-Verbose -Verbose "aipResetDigSign = $aipResetDigSign"

# Load all dependent files for execution
Import-Module ./AdvinstTaskUtils.ps1 -Force

# Force errors to be "terminating" errors. Otherwise, control
# will not transfer to the catch block.
$defaultErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"

# Validate "aipPath" input parameter.
if ([string]::IsNullOrWhitespace($aipPath) -or !(Test-Path $aipPath) )
{
  throw (Get-LocalizedString -Key "The project file (AIP) not found at: $aipPath.")
}

# Validate output package name
if ( ![string]::IsNullOrWhitespace($aipPackageName) -and [string]::IsNullOrWhitespace($aipBuild))
{
  throw (Get-LocalizedString -Key "Using a package output name requires a build to be specified")
}

# Validate output folder path
if ( ![string]::IsNullOrWhitespace($aipOutputFolder) -and [string]::IsNullOrWhitespace($aipBuild))
{
  throw (Get-LocalizedString -Key "Using a package output folder requires a build to be specified")
}

# Detect Advanced Installer path and validate it
try 
{
  $advinstComPath = Get-AdvinstComPath
  Write-Verbose -Verbose "advinstComPath = $advinstComPath"
}
catch 
{
  throw (Get-LocalizedString -Key "Failed to detect Advanced Installer path.")
}

# Compute the command switches
$advinstCommands = @()
if ( ![string]::IsNullOrWhitespace($aipPackageName) )
{
  $advinstCommands += [string]::Format("SetPackageName ""{0}"" -buildname ""{1}""", $aipPackageName, $aipBuild)
}

if ( ![string]::IsNullOrWhitespace($aipOutputFolder) )
{
  $advinstCommands += [string]::Format("SetOutputLocation -buildname ""{0}"" -path ""{1}""", $aipBuild, $aipOutputFolder)
}

if ( $aipResetDigSign -eq "true" )
{
  $advinstCommands += "ResetSig"
}

if ( ![string]::IsNullOrWhitespace($aipExtraCommands) )
{
  $extraCommandsTokens = $aipExtraCommands.Split("`r`n")
  foreach ($token in $extraCommandsTokens) 
  {
    $advinstCommands += $token;
  }
}

if ( [string]::IsNullOrWhitespace($aipBuild) )
{
  $advinstCommands += "Build"
}
else 
{
  $advinstCommands += [string]::Format("Build -buildslist ""{0}""", $aipBuild)
}

Write-Verbose -Verbose "advinstCommands = $advinstCommands"

# Create and execute the Advanced Installer commands file.
try 
{
  # Create the Advanced Installer commands file.
  $advinstCommandsFile = [System.IO.Path]::GetTempFileName()
  Write-Verbose -Verbose "advinstCommandsFile = $advinstCommandsFile"
  Create-AicFile -aicPath $advinstCommandsFile -aicCommands $advinstCommands
}
catch
{
  Remove-Item $advinstCommandsFile
  throw (Get-LocalizedString -Key "Failed to create Advanced Installer commands file.")
}

# Import the Task.Internal dll that has all the cmdlets we need for Build
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
try
{
  # Execute commands file 
  $advinstComArguments = [string]::Format("/execute ""{0}"" ""{1}""", $aipPath, $advinstCommandsFile)
  Write-Host "Executing Advanced Installer..."
  Invoke-Tool -Path $advinstComPath -Arguments $advinstComArguments
}
catch
{
  throw (Get-LocalizedString -Key "Failed to execute Advanced Installer")
}

# Delete the Advanced Installer commands file
if ( Test-Path $aipPath )
{
  Remove-Item $advinstCommandsFile
}

$ErrorActionPreference = $defaultErrorActionPreference
Write-Verbose "Finished Advanced Installer build step."
 