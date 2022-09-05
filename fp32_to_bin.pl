#!/usr/bin/perl
use 5.010;
use strict;

my %hex_to_bin_tab = (
  "0" => "0000",
  "1" => "0001",
  "2" => "0010",
  "3" => "0011",
  "4" => "0100",
  "5" => "0101",
  "6" => "0110",
  "7" => "0111",
  "8" => "1000",
  "9" => "1001",
  "a" => "1010",
  "b" => "1011",
  "c" => "1100",
  "d" => "1101",
  "e" => "1110",
  "f" => "1111",
);


sub bin_to_dec {
  my $exp = length($_[0]) -1;
  my $resu = 0;
  foreach(split //,$_[0]) {
    $resu = $resu + $_ * 2**$exp;
    $exp--;
  }
  return $resu;
};


sub get_bits {
  my $hbit = shift @_;
  my $lbit = shift @_;
  my $bits = shift @_;
  my $resu;
  for(my $i=$hbit;$i>=$lbit;$i--) {
    $resu = $resu.@$bits[$i];
  };
  return $resu;
}

while(<>) {
  print "    ",$_;
  my @num_hex = split//,$_;
  my @num_4bits = map {$hex_to_bin_tab{$_}} @num_hex;
  print "    ",@num_4bits,"\n";
  my @num_bits;
  foreach (@num_4bits) {
    @num_bits = (@num_bits,split//,$_);
  }
  @num_bits = reverse(@num_bits);
  my $sign = $num_bits[31];
  my @exp  = &get_bits(30,23,\@num_bits);
  my @tail = &get_bits(22,0,\@num_bits);
  
  print "    ",@exp,"\n";
  print "    ",@tail,"\n";

  my $exp_val = &bin_to_dec(@exp);
  my $tail_val = &bin_to_dec(@tail);
  print "    ","dbg-exp_val:$exp_val\n";
  print "    ","dbg-tail_val:$tail_val\n";
  if($exp_val > 0) {
    $tail_val = $tail_val * (2**(-23)) + 1;
    $exp_val = $exp_val - 127;
  } else {
    $tail_val = $tail_val * (2**(-23));
    $exp_val = -126;
  }

  print "    ","SIGN:$sign EXP:$exp_val TAIL:$tail_val \n";
  my $float_resu = ((-1) ** $sign) * (2 ** $exp_val) * $tail_val;
  print "RESU:$float_resu(dec)";
  print sprintf("  %x(hex)\n",$float_resu);

}
