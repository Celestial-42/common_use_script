#!/usr/bin/perl
use strict;
use 5.010;
use Spreadsheet::ParseExcel;
use Data::Dumper;
use POSIX;
use experimental qw( switch );
#use Spreadsheet::ParseXLSX;


my $parser = Spreadsheet::ParseExcel->new();
my $workbook_ha = $parser->parse("ha_ptable.xls");
my $workbook_ra = $parser->parse("ra_ptable.xls");

# config 
my $ccg_lut_amend_num = 5;
my @ha_i_struct_col_num = (3,2,4,3,2 ,2,3,3,2);
my @ha_o_struct_col_num = (3,2,3,1,7 ,3,7,6,5);
my @ra_i_struct_col_num = (3,2,2,2,2 ,3,2,2,2);
my @ra_o_struct_col_num = (6,3,3,5,3 ,3,6,4,6);

# divide into REQ Ptable and Snp PTable

sub worksheets_get {
    my @req_worksheets;
    my @snp_worksheets;

    my $workbook = $_[0];
    my @i_struct_col_num = @{$_[1]};
    my @o_struct_col_num = @{$_[2]};
    my $prefix = $_[3];
    my $idx = 0;
    for my $worksheet ($workbook->worksheets()) {
        my $str = uc($prefix.$worksheet->get_name());
        #say("-->$str");
        if($str =~ m/SNP$/) {
            my @temp;
            $temp[0] = $str; #name
            $temp[1] = $worksheet;
            $temp[2] = $i_struct_col_num[$idx];
            $temp[3] = $o_struct_col_num[$idx];
            push @snp_worksheets,\@temp;
        } else {
            my @temp;
            $temp[0] = $str; #name
            $temp[1] = $worksheet;
            $temp[2] = $i_struct_col_num[$idx];
            $temp[3] = $o_struct_col_num[$idx];
            push @req_worksheets,\@temp;
        }
        $idx+=1;
    }
    return (\@req_worksheets,\@snp_worksheets);
}

my ($ra_req_worksheets,$ra_snp_worksheets) = worksheets_get($workbook_ra,\@ra_i_struct_col_num,\@ra_o_struct_col_num,'ra_');
my ($ha_req_worksheets,$ha_snp_worksheets) = worksheets_get($workbook_ha,\@ha_i_struct_col_num,\@ha_o_struct_col_num,'ha_');

#say(Dumper($ra_req_worksheets));
#say(Dumper($ra_snp_worksheets));
#say(Dumper($ha_req_worksheets));
#say(Dumper($ha_snp_worksheets));


# Generate Package
sub enum_gene {
    my @st_enum_list;
    my @op_enum_list;
    my @worksheets = @{$_[0]};
    for my $array (@worksheets) {
        #say($array->[1]);
        my $worksheet = $array->[1];
        
        my ($row_min,$row_max) = $worksheet->row_range();
        #say($row_min,$row_max);
        for my $row(1 .. $row_max) {
            my $cell = $worksheet->get_cell($row,1);
            next unless $cell;
            next unless $cell->value();
            my $content = $cell->unformatted();

            my @content_arr = split //,$content;
            my @content_flit = grep {/[A-Z_a-z0-9]+/} @content_arr;
            my $fin_str = uc(join /''/,@content_flit);
            if (not $fin_str =~ m/IDLE/){ #skip IDLE st to keep IDLE state always zero value;
                push @st_enum_list,$fin_str if not grep {$_ eq $fin_str} @st_enum_list;
            }

            $cell = $worksheet->get_cell($row,2);
            $content = $cell->unformatted();
            @content_arr = split //,$content;
            @content_flit = grep {/[A-Za-z0-9_]+/} @content_arr;
            $fin_str = uc(join /''/,@content_flit);
        
            push @op_enum_list,$fin_str if not grep {$_ eq $fin_str} @op_enum_list;
        }        
    }
    #say("----");
    #say(Dumper(\@st_enum_list)); 
    #say(Dumper(\@op_enum_list)); 
    my @temp = (\@st_enum_list,\@op_enum_list);
    #say(Dumper(\@temp)); 
    #say("----");
    return \@temp;
}


