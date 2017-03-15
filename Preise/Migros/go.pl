#!/usr/bin/perl
use warnings;
use strict;

use HTTP::Cookies;
use HTTP::Request;
use WWW::Mechanize;

my $cookie_jar = HTTP::Cookies->new(file=>'cookies.dat', autosave=>1);

my $mech = WWW::Mechanize->new(
  agent           => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0',
  cookie_jar      => $cookie_jar,
  default_headers =>  HTTP::Headers->new('Accept-Language'  => 'de; en; *'),
  max_redirect    =>  0,
  autocheck       =>  0  # Don't die if request failes
);




my $request  = HTTP::Request->new('GET' => 'https://authentication.leshop.ch/authentication/public/v1/api/validate');
$request -> header('leshopch', 'eyJsdmwiOiJVIiwiZW5jIjoiQTI1NkdDTSIsImFsZyI6ImRpciIsImtpZCI6IjQyIn0..8giY8Tk_tXxU4H4J.97u0ikyCWyJVLTh34ReYCx2tLaVAx5Kb1t-z8BrXq4eO000HkYry6tGtdD3VQ1bwaE07a6quXbm3z0emvWNyUuxPvrFPL-xHdYs6ZEcntcizMeuL-9qTC0huTvAYNad3Xh2Cms7gcj-_iBF1eaZegx3F2hH7dzfpBNe-EnhOLLGVPqrN_-HzTYOuMDacSDErkC6jv5tjVAxOplwihjDfBv1srrC6RsHq9pda36XBTdzUMAqUGTZaBrBjPzhhrVYpwzlQo5KuH48ZvWVTzx9QCeQgVD-PYFQVU9LtE7TNev8dp78ruEtu5-bnkOipKmuit5qpTSWAFHbHOOe5mveJRg_Y_xE-eEqRD7lIPKqXcrMFhuUpHzsMnq-D86YOCZcEEN1LwXB5JfdTd_aiDNT5N1a266nnOKkaS7k5fFrzc3U2eQ.uZgd62jrEr0YJTxZT2Uyyg');
$request -> header('Cookie'  , 'leshop-tgt=j4OEzOQMamBefH5MHqR097YBvlVhLFLoS8b8bxvHXE4giTXZPoCkwDYCIN_jPh5rm9MiIi1WO-WPkyhNxvHG27PsmOOHtL8gMvVOLBORdfMNE3stKg8-mWJjXpmfGND0|MTQ4OTU2OTg1Mg|U0gxQVMxMjhDQkM|DlU_osREzit212MzUYPTug|ismPsICHMuMEjmEPIfe2b-QtyGA; _ga=GA1.2.1505309499.1489569859; leshop-routing=a; GEAR=58208fa837425a95150000a1-prod; _gat=1');
do_request($request);


# my $request  = HTTP::Request->new('POST' => 'https://authentication.leshop.ch/authentication/public/v1/api/tickets/token');
# my $response = $mech->request($request);
# show_http_headers_request_and_response($response);
# print $response->content;

# print "\n\n";

# $request = HTTP::Request->new('GET' => 'https://authentication.leshop.ch/authentication/public/v1/api/guest?rememberme=true');
# $request -> header('origin'   , 'https://www.leshop.ch/');
# $request -> header('referer'  , 'https://www.leshop.ch/');
# # $request -> header('Mime-Type', 'application/json');
# $response = $mech->request($request);
# show_http_headers_request_and_response($response);
# print $response->content;


sub do_request { #_{

  my $request  = shift;
  my $response = $mech->request($request);
  show_http_headers_request_and_response($response);

# print $response->content;
  print $response->decoded_content;


  print "\n\n";

} #_}


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
# print "HTTP Headers\n";
  printf "  %s\n", $response->status_line;
  print "  Request\n";
  &$f($response->request);
  print "  Response\n";
  &$f($response);

} #_}
