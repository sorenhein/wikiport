use strict;
use warnings;

use HTML::TreeBuilder;
use HTML::FormatText;

require './names.pl';

# Parse some fields out of Wiki pages.

if ($#ARGV != 0)
{
  print "Usage: parse.pl files.txt > out.txt\n";
  exit;
}


my (%MIG_names, %MIG_mails);
set_MIG(\%MIG_names, \%MIG_mails);

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

    if ($line =~ /^\{\{\{#!html/)
    {
      my @parsed_lines;
      parse_embedded_HTML($fi, \@parsed_lines);

      for my $pline (@parsed_lines)
      {
        process_line(\$pline, \@attachments, \@links, \@mails_from, \@mails_to, 
          \@mails, \@websites, \@dates)
      }
    }
    elsif ($line =~ /^Von: / || $line =~ /^From: /)
    {
      if ($line =~ /An: / || $line =~ /To: /)
      {
        my @split_lines;
        parse_runon_line($line, \@split_lines);

        for my $sline (@split_lines)
        {
          process_line(\$sline, \@attachments, \@links, \@mails_from, \@mails_to, 
            \@mails, \@websites, \@dates)
        }
      }
      else
      {
        process_line(\$line, \@attachments, \@links, \@mails_from, \@mails_to, 
          \@mails, \@websites, \@dates);
      }
    }
    else
    {
      process_line(\$line, \@attachments, \@links, \@mails_from, \@mails_to, 
        \@mails, \@websites, \@dates);
    }
  }

  close $fi;

  print "$fline\n";
  print "=" x length($fline), "\n\n";

  print_count_list(\@mails_from, "Mails from");
  print_count_list(\@mails_to, "Mails to");
  print_count_list(\@mails, "Mails in text");

  print_list(\@dates, "Dates");
  print_date_range(\@dates);

  print_list(\@attachments, "Attachments");
  print_count_list(\@websites, "Websites");
  print_list(\@links, "Links");
  print "\n\n";

}

close $fh;


sub parse_embedded_HTML
{
  my ($fi, $lines_ref) = @_;

  my $html_string = "";
  while (1)
  {
    my $html_line = <$fi>;
    last if $html_line =~ /^\}\}\}/;
    $html_string .= $html_line;
  }
  my $tree = HTML::TreeBuilder->new->parse($html_string);
  $tree->eof();

  my $formatter = HTML::FormatText::->new(leftmargin => 0, rightmargin => 80);
  my $text = $formatter->format($tree);

  my @lines = split /\n/, $text;
  for my $line (@lines)
  {
    chomp $line;
    $line =~ s///g;
    next if $line =~ /^\s+$/;
    $line =~ s/[^\x00-\x7f]//g; # Wide characters
    push @$lines_ref, $line;
    # print "LINE .$line.\n";
  }
  # print $text;
}


sub parse_runon_line
{
  my ($line, $lines_ref) = @_;

  my @headers = ("An: ", "An:", "To: ", 
    "Cc: ", "Kopie: ",
    "Betreff: ", "Subject: ",
    "Datum: ", "Gesendet: ", "Sent: ");
# print "LINE BEFORE .$line.\n";
  for my $h (@headers)
  {
    $line =~ s/$h/\n$h/;
  }

  @$lines_ref = split /\n/, $line;

# print "LINES AFTER:\n";
# print ".$_.\n" for @$lines_ref;
}


sub process_line
{
  my ($line_ref, $attachments_ref, $links_ref, 
    $mails_from_ref, $mails_to_ref, $mails_ref,
    $websites_ref, $dates_ref) = @_;

  parse_attachments($line_ref, $attachments_ref);
  parse_links($line_ref, $links_ref);

  parse_mails_from($line_ref, $mails_from_ref);
  parse_mails_to($line_ref, $mails_to_ref);
  parse_mails($line_ref, $mails_ref);

  parse_websites($line_ref, $websites_ref);
  parse_dates($line_ref, $dates_ref);
}


sub parse_MIG_name
{
  my $name = pop;
  if (defined $MIG_names{$name})
  {
    return $MIG_names{$name};
  }
  else
  {
    return $name;
  }
}


sub parse_MIG_mail
{
  my $mail = pop;
  my $lcmail = lc $mail;
  if (defined $MIG_mails{$lcmail})
  {
    return $MIG_mails{$lcmail};
  }
  else
  {
    return $mail;
  }
}


