use strict;
use warnings;

use File::Find qw(finddepth);

# Find missing pages from nested links in what we've got so far.
# As we don't know what's hiding, we don't recurse.
# parsed.text is the output from parse.pl on all deals.

if ($#ARGV != 0)
{
  print "Usage: nested.pl ignore > out.txt\n";
  exit;
}

my $dealdir = "../data/deals/found/";

my @pages;
list_pages(\@pages);

my (@deep_links, @top_links);

for my $page (@pages)
{
  my $base = $page;
  $base =~ s/.txt$//;

  open my $fh, "<", $page or die "Cannot open $page $!";
  while (my $line = <$fh>)
  {
    chomp $line;
    $line =~ s///g;
    parse_links(\$line, $base, \@deep_links, \@top_links);
  }
  close $fh;
}

# Strip the leading directory.
s/^$dealdir// for @deep_links;
s/^$dealdir// for @top_links;

for my $link (sort @deep_links)
{
  print "$link\n";
}
print "\n";

for my $link (sort @top_links)
{
  print "$link\n";
}



sub list_pages
{
  my ($list_ref) = @_;

  # https://stackoverflow.com/questions/2476019/how-can-i-recursively-read-out-directories-in-perl
  
  finddepth(
    sub
    {
      return if ($_ eq '.' || $_ eq '..');
      push @$list_ref, $File::Find::name;
    },
    $dealdir
  );

}


sub parse_links
{
  my ($line_ref, $base, $deep_links_ref, $top_links_ref) = @_;

  my @a = split /\[\[/, $$line_ref;
  return unless $#a > 0;

  for my $e (@a)
  {
    next if $e =~ /^attachment:([^]]*)\]\]/;

    if ($e =~ /([^]]*)\]\]/)
    {
      my @b = split /\|/, $1;
      if ($b[0] =~ /^\//)
      {
        push @$deep_links_ref, "$base$b[0]";
      }
      else
      {
        push @$top_links_ref, "$dealdir$b[0]";
      }
    }
  }
}



