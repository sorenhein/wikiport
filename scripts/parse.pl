use strict;
use warnings;

use HTML::TreeBuilder;
use HTML::FormatText;

require './names.pl';
require './websites.pl';

my $DEBUG_MAIL = 0;

# Parse some fields out of Wiki pages.

if ($#ARGV != 0)
{
  print "Usage: parse.pl files.txt > out.txt\n";
  exit;
}


my (%MIG_names, %MIG_mails);
set_MIG(\%MIG_names, \%MIG_mails);

my %websites_skip;
set_websites(\%websites_skip);

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

  my $formatter = HTML::FormatText::->new(leftmargin => 0, rightmargin => 300);
  my $text = $formatter->format($tree);
  
  if ($text =~ /An: / || $text =~ /To: /)
  {
    parse_runon_line_to_text(\$text);
  }

  my @lines = split /\n/, $text;
  for my $line (@lines)
  {
    chomp $line;
    $line =~ s///g;
    next if $line =~ /^\s+$/;
    $line =~ s/[^\x00-\x7f]//g; # Wide characters
    push @$lines_ref, $line;
  }
}


sub parse_runon_line_to_text
{
  my $line_ref = pop;

  my @headers = (
    "Von: ", "From: ",
    "An: ", "An:", "To: ", 
    "Cc: ", "Kopie: ",
    "Betreff: ", "Subject: ",
    "Datum: ", "Gesendet: ", "Sent: ");

  for my $h (@headers)
  {
    $$line_ref =~ s/$h/\n$h/;
  }
}


sub parse_runon_line
{
  my ($line, $lines_ref) = @_;

  $line = parse_runon_line_to_text(\$line);
  @$lines_ref = split /\n/, $line;
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

  parse_websites(\%websites_skip, $line_ref, $websites_ref);
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

  $$line_ref =~ s/mailto://g;
}


