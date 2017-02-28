#!/usr/bin/perl
use warnings;
use strict;
use feature 'say';

use LWP::Simple;

my $download_dir      = "$ENV{digitales_backup}crawler/Recht/SR/downloaded/"; die unless -d $download_dir;
my $download_from_url = 'https://www.admin.ch/opc/de/classified-compilation/';

$/ = "\x0d\x0a";



my %tree;
descend_level('national.html', 0, \%tree);


open (my $out, '>:encoding(utf-8)', "$ENV{digitales_backup}crawler/Recht/SR/created/inhaltsverzeichnis.html"); #_{
print $out "<!DOCTYPE html>
<head>
  <title>Systematische Rechtssammlung - Inhaltsverzeichnis</title>
  <meta name='description' content='Systematische Rechtssammlung - Inhaltsverzeichnis'>
  <meta charset='utf-8'/>

  <style>

    div.l0 {
      margin-left: 20px;
    }
    div.l1 {
      margin-left: 20px;
    }
    div.l2 {
      margin-left: 20px;
    }

    .content {
      display: none;
    }




  </style>
  <script>

    function show_hide(id) {
//    alert(id);
      var elem = document.getElementById(id);
//    alert(elem);
//    alert(elem.style);
//    alert(elem.style.display);
      if (elem.style.display == 'block') {
        elem.style.display='none';
      }
      else {
        elem.style.display='block';
      }
    }

  </script>
</head>
<body>
<h1>Systematische Rechtssammlung - Inhaltsverzeichnis</h1>
"; #_}

for my $child_tree (@{$tree{children}}) {
  print ref($child_tree), "\n";
  print_tree($child_tree);
}


print $out "</body></html>";
close ($out);


sub descend_level { #_{

  my $filename    = shift;
  my $level       = shift;
  my $parent_tree = shift;

# my %tree;

  my $fh = open_downloaded_file($filename);

  my $level_2_has_ul = 0;

  print "$level: $filename\n";

  while (my $line = <$fh>) { #_{
    chomp $line;

    if ($level == 0) { #_{
      if ($line =~ m|^ *<td><a href="/opc/de/classified-compilation/(\d).html">(.*)</a></td> *$|) {

        kategorie($level, $1, $2, $parent_tree);

      }
    } #_}
    elsif ($level == 1) { #_{
      if ($line =~ m|^ *<a href='/opc/de/classified-compilation/(\d+).html#\1'>(.*)</a> *$|) {

        kategorie($level, $1, $2, $parent_tree);
      }
    } #_}
    elsif ($level == 2) { #_{

      if ($line =~ m|^ *<h2 id="(\d\d\d)"> *$|) { #_{


        $line = <$fh>;
        chomp $line;

        $line =~ /(\d\d\d)\s+(.*)/;

        my $nr    = $1;
        my $name = $2;

        kategorie($level, $nr, $name, $parent_tree);
        

      } #_}

    } #_}

  } #_}
  close $fh;


} #_}

sub download_file_if_not_exists { #_{
  my $filename = shift;

  return if -e "${download_dir}$filename";

  print "Downloading $filename\n";
  getstore("${download_from_url}$filename", "${download_dir}$filename") or die "could not download $filename";

} #_}

sub open_downloaded_file { #_{
  my $filename = shift;

  download_file_if_not_exists($filename);

  open (my $fh, '<:encoding(utf-8)', "${download_dir}$filename") or die "could not open ${download_dir}$filename";

  1 while <$fh> !~ m|<!-- begin: main -->|;

  $fh;

} #_}

sub kategorie { #_{
  my $level       = shift;
  my $nr          = shift;
  my $name        = shift;
  my $parent_tree = shift;
# my $tree        = shift;


  my $tree = {};

  $tree -> {nr   } = $nr;
  $tree -> {level} = $level;
  $tree -> {name } = $name;

  push @{$parent_tree -> {children}}, $tree;
  descend_level("$1.html", $level+1, $tree) if $level < 2;

  return;

  my $indent = "  " x $level;


  my $id="kat_kont_$nr";

  print $out "$indent<div class='l$level'><!-- { -->\n";
  print $out "$indent  <div class='head'>$nr: <a href='javascript:show_hide(\"$id\");'>$name</a></div>\n";
  print $out "$indent  <div class='content' id='$id'><!-- { -->\n";
# print $out "$indent  <li><b>$1</b>: $2\n";

  descend_level("$1.html", $level+1) if $level < 2;

  print $out "$indent  </div><!-- } -->\n";
  print $out "$indent</div><!-- } -->\n";

} #_}

sub print_tree { #_{
  my $parent_tree = shift;

# $tree -> {nr   } = $nr;
# $tree -> {level} = $level;
# $tree -> {name } = $name;

# push @{$parent_tree -> {children}}, $tree;
# descend_level("$1.html", $level+1, $tree) if $level < 2;

# return;

  my $nr    = $parent_tree->{nr};
  my $level = $parent_tree->{level};
  my $name  = $parent_tree->{name};

  my $indent = "  " x $level;



  my $id="kat_kont_$nr";

  print $out "$indent<div class='l$level'><!-- { -->\n";

  if ($level < 2 and exists $parent_tree->{children}) {

    print $out "$indent  <div class='head'>$nr: <a href='javascript:show_hide(\"$id\");'>$name</a></div>\n";
    print $out "$indent  <div class='content' id='$id'><!-- { -->\n";
    for my $child_tree (@{$parent_tree->{children}}) {
      print_tree($child_tree);
    }
    print $out "$indent  </div> <!-- } -->\n";
  }
  else {

    print $out "$indent  <div class='head'>$nr: $name</div>\n";
  }

  print $out "$indent</div><!-- } -->\n";

} #_}

