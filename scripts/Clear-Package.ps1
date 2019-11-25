[CmdletBinding()]
# Remove DacFx and SQL elements from WebDeploy (WDP) package so this can be installed without DacPac installation
param(
    # Path of the WDP package
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ -PathType "Leaf" })] 
    [string]$Path
)

# Create temp folder
$tempPath = Join-Path $PSScriptRoot "\temp"
New-Item -ItemType directory -Force -Path $tempPath | Out-Null

function Remove-Elements($XmlPath, $XPath)
{
    [xml]$xml = Get-Content -Path $XmlPath

    $node = $xml.SelectSingleNode($XPath)

    while ($null -ne $node)
    {
        $node.ParentNode.RemoveChild($node) | Out-Null
        $node = $xml.SelectSingleNode($XPath)
    }

    $xml.Save($XmlPath)
}

Add-Type -AssemblyName "System.IO.Compression"
Add-Type -AssemblyName "System.IO.Compression.FileSystem"

try
{
    $stream = New-Object IO.FileStream($Path, [IO.FileMode]::Open)
    $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Update)

    # delete dacpac, old parameters and archive files
    ($zip.Entries | Where-Object { $_.FullName -like "*.dacpac" -or $_.FullName -eq "parameters.xml" -or $_.FullName -eq "archive.xml" }) | Foreach-Object {         
        if ($_.FullName -like "*.xml") {
            # extract the xml files before deleting them
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, (Join-Path $tempPath $_.FullName), $true)
        }
        $_.Delete()
    }

    # remove sql parameter elements from parameters
    Remove-Elements -XmlPath (Join-Path $tempPath "parameters.xml") -XPath ".//parameter[contains(@tags, 'SQLConnectionString')]"

    # remove dacfx elements from archive
    Remove-Elements -XmlPath (Join-Path $tempPath "archive.xml") -XPath ".//dbDacFx"

    # update zip with new parameters and archive files
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $tempPath "\parameters.xml"), "parameters.xml", "Optimal") | Out-Null
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $tempPath "\archive.xml"), "archive.xml", "Optimal") | Out-Null
}
finally
{
    if ($null -ne $zip)
    {
        $zip.Dispose()
    }

    if ($null -ne $stream)
    {   
        $stream.Dispose()
    }
}
