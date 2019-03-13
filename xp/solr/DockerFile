# escape=`
ARG BUILDER_BASE_IMAGE
ARG BASE_IMAGE
FROM ${BUILDER_BASE_IMAGE} as builder

# Install Sitecore Solr cores using SIF
ARG CONFIG_PACKAGE
ARG INSTALL_TEMP='c:\\install'
ARG SIF_CONFIG=${INSTALL_TEMP}\\sitecore-solr.json
ARG SITECORE_CORE_PREFIX
ARG XCONNECT_CORE_PREFIX
ARG XCONNECT_PACKAGE

COPY files/$XCONNECT_PACKAGE /Files/
COPY xp/solr/xconnect-xp0-configuresolrschemas.json ${INSTALL_TEMP}/
COPY files/$CONFIG_PACKAGE ${INSTALL_TEMP}/

RUN & 'c:/solr/bin/solr.cmd' start -p 8983; `
    Expand-Archive -Path (Join-Path $env:INSTALL_TEMP '*Configuration files*.zip') -DestinationPath $env:INSTALL_TEMP; `
    Install-SitecoreConfiguration -Path (Join-Path $env:INSTALL_TEMP 'sitecore-solr.json') `
    -SolrUrl "http://localhost:8983/solr" `
    -SolrRoot "c:/solr" `
    -SolrService "void" `
    -CorePrefix $env:SITECORE_CORE_PREFIX `
    -Skip "StopSolr", "StartSolr"; `
    Install-SitecoreConfiguration -Path (Join-Path $env:INSTALL_TEMP 'xconnect-solr.json') `
    -SolrUrl "http://localhost:8983/solr" `
    -SolrRoot "c:/solr" `
    -SolrService "void" `
    -CorePrefix $env:XCONNECT_CORE_PREFIX `
    -Skip "StopSolr", "StartSolr"; `
    Add-Type -Assembly System.IO.Compression.FileSystem; `
    $zip = [IO.Compression.ZipFile]::OpenRead('c:/Files/' + $Env:XCONNECT_PACKAGE); `
    $zip.Entries | where {$_.Name -like 'schema.json'} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, 'C:/Files/schema.json', $true)}; `
    $zip.Dispose(); `
    Install-SitecoreConfiguration -Path (Join-Path $env:INSTALL_TEMP 'xconnect-xp0-configuresolrschemas.json') `
    -SolrUrl "http://localhost:8983/solr" `
    -SolrCorePrefix $Env:XCONNECT_CORE_PREFIX; `
    Get-Process -Name "java" | Stop-Process -Force;

# Copy the clean cores for later use
RUN New-Item -Path 'c:/clean' -ItemType Directory | Out-Null; `
    Get-ChildItem -Path 'c:/solr/server/solr' | Foreach-Object { Copy-Item -Path $_.FullName -Destination 'c:/clean' -Recurse }

# Runtime image
FROM ${BASE_IMAGE} as final

COPY --from=builder /solr /solr
COPY --from=builder /clean /clean
COPY --from=builder /windows/system32/find.exe /windows/system32/
COPY xp/solr/PersistCores.cmd .

RUN mkdir data

# Set solr home dir to volume
ENV SOLR_HOME=c:/data

# Expose default port
EXPOSE 8983

# Boot
COPY xp/solr/Boot.cmd .

CMD Boot.cmd c:\\solr 8983 c:\\clean c:\\data
