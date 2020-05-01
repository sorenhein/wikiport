use strict;
use warnings;

# Check line 1 of deal Wiki pages for deal property.

my $header = '#acl';
my $group = "BeteiligungsPrüfungGroup";

if ($#ARGV != 0)
{
  print "Usage: parse.pl files.txt\n";
  exit;
}

my $file = $ARGV[0];

open my $fh, "<", $file or die "Cannot open $file: $!";

my $num = 0;
my $ok = 0;
my $notfound = 0;
my $bad = 0;
my @bads;

while (my $fline = <$fh>)
{
  chomp $fline;
  $fline =~ s///g;

  open my $fi, "<", $fline or die "Cannot open $fline: $!";
  my $line;
  my $found = 0;
  while ($line = <$fi>)
  {
    chomp $line;
    $line =~ s///g;
    if ($line =~ /^$header/)
    {
      $found = 1;
      last;
    }
  }
  close $fi;

  $num++;
  if (! $found)
  {
    $notfound++;
  }
  elsif ($line =~ /$group/)
  {
    $ok++;
  }
  else
  {
    $bad++;
    my @a = split /\s+/, $line;
    my $groups = "";
    for my $x (@a)
    {
      next if ($x =~ /^$header/);
      $x =~ s/:.*//;
      $groups .= " $x";
    }

    $fline =~ /^.*\/([^\/]*)/;

    push @bads, "$1: $groups";
  }
}

close $fh;


printf "%6d total\n", $num;
printf "%6d OK\n", $ok;
printf "%6d not found\n", $notfound;
printf "%6d bad\n\n", $bad;

my $len = 0;
for my $b (@bads)
{
  my @a = split /:/, $b;
  my $l = length($a[0]);
  $len = $l if $l > $len;
}

print "Bad pages:\n";
for my $b (@bads)
{
  my @a = split /:/, $b;
  printf "%${len}s:", $a[0];
  for my $i (1 .. $#a)
  { 
    print " $a[$i]";
  }
  print "\n";
}

