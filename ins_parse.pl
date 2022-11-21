#!/usr/bin/perl
use 5.010;
use strict;
my @err_msg;

my %switch_val = (
  "0" => "off",
  "1" => "on",
);

sub get_hash_key {
  my $hval = shift @_;
  my $hash = shift @_;
  foreach (keys %$hash) {
    if($hash->{$_} eq $hval) {
      return $_;
    }
  }
}

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

my $ins_ori_str;# = $ARGV[0];
if($ARGV[0] =~ m/.*\.log/) {
  die "file not found!" if not -e $ARGV[0];
  open(LOG,$ARGV[0]);
  while(<LOG>) {
    if($_ =~ m/ins\s+integral\s+1024\s+(.*)$/) {
      say "INSTRUCTION:".$1;
      $ins_ori_str = $1;
      last;
    }
  }
  close(LOG);
} else {
  $ins_ori_str = $ARGV[0];
}

$ins_ori_str =~ s/^\d?+\'?h//g;

my $ins_ori_len;
$ins_ori_len = length($ins_ori_str);
for(my $i=$ins_ori_len;$i<256;$i++) {
  $ins_ori_str = "0".$ins_ori_str;
};
my @ins_hex = split//,$ins_ori_str;


my @ins_4bits = map {$hex_to_bin_tab{$_}} @ins_hex;

