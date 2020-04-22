#!perl

use strict;
use warnings;


# Detects wiki pages whose names only differ by case.

if ($#ARGV != 0)
{
  print "Usage: collisions.pl list.txt\n";
  exit;
}

my %lower;

my $file = $ARGV[0];
open my $fh, "<", $file or die "Cannot open $file: $!";

while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;
  my $lcline = lc($line);

  if (defined $lower{$lcline})
  {
    print "$line ... $lower{$lcline}\n";
  }
  else
  {
    $lower{$lcline} = $line;
  }
}

close $fh;

