'''
Created on Oct 4, 2018

@author: huangjes

huangjes 10/4/2018:
initial version: Convert J750 atp file to ultraFlex atp, and compile to ultraFLEX .pat as specified PinMap file.
'''
import os
import sys
import re

import tkinter as tk
from tkinter import filedialog
from builtins import int
print('test')

 ###########################################################################
 #list all the files in rootdir, include the subFolders
def list_all_file(rootdir, file_type='*'):
    import os
    myfiles = []
    list = os.listdir(rootdir)
    for i in range (0,len(list)):
        path = os.path.join(rootdir,list[i])
        if os.path.isdir(path):
            myfiles.extend(list_all_file(path,file_type))
        if os.path.isfile(path):
            if file_type == '*':
                myfiles.append(path)
            elif os.path.splitext(path)[1].lower() == file_type.lower():
                myfiles.append(path)
            else: pass
    return myfiles
##########################################################################
####Compile ultra atp to pat
def UltraFlexPatternCompiler(input_file,ultraflex_pinmap,is_scan_pat=False):
    pinmap="-pinmap_workbook "
    digital_inst="-digital_inst "
    opcode_mode="-opcode_mode "
    scan_type="-scan_type "
    save_comments="-comments "
    
    pinmap=pinmap + ultraflex_pinmap + " " #specified the pinmap file
    digital_inst=digital_inst + "HSDMQ " #specified the digital instrument
    opcode_mode=opcode_mode +"single " #specififed the timing mode
    if is_scan_pat: scan_type=scan_type+"x4 " #specified the scan type in 2x for scan pattern
    switches=pinmap+digital_inst+opcode_mode
    switches=switches+scan_type+save_comments if(is_scan_pat) else switches+save_comments
    my_command="apc "+input_file +" " +switches
    #system("apc -stdin -output bar.pat")
    os.system(my_command)#invoke the pattern compiler by command-line interface: apc input-ascii-file(s) [switches]
    return None
##########################################################################
###couting vector line numbers to determine ultraFLEX use VM or SRM
def  getVectorNum(atp_file):
    vector_counts = 0
    with open(atp_file) as READVECTOR:
        for line in READVECTOR.readlines():
            line = line.strip()#remove space and '\n'
            if line.find('>') != -1: vector_counts  = vector_counts+1
    return vector_counts
##########################################################################
###########################################################################
#process j750 opcode
def repleace_j750_opcode(originStr):
    m=re.match(r'(?P<label>.*:)?(?P<opcode>.*)?>.*',originStr)
    if m != None:
        j750_label = m.group('label').strip() if m.group('label') != None else ''
        j750_opcode = m.group('opcode').strip() if m.group('opcode') != None else ''
    m=re.match(r'(?P<new_opcode>m?repeat) \d+', j750_opcode)
    only_opcode = j750_opcode if m == None else m.group('new_opcode')                   
    #process and convert J750 opcode to the UltraFlex opcode        
    if j750_opcode.find('mrepeat') != -1: #mrepeat -> repeat
        originStr=originStr.replace('mrepeat', 'repeat')
    elif j750_opcode.find('end_module') != -1:#end_module -> halt
        originStr=originStr.replace('end_module', 'halt')
    elif j750_opcode.find('ign') != -1:#ign -> mask
        originStr=originStr.replace('ign', 'mask')
    elif j750_opcode.find('clr_fail') != -1:#clr_fail move to comments
        originStr=originStr.replace('clr_fail', '')
        originStr=originStr+"//J750 has clr_fail"
    elif j750_opcode.find('set_code') != -1:#set_code change to comments
        originStr=re.sub(r'set_code\s*\d+', '', originStr)
    elif j750_opcode.find('clr_code') != -1:#clr_code change to comments
        originStr=originStr.replace('clr_code','')
    elif j750_opcode.find('flag') != -1:#flag -> branch_expr
        originStr=re.sub(r'flag', 'branch_expr', originStr)
    elif j750_opcode.find('clr_flag (cpuA)') != -1:
        originStr=originStr.replace('clr_flag', 'clr_cond_flags')
        originStr=originStr.replace('cpuA', 'cpuA_cond')
    elif j750_opcode.find('clr_flag (fail)') != -1:
        originStr=originStr.replace('clr_flag', 'clr_cond_flags')               
    elif j750_opcode.find('exit_loop') != -1:
        originStr=originStr.replace('exit_loop', 'clr_loop')
    elif j750_opcode.find('push') != -1:
        originStr=originStr.replace('push', 'push_subr')
    elif j750_opcode.find('call_glo') != -1:
        originStr=originStr.replace('call_glo', 'call globalAddr')
    elif j750_opcode.find('enable') != -1:#enable -> branch_expr
        originStr=originStr.replace('enable', 'branch_expr=')
        originStr=originStr.replace('cpuA', 'cpuA_cond')
        originStr=originStr.replace('cpuB', 'cpuB_cond')
        originStr=originStr.replace('cpuC', 'cpuC_cond')
        originStr=originStr.replace('cpuD', 'cpuD_cond')
    #======process cpuFlag, remove the J750 cpu opcode to comments
    elif j750_opcode.find('cpu') != -1:
        #WRITE.write('//    TER2018: below vector has opcode: ' + j750_opcode + '\n' )
        originStr=originStr.replace(j750_opcode, '')#remove the opcode command
        originStr='//    TER2018: below vector has opcode: ' + j750_opcode + '\n' +originStr
    return originStr, only_opcode
