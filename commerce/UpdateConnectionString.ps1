Param(
    $folder,
	$userName,
    $password,
    $server
)

$pathToGlobalJson  = $(Join-Path -Path $folder -ChildPath "wwwroot\bootstrap\Global.json")
$json = Get-Content $pathToGlobalJson -raw | ConvertFrom-Json; 

foreach ($p in $json.Policies.'$values') {
    if ($p.'$type' -eq 'Sitecore.Commerce.Plugin.SQL.EntityStoreSqlPolicy, Sitecore.Commerce.Plugin.SQL') {
        $p.Server = $server
        $p.UserName = $userName
        $p.Password = $password
        $p.TrustedConnection = $false
    }
}

$json = ConvertTo-Json $json -Depth 100
Set-Content $pathToGlobalJson -Value $json -Encoding UTF8

$pathToEnvironmentFiles = $(Join-Path -Path $folder -ChildPath "wwwroot\data\Environments")
$environmentFiles = Get-ChildItem $pathToEnvironmentFiles -Filter *.json

foreach ($jsonFile in $environmentFiles) {
    $json = Get-Content $jsonFile.FullName -Raw | ConvertFrom-Json
    $updated = $false
    
    foreach ($p in $json.Policies.'$values') {
        if ($p.'$type' -eq 'Sitecore.Commerce.Plugin.SQL.EntityStoreSqlPolicy, Sitecore.Commerce.Plugin.SQL') {
            $p.Server = $server
            $p.UserName = $userName
            $p.Password = $password
            $p.TrustedConnection = $false

            $updated = $true
        }
    }

    if($updated -eq $true) {
        $json = ConvertTo-Json $json -Depth 100

        Set-Content $jsonFile.FullName -Value $json -Encoding UTF8
    }
}