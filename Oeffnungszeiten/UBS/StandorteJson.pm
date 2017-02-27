package StandorteJson;

use JSON;

my $json;
BEGIN { #_{

  open (my $json_h, '<:encoding(utf-8)', "$ENV{digitales_backup}/crawler/Oeffnungszeiten/UBS/standorte.json") or die;
  my $json_text = <$json_h>;
  close $json_h;

  $json = from_json($json_text);

} #_}

sub elems { #_{
  my %hits_outer = %{$json->{hits}};
  map { $_->{fields} } @{$hits_outer{hits}};
} #_}

sub id2file { #_{
  my $id = shift;

 (my $file  = $id) =~ s|/|_|g;
  $file .= ".data";

  $file;
} #_}

1;