###########################################################################
#.atp compile from J750 to ultraFlex
def find_and_convert_opcode(j750_atp_file, ultra_atp_file, file_opcode_list, file_opcode_in_pattern):
    #ultra_atp_file=os.path.join(ultra_atp_file,os.path.split(j750_atp_file)[1])#create ultraFLEX file and path
    j750_atp_vector_linenum=-1
    j750_atp_vector_linenum = getVectorNum(j750_atp_file)
    print('Please wait...', j750_atp_file)
    
    originStr=""
    linenumber=0#counting .atp file line number
    is_scan_pat= False #check the pattern include scan or not
    flag_header_commets=-1 #indicate the pattern_header_commets
    pattern_header_commets=[]#save j750 atp header comments
    j750_opcode_list = []#save j750 opcode
    
    with open(j750_atp_file,'r') as READ, open(ultra_atp_file,'w') as WRITE, open(file_opcode_list,'a') as WRITE_opcode,open(file_opcode_in_pattern,'a') as WRITE_opcode_location:
        WRITE_opcode_location.write('--------------'+j750_atp_file+'--------------\n')
        #for originStr in READ.readlines():
        while True:
            originStr=READ.readline()
            if not originStr: break
            orginal_j750=originStr
            originStr=originStr.strip()
            linenumber=linenumber+1
            if originStr=='': continue#skip empty line
            
            #process the pattern_header_commets, move the header comments in to vector module
            if flag_header_commets==-1 and originStr.startswith(r'//'):
                pattern_header_commets.append(originStr)
                continue
            flag_header_commets = 1#clear flag
            
            #check pattern contain scan or not scan_pins = {
            if re.match('scan_pins =', originStr): is_scan_pat=True
            
            #1)check the line is comment or not, if comments just go to write original context directly
            if originStr.startswith(r'//') or originStr.startswith(r'/*'): 
                WRITE.write(originStr)
                continue 
            #not comments, do the below process
            
            #2)check the pattern has scan or not
            m=re.match(r'(?P<scan_pin_name>\w*):\d,', originStr)
            if m != None and m.group('scan_pin_name') != '':#scan pin setup
                WRITE.write(m.group('scan_pin_name') + ',\n')
                continue
            
            #3)process the vector module header
            m=re.match(r'vector\s*\(\s*\$tset\s*,(?P<pinlist>.*)\)' , originStr)
            if m != None and m.group('pinlist') != '':
                if j750_atp_vector_linenum > 64:
                    WRITE.write('vm_vector \n')
                else:
                    WRITE.write('srm_vector \n')
                WRITE.write('($tset, ' + m.group('pinlist') + ')\n')
                continue
            
            #vector context start, the pattern_header_commets will be write
            if originStr == '{':
                WRITE.write('{\n')
                for i in range(0,len(pattern_header_commets)):
                    WRITE.write(pattern_header_commets[i]+'\n')
                continue
            
            #4)process global subr label, #global subr -> global
            
            #4)check if it's not valid vector, or no label/opcode in the vector line, or scan setup with starting (
            #valid vector has symbol ">" 
            if originStr.find('>') == -1 or originStr.startswith('>')  or originStr.startswith('('): 
                WRITE.write(originStr+'\n')
                continue                
            
            #5)check pattern Label and Opcode
            (originStr,j750_opcode)=repleace_j750_opcode(originStr)
            #===========save opcode
            if j750_opcode != '':
                if j750_opcode not in j750_opcode_list:
                    j750_opcode_list.append(j750_opcode)
                    WRITE_opcode_location.write(str(linenumber) + ':\t')
                    WRITE_opcode_location.write(orginal_j750)
                    WRITE_opcode.write(j750_opcode + '\n')               
            #loop or set_loop... #expand the loop command
            if j750_opcode.find('loop') != -1:
                m=re.match('loop\w\s+(?P<loop_count>\d+)', j750_opcode)
                if m != None and m.group('loop_count') != '':
                    loop_count = int(m.group('loop_count'))
                    loopcontent = []
                    WRITE.write('// TER: Here loop start by loop_count:'+ str(loop_count) + '\n')
                    originStr=originStr.replace(j750_opcode,'')#remove opcode
                    current_read_line=originStr.strip()
                    loopcontent.append(current_read_line)
                    while current_read_line.find('end_loop') == -1:
                        current_read_line=READ.readline().strip()
                        linenumber=linenumber+1
                        (current_read_line,dummy_opcode)=repleace_j750_opcode(current_read_line)
                        loopcontent.append(current_read_line)
                    loopcontent[-1]=loopcontent[-1].replace(dummy_opcode,'')#remove end_loop opcode
                ##expand the loop command
                    for loopcnt in range(0,loop_count):
                        for i in range(0,len(loopcontent)):
                            if (loopcnt== loop_count-1 and i==len(loopcontent)-1): WRITE.write('// TER: Here loop end by loop_count'+str(loop_count)+'\n')
                            WRITE.write(loopcontent[i]+'\n')
                    continue
            WRITE.write(originStr + '\n')                                        
    return is_scan_pat                          
