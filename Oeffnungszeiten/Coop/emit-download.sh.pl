#!/usr/bin/perl
use warnings;
use strict;

open (my $d, '>', 'download.sh');

print $d "echo \\\n";
for my $i (1000 .. 5000) {

  print $d "     http://www.coop.ch/de/services/standorte-und-oeffnungszeiten/detail.html?id=$i -O $ENV{digitales_backup}crawler/Oeffnungszeiten/Coop/wgetted/$i.html \\\n";
}
print $d "| xargs -n 3 -P 12 wget -q\n";
close $d;
