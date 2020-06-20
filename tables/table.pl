#!perl

use strict;
use warnings;

if ($#ARGV < 0)
{
  print "Usage: table.pl Prüfung_*.txt > out.txt\n";
  exit;
}

# Output the files per year that we got and didn't get.
my %seen;
set_seen(\%seen);

my %headers;
set_header(\%headers);

my %tag_histo;
my @deals;

for my $file (@ARGV)
{
  if ($file !~ /Pr.+fung_(..)_20(..).txt/)
  {
    print "Skipping file $file\n";
    next;
  }

  my $month_no = $1;
  my $year_no = $2;
  $seen{$year_no}{$month_no} = 1;

  my $file_tag = '20' . $year_no . '-' . $month_no;

  print("Trying $file\n");
  $tag_histo{$file_tag} = 0;

  read_file($file, 
    $file_tag,
    \%tag_histo,
    \%headers, 
    \@deals);
}

for my $tag (sort keys %tag_histo)
{
  printf("%8s: %d\n", $tag, $tag_histo{$tag});
}


sub set_seen
{
  my $seen_ref = pop;
  for my $year (2006 .. 2020)
  {
    my $y = sprintf("%0d", $year-2000);
    for my $month (1 .. 12)
    {
      my $m = sprintf("%0d", $month);
      $seen_ref->{$y}{$m} = 0;
    }
  }
}


sub read_file
{
  my ($file, $file_tag, $tag_histo_ref, $headers_ref, $deals_ref) = @_;

  open my $fh, "<", $file or die "Cannot open $file $!";

  my $state = 0; # Starting out
  my @header_map;
  my $count  = 0;

  while (my $line = <$fh>)
  {
    chomp $line;
    $line =~ s///g;
    next if $line =~ /^\s*$/;

    last if $line =~ /Sonstige Beteiligungsangebote/;
    last if $line =~ /Emails an diese Seite/;
    last if $line =~ /mail_overview/;

    my @a = split /\|\|/, $line;
    next unless $#a >= 1;

    if ($state == 0 && $#a == 1 && $a[1] =~ /tablewidth/)
    {
      $line = <$fh>; # Now at the header line
      chomp $line;
      $line =~ s///g;

      if (! parse_header_line($line, $headers_ref, \@header_map))
      {
        print "Giving up on $file\n";
        return;
      }

      @a = split /\|\|/, $line;
      $count = $#a;

      $line = <$fh>; # Now at the format line which will be skipped
      $state = 1;
    }
    elsif ($state == 1)
    {
      if ($#a >= 1 && $#a != $count)
      {
        print("line '$line':\n");
        print("Surprise count: $#a vs. expected $count\n");
        next;
      }

      $tag_histo_ref->{$file_tag}++;
      # print("Added $line, count now $tag_histo_ref->{$file_tag}\n");
      parse_deal_line($file_tag, \@header_map, \@a, $deals_ref);
      
    }
  }
  close $fh;
}


sub set_header
{
  my ($headers_ref, $tag) = @_;

  $headers_ref->{'Nr.#'} = 0;

  $headers_ref->{'Eingang'} = 1;
  $headers_ref->{'Eingangsdatum'} = 1;

  $headers_ref->{'Firma/Projektname'} = 2;

  $headers_ref->{'WWW'} = 3;

  $headers_ref->{'Ansprechpartner'} = 4;

  $headers_ref->{'Sektor'} = 5;

  $headers_ref->{'Beschreibung'} = 6;

  $headers_ref->{'Kommentar'} = 7;

  $headers_ref->{'Status'} = 8;

  $headers_ref->{'Bewertung'} = 9;

  $headers_ref->{'Link'} = 10;

  $headers_ref->{'Ursprung'} = 11;

  $headers_ref->{'Zust.'} = 12;

  # 13 is file_tag.
}


sub parse_header_line
{
  my ($line, $headers_ref, $header_map_ref) = @_;

  # print "Header line $line\n";
  my @a = split /\|\|/, $line;
  if ($#a < 1)
  {
    print("Not enough header fields in $line\n");
    return 0;
  }

  for my $n (1 .. $#a)
  {
    my $e = $a[$n];
    $e =~ /'''\s*(\S*)'''/;
    my $f = $1;
    if (! defined $headers_ref->{$f})
    {
      print("Header '$f' not found\n");
      return 0;
    }

    # print("Got $f, mapped to ", $headers_ref->{$f}, "\n");
    $header_map_ref->[$n] = $headers_ref->{$f};
  }
  return 1;
}


sub parse_deal_line
{
  my ($file_tag, $header_map_ref, $fields_ref, $deals_ref) = @_;

  my @deal;
  $deal[13] = $file_tag;
  for my $n (1 .. $#$fields_ref)
  {
    $deal[$header_map_ref->[$n]] = $fields_ref->[$n];
  }

  if ($#$deals_ref >= 0)
  {
    check_deal_number($deals_ref->[-1][0], $deal[0]);
  }

  push @$deals_ref, \@deal;
}


sub get_deal_count
{
  my $s = pop;
  $s =~ s/(\d+)\/\d+\s*$/$1/;
  return $1;
}


sub print_deal
{
  my $dref = pop;
  for my $n (0 .. 13)
  {
    printf("%2d\t%s\n", $n, $dref->[$n]);
  }
}


sub check_deal_number
{
  my ($old_deal_ref, $new_deal_ref) = @_;
  my $old_no = get_deal_count($old_deal_ref);
  my $new_no = get_deal_count($new_deal_ref);

  if ($new_no != 1 && $new_no != $old_no+1)
  {
    print("Warning deal numbers $old_no, $new_no\n");
  }
}

