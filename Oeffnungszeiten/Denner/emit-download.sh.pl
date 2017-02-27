#!/usr/bin/perl
use warnings;
use strict;


open (my $d, '>', 'download.sh');

print $d "echo \\\n";
for my $i (100 .. 864) {

  print $d "     https://www.denner.ch/de/filialen/storecontroller/Stores/storeaction/detail/storeUid/$i/ -O $ENV{digitales_backup}crawler/Oeffnungszeiten/Denner/wgetted/$i.html \\\n";
}
print $d "| xargs -n 3 -P 12 wget -q\n";
close $d;
