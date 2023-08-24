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
  my $exp = scalar(@_) -1;
  my $resu = 0;
  foreach(@_) {
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

while(1) {
  print("hex num:");
  my $hex = <STDIN>;
  print("bits num:");
  my $bits = <STDIN>;





  my @num_hex = split//,$hex;
  my @num_4bits = map {$hex_to_bin_tab{$_}} @num_hex;
  say "Initial Bin:\t\t",@num_4bits;
  my @num_bits;
  foreach (@num_4bits) {
    @num_bits = (@num_bits,split//,$_);
  }
  my $len = scalar @num_bits;
  my $dec = $bits - $len;
  if($dec > $0) {
    while($dec > 0) {
      unshift @num_bits,0;
      $dec -= 1;
    }
  } else {
    $dec *= -1;
    while($dec > 0) {
      shift @num_bits,0;
      $dec -= 1;
    }  
  }

  say "Padded  Bin:\t\t",@num_bits;

  my $sign = shift @num_bits; #get sig bit
  my $val;
  my $max = 2**($bits-1);
  if($sign) {
      $val = $max - &bin_to_dec(@num_bits);
  } else {
      $val = &bin_to_dec(@num_bits);
  }
  say "act value:",$max;
  say "act value:",&bin_to_dec(@num_bits);
  say "act value:",$val;

  $val = $val * (1+($sign * (-2)));

  say "act value:",$val;


}
