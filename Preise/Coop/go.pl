#!/usr/bin/perl
use warnings;
use strict;
use LWP::Simple;
use JSON;
use HTML::Parser;
use Tree::Create::DepthFirst;
# use Tree::Simple::View::HTML;
use utf8;
binmode(STDOUT, ':utf8');

my $first_cur;

my $top_dir     = "$ENV{digitales_backup}crawler/Preise/Coop/";
my $wgetted_dir = "${top_dir}wgetted/";
die "directory $wgetted_dir missing" unless -d $wgetted_dir;

my $product_tree = Tree::Simple->new('Products');
my @top_level_categories = determine_top_level_categories();

open (my $out, '>:encoding(utf-8)', '../Coop.html') or die;
  print $out "<html><head>
    <meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
    <meta name='description' content='Preisliste Coop'>
    <title>Preisliste Coop</title>

    <style type='text/css'> 
    </style>

  </head><body>
  <h1>Preisliste Coop</h1>
  <pre><code>";

for my $category (@top_level_categories) { #_{
   do_menu_of_top_level_category(link_to_last_part($category->{href}), $category);
} #_}

my $in_red_or_whitewine = 0;
my $in_online_butcher   = 0;
my $in_rezepte          = 0;
$product_tree->traverse(sub { #_{
     my $node = shift;

     my $name = $node->getNodeValue()->{name};
     my $href = $node->getNodeValue()->{href};
#    printf("%-50s %s\n", '  ' x $node->getDepth() . $name, substr($href, 1,190) );
     printf $out ("%-50s\n"   , '  ' x $node->getDepth() . $name );

     if ($node->getDepth() == 1) { #_{

       if ($name eq 'Rotwein' or $name eq 'Weisswein') { #_{
         $in_red_or_whitewine = 1;
         $in_online_butcher   = 0;
         $in_rezepte          = 0;
       } #_}
       elsif ($name eq 'Ihr Online Metzger') { #_{
         $in_red_or_whitewine = 0;
         $in_online_butcher   = 1;
         $in_rezepte          = 0;
       } #_}
       elsif ($name eq 'Rezepte') { #_{
         $in_red_or_whitewine = 0;
         $in_online_butcher   = 0;
         $in_rezepte          = 1;
       } #_}
       else { #_{
         $in_red_or_whitewine = 0;
         $in_online_butcher   = 0;
         $in_rezepte          = 0;
       } #_}

     } #_}
     if ($node->isLeaf()) { #_{


       if (not $in_red_or_whitewine and not $in_online_butcher and not $in_rezepte) {
         do_product_details($href);
       }
       else {
         if ($name =~ /^Alle /) {
           do_product_details($href);
         }
       }

     } #_}
 }); #_}

print $out "</code></pre><body></html>";
close $out;



sub do_product_details { #_{

  my $href = shift;

  my ($menu_link, $local_file)=href_to_menu_link($href, 0); 

  download_link_if_necessary_with_specification_of_local_file($menu_link, $local_file);
  unless (-e $local_file) {
    print "! Could not download $menu_link to $local_file\n";
    return;
  }

  my $json = file_to_json($local_file);

# print "Number of pages: " . $json->{pagination}->{numberOfPages} . "\n";

  my $nof_pages = $json->{pagination}->{numberOfPages};

  for my $page_no (1 .. $nof_pages -1) {
    my ($menu_link, $local_file)=href_to_menu_link($href, $page_no); 
    download_link_if_necessary_with_specification_of_local_file($menu_link, $local_file);
  }

  parse_prices_from_json($href, $nof_pages);

} #_}

