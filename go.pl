#!/usr/bin/perl
use warnings;
use strict;

use LWP::UserAgent;
use HTML::Parser;
use Text::Wrap;
use URI;

my $method = shift;
my $url = shift;

my $user_agent = LWP::UserAgent->new ( #_{
  timeout         =>  10,
# agent           => 'TQ',
  agent           => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0',
  default_headers =>  HTTP::Headers->new('Accept-Language'  => 'de; en; *'),
# default_headers =>  HTTP::Headers->new('Accept-Language'  => 'en; de; *'),
  max_redirect    =>  1,
); #_}

my $html_parser = HTML::Parser->new( #_{
  start_h       => [\&hp_start_tag  , 'tag, attr, text'  ],
  end_h         => [\&hp_end_tag    , 'tag'              ],
  text_h        => [\&hp_text       , 'text'             ],
  comment_h     => [\&hp_comment    , 'text'             ],
  default_h     => [\&hp_default    , 'text'             ],
  process_h     => [\&hp_process    , 'text'             ],
  declaration_h => [\&hp_declaration, 'text'             ],
); #_}

$Text::Wrap::columns  = 120;
$Text::Wrap::unexpand =   0;

my $uri_ = URI->new($url) or die "No uri_ from $url\n";
page ($method, $uri_->scheme, $uri_->host, $uri_->path);

# topLevelDomain($host);

my %g_page_info;

sub topLevelDomain { #_{
  my $scheme = shift;
  my $host   = shift;
  page('GET', $scheme, $host, '/');

# whois($host);
# robot_txt($host); 
} #_}

sub whois { #_{

  my $host = shift;

  my $whois = readpipe("whois $host");

  if ($whois =~ m|whois: This information is subject to an Acceptable Use Policy.\nSee https://www.nic.ch/terms/aup/|s ) {

    my $holder            = matchUpToNLNL('Holder of domain name:', $whois);
    my $technical_contact = matchUpToNLNL('Technical contact:'    , $whois);
    my $registrar         = matchUpToNLNL('Registrar:'            , $whois);
    my $name_servers      = matchUpToNLNL('Name servers:'         , $whois);

#   my ($holder, $technical_contact, $registrar, $first_registration_date, $name_servers) = $whois =~ m|Holder of domain name:\n(.*)\nContractual Language.*\nTechnical contact:\n(.*)|s;#\nRegistrar:\n(.*?)\n.*First registration date:\n(.*?)\n.*Name servers:\n(.*)|s or die $whois;

    if ($holder) {
      print $holder;
    }
    else {
      print "No holder found";
    }

    print "\n\n";

    if ($technical_contact) {
      print $technical_contact;
    }
    else {
      print "No technical contact found";
    }

    print "\n\n";

    if ($name_servers) {
      print $name_servers;
    }
    else {
      print "No name servers found";
    }

    print "\n\n";

    if ($registrar) {
      print $registrar;
    }
    else {
      print "No registrar found";
    }

    print "\n\n";

  }
  else {
    print $whois;
  }


} #_}

sub matchUpToNLNL { #_{
  #
  #  Used for sub whois()
  #
  my $title = shift;
  my $text = shift;

  my ($ret) = $text =~ m!$title\n(.*?)\n(?:\n|$)!s;

  return $ret;

} #_}

