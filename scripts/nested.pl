use strict;
use warnings;

use File::Find qw(finddepth);

# Find missing pages from nested links in what we've got so far.
# As we don't know what's hiding, we don't recurse.
#
# Usage: perl nested.pl > out.txt

my $dealdir = "../data/deals/found/";

my %pages;
list_pages(\%pages);

my %pages_short;
shorten_pages(\%pages, \%pages_short);

# Dead links don't have to be downloaded again.
my %deadlinks;
my $deadfile = "deadlinks.txt";
read_file($deadfile, \%deadlinks);


my (%deep_links, %top_links);

for my $page (keys %pages)
{
  my $base = $page;
  $base =~ s/.txt$//;
  my $basebase = $base;
  $basebase =~ s/^$dealdir//;

  open my $fh, "<", $page or die "Cannot open $page $!";
  while (my $line = <$fh>)
  {
    chomp $line;
    $line =~ s///g;
    next if $line =~ /^##/; # Skip comments
    parse_links(\$line, $base, $basebase, \%deep_links, \%top_links);
  }
  close $fh;
}

my (%deep_short, %top_short);
shorten_links(\%deep_links, \%deep_short);
shorten_links(\%top_links, \%top_short);

for my $link (sort keys %deep_short)
{
  print "$link\n";
}
print "\n";

for my $link (sort keys %top_short)
{
  print "$link\n";
}



sub list_pages
{
  my ($pages_ref) = @_;

  # https://stackoverflow.com/questions/2476019/how-can-i-recursively-read-out-directories-in-perl
  
  finddepth(
    sub
    {
      return if ($_ eq '.' || $_ eq '..');
      my $name = $File::Find::name;
      $pages_ref->{$name} = 1;
    },
    $dealdir
  );
}


sub shorten_links
{
  my ($links_ref, $short_ref) = @_;
  for my $k (keys %$links_ref)
  {
    my $s = $k;
    $s =~ s/^$dealdir//;
    $short_ref->{$s} = 1;
  }
}


sub shorten_pages
{
  my ($pages_ref, $short_ref) = @_;
  for my $k (keys %$pages_ref)
  {
    my $s = $k;
    $s =~ s/.txt$//;
    $short_ref->{$s} = 1;
  }
}


sub read_file
{
  my ($deadfile, $deadlinks_ref) = @_;
  open my $fd, "<", $deadfile or die "Cannot open $deadfile: $!";
  while (my $line = <$fd>)
  {
    chomp $line;
    $line =~ s///g;
    $deadlinks_ref->{$dealdir . $line} = 1;
  }
  close $fd;
}


sub parse_links
{
  my ($line_ref, $base, $basebase, $deep_links_ref, $top_links_ref) = @_;

  my @a = split /\[\[/, $$line_ref;
  return unless $#a > 0;

  for my $e (@a)
  {
    next if $e =~ /^attachment:([^]]*)\]\]/;
    next if $e =~ /^mailto/;

    if ($e =~ /([^]]*)\]\]/)
    {
      my @b = split /\|/, $1;
      # Add our ugly __ directory format.
      my $underscored = $b[0];
      $underscored =~ s/\//___\//g;

      if ($b[0] =~ /^\//)
      {
        my $cand = "$base$underscored";
        $deep_links_ref->{$cand} = 1 unless 
          (defined $pages_short{$cand} ||
           defined $deadlinks{$cand});
      }
      else
      {
        my $cand = "$dealdir$underscored";

        # Could still be a deep link into our own structure,
        # but stated as an absolute link.  So APK may link to
        # [[APK/Lizenzmodell].
        if ($b[0] =~ /^$basebase\//)
        {
          $deep_links_ref->{$cand} = 1 unless 
            (defined $pages_short{$cand} ||
             defined $deadlinks{$cand});
        }
        else
        {
          $top_links_ref->{$cand} = 1 unless 
            (defined $pages_short{$cand} &&
             defined $deadlinks{$cand});
        }
      }
    }
  }
}