sub respace_mail
{
  my $line_ref = pop;

  $$line_ref =~ s/^\s*'([^']*)'\s*/$1/;
  $$line_ref =~ s/^\s*"([^']*)"\s*/$1/;

  $$line_ref =~ s/\(\s/(/;
  $$line_ref =~ s/\s\)/)/;
  $$line_ref =~ s/<\s/</;
  $$line_ref =~ s/\s>/>/;
  $$line_ref =~ s/\[\s/[/;
  $$line_ref =~ s/\s\]/]/;

  $$line_ref =~ s/(\V)\(/$1 (/;
  $$line_ref =~ s/\)(\V)/) $1/;
  $$line_ref =~ s/(\V)</$1 </;
  $$line_ref =~ s/>(\V)/> $1/;
  $$line_ref =~ s/(\V)\[/$1 [/;
  $$line_ref =~ s/\](\V)/] $1/;

  $$line_ref =~ s/\s+/ /g;
  $$line_ref =~ s/^\s+//;
  $$line_ref =~ s/\s+$//;
}


sub parse_mail
{
  my ($line, $list_ref) = @_;

  respace_mail(\$line);

  my $name = "";
  my $mail = "";
  if ($line =~ /^\s*(.*)\s+\((.*)\)\s+<(.*)>\s*$/)
  {
    # Sören Hein (sh@mig.ag) <sh@mig.ag>
    # Sören Hein (mailto:sh@mig.ag) <mailto:sh@mig.ag>
    if ($2 eq $3)
    {
      $name = $1;
      $mail = $2;
      $mail = $1 if $mail =~ /^mailto:(.*)/;
    }
  }
  elsif ($line =~ /^\s*'(.*)\s+\((.*)\)'\s+<(.*)>\s*$/)
  {
    # 'Sören Hein (sh@mig.ag)' <sh@mig.ag>
    # 'Sören Hein (mailto:sh@mig.ag)' <mailto:sh@mig.ag>
    if ($2 eq $3)
    {
      $name = $1;
      $mail = $2;
      $mail = $1 if $mail =~ /^\s*mailto:(.*)/;
    }
  }
  elsif ($line =~ /^\s*(.*)\s+<(.*)>\s+\((.*)\)\s*$/)
  {
    # Sören Hein <sh@mig.ag> (sh@mig.ag)
    # Sören Hein <mailto:sh@mig.ag> (mailto:sh@mig.ag)
    if ($2 eq $3)
    {
      $name = $1;
      $mail = $2;
      $mail = $1 if $mail =~ /^\s*mailto:(.*)/;
    }
  }
  elsif ($line =~ /^\s*(.*)\s+\[\[mailto:(.*)\]\]\s*$/)
  {
    # Sören Hein [[mailto:sh@mig.ag]] (WTF?)
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*'(.*)\s+\[(.*)\]'\s*$/)
  {
    # 'Sören Hein [mailto:sh@mig.ag]'
    # 'Sören Hein [mig.ag]'
    $name = $1;
    $mail = $2;
    $mail = $1 if $mail =~ /^\s*mailto:(.*)/;
  }
  elsif ($line =~ /^\s*(.*)\s+\[(.*)\]\s*$/)
  {
    # Sören Hein [mailto:sh@mig.ag]
    # Sören Hein [mig.ag]
    $name = $1;
    $mail = $2;
    $mail = $1 if $mail =~ /^\s*mailto:(.*)/;
  }
  elsif ($line =~ /^\s*'(.*)\s+\((.*)\)'\s*$/)
  {
    # 'Sören Hein (mailto:sh@mig.ag)'
    # 'Sören Hein (sh@mig.ag)'
    $name = $1;
    $mail = $2;
    $mail = $1 if $mail =~ /^\s*mailto:(.*)/;
  }
  elsif ($line =~ /^\s*(.*)\s+\((.*)\)\s*$/)
  {
    # Sören Hein (mailto:sh@mig.ag)
    # Sören Hein (sh@mig.ag)
    $name = $1;
    $mail = $2;
    $mail = $1 if $mail =~ /^\s*mailto:(.*)/;
    if ($mail !~ /\@/)
    {
      # Sören Hein (E-Mail)
      $name .= " ($mail)";
      $mail = "";
    }
  }
  elsif ($line =~ /^\s*(.*)\s+<(.*)>\s*$/)
  {
    # "Sören Hein" <mailto:sh@mig.ag>
    # 'Sören Hein' <mailto:sh@mig.ag>
    # "'Sören Hein." <mailto:sh@mig.ag> (WTF?)
    # Sören Hein <mailto:sh@mig.ag>
    # Sören Hein <sh@mig.ag>
    $name = $1;
    $mail = $2;
    $mail =~ s/^\s+//;
    $mail =~ s/\s+$//;

    $name = $1 if $name =~ /^"(.*)"$/;
    $name = $1 if $name =~ /^'(.*)'$/;
    $name = $1 if $name =~ /^\s*mailto:(.*)/;
    $mail = $1 if $mail =~ /^\s*mailto:(.*)/;
  }
  elsif ($line =~ /^\s*mailto:(.*)\s+mailto:(.*)\s*$/)
  {
    # mailto:sh@mig.ag mailto:sh@mig.ag
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*(.*)\s+mailto:(.*)\s*$/)
  {
    # Sören Hein mailto:sh@mig.ag
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*<(.*)>$/)
  {
    # <sh@mig.ag>
    # <mailto:sh@mig.ag>
    $mail = $1;
    $mail = $1 if $mail =~ /^\s*mailto:(.*)/;
  }
  elsif ($line =~ /^\s*\((.*)\)/)
  {
    # (sh@mig.ag)
    # (mailto:sh@mig.ag)
    $mail = $1;
    $mail = $1 if $mail =~ /^\s*mailto:(.*)/;
  }
  elsif ($line =~ /^\s*mailto:(.*)\s*$/)
  {
    # mailto:sh@mig.ag
    $mail = $1;
  }
  else
  {
    $name = $line;
  }

  if ($name =~ /^"(.*)"$/ || $name =~ /^'(.*)'$/)
  {
    $name = $1;
  }

  return if $name eq "" && $mail eq "";

  if (($mail eq $name || $mail eq "") && $name =~ /@/)
  {
    $mail = $name;
    $name = "";
  }

# print "GOT .$name., .$mail.\n";

  $name = parse_MIG_name($name) if $name ne "";
  $mail = parse_MIG_mail($mail) if $mail ne "";


  if ($name eq $mail)
  {
    $mail = "";
  }

# print "FOUND .$name., .$mail.\n";

  my $res;
  if ($mail eq "")
  {
    $res = $name;
  }
  elsif ($name eq "")
  {
    $res = $mail;
  }
  else
  {
    $res = "$name ($mail)";
  }

# print "RES .$res.\n";
  push @$list_ref, $res;
}


