# escape=`
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ADD sxa-solr.json /Files/Config/

RUN & 'c:/solr/bin/solr.cmd' start -p 8983; `
    Install-SitecoreConfiguration -Path 'C:/Files/Config/sxa-solr.json'`
    -SolrUrl "http://localhost:8983/solr" `
    -SolrRoot "c:/solr" `
    -SolrService "void" `
    -CorePrefix $env:SITECORE_CORE_PREFIX `
    -Skip "StopSolr", "StartSolr"; `
    Get-Process -Name "java" | Stop-Process -Force;
