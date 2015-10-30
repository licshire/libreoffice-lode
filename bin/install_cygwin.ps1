#
# Bootstrap lode by installing cygwin
#
#    Copyright (C) 2014 Norbert Thiebaud
#    License: GPLv3
#


$lode = $pwd
$temp = "$lode\packages\temp"
$root = "C:\cygwin"
$site = "http://mirrors.kernel.org/sourceware/cygwin/"
if(!(Test-Path -Path $lode\packages ))
{
	New-Item -ItemType directory -Path $lode\packages
}
if(!(Test-Path -Path $lode\packages\temp ))
{
	New-Item -ItemType directory -Path $lode\packages\temp
}

# the external nss module does not play well with cygwin 64
if([environment]::Is64BitOperatingSystem)
{
	$setup = "$lode\packages\setup-x86_64.exe"
	$url = "https://cygwin.com/setup-x86_64.exe"
}
else
{
	$setup = "$lode\packages\setup-x86.exe"
	$url = "https://cygwin.com/setup-x86.exe"
}

if(!(Test-Path -Path $setup ))
{
	$webclient = New-Object System.Net.WebClient
	$webclient.DownloadFile($url,$setup)
}

start $setup  "-B -n -N -q -d -D -L -X -s $site -l $temp -R $root" -Wait

$packages = @"
 -P autoconf,automake,bison,cabextract,doxygen,flex,gcc-g++
 -P git,gnupg,gperf,libxml2-devel,libpng12-devel,make,mintty
 -P openssh,openssl,patch,perl,pkg-config
 -P readline,rsync,unzip,emacs,wget,zip,perl-Archive-Zip
 -P python,python3
"@

start $setup  "-B -N -n -q -d -D -L -X -s $site -l $temp -R $root $packages" -Wait

start "$root/Cygwin.bat"
