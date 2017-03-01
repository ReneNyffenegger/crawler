#!/usr/bin/perl
use warnings;
use strict;
use utf8;

use HTML::Parser;

binmode STDOUT, ':encoding(utf8)';
my $download_dir      = "$ENV{digitales_backup}crawler/Recht/SR/downloaded/"; die unless -d $download_dir;
$/ = "\x0d\x0a";

my $out;
my $indent_;
my $code_pre;

my $is_in_kopf;
my @kopf_elems;

my @content;

my $is_in_h_for_content;
my $is_after_hr;
my $is_in_content;

my $cur_file;

my $parser = HTML::Parser->new(
  start_h       => [\&hp_start_tag  , 'tag, attr'],
  end_h         => [\&hp_end_tag    , 'tag'      ],
  text_h        => [\&hp_text       , 'text'     ],
);

for my $file (glob "$download_dir???*.html") { #_{

  next if $file =~ /national\.html$/;

  convert_text($file);

} #_}

sub convert_text { #_{
  $cur_file = shift;

 (my $filename_only = $cur_file) =~ s|.*/||;

  print "$filename_only\n";

  $indent_ = 0;
  $code_pre = '';

  @content = ();
  $is_in_h_for_content = 0;
  $is_after_hr = 0;
  $is_in_content = 0;

   @kopf_elems = ();

  open (my $in , '<:encoding(utf-8)', $cur_file);
  open (   $out, '>:encoding(utf-8)', "$ENV{digitales_backup}crawler/Recht/SR/created/$filename_only");


  my $title_seen = 0;
  my $text_ist_in_kraft = 0;
  while (my $line = <$in>) { #_{
    chomp $line;

    if ($line =~ m|<title>(.*)</title>|) { #_{

      my $title = $1;
      die if $title_seen++;
      print $out #_{
"<!doctype html>
<html>
 <head>
  <title>$title</title>
  <meta charset='utf-8'/>
  <meta name='description' content='$title'>
 </head><body>
   <h1>$title</h1>
"; #_}

      while (1) {
        $line = <$in>; chomp $line;
        last if $line =~ m|^ *<div id="toolbar" class="pull-right"> *|;
      }
      $line = <$in>; chomp $line; die $line unless $line =~ m|^ *<a href="#" id="expande-all">alles einblenden</a>|;
      $line = <$in>; chomp $line; die unless $line =~ m|^ *</div> *$|;
      $line = <$in>; chomp $line;
      print "Warning, length($line)=".length($line) if length($line) < 500;
      $parser->parse($line) or die;
    } #_}

    

    if ($line =~ m|^ *<div>Dieser Text ist in Kraft.</div> *$|) { #_{
      $text_ist_in_kraft = 1;
    } #_}


  } #_}

  print $out "<h1>Kopf</h1>";

  for my $kopf_elem (@kopf_elems) {

    print $out "<b>$kopf_elem->{tag}</b>: ";
    print $out join " - ", @{$kopf_elem->{parts}}; 
    print $out "\n<p>";

  }
  for my $elem (@content) {

    print $out "<h$elem->{title}{level}>" . $elem->{title}{text} .
              "</h$elem->{title}{level}>\n";

    print $out $elem->{content} // '&lt;null&gt;';

    if ($elem->{after_hr}) {
      print $out "<hr>$elem->{after_hr}";
    }
  }

  $code_pre =~ s/&/&amp;/g;
  $code_pre =~ s/</&lt;/g;
  $code_pre =~ s/>/&gt;/g;
  print $out "<code><pre>$code_pre</pre></code>\n";
  print $out "</body></html>";
  close $in;
  close $out;

  die unless $text_ist_in_kraft;

} #_}

#_{ HTML::Parser subs

sub hp_text { #_{
    my ($text) = @_;


    if ($is_in_kopf) { #_{
      push @{$kopf_elems[-1]->{parts}}, $text;
    } #_}
    else { #_{

      if (@content) {
        if ($is_in_h_for_content) {
          $content[-1]->{title}{text} .= $text;
        }
        elsif ($is_after_hr) {
          if (@content) {
            $content[-1]->{content} .= $text;
          }
          else {
            print "Warning, \@content is empty: after hr $text<\n";
          }
        }
        elsif ($is_in_content) {
   
          if (@content) {
            $content[-1]->{content} .= $text;
          }
          else {
            print "Warning, \@content is empty: content $text<\n";
          }
        }
      }
    } #_}

#   $text =~ s/\n/ /g;
    $code_pre .= '  ' x $indent_ . "Text: $text\n";
} #_}

sub hp_start_tag { #_{
  my ($tag, $attr) = @_;

  if ($is_in_kopf) { #_{

    if (grep { $_ eq $tag } qw(h1 h2 p) ) {
      push @kopf_elems, {tag=>$tag, parts=>[]};
    }

  } #_}
  elsif (my $name=$attr->{name}) { #_{

    if ($name eq 'kopf') {
      $is_in_kopf = 1;
    }

  } #_}
  else { #_{
    if ($tag =~ m|^h(\d)$|) { #_{

      push @content, {title=>{level=>$1}};
      $is_in_h_for_content= 1;
      $is_after_hr        = 0;
      $is_in_content      = 0;

    } #_}
    elsif ($tag eq 'div' or $tag eq 'p') {
      $is_in_content       = 1;
      $is_in_h_for_content = 0;
      $is_after_hr         = 0;
    }
    elsif ($tag eq 'hr') { #_{

      if ($is_in_content) {
        $is_after_hr       = 1;
      }
      $is_in_content      = 0;

    } #_}
  } # }




  $code_pre .= '  ' x $indent_ . "Tag: $tag";

  for my $k (keys %$attr) {
    $code_pre .= " $k=$attr->{$k}";
  }
  $code_pre .= "\n";

  if ($tag ne 'hr' and $tag ne 'br') {
    $indent_ ++;
  }


} #_}

sub hp_end_tag { #_{
  my ($tag, $text) = @_;

  $tag = substr($tag, 1);

  if ($tag eq 'div') { #_{
    $is_in_kopf = 0;
  } #_}
  else {
    if ($tag =~ m|^h\d$|) {
      $is_in_h_for_content = 0;
    }
  }


  if ($tag ne 'hr' and $tag ne 'br') {
    $indent_ --;
  }
  $code_pre .= '  ' x $indent_ . "Endtag: $tag\n";
} #_}

 #_}
