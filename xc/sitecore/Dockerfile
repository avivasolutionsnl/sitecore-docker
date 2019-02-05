# escape=`

# Stage 0: prepare files
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as builder

ARG COMMERCE_SIF_PACKAGE
ARG COMMERCE_CONNECT_PACKAGE
ARG COMMERCE_MA_PACKAGE
ARG COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE
ARG COMMERCE_XPROFILES_PACKAGE
ARG COMMERCE_XANALYTICS_PACKAGE

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

ADD files/ /Files/

RUN Expand-Archive -Path "/Files/$Env:COMMERCE_SIF_PACKAGE" -DestinationPath /Files/CommerceSIF -Force; `
    Expand-Archive -Path "/Files/$Env:COMMERCE_CONNECT_PACKAGE" -DestinationPath /Files/SitecoreCommerceConnectCore -Force; `
    Expand-Archive -Path "/Files/$Env:COMMERCE_MA_PACKAGE" -DestinationPath /Files/CommerceMACore -Force; `
    Expand-Archive -Path "/Files/$Env:COMMERCE_MA_FOR_AUTOMATION_ENGINE_PACKAGE" -DestinationPath /Files/CommerceMACoreForAE -Force; `
    Expand-Archive -Path "/Files/$Env:COMMERCE_XPROFILES_PACKAGE" -DestinationPath /Files/CommerceXProfiles -Force; `
    Expand-Archive -Path "/Files/$Env:COMMERCE_XANALYTICS_PACKAGE" -DestinationPath /Files/CommerceXAnalytics -Force

# Stage 1: perform actual build
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG COMMERCE_CERT_PATH
ARG ROOT_CERT_PATH
ARG WEB_TRANSFORM_TOOL
ARG COMMERCE_CONNECT_ENGINE_PACKAGE

COPY --from=builder /Files/CommerceSIF /Files/CommerceSIF/
COPY --from=builder /Files/SitecoreCommerceConnectCore /Files/SitecoreCommerceConnectCore
COPY --from=builder /Files/CommerceMACore /Files/CommerceMACore
COPY --from=builder /Files/CommerceMACoreForAE /Files/CommerceMACoreForAE
COPY --from=builder /Files/CommerceXProfiles /Files/CommerceXProfiles
COPY --from=builder /Files/CommerceXAnalytics /Files/CommerceXAnalytics
COPY --from=builder /Files/${WEB_TRANSFORM_TOOL} /Files/Microsoft.Web.XmlTransform.dll
COPY --from=builder /Files/${COMMERCE_CONNECT_ENGINE_PACKAGE} /Files/Sitecore.Commerce.Engine.Connect.update
COPY --from=builder /Files/${ROOT_CERT_PATH} /Files/${ROOT_CERT_PATH}

ADD xc/sitecore/InstallCommercePackages.ps1 /Scripts/
ADD files/$COMMERCE_CERT_PATH /Files/
ADD scripts/Import-Certificate.ps1 /Scripts/

# Trust Self signed certificates & import XConnect certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:COMMERCE_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:ROOT_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:COMMERCE_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:ROOT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

# Patch Solr config, set initializeOnAdd = true
# See: https://sitecore.stackexchange.com/questions/11523/index-sitecore-marketingdefinitions-master-was-not-found-exception-in-sitecore
ADD xc/sitecore/Sitecore.Commerce.Engine.Connectors.Index.Solr.InitializeOnAdd.config /inetpub/wwwroot/sitecore/App_Config/Include/zSitecore.Commerce.Engine.Connectors.Index.Solr.InitializeOnAdd.config

ENTRYPOINT /Scripts/Watch-Directory.ps1 -Path C:\Workspace -Destination c:\inetpub\wwwroot\sitecore
