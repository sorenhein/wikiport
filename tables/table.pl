#!perl

use strict;
use warnings;

use constant
{
  NUMBER => 0,
  DATE_IN => 1,
  COMPANY => 2,
  URL => 3,
  CONTACT => 4,
  SECTOR => 5,
  DESCRIPTION => 6,
  COMMENT => 7,
  STATUS => 8,
  ASSESSMENT => 9,
  WIKI => 10,
  ATTACH => 11,
  SOURCE => 12,
  OWNER => 13,
  FILE_MONTH => 14,
  DATE_MONTH =>  15
};

my @header_names =
(
  'Number',
  'Date',
  'Company',
  'URL',
  'Contact',
  'Sector',
  'Description',
  'Comment',
  'Status',
  'Grade',
  'Wiki',
  'Link',
  'Source',
  'Owner',
  'File month',
  'Date month'
);

my @print_fields =
(
  NUMBER,
  COMPANY,
  DESCRIPTION,
  COMMENT,
  WIKI,
  DATE_IN,
  FILE_MONTH,
  DATE_MONTH
);

my $unspecific = "../parseraw/tmp/partition/unspecific.txt";


if ($#ARGV < 0)
{
  print "Usage: table.pl Prüfung_*.txt > out.txt\n";
  exit;
}

# Read the list of deals to skip as they are too unspecific.
my %unspecifics;
read_unspecific(\%unspecifics);


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
    \%unspecifics,
    \%tag_histo,
    \%headers, 
    \@deals);
}

# Did we use all the unspecific deals?
for my $k (sort keys %unspecifics)
{
  if ($unspecifics{$k} != 2)
  {
    print "Odd unspecific deal: $k\n";
  }
}

for my $tag (sort keys %tag_histo)
{
  printf("%8s: %d\n", $tag, $tag_histo{$tag});
}

# Find deals that are close in time and that have the
# same Wiki link.

my %deals_by_link;
for my $dref (@deals)
{
  push @{$deals_by_link{$dref->[WIKI]}}, $dref;
}

my (@real_deals, @double_deals, @prufung_deals);
for my $wiki (sort keys %deals_by_link)
{
  # Deals without an own wiki page are not duplicates.
  if ($wiki =~ /Pr.+fung/)
  {
    my @a = @{$deals_by_link{$wiki}};
    for my $dref (@a)
    {
      push @prufung_deals, $dref;
    }
    next;
  }

  if ($#{$deals_by_link{$wiki}} == 0)
  {
    push @real_deals, $deals_by_link{$wiki}[0];
    next;
  }

  my @a = @{$deals_by_link{$wiki}};
  divide_by_time_gap(\@a, \@real_deals, \@double_deals);
}



print "\n";
print "Real deals: ", 1+$#real_deals, "\n";
print_csv(\@real_deals);

print "\n";
print "Prüfung deals: ", 1+$#prufung_deals, "\n";
print_csv(\@prufung_deals);

print "\n";
print "Double deals: ", 1+$#double_deals, "\n";
print_csv(\@double_deals);


sub read_unspecific
{
  my $unsp_ref = pop;
  open my $fu, "<", $unspecific or die "Cannot open $unspecific $!";

  while (my $line = <$fu>)
  {
    $line =~ /^(\d+\/\d+)\s+/;
    $unsp_ref->{$1} = 1;
  }
  close $fu;
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
  my ($file, $file_tag, $unspec_ref, $tag_histo_ref, $headers_ref, $deals_ref) = @_;

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
      parse_deal_line($file_tag, $unspec_ref, \@header_map, \@a, $deals_ref);
      
    }
  }
  close $fh;
}