sub parse_prices_from_json { #_{

  my $href      = shift;
  my $nof_pages = shift;

  for my $page_no  ( 0 .. $nof_pages-1) {
    my ($dummy_menu_link, $local_file)=href_to_menu_link($href, $page_no); 

    die unless -e $local_file;


    my $in_h2=0;
    my $in_a =0;
    my $in_dt=0;
    my $in_dd=0;
    my $in_span_itemprop_value = 0;
    my $current_article = '';
    my $price = 0;
    my $price_per_quantity = '';
    my $price_instead = '';
    my $rebate_from = '';
    my $value       = '';

    my $expect_dt_price          = 0;
    my $expect_dt_price_quantity = 0;
    my $expect_dt_price_instead  = 0;
    my $expect_dd_price = 0;
    my $expect_dd_price_quantity = 0;
    my $quantity                 = 0;
    
    my $parser = HTML::Parser->new(
      start_h       => [ sub { #_{

        my ($tag, $attr) = @_;

          if ($tag eq 'h2') { #_{
             $in_h2 = 1;
             $expect_dt_price_quantity = 0;
             $expect_dd_price_quantity = 0;
             $price_per_quantity = '';
          } #_}
          if ($tag eq 'a') { #_{
             $in_a = 1;
          } #_}
          if ($tag eq 'dl') { #_{
            die "attr class = $attr->{class}" unless $attr->{class} eq 'product-item__price';
            $expect_dt_price = 1;
          } #_}
          if ($tag eq 'dt') { #_{
             $in_dt = 1;

             if ($attr->{class} eq 'product-item__price__label product-item__price__value--save') {
               $expect_dt_price_instead = 1;
             }
             else {
               $expect_dt_price_instead = 0;

               if ($attr -> {class} eq 'product-item__price__label visuallyhidden') {
                 unless ($expect_dt_price) {
                   $expect_dd_price_quantity = 1;
                 }
               }
               else{
                 die;
               }
             }

          } #_}
          if ($tag eq 'dd') { #_{
             $in_dd = 1;
          } #_}
          if ($tag eq 'span') { #_{
            if ($attr->{itemprop} // '' eq 'value') {
              $in_span_itemprop_value = 1;
            }
          } #_}


      },
        
      'tag, attr'],  #_}
      end_h         => [ sub { #_{
        my $tag = shift;

      
        if ($tag eq '/h2') {
           $in_h2 = 0;
        }
        if ($tag eq '/a') {
           $in_a  = 0;
        }
        if ($tag eq '/dt') {
           $in_dt  = 0;
        }
        if ($tag eq '/dd') {
           $in_dd  = 0;
        }
        if ($tag eq '/span') {
           $in_span_itemprop_value  = 0;
        }
      
      },
      'tag'      ], #_}
      text_h        => [ sub { #_{
        my $text = shift;

        if ($in_h2 and $in_a) { #_{
           $current_article = $text;
           $price_instead   = '';
           $rebate_from = '';
           $value = '';
        } #_}

        if ($in_dt) { #_{

          if ($expect_dt_price) {

            die ">$text<" unless $text eq 'Preis';
            $expect_dt_price = 0;
            $expect_dd_price = 1;

          }
          elsif ($expect_dt_price_instead) {


            if ($text =~ m,statt (\d+\.\d\d)$,) {
              $price_instead = $price;
              $price = $1;

            }
            elsif ($text =~ m,Rabatt ab (\d+)$,) {
               $rebate_from = $1;
            }
            elsif ($text =~ m,Wert (\d+\.\d\d)$,) {
               $value = $1;
            }
            else {
              die ">$text<" unless $text =~ m,statt (\d+\.\d\d)$,;
            }

          }
          elsif ($expect_dt_price_quantity) {
            if ($text =~ m,Preis pro (.*)$,) {
               $expect_dt_price_quantity = 1;
            }
            else {
#             die ">$text<\n";;
            }

          }


        } #_}
        if ($in_dd) { #_{

          if ($expect_dd_price) {
            die ">$text<" unless $text =~ m/^\d+\.\d\d/;
            $price = $text;
            $expect_dd_price = 0;
#           print "                      $current_article  $price\n";
          }
          elsif ($expect_dd_price_quantity) {

            if ($text =~ m,(\d+\.\d\d/.*),) {

              $price_per_quantity = $1;

              my $line = sprintf "%25s %-85s", '', $current_article;

              my $price = sprintf "%7.2f", $price;

              if ($price_instead) {
                 $line .= "<del>$price</del>";
                 $line .= sprintf "  %7.2f ", $price_instead;
              }
              else {
                 $line .= $price . "          ";
              }
              $line .= " " . $price_per_quantity;

              print $out "$line\n";
#             printf $out "                          %-85s   %7.2f  %s  %s\n", $current_article, $price, $price_instead, $price_per_quantity;

#             print "$price_per_quantity\n";
            }

          }
        } #_}

        if ($in_span_itemprop_value) { #_{

# print ">$text<\n";
#         die ">$text<" unless $text =~ /(\d+)/;

#         $quantity = $1;
#         print $quantity, "\n";

        } #_}


       },
       'text'     ], #_} 
    );

    my $json = file_to_json($local_file);
    $parser -> parse($json->{productListerHTML});


#   print $json->{productListerHTML};
#   exit;
  }

} #_}

