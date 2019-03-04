Set-StrictMode -Version 2.0
 
Function Invoke-RegisterWindowsService {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    $pathWithArguments = "$Path ""-service"""
    New-Service -name $Name -binaryPathName $pathWithArguments -startupType Automatic
}
Register-SitecoreInstallExtension -Command Invoke-RegisterWindowsService -As RegisterWindowsService -Type Task