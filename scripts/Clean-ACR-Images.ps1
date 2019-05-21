param(
    [Parameter(Mandatory=$true)]
    [string]$registryName,
    [Parameter(Mandatory=$true)]
    [string]$repositoryName,
    [Parameter(Mandatory=$true)]
    [string]$gitHubRepositoryName
)

$presentTagsInACR = az acr repository show-tags -n $registryName --repository $repositoryName | ConvertFrom-Json;
Write-Host "Tags currently present in ACR"
Write-Host ($presentTagsInACR -join "`n")
Write-Host

$timestampsFromGitHub = (Invoke-RestMethod -Uri "https://api.github.com/repos/$gitHubRepositoryName/releases") | Select -ExpandProperty tag_name  | %{ $_.Split('-')[-1] };
Write-Host "Timestamps currently present as release in GitHub"
Write-Host ($timestampsFromGitHub -join "`n")
Write-Host

$tagsToBeDeletedFromACR = $presentTagsInACR | Where{ $_.Split('-')[-1] -notin $timestampsFromGitHub }

foreach($tag in $tagsToBeDeletedFromACR)
{
    Write-Host "Deleting $tag"
    az acr repository delete -n $registryName --image ${repositoryName}:${tag} --yes
}
