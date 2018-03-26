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
if($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
{
	$setup = "$lode\packages\setup-x86_64.exe"
	$url = "https://cygwin.com/setup-x86_64.exe"
}
elseif($env:PROCESSOR_ARCHITECTURE -eq "x86")
{
	$setup = "$lode\packages\setup-x86.exe"
	$url = "https://cygwin.com/setup-x86.exe"
}
else
{
	throw "No idea what architecture I'm running on"
}

if(!(Test-Path -Path $setup ))
{
	$webclient = New-Object System.Net.WebClient
	$webclient.DownloadFile($url,$setup)
}

start $setup  "-B -n -N -q -d -D -L -X -s $site -l $temp -R $root" -Wait

$packages = @"
 -P autoconf,automake,bison,cabextract,doxygen,flex
 -P gettext-devel,git,gnupg,gperf,libxml2-devel
 -P libpng12-devel,make,mintty,openssh,openssl,patch,perl
 -P pkg-config,readline,rsync,unzip,emacs,wget,zip
 -P perl-Archive-Zip,perl-Font-TTF,python,python3
"@

start $setup  "-B -N -n -q -d -D -L -X -s $site -l $temp -R $root $packages" -Wait

start "$root/Cygwin.bat"
