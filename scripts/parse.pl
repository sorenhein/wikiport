#!perl

use strict;
use warnings;

# Parse some fields out of Wiki pages.

if ($#ARGV != 0)
{
  print "Usage: parse.pl files.txt > out.txt\n";
  exit;
}


my %MIG_names;
set_MIG_names(\%MIG_names);

my %MIG_mails;
set_MIG_mails(\%MIG_mails);

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

    parse_mails_from(\$line, \@mails_from);
    parse_mails_to(\$line, \@mails_to);
    parse_mails(\$line, \@mails);
    # parse_dates(\$line, \@dates);
    parse_attachments(\$line, \@attachments);
    parse_websites(\$line, \@websites);
    parse_links(\$line, \@links);
  }

  close $fi;

  print "$fline\n";
  print "=" x length($fline), "\n\n";

  print_count_list(\@mails_from, "Mails from");
  print_count_list(\@mails_to, "Mails to");
  print_count_list(\@mails, "Mails in text");

  print_list(\@attachments, "Attachments");
  print_count_list(\@websites, "Websites");
  print_list(\@links, "Links");

}

close $fh;



sub set_MIG_names
{
  my $nref = pop;

  $nref->{"Axel Thierauf"}      = "MIG: AT";
  $nref->{"Thierauf, Axel"}     = "MIG: AT";
  $nref->{"Dr. Klaus Feix"}     = "MIG: KF";
  $nref->{"Klaus Feix"}         = "MIG: KF";
  $nref->{"JürgenKosch"}        = "MIG: JK";
  $nref->{"Kosch, Juergen"}     = "MIG: JK";
  $nref->{"Betz, Maria"}        = "MIG: MBe";
  $nref->{"Michael Motschmann"} = "MIG: MM";
  $nref->{"Stadler, Monika"}    = "MIG: MSt";
  $nref->{"Sören Hein"}         = "MIG: SH";
  $nref->{"Hein, Sören"}        = "MIG: SH";
  $nref->{"Hein, SÃ¶ren"}       = "MIG: SH";
}


sub set_MIG_mails
{
  my $nref = pop;

  $nref->{'at@mig.ag'}                = "MIG: AT";
  $nref->{'jk@mig.ag'}                = "MIG: JK";
  $nref->{'jk@hs984.hostedoffice.ag'} = "MIG: JK";
  $nref->{'kf@mig.ag'}                = "MIG: KF";
  $nref->{'kf@hs984.hostedoffice.ag'} = "MIG: KF";
  $nref->{'mbe@mig.ag'}               = "MIG: MBe";
  $nref->{'mm@mig.ag'}                = "MIG: MM";
  $nref->{'mst@mig.ag'}               = "MIG: MSt";
  $nref->{'sh@mig.ag'}                = "MIG: SH";
  $nref->{'sh@hs984.hostedoffice.ag'} = "MIG: SH";
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
  if (defined $MIG_mails{$mail})
  {
    return $MIG_mails{$mail};
  }
  else
  {
    return $mail;
  }
}


sub parse_mail
{
  my ($line, $list_ref) = @_;

  my $name = "";
  my $mail = "";
  if ($line =~ /^\s*(.*)\s+\[mailto:(.*)\]\s*$/)
  {
    # Sören Hein [mailto:sh@mig.ag]
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*(.*)\s+\((.*)\)\s+<(.*)>\s*$/)
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
  elsif ($line =~ /^\s*(.*)\s+<mailto:(.*)>\s*$/)
  {
    # Sören Hein <mailto:sh@mig.ag>
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*(.*)\s+<(.*)>\s*$/)
  {
    # Sören Hein <sh@mig.ag>
    $name = $1;
    $mail = $2;
  }
  elsif ($line =~ /^\s*mailto:(.*)\s*$/)
  {
    # mailto:sh@mig.ag
    $mail = $1;
  }
  else
  {
    $name = $line;
    $name =~ s/^\s+//;
  }

  if ($name =~ /^"(.*)"$/ || $name =~ /^'(.*)'$/)
  {
    $name = $1;
  }

  return if $name eq "" && $mail eq "";

  if ($mail eq "" && $name =~ /@/)
  {
    $mail = $name;
    $name = "";
  }

  $name = parse_MIG_name($name) if $name ne "";
  $mail = parse_MIG_mail($mail) if $mail ne "";

  if ($name eq $mail)
  {
    $mail = "";
  }

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


sub parse_mails_to
{
  my ($line_ref, $list_ref) = @_;

  $$line_ref = clean_line($$line_ref);

  my $field = "";
  $field = $1 if $$line_ref =~ /^An:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^To:\s+(.*)$/;
  $field = $1 if $$line_ref =~ /^A:\s+(.*)$/;

  return if $field eq "";

  # If there are semi-colons, we won't split on commas.
  my @a = split /;/, $field;

  if ($#a == 0)
  {
    # Only split on comma if there seem to be multiple mails.
    my @t = split /\@/, $a[0];
    @a = split /,/, $a[0] if $#t > 1;
  }

  my $found = 0;
  for my $m (@a)
  {
    next if $m eq "";
    $found = 1;
    parse_mail($m, $list_ref);
  }

  $$line_ref = "" if $found;
}


sub parse_mails
{
  my ($line_ref, $list_ref) = @_;

  $$line_ref = clean_line($$line_ref);

  # Only look for the actual mail with the @ symbol, not for the name.
  my @a = split /[ ,;]+/, $$line_ref;

  for my $m (@a)
  {
    next unless $m =~ /\@/;
    parse_mail($m, $list_ref);
  }
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
    next if $k =~ /^MIG:/;
    printf "%2d %s\n", $h{$k}, $k;
  }
  for my $k (sort keys %h)

  {
    next unless $k =~ /^MIG:/;
    printf "%2d %s\n", $h{$k}, $k;
  }

  print "\n";
}
