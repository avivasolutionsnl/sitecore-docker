# Script to copy Solr cores
# Start and stop the Solr container and run this script.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Container = 'sitecore-xp_solr_1',
    [Parameter(Mandatory=$false)]
    [string]$FromCoresFilePath = 'C:\solr\solr-7.2.1\server\solr',
    [Parameter(Mandatory=$false)]
    [string]$ToCoresFilePath = 'cores/'
)

mkdir -Force -Path ${ToCoresFilePath}

docker cp ${Container}:${FromCoresFilePath} ${ToCoresFilePath}

mv -Force ${ToCoresFilePath}/solr/* ${ToCoresFilePath}
rm -Recurse ${ToCoresFilePath}/solr

# LCOW mount binds do not yet support locking
# Replace native locking by simple locking
gci ${ToCoresFilePath} -recurse -filter "solrconfig.xml" | ForEach { (Get-Content $_.PSPath | ForEach {$_ -replace "solr.lock.type:native", "solr.lock.type:simple"}) | Set-Content $_.PSPath }

# Fix wrong path configuration
gci ${ToCoresFilePath} -recurse -filter "core.properties" | ForEach { (Get-Content $_.PSPath | ForEach {$_ -replace "config=conf\\solrconfig.xml", "config=solrconfig.xml"}) | Set-Content $_.PSPath }

# Remove all lock files
Remove-Item -Recurse -Path ${ToCoresFilePath} -include *.lock
