#!perl

use strict;
use warnings;


sub set_chars
{
  my $subs_ref = pop;

  $subs_ref->{"%20"} = ' ';
  $subs_ref->{"%21"} = '!';
  $subs_ref->{"%22"} = '"';
  $subs_ref->{"%23"} = '#';
  $subs_ref->{"%25"} = '%';
  $subs_ref->{"%26"} = '&';
  $subs_ref->{"%27"} = "'";
  $subs_ref->{"%28"} = "(";
  $subs_ref->{"%29"} = ")";
  $subs_ref->{"%2b"} = '+';
  $subs_ref->{"%2C"} = ',';
  $subs_ref->{"%2D"} = '-';
  $subs_ref->{"%2E"} = '.';
  $subs_ref->{"%2F"} = '/';
  $subs_ref->{"%3A"} = ':';
  $subs_ref->{"%3F"} = '?';
  $subs_ref->{"%40"} = '@';
  $subs_ref->{"%5B"} = '[';
  $subs_ref->{"%5D"} = ']';
  $subs_ref->{"%7B"} = '{';
  $subs_ref->{"%7C"} = '|';
  $subs_ref->{"%C2%AE"} = '®';
  $subs_ref->{"%C2%B4"} = '`';
  $subs_ref->{"%C3%80"} = 'À';
  $subs_ref->{"%C3%84"} = 'Ä';
  $subs_ref->{"%C3%9C"} = 'Ü';
  $subs_ref->{"%C3%9F"} = 'ß';
  $subs_ref->{"%C3%96"} = 'Ö';
  $subs_ref->{"%C3%A4"} = 'ä';
  $subs_ref->{"%C3%A9"} = 'é';
  $subs_ref->{"%C3%BC"} = 'ü';
  $subs_ref->{"%C3%B6"} = 'ö';
  $subs_ref->{"%C5%A1"} = 'š';
}


sub make_sub
{
  my ($subs_ref, $line_ref) = @_;

  if ($$line_ref =~ /\%/)
  {
    for my $k (keys %$subs_ref)
    {
      $$line_ref =~ s/$k/$subs_ref->{$k}/g;
    }
  }
}

1;
