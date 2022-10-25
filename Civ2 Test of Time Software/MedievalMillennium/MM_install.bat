@echo off
cls
echo Medieval Millennium will now be installed.
echo.
echo Press Ctrl-C to exit, or
pause
echo.

rem ********** PARENT FOLDER FILES **********
:FILEciv2Art
if exist ..\civ2Art.mm_backup goto FILEintro
echo Backing up and installing civ2Art.dll ...
copy ..\civ2Art.dll ..\civ2Art.mm_backup
copy InstallToParent\civ2Art.dll ..\civ2Art.dll

:FILEintro
if not exist ..\intro.dll goto FILEintroInstallOnly
if exist ..\intro.mm_backup goto FILEintroInstallOnly
:FILEintroBackupInstall
echo Backing up and installing intro.dll ...
copy ..\intro.dll ..\intro.mm_backup
copy InstallToParent\intro.dll ..\intro.dll
goto FILEmk
:FILEintroInstallOnly
echo Installing intro.dll ...
copy InstallToParent\intro.dll ..\intro.dll

:FILEmk
if exist ..\mk.mm_backup goto FILEss
echo Backing up and installing mk.dll ...
copy ..\mk.dll ..\mk.mm_backup
copy InstallToParent\mk.dll ..\mk.dll

:FILEss
if exist ..\ss.mm_backup goto FILEtiles
echo Backing up and installing ss.dll ...
copy ..\ss.dll ..\ss.mm_backup
copy InstallToParent\ss.dll ..\ss.dll

:FILEtiles
if exist ..\tiles.mm_backup goto FILEtotpp
echo Backing up and installing tiles.dll ...
copy ..\tiles.dll ..\tiles.mm_backup
copy InstallToParent\tiles.dll ..\tiles.dll

:FILEtotpp
if exist ..\TOTPP.mm_backup goto FILEadvice
echo Backing up and installing TOTPP.ini ...
copy ..\TOTPP.ini ..\TOTPP.mm_backup
copy InstallToParent\TOTPP.ini ..\TOTPP.ini

rem ********** ORIGINAL FOLDER FILES **********
:FILEadvice
if exist ..\Original\Advice.mm_backup goto FILEcity
echo Backing up and installing Advice.txt ...
copy ..\Original\Advice.txt ..\Original\Advice.mm_backup
copy InstallToOriginal\Advice.txt ..\Original\Advice.txt

:FILEcity
if exist ..\Original\City.mm_backup goto FILEcivwin_back
echo Backing up and installing City.bmp ...
copy ..\Original\City.bmp ..\Original\City.mm_backup
copy InstallToOriginal\City.bmp ..\Original\City.bmp

:FILEcivwin_back
if exist ..\Original\Civwin_back.mm_backup goto FILEdialog
echo Backing up and installing Civwin_back.bmp ...
copy ..\Original\Civwin_back.bmp ..\Original\Civwin_back.mm_backup
copy InstallToOriginal\Civwin_back.bmp ..\Original\Civwin_back.bmp

:FILEdialog
if exist ..\Original\Dialog.mm_backup goto FILEgame
echo Backing up and installing Dialog.bmp ...
copy ..\Original\Dialog.bmp ..\Original\Dialog.mm_backup
copy InstallToOriginal\Dialog.bmp ..\Original\Dialog.bmp

:FILEgame
if exist ..\Original\Game.mm_backup goto FILElabels
echo Backing up and installing Game.txt ...
copy ..\Original\Game.txt ..\Original\Game.mm_backup
copy InstallToOriginal\Game.txt ..\Original\Game.txt

:FILElabels
if exist ..\Original\Labels.mm_backup goto FILEmenu
echo Backing up and installing Labels.txt ...
copy ..\Original\Labels.txt ..\Original\Labels.mm_backup
copy InstallToOriginal\Labels.txt ..\Original\Labels.txt

:FILEmenu
if exist ..\Original\Menu.mm_backup goto FILErules
echo Backing up and installing Menu.txt ...
copy ..\Original\Menu.txt ..\Original\Menu.mm_backup
copy InstallToOriginal\Menu.txt ..\Original\Menu.txt

rem ********** SCENARIO FOLDER FILES **********
:FILErules
echo Finalizing installation ...
copy Rules_mm.txt Rules.txt

rem ********** COMPLETE **********
echo.
echo Medieval Millennium is now successfully installed!
echo.
echo Run 'MM_uninstall.bat' after you have finished playing,
echo before attempting to play any other type of Civ2ToT game.
echo.
pause
