#!perl

use strict;
use warnings;

if ($#ARGV != 0)
{
  print "Usage: presort.pl file.txt > out.txt\n";
  exit;
}

my $f = $ARGV[0];

open my $fh, "<", $f or die "Cannot open $f: $!";

my @a;
while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;
  push @a, $line;
}

my @b = sort @a;

print "$_\n" for @b;
