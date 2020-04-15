#!perl

use strict;
use warnings;

# Splits offs groups of Wiki pages from the central list.

if ($#ARGV != 2)
{
  print "Usage: split.pl list.txt portfolio.txt Portfolio > new.txt\n";
  exit;
}

my %groups;
read_groups($ARGV[1], \%groups);

my $outdir = $ARGV[2];

# Read the full list and split out some lines.
my (%pages, @rest);

my $file = $ARGV[0];
open my $fh, "<", $file or die "Cannot open $file: $!";

while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;

  my @a = split '/', $line;
  next unless $#a >= 0;
  if (defined $groups{$a[0]})
  {
    push @{$pages{$a[0]}}, $line;
  }
  else
  {
    push @rest, $line;
  }
}

close $fh;

# Write the individual output files.

mkdir $outdir unless -d $outdir;

for my $g (sort keys %pages)
{
  my $fout = $outdir . '/' . $g . '.txt';
  open my $fo, ">", $fout or die "Cannot open $fout: $!";
  for my $p (@{$pages{$g}})
  {
    print $fo $p, "\n";
  }
  close $fo;
}

# Write the remaining, unmatched lines.

for my $r (@rest)
{
  print $r, "\n";
}

sub read_groups
{
  my ($group_file, $groups_ref) = @_;

  open my $fg, "<", $group_file or die "Cannot open $group_file $!";
  while (my $line = <$fg>)
  {
    chomp $line;
    $line =~ s///g;
    $groups_ref->{$line} = 1;
  }
  close $fg;
}