my %ptable_enum;

$ptable_enum{"RASNP"} = enum_gene($ra_snp_worksheets);
$ptable_enum{"RAREQ"} = enum_gene($ra_req_worksheets);
$ptable_enum{"HASNP"} = enum_gene($ha_snp_worksheets);
$ptable_enum{"HAREQ"} = enum_gene($ha_req_worksheets);

#say(Dumper(\%ptable_enum));
# plus 1 to add "IDLE" state cnt
my $ra_snp_st_width = ceil(log($#{$ptable_enum{"RASNP"}->[0]}+1) / log(2));
my $ra_req_st_width = ceil(log($#{$ptable_enum{"RAREQ"}->[0]}+1) / log(2));
my $ha_snp_st_width = ceil(log($#{$ptable_enum{"HASNP"}->[0]}+1) / log(2));
my $ha_req_st_width = ceil(log($#{$ptable_enum{"HAREQ"}->[0]}+1) / log(2));
my $ra_snp_op_width = ceil(log($#{$ptable_enum{"RASNP"}->[1]}+1) / log(2));
my $ra_req_op_width = ceil(log($#{$ptable_enum{"RAREQ"}->[1]}+1) / log(2));
my $ha_snp_op_width = ceil(log($#{$ptable_enum{"HASNP"}->[1]}+1) / log(2));
my $ha_req_op_width = ceil(log($#{$ptable_enum{"HAREQ"}->[1]}+1) / log(2));

# Formatted Pkt file generate
my $st_name;
my $st_macro;
my $st_idx;

format STNAME =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< = @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'d@<<
        $st_name,                                             $st_macro,$st_idx
.



open(my $pkg_ofile,">./lut_test_verilog/ccg_lut_pkg.sv");

print $pkg_ofile "`ifndef CCG_LUT_PKG_SV\n";
print $pkg_ofile "`define CCG_LUT_PKG_SV\n";
print $pkg_ofile "package ccg_lut_pkg;\n";
for my $key (keys %ptable_enum) {
    print $pkg_ofile "    typedef enum logic [`CCG_${key}LUT_ST_WIDTH-1:0] {\n";
    select($pkg_ofile);
    $~ = "STNAME";
    $st_name =  $key."_"."IDLE";
    $st_macro = "`CCG_${key}LUT_ST_WIDTH";
    $st_idx = "0,";
    write;
    for my $idx  (0..$#{$ptable_enum{$key}->[0]}) {
        my $st = $ptable_enum{$key}->[0]->[$idx];

        my $idxp1 = $idx + 1;
        if($idx eq $#{$ptable_enum{$key}->[0]}) {
            $st_idx = $idxp1;
        }
        else {
            $st_idx = $idxp1.",";
        }

        $st_name =  $key."_".$st;
        $st_macro = "`CCG_${key}LUT_ST_WIDTH";
        write;
    }
    print $pkg_ofile "    } ccg_".lc($key)."lut_st_t;\n\n";

    print $pkg_ofile "    typedef enum logic [`CCG_${key}LUT_OP_WIDTH-1:0] {\n";
    select($pkg_ofile);
    $~ = "STNAME";
    for my $idx  (0..$#{$ptable_enum{$key}->[1]}) {
        my $st = $ptable_enum{$key}->[1]->[$idx];

        if($idx eq $#{$ptable_enum{$key}->[1]}) {
            $st_idx = $idx;
        }
        else {
            $st_idx = $idx.",";
        }

        $st_name = $key."_".$st;
        $st_macro = "`CCG_${key}LUT_OP_WIDTH";
        write;
    }

    print $pkg_ofile "    } ccg_".lc($key)."lut_op_t;\n\n";
}
print $pkg_ofile "endpackage:ccg_lut_pkg\n";
print $pkg_ofile "`endif\n";
close($pkg_ofile);
select(STDOUT);

# Macro generate
open(my $macro_ofile,">./lut_test_verilog/ccg_lut_define.v");
print $macro_ofile "`ifndef CCG_LUT_DEFINE\n";
print $macro_ofile "`define CCG_LUT_DEFINE\n";
print $macro_ofile "  `define CCG_RASNPLUT_ST_WIDTH $ra_snp_st_width\n";
print $macro_ofile "  `define CCG_RAREQLUT_ST_WIDTH $ra_req_st_width\n";
print $macro_ofile "  `define CCG_HASNPLUT_ST_WIDTH $ra_snp_st_width\n";
print $macro_ofile "  `define CCG_HAREQLUT_ST_WIDTH $ra_req_st_width\n";
print $macro_ofile "  `define CCG_RASNPLUT_OP_WIDTH $ra_snp_op_width\n";
print $macro_ofile "  `define CCG_RAREQLUT_OP_WIDTH $ra_req_op_width\n";
print $macro_ofile "  `define CCG_HASNPLUT_OP_WIDTH $ra_snp_op_width\n";
print $macro_ofile "  `define CCG_HAREQLUT_OP_WIDTH $ra_req_op_width\n";
print $macro_ofile "`endif\n";
close($macro_ofile);


# struct generate

sub struct_gene {
    my %struct_field;
    my @worksheets = @{$_[0]};
    for my $array (@worksheets) {
        #say($array->[1]);
        my @i_field;
        my @o_field;
        my $name = $array->[0];
        #say($name);
        my $worksheet = $array->[1];
        my $i_struct_col_num = $array->[2];
        my $o_struct_col_num = $array->[3];
        #say($row_min,$row_max);
        for my $col(1 .. $i_struct_col_num+$o_struct_col_num) {
            my $cell = $worksheet->get_cell(0,$col);

            my $content = $cell->unformatted();
            my @content_arr = split //,$content;
            my @content_flit = grep {/[A-Z_a-z0-9]+/} @content_arr;
            my $fin_str = lc(join /''/,@content_flit);

            if($col <= $i_struct_col_num) {
                push @i_field,$fin_str if not grep {$_ eq $fin_str} @i_field;
            } else {
                push @o_field,$fin_str if not grep {$_ eq $fin_str} @o_field;
            }
        }  
        my @temp = (\@i_field,\@o_field);
        $struct_field{$name} = \@temp;
    }
    return \%struct_field;
}


my $type;
my $type_ins;
format STRUCT_ITEM =
        @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        $type,                                                  $type_ins
.


open(my $struct_ofile,">./lut_test_verilog/ccg_lut_struct.sv");

select($struct_ofile);
$~ = "STRUCT_ITEM";

my @struct_hash_array;
for my $hash_ref ($ra_req_worksheets,$ra_snp_worksheets,$ha_req_worksheets,$ha_snp_worksheets) {
    my $struct_hash = struct_gene($hash_ref);
    push @struct_hash_array,$struct_hash;
    #say(Dumper($struct_hash));

    for my $name (keys(%{$struct_hash})) {
        my $st_op_class;
        $st_op_class = lc($name);
        $st_op_class = ($name =~ m/^RA/) ? "ra" : "ha";
        $st_op_class .= ($name =~ m/_SNP$/) ? "snp" : "req";
        #$st_op_class = "ha_req" if ($name =~ m/^ha_chi_snp$/); #Special cond
        my $struct_name = lc($name);
        print $struct_ofile "    typedef struct packed {\n";
        for my $idx (0..$#{$struct_hash->{$name}->[0]}){ #i_field
            my $item = $struct_hash->{$name}->[0]->[$idx]; 
            $type = ($item =~ m/cur_st/) ? "ccg_${st_op_class}lut_st_t" : "logic";
            $type = "ccg_${st_op_class}lut_op_t" if ($item =~ m/opcode/);
            $type_ins = $item.";";
            if($item =~ m/haz_cb_type/) {#special cond
                $type = 'ccg_copyback_type_t';
            }
            write;
        }
        print $struct_ofile "    } ccg_${struct_name}lut_i_t;\n\n";

        print $struct_ofile "    typedef struct packed {\n";
        for my $idx (0..$#{$struct_hash->{$name}->[1]}){ #i_field
            my $item = $struct_hash->{$name}->[1]->[$idx]; 
            $type = ($item =~ m/nxt_st/) ? "ccg_${st_op_class}lut_st_t" : "logic";
            $type = "ccg_${st_op_class}lut_op_t" if ($item =~ m/opcode/);
            $type_ins = $item.";";
            write;
        }
        print $struct_ofile "    } ccg_${struct_name}lut_o_t;\n\n";
    }
}

close($struct_ofile);
select(STDOUT);

# Ptable Logic RTL
# print(Dumper(\@struct_hash_array));

$ccg_lut_amend_num -= 1;
for my $hash_ref ($ra_req_worksheets,$ra_snp_worksheets,$ha_req_worksheets,$ha_snp_worksheets) {
    my @worksheets = @{$hash_ref};
    for my $array (@worksheets) {
        my $ptable_name = lc($array->[0]);

        #say("***************************$ptable_name");
        my ($row_min,$row_max) = $array->[1]->row_range();
        my $i_struct_col_num = $array->[2];
        my $o_struct_col_num = $array->[3];
        my $st_op_class;
        #$st_op_class = uc($name);
        $st_op_class = ($ptable_name =~ m/^ra/) ? "RA" : "HA";
        $st_op_class .= ($ptable_name =~ m/_snp$/) ? "SNP" : "REQ";
        #$st_op_class = "HA_REQ" if ($ptable_name =~ m/^ha_chisnp$/); #Special cond
        my $uc_ptable_name = uc($ptable_name);
        open(my $logic_ofile,">./lut_test_verilog/ccg_${ptable_name}lut.v");
        print $logic_ofile "`include \"ccg_lut_pkg.sv\"\n";
        print $logic_ofile "`include \"ccg_common_pkg.sv\"\n";
        print $logic_ofile "module ccg_${ptable_name}_ptable \n import ccg_lut_pkg::*; \nimport ccg_common_pkg::*; \n";
        print $logic_ofile "#(\n";
        print $logic_ofile "parameter type CCG_${uc_ptable_name}LUT_I_T = logic,\n";
        print $logic_ofile "parameter type CCG_${uc_ptable_name}LUT_O_T = logic\n";
        print $logic_ofile ")(\n";
        #print $logic_ofile "    input                                               clk,\n";
        #print $logic_ofile "    input                                               rst,\n";
        print $logic_ofile "    input  CCG_${uc_ptable_name}LUT_I_T                      ccg_${ptable_name}lut_amend_i_s[0:${ccg_lut_amend_num}],\n";
        print $logic_ofile "    input  CCG_${uc_ptable_name}LUT_O_T                      ccg_${ptable_name}lut_amend_o_s[0:${ccg_lut_amend_num}],\n";
        print $logic_ofile "    input                                                 ccg_${ptable_name}lut_amend_vld[0:${ccg_lut_amend_num}],\n";
        print $logic_ofile "    input  CCG_${uc_ptable_name}LUT_I_T                      ccg_${ptable_name}lut_i_s,\n";
        print $logic_ofile "    input                                                 ccg_${ptable_name}lut_i_vld,\n";
        print $logic_ofile "    output CCG_${uc_ptable_name}LUT_O_T                      ccg_${ptable_name}lut_o_s,\n";
        print $logic_ofile "    output logic                                          ccg_${ptable_name}lut_o_vld,\n";
        print $logic_ofile "    output logic                                          ccg_${ptable_name}lut_match\n";
        print $logic_ofile ");\n\n";
        print $logic_ofile "`include \"ccg_lut_struct.sv\"\n";
        #print $logic_ofile "ccg_${ptable_name}_lut_o_t ccg_${ptable_name}_lut_o_s_pre;\n\n";
        #print $logic_ofile "ccg_${ptable_name}_lut_o_t ccg_${ptable_name}_lut_o_s;\n\n";
        
        for my $idx (0..$ccg_lut_amend_num) {
            print $logic_ofile "wire amend_match_${idx} = ccg_${ptable_name}lut_amend_vld[$idx] & (ccg_${ptable_name}lut_amend_i_s[$idx] ==  ccg_${ptable_name}lut_i_s);\n";
        }
        print $logic_ofile "always_comb begin\n";
        for my $idx (0..$ccg_lut_amend_num) {
            my $prefix = ($idx == 0) ? "if" : "else if";
            print $logic_ofile "    $prefix(amend_match_${idx}) begin\n";
            #print $logic_ofile "        ccg_${ptable_name}lut_o_s_pre = ccg_${ptable_name}lut_amend_o_s[${idx}];\n";
            print $logic_ofile "        ccg_${ptable_name}lut_o_s = ccg_${ptable_name}lut_amend_o_s[${idx}];\n";
            print $logic_ofile "        ccg_${ptable_name}lut_match = 1'b1;\n";
            print $logic_ofile "    end\n";
        }
        print $logic_ofile "    else begin\n";
        print $logic_ofile "        case({";
        my $class_idx;
        given($st_op_class) {
            when("RAREQ") {$class_idx = 0}
            when("RASNP") {$class_idx = 1}
            when("HAREQ") {$class_idx = 2}
            when("HASNP") {$class_idx = 3}
        }
        my @i_field_array = @{$struct_hash_array[$class_idx]->{uc($ptable_name)}->[0]};
        my @o_field_array = @{$struct_hash_array[$class_idx]->{uc($ptable_name)}->[1]};
        #say(Dumper(\@i_field_array));
        #say(Dumper(\@o_field_array));
        my $str;
        for my $item (@i_field_array)  {
            $str .="ccg_${ptable_name}lut_i_s\.$item,";
        }
        chop($str);
        print $logic_ofile "$str})\n";
        my $worksheet = $array->[1];
        for my $row(1 .. $row_max) {
            my $cell = $worksheet->get_cell($row,1);
            next unless $cell;
            next unless $cell->value();
            print $logic_ofile "            {";
            my $all_str;
            #say(Dumper(\@i_field_array));
            for my $col (1..$i_struct_col_num) {
                my $if_cell = $worksheet->get_cell($row,$col);
                my $if_content;
                if($if_cell) {
                    $if_content = $if_cell->unformatted();
                    my @if_content_arr = split //,$if_content;
                    my @if_content_flit = grep {/[A-Z_a-z0-9]+/} @if_content_arr;
                    $if_content = uc(join /''/,@if_content_flit);
                    $if_content = "1'b0" if(not $if_content);#Special cond
                    $if_content = "1'b1" if($if_content =~ m/^1$/);#Special cond
                    if($i_field_array[$col-1] =~ m/haz_cb_type/) {#special cond
                        $if_content = $if_content if(not $if_content =~ m/^\d/);#Special cond
                    } else {
                        $if_content = $st_op_class."_".$if_content if(not $if_content =~ m/^\d/);#Special cond
                    }
                } else {
                    $if_content = "1'b0";
                    warn("undefined $ptable_name cell ($row,$col), use 1'b0 instead");
                }


                #say("$row---$col---$if_content---$all_str");
                $all_str .= $if_content.",";
            }
            chop($all_str);
            #say("--->$all_str");
            print $logic_ofile "$all_str}: begin\n";
            for my $idx (0..$#{\@o_field_array})  {
                my $item = $o_field_array[$idx];
                #$all_str = "                ccg_${ptable_name}lut_o_s_pre\.$item = ";
                $all_str = "                ccg_${ptable_name}lut_o_s\.$item = ";
                my $col = $idx+$i_struct_col_num+1;
                my $if_cell = $worksheet->get_cell($row,$col);
                my $if_content;
                if($if_cell) {
                    $if_content = $if_cell->unformatted();
                    my @if_content_arr = split //,$if_content;
                    my @if_content_flit = grep {/[A-Z_a-z0-9]+/} @if_content_arr;
                    $if_content = uc(join /''/,@if_content_flit);
                    $if_content = "1'b0" if(not $if_content);#Special cond
                    $if_content = "1'b1" if($if_content =~ m/^1$/);#Special cond
                    $if_content = $st_op_class."_".$if_content if(not $if_content =~ m/^\d/);#Special cond
                    
                } else {
                    $if_content = "1'b0";
                    warn("undefined $ptable_name cell ($row,$col), use 1'b0 instead");
                }
                $all_str .= $if_content;
                #say("$idx---$col---$item---$if_content");
                print $logic_ofile "$all_str;\n";
            }
            print $logic_ofile "                ccg_${ptable_name}lut_match = 1'b1;\n";
            print $logic_ofile "            end\n";

        }


        #default cond
        print $logic_ofile "            default:begin;\n";
        for my $idx (0..$#{\@o_field_array})  {
            my $item = $o_field_array[$idx];
            #$all_str = "                ccg_${ptable_name}lut_o_s_pre\.$item = ";
            my $all_str = "                ccg_${ptable_name}lut_o_s\.$item = ";
            my $col = $idx+$i_struct_col_num+1;
            my $if_content;
            $if_content = "1'b0" ;
            if($item =~ m/(cur|nxt)_st/) {
                $if_content = $st_op_class."_"."IDLE";#Special cond
            }
            $all_str .= $if_content;
            #say("$idx---$col---$item---$if_content");
            print $logic_ofile "$all_str;\n";
        }
        print $logic_ofile "                ccg_${ptable_name}lut_match = 1'b0;\n";
        print $logic_ofile "            end\n";


        print $logic_ofile "        endcase\n";
        print $logic_ofile "    end\n";
        print $logic_ofile "end\n\n";

        
        #print $logic_ofile "always_ff @(posedge clk,posedge rst) begin\n";
        #print $logic_ofile "    if(rst)\n";
        #print $logic_ofile "        ccg_${ptable_name}_lut_o_s <= ccg_${ptable_name}_lut_o_t'(0);\n";
        #print $logic_ofile "    else if(ccg_${ptable_name}_lut_in)\n";
        #print $logic_ofile "        ccg_${ptable_name}_lut_o_s <= ccg_${ptable_name}_lut_o_s_pre;\n";
        #print $logic_ofile "end\n";

        #print $logic_ofile "always_ff @(posedge clk,posedge rst) begin\n";
        #print $logic_ofile "    if(rst)\n";
        #print $logic_ofile "        ccg_${ptable_name}_lut_out <= 1'b0;\n";
        #print $logic_ofile "    else if(ccg_${ptable_name}_lut_in)\n";
        #print $logic_ofile "        ccg_${ptable_name}_lut_out <= ccg_${ptable_name}_lut_in;\n";
        #print $logic_ofile "end\n";
         
        print $logic_ofile "always_comb begin\n";
        print $logic_ofile "    ccg_${ptable_name}lut_o_vld = ccg_${ptable_name}lut_i_vld;\n";
        print $logic_ofile "end\n";#


        print $logic_ofile "endmodule\n";
        close($logic_ofile);
    } 
}







             
