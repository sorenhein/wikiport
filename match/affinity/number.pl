#!perl

use strict;
use warnings;

# Establish the Wiki number of matched Affinity deals.
# Derived from aff.pl

if ($#ARGV != 2)
{
  print "Usage: number.pl affinity.csv wiki.csv wpruf.csv\n";
  exit;
}

# File with Affinity deals to disregard, as there is no matching
# Wiki deal.  Same company, but too recent.
my $aff_exist_file = "../aff_exist";
my %aff_excludes;
read_exclude_file(\%aff_excludes);

my (@has_prufung, @has_own_page, @has_sharepoint, @has_none);
my (@has_exist_skip);
my (%aff_own, %aff_pruf);

my $aff = $ARGV[0];
my $wifile = $ARGV[1];
my $wpruf = $ARGV[2];

# Read the Affinity csv file.

open my $fh, "<", $aff or die "Cannot open $aff $!";
my $line = <$fh>; # Header line

while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;

  # Split on commas that are not between quotes.
  my @a = split /,(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)/, $line;

  # Turn dd/mm/yyyy into dd.mm.yy
  my $ad = $a[14]; # Date added
  $ad =~ s/\//./g;
  $ad =~ s/\.20/./;

  my @deal;
  $deal[0] = $a[2]; # Name
  $deal[1] = $ad; # Date added
  $deal[2] = $a[26]; # Wiki
  $deal[3] = $a[27]; # Sharepoint
  $deal[4] = $a[0]; # List ID
  $deal[5] = $a[1]; # Org ID

  if (deal_exists(\%aff_excludes, \@deal))
  {
    push @has_exist_skip, \@deal;
  }
  elsif ($deal[2] =~ /Pr/ && $deal[2] =~ /fung/)
  {
    push @has_prufung, \@deal;

    my $name = $a[2];
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;

    push @{$aff_pruf{$name}}, \@deal;
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


# Read the Wiki file.

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

# Read the Wiki Prüfung file, store by name.

my @wpruf_real;
my %wpruf_own;

open my $fp, "<", $wpruf or die "Cannot open $wpruf $!";
$line = <$fp>; # Header line

while ($line = <$fp>)
{
  chomp $line;
  $line =~ s///g;

  my @a = split /;(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)/, $line;
  
  my @deal;
  $deal[0] = $a[1]; # Company
  $deal[1] = $a[5]; # Date
  $deal[2] = $a[4]; # Wiki
  $deal[3] = $a[0]; # Number

  my $base = $deal[0];
  $base =~ s/^\s+//;
  $base =~ s/\s+$//;

  push @wpruf_real, \@deal;
  push @{$wpruf_own{$base}}, \@deal;
}

close $fp;


# List of matches.
my @number_matches;

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

  # There may be extra Affinity pages.
  if ($#{$wiki_own{$w}} != $#{$aff_own{$w}})
  {
    print "Extra Affinity deals $w: ", 1+$#{$wiki_own{$w}}, " vs ", 
      1+ $#{$aff_own{$w}}, "\n";
    print "  Affinity:";
    for my $aref (@{$aff_own{$w}})
    {
      print " $aref->[1]";
    }
    print "\n";

    print "  Wiki    :";
    for my $wref (@{$wiki_own{$w}})
    {
      my $wd = $wref->[1];
      print " $wd";
    }
    print "\n\n";
  }

  for my $wref (@{$wiki_own{$w}})
  {
    my $wd = $wref->[1];
    my $found = 0;
    for my $aref (@{$aff_own{$w}})
    {
      if ($aref->[1] eq $wd)
      {
        $found = 1;
        my @match;
        $match[0] = $aref->[4]; # List ID
        $match[1] = $aref->[5]; # Org ID
        $match[2] = $wref->[3]; # Wiki number
        push @number_matches, \@match;
        last;
      }
    }

    if (! $found)
    {
      print "Wiki page $w: Date $wd not found among:\n";
      print "  Referred to: ", $wref->[3], "\n Affinity dates:";
      for my $aref (@{$aff_own{$w}})
      {
        print " $aref->[1]";
      }
      print "\n\n";
    }
  }
}

# Look for deals in Affinity that have Wiki links although they're not
# in deal lists.

for my $a (sort keys %aff_own)
{
  next if defined $wiki_own{$a};
  print "Solo Affinity deal with wiki link, $a:";

  for my $aref (@{$aff_own{$a}})
  {
    print " $aref->[1]";
  }
  print "\n";
}

# Look for Prüfung deals in Affinity that are also in Wiki.

for my $a (sort keys %aff_pruf)
{
  if (! defined $wpruf_own{$a})
  {
    print "Affinity deal $a not in Wiki\n";
    print "  Referred to ";
    for my $aref (@{$aff_pruf{$a}})
    {
      print " ", $aref->[1], ", ", $aref->[2];
    }
    print "\n\n";

    next;
  }

  for my $aref (@{$aff_pruf{$a}})
  {
    my $ad = $aref->[1];
    my $found = 0;
    for my $wref (@{$wpruf_own{$a}})
    {
      if ($wref->[1] eq $ad)
      {
        $found = 1;
        my @match;
        $match[0] = $aref->[4]; # List ID
        $match[1] = $aref->[5]; # Org ID
        $match[2] = $wref->[3]; # Wiki number
        push @number_matches, \@match;
        last;
      }
    }

    if (! $found)
    {
      print "Affinity deal $a: Date $ad not found among:\n";
      print "  Referred to Wiki: ", $aref->[2], "\n Wiki dates:";
      for my $wref (@{$wpruf_own{$a}})
      {
        print " $wref->[1]";
      }
      print "\n\n";
    }
  }
}

# Print the Prüfung deals in Wiki that are not in Affinity.

print "Wiki Prüfung solo deals\n";
my $wsolo = 0;
for my $w (sort keys %wpruf_own)
{
  next if defined $aff_pruf{$w};
  for my $wref (@{$wpruf_own{$w}})
  {
    $wsolo++;
    print join ';', @$wref, "\n";
  }
}

for my $w (sort keys %wpruf_own)
{
  next unless defined $aff_pruf{$w};
  next if ($#{$wpruf_own{$w}} == $#{$aff_pruf{$w}});
  print "Wiki $w: ", 1+$#{$wpruf_own{$w}}, " vs ", 1+$#{$aff_pruf{$w}}, "\n";
}


# Count all Wiki Prüfung.
my $cwall = 0;
for my $w (sort keys %wpruf_own)
{
  for my $wref (@{$wpruf_own{$w}})
  {
    $cwall++;
  }
}

# Count all Affinity Prüfung.
my $caall = 0;
for my $a (sort keys %aff_pruf)
{
  for my $wref (@{$aff_pruf{$a}})
  {
    $caall++;
  }
}

print "Wiki solo $wsolo\n";
print "Wiki all  $cwall\n";
print "Aff  all  $caall\n";



print "\n";
print "Affinity Prüfung deals: ", 1+$#has_prufung, "\n";
# print_csv(\@has_prufung);

print "\n";
print "Wikipage deals: ", 1+$#has_own_page, "\n";
# print_csv(\@has_own_page);

print "\n";
print "Sharepoint-only: ", 1+$#has_sharepoint, "\n";
# print_csv(\@has_sharepoint);

print "\n";
print "None: ", 1+$#has_none, "\n";
# print_csv(\@has_none);

print "\n";
print "Has existing wiki skip ", 1+$#has_exist_skip, "\n";
# print_csv(\@has_exist_skip);

print "\n";
print "Number matches\n";
print_csv(\@number_matches);


sub read_exclude_file
{
  my $hash_ref = pop;
  my $fe;
  open $fe, "<", $aff_exist_file or die "Cannot open $fe $!";
  while ($line = <$fe>)
  {
    chomp $line;
    $line =~ /^(\d\d\.\d\d\.\d\d) (.*)$/;
    my ($d, $n) = ($1, $2);
    push @{$hash_ref->{$n}}, $d;
  }
  close $fe;
}


sub deal_exists
{
  my ($excl_has_ref, $deal_ref) = @_;
  my $wiki = $deal_ref->[2];
  $wiki =~ s/^.*\///;
  return 0 unless defined $excl_has_ref->{$wiki};
  for my $d (@{$excl_has_ref->{$wiki}})
  {
    return 1 if $d eq $deal_ref->[1];
  }
  return 0;
}


sub print_csv
{
  my $deals_ref = pop;
  for my $dref (@$deals_ref)
  {
    print join ';', @$dref, "\n";
  }
}

