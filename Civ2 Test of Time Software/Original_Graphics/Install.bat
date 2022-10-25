@echo off
cls
echo    ToT Original Game Graphics Modpack
echo.
echo 1. Install
echo 2. Uninstall
echo 3. Cancel
echo.

if "%OS%"=="Windows_NT" goto winNT

choice /c:123 Enter your selection:
if errorlevel 3 goto done
if errorlevel 2 goto uninst
if errorlevel 1 goto inst

:winNT
set /P choice=Type 1, 2 or 3 and hit Enter: 
if %choice%==1 goto inst
if %choice%==2 goto uninst
if %choice%==3 goto done
goto winNT

:inst
if not exist backup md backup
if not exist backup\cities.bmp copy ..\original\cities.bmp backup\cities.bmp
if not exist backup\icons.bmp copy ..\original\icons.bmp backup\icons.bmp
if not exist backup\improvements.bmp copy ..\original\improvements.bmp backup\improvements.bmp
if not exist backup\people.bmp copy ..\original\people.bmp backup\people.bmp
if not exist backup\terrain1.bmp copy ..\original\terrain1.bmp backup\terrain1.bmp
if not exist backup\terrain2.bmp copy ..\original\terrain2.bmp backup\terrain2.bmp
if not exist backup\units.bmp copy ..\original\units.bmp backup\units.bmp
if not exist backup\resource.spr copy ..\original\resource.spr backup\resource.spr
if not exist backup\static.spr copy ..\original\static.spr backup\static.spr
if not exist backup\rules_original.txt copy ..\original\rules.txt backup\rules_original.txt
if not exist backup\rules_extended.txt copy ..\extendedoriginal\rules.txt backup\rules_extended.txt
if not exist backup\pedia.txt copy ..\original\pedia.txt backup\pedia.txt
copy *.bmp ..\original\*.bmp
copy *.spr ..\original\*.spr
copy rules_original.txt ..\original\rules.txt
copy rules_extended.txt ..\extendedoriginal\rules.txt
copy pedia.txt ..\original\pedia.txt
goto done

:uninst
copy backup\*.bmp ..\original\*.*
copy backup\*.spr ..\original\*.*
copy backup\rules_original.txt ..\original\rules.txt
copy backup\rules_extended.txt ..\extendedoriginal\rules.txt
copy backup\pedia.txt ..\original\pedia.txt
goto done

:done