sub determine_top_level_categories { #_{

  my @categories;

  my $main_html = "${wgetted_dir}main.html";

  die unless -f $main_html;

  open (my $main, '<:encoding(UTF-8)', $main_html) or die;

  my $next_is_category_name = 0;
  my $category_link = '';
  while (my $in = <$main>) { #_{

    chomp $in;

    if ($in =~ m,<a class="primary-nav__link " *href="([^"]+)">,) {
      $category_link = $1;
      $next_is_category_name = 1;
      next;
    }
    if ($next_is_category_name) {
			die "$in does not match" unless $in =~ m,<span class="primary-nav__link__text">([^<]+)</span>,;

      push @categories, {name=>$1, href=>$category_link};

#     $categories{$1}{link} = $category_link;

      $next_is_category_name = 0;
      next;
    } #_}

  }

  close $main;

  return @categories;

} #_}

# qq sub do_category { #_{
# qq   my $category = shift;
# qq   download_link_if_necessary($category->{href});
# qq 
# qq   my $file_last_part = link_to_last_part($category->{href});
# qq 
# qq # printf "%-78s %s\n", $category->{name}, $file_last_part;
# qq # do_menu($file_last_part, $categories{$category});
# qq 
# qq   return;
# qq 
# qq   my $local_file = link_to_local_file($category->{link});
# qq 
# qq   open (my $file, '<:encoding(utf-8)', $local_file) or die;
# qq 
# qq   while (my $line = <$file>) { #_{
# qq 
# qq       if ($line =~ m,<li class="list__item"><a href="([^"]+)">([^<]+)</a></li>,) { #_{
# qq 
# qq         my $link        = $1;
# qq         my $subcategory = $2;
# qq 
# qq         do_subcategory($category, $subcategory);
# qq 
# qq       } #_}
# qq 
# qq 
# qq   } #_}
# qq 
# qq   close $file;
# qq 
# qq } #_}

sub do_menu_of_top_level_category { #_{

  my $last_part          = shift;
  my $top_level_category = shift;

  my $tree_creator = Tree::Create::DepthFirst->new();

  my $in_a   = 0;
  my $href   = '';

  download_menu_if_necessary($last_part);

  my $local_file = last_part_to_local_menu_file($last_part);

  open (my $fh, '<:encoding(utf-8)', $local_file) or die;
  my $file_text = <$fh>;
  close $fh;

  my $json = from_json($file_text);


  my $content = $json->{subMenu};

  my $depth = -1;
  my $cur_category;
  my $parser = HTML::Parser->new(
    start_h       => [ sub { #_{

      my ($tag, $attr) = @_;

        if ($tag eq 'ul') {
          $depth++ if $tag eq 'ul';
        }
  
        if ($tag eq 'a') {
          $in_a = 1;
          $href = $attr->{href};
          $cur_category = {href=>$href};
        }

    },
      
    'tag, attr'],  #_}
    end_h         => [ sub { #_{
      my $tag = shift;
    
      if ($tag eq '/ul') {
        $depth--;
      }
      if ($tag eq '/a') {
        $in_a = 0;
      }
    
    },
    'tag'      ], #_}
    text_h        => [ sub { #_{
      my $text = shift;
     
      if ($in_a) {
        $text =~ s/\n//g;
        $text =~ s/^\s+//g;
        $text =~ s/s+$//g;
        if ($text =~ m/\w/) {

          $first_cur = $cur_category unless $first_cur;

         $cur_category ->{name} = $text;
          $tree_creator -> addNode($depth, $cur_category);
        }
      }

     },
     'text'     ], #_} 
  );

  $parser -> parse($content);

  my $tree = $tree_creator->getTree();
  $tree->setNodeValue($top_level_category);
  $product_tree->addChild($tree)


} #_}

# QQ sub do_subcategory { #_{
# QQ   my $category    = shift;
# QQ   my $subcategory = shift;
# QQ 
# QQ   my $link = $categories{$category}{subcategories}{$subcategory}{link};
# QQ   printf "  %-76s %s\n", $subcategory, $link;
# QQ 
# QQ   download_link_if_necessary($link);
# QQ 
# QQ   my $local_file = link_to_local_file($link);
# QQ 
# QQ   open (my $file, '<:encoding(utf-8)', $local_file) or die;
# QQ 
# QQ   while (my $in = <$file>) {
# QQ     chomp $in;
# QQ 
# QQ     if ($in =~ m,<li class="list__item"><a href="([^"]+)">([^<]+)</a></li>,) {
# QQ       my $link = $1;
# QQ       my $sub_sub_category = $2;
# QQ 
# QQ       print "    $sub_sub_category\n";
# QQ 
# QQ     }
# QQ 
# QQ # q
# QQ # q    if ($in =~ m,<h2 class="delta delta--base product-item__name" data-equal-heights-group="product-item__name" ?>,) {
# QQ # q      do_product($category, $subcategory, $file);
# QQ # q      next;
# QQ # q    }
# QQ # q    die $in if $in =~ m,<h2,;
# QQ # q
# QQ    }
# QQ 
# QQ   close $file;
# QQ 
# QQ } #_}

