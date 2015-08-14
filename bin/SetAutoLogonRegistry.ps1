

$user = Read-Host 'What is the tdf user (default tdf)'
if( $user = '' )
{
	$user = 'tdf'
}

$password = Read-Host 'What is the password?'

$RegPath = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\winlogon"
Set-ItemProperty $RegPAth "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty $RegPAth "DefaultUsername" -Value "$user" -type String
Set-ItemProperty $RegPAth "DefaultPassword" -Value "$password" -type String

