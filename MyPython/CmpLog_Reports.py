# -*- coding: utf-8 -*-
'''
Created on 2020-2-12

@author: Jesse

Version:
0.0    2020/2/14    first version for debug purpose, can achieve report generation with 3 sheets: Reference; Compare; Report

 
'''
import os
# import sys
# import csv
import xlwt
import xlrd
import xlutils
from xlutils.copy import copy
import time

# Date:    2020/2/13
# Author:    Jesse
def read_csv_gather_data(file_name):
    '''open the target file, and read out the necessary data
    input: file_name -target file to to open for readout
    output: parameter_data -all of the necessary data from the input file
            gather data are:
            basic info: ['Date','ProgramName','ProgramRevision','Wafer','TesterType','ExecRevision']
            real data:  ['Parameter','Tests#','Patterns','Unit','HighL','LowL']
    '''
    parameter_data = {}
    parameter_data_key=['Date','ProgramName','ProgramRevision','Wafer','TesterType','ExecRevision', 'Parameter','Tests#','Patterns','Unit','HighL','LowL']
    with open(file_name, "r") as f:
        row_num = 1
        for line in f:
            for val in parameter_data_key:
                data = line_content_split(val, line)#do not split line str val
                if data is not None:
                    parameter_data[val]=data
                    continue                 
            if line.startswith('LowL,'):
                break
#             print(line)
            row_num +=1
            # in case out of search
            if row_num > 200:
                break
    return  parameter_data
       
def line_content_split(key, str_line):
    if str_line.startswith(key + ','):
        return str_line.strip()

def write_csv_raw_data_temp(raw_data_reference, raw_data_compare):
#     workbook_name ='./Report.xls'
    writebook = xlwt.Workbook(workbook_name)
    global_info_key=['Date','ProgramName','ProgramRevision','Wafer','TesterType','ExecRevision']
    parameter_data_key=['Parameter','Tests#','Patterns','Unit','HighL','LowL']
    sheet = writebook.add_sheet(g_sheet_reference, cell_overwrite_ok=True)#allow overwrite
    write_sheet(sheet, global_info_key, parameter_data_key, raw_data_reference)
    sheet = writebook.add_sheet(g_sheet_compare, cell_overwrite_ok=True)#allow overwrite
    write_sheet(sheet, global_info_key, parameter_data_key, raw_data_compare)
    writebook.save(workbook_name)

def write_sheet(sheet, global_info_key, parameter_data_key, raw_data):
    row =0
    for key_val in global_info_key:
        list_info_data=raw_data[key_val].split(',')
        column=0
        for val in list_info_data:
            sheet.write(row,column,val)
            column += 1
        row += 1
        
    para_row = row
    para_column = 0    
    for key_val in parameter_data_key:
        para_row = row
        list_parameter_data=raw_data[key_val].split(',')
        for val in list_parameter_data:
            sheet.write(para_row,para_column,val)
            if key_val == 'Parameter':
                # WRITE ADDITIONAL INFO
                #in case val is 'Parameter', write the title of Tname/Pin/Channel
                if para_row==6: #val.strip()=='Parameter':
                    sheet.write(para_row, g_col_tname, 'Tname')#write Tname
                    sheet.write(para_row, g_col_pin, 'Pin')#write Pin
                    sheet.write(para_row, g_col_channel, 'Channel')#write channel
#                     sheet.write(para_row, g_col_comments, 'Comments')#write channel
                elif para_row > 6:              
                    #in case val include more than 2 spaces, need split to get:
                    #Tname, Pin, channel 
                    #example: val='O_VSS CAN_A_RX 65'
                    test_info = val.strip().split(' ')
                    count = test_info.__len__()
                    if count == 1:
                        sheet.write(para_row, g_col_tname, test_info[0])# only write Tname
                    elif count == 2:
                        sheet.write(para_row, g_col_tname, test_info[0])#write Tname
                        sheet.write(para_row, g_col_pin, test_info[1])#write Pin                
                    else:
                        sheet.write(para_row, g_col_tname, test_info[0])#write Tname
                        sheet.write(para_row, g_col_pin, test_info[1])#write Pin
                        sheet.write(para_row, g_col_channel, test_info[2])#write channel
            para_row += 1
        para_column += 1  

