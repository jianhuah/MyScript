import subprocess
import os
from pathlib import Path

# Function to get all files from the specified folder path
def get_files_from_folder(folder_path):
    '''
    Get all files from the specified folder path, include files in the sub-folders.

    Args:
        folder_path (str): The input folder path.

    Returns:
        string list: All files in the input folder path.
    '''
    folder_path = Path(folder_path)
    all_files = list(folder_path.rglob('*'))

    # Filter out directories, keeping only files
    all_files = [file for file in all_files if file.is_file()]

    return all_files


# Function to check if the specified file is *.atp type or not
def is_atp_file(file_path):
    _, file_extension = os.path.splitext(file_path)
    return file_extension.lower() == '.atp'



#main function to exeute
if __name__ == "__main__":
    # Specify the folder path
##    folder_path = r'C:\Users\\Desktop\99_Temp\'
    # Get the current working directory (current folder)
    folder_path = os.getcwd()

    # Get all files from the folder and its subfolders
    all_files = get_files_from_folder(folder_path)

    # List of PAT files to merge
    atp_files_list =[]
    pm = 'Pin Map.txt'
    #print(pm)
    ##switches='" -pinmap_sheet "‘ +pinmap_workbook+'" -digital_inst HSDMQ -opcode_mode single"‘
    ##cmdstr='apc “ ‘ +f+ ‘ " -pinmap_workbook “ ‘ +wkbk+ ‘ " -pinmap_sheet “ ‘ +pm+ ‘ " -digital_inst HSDM -opcode_mode single -comments -logfile "apc_atp2Pat.log“ ‘
    # Print the list of files
    for file in all_files:
##        print(file)
        if is_atp_file(file):
            atp_files_list.append(file)
    #get counts of atp files
    total_files_to_compile=len(atp_files_list)
    i=0
    for file in atp_files_list:
        i+=1
        print("Pattern compile progressing:",i,"/",total_files_to_compile)
        #start reverse compile pat to atp
        #switches=str(file)+switches
        #print (switches)
        cmd_line='apc "'+str(file)+ '" -pinmap_workbook "'+pm+'" -digital_inst HSDMQ -opcode_mode single'
        ##print (cmd_line)
        result = subprocess.run(cmd_line, shell=True)
        #result.wait()
        print("    Pattern compile done:", file)

    # Pause the script
    input("Press Enter to continue...")