sub pure_comma_text
{
  my ($name, $list_ref) = @_;
  my @a = split ',', $name;
  return 0 unless $#a > 0;

  my @b;
  my $found = 0;
  for my $n (@a)
  {
    $n =~ s/^\s+//;
    $n =~ s/\s+$//;
    my $m = parse_MIG_name($n);
    push @b, $m;
    $found = 1 if $m ne $n;
  }

  return 0 unless $found;

  push @$list_ref, $_ for @b;
  return 1;
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
    if ($2 eq $3)
    {
      $name = $1;
      $mail = $2;
    }
  }
  elsif ($line =~ /^\s*'(.*)\s+\((.*)\)'\s+<(.*)>\s*$/)
  {
    # 'Sören Hein (sh@mig.ag)' <sh@mig.ag>
    if ($2 eq $3)
    {
      $name = $1;
      $mail = $2;
    }
  }
  elsif ($line =~ /^\s*(.*)\s+<(.*)>\s+\((.*)\)\s*$/)
  {
    # Sören Hein <sh@mig.ag> (sh@mig.ag)
    if ($2 eq $3)
    {
      $name = $1;
      $mail = $2;
    }
  }
  elsif ($line =~ /^\s*(.*)\s+\[(.*)\]\s+\((.*)\)\s*$/)
  {
    # Sören Hein [sh@mig.ag] (sh@mig.ag)
    if ($2 eq $3)
    {
      $name = $1;
      $mail = $2;
    }
  }
  elsif ($line =~ /^\s*(.*)\s+\[(.*)\]\s+\[(.*)\]\s*$/)
  {
    # Sören Hein [sh@mig.ag] [sh@mig.ag]
    if ($2 eq $3)
    {
      $name = $1;
      $mail = $2;
    }
  }
  elsif ($line =~ /^\s*<(.*)>\s+\((.*)\)\s*$/)
  {
    # <sh@mig.ag> (sh@mig.ag)
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*<(.*)>\s+<(.*)>\s*$/)
  {
    # <sh@mig.ag> <sh@mig.ag>
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*(.*)\s+\[\[(.*)\]\]\s*$/)
  {
    # Sören Hein [[sh@mig.ag]] (WTF?)
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*(.*)\s+\[(.*)\]\s*$/)
  {
    # Sören Hein [sh@mig.ag]
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*(.*)\s+\((.*)\)\s*$/)
  {
    # Sören Hein (sh@mig.ag)
    $name = $1;
    $mail = $2;
    if ($mail !~ /\@/)
    {
      # Sören Hein (E-Mail)
      $name .= " ($mail)";
      $mail = "";
    }
  }
  elsif ($line =~ /^<(\S+)\s*<(.+)>\s*>$/)
  {
    # <sh@mig.ag<sh@mig.ag>> (WTF?)
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*(.*)\s+<(.*)>\s*$/)
  {
    # Sören Hein <sh@mig.ag>
    $name = $1;
    $mail = $2;

    $name = $1 if $name =~ /^"(.*)"$/;
    $name = $1 if $name =~ /^'(.*)'$/;
  }
  elsif ($line =~ /^\s*<(.*)>$/)
  {
    # <sh@mig.ag>
    $mail = $1;
  }
  elsif ($line =~ /^\s*\((.*)\)/)
  {
    # (sh@mig.ag)
    $mail = $1;
  }
  elsif ($line =~ /^\s*(.*)\s+(.*)\s*$/)
  {
    # Sören Hein sh@mig.ag
    my ($n, $m) = ($1, $2);
    if ($m =~ /\@/)
    {
      $name = $n;
      $mail = $m;
    }
    else
    {
      $name = $line;
    }
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

  if ($mail =~ /^(.*)<(.*)>\s*$/)
  {
    # sh@mig.ag<sh@mig.ag> (WTF?).
    my ($c1, $c2) = ($1, $2);
    if ($c1 eq $c2)
    {
      $mail = $c1;
    }
  }

  if ($mail =~ /^@/)
  {
    # Probably something else, @Jörg, @€2.25k/unit, ...
    return;
  }

  if ($mail =~ /^\//)
  {
    # Probably a wrong web address that is really a mail.
    $mail =~ s/^\/+//;
  }

print "GOT .$name., .$mail.\n" if $DEBUG_MAIL;

  $name = parse_MIG_name($name) if $name ne "";
  $mail = parse_MIG_mail($mail) if $mail ne "";


  if (lc($name) eq lc($mail))
  {
    $mail = "";
  }

print "FOUND .$name., .$mail.\n" if $DEBUG_MAIL;

  my $res;
  if ($mail eq "")
  {
    # Try to split on commas anyway and check whether at least
    # one entry is a MIG one.
    return if pure_comma_text($name, $list_ref);

    $res = $name;
  }
  elsif ($name eq "")
  {
    if ($mail !~ /^MIG: /)
    {
      $mail =~ /\@(.*)/;
      return unless defined $1;
      my $trail = $1;
      return unless $trail =~ /\./; # Must contain a dot
      return unless ($trail =~ /[A-Za-z]/); # Not just numbers.
    }

    $res = $mail;
  }
  else
  {
    $res = "$name ($mail)";
  }

  return if ($res =~ /undisclosed/i || $res =~ /verborgen/i);

print "RES .$res.\n" if $DEBUG_MAIL;
  push @$list_ref, $res;
}


sub clean_line
{
  my $line = pop;

  $line =~ s/^\s+//;
  $line =~ s/\s+$//;
  $line =~ s/\xc2\xa0/ /g;
  $line=~ s/%20/ /g;
  $line =~ s/%3c/</g;
  $line =~ s/%3e/>/g;

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

  if ($field =~ /(.*) [Ii]m Auftrag von (.*)/)
  {
    my $field1 = $1;
    my $field2 = $2;
    parse_mail($field1, $list_ref);
    parse_mail($field2, $list_ref);
  }
  else
  {
print "MAILFROM .$field.\n" if $DEBUG_MAIL;
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
    # Find quoted ranges.  We won't split within them.
    my @quoteRanges = ();
    find_quote_ranges($a[0], '"', \@quoteRanges);
    find_quote_ranges($a[0], "'", \@quoteRanges);

    my @commas;
    find_quotable_commas($a[0], \@quoteRanges, \@commas);

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
    @a = @b if $#b > 0;
  }

  my $found = 0;
  for my $m (@a)
  {
    next if $m eq "";
    $found = 1;
    $m =~ s/"//g;

    print "MAILTO .$m.\n" if $DEBUG_MAIL;
    parse_mail($m, $list_ref);
  }

  $$line_ref = "" if $found;
}


sub parse_mails
{
  my ($line_ref, $list_ref) = @_;

  $$line_ref = clean_line($$line_ref);
  $$line_ref =~ s/\|\|(\w)/ $1/g;
  $$line_ref =~ s/(\w)\|\|/$1 /g;

  # Only look for the actual mail with the @ symbol, not for the name.
  my @a = split /[ ,;:\=\<\>\(\)"\[\]]+/, $$line_ref;

  for my $m (@a)
  {
    next unless $m =~ /\@/;
    print "FREETEXT .$m.\n" if $DEBUG_MAIL;
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
  my ($web_skip_ref, $line_ref, $list_ref) = @_;

  my @a = split /[,;|\s\xa0]+/, $$line_ref;
  for my $e (@a)
  {
    if ($e =~ /www\./ || $e =~ /^http/)
    {
      $e =~ s/\.$//;
      $e =~ s/\/$//;

      my $hit = 0;
      for my $k (keys %$web_skip_ref)
      {
        $hit = 1 if $e =~ /$k/i;
      }
      next if $hit;

      $e =~ s/^.*http:\/([^\/].*)/http:\/$1/g; # Fix http:/
      $e =~ s/^.*(http\/\/)/$1:/g; # Fix http//

      $e =~ s/^.*(http:\/\/.*)/$1/; # Nothing in front of http
      $e =~ s/^.*(https:\/\/.*)/$1/; # Nothing in front of https

      $e =~ s/^.*(www.*)/$1/; # Everything in front of www

      $e =~ s/-$//; # Trailing -

      $e =~ s/^<([^>]*)>$/$1/; # <...>
      $e =~ s/^\(([^)*])\)*>$/$1/; # (...)

      $e =~ s/^http:\/\///;
      $e =~ s/^https:\/\///;

      $e =~ s/\)$//; # Trailing )
      $e =~ s/>$//; # Trailing >
      $e =~ s/\/$//; # Trailing /

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
