#!/usr/bin/perl
use warnings;
use strict;
use lib '..';
use Oeffnungszeiten;

use utf8;


  Oeffnungszeiten::create_html("$ENV{digitales_backup}crawler/Oeffnungszeiten/Coop/wgetted/*.html", 'Coop');

# use HTML::Parser;
# use Encode qw(decode encode);
# 
# 
# my @in_tags = qw(span tr title);
# 
# my %g;
# 
# my $html_parser = HTML::Parser->new(
#   start_h       => [\&hp_start_tag  , 'tag, attr, text'  ],
#   end_h         => [\&hp_end_tag    , 'tag'              ],
#   text_h        => [\&hp_text       , 'text'             ],
# );
# 
# $html_parser->report_tags(qw(span tr title));
# 
# my $in_title = 0;
# my $title ='';
# my $strasse = '';
# my $plz = '';
# my $ort = '';
# my $telephone = '';
# my $fax = '';
# my $geschf = '';
# my %zeiten;
# 
# my $out = open_html();
# for my $file ( glob "$ENV{digitales_backup}crawler/Oeffnungszeiten/Coop/wgetted/*.html") {
# 
# 
#   $g{itemprop} = '';
#   $g{datetime} = '';
#   $in_title = 0;
#   $title ='';
#   $strasse = '';
#   $plz = '';
#   $ort = '';
#   $telephone = '';
#   $fax = '';
#   $geschf = '';
#   %zeiten = ();
# 
#   $html_parser->parse_file($file) or die;
# 
#   next unless length($title) > 4;
# 
#   $telephone =~ s/^Tel\S* *//;
#   $fax =~ s/^Fax\S* *//;
#   
#   print $out "<tr>
#     <td>
#       $title<br>
#       $strasse<br>
#         $plz <b>$ort</b>
#     </td>
# 
#     
#     <td>
#       <table border=0>
#         <tr><td>Mo:</td><td><td>$zeiten{Mo}</td>
#         <tr><td>Di:</td><td><td>$zeiten{Tu}</td>
#         <tr><td>Mi:</td><td><td>$zeiten{We}</td>
#         <tr><td>Do:</td><td><td>$zeiten{Th}</td>
#         <tr><td>Fr:</td><td><td>$zeiten{Fr}</td>
#         <tr><td>Sa:</td><td><td>$zeiten{Sa}</td>
#         <tr><td>So:</td><td><td>$zeiten{Su}</td>
#       </table>
# 
#     </td>
#         
#     <td>
#       <table border=0>
#         <tr><td>Tel:</td><td>$telephone</td></tr>
#         <tr><td>Fax:</td><td>$fax</td></tr>
#       </table>
#     </td>
#     <td>$geschf</td>
#   </tr>";
# 
# 
# }
# 
# 
# print $out "</table><body></html>";
# close $out;
# 
# #_{ HTML Parser methods
# 
# sub hp_text { #_{
#     my ($text) = @_;
# 
#     $text = encode('latin1', decode('utf-8', $text));
# 
#     if ($g{in}{title}) {
#       string_append($title, $text);
#     }
# 
#     if ($g{in}{span}) {
#       string_append($strasse   ,$text) if $g{itemprop} eq 'streetAddress';
#       string_append($plz       ,$text) if $g{itemprop} eq 'postalCode';
#       string_append($ort       ,$text) if $g{itemprop} eq 'addressLocality';
#       string_append($telephone ,$text) if $g{itemprop} eq 'telephone';
#       string_append($fax       ,$text) if $g{itemprop} eq 'faxNumber';
#       string_append($geschf    ,$text) if $g{itemprop} eq 'employee';
#     }
# 
# 
# } #_}
# 
# sub hp_start_tag { #_{
#     my ($tag, $attr, $text) = @_;
# 
# 
#      if (grep { $tag eq $_ } @in_tags ) {
#        $g{in}{$tag} = 1;
# 
#        if (exists $attr->{itemprop}) {
#          $g{itemprop} = $attr->{itemprop};
#        }
#      }
# 
#      if ($tag eq 'tr') { #_{
# 
#        if ($attr->{itemprop} // '?' eq 'openingHours') {
# 
#          my $day = substr($attr->{datetime}, 0, 2);
#          $zeiten{$day} = substr($attr->{datetime}, 3);
# 
#        }
#      } #_}
# 
# 
# } #_}
# 
# sub hp_end_tag { #_{
#     my ($tag) = @_;
# 
#     if ( grep { $tag eq "/$_" } @in_tags ) {
# 
#       $g{in}{substr($tag, 1)} = 0;
#       $g{itemprop} = '';
# 
#     }
# 
# } #_}
# 
# #_}
# 
# sub string_append { #_{
#   if ($_[0]) {
#     $_[0] .= " $_[1]"; 
#   }
#   else {
#     $_[0] = $_[1];
#   }
# } #_}
# 
# sub open_html { #_{
#   open (my $out, '>:encoding(utf-8)', '../Coop.html') or die;
#   print $out "<html><head>
#     <meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
#     <title>Coop Öffnungszeiten</title>
# 
#     <style type='text/css'> 
#       tr { vertical-align: top}
#       * { font-family: sans-serif}
#     </style>
#   </head><body><h1>Coop Öffnungszeiten</h1>";
#   print $out "<table border='1'>\n";
# 
#   return $out;
# 
# } #_}
