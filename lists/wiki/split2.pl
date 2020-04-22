#!perl

use strict;
use warnings;

use File::Basename;
use File::Path qw/make_path/;


# Splits offs groups of Wiki pages from the central list.
# Unlike split.pl this takes into account that the groups may not
# be at top level.  It could either be a deeper "directory" or a file.

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

  # Store by the root in pages.
  my @a = split '/', $line;
  my $baseline = $a[0];

  # Take the complete match if it's there.  Store by its root.

# print "line .$line.\n";

  if (defined $groups{$line})
  {
# print "   direct hit\n";
    push @{$pages{$baseline}}, $line;
    next;
  }

  # Try subsets of line.
  my $sub = "";
  my $found = 0;
  for (my $i = 0; $i < $#a; $i++)
  {
    $sub .= "/" if $i > 0;
    $sub .= $a[$i];
    if (defined $groups{$sub})
    {
      push @{$pages{$baseline}}, $line;
      $found = 1;
      last;
    }
  }

  push @rest, $line unless $found;
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

