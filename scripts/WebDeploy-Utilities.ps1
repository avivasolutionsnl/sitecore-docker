
Function RemoveDbDacFxDependencies {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WdpFullpath
    )

    Write-Host "Patching $WdpFullpath"
    
    $extractPath = Join-Path -Path (Split-Path $WdpFullpath) -ChildPath (Get-Item -Path $WdpFullpath).BaseName
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse
    }
    Expand-Archive -Path $WdpFullpath -DestinationPath $extractPath

    $parametersXmlPath = Join-Path -Path $extractPath -ChildPath "parameters.xml"
    $xml = [xml](Get-Content $parametersXmlPath)
    $parametersWithdbDacFxNodes = $xml.SelectNodes('//parameters/parameter[parameterEntry[@scope="dbDacFx"]]')
    $parametersWithdbDacFxNodes | % { $dbDacFxNode = $_.SelectSingleNode('//parameterEntry[@scope="dbDacFx"]'); $_.RemoveChild($dbDacFxNode); }
    $xml.OuterXml | Out-File $parametersXmlPath
    Compress-Archive -Path $parametersXmlPath -DestinationPath $WdpFullpath -Update

    $archiveXmlPath = Join-Path -Path $extractPath -ChildPath "archive.xml"
    $xml = [xml](Get-Content $archiveXmlPath)
    $dbDacFxNodes = $xml.SelectNodes('//sitemanifest/dbDacFx')
    $dbDacFxNodes | % { $xml.sitemanifest.RemoveChild($_) }
    $xml.OuterXml | Out-File $archiveXmlPath
    Compress-Archive -Path $archiveXmlPath -DestinationPath $WdpFullpath -Update

    Remove-Item $extractPath -Recurse
    
    Write-Host "Done patching $WdpFullpath!" -ForegroundColor Green
}