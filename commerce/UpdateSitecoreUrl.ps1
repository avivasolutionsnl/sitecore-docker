Param(
    $folder,
	$hostName
)

$pathToConfigJson = $(Join-Path -Path $folder -ChildPath wwwroot\data\Environments\PlugIn.Content.PolicySet-1.0.0.json);
$json = Get-Content $pathToConfigJson -raw | ConvertFrom-Json; 

foreach ($p in $json.Policies.'$values') {
    if ($p.'$type' -eq 'Sitecore.Commerce.Plugin.Management.SitecoreConnectionPolicy, Sitecore.Commerce.Plugin.Management') {
        $p.Host = $hostName
    }
}

$json = ConvertTo-Json $json -Depth 100
Set-Content $pathToConfigJson -Value $json -Encoding UTF8