#save data in global usage        
def read_fetched_data(file_name):
    global g_title_info_reference
    global g_title_info_compare
    global g_dic_tests_reference
    global g_dic_tests_compare
    workbook = xlrd.open_workbook(file_name)
    #read reference sheet to dict
    sheet = workbook.sheet_by_name(g_sheet_reference)
    rows = sheet.nrows
    g_dic_tests_reference, g_title_info_reference=read_sheet_to_dict(sheet, rows)
    #read compare sheet to dict
    sheet = workbook.sheet_by_name(g_sheet_compare)
    rows = sheet.nrows
    g_dic_tests_compare, g_title_info_compare=read_sheet_to_dict(sheet, rows)    
# # 0            1         2           3       4        5       6        7      8          9
# # Parameter    Tests#    Patterns    Unit    HighL    LowL    Tname    Pin    Channel    Comments

def read_sheet_to_dict(sheet, rows):
    dic_tests={}
    dic_title_info={}
    for this_row in range(0,6):
        row_val=sheet.row_values(this_row)
        dic_title_info[row_val[0]]=row_val[1]
    for this_row in range(16, rows):#start tests on row 16
        row_val = sheet.row_values(this_row)
# 0            1         2           3       4        5       6        7      8          9
# Parameter    Tests#    Patterns    Unit    HighL    LowL    Tname    Pin    Channel    Comments
        if row_val.__len__() == 9:#a valid test
            #save to dict, key is Tests#; value is other parameters till Pin(7)
            dict_val=''
            for i in range(2,8):
                val=str(row_val[i])
                val = val[:-4] if val.upper().endswith('.PAT') else val#delet postfix '.PAT'
                dict_val += (val + ',')
            dic_tests[int(row_val[1])] = dict_val#convert key to number not string
    return dic_tests, dic_title_info   

def perform_alignment(list_all_keys):
# 0            1         2           3       4        5       6        7      8          9
# Parameter    Tests#    Patterns    Unit    HighL    LowL    Tname    Pin    Channel    Comments

# 0.    Perfect match, no misalignment.
# 1.    Test# missing, not found in the other file. 
# 2.    Pattern mismatch
# 3.    Unit mismatch
# 4.    HighLimit mismatch
# 5.    LowLimit mismatch
# 6.    Tname mismatch
# 7.    Pin mismatch
    dict_result={}
    comments = ['Perfect matched. ',
                'Test# missing. ',
                'Pattern mismatch. ',
                'Unit mismatch. ',
                'HighLimit mismatch. ',
                'LowLimit mismatch. ',
                'Tname mismatch. ',
                'Pin mismatch. ']
    for key in list_all_keys:
        result =[]
        val_compare = g_dic_tests_compare.get(key)
        val_reference = g_dic_tests_reference.get(key)
        if val_compare is None or val_reference is None:
            result.append(comments[1])#'Test# missing, not found in the other file. '
        elif val_compare == val_reference:
            result.append(comments[0])#'Perfect match, no misalignment. '
        else:
            parameters_compare = val_compare.split(',')
            parameters_reference = val_reference.split(',')
            for i in range(6):#parameters_reference.__len__()
                if parameters_compare[i] != parameters_reference[i]:
                    result.append(comments[i+2])#align comments and parameter
        dict_result[key]=result
    return dict_result

    
def wirte_results_to_report(dict_result, sheet):
    red_style = xlwt.easyxf('pattern: pattern solid, fore_colour red')
    yellow_style = xlwt.easyxf('pattern: pattern solid, fore_colour yellow')
    green_style = xlwt.easyxf('pattern: pattern solid, fore_colour light_green')

    data = xlrd.open_workbook(workbook_name)
    ws = xlutils.copy.copy(data) #copy original data
    table=ws.get_sheet(sheet)      
    row = 16# start row is 16
    for key_val in dict_result:
        str_result=''
        for statements in dict_result[key_val]:
            str_result += statements
        if str_result.find('Perfect match') != -1:
            style=green_style
        elif str_result.find('missing') != -1:
            style=red_style
        elif str_result.find('mismatch') != -1:
            style=yellow_style            
        table.write(row, g_col_comments, str_result, style) # add data to column 'comments'
        row +=1#to next row
    ws.save(workbook_name)  #save old and added data


def write_report_sheet(sheet_name):
    data = xlrd.open_workbook(workbook_name)
    ws = xlutils.copy.copy(data) #copy original data
    sheet=ws.add_sheet(sheet_name, cell_overwrite_ok=True)
