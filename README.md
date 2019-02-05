Run Sitecore 9 XP0 and XC using Docker for Windows.

# Disclaimer
This repository contains experimental code that we use in development setups. We do not consider the current code in this repository ready for production.
Hopefully this will help you to get up and running with Sitecore and Docker. By no means we consider ourselves Docker experts and thus expect these images to still contain a lot of bugs. Great help for creating this setup was provided by the [sitecoreops](https://github.com/sitecoreops/sitecore-images) and [sitecore-nine-docker](https://github.com/pbering/sitecore-nine-docker) repos. Please feel free to provide feedback by creating an issue, PR, etc. 


# Requirements
- Windows 10 update 1809
- Docker for Windows (version 18.09.1 or better): https://docs.docker.com/docker-for-windows/
- Sitecore installation files
- [Nuke.build](https://nuke.build)


# Build
As Sitecore does not distribute Docker images, the first step is to build the required Docker images.

## Pre-build steps
For this you need to place the Sitecore installation files and a Sitecore license file in the `files` directory. Which files to use are defined in the build configuration files:
- [Base images build config](./build/Build.Base.cs)
- [XP images build config](./build/Build.Xp.cs)
- [XC images build config](./build/Build.Xc.cs)
- [Overall build config](./build/Build.cs)

The XP0 Sitecore topology requires SSL between the services, for this we need self signed certificates for the 
xConnect and SOLR roles. You can generate these by running the `./Generate-Certificates.ps1` script (note that this requires an Administrator elevated powershell environment and you may need to set the correct execution policy, e.g. `PS> powershell.exe -ExecutionPolicy Unrestricted`).

> SXA is installed using Commerce SIF. Therefore building SXA images requires you have the Commerce SIF package availabled in the `Files` directory.

## Build
Build all images using:
```
PS> nuke 
```

The build results in the following Docker images:
- Base
    - `sitecore-base-sitecore`: IIS + ASP.NET
    - `sitecore-base-openjdk`: Windows Server Core + OpenJDK
    - `sitecore-base-solr-builder`: sitecore-base-openjdk + Solr

- XP0
    - `sitecore-xp-sitecore`: IIS + ASP.NET + Sitecore
    - `sitecore-xp-mssql`: MS SQL + Sitecore databases
    - `sitecore-xp-solr`: Apache Solr 
    - `sitecore-xp-xconnect`: IIS + ASP.NET + XConnect
- XP0 with SXA installed
    - `sitecore-xp-sitecore-sxa`
    - `sitecore-xp-solr-sxa`
    - `sitecore-xp-mssql-sxa`

- XC
    - `sitecore-xc-commerce`: ASP.NET
    - `sitecore-xc-sitecore`: IIS + ASP.NET + Sitecore
    - `sitecore-xc-sitecore-intermediate`: *Only used during build*
    - `sitecore-xc-mssql`: MS SQL + Sitecore databases
    - `sitecore-xc-mssql-intermediate`: *Only used during build*
    - `sitecore-xc-solr`: Apache Solr 
    - `sitecore-xc-xconnect`: IIS + ASP.NET + XConnect
- XC with SXA installed
    - `sitecore-xc-sitecore-sxa`
    - `sitecore-xc-solr-sxa`
    - `sitecore-xc-mssql-sxa`

All images are contain a version tag that corresponds to the Sitecore commercial version number e.g. `xp-sitecore-sitecore:9.0.2`.

### Build a selection of images
To build a certain Docker image or set of images run a specific Nuke.Build target, e.g to build only XP0 images:
```
PS> nuke xp
```
Each Docker image (or set of images, e.g. `XP0` or `XC`) has a corresponding target definition in the build configuration.


### Push images
To push the Docker images to your repository use the `push` build targets, e.g. to push all images:
```
PS> nuke push
```

NB. To prefix the Docker images with your repository name change the `RepoImagePrefix`, `XpImagePrefix` and/or `XcImagePrefix` build setting parameters.


# Run
Docker compose is used to start up all required services. 
Docker compose files are present for each setup in their respective directories, e.g. `xp` and `xc`. Use your setup of choice as working directory for all docker-compose commands below.

Place the Sitecore source files in the `.\wwwroot\sitecore` (and `.\wwwroot\commerce` for XC) directory.

Create a webroot directory:
```
PS> mkdir -p wwwroot/sitecore
```

Create the log directories which are mounted in the Docker compose file:
```
PS> ./CreateLogDirs.ps1
```

To start Sitecore;
```
PS> docker-compose up
```

or to start Sitecore with SXA:
```
PS> docker-compose -f docker-compose.yml -f docker-compose.sxa.yml up
```

Run-time parameters can be modified using the `.env` file:

| Field                     | Description                                      |
| ------------------------- | ------------------------------------------------ |
| SQL_SA_PASSWORD           | The password to use for the SQL sa user          |
| SITECORE_SITE_NAME        | Host name of the Sitecore site                   |
| IMAGE_PREFIX              | The Docker image prefix to use                   |
| TAG                       | The version to tag the Docker images with        |

NB. these run-time parameters should match the used build parameters.

## DNS
To set the Docker container service names as DNS names on your host edit your `hosts` file. 
A convenient tool to automatically do this is [whales-names](https://github.com/gregolsky/whales-names).


# Known issues
Docker for Windows can be unstable at times, some troubleshooting tips are listed below.

## Containers not reachable by domain name
Sometimes the internal Docker DNS is malfunctioning and containers (e.g. mssql) cannot be reached by domain name. To solve this restart the Docker daemon.

## Clean up network hosting
In case it's no longer possible to create networks and docker network commands don't work give this a try: https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/live/windows-server-container-tools/CleanupContainerHostNetworking

## Clean Docker install
In case nothing else helps, perform a clean Docker install using the following steps:
- Uninstall Docker

- Check that no Windows Containers are running (https://docs.microsoft.com/en-us/powershell/module/hostcomputeservice/get-computeprocess?view=win10-ps):
```
PS> Get-ComputeProcess
```
and if so, stop them using `Stop-ComputeProcess`.

- Remove the `C:\ProgramData\Docker` directory (and Windows Containers) using the [docker-ci-zap](https://github.com/jhowardmsft/docker-ci-zap) tool as administrator in `cmd`:
```
PS> docker-ci-zap.exe -folder "c:\ProgramData\Docker"
```

- Install Docker

## Docker build fails
Docker for Windows build can be flaky from time to time. Error messages like below can be solved by trying harder (i.e. more often) and making sure no other programs (e.g. file explorer) have the applicable directory open. 
```
ERROR: Service 'solr' failed to build: failed to register layer: re-exec error: exit status 1: output: remove \\?\C:\ProgramData\Docker\windowsfilter\6d12d77235757f9e1cdd58216d104f0e51bc56e6021cf206a2dd6d97b0d3520f\UtilityVM\Files\Windows\WinSxS\amd64_microsoft-windows-a..ence-inventory-core_31bf3856ad364e35_10.0.16299.15_none_81bfff856a844456\aepic.dll: Access is denied.
```

## Certificate issues with XConnect
There is an excellent describtion of how XConnect uses certificates here: https://kamsar.net/index.php/2017/10/All-about-xConnect-Security/

An issue we encountered lately was the `Could not create SSL/TLS secure channel.` one (mentioned in above describtion).
To grant permissions in a Docker container you can use [Carbon](http://get-carbon.org/documentation.html), e.g.
```
PS> Get-Permission -Identity sitecore -Path 'cert:\localmachine\my\9CC4483261B92D7C5B32239115283933FC5014C'
```
If none are returned for the `xConnect.client` certificate, you probably need to give permissions to the sitecore user. For example:
```
PS>  Grant-Permission -Identity sitecore -Permission GenericRead -Path 'cert:\localmachine\my\9CC4483261B92D7C5B32239115283933FC5014C4'
```

## Certificates issues with Commerce
Communication between services might fail when the certificates are not installed correctly. Verify what certificates are installed by:
```
PS> Get-ChildItem cert:\localmachine\my
```

The certificate thumbprint in `<Your>.Commerce.Engine/wwwroot/config.json` should match the one in `Y.Commerce.Engine/Sitecore.Commerce.Engine.Connect.config`.
Note that when you have build new images the thumbprint in the `<Your>.Commerce.Engine/wwwroot/config.json` has to be manually updated.

To determine and set the root certificate to use for a HTTPS connection:
1. Determine certificate used for IIS: `PS> Get-WebBinding | Select certificateHash`
2. Determine root certificate used to sign the in step 1 obtained certificate: `PS> Get-ChildItem cert:\localmachine\my\<certificateHash> | Select Issuer`
3. Lookup thumbprint of the issuer: `PS> Get-ChildItem cert:\localmachine\root\
3. Export the root certificate: `PS> Export-Certificate -Cert cert:\localmachine\root\<thumbprint> -FilePath <file>`
4. Import the root certificate (on the client): `PS> Import-Certificate <file> -CertStoreLocation cert:\localmachine\root`

## Commerce setup
- We have quite a lot of custom powershell scripts for trivial installation tasks. This is because the commerce SIF scripts contain hardcoded values. For example, it is not possible to use hostnames other than localhost. We should be able to remove this custom code when those scripts get fixed.
- During the installation of the commerce server instances, it tries to set permissions on the log folder. For some reason, this results in an exception saying the access control list is not in canonical form. This can be ignored, because the log folders are mounted on the host. However, it does cause an annoying delay in the installation. 

## Solr errors in Sitecore log
After a clean start Sitecore reports errors like:
```
ERROR: [doc=sitecore://master/{731cb645-faa3-4440-9511-a27556a63ad9}?lang=fr-fr&amp;ver=1&amp;ndx=sitecore_master_index] unknown field '_indexname_t_fr'
```

Populating the Solr managed schemas will solve this, e.g. do this via the Sitecore Control Panel.
An automated solution is planned in [this](https://github.com/avivasolutionsnl/sitecore-docker/issues/38) issue.
