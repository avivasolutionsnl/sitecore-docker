Param(
    $certificateFile = "",
    $secret = "",
    $storeName = "Root",
    $storeLocation = "LocalMachine"
)

# $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2; `
# $cert.Import($certificateFile,'secret','DefaultKeySet'); `
# $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $storeName, $storeLocation; `
# $store.Open('ReadWrite'); `
# $store.Add($cert); `
# $store.Close()

$pwd = ConvertTo-SecureString -String $secret -Force -AsPlainText; `
Import-PfxCertificate -FilePath $certificateFile -CertStoreLocation Cert:\$storeLocation\$storeName -Password $pwd
