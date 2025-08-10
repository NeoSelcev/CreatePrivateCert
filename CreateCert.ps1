# Create and export a self-signed certificate
#########################################################################################################################################
function print([String] $message) {
    Write-Host $message -ForegroundColor Re 
}
function printExecution([String] $message) {
    Write-Host "### " -ForegroundColor White -NoNewline
    Write-Host $message -ForegroundColor Green
}
function printResult([String] $message) {
    Write-Host "    -> " -ForegroundColor White -NoNewline
    Write-Host $message -ForegroundColor Yellow
}
function requestPressKeyToFinish {
    Write-Host "Press enter to exit" -ForegroundColor Magenta -NoNewline
    read-host
    ii $WorkingFolder
    stop-process -Id $PID
}
#########################################################################################################################################
print ("Start")
#########################################################################################################################################
printExecution("Setting certificate properties")
$CertificateName = "Firebase HTTP1.1"
$IssuedFor = "Firebase cloud messaging"
$IssuerCompany = "MAX"
$FriendlyName = "firebaseCertificate"
$Password = 123456
$YearsToExpire = 40
printResult ("defined: CertificateName [$CertificateName], IssuedFor [$IssuedFor], IssuerCompany [$IssuerCompany], FriendlyName [$FriendlyName], Password [$Password], YearsToExpire [$YearsToExpire]")
#########################################################################################################################################
printExecution("Set working folder")
$CurrentDateTime = Get-Date -Format "yyyy.MM.dd_HH-mm-ss"
$DesktopFolder = [System.Environment]::GetFolderPath('Desktop')
$WorkingFolder = New-Item -Path "$DesktopFolder\Certificates" -Name "$CertificateName-$CurrentDateTime" -ItemType "directory"
printResult ("[$WorkingFolder]")
#########################################################################################################################################
#########################################################################################################################################
#########################################################################################################################################
printExecution("Create PFX certificate")
$Certificate = New-SelfSignedCertificate -Type Custom -Subject "CN=$IssuedFor, OU=$IssuedFor, O=$IssuerCompany, C=US" -certstorelocation Cert:\LocalMachine\My -dnsname $CertificateName -TextExtension @("2.5.29.19={text}false") -KeyUsage DigitalSignature -KeyLength 2048 -NotAfter (Get-Date).AddYears($YearsToExpire) -FriendlyName $FriendlyName -KeySpec KeyExchange
$CertificateSubject = $Certificate.Subject
$CertificateThumbprint = $Certificate.Thumbprint
printResult ("created: Subject [$CertificateSubject], Thumbprint [$CertificateThumbprint]")
#########################################################################################################################################
printExecution("Export PFX certificate")
$ExportPassword = ConvertTo-SecureString -String $Password -Force -AsPlainText
Export-PfxCertificate -cert Cert:\LocalMachine\My\$CertificateThumbprint -FilePath $WorkingFolder\$CertificateName.pfx -Password $ExportPassword
$PfxCertificateLocation = "$WorkingFolder\$CertificateName.pfx"
printResult ("exported [$WorkingFolder\$CertificateName.pfx]")
#########################################################################################################################################
printExecution("Remove certificate from the store")
Get-ChildItem Cert:\LocalMachine\My\$CertificateThumbprint | Remove-Item
printResult ("removed")
#########################################################################################################################################
printExecution("Save certificate install password")
$NewFile = New-Item -Path $WorkingFolder -Name "install password.txt" -ItemType "file"
Set-Content $NewFile $Password
printResult ("saved [$WorkingFolder\install password.txt]")
#########################################################################################################################################
printExecution("Save private key")
openssl pkcs12 -in $PfxCertificateLocation -nocerts -nodes -out "$WorkingFolder\private.key" -password pass:$Password
printResult ("saved [$WorkingFolder\private.key]")
#########################################################################################################################################
printExecution("Save rsa private key")
openssl rsa -in "$WorkingFolder\private.key" -out "$WorkingFolder\rsa private.key"
printResult ("saved [$WorkingFolder\rsa private.key]")
#########################################################################################################################################
printExecution("Save rsa public key")
openssl rsa -in "$WorkingFolder\private.key" -pubout -out "$WorkingFolder\rsa public.key"
printResult ("saved [$WorkingFolder\rsa public.key]")
#########################################################################################################################################
printExecution("Save certificate")
openssl pkcs12 -in $PfxCertificateLocation -nokeys -out "$WorkingFolder\$CertificateName.pem" -nodes -password pass:$Password
printResult ("saved [$WorkingFolder\$CertificateName.pem]")
#########################################################################################################################################
printExecution("Convert pfx certificate to crt")
openssl pkcs12 -in $PfxCertificateLocation -clcerts -nokeys -out "$WorkingFolder\$CertificateName.crt" -password pass:$Password -passin pass:$Password -passout pass:$Password
printResult ("converted [$WorkingFolder\pfx_key public.crt]")
#########################################################################################################################################
print("End")
#########################################################################################################################################
requestPressKeyToFinish 

