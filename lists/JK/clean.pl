#!perl

use strict;
use warnings;

# Fixes the special characters in Jürgen's export.

if ($#ARGV < 0)
{
  print "Usage: clean.pl file.txt > out.txt\n";
  exit;
}

my $file = $ARGV[0];
open my $fh, "<", $file or die "Cannot open $file: $!";

my %subs;
set_chars();

while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;
  print make_sub(\$line), "\n";
}

close $fh;


sub set_chars
{
  $subs{"20"} = ' ';
  $subs{"21"} = '!';
  $subs{"22"} = '"';
  $subs{"23"} = '#';
  $subs{"25"} = '%';
  $subs{"26"} = '&';
  $subs{"27"} = "'";
  $subs{"28"} = "(";
  $subs{"29"} = ")";
  $subs{"2b"} = '+';
  $subs{"2c"} = ',';
  $subs{"2d"} = '-';
  $subs{"2e"} = '.';
  $subs{"2f"} = '/';
  $subs{"3a"} = ':';
  $subs{"3f"} = '?';
  $subs{"40"} = '@';
  $subs{"5b"} = '[';
  $subs{"5d"} = ']';
  $subs{"7b"} = '{';
  $subs{"7c"} = '|';
  $subs{c2ae} = '®';
  $subs{c2b4} = '`';
  $subs{c380} = 'À';
  $subs{c384} = 'Ä';
  $subs{c39c} = 'Ü';
  $subs{c39f} = 'ß';
  $subs{c396} = 'Ö';
  $subs{c3a4} = 'ä';
  $subs{c3a9} = 'é';
  $subs{c3bc} = 'ü';
  $subs{c3b6} = 'ö';
  $subs{c5a1} = 'š';
}


sub make_sub
{
  my $line_ref = pop;
  my $offset = 0;
  my $result = "";

  while (1)
  {
    my $pos1 = index($$line_ref, '(', $offset);
    if ($pos1 == -1)
    {
      $result .= substr $$line_ref, $offset;
      last;
    }

    my $pos2 = index($$line_ref, ')', $pos1);
    if ($pos2 < $pos1)
    {
      $result .= substr $$line_ref, $offset;
      last;
    }

    $result .= substr $$line_ref, $offset, $pos1 - $offset;

    my $code = substr $$line_ref, $pos1+1, $pos2 - $pos1 - 1;
    my $clear = '';
    while ($code ne '')
    {
      my $found = 0;
      for my $k (keys %subs)
      {
        if ($code =~ /^$k/)
        {
          $clear = $clear . $subs{$k};
          $code =~ s/^$k//;
          $found = 1;
          last;
        }
      }

      if (! $found)
      {
        print "Could not fix:\n";
        print "$$line_ref\n";
        print "$code\n";
        exit;
      }
    }

    $result .= $clear;
    $offset = $pos2 + 1;
  }

  return $result;
}