#     sheet = writebook.add_sheet(sheet_name)

    list_all_keys = list(set(g_dic_tests_reference.keys()).union(g_dic_tests_compare.keys()))
    list_all_keys.sort()#sort all of the keys

    dict_result = perform_alignment(list_all_keys)
    
    red_style = xlwt.easyxf('pattern: pattern solid, fore_colour red')
    yellow_style = xlwt.easyxf('pattern: pattern solid, fore_colour yellow')
    green_style = xlwt.easyxf('pattern: pattern solid, fore_colour light_green')
    
    row=0
    column=0
    #write global info.
    for key_val in g_title_info_reference:
        sheet.write(row, column, key_val)
        sheet.write(row, column+1, g_title_info_reference[key_val])
        sheet.write(row, column+7, key_val)
        sheet.write(row, column+8, g_title_info_compare[key_val])        
        row +=1
    #write title
    title=['Tests#','Patterns','Unit','HighL','LowL','Tname','Pin']
    column=0
    for val in title:
        sheet.write(row, column, val)
        sheet.write(row, column+7, val)
        column+=1
    sheet.write(row, column+7, 'Comments')
    row +=1       
    #frozen in specified row
    sheet.set_panes_frozen(True)
    sheet.set_horz_split_pos(row)
    #     row = 16# start row is 16
    column = 0
    #write data
    for key_val in list_all_keys:
        column = 0
        # write reference data
        if g_dic_tests_reference.get(key_val) is None:
            sheet.write(row, column, '')
            column +=7
        else:
            my_str=str(key_val)+','+g_dic_tests_reference[key_val]
            write_data=my_str.split(',')
#             write_data=write_data.replace(',','\t').strip()
            for val in write_data[:-1]:#the last element is empty must remove due to addtional ',' in g_dic_tests_compare[key_val]
                sheet.write(row, column, val)
                column +=1
        
        # write compare data
        if g_dic_tests_compare.get(key_val) is None:
            sheet.write(row, column, '')
            column +=7
        else:
            my_str=str(key_val)+','+g_dic_tests_compare[key_val]
            write_data=my_str.split(',')
            for val in write_data[:-1]:#the last element is empty must remove due to addtional ',' in g_dic_tests_compare[key_val]
                sheet.write(row, column, val)
                column +=1
        
        # write result to column 'comments'
        str_result=''
        if dict_result.get(key_val) is not None:   
            for statements in dict_result[key_val]:
                str_result += statements
            if str_result.find('Perfect matched') != -1:
                style=green_style
            elif str_result.find('missing') != -1:
                style=red_style
            elif str_result.find('mismatch') != -1:
                style=yellow_style            
            sheet.write(row, column, str_result, style)        
        row +=1#to next row   
    ws.save(workbook_name)


#######################################################################
''' main function
'''        
#define constant value for setup
file_path = r"C:\jianhua\Datalog_compare_process"
workbook_name ='Datalog_Compare_Report'#report file name
#sheet name for save data
g_sheet_reference='Reference'
g_sheet_compare='Compare'
g_sheet_report ='Report'

#title info in excel column position
g_col_tname=6
g_col_pin=7
g_col_channel=8
g_col_comments=9

#define report sheet title and data in dictionary
g_title_info_reference = {}
g_title_info_compare = {}

g_dic_tests_reference={}
g_dic_tests_compare={}

#creat report to a target path with added date-time
time_now = time.strftime("%Y_%m_%d_%H_%M")
workbook_name+=('_'+time_now+'.xls')
workbook_name = os.path.join(file_path, workbook_name)

#########    Step 1    ###################################
#open read csv file, and fetch the necessary data as Reference
csv_name="rva98baa_01_q822449a_17_va98ea101baq01_p_ews1_tj75060_20190908092525.std.gextb.csv"
file_name = os.path.join(file_path, csv_name)
print('Open to read:', file_name)
reference_raw_data = read_csv_gather_data(file_name)

#open read csv file, and fetch the necessary data as Compare
csv_name="rva98baq_q822449a1_17_va98ea106baq01_e_ews1_tuflex05_20191129101535.std.gextb.csv"
file_name = os.path.join(file_path, csv_name)
print('Open to read:', file_name)
compare_raw_data = read_csv_gather_data(file_name) 

#########    Step 2    ###################################
#write the raw data(both Reference and Compare) to temp workbook
print('write_csv_raw_data_temp...')
write_csv_raw_data_temp(reference_raw_data,compare_raw_data)
print('write_csv_raw_data_temp. Done!')
#########    Step 3    ###################################
#read tests from temp workbook, and store to dictionary as GLOBAL
print('read tests from temp workbook...')
read_fetched_data(workbook_name)
print('read tests from temp workbook. Done!')

#########    Step 4    ###################################
#perform datalog compare check, and write compare results to report file
print('start write report to workbook...')
write_report_sheet(g_sheet_report)
print('start write report to workbook. Done!')
print('Report done!', workbook_name)

