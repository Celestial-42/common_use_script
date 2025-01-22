import json
import argparse
import sys
import os
import csv
import re

from pathlib import Path
from sam_type_lib import *

def region_size_chk(saddr:str,eaddr:str,size:str):
    saddr_int = int(saddr,16)
    eaddr_int = int(eaddr,16)
    size_int = size_str_to_dec[size]
    if(eaddr_int - saddr_int != (size_int-1)):
        temp = eaddr_int - saddr_int + 1
        idx = 0
        while(temp >= 1024):
            temp = temp / 1024.0
            idx += 1
        cal_size = "%d%s" % (temp,size_str_list[idx])
        return (False,"Region Size not match!\n\tstart_addr:%s\nend_addr:%s\ncfg_size:%s\ncal_size:%s"% (saddr,eaddr,size,cal_size))
    elif(saddr_int % size_int != 0):
        return (False,"Region %s start addr must be aligned to size!" % saddr)
    else:
        return (True,"Chk Pass!")

def region_num_chk(region_list:list,trans_en:bool):
    #scg_num = 0
    htg_num = 0
    nhtg_num = 0
    #scg_region = []
    htg_region = []
    nhtg_region = []
    for region in region_list:
        match region["region_type"]:
            # case "scg":
            #     scg_num  += 1
            #     scg_region.append(region)
            case "htg":
                htg_num  += 1
                region["index"] = htg_num
                htg_region.append(region)
            case "nhtg":
                nhtg_num  += 1
                region["index"] = nhtg_num
                nhtg_region.append(region)
    if(nhtg_num > 64):
        print("Non-Hash Region Exceed 64!")
        if(trans_en):
            if(htg_num > 32):
                sys.exit("Hash Region Exceed 32! \nNo region left, total region num exceed!")
            else:
                alt_htg_num = nhtg_num - 64
                if(alt_htg_num + htg_num > 32):
                    print("Total Region Exceed! %d Hash Region and %d non Hash Region " % htg_num,nhtg_num)
                else:
                    htg_region.extend(nhtg_region[-alt_htg_num:])
                    nhtg_region = nhtg_region[:-alt_htg_num]
                    print("Hash Region Exceed 32! Use %d Hash Region instead" % alt_htg_num)
        else:
            sys.exit("Total Non-Hash Region num exceed! May turn on unused Hash Region Reg to Non-Hash Region?")
    return [[htg_num,htg_region],[nhtg_num,nhtg_region]]

def sector_draw(saddr:int,eaddr:int,max_name_size:int,name:str,type:str,index:int,size:str):
    region_idx = ""
    match type:
        case "htg":
            region_idx  = "Hashed region " + f"{index:02d}"
        case "nhtg":
            region_idx  = "Non hashed region " + f"{index:02d}"
    saddr_full = f"{saddr:#020_x}"
    eaddr_full = f"{eaddr:#020_x}"
    ostr  = "|-" + "-" * 20 + "-|-" + "-" * max_name_size + "-|\n"
    ostr += "| " + saddr_full.upper() + " | " + " "*max_name_size + " |\n"
    ostr += "| " + " " * 20 + " | " + f"{name:^{max_name_size}}" + " |\n"
    ostr += "| " + " " * 20 + " | " + f"{size:^{max_name_size}}" + " |\n"
    ostr += "| " + " " * 20 + " | " + f"{region_idx:^{max_name_size}}" + " |\n"
    ostr += "| " + eaddr_full.upper() + " | " + " "*max_name_size + " |\n"
    ostr += "|-" + "-" * 20 + "-|-" + "-" * max_name_size + "-|\n"
    return ostr

def region_draw(region_list:list):
    region_addr_dict = {}
    region_keys = []
    max_region_name_length = 20 #for "Non hashed region XX"
    ostr = ""
    for region in region_list:
        region_addr_dict[int(region["start_addr"],16)] = region
        region_keys.append(int(region["start_addr"],16))
        if len(region["region_description"]) > max_region_name_length:
            max_region_name_length = len(region["region_description"])

    region_keys.sort()
    last_end_addr = -1;
    for region_key in region_keys:
        if(int(region_addr_dict[region_key]["start_addr"],16) != last_end_addr + 1):
            temp = int(region_addr_dict[region_key]["start_addr"],16)-last_end_addr+1
            idx = 0
            while(temp >= 1024):
                temp = temp / 1024.0
                idx += 1
            cal_size = "%1.4f%s" % (temp,size_str_list[idx])
            ostr += sector_draw(last_end_addr+1,
                                int(region_addr_dict[region_key]["start_addr"],16)-1,
                                max_region_name_length,
                                "Reserved",
                                "",
                                "",
                                cal_size)

        ostr += sector_draw(int(region_addr_dict[region_key]["start_addr"],16),
                            int(region_addr_dict[region_key]["end_addr"],16),
                            max_region_name_length,
                            region_addr_dict[region_key]["region_description"],
                            region_addr_dict[region_key]["region_type"],
                            region_addr_dict[region_key]["index"],
                            region_addr_dict[region_key]["region_size"])
        last_end_addr = int(region_addr_dict[region_key]["end_addr"],16)
    return ostr
    
