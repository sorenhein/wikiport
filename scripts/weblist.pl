use strict;
use warnings;

# Parse the output format of parse.pl and make a mail histogram.

if ($#ARGV != 0)
{
  print "Usage: weblist.pl out.txt > histo.txt\n";
  exit;
}


my (%websites);

my $file = $ARGV[0];

open my $fh, "<", $file or die "Cannot open $file: $!";

while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;

  next unless ($line =~ /^Websites$/);

  <$fh>; # Skip dashes
  
  do
  {
    $line = <$fh>;
    chomp $line;
    $line =~ s///g;
    last if $line =~ /^\s*$/;

    $line =~ /^\s*(\d+)\s+(.*)/;
    my ($count, $value) = ($1, $2);

    $websites{$value} += $count;
  }
}

close $fh;

print_hash("Websites", \%websites);


sub print_hash
{
  my($name, $hash_ref) = @_;

  print "$name\n";
  print "-" x length($name), "\n";

  for my $k (sort {$hash_ref->{$b} <=> $hash_ref->{$a}} keys %$hash_ref)
  {
    printf "%4d %s\n", $hash_ref->{$k}, $k;
  }
  print "\n";
}
