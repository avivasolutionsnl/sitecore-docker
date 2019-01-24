# escape=`
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD files/ /Files/

# Extract Marketing Automation, see InstallAutomationEngineModule SIF task
RUN Expand-Archive -Force -Path "/Files/$Env:COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE" -DestinationPath C:\inetpub\wwwroot\xconnect

# Copy XConnect Models for SC9 Commerce, see Connect.Copy.Models SIF task
COPY xc/xconnect/Sitecore.Commerce.Connect.XConnect.Models.json /Files/
RUN cp /Files/Sitecore.Commerce.Connect.XConnect.Models.json C:\inetpub\wwwroot\xconnect\App_data\jobs\continuous\IndexWorker\App_data\Models\; `
    cp /Files/Sitecore.Commerce.Connect.XConnect.Models.json C:\inetpub\wwwroot\xconnect\App_data\Models\