sub clean_line
{
  my $line = pop;

  $line =~ s/^\s+//;
  $line =~ s/\s+$//;
  $line =~ s/\xc2\xa0/ /g;

  return $line;
}


sub parse_mails_from
{
  my ($line_ref, $list_ref) = @_;

  $$line_ref = clean_line($$line_ref);

  my $field = "";
  $field = $1 if $$line_ref =~ /^Von:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^From:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^De:\s+(.*)$/;

  return if $field eq "";

  if ($field =~ /(.*) Im Auftrag von (.*)/)
  {
    my $field1 = $1;
    my $field2 = $2;
    parse_mail($field1, $list_ref);
    parse_mail($field2, $list_ref);
  }
  else
  {
    parse_mail($field, $list_ref);
  }
  $$line_ref = "";
}


sub find_quote_ranges
{
  my ($line, $quote, $qref) = @_;

  my $l = length($line);
  my $index = 0;
  my $open = 0;
  while ($index < $l)
  {
    my $nextd = index($line, $quote, $index);
    if ($nextd == -1)
    {
      if ($open)
      {
        print "WARNING Dangling quote\n";
        push @$qref, [$index, $l];
      }
      last;
    }
    elsif ($open)
    {
      push @$qref, [$index, $nextd-1];
      $index = $nextd+1;
      $open = 0;
    }
    else
    {
      $index = $nextd+1;
      $open = 1;
    }
  }
}


sub is_quotable_comma
{
  my ($i, $qref) = @_;

  foreach my $r (@$qref)
  {
    if ($i >= $r->[0] && $i <= $r->[1])
    {
      return 0;
    }
  }
  return 1;
}


sub find_quotable_commas
{
  my ($line, $qref, $cref) = @_;

  my $l = length($line);
  my $index = 0;
  while ($index < $l)
  {
    my $nextc = index($line, ',', $index);
    last if $nextc == -1;
    if (is_quotable_comma($nextc, $qref))
    {
      push @$cref, $nextc;
    }
    $index = $nextc+1;
  }

}

