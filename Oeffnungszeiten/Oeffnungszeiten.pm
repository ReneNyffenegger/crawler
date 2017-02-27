package Oeffnungszeiten;

use strict;
use warnings;

use utf8;
use HTML::Parser;
use Encode qw(decode encode);

# Variablen #_{
my $in_title = 0;
#my $migros_follows_opening_hours = 0;
my $title ='';
my $strasse = '';
my $plz = '';
my $ort = '';
my $telephone = '';
my $fax = '';
my $geschf = '';  # Nur Coop?
my %zeiten;
# my $wochentag = '';
my $weekday ='';

my %WT2WD        = (So      =>'Su', Mo    =>'Mo', Di      =>'Tu', Mi      =>'We', Do        =>'Th', Fr     =>'Fr', Sa     =>'Sa');
my %Wochentag2WD = (Sonntag =>'Su', Montag=>'Mo', Dienstag=>'Tu', Mittwoch=>'We', Donnerstag=>'Th', Freitag=>'Fr', Samstag=>'Sa');



my @in_tags = qw(span tr td title p);

my %g;
 #_}

my $html_parser = HTML::Parser->new( #_{
  start_h       => [\&hp_start_tag  , 'tag, attr, text'  ],
  end_h         => [\&hp_end_tag    , 'tag'              ],
  text_h        => [\&hp_text       , 'text'             ],
); #_}

$html_parser->report_tags(qw(span tr td title meta p));

my $migros_coop_etc;

sub create_html { #_{

  my $html_glob_expr    = shift;
     $migros_coop_etc    = shift;

  my $out = open_html();
  
  for my $file (glob $html_glob_expr) { #_{

    print "$file\n";
  
    $g{itemprop} = '';
    $g{datetime} = '';
    $in_title = 0;
    $title ='';
    $strasse = '';
    $plz = '';
    $ort = '';
    $telephone = '';
    $fax = '';
    $geschf = '';
    %zeiten = ();

    if ($migros_coop_etc eq 'Migros' or $migros_coop_etc eq 'Coop') {
      $html_parser->parse_file($file) or die;
    }
    else {
      parse_denner($file);

    }
    next unless length($title) > 4;
  
    $telephone =~ s/^Tel\S* *//;
    $fax =~ s/^Fax\S* *//;

    my $td_geschf='';
    my $tr_fax   ='';
    if ($migros_coop_etc eq 'Coop') {

      $td_geschf = "<td>$geschf</td>";
      $tr_fax    = "<tr><td>Fax:</td><td>$fax</td></tr>";
    }
    elsif ($migros_coop_etc eq 'Migros') {

      $title =~ s/&gt;.*//;

    }

    if ($migros_coop_etc eq 'Migros' or $migros_coop_etc eq 'Denner') { #_{
      for my $k (keys %WT2WD) {

        $zeiten{$WT2WD{$k}} = 'geschlossen' unless $zeiten{$WT2WD{$k}};
      }
    } #_}

    my $td_file='';
#   $td_file = "<td>$file</td>";

    
    print $out "<tr>$td_file
       <td>
        $title<br>
        $strasse<br>
        $plz <b>$ort</b>
      </td>
      
      <td>
        <table border=0>
          <tr><td>Mo:</td><td><td>$zeiten{Mo}</td>
          <tr><td>Di:</td><td><td>$zeiten{Tu}</td>
          <tr><td>Mi:</td><td><td>$zeiten{We}</td>
          <tr><td>Do:</td><td><td>$zeiten{Th}</td>
          <tr><td>Fr:</td><td><td>$zeiten{Fr}</td>
          <tr><td>Sa:</td><td><td>$zeiten{Sa}</td>
          <tr><td>So:</td><td><td>$zeiten{Su}</td>
        </table>
  
      </td>
          
      <td>
        <table border=0>
          <tr><td>Tel:</td><td>$telephone</td></tr>
          $tr_fax
        </table>
      </td>
      $td_geschf
    </tr>";
  
  
  } #_}
  
  
  print $out "</table><body></html>";
  close $out;

} #_}

#_{ HTML Parser methods

sub hp_text { #_{
    my ($text) = @_;

    $text = encode('latin1', decode('utf-8', $text));

    if ($g{in}{title}) {
      string_append($title, $text);
    }

    if ($g{in}{span} or $g{in}{p}) {
      string_append($strasse   ,$text) if $g{itemprop} eq 'streetAddress';
      string_append($plz       ,$text) if $g{itemprop} eq 'postalCode';
      string_append($ort       ,$text) if $g{itemprop} eq 'addressLocality';
      string_append($telephone ,$text) if $g{itemprop} eq 'telephone';

      if ($migros_coop_etc eq 'Coop') {
        string_append($geschf    ,$text) if $g{itemprop} eq 'employee';
        string_append($fax       ,$text) if $g{itemprop} eq 'faxNumber';
      }
#     elsif ($migros_coop_etc eq 'Migros') {

#       if ($g{itemprop} eq 'opens') {
#         $zeiten{$weekday} = $attr->{content}
#       }
#       elsif ($g{itemprop} eq 'closes') {
#         $zeiten{$weekday} = "-$attr->{content}";
#       }

#     }


    }

    if ($g{in}{td}) {

      if ($g{itemprop} eq 'dayOfWeek' and $migros_coop_etc eq 'Migros') {
        $text =~ s/ //g;
        $weekday = $WT2WD{$text};
      }

    }
#   if ($migros_follows_opening_hours) {
#     string_append($zeiten{$weekday}, $text);
#   }


} #_}

