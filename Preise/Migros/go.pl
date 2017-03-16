#!/usr/bin/perl
use 5.10.0;
use warnings;
use strict;

use HTTP::Cookies;
use HTTP::Request;
use WWW::Mechanize;
use JSON;
use Tree::Simple;

my $cookie_jar = HTTP::Cookies->new(file=>'cookies.dat', autosave=>1);

my $mech = WWW::Mechanize->new(
  agent           => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0',
  cookie_jar      => $cookie_jar,
  default_headers =>  HTTP::Headers->new('Accept-Language'  => 'de; en; *'),
  max_redirect    =>  0,
  autocheck       =>  0  # Don't die if request failes
);


my $leshopch_token = 
    'eyJsdmwiOiJVIiwiZW5jIjoiQTI1NkdDTSIsImFsZyI6ImRpciIsImtpZCI6IjQyIn0..Gj2s2ZMCOpisIOwP.9mkg11M-zCMBZ3X2AAOmMII3GIZyog9xtsQ5C36z3niIwgdwEuyC0WSE_mnfyF2MdsoWZyKaQhZ77Y7rGc0WogkGpwJeVvTX40d7bqEn9dUjKNLblansGaCk88Iuk8nLXzHwDfdkOjZm6wD2ZKwj5n6Uby-AZrFk7NiovHwX2KPNZbQkQZpbiPtUUMgJkj0gq6o-6tI_OtsCOIzdL9tpbpSqIIp66L28yfdVUQ398NoxhpM_dgo_nw8gz-aIiBSPTTvk50_uFgR84n7uPu7r3rhVBXYzZCv4RM5PfQzwodPzvKiZbEP0GuVY7IwI2e-Qv3OCMg3WQ2AIrDIWCzPdrR5xza8pZdS1Gl_JwuAmxl-TZ8AUCcAcCSIgZTaNWfdZIpZAeV_pWXBLukXfYjEgu08HABIwR6D2tBUDF0MhVLPw9A.GJvQeTPLqS2eT8fMK1Yn_A'
  # 'eyJsdmwiOiJVIiwiZW5jIjoiQTI1NkdDTSIsImFsZyI6ImRpciIsImtpZCI6ImRlZmF1bHQifQ..yis5B69SsNjFoRWJ.ETCnibanQoumCAKl2dawwhL59qo7cQF0r2G42ld5GJm6IpiSH5ni1Rx2sxZI5tFW0s5U6ItQ2yognyHWOF9Y143fgQegE1UFj1nCi4yOS2e2IZN1-UxIT4BoOmhxbrj7y85__2rxnqeXMkaDsk5Dkdm0LmvbthIV7F6h6Jhdz_OqJvYNzGRS2BQtj_1sSgzPC0c6z2tdTXRwOXxqIsL0vyt1ukEv0NNKAI7HcewgaLYPTa8irLuQrcbwtg62jSNmKfm2ZAGbAe94twwQHczM5lE1SInMtcT4giz_lRPUq7A-Rwz9NoDvs5kH6_ZW3lN6u6aLpeGLJ62W0qXwhut7z8Oquu6GNJAJx9XcsAg6jK2-Qsj5BG58D-5notYHKOwVbIBJSzTdgciOHq3Nt5pNdaLmoKmNYyPCfEGwu8PeRfvKGA.73ThZaH8OXztWKRQCkY5JA';
  # 'eyJsdmwiOiJVIiwiZW5jIjoiQTI1NkdDTSIsImFsZyI6ImRpciIsImtpZCI6IjQyIn0..8giY8Tk_tXxU4H4J.97u0ikyCWyJVLTh34ReYCx2tLaVAx5Kb1t-z8BrXq4eO000HkYry6tGtdD3VQ1bwaE07a6quXbm3z0emvWNyUuxPvrFPL-xHdYs6ZEcntcizMeuL-9qTC0huTvAYNad3Xh2Cms7gcj-_iBF1eaZegx3F2hH7dzfpBNe-EnhOLLGVPqrN_-HzTYOuMDacSDErkC6jv5tjVAxOplwihjDfBv1srrC6RsHq9pda36XBTdzUMAqUGTZaBrBjPzhhrVYpwzlQo5KuH48ZvWVTzx9QCeQgVD-PYFQVU9LtE7TNev8dp78ruEtu5-bnkOipKmuit5qpTSWAFHbHOOe5mveJRg_Y_xE-eEqRD7lIPKqXcrMFhuUpHzsMnq-D86YOCZcEEN1LwXB5JfdTd_aiDNT5N1a266nnOKkaS7k5fFrzc3U2eQ.uZgd62jrEr0YJTxZT2Uyyg');
