#!/usr/bin/perl
use warnings;
use strict;

use JSON;


open (my $json_h, '<:encoding(utf-8)', "$ENV{digitales_backup}/crawler/Oeffnungszeiten/Post/places.json") or die;
my $json_text = <$json_h>;
close $json_h;

open (my $d, '>', 'download.sh');
print $d "echo \\\n";

my $json = from_json($json_text);

printf "Count: %d\n", $json->{count};

my @pois_outer = @{$json->{pois}};

for my $poi_outer (@pois_outer) {

# printf "%10.7f %10.7f\n", $poi_outer->{x}, $poi_outer->{y};

  my @pois_inner = @{$poi_outer->{pois}};

  for my $poi_inner (@pois_inner) {



#   printf "  %-20s %2s  %10.7f %10.7f  %-70s %-30s %4s %-30s %-30s\n",
#     $poi_inner->{id},
#     $poi_inner->{type},
#     $poi_inner->{x},
#     $poi_inner->{y},
#     $poi_inner->{name},
#     $poi_inner->{info}->{Street}       // 'n/a',
#     $poi_inner->{info}->{Zip},
#     $poi_inner->{info}->{City},
#     $poi_inner->{info}->{PickpostCity} // 'n/a';

    if (# $poi_inner->{type} eq 'T1' or #  PickPost-Stelle
          $poi_inner->{type} eq 'T3'    #  Postagentur od. Poststelle
       ) {
        print $d "     'https://places.post.ch/Public/PoiDetail/LongDetailPagePartial?poiId=$poi_inner->{id}&lang=de' -O $ENV{digitales_backup}crawler/Oeffnungszeiten/Post/wgetted/$poi_inner->{id}.html \\\n";
    }

  }

}



print $d "| xargs -n 3 -P 12 wget -q\n";
close $d;

system "chmod 755 download.sh";