sub hp_start_tag { #_{
    my ($tag, $attr, $text) = @_;


    if (grep { $tag eq $_ } @in_tags ) { #_{
       $g{in}{$tag} = 1;

       if (exists $attr->{itemprop}) { #_{
         $g{itemprop} = $attr->{itemprop};
 
         if ($tag eq 'span' and $migros_coop_etc eq 'Migros') { #_{

           if (my $content = $attr->{content}) { #_{

             if ($content ne '00:00') { #_{
               if ($g{itemprop} eq 'opens') { #_{
   
                 $zeiten{$weekday} .= ' / ' if $zeiten{$weekday};
                 $zeiten{$weekday} .= $content;
   
               } #_}
               elsif ($g{itemprop} eq 'closes') { #_{
                 $zeiten{$weekday} .= "-$content";
               } #_}
             } #_}
           } #_}
         } #_}
       } #_}
     } #_}

     if ($tag eq 'tr') { #_{

       if ($migros_coop_etc eq 'Coop') {
         if ($attr->{itemprop} // '?' eq 'openingHours') {
  
           my $day = substr($attr->{datetime}, 0, 2);
           $zeiten{$day} = substr($attr->{datetime}, 3);
  
         }
       }
     } #_}




} #_}

sub hp_end_tag { #_{
    my ($tag) = @_;

    if ( grep { $tag eq "/$_" } @in_tags ) {

      $g{in}{substr($tag, 1)} = 0;
      $g{itemprop} = '';


#      if ($migros_coop_etc eq 'Migros') {
#        if ($tag eq '/td') {
#          if ($migros_follows_opening_hours) {
#            $migros_follows_opening_hours = 0;
#          }
#        }
#      }

    }

} #_}

#_}

sub parse_denner { #_{
  my $filename = shift;

# local $/ = chr(13).chr(10);

  open (my $file_h, '<:encoding(utf-8)', $filename) or die;

  my $in_oeffnungszeiten = 0;
  my $next_WD = '';

  while (my $line = <$file_h>) { #_{

    chomp $line;
    $line =~ s/\x{0d}//g;
    $line =~ s/\x{09}/ /g;

    $title     = $1 if $line =~ m|<span itemprop="name">(.*)</span>|;
    $strasse   = $1 if $line =~ m|<span itemprop="streetAddress">(.*)</span>|;
    $ort       = $1 if $line =~ m|<span itemprop="addressLocality">(.*)</span>|;
    $plz       = $1 if $line =~ m|<span itemprop="postalCode">(.*)</span>|;
    $telephone = $1 if $line =~ m|Tel\. (\d\d\d \d\d\d \d\d \d\d)|;


    if ($line =~ m!<div class="itemtitle">Öffnungszeiten</div>!) {

      $in_oeffnungszeiten = 1;
      next;
    }

    $in_oeffnungszeiten = 0 if $line =~ m|</table>|;

    if ($in_oeffnungszeiten) { #_{

#     print "In Oeff: $line\n";

        if ($next_WD) { #_{
 
          if ($line =~ m|<td>(\d\d:\d\d - \d\d:\d\d) Uhr</td>|) {
            
              if ($zeiten{$next_WD}) {
                $zeiten{$next_WD} .= ' / ';
              }
              $zeiten{$next_WD} .= $1;
            
              next;
          };

#         $next_WD = '';
 
        } #_}

        if ($line =~ m|<td>(.*)</td>|) { #_{

          if (exists $Wochentag2WD{$1}) {
            $next_WD = $Wochentag2WD{$1};
#           print "Wochentag = $1, next_wochentag=$next_WD, line: $line\n";
#           next
          }

#         die "line: $line\n\$1: $1\n" unless $next_WD;
          next;

      } #_}

    } #_}

  } #_}


  close $file_h;

} #_}

sub open_html { #_{
  open (my $out, '>:encoding(utf-8)', "../$migros_coop_etc.html") or die;
  print $out "<html><head>
    <meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
    <meta name='description' content='$migros_coop_etc Öffnungszeiten'>
    <title>$migros_coop_etc Öffnungszeiten</title>

    <style type='text/css'> 
      tr { vertical-align: top}
      * { font-family: sans-serif}
    </style>
  </head><body>
  
  <a href='index.html'>Öffnungszeiten</a> von $migros_coop_etc
";

  print $out "<table border='1'>\n";

  return $out;

} #_}

sub string_append { #_{
  if ($_[0]) {
    $_[0] .= " $_[1]"; 
  }
  else {
    $_[0] = $_[1];
  }
} #_}

1;
