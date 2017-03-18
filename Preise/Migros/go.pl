#!/usr/bin/perl
use utf8;
use Encode;
binmode(STDOUT, ":utf8");

my $print_ids = 1;

#
#   https://catalog.leshop.ch/catalog/public/v1/api/compatibility/categories/35961,29154?language=de
#     {"29154":{"id":29154,"parentId":25131,"name":{"de":"Milch"},"slug":{"de":"milch"},"sortPriority":1,"path":"/Le Shop/Map_Dairy/Dairy/Milk","categories":[29160,29156,29159,34206,29580,35961],"displayPromotionsOnly":false},
#      "35961":{"id":35961,
#               "parentId":29154,
#               "name":{"de":"Kondensmilch"},
#               "slug":{"de":"kondensmilch"},
#               "sortPriority":6,
#               "path":"/Le Shop/Map_Dairy/Dairy/Milk/Condensedmilk"
#               ,"productsUndeliverabilities":{
#                  "51572":{},
#                  "217413":{"warehouses":[1]}},
#                  "displayPromotionsOnly":false}
#      }
#
#   https://catalog.leshop.ch/catalog/public/v1/api/compatibility/products/51572,217413?language=de&shortVersion=true
#   https://catalog.leshop.ch/catalog/public/v1/api/compatibility/prices/51572,217413/warehouses/2
#
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
'eyJsdmwiOiJVIiwiZW5jIjoiQTI1NkdDTSIsImFsZyI6ImRpciIsImtpZCI6ImRlZmF1bHQifQ..TJ67skeyWV2_160V.6zXt1TuSvHMBSRaCQQrkQ3OBGBRcge4IyY5_aM6AZEwTZqMX58REFvDnb1Qj2O1o_d22k8iW5TdT4L0PuuZORk0WXk_a3gjAqxtHrw3q5Lx54GNksd1Lq6kZq-_hRFHl_4rTdMiy80W0mUTcky_98bogud54sum_v-BHHByh4IHxdaT1r4P3_abSCeOlBr_xV3bMiJDIlDVmaVgvUTnDAub5bu5Ty7jASbwyCT48LdZQBEZemFSpZt06nFNdOIjPJn4RJzwFMJeieYsqetnztD41uLN1UX7ciTfPb0xA9AR4DmY8aUd5oGpvu64EaBzRaGc-gzYY9cxz2FzQLzAiwT8fBcfPyk4JRx6fei9atGmv0cr2FGzftn3_LX-DltBLJ0IAcrApQ_MjJy6nrNGeDxSdy4NQ-oyqqJ7CXeuWpsb3yw.87qDps1D2KwvvEvKjZlHzw'
;

my $cookie = 
  'leshop-tgt=j4OEzOQMamBefH5MHqR097YBvlVhLFLoS8b8bxvHXE4giTXZPoCkwDYCIN_jPh5rm9MiIi1WO-WPkyhNxvHG27PsmOOHtL8gMvVOLBORdfMNE3stKg8-mWJjXpmfGND0|MTQ4OTU2OTg1Mg|U0gxQVMxMjhDQkM|DlU_osREzit212MzUYPTug|ismPsICHMuMEjmEPIfe2b-QtyGA; _ga=GA1.2.1505309499.1489569859; leshop-routing=a; GEAR=58208fa837425a95150000a1-prod; _gat=1'
;




do_request('GET', 'https://catalog.leshop.ch/catalog/public/v1/api/compatibility/lightCategories?language=de', 'catalog.json');

# do_request('GET', 'https://catalog.leshop.ch/catalog/public/v1/api/compatibility/categories/35961?language=de', 'cat-35961');



# XXXXX:

my $json = read_wgetted_json_file('catalog.json') or die;

my $tree = build_catalog_tree($json);

#_{ Get »le Shop« tree
my $le_shop_tree;
for my $cat ($tree->getAllChildren()) {
# print $cat->getNodeValue()->{name}, "\n";
  if ($cat->getNodeValue()->{name} eq 'Le Shop') {
#   print "yep\n";
    $le_shop_tree = $cat->clone();
    last;
  }
}
 #_}

#_{ Remove »undeliverable« categery
my @undeliverables_to_remove;
for my $cat ($le_shop_tree->getAllChildren()) {
  my $v = $cat->getNodeValue();
  if ($v->{undevilerability}) {
    push @undeliverables_to_remove, $cat;
#   print "Remove $v->{name}\n";
  }
  else {
#   print "Keep $v->{name}\n";
  }
}

$le_shop_tree->removeChild($_) for (@undeliverables_to_remove);
#_}

$le_shop_tree->traverse(sub { #_{ Download price and catalog items
  my $node = shift;

  if ($node->isLeaf()) { #_{
    my $v = $node->getNodeValue();
    my $cat=$v->{id};
    do_request('GET', "https://catalog.leshop.ch/catalog/public/v1/api/compatibility/categories/$cat?language=de", "cat-$cat");

    my $json_cat = read_wgetted_json_file("cat-$cat");

    for my $prod_id (keys %{$json_cat->{$cat}->{productsUndeliverabilities}}) {

      do_request('GET', "https://catalog.leshop.ch/catalog/public/v1/api/compatibility/products/$prod_id?language=de&shortVersion=true", "prod-$prod_id");
      do_request('GET', "https://catalog.leshop.ch/catalog/public/v1/api/compatibility/prices/$prod_id/warehouses/2", "prod-$prod_id-price");

      my $json_prod        = read_wgetted_json_file("prod-$prod_id"      )->{$prod_id};
      my $json_prod_price  = read_wgetted_json_file("prod-$prod_id-price")->{$prod_id};

      $node -> generateChild(
          {name     =>$json_prod->{name}{de},
           nof_units=>$json_prod->{numberOfUnits},
           id       =>$prod_id,
           prod     =>1,
           price    => {min      => $json_prod_price->{price}{minimum},
                        max      => $json_prod_price->{price}{maximum},
                        est      => $json_prod_price->{price}{estimated},
                        exact    => $json_prod_price->{price}{exact},
                        unit     => $json_prod_price->{unitPrice}{unit},
                        per_unit => $json_prod_price->{unitPrice}{price} },
           active   => $json_prod_price->{active}

         });

    }


  } #_}

}); #_}