sub page { #_{

  my $method = shift;
  my $scheme = shift;
  my $host   = shift;
  my $path   = shift;

  my $url  = "$scheme://$host$path";

  print "url = $url\n";

  my $http_response = $user_agent -> request(
       HTTP::Request -> new ($method=>$url)
  );

  my $content = $http_response->content;

  if ($http_response->code == 301) {
    printf "301 Moved Permanently to %s\n", $http_response->header('Location');
    return;
  }
  if ($http_response->code == 302) {
    printf "302 Found, got to %s\n", $http_response->header('Location');
    return;
  }

  show_http_headers($http_response->headers);

  open (my $out, '>:encoding(utf-8)', '/tmp/crawler.html') or die;
  print $out $content;
  close $out;

  %g_page_info = (
     url => $url
  );
  $html_parser->parse($content);
  $html_parser->eof;

  print "\n\n";
  printf "status:      %s\n", $http_response->status_line              ;
  printf "server:      %s\n", $http_response->header('Server') // 'n/a';
  printf "title:       %s\n", $g_page_info{title}              // 'n/a';
  printf "language:    %s\n", $g_page_info{lang}               // 'n/a';
  printf "charset:     %s\n", $g_page_info{meta}{charset    }  // 'n/a';
  printf "robots:      %s\n", $g_page_info{meta}{robots     }  // 'n/a';
  printf "generator:   %s\n", $g_page_info{meta}{generator  }  // 'n/a';
  printf "keywords:    %s\n", wrap('', '             ', $g_page_info{meta}{keywords   } // 'n/a');
  printf "description: %s\n", $g_page_info{meta}{description}  // 'n/a';
  printf "declaration: %s\n", $g_page_info{declaration}        // 'n/a'; 

  print "<iframes>\n";
  for my $link (@{$g_page_info{iframes}}) {
    print_url($link->{dest});
  }

  print "links:\n";
  for my $link (@{$g_page_info{links}}) { #_{
    print_url($link->{dest}, $link->{text});
#    printf("  %-5s %-30s %4d %-50s %-50s %s\n", 
#      $link->{dest}->{scheme} // 'n/a',
#      $link->{dest}->{host  } // 'n/a', 
#      $link->{dest}->{port  } //    0 , 
#      $link->{dest}->{path  } // 'n/a', 
#      $link->{dest}->{query } // '',
#      $link->{text}           // 'n/a'
#    );
  } #_}

  print "TODOs\n";
  for my $todo (@{$g_page_info{TODO}}) {
    printf "  $todo\n";
  }

} #_}

sub robot_txt { #_{

  my $host = shift;

  my $http_response = $user_agent -> request(
       HTTP::Request -> new (GET=>"http://$host/robots.txt")
  );

  show_http_headers($http_response->headers);

# print $http_response->content;

} #_}

sub print_url { #_{
  my $dest = shift;
  my $text = shift;

  printf("  %-5s %-30s %4d %-50s %-50s %-20s %s\n", 
    $dest->{scheme} // 'n/a',
    $dest->{host  } // 'n/a', 
    $dest->{port  } //    0 , 
    $dest->{path  } // 'n/a', 
    $dest->{query } // '',
    $dest->{fragment} // '',   # the part after a # (the anchor)
    $text           // 'n/a'
  );
} #_}

sub show_http_headers { #_{
  my $http_headers = shift;

  print "HTTP Headers\n";
  for my $header_field_name ($http_headers->header_field_names) {
    printf "  %-50s: %s\n", $header_field_name, wrap('', '                 ', $http_headers->header($header_field_name) // '?');
  }

} #_}

#_{ HTML Parser methods

sub hp_text { #_{
    my ($text) = @_;
    $text =~ s/\s+/ /g;


    if ($g_page_info{in_title}) {
      string_append($g_page_info{title}, $text);
    }
    elsif ($g_page_info{cur_a}) {
      string_append($g_page_info{cur_a}{text}, $text);
    }
    else {

      if ($text =~ /(\w+str(?:asse|\.))\s+(\w*\d\w*)/) {
        print "Strasse:    $1 $2\n";
      }
      if ($text =~ s/(CH\d\d( \d{4}){4} \d)//) {
         print "IBAN:      $1\n";
      }
      if ($text =~ /\b(\d\d\d\d)\s+(\w+)/) {
        if ($text !~ /([Ss]eit|[vV]on|[Cc]opyright|Jahr|\(c\)) (\d\d\d\d)/) { 
          my $plz = $1;
          if ($text !~ /(Jan|Feb|Mär|Apr|Mai|Jun|Jul|Aug|Sep|Okt|Nov|Dez)\w+ $plz/) {
            print "Ort:      $text\n";
          }
        }
      }
      if ($text =~ /\b(\d\d\d \d\d\d \d\d \d\d)/) {
        print "Tel:       $1\n";
      }
      if ($text =~ /(\+\d\d \d\d \d\d\d \d\d \d\d)/) {
        print "Tel:       $1\n";
      }
      if ($text =~ /(\S+\@\S+\.\S+)/) {
        print "Email: $1\n";
      }

    }

} #_}

sub hp_comment { #_{
    my ($comment) = @_;
#   print "Comment: $comment\n";
} #_}

sub hp_start_tag { #_{
    my ($tag, $attr, $text) = @_;


    if    ($tag eq 'meta' ) { #_{

      if (my $name=$attr->{name}) { #_{

        $name = lc $name;

        my $content = $attr->{content};

        if (grep { $_ eq $name } (qw(robots description keywords generator language))) {
          $g_page_info{meta}{$name} = $content;
        }
        elsif ( grep {$_ eq $name} (qw(date google-site-verification viewport))) {
          # Skip
        }
        else {
          push @{$g_page_info{TODO}}, "Unknown meta name $name ($content)";
        }

      } #_}
      elsif (my $http_equiv = $attr->{'http-equiv'} and my $content = $attr->{content}) { #_{
        if ($http_equiv eq 'Content-Type') {
          $g_page_info{meta}{content_type} = $content;
        }
        elsif (grep {$_ eq $http_equiv} (qw(X-UA-Compatible Content-Style-Type))) {
          # Skip
        }
        else {
          push @{$g_page_info{TODO}}, "Unknown http-equiv $http_equiv ($content)";
        }
      } #_}
      elsif (my $charset = $attr->{charset}) {
         $g_page_info{meta}{charset} = $charset;
      }
      else {
          push @{$g_page_info{TODO}}, "Unknown meta tag $text";
      }


    } #_}
    elsif ($tag eq 'a'     ) { #_{


      my $dest = URI->new_abs($attr->{href}, $g_page_info{url});

      print "! a $attr->{href} -> $dest\n";

      my $dest_uri = URI->new($dest);

      my $scheme = $dest->scheme;

      if ($scheme eq 'mailto') {

        print "<a mailto: " . $dest->to . "\n";

      }
      elsif ($scheme eq 'javascript') {
         print "javascript $attr->{href}\n";
      }
      else {

        $g_page_info{cur_a} = {# dest=>$dest,
                               dest => {
                                 scheme   => $scheme,
                                 host     => $dest_uri->host  ,
                                 port     => $dest_uri->port  ,
                                 path     => $dest_uri->path  ,
                                 query    => $dest_uri->query ,
                                 fragment => $dest_uri->fragment   # the part after a # (the anchor)
                               },
                               text=>''};
      }

    } #_}
    elsif ($tag eq 'iframe') { #_{

      my $dest = URI->new_abs($attr->{src}, $g_page_info{url});

      my $dest_uri = URI->new($dest);

      my $scheme = $dest->scheme;

      if ($scheme eq 'mailto') {

        print "<a mailto: " . $dest->to . "\n";

      }
      elsif ($scheme eq 'javascript') {
         print "javascript $attr->{href}\n";
      }
      else {

        $g_page_info{cur_iframe} = {
                               dest => {
                               scheme => $scheme,
                               host   => $dest_uri->host  ,
                               port   => $dest_uri->port  ,
                               path   => $dest_uri->path  ,
                               query  => $dest_uri->query ,
                               fragment => $dest_uri->fragment   # the part after a # (the anchor)
                             },
                             text=>''};
      }

    } #_}
    elsif ($tag eq 'title' ) { #_{

      $g_page_info{in_title} = 1;
      $g_page_info{title} = '';

    } #_}
    elsif ($tag eq 'html'  ) { #_{

      if (my $lang = $attr->{lang}) {

        $g_page_info{lang}=$lang;
      }

    } #_}


} #_}

sub hp_end_tag { #_{
    my ($tag) = @_;

    if ($tag eq '/title') {
      $g_page_info{in_title} = 0;
    }
    elsif ($tag eq '/a') {
      push @{$g_page_info{links}}, $g_page_info{cur_a};
      $g_page_info{cur_a} = undef;
    }
    elsif ($tag eq '/iframe') {
      push @{$g_page_info{iframes}}, $g_page_info{cur_iframe};
      $g_page_info{cur_iframe} = undef;
    }

} #_}

sub hp_default { #_{
    my ($text) = @_;
} #_}

sub hp_process { #_{
    my ($text) = @_;
#   print $text,"\n";
} #_}

sub hp_declaration { #_{
    my ($text) = @_;
    
    if (exists $g_page_info{declaration}) {
       print "Warning, declaration already exists\n";
    }
    else {
      $g_page_info{declaration} = $text;
    }
} #_}

#_}

sub string_append { #_{
  if ($_[0]) {
    $_[0] .= " $_[1]"; 
  }
  else {
    $_[0] = $_[1];
  }
} #_}
