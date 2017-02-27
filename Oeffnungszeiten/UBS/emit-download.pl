#!/usr/bin/perl
use warnings;
use strict;
use StandorteJson;

#q use JSON;


#q open (my $json_h, '<:encoding(utf-8)', "$ENV{digitales_backup}/crawler/Oeffnungszeiten/UBS/standorte.json") or die;
#q my $json_text = <$json_h>;
#q close $json_h;

open (my $d, '>', 'download.sh');
print $d "echo \\\n";

#q my $json = from_json($json_text);

# printf "totalResults %d\n", $json->{totalResults};

# my %hits_outer = %{$json->{hits}};

for my $hit_inner (StandorteJson::elems()) {

  die scalar @{$hit_inner->{id}} unless scalar @{$hit_inner->{id}} == 1;

# my $id = $hit_inner->{fields}{id}[0];
  my $id = $hit_inner->{id}[0];

  next unless substr($id, 4, 2) eq 'ch';
  my $url = StandorteJson::id2file($id);



# printf "%-60s |\n", $id;

  print $d "     https://www.ubs.com/standorte/_jcr_content.location.$url -O $ENV{digitales_backup}crawler/Oeffnungszeiten/UBS/wgetted/$url \\\n";


}



print $d "| xargs -n 3 -P 12 wget -q\n";
close $d;

system "chmod 755 download.sh";
