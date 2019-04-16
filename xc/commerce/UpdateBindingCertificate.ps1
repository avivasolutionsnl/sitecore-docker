#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory = $true)]
    [X509Certificate]$certificate, 
    [Parameter(Mandatory = $true)]
    [string]$bindingName, 
    [Parameter(Mandatory = $true)]
    [uint32]$port
)

Write-Host "Deleting old $bindingName with port $port"
Get-WebBinding -Name $bindingName -Protocol 'https' -Port $port | Remove-WebBinding

Write-Host "Creating new binding $bindingName with port $port"
New-WebBinding -Name $bindingName -HostHeader '*' -IPAddress * -Protocol 'https' -Port $port
$binding = Get-WebBinding -Name $bindingName -Protocol 'https' -Port $port
Write-Host "Succesfully created a new https binding with name $bindingName!" -ForegroundColor Green

Write-Host "Updating the certificate for binding $bindingName with port $port"
$binding.AddSslCertificate($certificate.GetCertHashString(), 'My')
Write-Host "Succesfully updated the binding certificate!" -ForegroundColor Green