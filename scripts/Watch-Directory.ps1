[CmdletBinding()]
param(
    # Path to watch for changes
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})] 
    $Path,
    # Destination path to keep updated
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_ -PathType 'Container'})] 
    $Destination,
    # Array of filename patterns (-like operator) to ignore
    [Parameter(Mandatory=$false)]
    [array]$Ignore = @("*\obj\*", "*.cs", "*.csproj", "*.user")
)

function Sync 
{
    Get-ChildItem -Path $Path -Recurse -File | % {
        $sourcePath = $_.FullName
        $targetPath = ("{0}\{1}" -f $Destination, $_.FullName.Replace("$Path\", ""))  
        $ignored = $false
        
        if($Ignore -ne $null -and $Ignore.Length -gt 0) {
            :filter foreach($filter in $Ignore) {
                if($sourcePath -like $filter)
                {                    
                    $ignored = $true
                    break :filter
                }
            }                
        }

        if($ignored -eq $false)
        {
            $triggerReason = $null

            if(Test-Path -Path $targetPath -PathType Leaf) 
            {
                Compare-Object (Get-Item $sourcePath) (Get-Item $targetPath) -Property Name, Length, LastWriteTime | % {
                    $triggerReason = "Different"
                }
            }
            else
            {
                $triggerReason = "Missing"
            }

            if($triggerReason -ne $null)
            {
                New-Item -Path (Split-Path $targetPath) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
               
                Copy-Item -Path $sourcePath -Destination $targetPath -Force
               
                Write-Output ("{0}: {1, -9} -> {2, -9}" -f [DateTime]::Now.ToString("HH:mm:ss:fff"), $triggerReason, ($sourcePath.Replace("$Path\", "")))
            }
        }
    }   
}

$Destination = $Destination.TrimEnd("\")

Write-Host ("{0}: Warming up..." -f [DateTime]::Now.ToString("HH:mm:ss:fff"))

# Initial sync
Sync | Out-Null

# Warm up
try 
{
    Invoke-WebRequest -Uri "http://localhost:80" -UseBasicParsing -TimeoutSec 20 -ErrorAction "SilentlyContinue" | Out-Null
}
catch 
{
    # OK    
}

Write-Host ("{0}: Watching '{1}' for changes, will copy to '{2}' while ignoring '{3}'." -f [DateTime]::Now.ToString("HH:mm:ss:fff"), $Path, $Destination, ($Ignore -join ", "))

# Start            
while($true)
{   
    Sync | Write-Host

    Sleep -Milliseconds 500
}