;

my $cookie = 
  'leshop-tgt=j4OEzOQMamBefH5MHqR097YBvlVhLFLoS8b8bxvHXE4giTXZPoCkwDYCIN_jPh5rm9MiIi1WO-WPkyhNxvHG27PsmOOHtL8gMvVOLBORdfMNE3stKg8-mWJjXpmfGND0|MTQ4OTU2OTg1Mg|U0gxQVMxMjhDQkM|DlU_osREzit212MzUYPTug|ismPsICHMuMEjmEPIfe2b-QtyGA; _ga=GA1.2.1505309499.1489569859; leshop-routing=a; GEAR=58208fa837425a95150000a1-prod; _gat=1'
#                                                                                                                                                                                                                                '_ga=GA1.2.1505309499.1489569859; leshop-routing=a; GEAR=local-58208e2dcf67b62bc20000d7';
# 'leshop-tgt=j4OEzOQMamBefH5MHqR097YBvlVhLFLoS8b8bxvHXE4giTXZPoCkwDYCIN_jPh5rm9MiIi1WO-WPkyhNxvHG27PsmOOHtL8gMvVOLBORdfMNE3stKg8-mWJjXpmfGND0|MTQ4OTU2OTg1Mg|U0gxQVMxMjhDQkM|DlU_osREzit212MzUYPTug|ismPsICHMuMEjmEPIfe2b-QtyGA; _ga=GA1.2.1505309499.1489569859; leshop-routing=a; GEAR=58208fa837425a95150000a1-prod; _gat=1'
;

# my $request  = HTTP::Request->new('GET' => 'https://authentication.leshop.ch/authentication/public/v1/api/validate');
# $request -> header('leshopch', 'eyJsdmwiOiJVIiwiZW5jIjoiQTI1NkdDTSIsImFsZyI6ImRpciIsImtpZCI6IjQyIn0..8giY8Tk_tXxU4H4J.97u0ikyCWyJVLTh34ReYCx2tLaVAx5Kb1t-z8BrXq4eO000HkYry6tGtdD3VQ1bwaE07a6quXbm3z0emvWNyUuxPvrFPL-xHdYs6ZEcntcizMeuL-9qTC0huTvAYNad3Xh2Cms7gcj-_iBF1eaZegx3F2hH7dzfpBNe-EnhOLLGVPqrN_-HzTYOuMDacSDErkC6jv5tjVAxOplwihjDfBv1srrC6RsHq9pda36XBTdzUMAqUGTZaBrBjPzhhrVYpwzlQo5KuH48ZvWVTzx9QCeQgVD-PYFQVU9LtE7TNev8dp78ruEtu5-bnkOipKmuit5qpTSWAFHbHOOe5mveJRg_Y_xE-eEqRD7lIPKqXcrMFhuUpHzsMnq-D86YOCZcEEN1LwXB5JfdTd_aiDNT5N1a266nnOKkaS7k5fFrzc3U2eQ.uZgd62jrEr0YJTxZT2Uyyg');
# $request -> header('Cookie'  , 'leshop-tgt=j4OEzOQMamBefH5MHqR097YBvlVhLFLoS8b8bxvHXE4giTXZPoCkwDYCIN_jPh5rm9MiIi1WO-WPkyhNxvHG27PsmOOHtL8gMvVOLBORdfMNE3stKg8-mWJjXpmfGND0|MTQ4OTU2OTg1Mg|U0gxQVMxMjhDQkM|DlU_osREzit212MzUYPTug|ismPsICHMuMEjmEPIfe2b-QtyGA; _ga=GA1.2.1505309499.1489569859; leshop-routing=a; GEAR=58208fa837425a95150000a1-prod; _gat=1');
# do_request($request);



goto XXXXX;

