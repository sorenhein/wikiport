#!perl

use strict;
use warnings;

if ($#ARGV != 1)
{
  print "Usage: uniques.pl file1.txt file2.txt > out.txt\n";
  exit;
}

my (@lines1, @lines2);
read_file($ARGV[0], \@lines1);
read_file($ARGV[1], \@lines2);

@lines1 = sort @lines1;
@lines2 = sort @lines2;

my $used1 = 1;
my $used2 = 1;
my ($line1, $line2);
my $done1 = 0;
my $done2 = 0;
my (@unique1, @unique2);

my $index1 = -1;
my $index2 = -1;
my $lastno1 = $#lines1;
my $lastno2 = $#lines2;

while (1)
{
  if (! $done1 && $used1)
  {
    $done1 = 1;
    while (++$index1 <= $lastno1)
    {
      $line1 = $lines1[$index1];
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
    while (++$index2 <= $lastno2)
    {
      $line2 = $lines2[$index2];
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
  # print "HERE\n";
}

  if ($done1)
  {
    push @unique2, $line2;
    $used1 = 0;
    $used2 = 1;
  }
  elsif ($done2)
  {
    push @unique1, $line1;
    $used1 = 1;
    $used2 = 0;
  }
  elsif ($line1 gt $line2)
  {
    push @unique2, $line2;
    $used1 = 0;
    $used2 = 1;
  }
  elsif ($line1 lt $line2)
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

print "Unique to $ARGV[0]\n";
print "$_\n" for @unique1;
print "\n";

print "Unique to $ARGV[1]\n";
print "$_\n" for @unique2;
print "\n";


sub read_file
{
  my ($name, $list_ref) = @_;

  open my $fh, "<", $name or die "Cannot open $name: $!";
  while (my $line = <$fh>)
  {
    chomp $line;
    $line =~ s///g;
    push @$list_ref, $line;
  }
  close $fh;
}

