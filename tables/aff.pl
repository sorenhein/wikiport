#!perl

use strict;
use warnings;

if ($#ARGV != 1)
{
  print "Usage: aff.pl affinity.csv wiki.csv\n";
  exit;
}

my (@has_prufung, @has_own_page, @has_sharepoint, @has_none);
my %aff_own;

my $aff = $ARGV[0];
my $wifile = $ARGV[1];

open my $fh, "<", $aff or die "Cannot open $aff $!";
my $line = <$fh>; # Header line

while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;

  # Split on commas that are not between quotes.
  my @a = split /,(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)/, $line;

  my @deal;
  $deal[0] = $a[2]; # Name
  $deal[1] = $a[14]; # Date added
  $deal[2] = $a[26]; # Wiki
  $deal[3] = $a[27]; # Sharepoint

  if ($deal[2] =~ /Pr/ && $deal[2] =~ /fung/)
  {
    push @has_prufung, \@deal;
  }
  elsif ($deal[2] ne '""')
  {
    push @has_own_page, \@deal;

    my $base = $deal[2];
    $base =~ s/^.*\///;

    # Wiki link may have %20 for space.
    $base =~ s/%20/ /g;

    push @{$aff_own{$base}}, \@deal;
  }
  elsif ($deal[3] ne '""')
  {
    push @has_sharepoint, \@deal;
  }
  else
  {
    push @has_none, \@deal;
  }
}

close $fh;


my @wiki_real;
my %wiki_own;

open my $fw, "<", $wifile or die "Cannot open $wifile $!";
$line = <$fw>; # Header line

while ($line = <$fw>)
{
  chomp $line;
  $line =~ s///g;

  my @a = split /;(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)/, $line;
  
  my @deal;
  $deal[0] = $a[1]; # Company
  $deal[1] = $a[5]; # Date
  $deal[2] = $a[4]; # Wiki
  $deal[3] = $a[0]; # Number

  my $base = $deal[2];
  $base =~ s/^.*\///;

  push @wiki_real, \@deal;
  push @{$wiki_own{$base}}, \@deal;
}

close $fw;

for my $w (sort keys %wiki_own)
{
  if (! defined $aff_own{$w})
  {
    print "Wiki page $w not in Affinity:\n";
    print "  Referred to: ";
    for my $wref (@{$wiki_own{$w}})
    {
      print " ", $wref->[3];
    }
    print "\n\n";

    next;
  }

  for my $wref (@{$wiki_own{$w}})
  {
    my $wd = $wref->[1];
    my $found = 0;
    for my $aref (@{$aff_own{$w}})
    {
      # Is in format dd/mm/yyyy.
      my $ad = $aref->[1];
      $ad =~ s/\//./g;
      $ad =~ s/\.20/./;

      if ($ad eq $wd)
      {
        $found = 1;
        last;
      }
    }

    if (! $found)
    {
      print "Wiki page $w: Date $wd not found among:\n";
      print "  Referred to: ", $wref->[3], "\n Affinity dates:";
      for my $aref (@{$aff_own{$w}})
      {
        # Is in format dd/mm/yyyy.
        my $ad = $aref->[1];
        $ad =~ s/\//./g;
        $ad =~ s/\.20/./;
        print " $ad";
      }
      print "\n\n";
    }
  }
}

exit;


print "\n";
print "Prüfung deals: ", 1+$#has_prufung, "\n";
print_csv(\@has_prufung);

print "\n";
print "Wikipage deals: ", 1+$#has_own_page, "\n";
print_csv(\@has_own_page);

print "\n";
print "Sharepoint-only: ", 1+$#has_sharepoint, "\n";
print_csv(\@has_sharepoint);

print "\n";
print "None: ", 1+$#has_none, "\n";
print_csv(\@has_none);





sub print_csv
{
  my $deals_ref = pop;
  for my $dref (@$deals_ref)
  {
    print join ',', @$dref, "\n";
  }
}

