[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$Path
)

Add-Type -Assembly "System.IO.Compression.FileSystem"

Get-ChildItem -Path $Path -Filter "*Sitecore.Commerce.Engine.SDK*.zip" | ForEach-Object {
    $zipPath = $_.FullName

    try
    {
        $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
        
        ($zip.Entries | Where-Object { $_.FullName -like "Sitecore.*.dacpac" -and !($_.Name -like "*azure*") }) | Foreach-Object { 
            [IO.Compression.ZipFileExtensions]::ExtractToFile($_, (Join-Path $Path $_.Name), $true)
        }
    }
    finally
    {
        if ($zip -ne $null)
        {
            $zip.Dispose()
        }
    }
}