############################################################################################       
#############---------MAIN FUNCTION
root = tk.Tk()
root.withdraw()

while True: #will break when selected path is not empty
    print('Please select the target J750 pattern folder...')
    base_path=filedialog.askdirectory()
    print('The selected folder is: ' +base_path)
    print('Please select the target ultraFLEX pinMap file...')
    ultraflex_pinmap=filedialog.askopenfilename()
    print('The selected folder is: ' +ultraflex_pinmap)
    j750_all_files = list_all_file(base_path,'.atp')#list all the .atp files under the path
    if len(j750_all_files) !=0 : break 
    print('Specified path is empty, please select a new path: ', base_path)
    os.system('pause')
 
##create target ultraFLEX folder to save new pattern file    
output_folder_path = os.path.join(os.path.split(base_path)[0],'ultraFLEX')
#check if output folder exist, if not then create the folder
if not os.path.exists(output_folder_path): os.makedirs(output_folder_path)

is_scan_pat=False #check the pattern include scan or not
#use for save opcode and opcode located in pattern
file_opcode_list=os.path.join(output_folder_path,"_opcode_list.txt")
file_opcode_in_pattern=os.path.join(output_folder_path,"_opcode_in_pattern.txt")
if os.path.exists(file_opcode_list): os.remove(file_opcode_list)
if os.path.exists(file_opcode_in_pattern): os.remove(file_opcode_in_pattern)

#start convert j750 atp to ultraflex atp
for i in range(0, len(j750_all_files)):
    j750_atp_file=j750_all_files[i]
    ultra_atp_file=os.path.join(output_folder_path,os.path.split(j750_atp_file)[1])#create ultraFLEX file and path
    is_scan_pat=find_and_convert_opcode(j750_atp_file,ultra_atp_file,file_opcode_list,file_opcode_in_pattern)
    UltraFlexPatternCompiler(ultra_atp_file, ultraflex_pinmap,is_scan_pat)
print('DONE!')
