#!/usr/bin/perl
use warnings;
use strict;

use LWP::UserAgent;
use HTML::Parser;
use Text::Wrap;
use URI;


my $url = shift;



my $user_agent = LWP::UserAgent->new (
  timeout         =>  10,
  agent           => 'TQ',
  default_headers =>  HTTP::Headers->new('Accept-Language'  => 'de; en; *'),
);

my $html_parser = HTML::Parser->new(
  start_h       => [\&hp_start_tag  , 'tag, attr, text'  ],
  end_h         => [\&hp_end_tag    , 'tag'              ],
  text_h        => [\&hp_text       , 'text'             ],
  comment_h     => [\&hp_comment    , 'text'             ],
  default_h     => [\&hp_default    , 'text'             ],
  process_h     => [\&hp_process    , 'text'             ],
  declaration_h => [\&hp_declaration, 'text'             ],
);

$Text::Wrap::columns  = 120;
$Text::Wrap::unexpand =   0;

my $uri_ = URI->new($url) or die;
page ($uri_->scheme, $uri_->host, $uri_->path);

# topLevelDomain($host);

my %g_page_info;

sub topLevelDomain { #_{
  my $scheme = shift;
  my $host   = shift;
  page($scheme, $host, '/');

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

  my $scheme = shift;
  my $host    = shift;
  my $path   = shift;

  my $url  = "$scheme://$host$path";

  print "url = $url\n";

  my $http_response = $user_agent -> request(
       HTTP::Request -> new (GET=>$url)
  );

  my $content = $http_response->content;
# show_http_headers($http_response->headers);

# print $content;

  %g_page_info = (
     url => $url
  );
  $html_parser->parse($content);
  $html_parser->eof;

  print "\n\n";
  printf "title:       %s\n", $g_page_info{title}             // 'n/a';
  printf "language:    %s\n", $g_page_info{lang}              // 'n/a';
  printf "charset:     %s\n", $g_page_info{meta}{charset    } // 'n/a';
  printf "robots:      %s\n", $g_page_info{meta}{robots     } // 'n/a';
  printf "generator:   %s\n", $g_page_info{meta}{generator  } // 'n/a';
  printf "keywords:    %s\n", wrap('', '             ', $g_page_info{meta}{keywords   } // 'n/a');
  printf "description: %s\n", $g_page_info{meta}{description} // 'n/a';

  for my $link (@{$g_page_info{a}}) {
     printf("  %-5s %-30s %4d %-50s %-20s %s\n", 
       $link->{dest}->{scheme} // 'n/a',
       $link->{dest}->{host  }, 
       $link->{dest}->{port  }, 
       $link->{dest}->{path  }, 
       $link->{dest}->{query } // '',
       $link->{text}
     );
  }

  for my $todo (@{$g_page_info{TODO}}) {
    printf "TODO $todo\n";
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

sub show_http_headers { #_{
  my $http_headers = shift;

  for my $header_field_name ($http_headers->header_field_names) {
    printf "%-30s: %s\n", $header_field_name, $http_headers->header($header_field_name);
  }

} #_}

#_{ HTML Parser methods

sub hp_text { #_{
    my ($text) = @_;
    $text =~ s/\n//g;

    if ($g_page_info{in_title}) {
      $g_page_info{title} .= $text;
    }
    elsif ($g_page_info{cur_a}) {
      $g_page_info{cur_a}{text} .= $text;
    }
    else {

      if ($text =~ /(\w+str(?:asse|\.))\s+(\w*\d\w*)/) {
        print "Strasse: $1 $2\n";
#       print "Strasse: $text\n";
      }
      if ($text =~ /\b(\d\d\d\d)\s+(\w+)/) {
#       print "Ort: $1 $2\n";
        print "Ort: $text\n";
      }
      if ($text =~ /\b(\d\d\d \d\d\d \d\d \d\d)/) {
        print "Tel: $1\n";
#       print "Tel: $text\n";
      }
      if ($text =~ /(\+\d\d \d\d \d\d\d \d\d \d\d)/) {
        print "Tel: $1\n";
#       print "Tel: $text\n";
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
          push @{$g_page_info{TODO}}, "Unknown meta name $name ($content)";
        }
      } #_}
      elsif (my $charset = $attr->{charset}) {
         $g_page_info{meta}{charset} = $charset;
      }
      else {
          push @{$g_page_info{TODO}}, "Unknown meta tag $text";
      }


    } #_}
    elsif ($tag eq 'a'    ) { #_{

      my $dest = URI->new_abs($attr->{href}, $g_page_info{url});

      my $dest_uri = URI->new($dest);

      $g_page_info{cur_a} = {# dest=>$dest,
                             dest => {
                               scheme => $dest_uri->scheme,
                               host   => $dest_uri->host  ,
                               port   => $dest_uri->port  ,
                               path   => $dest_uri->path  ,
                               query  => $dest_uri->query 
                             },
                             text=>''};

    } #_}
    elsif ($tag eq 'title') { #_{

      $g_page_info{in_title} = 1;
      $g_page_info{title} = '';

    } #_}
    elsif ($tag eq 'html' ) { #_{

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
      push @{$g_page_info{a}}, $g_page_info{cur_a};
      $g_page_info{cur_a} = undef;
    }

} #_}

sub hp_default { #_{
    my ($text) = @_;
} #_}

sub hp_process { #_{
    my ($text) = @_;
} #_}

sub hp_declaration { #_{
    my ($text) = @_;
} #_}

#_}