sub set_header
{
  my ($headers_ref, $tag) = @_;

  $headers_ref->{'Nr.#'} = NUMBER;

  $headers_ref->{'Eingang'} = DATE_IN;
  $headers_ref->{'Eingangsdatum'} = DATE_IN;

  $headers_ref->{'Firma/Projektname'} = COMPANY;
  $headers_ref->{'Firma'} = COMPANY;

  $headers_ref->{'WWW'} = URL;

  $headers_ref->{'Ansprechpartner'} = CONTACT;

  $headers_ref->{'Sektor'} = SECTOR;

  $headers_ref->{'Beschreibung'} = DESCRIPTION;
  $headers_ref->{'Projektname'} = DESCRIPTION;

  $headers_ref->{'Kommentar'} = COMMENT;

  $headers_ref->{'Status'} = STATUS;

  $headers_ref->{'Bewertung'} = ASSESSMENT;

  $headers_ref->{'Link'} = ATTACH;

  $headers_ref->{'Ursprung'} = SOURCE;

  $headers_ref->{'Zust.'} = OWNER;

  $headers_ref->{'File month'} = FILE_MONTH;

  $headers_ref->{'Date month'} = DATE_MONTH;
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


sub parse_deal_date
{
  my $dref = pop;
  my $d = $dref->[DATE_IN];
  $d =~ /^\s*(\d\d).(\d\d).(\d\d)\s*$/;
  my ($day, $month, $year) = ($1, $2, $3);

  if ($year < 4 ||$year > 20)
  {
    print "Date $d: Year warning ($year)\n";
  }

  if ($month < 1 || $month > 12)
  {
    print "Date $d: Month warning ($month)\n";
  }

  if ($day < 1 || $day > 31)
  {
    print "Date $d: Day warning ($day)\n";
  }

  $dref->[DATE_MONTH] = '20' . $year . '-' . $month;

  if ($dref->[DATE_MONTH] ne $dref->[FILE_MONTH])
  {
    my $y0 = substr($dref->[FILE_MONTH], 0, 4);
    my $m0 = substr($dref->[FILE_MONTH], 5, 2);

    my $delta = 12 * (2000 + $year - $y0) + $month - $m0;
    if ($delta < -2 || $delta > 2)
    {
      print "Deal: ", $dref->[COMPANY], ": delta ", $delta, "\n";
      print "Date mismatch warning: $dref->[DATE_MONTH] vs ",
        $dref->[FILE_MONTH], "\n";
      # print "$year, $month; $y0, $m0\n";
    }
  }
}


sub fix_deal_name
{
  my $dref = pop;
  my $name = $dref->[COMPANY];
  if ($name !~ /'''/ && $name !~ /^\s*$/)
  {
    print "Not bold:\n";
    print_csv_deal($dref);
  }

  $name =~ s/'''//g;

  if ($name !~ /\[\[/)
  {
    $name =~ s/^\s*//;
    $name =~ s/\s*$//;
    $dref->[COMPANY] = $name;

    $dref->[WIKI] = "https://info.mig.ag/Prüfung_" .
      substr($dref->[FILE_MONTH], 5, 2) . "_" .
      substr($dref->[FILE_MONTH], 0, 4);
  }
  else
  {
    $name =~ s/\[\[//;
    $name =~ s/\]\]//;
    $name =~ s/^\s*//;
    $name =~ s/\s*$//;
    $dref->[COMPANY] = $name;

    $dref->[WIKI] = "https://info.mig.ag/" . $name;
  }
}


sub fix_date_in
{
  my $dref = pop;
  my $date = $dref->[DATE_IN];
  $date =~ s/^\s*//;
  $date =~ s/\s*$//;
  $dref->[DATE_IN] = $date;
}


sub parse_deal_line
{
  my ($file_tag, $unspec_ref, $header_map_ref, $fields_ref, $deals_ref) = @_;

  my @deal;
  $deal[$_] = '' for 0 .. DATE_MONTH;
  $deal[FILE_MONTH] = $file_tag;

  for my $n (1 .. $#$fields_ref)
  {
    $deal[$header_map_ref->[$n]] = $fields_ref->[$n];
  }

  # Wiki may have trailing spaces.
  $deal[NUMBER] =~ s/\s+$//;

  if ($#$deals_ref >= 0)
  {
    check_deal_number($deals_ref->[-1][0], $deal[NUMBER]);
  }

  if (defined $unspec_ref->{$deal[NUMBER]})
  {
    print "Skipping unspecific deal ", $deal[COMPANY], ", ", 
      $deal[NUMBER], "\n";
    $unspec_ref->{$deal[NUMBER]}++;
    return;
  }

  parse_deal_date(\@deal);

  fix_deal_name(\@deal);
  fix_date_in(\@deal);

  push @$deals_ref, \@deal;
}


sub get_deal_count
{
  my $s = pop;
  $s =~ s/(\d+)\/\d+\s*$/$1/;
  return $1;
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


sub print_csv_header
{
  for my $n (@print_fields)
  # for my $n (0 .. DATE_MONTH)
  {
    printf("%2s;", $header_names[$n]);
  }
  print "\n";
}


sub print_csv_deal
{
  my $dref = pop;
  # for my $n (0 .. DATE_MONTH)
  for my $n (@print_fields)
  {
    if ($dref->[$n] =~ /;/)
    {
      $dref->[$n] = '"' . $dref->[$n] . '"';
    }
    print "$dref->[$n];";
  }
  print "\n";
}


sub print_csv
{
  my $deals_ref = pop;
  print_csv_header();
  for my $dref (@$deals_ref)
  {
    print_csv_deal($dref);
  }
}


sub push_right_list
{
  my ($dist_list_ref, $double_list_ref, $distinct_flag, $to_push) = @_;
  if ($distinct_flag)
  {
    push @$dist_list_ref, $to_push;
  }
  else
  {
    push @$double_list_ref, $to_push;
  }
}


sub divide_by_time_gap
{
  my ($list_ref, $use_ref, $double_ref) = @_;

  for my $dref (@$list_ref)
  {
    my $d = substr($dref->[DATE_IN], 0, 2);
    my $m = substr($dref->[DATE_IN], 3, 2);
    my $y = substr($dref->[DATE_IN], 6, 2);
    $dref->[16] = 365*$y + 30*$m + $d;
  }
  my @c = sort {$a->[16] <=> $b->[16]} @$list_ref;

  # Can be a bit tricky to punch out the smallest number of duplicates.
  if ($#c == 1)
  {
    # Two deals are easy.
    my $distinct_flag = ($c[1][16] - $c[0][16] > 330);
    push_right_list($use_ref, $double_ref, $distinct_flag, \@{$c[1]});
    push @$use_ref, $c[0];
  }
  else
  {
    for (my $n = $#c; $n >= 1; $n--)
    {
      if ($c[$n][16] - $c[$n-1][16] > 330)
      {
        push @$use_ref, $c[$n];
      }
      elsif ($n >= 2 && 
            $c[$n][16] - $c[$n-2][16] > 330 &&
            $c[$n-1][16] - $c[$n-2][16] <= 330)
      {
        # Rather than punching out n and n-1, we can just punch out n-1.
        push @$use_ref, $c[$n];
      }
      else
      {
        push @$double_ref, $c[$n];
      }
    }
    push @$use_ref, $c[0];
  }
}
