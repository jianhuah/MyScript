import os
import time
import pyautogui
from pathlib import Path
from PyPDF2 import PdfWriter
from PyPDF2 import PdfWriter

def get_files_from_folder(folder_path):
    folder_path = Path(folder_path)
    all_files = list(folder_path.rglob('*'))

    # Filter out directories, keeping only files
    all_files = [file for file in all_files if file.is_file()]

    return all_files

def is_pdf_file(file_path):
    _, file_extension = os.path.splitext(file_path)
    return file_extension.lower() == '.pdf'

# Specify the folder path
folder_path = r'C:\Users\MI\Desktop\JH\通信原理_西电 课件全（江同学整理）\第1章 绪论'#'path/to/your/folder'

# Get all files from the folder and its subfolders
all_files = get_files_from_folder(folder_path)

merger = PdfWriter()

# Print the list of files
for file in all_files:
    print(file)
    # Iterate through PDF files and import to OneNote
    #List of PDF file paths to import
    if is_pdf_file(file):
        pdf_file_path=file
        merger.append(pdf_file_path)

merger.write("merged_pdfs.pdf")
print("Batch merge completed.")
