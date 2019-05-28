
[CmdletBinding()]
param(
    # Path to watch for changes
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})] 
    $Path,
    # Array Destination path to keep updated
    [Parameter(Mandatory=$true)]
    [array]$Destinations,
    # Array of filename patterns (-like operator) to ignore
    [Parameter(Mandatory=$false)]
    [array]$Ignore = @("*\obj\*", "*.cs", "*.csproj", "*.user")
)

# Milliseconds to sleep between sync operations
$SleepMilliseconds = 5000
if (Get-Item -Path Env:WatchSleepMilliseconds -ErrorAction SilentlyContinue) {
    $SleepMilliseconds = $Env:WatchSleepMilliseconds
}
function Sync 
{
    Foreach($destination in $Destinations) {
        try {
            $dirty = $false
            $raw = (robocopy $Path $destination /E /XX /MT:1 /NJH /NJS /FP /NDL /NP /NS /R:5 /W:1 /XD obj /XF *.user /XF *ncrunch* /XF *.cs)
            $raw | ForEach-Object {
                $line = $_.Trim().Replace("`r`n", "").Replace("`t", " ")
                $dirty = ![string]::IsNullOrEmpty($line)
        
                if ($dirty)
                {
                    Write-Host ("{0}: {1}" -f [DateTime]::Now.ToString("HH:mm:ss:fff"), $line) -ForegroundColor DarkGray            
                }
            }
        
            if ($dirty)
            {
                Write-Host ("{0}: Done syncing..." -f [DateTime]::Now.ToString("HH:mm:ss:fff")) -ForegroundColor Green
            }
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Host ("{0}: The following error occured during sync: $ErrorMessage" -f [DateTime]::Now.ToString("HH:mm:ss:fff")) -ForegroundColor Red
        }
    }
}

# Initial sync
Sync | Out-Null

Foreach($destination in $Destinations) {
    Write-Host ("{0}: Watching '{1}' for changes, will copy to '{2}' while ignoring '{3}'." -f [DateTime]::Now.ToString("HH:mm:ss:fff"), $Path, $destination, ($Ignore -join ", "))
}

# Start            
while($true) {   
    Sync | Write-Host

    Sleep -Milliseconds $SleepMilliseconds
}