def region_reorder(region_list:list):
    region_addr_list = []
    region_addr_dict = {}
    region_keys = []
    for region in region_list:
        region_addr_dict[int(region["start_addr"],16)] = region
        region_keys.append(int(region["start_addr"],16))
    region_keys.sort()
    for keys in region_keys:
        region_addr_list.append(region_addr_dict[keys])
    return region_addr_list

def csv_to_json(infile:str,outfile:str):
    with open(infile,'r') as csv_file:
        sam_csv = csv.reader(csv_file)
        sam_json = {"region":[]}
        for row in sam_csv:
            sam_region_dict = {}
            print(row[1])
            if(row[1]):
                sam_region_dict["start_addr"] = row[3].lower()
                sam_region_dict["end_addr"] = row[5].lower()
                sam_region_dict["region_size"] = re.sub(r'\s',"",row[7])
                sam_region_dict["region_description"] = row[11][:80]
                sam_region_dict["region_type"] = "htg"
                sam_region_dict["region_target_type"] = row[8]
                sam_region_dict["region_secure_type"] = "2'b00" # CMN-700 not used,assign 2'b00 Trusted Device for all
                if(re.match("scg",row[1])):
                    sam_region_dict["region_type"] = "htg"
                elif(re.match("htg",row[1])):
                    sam_region_dict["region_type"] = "htg"
                elif(re.match("nh",row[1])):
                    sam_region_dict["region_type"] = "nhtg"
                sam_json["region"].append(sam_region_dict)
        

    with open(outfile,'w') as json_file:
        json.dump(sam_json,json_file)

def htg_reg(idx:int,region:dict,register_list:list):
        non_hash_en = "1'b1" if (region["region_type"] == "nhtg") else "1'b0"
        start_addr_trunc = region["start_addr"][:-4];
        if idx < 3: #SCG reg configure generate
            addr = 3584+idx*8 #base 'he00
            register_list.append(register("sys_cache_grp_region"+str(idx),"16'h"+f"{addr:x}","Secure"))
            register_list[-1].add_field(56,7,"region"+str(idx)+"_size",size_str_to_cfg[region["region_size"]])
            register_list[-1].add_field(16,36,"region"+str(idx)+"_base_addr",start_addr_trunc.replace("0x","'h"))
            register_list[-1].add_field(6,2,"region"+str(idx)+"_secure",region["region_secure_type"])
            register_list[-1].add_field(2,3,"region"+str(idx)+"_target_type",htg_target_type[region["region_target_type"]])
            register_list[-1].add_field(1,1,"region"+str(idx)+"_nonhash_reg_en",non_hash_en)
            register_list[-1].add_field(0,1,"region"+str(idx)+"_valid","1'b1")
        else:
            if(idx < 8):
                addr = 3584+idx*8
            else:
                addr = 12288+idx*8 #base 'h3000
            register_list.append(register("hashed_tgt_grp_cfg1_region"+str(idx),"16'h"+f"{addr:x}","Secure"))
            register_list[-1].add_field(56,7,"htg_region"+str(idx)+"_size",size_str_to_cfg[region["region_size"]])
            register_list[-1].add_field(16,36,"htg_region"+str(idx)+"_base_addr",start_addr_trunc.replace("0x","'h"))
            register_list[-1].add_field(6,2,"htg_region"+str(idx)+"_secure",region["region_secure_type"])
            register_list[-1].add_field(2,3,"htg_region"+str(idx)+"_target_type",htg_target_type[region["region_target_type"]])
            register_list[-1].add_field(1,1,"htg_region"+str(idx)+"_nonhash_reg_en",non_hash_en)
            register_list[-1].add_field(0,1,"htg_region"+str(idx)+"_valid","1'b1")