# QQ sub do_product { #_{
# QQ   my $category    = shift;
# QQ   my $subcategory = shift;
# QQ   my $file        = shift;
# QQ 
# QQ   my $in = <$file>;
# QQ   chomp $in;
# QQ 
# QQ   my $link;
# QQ   my $product_name;
# QQ   my $blood_red = '';
# QQ 
# QQ   if ($in =~ m,<a href="([^"]+)" data-line-clamp="1:3" data-product-overlay>([^<]+)</a>,) {
# QQ 
# QQ     $link = $1;
# QQ     $product_name = $2;
# QQ 
# QQ   }
# QQ   elsif ($in =~ m,<a href="([^"]+)" data-line-clamp="1:3" data-product-overlay (data-modal-modifiers="theme--blood-red")?>,) {
# QQ     $link = $1;
# QQ 
# QQ     if ($2) {
# QQ       $blood_red = "BLUTROT";
# QQ     }
# QQ 
# QQ     $in = <$file>;
# QQ     chomp $in;
# QQ 
# QQ     die $in unless $in =~ m,^\s*(\S.*)</a>,;
# QQ      $product_name = $1;
# QQ   }
# QQ   else {
# QQ     die $in;
# QQ   }
# QQ 
# QQ 
# QQ   printf "    %-74s %s\n", "$product_name $blood_red", $link;
# QQ 
# QQ 
# QQ } #_}

sub download_link_if_necessary { #_{
  my $link = shift;

  my $local_file = link_to_local_file($link);

  download_link_if_necessary_with_specification_of_local_file($link, $local_file);

} #_}

sub download_link_if_necessary_with_specification_of_local_file { #_{
  my $link       = shift;
  my $local_file = shift;

  return if -f $local_file;

  my $url        = "http://coopathome.ch$link";
  print "Downloading $url to $local_file\n";

  getstore($url, $local_file) or die;

  system ("dos2unix $local_file");
} #_}

sub last_part_to_local_menu_file { #_{

  my $last_part = shift;
  my $local_file = "${wgetted_dir}menu_$last_part";

  return $local_file;

} #_}

sub download_menu_if_necessary { #_{

  my $last_part = shift;  # m_0001  etc 

  my $local_file = last_part_to_local_menu_file($last_part);

  return if -f $local_file;

  my $url       = "https://www.coopathome.ch/de/navigation/menu/get/?categoryCode=$last_part";

  print "Getting $url\n";
  getstore($url, $local_file) or die;
  system ("dos2unix $local_file");


} #_}

sub href_to_menu_link { #_{
  my $href    = shift;
  my $page_no = shift;

  $href = substr($href, 3); # rm »de/«

  $href =~ m,^(.*?)/([^/]+?)(?:\?(.+))?$,;

  my $part_1 = $1;
  my $part_2 = $2;
  my $part_3 = $3;

  my $link       = "$part_1/$part_2/results?page=$page_no";
  my $local_file = "${wgetted_dir}$part_2-result_$page_no";
  if ($part_3) {
    $link .= "&$part_3";
    $local_file .= "-$part_3";
  }
  $local_file =~ s/%3A/+/g;

  return ($link, $local_file);

} #_}

sub link_to_last_part { #_{
  my $link = shift;

  $link =~ m,([^/]*)$,;
  my $file_name = $1;
  return $file_name;

} #_}

sub link_to_local_file { #_{

  my $link = shift;

  my $file_name = link_to_last_part($link);

  my $local_file = "${wgetted_dir}$file_name";

  return $local_file;

} #_}

sub file_to_json { #_{

  my $local_file = shift;

  open (my $h, '<:encoding(utf-8)', $local_file) or die;
  my $json_txt = join "", <$h>;
  close $h;

  my $json = from_json($json_txt);

  return $json;

} #_}
