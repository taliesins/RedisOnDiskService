[CmdletBinding()]
param(
	[string] $environmentConfigurationFilePath = (Join-Path (Split-Path -parent $MyInvocation.MyCommand.Definition) "deployment_configuration.json" ),
	[string] $productConfigurationFilePath = (Join-Path (Split-Path -parent $MyInvocation.MyCommand.Definition) "configuration.xml" )
)

$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
Import-Module $scriptPath\PowershellModules\CommonDeploy.psm1 -Force

$rootPath = Split-Path -parent $scriptPath

$e = $environmentConfiguration = Read-ConfigurationTokens $environmentConfigurationFilePath

#Ensure that database file directory exists
$databaseWorkingDirectory = $e.DatabaseFileDirectory
if($databaseWorkingDirectory.StartsWith(".")) {
	$databaseWorkingDirectory = (Join-Path $rootPath $databaseWorkingDirectory.SubString(1, $databaseWorkingDirectory.Length - 1)).ToString()
}

$databaseWorkingDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($databaseWorkingDirectory)

if (!(Test-Path $databaseWorkingDirectory)){
	mkdir $databaseWorkingDirectory
}

#Ensure that log working directory exists
$logWorkingDirectory = split-path $e.LogFile
if($logWorkingDirectory.StartsWith(".")) {
	$logWorkingDirectory = (Join-Path $rootPath $logWorkingDirectory.SubString(1, $logWorkingDirectory.Length - 1)).ToString()
}

$logWorkingDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($logWorkingDirectory)

if (!(Test-Path $logWorkingDirectory)){
	mkdir $logWorkingDirectory
}

# Setup the configuration
$updateConfiguration = Join-Path $scriptPath "UpdateConfiguration.ps1"
if(Test-Path $updateConfiguration) {
	&$updateConfiguration $environmentConfigurationFilePath $productConfigurationFilePath
}

Install-All `
	-rootPath $rootPath `
	-environmentConfigurationFilePath $environmentConfigurationFilePath `
	-productConfigurationFilePath $productConfigurationFilePath

# Run post install configuration
$updateConfigurationPostInstall = Join-Path $scriptPath "UpdateConfigurationPostInstall.ps1"
if(Test-Path $updateConfigurationPostInstall) {
    &$updateConfigurationPostInstall $environmentConfigurationFilePath $productConfigurationFilePath
}    