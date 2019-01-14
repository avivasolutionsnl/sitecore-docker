# Script to copy Solr cores
# Start and stop the Solr container and run this script.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Container = 'sitecore-docker_solr_1',
    [Parameter(Mandatory=$false)]
    [string]$FromCoresFilePath = 'C:\solr\solr-6.6.2\server\solr',
    [Parameter(Mandatory=$false)]
    [string]$ToCoresFilePath = 'cores/'
)

mkdir -Force -Path ${ToCoresFilePath}

docker cp ${Container}:${FromCoresFilePath}\Sitecore_fxm_master_index ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\Sitecore_fxm_web_index ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\Sitecore_marketingdefinitions_master ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\Sitecore_marketingdefinitions_web ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\Sitecore_marketing_asset_index_web ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\Sitecore_marketing_asset_index_master ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\Sitecore_suggested_test_index ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\Sitecore_testing_index ${ToCoresFilePath}

docker cp ${Container}:${FromCoresFilePath}\Sitecore_core_index ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\Sitecore_master_index ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\Sitecore_web_index ${ToCoresFilePath}

docker cp ${Container}:${FromCoresFilePath}\xp0_xdb ${ToCoresFilePath}
docker cp ${Container}:${FromCoresFilePath}\xp0_xdb_rebuild ${ToCoresFilePath}

# LCOW mount binds do not yet support locking
# Replace native locking by simple locking
gci ${ToCoresFilePath} -recurse -filter "solrconfig.xml" | ForEach { (Get-Content $_.PSPath | ForEach {$_ -replace "solr.lock.type:native", "solr.lock.type:simple"}) | Set-Content $_.PSPath }

# Fix wrong path configuration
gci ${ToCoresFilePath} -recurse -filter "core.properties" | ForEach { (Get-Content $_.PSPath | ForEach {$_ -replace "config=conf\\solrconfig.xml", "config=solrconfig.xml"}) | Set-Content $_.PSPath }

# Remove all lock files
Remove-Item -Recurse -Path ${ToCoresFilePath} -include *.lock
