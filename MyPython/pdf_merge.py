import os
import PyPDF2
##import pyautogui
from pathlib import Path
from PyPDF2 import PdfMerger
from PyPDF2 import PdfWriter
from PyPDF2 import PdfReader, PdfWriter

def get_files_from_folder(folder_path):
    folder_path = Path(folder_path)
    all_files = list(folder_path.rglob('*'))

    # Filter out directories, keeping only files
    all_files = [file for file in all_files if file.is_file()]

    return all_files

def is_pdf_file(file_path):
    _, file_extension = os.path.splitext(file_path)
    return file_extension.lower() == '.pdf'

def merge_pdfs_with_bookmarks(pdf_files, output_pdf):
##    pdf_merger = PdfMerger()
    pdf_merger = PdfWriter()
    for index, pdf_file in enumerate(pdf_files):
##        pdf_merger.append(pdf_file, bookmark=f'Bookmark {index + 1}')
        print(pdf_file)

        pdf_reader = PdfReader(pdf_file)
##        # Add bookmark for each PDF file
##        outline_item = pdf_merger.add_outline_item(f'Bookmark {index + 1}', index)
##        outline_item.append(pdf_merger.getPageDestination(index))
          # Add bookmark for each PDF file
##        print(index)

        # Get the file name without the path
        file_name_only = os.path.basename(pdf_file)
        #destination_name = f'bookmark_{index + 1}_Start'
        destination_name = f'{file_name_only}'
##        print(destination_name)
##        print(len(pdf_merger.pages))
        pdf_merger.add_outline_item(destination_name, len(pdf_merger.pages))
        
##        pdf_merger.add_page(pdf_reader.getPage(0))
##        print(range(len(pdf_reader.pages)))
        # Loop through all pages in the current PDF file
        # Remove the last page due to no meanful content
        for page_num in range(len(pdf_reader.pages)-1):
            pdf_merger.add_page(pdf_reader.pages[page_num])
        
        with open(output_pdf, 'wb') as output:
            pdf_merger.write(output)

#main function to exeute
if __name__ == "__main__":
    # Specify the folder path
##    folder_path = r'C:\Users\\Desktop\99_Temp\'
    # Get the current working directory (current folder)
    folder_path = os.getcwd()

    # Get all files from the folder and its subfolders
    all_files = get_files_from_folder(folder_path)

    # List of PDF files to merge
    pdf_files_to_merge =[]## ['file1.pdf', 'file2.pdf', 'file3.pdf']
    # Print the list of files
    for file in all_files:
##        print(file)
        ## List of PDF files to merge
        if is_pdf_file(file):
            pdf_files_to_merge.append(file)
        
    # Output PDF file with bookmarks
##    output_pdf_file = 'merged_output.pdf'
    output_pdf_file = os.path.basename(folder_path)
    output_pdf_file = output_pdf_file + '.pdf'

    merge_pdfs_with_bookmarks(pdf_files_to_merge, output_pdf_file)

    print(f'Merged PDF with bookmarks saved to: {output_pdf_file}')

    # Pause the script
    input("Press Enter to continue...")
