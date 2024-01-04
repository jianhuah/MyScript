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


# Function to check if the specified file is *.pat type or not
def is_pat_file(file_path):
    _, file_extension = os.path.splitext(file_path)
    return file_extension.lower() == '.pat'



#main function to exeute
if __name__ == "__main__":
    # Specify the folder path
##    folder_path = r'C:\Users\\Desktop\99_Temp\'
    # Get the current working directory (current folder)
    folder_path = os.getcwd()

    # Get all files from the folder and its subfolders
    all_files = get_files_from_folder(folder_path)

    # List of PAT files to merge
    pat_files_list =[]
    # Print the list of files
    for file in all_files:
##        print(file)
        if is_pat_file(file):
            pat_files_list.append(file)
            #start reverse compile pat to atp
            result = subprocess.run(["aprc", file, "-force"], capture_output=True, text=True)
            print("Return code:", result.returncode)
            print("Output:", result.stdout)

    # Pause the script
    input("Press Enter to continue...")
### Example 1: Run a simple command
##result = subprocess.run(["aprc", "-help"], capture_output=True, text=True)
##print("Return code:", result.returncode)
##print("Output:", result.stdout)

