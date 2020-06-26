@echo off

rem get file name
for %%I in (.) do set FileName=%%~nxI

rem get extension
pushd ..
for %%I in (.) do set DirName=%%~nxI
if %DirName%==extensions (set FileExt=ext)
if %DirName%==modules (set FileExt=mod)
echo %FileExt%
popd

set FileName=%FileName%.%FileExt%
echo %FileName%

del source.zip
"D:\Program Files\7-Zip\7z.exe" a source.zip .\source\*
del %FileName%
ren source.zip %FileName%
