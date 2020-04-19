#!perl

use strict;
use warnings;

use File::Basename;
use File::Path qw/make_path/;


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

  # Take the complete match if it's there.  Otherwise go by
  # the Wiki root and take all Wiki pages with the input root.

print "line .$line.\n";

  if (defined $groups{$line})
  {
print "   direct hit\n";
    push @{$pages{$line}}, $line;
    next;
  }

  my @a = split '/', $line;
  next unless $#a >= 0;
  if (defined $groups{$a[0]})
  {
print "   leading hit\n";
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

  # Make any directories on the path that don't exist.
  my $dir = dirname($fout);
  make_path($dir);

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

