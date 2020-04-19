#!perl

use strict;
use warnings;

# Fixes the special characters in the fixed(!) Affinity output.

if ($#ARGV < 0)
{
  print "Usage: fixspecial.pl file.txt > out.txt\n";
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
  make_sub(\$line);
  print $line, "\n";
}

close $fh;


sub set_chars
{
  $subs{"%20"} = ' ';
  $subs{"%21"} = '!';
  $subs{"%22"} = '"';
  $subs{"%23"} = '#';
  $subs{"%25"} = '%';
  $subs{"%26"} = '&';
  $subs{"%27"} = "'";
  $subs{"%28"} = "(";
  $subs{"%29"} = ")";
  $subs{"%2b"} = '+';
  $subs{"%2C"} = ',';
  $subs{"%2D"} = '-';
  $subs{"%2E"} = '.';
  $subs{"%2F"} = '/';
  $subs{"%3A"} = ':';
  $subs{"%3F"} = '?';
  $subs{"%40"} = '@';
  $subs{"%5B"} = '[';
  $subs{"%5D"} = ']';
  $subs{"%7B"} = '{';
  $subs{"%7C"} = '|';
  $subs{"%C2%AE"} = '®';
  $subs{"%C2%B4"} = '`';
  $subs{"%C3%80"} = 'À';
  $subs{"%C3%84"} = 'Ä';
  $subs{"%C3%9C"} = 'Ü';
  $subs{"%C3%9F"} = 'ß';
  $subs{"%C3%96"} = 'Ö';
  $subs{"%C3%A4"} = 'ä';
  $subs{"%C3%A9"} = 'é';
  $subs{"%C3%BC"} = 'ü';
  $subs{"%C3%B6"} = 'ö';
  $subs{"%C5%A1"} = 'š';
}


sub make_sub
{
  my $line_ref = pop;

  if ($$line_ref =~ /\%/)
  {
    for my $k (keys %subs)
    {
      $$line_ref =~ s/$k/$subs{$k}/g;
    }
  }
}