# my $request = HTTP::Request->new('GET' => 'https://catalog.leshop.ch/catalog/public/v1/api/compatibility/products/125531,215771,230738,62966,215888,205839,59029,49960,9902,229247,98077,215889,94678,70794,3501895,130507,112821,221697,3378442,142094,126632,3313519,225714,225087,104596,3534691,16380,46526,65147,125901,3505600,78984,98026,98749,3321740,3004264,227552,3155517,59479?language=de&shortVersion=true');
# my $request = HTTP::Request->new('GET' => 'https://catalog.leshop.ch/catalog/public/v1/api/compatibility/prices/125531,215771,230738,62966,215888,205839,59029,49960,9902,229247,98077,215889,94678,70794,3501895,130507,112821,221697,3378442,142094,126632,3313519,225714,225087,104596,3534691,16380,46526,65147,125901,3505600,78984,98026,98749,3321740,3004264,227552,3155517,59479/warehouses/2');
  my $request = HTTP::Request->new('GET' => 'https://catalog.leshop.ch/catalog/public/v1/api/compatibility/lightCategories?language=de');
$request -> header('leshopch', $leshopch_token);
$request -> header('Cookie'  , );
my $content_catalog = do_request($request);

open (my $out, '>:encoding(utf-8)', "$ENV{digitales_backup}crawler/Preise/Migros/wgetted/catalog.json") or die;
print $out $content_catalog;
close $out;

XXXXX:

my $json = read_json_file("$ENV{digitales_backup}crawler/Preise/Migros/wgetted/catalog.json") or die;

my $tree = build_catalog_tree($json);

$tree->traverse(sub {
  my $node = shift;
  my $v = $node->getNodeValue();
  print '  ' x $node->getDepth() . $v -> {name} . ' ' . $v->{id} . ' ' . $v->{parentId} . ' ' . $v->{undevilerability}. "\n";

});


# my $request  = HTTP::Request->new('POST' => 'https://authentication.leshop.ch/authentication/public/v1/api/tickets/token');
# $request = HTTP::Request->new('GET' => 'https://authentication.leshop.ch/authentication/public/v1/api/guest?rememberme=true');
# $request -> header('origin'   , 'https://www.leshop.ch/');
# $request -> header('referer'  , 'https://www.leshop.ch/');
# $request -> header('Mime-Type', 'application/json');


sub do_request { #_{

  my $request  = shift;
  my $response = $mech->request($request);
  show_http_headers_request_and_response($response);

# print $response->content;
  return $response->decoded_content;


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
  printf "  %s\n", $response->status_line;

  #################
  return;
  #################

  print "  Request\n";
  &$f($response->request);
  print "  Response\n";
  &$f($response);

} #_}

sub read_json_file { #_{
  my $filename = shift;
  open (my $in, '<:encoding(utf-8)', $filename) or die;
  my $json_text = join '', <$in>;
  close $in;

  return from_json($json_text);
  
} #_}

sub build_catalog_tree {

  my $json_catalog = shift;

  my $tree = Tree::Simple->new('root');


  my $get_or_make_tree = sub { #_{
    state %trees_seen;
    my $id = shift;

    return $tree if $id == 0;

    my $tree_;
    if (exists $trees_seen{$id}) {
      $tree_ = $trees_seen{$id};
    }
    else {
      $tree_ = Tree::Simple->new('?'); 
      $trees_seen{$id} = $tree_;
    }

    return $tree_;

  }; #_}

  for my $id (keys %$json) {
  
#   if ($id > 0) {
  
      my $parentId  = $json->{$id}{parentId} // '';
      my $name      = $json->{$id}{name}{de};

      my $undevilerability = 0;

      $undevilerability = 1 if exists $json->{$id}{undeliverability};

#     $name .= " ($id -> $parentId )";

#     my $parent_tree = &$get_or_make_tree($parentId);
      my $cur_tree    = &$get_or_make_tree($id);
      $cur_tree->setNodeValue({name => $name, id=>$id, parentId=>$parentId, undevilerability=>$undevilerability});

      for my $child (@{$json->{$id}{categories}}) {
        my $child_tree = &$get_or_make_tree($child);

        $cur_tree->addChild($child_tree);

#     }
  
#     $parent_tree->addChild($cur_tree);
  
  #   my $ids_seen{$k} = Tree::Simple->new($json->{$k}{name}{de};
  
  
  #   if (my $parent_tree = $ids_seen{}) {
  #     $parent_tree->addChild($ids_seen{$k});
  #   }
  #   else {
  #     $ids_seen{$json->{$k}{parentId}} = Tree::Simple->new{
  #     Tree::Simple->new($json->{$k}{name}{de});
  #   }
  
  #   die unless $ids_seen{$json->{$k}{parentId}};
  #   print ": Parent : ", $json->{$k}{parentId};
    }
#   else {
#     $ids_seen{0} = $tree;
#   }
  # print "\n";
  }


  return $tree;

}
