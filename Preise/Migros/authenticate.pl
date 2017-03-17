#!/usr/bin/perl
use warnings;
use strict;

use HTTP::Cookies;
# use HTTP::Request;
use WWW::Mechanize;
# use JSON;
# use Tree::Simple;

my $cookie_jar = HTTP::Cookies->new(file=>'cookies.dat', autosave=>1);
my $mech = WWW::Mechanize->new(
  agent           => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0',
  cookie_jar      => $cookie_jar,
  default_headers =>  HTTP::Headers->new('Accept-Language'  => 'de; en; *'),
  max_redirect    =>  0,
  autocheck       =>  0  # Don't die if request failes
);


my $request  = HTTP::Request->new('POST' => 'https://authentication.leshop.ch/authentication/public/v1/api/tickets/token');
$request->header('Cookie', 'leshop-tgt=sbbRzv54BJi0VVzU_C7pxvcC_mOdpOHAahZAlq0IqNjQd9KW_9X_tV9evvHi1bLwxn-GUmnwj-S_oWvTbvaGHZP4uRubW5OKcAdPjC-FlBsK9QqYHwpkEjKbyhHbPHfs|MTQ4OTc3NjU0MQ|U0gxQVMxMjhDQkM|ITYBA8l1vLwot_jDO4k6Jw|TJcXFJSzFRF9t9QiqkhOrkKPDys; _ga=GA1.2.861690656.1489776516; leshop-routing=a; GEAR=local-582086d16b0c5a68b10000fd');
my $response = $mech->request($request);
show_http_headers_request_and_response($response);

sub show_http_headers_request_and_response { #_{
  my $response = shift;

# print $response->headers->as_string;

  my $f = sub {
    my $req = shift;
    my $h   = $req->headers;
    for my $header_field_name ($h->header_field_names) {
      printf "    %-50s: %s\n", $header_field_name, $h->header($header_field_name) // '?';
    }
  };

  printf "%s %s\n", $response->request->method, $response->request->uri;
  printf "  %s\n", $response->status_line;

  #################
# return;
  #################

  print "  Request\n";
  &$f($response->request);
  print "  Response\n";
  &$f($response);

} #_}
