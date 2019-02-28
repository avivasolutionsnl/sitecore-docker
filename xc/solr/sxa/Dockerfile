# escape=`
ARG BUILDER_BASE_IMAGE
ARG BASE_IMAGE
FROM ${BUILDER_BASE_IMAGE} as builder

# Install Sitecore Solr cores using SIF
ARG INSTALL_TEMP='c:\\install'
ARG SITECORE_CORE_PREFIX="sitecore"

COPY sxa-solr.json ${INSTALL_TEMP}/

RUN & 'c:/solr/bin/solr.cmd' start -p 8983; `
    Install-SitecoreConfiguration -Path (Join-Path $env:INSTALL_TEMP 'sxa-solr.json') `
    -SolrUrl "http://localhost:8983/solr" `
    -SolrRoot "c:/solr" `
    -SolrService "void" `
    -CorePrefix $env:SITECORE_CORE_PREFIX `
    -Skip "StopSolr", "StartSolr"; `
   Get-Process -Name "java" | Stop-Process -Force;

# Copy the clean cores for later use
RUN New-Item -Path 'c:/clean' -ItemType Directory | Out-Null; `
    Get-ChildItem -Path 'c:/solr/server/solr' | Foreach-Object { Copy-Item -Path $_.FullName -Destination 'c:/clean' -Recurse }

# Runtime image
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY --from=builder /clean /clean
