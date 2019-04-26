# escape=`
# Docker image for installing Solr cores using SIF
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install JAVA
ENV JAVA_HOME C:\\ojdkbuild
ENV JAVA_VERSION 8u161
ENV JAVA_OJDKBUILD_VERSION 1.8.0.161-1
ENV JAVA_OJDKBUILD_ZIP java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip

RUN setx /M PATH ('{0}\bin;{1}' -f $env:JAVA_HOME, $env:PATH); `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    $url = ('https://github.com/ojdkbuild/ojdkbuild/releases/download/{0}/{1}' -f $env:JAVA_OJDKBUILD_VERSION, $env:JAVA_OJDKBUILD_ZIP); `
    Invoke-WebRequest -Uri $url -OutFile 'ojdkbuild.zip'; `
    Expand-Archive ojdkbuild.zip -DestinationPath C:\; `
    Move-Item -Path ('C:\{0}' -f ($env:JAVA_OJDKBUILD_ZIP -Replace '.zip$', '')) -Destination $env:JAVA_HOME; `
    Remove-Item ojdkbuild.zip -Force;

# Install Solr
ARG SOLR_VERSION=7.2.1
RUN Invoke-WebRequest -Uri ('http://archive.apache.org/dist/lucene/solr/{0}/solr-{0}.zip' -f $env:SOLR_VERSION) -OutFile /solr.zip; `
    Expand-Archive -Path /solr.zip -DestinationPath /temp; `
    Move-Item -Path "C:/temp/solr-*" -Destination c:\solr;
