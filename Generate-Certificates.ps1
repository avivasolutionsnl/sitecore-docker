.\Generate-Self-Signed-Certificate.ps1 -dnsName 'xConnect.client' -file '.\Files\xConnect.pfx' -secret 'secret'
.\Generate-Self-Signed-Certificate.ps1 -dnsName 'solr' -file '.\Files\solr.pfx' -secret 'secret'
.\Generate-Self-Signed-Certificate.ps1 -dnsName 'sitecore' -file '.\Files\sitecore.pfx' -secret 'secret'
.\Generate-Self-Signed-Certificate.ps1 -dnsName 'commerce.client' -file '.\Files\commerce.pfx' -secret 'secret'
.\Generate-Self-Signed-Certificate.ps1 -dnsName 'identity' -file '.\Files\identity.pfx'

$cert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname 'DO_NOT_TRUST_SitecoreRootCert' -KeyUsage DigitalSignature,CertSign -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider';
$pwd = ConvertTo-SecureString -String 'secret' -Force -AsPlainText;
Export-PfxCertificate -cert $cert -FilePath '.\Files\root.pfx' -Password $pwd;
