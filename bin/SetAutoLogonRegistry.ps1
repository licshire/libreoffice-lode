

$user = Read-Host 'What is the tdf user (default tdf)'
if( $user = '' )
{
	$user = 'tdf'
}

$password = Read-Host 'What is the password?'

Push-Location
Set-Location HKLM\Software\Microsoft\Windows NT\CurrentVersion\winlogon
if(Get-ItemProperty -PATH . -Name AutoAdminLogon -ea 0).AutoAdminLogon)
{
	'AutoAdminLogon already exist'
}
else
{
	Set-ItemProperty -PATH . -Name AutoAdminLogon -Value '1'
}

if(Get-ItemProperty -PATH . -Name DefaultUsername -ea 0).DefaultUsername = "$user")
{
	'AutoAdminLogon already exist and correct'
}
else
{
	Set-ItemProperty -PATH . -Name DefaultUsername -Value "$user"
}

if(Get-ItemProperty -PATH . -Name DefaultUsername -ea 0).DefaultUsername = $password)
{
	'AutoAdminLogon already exist and correct'
}
else
{
	Set-ItemProperty -PATH . -Name DefaultUsername -Value "$password"
}

Pop-Location
