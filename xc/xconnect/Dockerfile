# escape=`
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE
ARG COMMERCE_CONNECT_PACKAGE

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY files/ /Files/

# Extract Marketing Automation, see Module-CommerceMarketingAutomation-Post SIF include
RUN Expand-Archive -Force -Path "/Files/$Env:COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE" -DestinationPath C:\inetpub\wwwroot\xconnect;

# Copy XConnect Models for SC9 Commerce, see CopyConnectModels SIF include
RUN Expand-Archive -Force -Path "/Files/$Env:COMMERCE_CONNECT_PACKAGE" -DestinationPath "/Files/temp"; `
    Copy-Item -Path "/Files/temp/Content/Website/XConnectModels/Sitecore.Commerce.Connect.XConnect.Models.json" -Destination C:\inetpub\wwwroot\xconnect\App_data\jobs\continuous\IndexWorker\App_data\Models\; `
    Copy-Item -Path "/Files/temp/Content/Website/XConnectModels/Sitecore.Commerce.Connect.XConnect.Models.json" -Destination C:\inetpub\wwwroot\xconnect\App_data\Models\; `
    Remove-Item "/Files/temp" -Recurse;
