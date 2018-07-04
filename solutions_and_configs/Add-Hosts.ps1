#############################################################################
# Add entries in windows hosts. If key is available, it will be overwritten #
#############################################################################

function setHostEntries([hashtable] $entries) {
    $hostsFile = "$env:windir\System32\drivers\etc\hosts"
    $newLines = @()

    $c = Get-Content -Path $hostsFile
    foreach ($line in $c) {
        $bits = [regex]::Split($line, "\s+")
        if ($bits.count -eq 2) {
            $match = $NULL
            ForEach($entry in $entries.GetEnumerator()) {
                if($bits[1] -eq $entry.Key) {
                    $newLines += ($entry.Value + '     ' + $entry.Key)
                    Write-Host Replacing HOSTS entry for $entry.Key
                    $match = $entry.Key
                    break
                }
            }
            if($match -eq $NULL) {
                $newLines += $line
            } else {
                $entries.Remove($match)
            }
        } else {
            $newLines += $line
        }
    }

    foreach($entry in $entries.GetEnumerator()) {
        Write-Host Adding HOSTS entry for $entry.Key
        $newLines += $entry.Value + '     ' + $entry.Key
    }

    Write-Host Saving $hostsFile
    Clear-Content $hostsFile
    foreach ($line in $newLines) {
        $line | Out-File -encoding ASCII -append $hostsFile
    }
}

$entries = @{
	'docker.mssql' = "172.16.1.2"
	'docker.habitat.dev.local' = "172.16.1.3"
	'docker.solr' = "172.16.1.4"
	'xconnect' = "172.16.1.5"
};
setHostEntries($entries)