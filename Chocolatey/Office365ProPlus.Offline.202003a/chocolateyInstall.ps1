﻿$ErrorActionPreference = 'Stop'

$script                     = $MyInvocation.MyCommand.Definition
$packageName                = 'Office365ProPlus'
$configFile                 = Join-Path $(Split-Path -parent $script) 'configuration.xml'
$configFile64               = Join-Path $(Split-Path -parent $script) 'configuration64.xml'
$bitCheck                   = Get-ProcessorBits
$forceX86                   = $env:chocolateyForceX86
$configurationFile          = if ($BitCheck -eq 32 -Or $forceX86) { $configFile } else { $configFile64 }
$officetempfolder           = Join-Path $env:Temp 'chocolatey\Office365ProPlus'

$pp = Get-PackageParameters
$configPath = $pp["ConfigPath"]
$language = $pp["Language"]
$installerFolder = $pp["InstallerFolder"]

if ($configPath)
{
    Write-Output "Custom config specified: $configPath"
    $configurationFile = $configPath
}
elseif ($language)
{
    Write-Output "Language specified: $language"
    
    $file = $configFile
    $x = [xml] (Get-Content $file)
    $nodes = $x.SelectNodes("/Configuration/Add/Product/Language")
    foreach($node in $nodes) {
        $node.SetAttribute("ID", $language)
    }
    $x.Save($file)
    
    $file = $configFile64
    $x = [xml] (Get-Content $file)
    $nodes = $x.SelectNodes("/Configuration/Add/Product/Language")
    foreach($node in $nodes) {
        $node.SetAttribute("ID", $language)
    }
    $x.Save($file)
}
elseif ($installerFolder)
{
    $officetempfolder = $installerFolder
}
else
{
    Write-Error 'No custom configuration specified.' -ErrorAction Stop
    Write-Output 'No language specified. Defaulting to OS language.'
    Write-Error 'No installation file specified. Please define one.' -ErrorAction Stop
}

$packageArgs                = @{
    packageName             = 'Office365DeploymentTool'
    fileType                = 'exe'
#    url                     = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_11509-33604.exe'
#    checksum                = 'D7978D00FC761157C4CC64B5055CF29D20BFA36669926B1197930B35C959DE5C'
#    checksumType            = 'sha256'
    softwareName            = 'Microsoft Office 365 ProPlus*'
#    silentArgs              = "/extract:`"$officetempfolder`" /log:`"$officetempfolder\OfficeInstall.log`" /quiet /norestart"
    validExitCodes          = @(
        0, # success
        3010, # success, restart required
        2147781575, # pending restart required
        2147205120  # pending restart required for setup update
    )
}

# Download and install the deployment tool
#Install-ChocolateyPackage @packageArgs

# Use the deployment tool to download the setup files
#$packageArgs['packageName'] = 'Office365ProPlusInstaller'
#$packageArgs['file'] = "$officetempfolder\Setup.exe"
#$packageArgs['silentArgs'] = "/download $configurationFile `"$officetempfolder\setup.exe`""
#Install-ChocolateyInstallPackage @packageArgs

# Run the actual Office setup
$packageArgs['file'] = "$officetempfolder\Setup.exe"
$packageArgs['packageName'] = $packageName
$packageArgs['silentArgs'] = "/configure $configurationFile"
Install-ChocolateyInstallPackage @packageArgs

<#
if (Test-Path "$officetempfolder") {
    Remove-Item -Recurse "$officetempfolder"
}
#>
