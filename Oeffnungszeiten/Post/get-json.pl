#!/usr/bin/perl
use warnings;
use strict;

use LWP::Simple;

my $url = 
  'https://places.post.ch/StandortSuche/StaoCacheService/Find' .
  '?jsonp=cb20' .
  '&query=T3%2CT9%2CT1%2CT8' .
  '&clusterdist=6' .
  '&lang=de'       .
  '&extent=3.522061631083488%2C' .
         '44.70572129563324%2C'  .
         '12.926358506083488%2C' .
         '48.84119027694612' .
  '&autoexpand=false' .
  '&maxpois=5000' .           # Needed to change this!
  '&agglevel=0' .
  '&encoding=UTF-8' .
  '&_=1488185484026'          # session id?
;

getstore($url, "$ENV{digitales_backup}/crawler/Oeffnungszeiten/Post/places.json") or die;

print "\n\n   TODO: rm cb20( .. ) in $ENV{digitales_backup}/crawler/Oeffnungszeiten/Post/places.json\n\n";