def nhtg_reg(idx:int,region:dict,register_list:list):
        if idx < 24: 
            addr = 3072+idx*8 #base 'hc00
        else:
            addr = 8192+idx*8 #base 'h2000
        start_addr_trunc = region["start_addr"][:-4];
        register_list.append(register("non_hash_mem_region_cfg1_reg"+str(idx),"16'h"+f"{addr:x}","Secure"))
        register_list[-1].add_field(56,7,"region"+str(idx)+"_size",size_str_to_cfg[region["region_size"]])
        register_list[-1].add_field(16,36,"region"+str(idx)+"_base_addr",start_addr_trunc.replace("0x","'h"))
        register_list[-1].add_field(6,2,"region"+str(idx)+"_secure",region["region_secure_type"])
        register_list[-1].add_field(2,3,"region"+str(idx)+"_target_type",htg_target_type[region["region_target_type"]])
        register_list[-1].add_field(1,1,"region"+str(idx)+"_nonhash_reg_en","1'b0")
        register_list[-1].add_field(0,1,"region"+str(idx)+"_valid","1'b1")

class field:
    def __init__(self,lsb,width,name,value):
        self.lsb = lsb
        self.width = width
        self.name = name
        self.value = value
    def get_csv_str(self):
            return field_conv(self.lsb,self.width)+","+self.name+","+self.value
    
class register:
    def __init__(self,name,addr,secure_type = "Secure",secure_type_ovwrreg = ''):
        self.name = name
        self.addr = addr
        self.secure_type = secure_type
        self.secure_type_ovwrreg = secure_type_ovwrreg
        self.fields = []
    
    def add_field(self , lsb:int, width:int, name:str, value):
        self.fields.append(field(lsb,width,name,value))

    def get_csv_str(self):
        csv_str = "%s,%s,%s" %(self.addr,self.name,self.secure_type)
        for idx,field in enumerate(self.fields):
            if(idx == 0):
                csv_str += ","+field.get_csv_str();
            else:
                csv_str += "\n,,,"+field.get_csv_str();
        return csv_str

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-f','--file',type=str,help='Specify input region cofiguration json file path')
    parser.add_argument('-n_h2nh','--no_htg2nhtg',action='store_false',help='Enable unused Hash Region Reg configure to Non-Hash Region')
    parser.add_argument('-n_d','--no_draw',action='store_false',help='draw region with ascii')
    # parser.add_argument('-rc','--rcomp',action='store_true',help='set RCOMP_EN=1')
    args = parser.parse_args()

    if(args.file):
        if (not os.access(args.file,os.R_OK)):
            sys.exit("Input file can't be read")

        file_name,extension = os.path.splitext(os.path.basename(args.file))
        path = os.path.dirname(os.path.realpath(args.file))
        i_f = path+"/"+file_name+extension
        o_f = path+"/"+file_name+".json"
        if(re.match(".csv",extension)):
            csv_to_json(i_f,o_f)
            with open(file_name+".json",'r') as json_file:
                region_dict = json.load(json_file)
        elif(re.match(".json",extension)):
            with open(args.file,'r') as json_file:
                region_dict = json.load(json_file)
        else:
            sys.exit("unrecoginzed file type!")
    else:
        csv_to_json("./sam_region_cfg.csv"
                    ,"./sam_region_cfg.json")
        with open("./sam_region_cfg.json",'r') as json_file:
            region_dict = json.load(json_file)

    for region in region_dict["region"] :
        resu = region_size_chk(region["start_addr"],region["end_addr"],region["region_size"])
        if not resu[0] :
            sys.exit(resu[1])
    region_list = region_reorder(region_dict["region"])

    (htg,nhtg) = region_num_chk(region_list,args.no_htg2nhtg)
    # htg[0] : htg_num htg[1]:region_list
    # recreate indexed region

    print("Total %d Hash Region and %d Non-Hash Region to be generated " % (htg[0],nhtg[0]))

    register_list = []
    for (idx,region) in enumerate(htg[1]):
        htg_reg(idx,region,register_list)

    for (idx,region) in enumerate(nhtg[1]):
        nhtg_reg(idx,region,register_list)

    with open('sam_region_register.csv','w') as f:
        for register in register_list:
            f.write(register.get_csv_str())
            f.write("\n")

    if(args.no_draw):
        region_indexed_dict = htg[1] + nhtg[1]
        with open('sam_region.txt','w') as f:
            f.write(region_draw(region_indexed_dict))
    print("GENERATE DONE")

            
            
