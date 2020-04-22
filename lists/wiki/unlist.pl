use strict;
use warnings;

use HTML::TreeBuilder;
use HTML::FormatText;

# Parse text fields out of Wiki pages.

if ($#ARGV != 0)
{
  print "Usage: unlist.pl index.html > out.txt\n";
  exit;
}

open my $fh, "<", $ARGV[0] or die "Cannot open $ARGV[0]: $!";

# Skip until we reach the line with "system pages".
while (my $line = <$fh>)
{
  last if ($line =~ /system pages/);
}

# Parse the main part of the page.
while (my $line = <$fh>)
{
  last if $line =~ /pagebottom/;
  chomp $line;
  $line =~ s///g;

  next if $line =~ /^\<\/p\>\<h2\>.*\<\/h2\>$/;
  next if $line =~ /^\<h2\>.*\<\/h2\>$/;

  my @split = split /\<\/a\>/, $line;
  s/\<[^>]*\>//g for @split;

  for my $g (@split)
  {
    next if $g =~ /^\s*$/;
    last if $g =~ /TitelIndex/;
    $g =~ s/&amp;/&/g;
    print "$g\n";
  }
}

close $fh;

