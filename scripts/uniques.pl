#!perl

use strict;
use warnings;

if ($#ARGV != 1)
{
  print "Usage: uniques.pl file1.txt file2.txt > out.txt\n";
  exit;
}

my $f1 = $ARGV[0];
my $f2 = $ARGV[1];

open my $fh1, "<", $f1 or die "Cannot open $f1 $!";
open my $fh2, "<", $f2 or die "Cannot open $f2 $!";

my $used1 = 1;
my $used2 = 1;
my ($line1, $line2);
my $done1 = 0;
my $done2 = 0;
my (@unique1, @unique2);

while (1)
{
  if (! $done1 && $used1)
  {
    $done1 = 1;
    while ($line1 = <$fh1>)
    {
      chomp $line1;
      $line1 =~ s///g;
      if ($line1 !~ /^\s*$/)
      {
        $done1 = 0;
        $used1 = 0;
        last;
      }
    }
  }

  if (! $done2 && $used2)
  {
    $done2 = 1;
    while ($line2 = <$fh2>)
    {
      chomp $line2;
      $line2 =~ s///g;
      if ($line2 !~ /^\s*$/)
      {
        $done2 = 0;
        $used2 = 0;
        last;
      }
    }
  }

  last if ($done1 && $done2);

if (! defined $line2)
{
  print "HERE\n";
}

  if ($done1 || $line1 gt $line2)
  {
    push @unique2, $line2;
    $used1 = 0;
    $used2 = 1;
  }
  elsif ($done2 || $line1 lt $line2)
  {
    push @unique1, $line1;
    $used1 = 1;
    $used2 = 0;
  }
  else
  {
    $used1 = 1;
    $used2 = 1;
  }
}

close $fh1;
close $fh2;

print "Unique to $f1:\n";
print "$_\n" for @unique1;
print "\n";

print "Unique to $f2:\n";
print "$_\n" for @unique2;
print "\n";

