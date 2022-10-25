@echo off
cls
echo.
echo        NAPOLEON 1805 - 1815  (BAT ONE)
echo.
echo Loading seasonal rules files for next phase of the game
echo Please choose from the options below:
echo.
echo 1. Load September, 1805
echo 2. Load Summer Files
echo 3. Load Winter Files
echo 4. Exit without Loading
echo.

if "%OS%"=="Windows_NT" goto winxp

choice /c:1234 Enter your selection

if errorlevel 4 goto done
if errorlevel 3 goto Winter
if errorlevel 2 goto Summer
if errorlevel 1 goto Aug1805

:winxp
set /P choice=Type a number (1-4) and hit Enter: 
if %choice%==1 goto Aug1805
if %choice%==2 goto Summer
if %choice%==3 goto Winter
if %choice%==4 goto done
goto winxp

:Aug1805
echo.
echo August, 1805
@echo off
copy Terrain\sTerrain1.bmp Terrain1.bmp
copy Terrain\sTerrain2.bmp Terrain2.bmp
copy Rules\rules_summer_1.txt rules.txt
goto MSG

:Summer
echo.
echo Summer
@echo off
copy Rules\rules_summer_1.txt rules.txt
goto MSG

:Winter
echo.
echo Winter
@echo off
copy Rules\rules_winter_1.txt rules.txt
goto MSG


:MSG
echo.
echo ==================================================================
echo NAPOLÉON 1805 - 1815
echo.
echo 
echo 
echo 
echo 
echo ==================================================================
echo.
echo.
pause
goto done

:done
quit