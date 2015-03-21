#!/usr/bin/env perl
# -*- tab-width : 4; indent-tabs-mode : nil -*-

use warnings;
use strict;
use IO::Socket;
use threads;
use threads::shared;
use Cwd 'abs_path';
use POSIX ;

my $client;
my $pid;

if ( "$ENV{LODE_HOME}" eq "")
{
    die "LODE_HOME not set";
}
$SIG{PIPE} = 'IGNORE';
$SIG{ALRM} = sub { system("TASKKILL /F /T /PID $pid");
                   print $client "\n######TIMED-OUT######\n";
                   die "timeout\n";
};

my $server = new IO::Socket::INET (
    LocalHost => 'localhost',
    LocalPort => '2628',
    Proto => 'tcp',
    Listen => 1,
    Reuse => 1,
    );
die "Could not create socket: $!\n" unless $server;

for(;;)
{
    do
    {
        print "accepting\n";
        $client = $server->accept;
    }
    until ( defined($client) );
    processit($client);
}

sub processit
{
    my ($lclient) = @_; #local client
    if($lclient->connected)
    {
        my $wd = <$lclient>;
        my $cmd = <$lclient>;
        print "prcoess it\n";
        if( defined($wd) && defined($cmd))
        {
            chomp $wd;
            ($wd) = split(' ', $wd);
            $wd = abs_path($wd);
            if ($wd =~ /^$ENV{LODE_HOME}/ )
            {
                print $lclient "working dir is :". $wd. "\n";
                if(chdir $wd)
                {
                    chomp $cmd;
                    if( "$cmd" eq "make" )
                    {
                        $pid = open(RESULT, "-|");
                        if($pid)
                        {
                            print "forked pid $pid \n";
                            alarm 10800; # 3 hours max
                            while(<RESULT>)
                            {
                                if( ! print $lclient "$_")
                                {
                                    print "client bailed\n";
                                    system("TASKKILL /F /T /PID $pid");
                                    last;
                                }
                            }
                            alarm 0;
                        }
                        else
                        {
                            open STDERR, ">&STDOUT";
                            exec "make", "-f", "C:/cygwin/$ENV{LODE_HOME}/bin/cygwrapper.Makefile" || die "can't exec";
                        }
                        print "CLose RESULT"."\n";
                        close RESULT;
                    }
                    elsif( "$cmd" eq "test")
                    {
                        print $lclient "Test OK\n";
                        print $lclient '#######SUCCESS#######'."\n";
                    }
                    else
                    {
                        print "bad command\n";
                        print $lclient "bad command :". $cmd . "\n";
                    }
                }
                else
                {
                    print "can't chdir to : ".$wd."\n";
                    print $lclient "can't chdir to : ".$wd."\n";
                }
            }
            else
            {
                print "bad working dir : ".$wd."\n";
                print $lclient "bad working dir : ".$wd."\n";
            }
        }
    }
    close( $lclient);
}