#_{ Print to HTML
open (my $out, '>:encoding(utf-8)', '../Migros.html') or die; #_{
  print $out "<html><head>
    <meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
    <meta name='description' content='Preisliste Migros'>
    <title>Preisliste Migros</title>

    <style type='text/css'> 
    .r0 {background-color:#ffffe7;}
    .r1 {background-color:#ffe7ff;}
    .st {color: #777;}
    </style>

  </head><body>
  <h1>Preisliste Coop</h1>";
  print $out "<pre><code>"
  ; #_}

my $r = 0;
$le_shop_tree->traverse(sub { #_{

  my $node = shift;
  my $v = $node->getNodeValue();

  my $id = '';
  if ($print_ids) {
    $id = "ID: $v->{id}";
  }

  if ($v->{prod}) {

     $r = 1-$r;
     print $out "<span class='r$r'>";


     print  $out " " x 10;

     my $price;
     if ($v->{price}{exact}) {
       $price = sprintf "    %7.2f", $v->{price}{est}
     }
     else {
       $price = sprintf("ca. %7.2f (%0.2f-%0.2f)", $v->{price}{est}, $v->{price}{min}, $v->{price}{max});
     }

     $v->{price}{unit} = 'St.' if $v->{price}{unit} eq 'piece';

#    printf $out "%-120s | %2d Stück: %7.2f %7.2f %7.2f (%1s) | %7.2f/%-5s | %-5s $id",
     printf $out "%-120s | <span class='st'>%2i Stück:</span> %-26s | %7.2f/%-5s $id",
             $v->{name}, $v->{nof_units}, $price, $v->{price}{per_unit}, $v->{price}{unit}
#                          $v->{nof_units}, 
#                                $v->{price}{min},
#                                      $v->{price}{max},
#                                            $v->{price}{est},
#                                                   $v->{price}{exact},
#                                                           $v->{price}{per_unit},
#                                                                 $v->{price}{unit},
#                                                                        $v->{active}
                                                                        ;
      

#    if ($v->{price}{min} != $v->{price}{max}  or
#        $v->{price}{min} != $v->{price}{est}) {

#        print $out " * oh oh *";
#    
#    }
     print $out "</span>";

  }
  else {
# print '  ' x $node->getDepth() . $v -> {name} . ' ' . $v->{id} . ' ' . $v->{parentId} . ' ' . $v->{undevilerability}. "\n";
# print '  ' x $node->getDepth() . $v -> {name} . ' ' . $v->{id} . "\n";


    print $out '  ' x $node->getDepth() . $v -> {name} . "  $id"; #              . "\n";
  }
  print $out "\n";

}); #_}

print $out "</pre></code>\n";
print $out "<p>
Vgl <a href='Coop.html'>Preisliste Coop</a>

</html>";

#_}

sub do_request { #_{

  my $method       = shift;
  my $url          = shift;
# my $request      = shift;
  my $wgetted_file = shift;

  my $archive_file = "$ENV{digitales_backup}crawler/Preise/Migros/wgetted/$wgetted_file";
  return if -f $archive_file;

  print "$method $url -> $archive_file\n";

  my $request = HTTP::Request->new($method, $url);
  $request -> header('leshopch', $leshopch_token);
  $request -> header('Cookie'  , );

  my $response = $mech->request($request);
# show_http_headers_request_and_response($response);

  open (my $out, '>:encoding(utf-8)', $archive_file) or die;
  print $out decode("utf-8", $response->decoded_content);
  close $out;


# print $response->content;
# return $response->decoded_content;


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

sub read_wgetted_json_file { #_{
  my $filename = shift;
  my $archived_file = "$ENV{digitales_backup}crawler/Preise/Migros/wgetted/$filename";
  open (my $in, '<:encoding(utf-8)', $archived_file) or die;
  my $json_text = join '', <$in>;
  close $in;

  my $json;
  eval {
    $json = from_json($json_text);
  };
  if ($@) {
     unlink $archived_file;
     die "$archived_file seemed not to be a JSON file";
  }

  if (exists $json->{'leshop-error'}) {

    system "cat $archived_file";

    unlink $archived_file;
    die "leshop-error for $archived_file\n";
  }

  return $json;
  
} #_}

sub build_catalog_tree { #_{

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

  for my $id (keys %$json) { #_{
  
      my $parentId  = $json->{$id}{parentId} // '';
      my $name      = $json->{$id}{name}{de};

      my $undevilerability = 0;

      $undevilerability = 1 if exists $json->{$id}{undeliverability};


      my $cur_tree    = &$get_or_make_tree($id);
      $cur_tree->setNodeValue({name => $name, id=>$id, parentId=>$parentId, undevilerability=>$undevilerability});

      for my $child (@{$json->{$id}{categories}}) {
        my $child_tree = &$get_or_make_tree($child);

        $cur_tree->addChild($child_tree);

      }

  } #_}
  return $tree;

} #_}
