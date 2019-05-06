# As mkdir does not give an error exit code when it fails, 
# suppress all warnings as it clutters the build output
mkdir -p .\logs\sitecore 2> $null
mkdir -p .\logs\xconnect 2> $null
mkdir -p .\logs\identity 2> $null
mkdir -p .\logs\commerce\CommerceAuthoring_Sc9 2> $null 
mkdir -p .\logs\commerce\CommerceMinions_Sc9 2> $null
mkdir -p .\logs\commerce\CommerceOps_Sc9 2> $null
mkdir -p .\logs\commerce\CommerceShops_Sc9 2> $null
mkdir -p .\logs\commerce\SitecoreIdentityServer 2> $null
mkdir -p .\data\mssql 2> $null
mkdir -p .\data\solr 2> $null
mkdir -p .\wwwroot\sitecore 2> $null
mkdir -p .\wwwroot\commerce 2> $null