#!perl

use strict;
use warnings;

# Parse some fields out of Wiki pages.

if ($#ARGV != 0)
{
  print "Usage: parse.pl files.txt > out.txt\n";
  exit;
}


my $file = $ARGV[0];

open my $fh, "<", $file or die "Cannot open $file: $!";

while (my $fline = <$fh>)
{
  chomp $fline;
  $fline =~ s///g;

  open my $fi, "<", $fline or die "Cannot open $fline: $!";

  my (@mails_from, @mails_to, @mails, @dates, @attachments, @websites, @links);
  
  while (my $line = <$fi>)
  {
    chomp $line;
    $line =~ s///g;

    # parse_mails_from(\$line, \@mails_from);
    # parse_mails_to(\$line, \@mails_from);
    # parse_mails(\$line, \@mails_from);
    # parse_dates(\$line, \@dates);
    parse_attachments(\$line, \@attachments);
    parse_websites(\$line, \@websites);
    parse_links(\$line, \@links);
  }

  close $fi;

  print "$fline\n";
  print "=" x length($fline), "\n\n";

  print_list(\@attachments, "Attachments");
  print_count_list(\@websites, "Websites");
  print_list(\@links, "Links");

}

close $fh;



sub parse_mails_from
{
  my ($line_ref, $list_ref) = @_;
}


sub parse_mails_to
{
  my ($line_ref, $list_ref) = @_;
}


sub parse_mails
{
  my ($line_ref, $list_ref) = @_;
}


sub parse_dates
{
  my ($line_ref, $list_ref) = @_;
}


sub parse_attachments
{
  my ($line_ref, $list_ref) = @_;

  my @a = split /\[\[/, $$line_ref;
  return unless $#a > 0;

  for my $e (@a)
  {
    if ($e =~ /^attachment:([^]]*)\]\]/)
    {
      my @b = split /\|/, $1;
      push @$list_ref, $b[0];
    }
  }
}


sub parse_websites
{
  my ($line_ref, $list_ref) = @_;

  my @a = split /[,;|\s\xa0]+/, $$line_ref;
  for my $e (@a)
  {
    if ($e =~ /www\./ || $e =~ /^http/)
    {
      $e =~ s/\.$//;
      $e =~ s/\/$//;
      next if $e =~ /facebook/i;
      next if $e =~ /linkedin/i;
      next if $e =~ /twitter/i;
      next if $e =~ /www.mig.ag/i;
      push @$list_ref, $e;
    }
  }
}


sub parse_links
{
  my ($line_ref, $list_ref) = @_;

  my @a = split /\[\[/, $$line_ref;
  return unless $#a > 0;

  for my $e (@a)
  {
    next if $e =~ /^attachment:/;
    if ($e =~ /([^]]*)\]\]/)
    {
      my @b = split /\|/, $1;
      push @$list_ref, $b[0];
    }
  }
}


sub print_sub_header
{
  my $name = pop;
  print "$name\n";
  print "-" x length($name), "\n";
}


sub print_list
{
  my ($list_ref, $name) = @_;
  return unless $#$list_ref >= 0;

  print_sub_header($name);

  print "$_\n" for @$list_ref;
  print "\n";
}


sub print_count_list
{
  my ($list_ref, $name) = @_;
  return unless $#$list_ref >= 0;

  print_sub_header($name);

  my %h;
  $h{$_}++ for @$list_ref;

  for my $k (sort keys %h)
  {
    printf "%2d %s\n", $h{$k}, $k;
  }
  print "\n";
}
