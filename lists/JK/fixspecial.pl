#!perl

use strict;
use warnings;

require 'chars.pl';

# Fixes the special characters in the fixed(!) Affinity output.

if ($#ARGV < 0)
{
  print "Usage: fixspecial.pl file.txt > out.txt\n";
  exit;
}

my $file = $ARGV[0];
open my $fh, "<", $file or die "Cannot open $file: $!";

my %subs;
set_chars(\%subs);

while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;
  make_sub(\%subs, \$line);
  print $line, "\n";
}

close $fh;

