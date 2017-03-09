#!/usr/bin/perl
use warnings;
use strict;
use LWP::Simple;
use JSON;
use HTML::Parser;
binmode(STDOUT, ':utf8');

my $top_dir     = "$ENV{digitales_backup}crawler/Preise/Coop/";
my $wgetted_dir = "${top_dir}wgetted/";
die "directory $wgetted_dir missing" unless -d $wgetted_dir;

my @top_level_categories = determine_top_level_categories();

# my $indent = 0;

for my $category (@top_level_categories) { #_{
#  printf "%-70s %20s\n", $category->{name}, $category->{href};
   do_menu(link_to_last_part($category->{href}), $category);
} #_}

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

print_categories_recursively(\@top_level_categories, 0);

sub print_categories_recursively {
  my $categories = shift;
  my $indent     = shift;

  for my $category (reverse @$categories) {
    print "  " x $indent;
    print $category -> {name} // 'n/a';
    print "\n";

    if (exists $category->{categories}) {
      print_categories_recursively($category->{categories}, $indent+1);
    }

  }


}

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

sub do_category { #_{
  my $category = shift;
  download_link_if_necessary($category->{href});

  my $file_last_part = link_to_last_part($category->{href});

# printf "%-78s %s\n", $category->{name}, $file_last_part;
# do_menu($file_last_part, $categories{$category});

  return;

  my $local_file = link_to_local_file($category->{link});

  open (my $file, '<:encoding(utf-8)', $local_file) or die;

  while (my $line = <$file>) { #_{

      if ($line =~ m,<li class="list__item"><a href="([^"]+)">([^<]+)</a></li>,) {

        my $link        = $1;
        my $subcategory = $2;

# QQ    $categories{$category}{subcategories}{$subcategory}{link} = $link;

        do_subcategory($category, $subcategory);

#       print "    $subcategory ($link)\n";

      }


  } #_}

  close $file;

} #_}

sub do_menu { #_{

  my $last_part    = shift;
  my $cur_category = shift;

  my @category_stack = ($cur_category);

  my $in_a   = 0;
  my $href   = '';

# $cur_category -> {foo} = 'foo';

# print "do_menu, $last_part, $cur_category\n";


  download_menu_if_necessary($last_part);

  my $local_file = last_part_to_local_menu_file($last_part);

  open (my $fh, '<:encoding(utf-8)', $local_file) or die;
  my $file_text = <$fh>;
  close $fh;

  my $json = from_json($file_text);


  my $content = $json->{subMenu};

  my $parser = HTML::Parser->new(
    start_h       => [ sub { #_{
      my ($tag, $attr) = @_;
  
      if ($tag eq 'ul') {
#       $indent ++;
        print "x\n";
#       @{$category_stack[0]->{categories}} = [];
        $cur_category -> {categories} = [];
        unshift @category_stack, $cur_category;

#       unshift @category_stack, {};
      }
      if ($tag eq 'li') {
      }
      if ($tag eq 'a') {
        $in_a = 1;
        $href = $attr->{href};
#       $cat->{href} = $href;
        $cur_category = {href=>$href};
        push @category_stack, $cur_category;
#       $category_stack[0]-->{href} = $href;
      }

    },
      
    'tag, attr'],  #_}
    end_h         => [ sub { #_{
      my ($tag, $text) = @_;
    
      if ($tag eq '/ul') {
        print "y\n";
        shift @category_stack;
#       $indent --;
      }
      if ($tag eq '/li') {
      }
      if ($tag eq '/a') {
        $in_a = 0;
      }
    
    },
    'tag'      ], #_}
    text_h        => [ sub { #_{
      my ($text) = @_;
     
      if ($in_a) {
        $text =~ s/\n//g;
        $text =~ s/^\s+//g;
        $text =~ s/s+$//g;
        $cur_category ->{text} = $text;
#       ${$category_stack[0]}[-1]->{name}=$text;
#       print "$text ($href)\n";
      }
     },
     'text'     ], #_} 

  );

  $parser -> parse($content);


  while ($content =~ m,<ul>(.*?)</ul>,) {

  }

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
  my $url        = "http://coopathome.ch$link";

  return if -f $local_file;

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






