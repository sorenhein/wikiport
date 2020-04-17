use strict;
use warnings;

# Parse the output format of parse.pl and make a mail histogram.

if ($#ARGV != 0)
{
  print "Usage: parse.pl out.txt > histo.txt\n";
  exit;
}


my (%one_external, %one_internal, %more, 
  %none_MIG_good, %none_MIG_bad, %none_other);

my $file = $ARGV[0];

open my $fh, "<", $file or die "Cannot open $file: $!";

while (my $line = <$fh>)
{
  chomp $line;
  $line =~ s///g;

  next unless 
    ($line =~ /^Mails from$/ || 
     $line =~ /^Mails to$/ || 
     $line =~ /^Mails in text$/);

  <$fh>; # Skip dashes
  
  do
  {
    $line = <$fh>;
    chomp $line;
    $line =~ s///g;
    last if $line =~ /^\s*$/;

    $line =~ /^\s*(\d+)\s+(.*)/;
    my ($count, $value) = ($1, $2);

    my $num_ats = () = $line =~ /\@/gi;

    if ($num_ats > 1)
    {
      $more{$value} += $count;
    }
    elsif ($num_ats == 1)
    {
      if ($line =~ /mig.ag/)
      {
        $one_internal{$value} += $count;
      }
      else
      {
        $one_external{$value} += $count;
      }
    }
    else
    {
      if ($line =~ /MIG: /)
      {
        if ($line =~ /MIG: \w+$/)
        {
          $none_MIG_good{$value} += $count;
        }
        else
        {
          $none_MIG_bad{$value} += $count;
        }
      }
      else
      {
        $none_other{$value} += $count;
      }
    }
  }
}

close $fh;

print_hash("One external", \%one_external);
print_hash("One internal", \%one_internal);
print_hash("More @", \%more);
print_hash("None internal good", \%none_MIG_good);
print_hash("None internal bad", \%none_MIG_bad);
print_hash("None external", \%none_other);


sub print_hash
{
  my($name, $hash_ref) = @_;

  print "$name\n";
  print "-" x length($name), "\n";

  for my $k (sort {$hash_ref->{$b} <=> $hash_ref->{$a}} keys %$hash_ref)
  {
    printf "%4d %s\n", $hash_ref->{$k}, $k;
  }
  print "\n";
}