my @ins_bits;
foreach (@ins_4bits) {
  @ins_bits = (@ins_bits,split//,$_);
}

@ins_bits = reverse(@ins_bits);

sub bin_to_dec {
  my $exp = length($_[0]) -1;
  my $resu = 0;
  foreach(split //,$_[0]) {
    $resu = $resu + $_ * 2**$exp;
    $exp--;
  }
  return $resu;
};

sub bin_to_dec_signed {
  my @bin_list = split //,$_[0];
  my $sign = shift @bin_list;
  my $exp = @bin_list;
  my $neg_max = -1 * (2**$exp);
  $exp--;
  my $resu = 0;
  foreach(@bin_list) {
    $resu = $resu + $_ * 2**$exp;
    $exp--;
  }
  if($sign) { #neg
    $resu = $neg_max + $resu;
  } else {
    $resu = $resu;
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

sub get_str {
  my $key = shift @_;
  my $hash = shift @_;
  my @all_keys = keys %$hash;
  my $get_key = grep /^$key$/,keys %$hash;
  if($get_key) {
    return $hash->{$key};
  }else{
    return sprintf("Reserved_Value :0x%x (%d)",$key,$key);
  }
}



my %npu_work_block_mode_tab = (
  "1" => "PE_VPU",
  "2" => "VPU",
  "3" => "Only DMA",
);
my %pe_conv_mode_tab = (
  "0" => "PE_IDLE",
  "1" => "Conv_2D",
  "2" => "DepthWiseConv",
  "3" => "AtrousConv",
  "4" => "TransposeConv",
  "5" => "FullConnect",
  "6" => "DW_PW",
  "7" => "GEMM",
);
my %pe_pmode_tab = (
  "0" => "1_OCH",
  "1" => "2_OCH",
  "2" => "4_OCH",
);
my %npu_pmode_tab = (
  "0" => "ALL_OCH",
  "2" => "2RP",
  "3" => "4RP",
);
my %broadcast_info_tab = (
  "0" => "1_to_1",
  "1" => "1_to_2",
  "2" => "1_to_4",
  "3" => "1_to_8",
);




my $npu_work_block_mode = &bin_to_dec(&get_bits(1011,1008,\@ins_bits));
my $pg_num              = &bin_to_dec(&get_bits(999,992,\@ins_bits));
my $pe_conv_mode        = &bin_to_dec(&get_bits(991,988,\@ins_bits));
my $pe_pmode            = &bin_to_dec(&get_bits(987,984,\@ins_bits));
my $npu_pmode           = &bin_to_dec(&get_bits(983,980,\@ins_bits));
my $kernel_size_h       = &bin_to_dec(&get_bits(979,972,\@ins_bits));
my $kernel_size_w       = &bin_to_dec(&get_bits(971,964,\@ins_bits));
my $padding_left        = &bin_to_dec(&get_bits(963,956,\@ins_bits));
my $padding_right       = &bin_to_dec(&get_bits(955,948,\@ins_bits));
my $padding_up          = &bin_to_dec(&get_bits(947,940,\@ins_bits));
my $padding_down        = &bin_to_dec(&get_bits(939,932,\@ins_bits));
my $stride_h            = &bin_to_dec(&get_bits(931,928,\@ins_bits));
my $stride_w            = &bin_to_dec(&get_bits(927,924,\@ins_bits));
my $bias                = &bin_to_dec(&get_bits(923,920,\@ins_bits));
my $kernel_force_split  = &bin_to_dec(&get_bits(872,872,\@ins_bits));
my $broadcast_info      = &bin_to_dec(&get_bits(871,864,\@ins_bits));
my $as_conv_rate        = &bin_to_dec(&get_bits(931,924,\@ins_bits));
my $dw_pw_conv_dw_bias  = &bin_to_dec(&get_bits(923,920,\@ins_bits));
my $dw_pw_conv_pw_bias  = &bin_to_dec(&get_bits(919,916,\@ins_bits));

my $npu_work_block_mode_str = &get_str($npu_work_block_mode , \%npu_work_block_mode_tab);
my $pe_conv_mode_str        = &get_str($pe_conv_mode        , \%pe_conv_mode_tab);
my $pe_pmode_str            = &get_str($pe_pmode            , \%pe_pmode_tab);
my $npu_pmode_str           = &get_str($npu_pmode           , \%npu_pmode_tab);
my $broadcast_info_str      = &get_str($broadcast_info      , \%broadcast_info_tab);

my %vpu_mode_tab = (
  "0"  => "VPU_IDLE",
  "1"  => "Eltwise",
  "2"  => "ReLU",
  "3"  => "Sigmoid",
  "4"  => "Pooling",
  "5"  => "Global_Pooling",
  "6"  => "Upsample",
  "7"  => "SGM",
  "8"  => "Eltwise_Relu",
  "9"  => "Only_Relu",
  "10" => "Only_Sigmoid",
  "11" => "Data_Format",
  "12" => "Tranapose",
);
my %eltwise_type_tab = (
  "0"  => "Add",
  "2"  => "Max",
  "3"  => "Product",
);
my %relu_type_tab = (
  "0"  => "ReLU",
  "1"  => "ReLU6",
  "2"  => "LReLU",
  "3"  => "PReLU",
);
my %pooling_type_tab = (
  "0"  => "MAX",
  "1"  => "AVG",
);
my %sgm_type_tab = (
  "0"  => "Gathering",
  "1"  => "Disparity",
  "2"  => "Correlation",
  "3"  => "Softmax_Division",
  "4"  => "Right_Shift",
  "5"  => "Softmax_E^X",
  "6"  => "Softmax_W",
);
my %o_relu_type_tab = (
  "0"  => "vReLU",
  "1"  => "vReLU6",
  "2"  => "vLReLU",
  "3"  => "vPReLU",
);
my %transpose_type_tab = (
  "0"  => "CxHW -> HxCW",
  "1"  => "CxHW -> CxWH",
);

my $vpu_mode            = &bin_to_dec(&get_bits(863,860,\@ins_bits));
my $eltwise_type        = &bin_to_dec(&get_bits(859,856,\@ins_bits));
my $relu_type           = &bin_to_dec(&get_bits(859,856,\@ins_bits));
my $pooling_type        = &bin_to_dec(&get_bits(859,856,\@ins_bits));
my $pooling_kernel_size = &bin_to_dec(&get_bits(855,852,\@ins_bits));
my $pooling_stride      = &bin_to_dec(&get_bits(851,848,\@ins_bits));
my $upsample_scale      = &bin_to_dec(&get_bits(855,848,\@ins_bits));
my $sgm_type            = &bin_to_dec(&get_bits(859,856,\@ins_bits));
my $o_relu_type         = &bin_to_dec(&get_bits(859,856,\@ins_bits));
my $transpose_type      = &bin_to_dec(&get_bits(859,856,\@ins_bits));

my $vpu_mode_str       = &get_str($vpu_mode       , \%vpu_mode_tab);
my $eltwise_type_str   = &get_str($eltwise_type   , \%eltwise_type_tab);
my $relu_type_str      = &get_str($relu_type      , \%relu_type_tab);
my $pooling_type_str   = &get_str($pooling_type   , \%pooling_type_tab);
my $sgm_type_str       = &get_str($sgm_type       , \%sgm_type_tab);
my $o_relu_type_str    = &get_str($o_relu_type    , \%o_relu_type_tab);
my $transpose_type_str = &get_str($transpose_type , \%transpose_type_tab);

my $pooling_padding    = &get_bits(847,844,\@ins_bits);
my $relu_a_value       = &bin_to_dec(&get_bits(855,824,\@ins_bits));
my $global_pooling_val = &bin_to_dec(&get_bits(855,824,\@ins_bits));
my $sgm_offset0        = &get_bits(855,844,\@ins_bits);
my $sgm_offset1        = &get_bits(843,832,\@ins_bits);


my $dequant_scale1 =  &get_bits(799,768,\@ins_bits);
my $quant_scale1   =  &get_bits(767,736,\@ins_bits);
my $dequant_scale0 =  &get_bits(735,704,\@ins_bits);
my $quant_scale0   =  &get_bits(703,672,\@ins_bits);

my %input_format_type_tab = (
  "0"  => "NCHW",
  "1"  => "NC2HW",
  "2"  => "NC4HW",
  "3"  => "NC8HW",
  "4"  => "NC16HW",
  "5"  => "NC3HW",
);
my %input_data_type_tab = (
  "1"  => "INT16",
  "2"  => "INT8",
  "3"  => "UINT8",
);

my $input_size_n = &bin_to_dec(&get_bits(671,660,\@ins_bits));
my $input_size_c = &bin_to_dec(&get_bits(659,648,\@ins_bits));
my $input_size_h = &bin_to_dec(&get_bits(647,636,\@ins_bits));
my $input_size_w = &bin_to_dec(&get_bits(635,624,\@ins_bits));
my $input_format = &bin_to_dec(&get_bits(623,620,\@ins_bits));
my $input_data   = &bin_to_dec(&get_bits(619,616,\@ins_bits));

my $input_format_str = &get_str($input_format , \%input_format_type_tab);
my $input_data_str   = &get_str($input_data   , \%input_data_type_tab);

my %output_format_type_tab = (
  "0"  => "NCHW",
  "2"  => "NC4HW",
  "3"  => "NC8HW",
  "4"  => "NC16HW",
);
my %output_data_type_tab = (
  "1"  => "INT16",
  "2"  => "INT8",
);

my $output_size_n = &bin_to_dec(&get_bits(607,596,\@ins_bits));
my $output_size_c = &bin_to_dec(&get_bits(595,584,\@ins_bits));
my $output_size_h = &bin_to_dec(&get_bits(583,572,\@ins_bits));
my $output_size_w = &bin_to_dec(&get_bits(571,560,\@ins_bits));
my $output_format = &bin_to_dec(&get_bits(559,556,\@ins_bits));
my $output_data   = &bin_to_dec(&get_bits(555,552,\@ins_bits));

my $output_format_str = &get_str($output_format , \%output_format_type_tab);
my $output_data_str   = &get_str($output_data   , \%output_data_type_tab);

my %base_addr_sel_tab = (
  "0"  => "DDR",
  "1"  => "OCM",
);

my $f_in_addr_sel      = &bin_to_dec(&get_bits(488 , 488 , \@ins_bits));
my $k_in_addr_sel      = &bin_to_dec(&get_bits(487 , 487 , \@ins_bits));
my $f_out_addr_sel     = &bin_to_dec(&get_bits(486 , 486 , \@ins_bits));
my $bias_addr_sel      = &bin_to_dec(&get_bits(485 , 485 , \@ins_bits));
my $k_in_2_addr_sel    = &bin_to_dec(&get_bits(484 , 484 , \@ins_bits));
my $other_addr_sel     = &bin_to_dec(&get_bits(483 , 483 , \@ins_bits));
my $bias_2_addr_sel    = &bin_to_dec(&get_bits(482 , 482 , \@ins_bits));
my $dequant_addr_sel   = &bin_to_dec(&get_bits(481 , 481 , \@ins_bits));
my $dequant_2_addr_sel = &bin_to_dec(&get_bits(480 , 480 , \@ins_bits));

my $f_in_addr_str     = &get_str( $f_in_addr_sel       , \%base_addr_sel_tab);
my $k_in_addr_str     = &get_str( $k_in_addr_sel       , \%base_addr_sel_tab);
my $f_out_addr_str    = &get_str( $f_out_addr_sel      , \%base_addr_sel_tab);
my $bias_addr_str     = &get_str( $bias_addr_sel       , \%base_addr_sel_tab);
my $k_in_2_addr_str   = &get_str( $k_in_2_addr_sel     , \%base_addr_sel_tab);
my $other_addr_str    = &get_str( $other_addr_sel      , \%base_addr_sel_tab);
my $bias_2_addr_str   = &get_str( $bias_2_addr_sel     , \%base_addr_sel_tab);
my $dequant_addr_str  = &get_str( $dequant_addr_sel    , \%base_addr_sel_tab);
my $dequant_2_addr_str= &get_str( $dequant_2_addr_sel  , \%base_addr_sel_tab);

my $f_in_addr      = &bin_to_dec(&get_bits(479 , 448 , \@ins_bits));
my $k_in_addr      = &bin_to_dec(&get_bits(447 , 416 , \@ins_bits));
my $f_out_addr     = &bin_to_dec(&get_bits(415 , 384 , \@ins_bits));
my $bias_addr      = &bin_to_dec(&get_bits(383 , 352 , \@ins_bits));
my $k_in_2_addr    = &bin_to_dec(&get_bits(351 , 320 , \@ins_bits));
my $other_addr     = &bin_to_dec(&get_bits(319 , 288 , \@ins_bits));
my $bias_2_addr    = &bin_to_dec(&get_bits(287 , 256 , \@ins_bits));
my $dequant_addr   = &bin_to_dec(&get_bits(255 , 224 , \@ins_bits));
my $dequant_2_addr = &bin_to_dec(&get_bits(223 , 192 , \@ins_bits));


my $dma_sn          = &bin_to_dec(&get_bits(187 , 172 , \@ins_bits));
my $ocm_in_ind      = &bin_to_dec(&get_bits(171 , 171 , \@ins_bits));
my $wb_ins_exe_ind  = &bin_to_dec(&get_bits(170 , 170 , \@ins_bits));
my $wb_ins_exe_wait = &bin_to_dec(&get_bits(169 , 169 , \@ins_bits));
my $unlock_ind      = &bin_to_dec(&get_bits(168 , 168 , \@ins_bits));
my $unlock_bn_begin = &bin_to_dec(&get_bits(167 , 156 , \@ins_bits));
my $unlock_bn_end   = &bin_to_dec(&get_bits(155 , 144 , \@ins_bits));


my $decompress_en             = &bin_to_dec(&get_bits(129 , 129 , \@ins_bits));
my $pw_decompress_en          = &bin_to_dec(&get_bits(61  , 61  , \@ins_bits));
my $queue_flex_cfg            = &bin_to_dec(&get_bits(143 , 130 , \@ins_bits));
my $firm_size_compressed      = &bin_to_dec(&get_bits(128 , 112 , \@ins_bits));
my $firm_ori_data_tail_mod    = &bin_to_dec(&get_bits(111 , 108 , \@ins_bits));
my $flex_size_compressed      = &bin_to_dec(&get_bits(107 , 80  , \@ins_bits));
my $flex_ori_data_tail_mod    = &bin_to_dec(&get_bits(79  , 76  , \@ins_bits));
my $pw_queue_flex_cfg         = &bin_to_dec(&get_bits(75 ,  62 , \@ins_bits));
my $pw_firm_size_compressed   = &bin_to_dec(&get_bits(60  , 44  , \@ins_bits));
my $pw_firm_ori_data_tail_mod = &bin_to_dec(&get_bits(43  , 40  , \@ins_bits));
my $pw_flex_size_compressed   = &bin_to_dec(&get_bits(39  , 12  , \@ins_bits));
my $pw_flex_ori_data_tail_mod = &bin_to_dec(&get_bits(11  , 8   , \@ins_bits));

my $conv_asym_quant_en   = &get_bits(704,704,\@ins_bits);
my $vpu_asym_quant_en    = &get_bits(8  , 8  , \@ins_bits);

my $conv_asym_quant_bias_1  ;
my $conv_asym_quant_bias_0  ;
my $vpu_asym_dequant_bias_1 ;
my $vpu_asym_dequant_bias_0 ;
my $vpu_asym_quant_bias     ;
if($output_data eq &get_hash_key("INT16",\%output_data_type_tab)) {
  $conv_asym_quant_bias_1  = &bin_to_dec_signed(&get_bits(799,784,\@ins_bits));
  $conv_asym_quant_bias_0  = &bin_to_dec_signed(&get_bits(783,768,\@ins_bits));
  $vpu_asym_quant_bias     = &bin_to_dec_signed(&get_bits(31 , 16 , \@ins_bits));
} else {
  $conv_asym_quant_bias_1  = &bin_to_dec_signed(&get_bits(791,784,\@ins_bits));
  $conv_asym_quant_bias_0  = &bin_to_dec_signed(&get_bits(775,768,\@ins_bits));
  $vpu_asym_quant_bias     = &bin_to_dec_signed(&get_bits(23 , 16 , \@ins_bits));
}
if($input_data eq &get_hash_key("INT16",\%input_data_type_tab)) {
  $vpu_asym_dequant_bias_1 = &bin_to_dec_signed(&get_bits(63 , 48 , \@ins_bits));
  $vpu_asym_dequant_bias_0 = &bin_to_dec_signed(&get_bits(47 , 32 , \@ins_bits));
} else {
  $vpu_asym_dequant_bias_1 = &bin_to_dec_signed(&get_bits(55 , 48 , \@ins_bits));
  $vpu_asym_dequant_bias_0 = &bin_to_dec_signed(&get_bits(39 , 32 , \@ins_bits));
}


my %cpu_ins_indicator_type_tab = (
  "0"  => "NPU",
  "1"  => "CPU",
);
my $cpu_ins_indicator       = &bin_to_dec(&get_bits(0  , 0  , \@ins_bits));
my $cpu_ins_indicator_str   = &get_str( $cpu_ins_indicator , \%cpu_ins_indicator_type_tab);


my $input_feature_padding_value_hbits = &get_bits(615 , 608 , \@ins_bits);
my $input_feature_padding_value_lbits = &get_bits(551 , 544 , \@ins_bits);
my $input_feature_padding_value_bits  = $input_feature_padding_value_hbits.$input_feature_padding_value_lbits;
my $input_feature_padding_value_int16 = &bin_to_dec_signed($input_feature_padding_value_bits);
my $input_feature_padding_value_int8  = &bin_to_dec_signed($input_feature_padding_value_lbits);




my $name;
my $val;
my $template_name = "NPU_FIELD";
format NPU_FIELD = 
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>>>>>>>
$name,$val
.

select(STDOUT);
$~ = $template_name;

sub msgp {
  my $tab_lv = shift @_;
  $name = shift @_;
  $val = shift @_;
  print " "x$tab_lv;
  write;
}



sub float_bin_print {
  return sprintf("'h%08x",&bin_to_dec(shift @_));
  #my $bits = shift @_;
  #say $bits;
  #my $dec_val = &bin_to_dec($bits);
  #say $dec_val;
  #my $hex = sprintf("'h%08x",$dec_val);
  #say $hex;
  #say "---";
  #my $temp = pack "B32",00111111100000000000000000000000;
  #say $temp;
  #my $float = unpack "N",$temp;
  #say $float;
  #say "---";
  #return $float;
}

print "-"x18;print "NPU_INSTRUCTION";say "-"x18;
if(not $cpu_ins_indicator) { 
  say "NPU Working Block Mode: $npu_work_block_mode_str";
  if($npu_work_block_mode eq 1) {#Conv
    &conv_print(2);
    &vpu_print(2);
    &quantization_print(2);
    &input_feature_print(2);
    &output_feature_print(2);
    &addr_info_print(2);
    &dma_ctrl_print(2);
    &kernel_compress_print(2);
  } elsif($npu_work_block_mode eq 2) {#Vpu
    &vpu_print(2);
    &quantization_print(2);
    &vpu_asym_quant_print(2);
    &input_feature_print(2);
    &output_feature_print(2);
    &addr_info_print(2);
    &dma_ctrl_print(2);
  } elsif($npu_work_block_mode eq 3) {#Only DMA
    &dma_ctrl_print(2);
  }
} else {
  say "This is a CPU Instruction!"
}
say "-"x51;




#PRINT SUB
sub conv_print{
  say "PE config info:";
  my $base_tab_lv = shift @_;
  &msgp($base_tab_lv,"pg_num:",$pg_num);
  &msgp($base_tab_lv,"npu_pmode:",$npu_pmode_str);
  &msgp($base_tab_lv,"pe_pmode:",$pe_pmode_str);
  &msgp($base_tab_lv,"pe_conv_mode:",$pe_conv_mode_str);
  &msgp($base_tab_lv,"broadcast_info",$broadcast_info_str);
  if($pe_conv_mode eq &get_hash_key("Conv_2D",\%pe_conv_mode_tab)) {
    &msgp($base_tab_lv,"kernel_size_h:",$kernel_size_h);
    &msgp($base_tab_lv,"kernel_size_w:",$kernel_size_w);
    &msgp($base_tab_lv,"padding_left",$padding_left);
    &msgp($base_tab_lv,"padding_right",$padding_right);
    &msgp($base_tab_lv,"padding_up",$padding_up);
    &msgp($base_tab_lv,"padding_down",$padding_down);
    &msgp($base_tab_lv,"stride_h",$stride_h);
    &msgp($base_tab_lv,"stride_w",$stride_w);
    &msgp($base_tab_lv,"bias",sprintf("'b%04b",$bias));
    &msgp($base_tab_lv,"kernel_force_split",$switch_val{$kernel_force_split});
  } elsif($pe_conv_mode eq &get_hash_key("DepthWiseConv",\%pe_conv_mode_tab)) {
    &msgp($base_tab_lv,"kernel_size_h:",$kernel_size_h);
    &msgp($base_tab_lv,"kernel_size_w:",$kernel_size_w);
    &msgp($base_tab_lv,"padding_left",$padding_left);
    &msgp($base_tab_lv,"padding_right",$padding_right);
    &msgp($base_tab_lv,"padding_up",$padding_up);
    &msgp($base_tab_lv,"padding_down",$padding_down);
    &msgp($base_tab_lv,"stride_h",$stride_h);
    &msgp($base_tab_lv,"stride_w",$stride_w);
    &msgp($base_tab_lv,"bias",sprintf("'b%04b",$bias));
    &msgp($base_tab_lv,"kernel_force_split",$switch_val{$kernel_force_split});
  } elsif($pe_conv_mode eq &get_hash_key("AtrousConv",\%pe_conv_mode_tab)) {
    &msgp($base_tab_lv,"kernel_size_h:",$kernel_size_h);
    &msgp($base_tab_lv,"kernel_size_w:",$kernel_size_w);
    &msgp($base_tab_lv,"padding_left",$padding_left);
    &msgp($base_tab_lv,"padding_right",$padding_right);
    &msgp($base_tab_lv,"padding_up",$padding_up);
    &msgp($base_tab_lv,"padding_down",$padding_down);
    &msgp($base_tab_lv,"as_conv_rate",$as_conv_rate);
    &msgp($base_tab_lv,"bias",sprintf("'b%04b",$bias));
  } elsif($pe_conv_mode eq &get_hash_key("TransposeConv",\%pe_conv_mode_tab)) {
    &msgp($base_tab_lv,"kernel_size_h:",$kernel_size_h);
    &msgp($base_tab_lv,"kernel_size_w:",$kernel_size_w);
    &msgp($base_tab_lv,"padding_left",$padding_left);
    &msgp($base_tab_lv,"padding_right",$padding_right);
    &msgp($base_tab_lv,"padding_up",$padding_up);
    &msgp($base_tab_lv,"padding_down",$padding_down);
    &msgp($base_tab_lv,"stride_h",$stride_h);
    &msgp($base_tab_lv,"stride_w",$stride_w);
    &msgp($base_tab_lv,"bias",sprintf("'b%04b",$bias));
  } elsif($pe_conv_mode eq &get_hash_key("FullConnect",\%pe_conv_mode_tab)) {
    &msgp($base_tab_lv,"kernel_size_h:",$kernel_size_h);
    &msgp($base_tab_lv,"kernel_size_w:",$kernel_size_w);
    &msgp($base_tab_lv,"bias",sprintf("'b%04b",$bias));
  } elsif($pe_conv_mode eq &get_hash_key("DW_PW",\%pe_conv_mode_tab)) {
    &msgp($base_tab_lv,"kernel_size_h:",$kernel_size_h);
    &msgp($base_tab_lv,"kernel_size_w:",$kernel_size_w);
    &msgp($base_tab_lv,"padding_left",$padding_left);
    &msgp($base_tab_lv,"padding_right",$padding_right);
    &msgp($base_tab_lv,"padding_up",$padding_up);
    &msgp($base_tab_lv,"padding_down",$padding_down);
    &msgp($base_tab_lv,"stride_h",$stride_h);
    &msgp($base_tab_lv,"stride_w",$stride_w);
    &msgp($base_tab_lv,"dw_bias",sprintf("'b%04b",$dw_pw_conv_dw_bias));
    &msgp($base_tab_lv,"pw_bias",sprintf("'b%04b",$dw_pw_conv_pw_bias));
  } elsif($pe_conv_mode eq &get_hash_key("PE_IDLE",\%pe_conv_mode_tab)) {
    &msgp($base_tab_lv,"PE_IDLE");
  } 
}

sub vpu_print{
  say "VPU config info:";
  my $base_tab_lv = shift @_;
  &msgp($base_tab_lv,"vpu_mode",$vpu_mode_str);
  if($vpu_mode eq  &get_hash_key("Eltwise",\%vpu_mode_tab)) {
    &msgp($base_tab_lv+1,"eltwise_type",$eltwise_type_str);
  } elsif($vpu_mode eq  &get_hash_key("ReLU",\%vpu_mode_tab)) {
    &msgp($base_tab_lv+1,"relu_type",$relu_type_str);
    if($relu_type eq  &get_hash_key("LReLU",\%relu_type_tab)) {
      &msgp($base_tab_lv+2,"relu_a_value",sprintf("'h%08x",$relu_a_value));
    }

  } elsif($vpu_mode eq  &get_hash_key("Sigmoid",\%vpu_mode_tab)) {
  } elsif($vpu_mode eq  &get_hash_key("Pooling",\%vpu_mode_tab)) {
    &msgp($base_tab_lv+1,"pooling_type",$pooling_type_str);
    &msgp($base_tab_lv+1,"pooling_kernel_size",$pooling_kernel_size);
    &msgp($base_tab_lv+1,"pooling_stride",$pooling_stride);
    &msgp($base_tab_lv+1,"pooling_padding",sprintf("'b%s",$pooling_padding));
  } elsif($vpu_mode eq  &get_hash_key("Global_Pooling",\%vpu_mode_tab)) {
    &msgp($base_tab_lv+1,"pooling_type",$pooling_type_str);
    &msgp($base_tab_lv+1,"global_pooling_val",&float_bin_print($global_pooling_val));
  } elsif($vpu_mode eq  &get_hash_key("Upsample",\%vpu_mode_tab)) {
    &msgp($base_tab_lv+1,"upsample_scale",$upsample_scale);
  } elsif($vpu_mode eq  &get_hash_key("SGM",\%vpu_mode_tab)) {
    &msgp($base_tab_lv+1,"sgm_type",$sgm_type_str);
    if($sgm_type eq  &get_hash_key("Correlation",\%sgm_type_tab)) {
      my @sgm_offset = split//,$sgm_offset0;
      my $sign = shift @sgm_offset;
      if($sign) {
        &msgp($base_tab_lv+2,"D0","-".&bin_to_dec(join "",@sgm_offset));
      } else {
        &msgp($base_tab_lv+2,"D0",&bin_to_dec(join "",@sgm_offset));
      }
    } elsif($sgm_type eq  &get_hash_key("Softmax_E^X",\%sgm_type_tab)) {
        &msgp($base_tab_lv+2,"act_ich_num",$sgm_offset0);
        &msgp($base_tab_lv+2,"sgm_offset1",$sgm_offset1);
    } elsif($sgm_type eq  &get_hash_key("Softmax_W",\%sgm_type_tab)) {
        &msgp($base_tab_lv+2,"act_ich_num",$sgm_offset0);
        &msgp($base_tab_lv+2,"sgm_offset1",$sgm_offset1);
    } else {
        &msgp($base_tab_lv+2,"sgm_offset0",$sgm_offset0);
        &msgp($base_tab_lv+2,"sgm_offset0",$sgm_offset0);
    }
  } elsif($vpu_mode eq  &get_hash_key("Eltwise_Relu",\%vpu_mode_tab)) {
    &msgp($base_tab_lv+1,"eltwise_type",$eltwise_type_str);
  } elsif($vpu_mode eq  &get_hash_key("Only_Relu",\%vpu_mode_tab)) {
    &msgp($base_tab_lv+1,"relu_type",$relu_type_str);
    if($relu_type eq  &get_hash_key("LReLU",\%relu_type_tab)) {
      &msgp($base_tab_lv+2,"relu_a_value",&float_bin_print($relu_a_value));
    }
  } elsif($vpu_mode eq  &get_hash_key("Only_Sigmoid",\%vpu_mode_tab)) {
  } elsif($vpu_mode eq  &get_hash_key("Data_Format",\%vpu_mode_tab)) {
  } elsif($vpu_mode eq  &get_hash_key("Tranapose",\%vpu_mode_tab)) {
    &msgp($base_tab_lv+1,"transpose_type",$transpose_type_str);
  } 
}

sub quantization_print{
  say "Quantization info:";
  my $base_tab_lv = shift @_;
  if($vpu_mode eq  &get_hash_key("Eltwise",\%vpu_mode_tab)) {
    &msgp($base_tab_lv,"dequant_scale1",&float_bin_print($dequant_scale1));
    &msgp($base_tab_lv,"dequant_scale0",&float_bin_print($dequant_scale0));
    &msgp($base_tab_lv,"quant_scale1",&float_bin_print($quant_scale1));
    &msgp($base_tab_lv,"quant_scale0",&float_bin_print($quant_scale0));
  } elsif($vpu_mode eq  &get_hash_key("Eltwise_Relu",\%vpu_mode_tab)) {
    &msgp($base_tab_lv,"dequant_scale1",&float_bin_print($dequant_scale1));
    &msgp($base_tab_lv,"dequant_scale0",&float_bin_print($dequant_scale0));
    &msgp($base_tab_lv,"quant_scale1",&float_bin_print($quant_scale1));
    &msgp($base_tab_lv,"quant_scale0",&float_bin_print($quant_scale0));
  } elsif($pe_conv_mode eq  &get_hash_key("GEMM",\%pe_conv_mode_tab)) {
    &msgp($base_tab_lv,"dequant_scale0",&float_bin_print($dequant_scale0));
    &msgp($base_tab_lv,"quant_scale0",&float_bin_print($quant_scale0));
  } else {
    &msgp($base_tab_lv,"dequant_scale0",&float_bin_print($dequant_scale0));
    &msgp($base_tab_lv,"quant_scale0",&float_bin_print($quant_scale0));
    if($pe_conv_mode eq &get_hash_key("DW_PW",\%pe_conv_mode_tab)) {
        &msgp($base_tab_lv,"quant_scale1",&float_bin_print($quant_scale1));
    }
    if($conv_asym_quant_en) {
      &msgp($base_tab_lv,"conv_asym_quant_en",$switch_val{$conv_asym_quant_en});
      &msgp($base_tab_lv+1,"conv_asym_quant_bias_1",$conv_asym_quant_bias_1);
      &msgp($base_tab_lv+1,"conv_asym_quant_bias_0",$conv_asym_quant_bias_0);
    } else {
      &msgp($base_tab_lv,"conv_asym_quant_en",$switch_val{$conv_asym_quant_en});
    }
  }
}


sub input_feature_print{
  say "Input feature info:";
  my $base_tab_lv = shift @_;
  if($pe_conv_mode eq  &get_hash_key("GEMM",\%pe_conv_mode_tab)) {
    &msgp($base_tab_lv,"gemm_k",$input_size_n);
    &msgp($base_tab_lv,"gemm_channel",$input_size_c);
    &msgp($base_tab_lv,"gemm_l_h",$input_size_h);
    &msgp($base_tab_lv,"gemm_r_w",$input_size_w);
    &msgp($base_tab_lv,"input_format",$input_format_str);
    &msgp($base_tab_lv,"input_data",$input_data_str);
  } else {
    &msgp($base_tab_lv,"input_size_n",$input_size_n);
    &msgp($base_tab_lv,"input_size_c",$input_size_c);
    &msgp($base_tab_lv,"input_size_h",$input_size_h);
    &msgp($base_tab_lv,"input_size_w",$input_size_w);
    &msgp($base_tab_lv,"input_format",$input_format_str);
    &msgp($base_tab_lv,"input_data",$input_data_str);
  }
  if($conv_asym_quant_en) {
    if($input_data eq &get_hash_key("INT16",\%input_data_type_tab)) {
      &msgp($base_tab_lv , "input_feature_padding" , $input_feature_padding_value_int16  );
    }
    else {
      &msgp($base_tab_lv , "input_feature_padding" , $input_feature_padding_value_int8  );
    }
  }
}

sub output_feature_print{
  say "Output feature info:";
  my $base_tab_lv = shift @_;
  &msgp($base_tab_lv,"output_size_n",$output_size_n);
  &msgp($base_tab_lv,"output_size_c",$output_size_c);
  &msgp($base_tab_lv,"output_size_h",$output_size_h);
  &msgp($base_tab_lv,"output_size_w",$output_size_w);
  &msgp($base_tab_lv,"output_format",$output_format_str);
  &msgp($base_tab_lv,"output_data",$output_data_str);
}

sub addr_info_print{
  say "Addr info:";
  my $base_tab_lv = shift @_;
  if($vpu_mode eq  &get_hash_key("Eltwise",\%vpu_mode_tab)) {
    &msgp($base_tab_lv,"1st f_in_addr_sel     ",$f_in_addr_str     );
    &msgp($base_tab_lv,"2nd f_in_addr_sel     ",$k_in_addr_str     );
  } else {
    &msgp($base_tab_lv,"f_in_addr_sel     ",$f_in_addr_str     );
    &msgp($base_tab_lv,"k_in_addr_sel     ",$k_in_addr_str     );
  }
  &msgp($base_tab_lv,"f_out_addr_sel    ",$f_out_addr_str    );
  &msgp($base_tab_lv,"bias_addr_sel     ",$bias_addr_str     );
  &msgp($base_tab_lv,"k_in_2_addr_sel   ",$k_in_2_addr_str   );
  &msgp($base_tab_lv,"other_addr_sel    ",$other_addr_str    );
  &msgp($base_tab_lv,"bias_2_addr_sel   ",$bias_2_addr_str   );
  &msgp($base_tab_lv,"dequant_addr_sel  ",$dequant_addr_str  );
  &msgp($base_tab_lv,"dequant_2_addr_sel",$dequant_2_addr_str);

  if($vpu_mode eq  &get_hash_key("Eltwise",\%vpu_mode_tab)) {
    &msgp($base_tab_lv,"1st f_in_addr     ",sprintf("'h%08x",$f_in_addr     ));
    &msgp($base_tab_lv,"2nd f_in_addr     ",sprintf("'h%08x",$k_in_addr     ));
  } else {
    &msgp($base_tab_lv,"f_in_addr     ",sprintf("'h%08x",$f_in_addr     ));
    &msgp($base_tab_lv,"k_in_addr     ",sprintf("'h%08x",$k_in_addr     ));
  }
  &msgp($base_tab_lv,"f_out_addr    ",sprintf("'h%08x",$f_out_addr    ));
  &msgp($base_tab_lv,"bias_addr     ",sprintf("'h%08x",$bias_addr     ));
  &msgp($base_tab_lv,"k_in_2_addr   ",sprintf("'h%08x",$k_in_2_addr   ));
  &msgp($base_tab_lv,"other_addr    ",sprintf("'h%08x",$other_addr    ));
  &msgp($base_tab_lv,"bias_2_addr   ",sprintf("'h%08x",$bias_2_addr   ));
  &msgp($base_tab_lv,"dequant_addr  ",sprintf("'h%08x",$dequant_addr  ));
  &msgp($base_tab_lv,"dequant_2_addr",sprintf("'h%08x",$dequant_2_addr));
}

sub dma_ctrl_print{
  say "DMA control info:";
  my $base_tab_lv = shift @_;
  &msgp($base_tab_lv , "dma_sn"          , $dma_sn     );
  &msgp($base_tab_lv , "ocm_in_ind"      , $switch_val{$ocm_in_ind});
  &msgp($base_tab_lv , "wb_ins_exe_ind"  , $switch_val{$wb_ins_exe_ind});
  &msgp($base_tab_lv , "wb_ins_exe_wait" , $switch_val{$wb_ins_exe_wait});
  &msgp($base_tab_lv , "unlock_ind"      , $switch_val{$unlock_ind});
  &msgp($base_tab_lv , "unlock_bn_begin" , $unlock_bn_begin    );
  &msgp($base_tab_lv , "unlock_bn_end"   , $unlock_bn_end     );
}

sub kernel_compress_print{
  say "Kernel compress info:";
  my $base_tab_lv = shift @_;
  &msgp($base_tab_lv,"decompress_en",$switch_val{$decompress_en});
  if($decompress_en) {
    &msgp($base_tab_lv , "queue_flex_cfg"         , $queue_flex_cfg          );
    &msgp($base_tab_lv , "firm_size_compressed"   , $firm_size_compressed    );
    &msgp($base_tab_lv , "firm_ori_data_tail_mod" , $firm_ori_data_tail_mod  );
    &msgp($base_tab_lv , "flex_size_compressed"   , $flex_size_compressed    );
    &msgp($base_tab_lv , "flex_ori_data_tail_mod" , $flex_ori_data_tail_mod  );
  }
  &msgp($base_tab_lv,"pw_compress_en",$switch_val{$pw_decompress_en});
  if($pw_decompress_en) {
    &msgp($base_tab_lv , "pw_queue_flex_cfg"         , $pw_queue_flex_cfg          );
    &msgp($base_tab_lv , "pw_firm_size_compressed"   , $pw_firm_size_compressed    );
    &msgp($base_tab_lv , "pw_firm_ori_data_tail_mod" , $pw_firm_ori_data_tail_mod  );
    &msgp($base_tab_lv , "pw_flex_size_compressed"   , $pw_flex_size_compressed    );
    &msgp($base_tab_lv , "pw_flex_ori_data_tail_mod" , $pw_flex_ori_data_tail_mod  );
  }
}

sub vpu_asym_quant_print{
  say "Vpu asym quantization info:";
  my $base_tab_lv = shift @_;
  &msgp($base_tab_lv,"vpu_asym_quant_en",$switch_val{$vpu_asym_quant_en});
  if($vpu_asym_quant_en) {
    &msgp($base_tab_lv , "vpu_asym_dequant_bias_1" , $vpu_asym_dequant_bias_1  );
    &msgp($base_tab_lv , "vpu_asym_dequant_bias_0" , $vpu_asym_dequant_bias_0  );
    &msgp($base_tab_lv , "vpu_asym_quant_bias" , $vpu_asym_quant_bias  );
    if($input_data eq &get_hash_key("INT16",\%input_data_type_tab)) {
      &msgp($base_tab_lv , "input_feature_padding" , $input_feature_padding_value_int16  );
    }
    else {
      &msgp($base_tab_lv , "input_feature_padding" , $input_feature_padding_value_int8  );
    }
  }
}

#---------------------------------------------------
# INSTRUCTION constraint check 
#--------------------------------------------------- 
sub in_list {
  return grep /$_[0]/,(keys %{$_[1]});
}

sub err_chk{
  unshift @err_msg,$_[1] if(not eval($_[0]));
}


&err_chk('&in_list($pe_conv_mode,\%pe_conv_mode_tab)'
        ,"pe_conv_mode value is invalid! : $pe_conv_mode_str");
&err_chk('$npu_work_block_mode_str eq "PE_VPU" ? ($pe_conv_mode_str ne "PE_IDLE") : 1'
         ,"Conv mode under PE_VPU is invalid! : $pe_conv_mode_str");
&err_chk('$npu_work_block_mode_str eq "VPU" ? ($pe_conv_mode_str eq "PE_IDLE") : 1'
         ,"Conv mode under VPU is invalid! : $pe_conv_mode_str");
&err_chk('$npu_work_block_mode_str eq "Only DMA" ? ($pe_conv_mode_str eq "PE_IDLE") : 1'
         ,"Conv mode under Only DMA is invalid! : $pe_conv_mode_str");
&err_chk('$pe_conv_mode_str eq "TransposeConv" ? ($npu_pmode_str eq "ALL_OCH") : 1'
         ,"TransposeConv only support ALL_OCH! : $npu_pmode_str");
&err_chk('$pe_conv_mode_str eq "AtrousConv" ? ($npu_pmode_str eq "ALL_OCH") : 1'
         ,"AtrousConv only support ALL_OCH! : $npu_pmode_str");

&err_chk('$npu_pmode_str eq "2RP" ? ($broadcast_info le 2) : 1'
         ,"1_to_8 broadcast is not support under 2RP! : $broadcast_info_str");
&err_chk('$npu_pmode_str eq "4RP" ? ($broadcast_info le 1) : 1'
         ,"1_to_4/8 broadcast is not support under 4RP! : $broadcast_info_str");
&err_chk('$pe_conv_mode_str eq "GEMM" ? ($broadcast_info eq 3) : 1'
         ,"GEMM only suppoer 1_to_8 broadcast! : $broadcast_info_str");


 #say "---";
 #say eval('$npu_work_block_mode_str eq "PE_VPU" ? ($pe_conv_mode_str ne "Conv_2D") : 1');
 #say "---";
foreach (@err_msg) {
  say $_;
}
