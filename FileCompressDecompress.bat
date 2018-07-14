@title File Compress and .gz Decompress...
@echo off
echo Please only type in 0 or 1:
echo 0 means Comp   -^> Compress file to .gz
echo 1 means Decomp -^> Decompress .gz file
set /p ComDecom=
if %ComDecom% equ 0   (echo You have selected Comp   -^> Compress file to .gz & goto runComp)    else (echo>nul)
if %ComDecom% equ 1   (echo You have selected Decomp -^> Decompress .gz file  & goto runDecomp)  else (echo>nul)
echo %ComDecom% is neither to Compress nor Decompress, will exit and not run anymore. 
pause>nul
exit

:: run to compress file
:runComp
echo Please type in the file type you want compress and confirm by click ENTER...
echo (for example the .txt file, type the extension .txt)
:: type in the file extension in screen
set /p extension=
echo The file type you want compress is: %extension%
pause
echo start compress the traget file with specified extension file %extension%...
for %%f in (*%extension%) do echo processing %%f & gzip %%f 
echo compress done!
pause
exit

:: run to decompress file
:runDecomp
echo start decompress the .gz file...
for %%f in (*.gz) do echo processing %%f & gzip %%f -d
echo decompress done!
pause
exit