sub parse_mails_to
{
  my ($line_ref, $list_ref) = @_;

  $$line_ref = clean_line($$line_ref);

  my $field = "";
  $field = $1 if $$line_ref =~ /^An:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^To:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^A:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^Kopie:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^Cc:\s+(.*)$/;

  return if $field eq "";
  $field =~ s/,$//; # WTF?

  # If there are semi-colons, we won't split on commas.
  my @a = split /;/, $field;

  if ($#a == 0 && $a[0] =~ /,/)
  {
# print "HERE .$$line_ref.\n";
    # Find quoted ranges.  We won't split within them.
    my @quoteRanges = ();
    find_quote_ranges($a[0], '"', \@quoteRanges);
# print "HERE2 .$$line_ref.\n";
    find_quote_ranges($a[0], "'", \@quoteRanges);
# print "HERE3 .$$line_ref.\n";

if ($#quoteRanges >= 0)
{
  # print "QUOTE\n";
}

    my @commas;
    find_quotable_commas($a[0], \@quoteRanges, \@commas);
# print "HERE4 .$$line_ref.\n";

    my $index = 0;
    my @b;
    for my $c (@commas)
    {
      my $cand = substr($a[0], $index, $c-$index);

      # Preceding interval should probably have an @,
      # i.e. should look like a mail address.

      if ($cand =~ /\@/)
      {
        push @b, $cand;
        $index = $c+1;
      }
    }

    push @b, substr($a[0], $index);

    if ($#b > 0)
    {
# print "FOUND A COMMA\n";
      @a = @b;
    }
    # else
    # {
# print "NO COMMA\n";
    # }

  }

  my $found = 0;
  for my $m (@a)
  {
    next if $m eq "";
    $found = 1;
    $m =~ s/"//g;
# print "MAILTO .$m.\n";
if ($m =~ /Motsch/)
{
  # print "HERE\n";
}
    parse_mail($m, $list_ref);
  }

  $$line_ref = "" if $found;
}


sub parse_mails
{
  my ($line_ref, $list_ref) = @_;

  $$line_ref = clean_line($$line_ref);

  # Only look for the actual mail with the @ symbol, not for the name.
  my @a = split /[ ,;:\=\<\>\(\)"\[\]]+/, $$line_ref;

  for my $m (@a)
  {
    next unless $m =~ /\@/;
# print "FREETEXT .$m.\n";
    $m =~ s/\.$//;
    parse_mail($m, $list_ref);
  }
}


sub parse_date
{
  my ($line, $list_ref) = @_;

  my ($weekday, $day, $month, $year);
  if ($line =~ /(\w+tag), (\d+)\. (\w+) (\d+)\s+/)
  {
    $day = $2;
    $month = $3;
    $year = $4;
  }
  elsif ($line =~ /(\d\d\d\d)\/(\d\d)\/(\d\d)/)
  {
    $day = $3;
    $month = $2;
    $year = $1;
  }
  elsif ($line =~ /(\d?\d)\.(\d\d)\.(\d\d\d?\d?)/)
  {
    $day = $1;
    $month = $2;
    $year = $3;
    $year += 2000 if $year < 100;
  }
  else
  {
    print "ODD DATE .$line.\n";
  }

  return if ($day <= 0 || $day > 31 || 
    $month <= 0 || $month > 12 || 
    $year < 2000);

  $day .= "0" if ($day < 10 && length($day) == 1);

  my $date = $year . '-' . $month . "-" . $day;
  push @$list_ref, $date;

}


sub parse_dates
{
  my ($line_ref, $list_ref) = @_;

  $$line_ref = clean_line($$line_ref);

  my $field = "";
  $field = $1 if $$line_ref =~ /^Gesendet:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^Datum:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^Sent:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^Date:\s+(.*)$/;

  if ($field eq "")
  {
    if ($$line_ref =~ /(\d?\d\.\d\d\.\d\d\d?\d?)/)
    {
      $field = $1;
    }
    return if $field eq "";
    parse_date($field, $list_ref);
  }
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

  $$line_ref =~ s/\[\[[^]]*\]\]//g;
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
  $$line_ref =~ s/\[\[[^]]*\]\]//g;
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

  print "$_\n" for sort @$list_ref;
  print "\n";
}


sub print_date_range
{
  my $dref = pop;
  my @d = sort @$dref;
  return if $#d <= 0;

  $d[0] =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
  my ($y1, $m1, $d1) = ($1, $2, $3);

  if (! defined $y1)
  {
    print "ODD YEAR\n";
  }

  $d[$#d] =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
  my ($y2, $m2, $d2) = ($1, $2, $3);

  my $diff = 365 * ($y2-$y1) + 30 * ($m2-$m1) + ($d2-$d1);

  print "Approx. $diff days in process\n\n";
}


sub print_count_list
{
  my ($list_ref, $name) = @_;
  return unless $#$list_ref >= 0;

  print_sub_header($name);

  my %h;
  $h{$_}++ for @$list_ref;

  my @MIG;
  for my $k (sort keys %h)
  {
    if ($k =~ /^MIG:/)
    {
      push @MIG, $k;
    }
    else
    {
      printf "%2d %s\n", $h{$k}, $k;
    }
  }

  for my $k (sort @MIG)
  {
    printf "%2d %s\n", $h{$k}, $k;
  }

  print "\n";
}
