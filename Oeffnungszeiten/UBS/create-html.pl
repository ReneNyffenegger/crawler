#!/usr/bin/perl

use StandorteJson;

use lib '..';
use Oeffnungszeiten;

use JSON;

use utf8;
use warnings;
use strict;

my %datafile2jsonelem;

for my $jsonelem (StandorteJson::elems()) { #_{  create index for json elems, indexed by $id
  my $id = $jsonelem->{id}[0];

  my $file = StandorteJson::id2file($id);

# print "$id - $file\n";

  $datafile2jsonelem{$file} = $jsonelem;

} #_}

Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/UBS/wgetted/*.data", 'UBS', \&parse_file);


sub parse_file {
  my $filename = shift;
  print "P: $filename\n";
 
 (my $file_last_part = $filename) =~ s|.*/||;

  open (my $json_h, '<:encoding(utf-8)', "$ENV{digitales_backup}/crawler/Oeffnungszeiten/UBS/wgetted/$file_last_part") or die;
  my $json_text = <$json_h>;
  close $json_h;

  my $json = from_json($json_text);

  print $json -> {telephoneNumber}, "\n";

  
  my $json_elem = $datafile2jsonelem{$file_last_part};

  my $address = $json_elem->{bu_podAddress}[0];
  die unless $address =~ m|(.*), (\d\d\d\d) (.*)|;
  $Oeffnungszeiten::strasse = $1;
  $Oeffnungszeiten::plz = $2;
  $Oeffnungszeiten::ort = $3;

  $Oeffnungszeiten::title = $json_elem->{title}[0] . " $Oeffnungszeiten::ort";

  $Oeffnungszeiten::telephone = $json->{telephoneNumber};
  $Oeffnungszeiten::telephone =~ s/-/ /g;
  $Oeffnungszeiten::telephone =~ s/ *\+41 *//;
  $Oeffnungszeiten::telephone =~ s/^(\d\d) /0$1 /;

  for my $ophours (@{$json->{busOpenHrs}{businessOpeningHours}[0]{weekOpeningHours}}) {

    my $state = $ophours -> {state};

    for my $day (qw(Mo Tu We Th Fr Sa Su)) {

      if ($day eq $ophours->{day}) {

        if ($state eq "LUNCH_BREAK") {
          $Oeffnungszeiten::zeiten{$day} = "$ophours->{collapsedHrs}[0]-$ophours->{collapsedHrs}[1] / $ophours->{collapsedHrs}[2]-$ophours->{collapsedHrs}[3]";
        }
        elsif ($state eq "MORNING_CLOSED") {
          $Oeffnungszeiten::zeiten{$day} = "$ophours->{collapsedHrs}[2]-$ophours->{collapsedHrs}[3]";
        }
        elsif ($state eq "NO_LUNCH") {
          $Oeffnungszeiten::zeiten{$day} = "$ophours->{collapsedHrs}[0]-$ophours->{collapsedHrs}[1]";
        }
        elsif ($state eq "AFTERNOON_CLOSED") {
          $Oeffnungszeiten::zeiten{$day} = "$ophours->{collapsedHrs}[0]-$ophours->{collapsedHrs}[1]";
        }
        elsif ($state eq "CLOSED") {
          $Oeffnungszeiten::zeiten{$day} = "geschlossen";
#         die $filename;
        }
        elsif ($state eq "TWENTFOUR_OPEN") {
          # Bankomat?
          $Oeffnungszeiten::title = '';
        }
        else {
           die "state: $state";
        }

      }
    }

  }

}
