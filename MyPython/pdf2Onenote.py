import os
import time
import pyautogui
from pathlib import Path

def get_files_from_folder(folder_path):
    folder_path = Path(folder_path)
    all_files = list(folder_path.rglob('*'))

    # Filter out directories, keeping only files
    all_files = [file for file in all_files if file.is_file()]

    return all_files

def is_pdf_file(file_path):
    _, file_extension = os.path.splitext(file_path)
    return file_extension.lower() == '.pdf'

# Function to open OneNote, create a new page, and paste PDF content
def import_pdf_to_onenote(pdf_path):
    # Open OneNote (modify the path based on your system)
    pyautogui.hotkey('win', 's')
    time.sleep(1)  # Wait for the search bar to appear
    pyautogui.write('OneNote', interval=0.1)
    pyautogui.press('enter')
    time.sleep(3)  # Wait for OneNote to open

    # Create a new page
    pyautogui.hotkey('ctrl', 'n')
    time.sleep(1)  # Wait for the new page to be created

    # Paste content from PDF
    pyautogui.hotkey('ctrl', 'v')

### List of PDF file paths to import
##pdf_files = ['path/to/your/file1.pdf', 'path/to/your/file2.pdf', 'path/to/your/file3.pdf']

# Specify the folder path
folder_path = r'C:\Users\huangjes\Desktop\99_Temp\通信原理_西电 课件全（江同学整理）\第1章 绪论'#'path/to/your/folder'

# Get all files from the folder and its subfolders
all_files = get_files_from_folder(folder_path)

# Print the list of files
for file in all_files:
    print(file)
    # Iterate through PDF files and import to OneNote
    #List of PDF file paths to import
    if is_pdf_file(file):
        pdf_file_path=file
##    
### Iterate through PDF files and import to OneNote
##for pdf_file_path in pdf_files:
        import_pdf_to_onenote(pdf_file_path)
        time.sleep(5)  # Add a delay between imports to account for processing time

print("Batch import completed.")
