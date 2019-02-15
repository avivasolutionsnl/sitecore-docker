
Param(
    [Parameter(Mandatory=$True)]
    $certpath,
    $secret = "secret",
    [Parameter(Mandatory=$True)]
    $sitename,
    [Parameter(Mandatory=$True)]
    $hostname
)

$password = ConvertTo-SecureString -String $secret -Force -AsPlainText;
$PFXCert = Get-PfxData -FilePath $certpath -Password $password;
New-WebBinding -Name $sitename -IPAddress * -Port 443 -Protocol "https" -HostHeader $hostname;
$binding = Get-WebBinding -Name $sitename -Protocol "https";
$binding.AddSslCertificate($PFXCert.EndEntityCertificates.ThumbPrint, 'my')