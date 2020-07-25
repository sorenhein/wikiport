#!perl

# Checks that Assessments follow the syntax JK:5, AT:4
# No spaces.  No number or a question mark are allowed.

use strict;
use warnings;

if ($#ARGV < 0)
{
  print "Usage: table.pl wiki.csv\n";
  exit;
}

my %people;
$people{AT} = 1;
$people{DB} = 1;
$people{GR} = 1;
$people{JK} = 1;
$people{KA} = 1;
$people{KF} = 1;
$people{KSG} = 1;
$people{MB} = 1;
$people{MG} = 1;
$people{MK} = 1;
$people{MBo} = 1;
$people{SH} = 1;
$people{beobachten} = 1;

my @deals;
for my $file (@ARGV)
{
  print("Trying $file\n");
  read_file($file, \@deals);
}
print "Got deals: ", 1+$#deals, "\n";

my @histo;
$histo[$_] = 0 for 0..4;

for my $dref (@deals)
{
  my ($wiki_no, $text) = @$dref;
  my @a = split ', ', $text;
  my $error = 0;
  for my $t (@a)
  {
    if (length($t) <= 2)
    {
      if (! defined $people{$t})
      {
        $error = 1;
      }
      last;
    }

    my @b = split ':', $t;

    my $initials = $b[0];
    if (! defined $people{$initials})
    {
      $error = 2;
      last;
    }

    if (length($t) > 5)
    {
      $error = 3 unless $t eq 'beobachten';
      last;
    }

    my $score = $b[1];
    if ($score !~ /^[123456?]/)
    {
      $error = 4;
      last;
    }
  }

  if ($error)
  {
    print "$wiki_no: $error, $text\n";
  }

  $histo[$error]++;
}

for my $i (0 .. $#histo)
{
  printf("%2d  %d\n", $i, $histo[$i]);
}


sub read_file
{
  my ($file, $deals_ref) = @_;

  open my $fh, "<", $file or die "Cannot open $file $!";

  my $count  = 0;

  while (my $line = <$fh>)
  {
    chomp $line;
    $line =~ s///g;
    next if $line =~ /^\s*$/;

    $line =~ /^(\d\d\/\d\d\d\d);(.*)$/;
    my @a = ($1, $2);
    next if $a[1] =~ /^\s*$/;
    push @$deals_ref, \@a;
  }
  close $fh;
}
