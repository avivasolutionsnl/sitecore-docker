
Param(
    [Parameter(Mandatory=$True)]
    $certpath,
    $secret = "secret",
    [Parameter(Mandatory=$True)]
    $sitename,
    [Parameter(Mandatory=$True)]
    $hostname,
    $port = "443",
    $protocol = "https"

)

$password = ConvertTo-SecureString -String $secret -Force -AsPlainText;
$PFXCert = Get-PfxData -FilePath $certpath -Password $password;
New-WebBinding -Name $sitename -IPAddress * -Port $port -Protocol $protocol -HostHeader $hostname;
$binding = Get-WebBinding -Name $sitename -Protocol $protocol;
$binding.AddSslCertificate($PFXCert.EndEntityCertificates.ThumbPrint, 'my')