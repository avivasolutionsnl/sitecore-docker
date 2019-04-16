Param(
    $folder,
	$hostName
)

$pathToConfigJson = $(Join-Path -Path $folder -ChildPath wwwroot\config.json);
$content = Get-Content $pathToConfigJson -raw
Write-Host $content
$json = Get-Content $pathToConfigJson -raw | ConvertFrom-Json; 

$sitecoreIdentityServerUrl = 'http://{0}:5050' -f $hostName; 
$json.AppSettings.SitecoreIdentityServerUrl = $sitecoreIdentityServerUrl; 
$json = ConvertTo-Json $json -Depth 100; 
Set-Content $pathToConfigJson -Value $json -Encoding UTF8;