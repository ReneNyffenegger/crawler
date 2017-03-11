#!/usr/bin/perl
use warnings;
use strict;
use LWP::Simple;
use JSON;
use HTML::Parser;
use Tree::Create::DepthFirst;
binmode(STDOUT, ':utf8');

my $first_cur;

my $top_dir     = "$ENV{digitales_backup}crawler/Preise/Coop/";
my $wgetted_dir = "${top_dir}wgetted/";
die "directory $wgetted_dir missing" unless -d $wgetted_dir;

my $product_tree = Tree::Simple->new('Products');
my @top_level_categories = determine_top_level_categories();

# my $indent = 0;

for my $category (@top_level_categories) { #_{
#  printf "%-70s %20s\n", $category->{name}, $category->{href};
   do_menu_of_top_level_category(link_to_last_part($category->{href}), $category);

#  print $category->{name}, '  ', link_to_last_part($category->{href}), "\n";
#  $category->{tree}->traverse(sub {
#    my $node = shift;
#    printf(        "  %-50s %s\n", '  ' x $node->getDepth() . $node->getNodeValue()->{name}, link_to_last_part($node->getNodeValue()->{href}));
#  });

} #_}
#
#  print $category->{name}, '  ', link_to_last_part($category->{href}), "\n";

my $in_red_or_whitewine = 0;
$product_tree->traverse(sub {
     my $node = shift;
#    return if $node->getDepth() == -0;
#    printf("%-50s %s\n", '  ' x $node->getDepth() . $node->getNodeValue()->{name}, link_to_last_part($node->getNodeValue()->{href}));

     my $name = $node->getNodeValue()->{name};
     my $href = $node->getNodeValue()->{href};
     printf("%-50s %s\n", '  ' x $node->getDepth() . $name, substr($href, 1,190) );

     if ($node->getDepth() == 1) {

       if ($name eq 'Rotwein' or $name eq 'Weisswein') {
         $in_red_or_whitewine = 1;
       }
       else {
         $in_red_or_whitewine = 0;
       }

     }
     if ($node->isLeaf()) {

#      print "$href\n";
#      my ($menu_url, $local_file)=href_to_menu_url($href, 0); 

       if (not $in_red_or_whitewine) {
         do_product_details($href);
#        print "                                                 " . $menu_url . "  " . $local_file . "\n";
       }
       else {
         if ($name =~ /^Alle /) {
           do_product_details($href);
#          print "                                                 " . $menu_url . "  " . $local_file . "\n";
         }
       }

#      download_link_if_necessary(

#      print "  " .  . "\n";

     }
 });

# for my $category (@categories) { #_{
#    printf "%-70s %20s\n", $category->{name}, $category->{href};
# 
# #  for my $key (keys %$category) {
# #    print "  $key\n";
# #  }
# #  if ($category->{categories}) {
# #    print "  yes\n";
# #  }
# 
# } #_}

#print_categories_recursively(\@top_level_categories, 0);

# sub print_categories_recursively { #_{
#   my $categories = shift;
#   my $indent     = shift;
# 
#   for my $category (reverse @$categories) {
# #   print "  " x $indent;
# #   print $category -> {name} // 'n/a';
# #   print "\n";
# 
# #   if (exists $category->{categories}) {
# #     print_categories_recursively($category->{categories}, $indent+1);
# #   }
# 
#   }
# 
# 
# } #_}

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

  for my $page_no (1 .. ($json->{pagination}->{numberOfPages}-1)) {
    my ($menu_link, $local_file)=href_to_menu_link($href, $page_no); 
    download_link_if_necessary_with_specification_of_local_file($menu_link, $local_file);
  }

} #_}

sub determine_top_level_categories { #_{

  my @categories;

  my $main_html = "${wgetted_dir}main.html";

  die unless -f $main_html;

  open (my $main, '<:encoding(UTF-8)', $main_html) or die;

  my $next_is_category_name = 0;
  my $category_link = '';
  while (my $in = <$main>) {

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
    }

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

# $product_tree->addChild($top_level_category);

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
# $tree->setNodeValue({name=>$top_level_category->{name}, href=>'TODO TODO'});
  $tree->setNodeValue($top_level_category);
# $product_tree->addChild($tree_creator->getTree());
# $top_level_category->{tree} = $tree_creator->getTree();
  $product_tree->addChild($tree)

# while ($content =~ m,<ul>(.*?)</ul>,) {

# }

# print join "\n", keys %{$json};


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

sub do_product { #_{
  my $category    = shift;
  my $subcategory = shift;
  my $file        = shift;

  my $in = <$file>;
  chomp $in;

  my $link;
  my $product_name;
  my $blood_red = '';

  if ($in =~ m,<a href="([^"]+)" data-line-clamp="1:3" data-product-overlay>([^<]+)</a>,) {

    $link = $1;
    $product_name = $2;

  }
  elsif ($in =~ m,<a href="([^"]+)" data-line-clamp="1:3" data-product-overlay (data-modal-modifiers="theme--blood-red")?>,) {
    $link = $1;

    if ($2) {
      $blood_red = "BLUTROT";
    }

    $in = <$file>;
    chomp $in;

    die $in unless $in =~ m,^\s*(\S.*)</a>,;
     $product_name = $1;
  }
  else {
    die $in;
  }


  printf "    %-74s %s\n", "$product_name $blood_red", $link;


} #_}

sub download_link_if_necessary { #_{
  my $link = shift;


  my $local_file = link_to_local_file($link);
# my $url        = "http://coopathome.ch$link";

  download_link_if_necessary_with_specification_of_local_file($link, $local_file);

} #_}

sub download_link_if_necessary_with_specification_of_local_file {
  my $link       = shift;
  my $local_file = shift;

  return if -f $local_file;

  my $url        = "http://coopathome.ch$link";
  print "Downloading $url to $local_file\n";

  getstore($url, $local_file) or die;

  system ("dos2unix $local_file");
}

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

# my $link = "http://www.coopathome.ch$part_1/$part_2/results?page=$page_no";
  my $link =                         "$part_1/$part_2/results?page=$page_no";
  my $local_file = "${wgetted_dir}$part_2-result_$page_no";
# my $link =                        "$part_1/results?page=$page_no";
  if ($part_3) {
    $link .= "&$part_3";
    $local_file .= "-$part_3";
  }
  $local_file =~ s/%3A/+/g;

# return $link;
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
