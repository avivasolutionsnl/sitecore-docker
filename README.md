Run Sitecore using Docker and Windows containers.

# Requirements
- Docker for Windows: https://docs.docker.com/docker-for-windows/
- Hyper-V enabled
- Sitecore installation files

# Build
As Sitecore does not distribute Docker images, the first step is to build the required Sitecore Docker images.
For this you need the Sitecore installation files and a Sitecore license file. Download the Sitecore 9 packages for
XP Single and unzip the file in the `files` folder in this repository. 

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

# Run
Docker compose is used to start up all required services.

To start Sitecore:
```
$ docker-compose up
```

## DNS
The containers have fixed IP addresses in the docker compose file. The easiest way to access the containers from the host is by adding the following to your hosts file:

``` Hosts
172.16.238.10	solr
172.16.238.12	xconnect
172.16.238.13	sitecore
172.16.238.11	mssql
```

## Log files
Logging is set up to log on the host under the logs folder of this repository. 

## Known issues
- Installation files are not removed
- Size of images is not optimized (Multiple RUN statements)
- Docker best practices?