import win32com.client
import os
import time

def import_pdf_to_onenote(pdf_path):
    # Create OneNote application object
    onenote = win32com.client.Dispatch("OneNote.Application")

##    # Get the IApplication interface
##    onenote_app = onenote.GetHierarchy("", win32com.client.constants.hsNotebook, "")
##
##    # Get the current notebook
##    notebooks = onenote_app.GetNotebooks()
##    notebook = notebooks.GetItemAt(1)  # Assuming the first notebook; adjust as needed
##
##    # Specify the section to insert the file
##    sections = notebook.GetSections()
##    section = sections.GetItemAt(1)  # Assuming the first section; adjust as needed
####    # Open a notebook
####    notebook_path = r'C:\Users\huangjes\Desktop\99_Temp\通信原理_西电 课件全（江同学整理）\Communication\New Section 1.one'#"C:\path\to\your\notebook.one"
####    onenote.OpenHierarchy(notebook_path)
####
####    # Find the active section
####    section = onenote.Windows.CurrentWindow.CurrentSection

    # Wait for OneNote to open
    onenote.WaitUntilDone(3000)

    # Get the current active window
    current_window = onenote.Windows.CurrentWindow

    # Get the current section of the active window
    section = current_window.CurrentSection
    
    # Specify the page title
    page_title = "Imported PDF Page"

    # Create a new page
    page = section.NewPage(page_title)

    # Get the content object of the page
    page_content = page.PageObjects

    # Insert the file printout
    file_printout = page_content.AddNew(win32com.client.constants.otFile, "", True)
    file_printout.File = pdf_path
    file_printout.InsertFileAsPrintout(pdf_path, "", "")

    # Save and sync changes
    onenote.Save(True)
    ###onenote_app.SyncAllObjects(win32com.client.constants.hsNotebook)
    
if __name__ == "__main__":
    # Specify the path to your PDF file
    pdf_file_path = r'C:\Users\huangjes\Desktop\99_Temp\通信原理_西电 课件全（江同学整理）\第1章 绪论\1.4_1.5 信息度量、性能指标.pdf'

    # Check if the PDF file exists
    if os.path.exists(pdf_file_path):
        # Import the PDF file to OneNote
        import_pdf_to_onenote(pdf_file_path)
        print(f"PDF file '{pdf_file_path}' imported to OneNote.")
    else:
        print(f"Error: PDF file '{pdf_file_path}' not found.")
