Run Sitecore using Docker and Windows containers.

# Requirements
- Docker for Windows: https://docs.docker.com/docker-for-windows/
- Hyper-V enabled

# Build
As Sitecore does not distribute Docker images, the first step is to build the required Sitecore Docker images.
For this you need a Sitecore zip file and a Sitecore license file.

To build:
```
$ ./Build.ps1 Sitecore.zip license.xml
```

The build results in having two Docker images:
- sitecore: IIS + ASP.NET + Sitecore
- mssql-sitecore: MS SQL + Sitecore databases

Optionally, verify that by running:
```
$ docker images
```

# Run
Docker compose is used to start up all required services.

To start Sitecore:
```
$ docker-compose up
```

## Port mapping
Windows Containers use WinNAT for networking. Currently WinNAT does not support (https://blogs.technet.microsoft.com/virtualization/2016/05/25/windows-nat-winnat-capabilities-and-limitations/) accessing external endpoints running on the same host.
To overcome this limitation a workaround is to use the internal IP address of the container. Look up the internal IP of a container using `docker inspect`, e.g:
```
$ docker inspect -f '{{ .NetworkSettings.IPAddress }}' docker_sitecore_1
```
### Traefik
[Traefik](https://traefik.io/) enables you to access a container (that exposes port 80) by using its name and (by docker-compose) given prefix. Download the Traefik executable [here](https://github.com/containous/traefik/releases) (choose traefik_windows-amd64 for Windows).

To run Traefik:
```
$ traefik_windows-amd64 --configFile=traefik/traefik.toml
```
> The provided configuration uses port 80 and 8080, so make sure that no other service (e.g. IIS) are using these ports. 

To view the Traefik admin panel go to: `http://localhost:8080`

For Sitecore go to: `http://sitecore.docker.localhost`.
This follows the pattern `http://<container name>.<prefix>.localhost`. Docker compose uses by default the working directory as prefix.

