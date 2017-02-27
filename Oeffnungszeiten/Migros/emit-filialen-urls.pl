#!/usr/bin/perl
use warnings;
use strict;

use LWP::Simple;
use XML::Parser;

my $fil_xml_name = 'filialen.xml';
# getstore('https://filialen.migros.ch/sitemap?&lang=de', $fil_xml_name) or die;

my $xml_parser = new XML::Parser(Style => 'Stream');

my $in_loc = 0;
open (my $fil_xml_h, '<', $fil_xml_name) or die;
open (my $dl_url_h , '>', 'download.sh') or die;
print $dl_url_h "echo \\\n";
$xml_parser -> setHandlers (
   Start     => \&    start_element,
   End       => \&      end_element,
   Char      => \&     char_data,
   Default   => \&  default_element
);
$xml_parser -> parse($fil_xml_h);
print $dl_url_h "| xargs -n 3 -P 12 wget -q\n";

sub start_element {

  my($parseinst, $element, %attributes) = @_;

  $in_loc = 1 if $element eq 'loc';

# print "start element: [$element]\n";

# foreach my $attribute (keys %attributes) {
#   print "    $attribute = $attributes{$attribute}\n"
# }

}

sub end_element {
  my($parseinst, $element, %attributes) = @_;

  $in_loc = 0 if $element eq 'loc';
# print "end element: [$element]\n";

# It seems as though attributes will be always
# be empty in end_element?
# foreach my $attribute (keys %attributes) {
#   print "    $attribute = $attributes{$attribute}\n"
# }

# print "\n";
}

sub char_data {
  my($parseinst, $data) = @_;

  if ($in_loc) {

    $data =~ s/{amp}/&/;
   (my $id = $data) =~ s|.*/||;
    print $dl_url_h "     $data -O $ENV{digitales_backup}crawler/Oeffnungszeiten/Migros/wgetted/$id.html \\\n";
#   print $dl_url_h "     $data -O                                                      wgetted/$id.html \\\n";
  }

# print "character data:\n";
# print "  data: $data\n"; 

}

sub default_element {

  my $parseinst = shift;

  my $what_is_this = shift;

}
