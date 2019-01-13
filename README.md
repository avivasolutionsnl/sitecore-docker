Run Sitecore 9 (with XConnect) using Docker and Windows containers.

# Disclaimer
This repository contains experimental code that we use in development setups. We do not consider the current code in this repository ready for production.
Hopefully this will help you to get up and running with Sitecore and Docker. By no means we consider ourselves Docker experts and thus expect these images to still contain a lot of bugs. Great help for creating this setup was provided by the [sitecoreops](https://github.com/sitecoreops/sitecore-images) and [sitecore-nine-docker](https://github.com/pbering/sitecore-nine-docker) repos. Please feel free to provide feedback by creating an issue, PR, etc. 


# Requirements
- Windows 10 update 1709 (with Hyper-V enabled)
- Docker for Windows (version 1712 or better): https://docs.docker.com/docker-for-windows/
- Visual Studio 15.5.3
- Sitecore installation files
- [Nuke.build](https://nuke.build)


# Build
As Sitecore does not distribute Docker images, the first step is to build the required Docker images.

## Pre-build steps
For this you need the Sitecore installation files and a Sitecore license file. 
What files to use are set in the [build configuration](./build/Build.cs).

The xp0 Sitecore topology requires SSL between the services, for this we need self signed certificates for the 
xConnect and SOLR roles. You can generate these by running the `./Generate-Certificates.ps1` script (note that this requires an Administrator elevated powershell environment and you may need to set the correct execution policy, e.g. `PS> powershell.exe -ExecutionPolicy Unrestricted`).

## Build
Build all images using:
```
PS> nuke 
```

The build results in the following Docker images:
- sitecore: IIS + ASP.NET + Sitecore
- mssql: MS SQL + Sitecore databases
- solr: Apache Solr 
- xconnect: IIS + ASP.NET + XConnect

and two SXA images:
- sitecore-sxa
- mssql-sxa

### Push images
Push the Docker images to your repository, e.g:
```
PS> nuke push
```


# Run
Docker compose is used to start up all required services.

Place the Sitecore source files in the `.\wwwroot\sitecore` directory.

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


## DNS
To set the Docker container service names as DNS names on your host edit your `hosts` file. 
A convenient tool to automatically do this is [whales-names](https://github.com/gregolsky/whales-names).

## (Optionally) Obtain Solr cores
Stop the `solr` container and copy the cores to your the `cores` directory:
```
PS> ./CopyCores.ps1
```

## (Optionally) Obtain database files from images
Stop the `mssql` container and copy the databases to the `databases` directory:
```
PS> ./CopyDatabases.ps1
```


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
