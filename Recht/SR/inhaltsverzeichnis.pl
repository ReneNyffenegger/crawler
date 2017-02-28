#!/usr/bin/perl
use warnings;
use strict;

use LWP::Simple;

my $download_dir      = "$ENV{digitales_backup}crawler/Recht/SR/downloaded/"; die unless -d $download_dir;
my $download_from_url = 'https://www.admin.ch/opc/de/classified-compilation/';



open (my $out, '>:encoding(utf-8)', "$ENV{digitales_backup}crawler/Recht/SR/created/inhaltsverzeichnis.html");
print $out "<!DOCTYPE html>
<head>
  <title>Systematische Rechtssammlung - Inhaltsverzeichnis</title>
  <meta name='description' content='Systematische Rechtssammlung - Inhaltsverzeichnis'>
  <meta charset='utf-8'/>
</head>
<body>
<h1>Systematische Rechtssammlung - Inhaltsverzeichnis</h1>
";


descend_level('national.html', 0);
print $out "</body></html>";
close ($out);


sub descend_level { #_{

  my $filename = shift;
  my $level    = shift;
  my $fh = open_downloaded_file($filename);

  print "$level: $filename\n";

  print $out "<ul>\n";
  while (my $line = <$fh>) { #_{

    if ($level == 0) { #_{
      if ($line =~ m|^ *<td><a href="/opc/de/classified-compilation/(\d).html">(.*)</a></td> *$|) {

        print $out "  <li><b>$1</b>: $2\n";
        descend_level("$1.html", $level+1);

      }
    } #_}
    elsif ($level == 1) { #_{
      if ($line =~ m|^ *<a href='/opc/de/classified-compilation/(\d+).html#\1'>(.*)</a> *$|) {

        print $out "  <li><b>$1</b>: $2\n";
        descend_level("$1.html", $level+1);

      }
    } #_}
    elsif ($level == 2) {
#
    }

  } #_}
  close $fh;

  print $out "</ul>";

} #_}

sub download_file_if_not_exists { #_{
  my $filename = shift;

  return if -e "${download_dir}$filename";

  print "Downloading $filename\n";
  getstore("${download_from_url}$filename", "${download_dir}$filename") or die "could not download $filename";

} #_}

sub open_downloaded_file {
  my $filename = shift;

  download_file_if_not_exists($filename);

  open (my $fh, '<:encoding(utf-8)', "${download_dir}$filename") or die "could not open ${download_dir}$filename";

  1 while <$fh> !~ m|<!-- begin: main -->|;

  $fh;

}
