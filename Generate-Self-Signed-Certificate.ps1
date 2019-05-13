Param(
    $dnsName = "",
    $file = "",
    $secret = "secret",
    $signer
)

$cert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $dnsName -Signer $signer -KeyExportPolicy Exportable -Provider "Microsoft Strong Cryptographic Provider" `
-HashAlgorithm "SHA256"

$pwd = ConvertTo-SecureString -String $secret -Force -AsPlainText

Export-PfxCertificate -cert $cert -FilePath $file -Password $pwd