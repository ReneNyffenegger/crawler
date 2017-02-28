#!/usr/bin/perl
use warnings;
use strict;
use feature 'say';
# use Data::Dump qw(dump);

binmode STDOUT, ':encoding(utf8)';

use LWP::Simple;
use utf8;

my $download_dir      = "$ENV{digitales_backup}crawler/Recht/SR/downloaded/"; die unless -d $download_dir;
my $download_from_url = 'https://www.admin.ch/opc/de/classified-compilation/';

$/ = "\x0d\x0a";



my $cur_tree;
my %tree;
my %id2name;
descend_level('national.html', 0, \%tree);

# print dump(%tree);


open (my $out, '>:encoding(utf-8)', "$ENV{digitales_backup}crawler/Recht/SR/created/index.html"); #_{
print $out "<!DOCTYPE html>
<head>
  <title>Systematische Rechtssammlung - Inhaltsverzeichnis</title>
  <meta name='description' content='Systematische Rechtssammlung - Inhaltsverzeichnis'>
  <meta charset='utf-8'/>

  <style>

    td.nr0 {padding-left: 10px}
    td.nr1 {padding-left: 25px}
    td.nr2 {padding-left: 40px}
    td.nr3 {padding-left: 55px}

    td.lvl0 {font-size: 30px}
    td.lvl1 {font-size: 26px}
    td.lvl2 {font-size: 22px}
    td.lvl3 {font-size: 12px}

    .content {
//    display: none;
      display: block
    }




  </style>
  <script>

    function show_hide(id) {
      return;
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

print $out "<table>\n";
for my $child_tree (@{$tree{children}}) {
  print_tree($child_tree);
}
print $out "</table>\n";


print $out "</body></html>";
close ($out);


sub descend_level { #_{

  my $filename    = shift;
  my $level       = shift;
  my $parent_tree = shift;


  my $fh = open_downloaded_file($filename);

  my $level_2_has_ul = 0;


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
      if ($line =~ m|^ *<a name="([^"]+)"></a>(\S*)|) {

        my $nr = $1;
        die unless $1 eq $2;

        my $tree = {
          level => $cur_tree->{level}+1,
          nr=>$nr,
        };
        my $line = <$fh>; chomp ($line); die unless $line =~ m|^ *</td> *$|;
           $line = <$fh>; chomp ($line); die unless $line =~ m|^ *<td> *$|;
           $line = <$fh>; chomp ($line); 

           
        if ($line =~ m|^ *<a href='/opc/de/classified-compilation/([^']+)'>(.*)</a> *$|) { #_{

          my $url = $1;

          $tree->{url } = $url;
          $tree->{name} = $2;

          die unless $url =~ m!^([^/])+/index.html!;
          download_file_if_not_exists($url);
             

        } #_}
        else { #_{

          $tree->{name} = $line;


          while (1) { #_{

            $line = <$fh>; chomp ($line); die "$. $line" unless $line =~ m|^ *→ *$|;
            $line = <$fh>; chomp ($line); die $line unless $line =~ m|^ *<a href='/opc/de/classified-compilation/(\d[\d.]).html#([^']+)'>\2</a> *$|;
            my $id = $2;
#           print "id: $id\n";

            $line = <$fh>; chomp ($line);
            die $line unless $line =~ s! *(</td>|<br/>) *$!!;
            my $td_br = $1;

            $line =~ s/^ *//;
            my $target = $line;
#           print "target: $id -> $target\n";
            push @{$tree->{targets}}, {id=>$id, target=>$target};

            last if $td_br eq '</td>';
            $line = <$fh>; chomp ($line); die unless $line =~ m|^ *$|;
          } #_}

        } #_}

        push @{$cur_tree->{children}}, $tree;


      }

    } #_}

  } #_}
  close $fh;


} #_}

sub download_file_if_not_exists { #_{
  my $filename = shift;

  my $filename_local  = $filename;
  my $filename_remote = $filename;

  if ($filename =~ m!(.*)/index.html!) {

    $filename_local = "$1.html";
  }

  return if -e "${download_dir}$filename_local";

  print "Downloading $filename\n";
  getstore("${download_from_url}$filename_remote", "${download_dir}$filename_local") or die "could not download $filename_remote";

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


  $cur_tree = {};

  $cur_tree -> {nr   } = $nr;
  $cur_tree -> {level} = $level;
  $cur_tree -> {name } = $name;

  push @{$parent_tree -> {children}}, $cur_tree;
  descend_level("$1.html", $level+1, $cur_tree) if $level < 2;

  return;


} #_}

sub print_tree { #_{
  my $parent_tree = shift;

  my $nr    = $parent_tree->{nr};
  my $level = $parent_tree->{level};
  my $name  = $parent_tree->{name};

  my $indent = "  " x $level;

  my $name_td = $name;
  if (exists $parent_tree->{url}) {
    $name_td = "<a href='https://www.admin.ch/opc/de/classified-compilation/$parent_tree->{url}'>$name</a>";
  }

  my $targets = '';
  if (exists $parent_tree->{targets}) {
    for my $target (@{$parent_tree->{targets}}) {

      if ($targets) {
        $targets .= ", ";
      }
      else {
        $targets = " (";
      }
      $targets .= "<a href='#id_$target->{id}'>";
      $targets .= $target->{id};
      $targets .= "</a>";
      if ($target->{target}) {
        $targets .= " [$target->{target}]";
      }

    }
    $targets .= ")";
  }

  print $out "<tr id='id_$nr'><td class='nr$level lvl$level'>$nr</td><td class='nm$level lvl$level'>$name_td$targets</td></tr>\n";

  if (exists $parent_tree->{children}) {
    for my $child_tree (@{$parent_tree->{children}}) {
       print_tree($child_tree);
    }
  }




# Show/Hide inhaltsverzeichnis
# my $id="kat_kont_$nr";
#
# print $out "$indent<div class='l$level'><!-- { -->\n";
#
#
# if (exists $parent_tree->{children}) {
#
#   print $out "$indent  <div class='head'>$nr: <a href='javascript:show_hide(\"$id\");'>$name</a></div>\n";
#   print $out "$indent  <div class='content' id='$id'><!-- { -->\n";
#   for my $child_tree (@{$parent_tree->{children}}) {
#     print_tree($child_tree);
#   }
#   print $out "$indent  </div> <!-- } -->\n";
# }
# else {
#
#   print $out "$indent  <div class='head'>$nr: $name</div>\n";
# }
#
# print $out "$indent</div><!-- } -->\n";

} #_}

