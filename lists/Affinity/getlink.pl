#!perl

use strict;
use warnings;

if ($#ARGV < 0)
{
  print "Usage: getlink.pl list.csv > out.txt\n";
  exit;
}

my $file = $ARGV[0];
open my $fh, "<", $file or die "Cannot open $file: $!";

while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;

  my @a = split /,/, $line;
  for my $b (@a)
  {
    if ($b =~ /https/)
    {
      $b =~ s/^https:\/\/info.mig.ag\///;
      print "$b\n";
    }
  }
}

close $fh;
