Run Sitecore 9 (with XConnect) using Docker and Windows containers.

# Requirements
- Windows 10 update 1709 (with Hyper-V enabled)
- Docker for Windows (version 1712 or better): https://docs.docker.com/docker-for-windows/
- Visual Studio 15.5.3
- Sitecore installation files

# Build
As Sitecore does not distribute Docker images, the first step is to build the required Docker images.
For this you need the Sitecore installation files and a Sitecore license file. What files to use are set by environment variables (interpreted by docker-compose); download all the packages that are defined by variables in the `.env.` file.

The xp0 Sitecore topology requires SSL between the services, for this we need self signed certificates for the 
xConnect and SOLR roles. You can generate these by running the './Generate-Certificates.ps1' script. 

Next, modify the .env file and change the build parameters if needed:

| Field                     | Description                                      |
| ------------------------- | ------------------------------------------------ |
| SQL_SA_PASSWORD           | The password to use for the SQL sa user          |
| SQL_DB_PREFIX             | Prefix to use for all DB names                   |
| SOLR_HOST_NAME            | Host name to use for the SOLR instance           |
| SOLR_PORT                 | Port to use for the SOLR instance                |
| SOLR_SERVICE_NAME         | Name of the SOLR Windows service                 |
| XCONNECT_SITE_NAME        | Host name of the Xconnect site                   |
| XCONNECT_SOLR_CORE_PREFIX | Prefix to use for the XConnect SOLR cores        |
| SITECORE_SITE_NAME        | Host name of the Sitecore site                   |
| SITECORE_SOLR_CORE_PREFIX | Prefix to use for the Sitecore SOLR cores        |

The build results in the following Docker images:
- sitecore: IIS + ASP.NET + Sitecore
- mssql: MS SQL + Sitecore databases
- solr: Apache Solr 
- xconnect: IIS + ASP.NET + XConnect

As final step build all Solr indexes (populate and re-build indexes), and perform a Docker commit for the Solr image to persist the changes.

# Run
Docker compose is used to start up all required services.

Place the Sitecore source files in the `.\wwwroot\sitecore` directory.

Create the log directories which are mounted in the Docker compose file:
```
$ mkdir -p .\logs\sitecore
$ mkdir -p .\logs\xconnect
```

Create a webroot directory:
```
PS> mkdir -p wwwroot/sitecore
```

To start Sitecore:
```
$ docker-compose up
```

## DNS
The containers have fixed IP addresses in the docker compose file. The easiest way to access the containers from the host is by adding the following to your hosts file:

``` Hosts
172.16.238.10	solr
172.16.238.11	mssql
172.16.238.12	xconnect
172.16.238.13	sitecore
```

## Log files
Logging is set up to log on the host under the logs folder of this repository. 

## Known issues
Docker for Windows can to be unstable at times. Some common troubleshooting items are listed here.

### Clean up network hosting
In case it's no longer possible to create networks and docker network commands don't work give this a try: https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/live/windows-server-container-tools/CleanupContainerHostNetworking

### Clean Docker install
In case nothing else helps, perform a clean Docker install using the following steps:
- Uninstall Docker

- Check that no Windows Containers are running (https://docs.microsoft.com/en-us/powershell/module/hostcomputeservice/get-computeprocess?view=win10-ps):
```
$ Get-ComputeProcess
```
and if so, stop them using `Stop-ComputeProcess`.

- Remove the `C:\ProgramData\Docker` directory (and Windows Containers) using the [docker-ci-zap](https://github.com/jhowardmsft/docker-ci-zap) tool as administrator in `cmd`:
```
$ docker-ci-zap.exe -folder "c:\ProgramData\Docker"
```

- Install Docker
