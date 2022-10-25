@echo off
cls
echo.
echo        NAPOLEON 1805 - 1815 (BAT TWO)
echo.
echo Loading seasonal rules file for next phase of the game
echo Please choose from the options below:
echo.
echo 1. Load Summer Files
echo 2. Load Winter Files
echo 3. Exit without Loading
echo.

if "%OS%"=="Windows_NT" goto winxp

choice /c:123 Enter your selection

if errorlevel 3 goto done
if errorlevel 2 goto Winter
if errorlevel 1 goto Summer


:winxp
set /P choice=Type a number (1-3) and hit Enter: 
if %choice%==1 goto Summer
if %choice%==2 goto Winter
if %choice%==3 goto done
goto winxp

:Summer
echo.
echo Summer
@echo off
copy Rules\rules_summer_2.txt rules.txt
goto MSG

:Winter
echo.
echo Winter
@echo off
copy Rules\rules_winter_2.txt rules.txt
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