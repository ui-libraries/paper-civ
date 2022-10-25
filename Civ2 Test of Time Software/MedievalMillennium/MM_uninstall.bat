@echo off
cls
echo Medieval Millennium will now be uninstalled.
echo.
echo Press Ctrl-C to exit, or
pause
echo.

rem ********** PARENT FOLDER FILES **********
:FILEciv2Art
if not exist ..\civ2Art.mm_backup goto FILEintro
echo Restoring civ2Art.dll ...
copy ..\civ2Art.mm_backup ..\civ2Art.dll
del ..\civ2Art.mm_backup

:FILEintro
if not exist ..\intro.dll goto FILEmk
if not exist ..\intro.mm_backup goto FILEintroDeleteOnly
:FILEintroBackupFound
echo NOTE: Did not restore intro.mm_backup to intro.dll
echo since intro.dll is not a standard part of a Civ2ToT installation.
echo You may rename the backup file manually if you had previously
echo installed a custom version of this file that was not part
echo of Medieval Millennium.
del ..\intro.dll
goto FILEmk
:FILEintroDeleteOnly
echo Removing intro.dll ...
del ..\intro.dll

:FILEmk
if not exist ..\mk.mm_backup goto FILEss
echo Restoring mk.dll ...
copy ..\mk.mm_backup ..\mk.dll
del ..\mk.mm_backup

:FILEss
if not exist ..\ss.mm_backup goto FILEtiles
echo Restoring ss.dll ...
copy ..\ss.mm_backup ..\ss.dll
del ..\ss.mm_backup

:FILEtiles
if not exist ..\tiles.mm_backup goto FILEtotpp
echo Restoring tiles.dll ...
copy ..\tiles.mm_backup ..\tiles.dll
del ..\tiles.mm_backup

:FILEtotpp
if not exist ..\TOTPP.mm_backup goto FILEadvice
echo Restoring TOTPP.ini ...
copy ..\TOTPP.mm_backup ..\TOTPP.ini
del ..\TOTPP.mm_backup

rem ********** ORIGINAL FOLDER FILES **********
:FILEadvice
if not exist ..\Original\Advice.mm_backup goto FILEcity
echo Restoring Advice.txt ...
copy ..\Original\Advice.mm_backup ..\Original\Advice.txt
del ..\Original\Advice.mm_backup

:FILEcity
if not exist ..\Original\City.mm_backup goto FILEcivwin_back
echo Restoring City.bmp ...
copy ..\Original\City.mm_backup ..\Original\City.bmp
del ..\Original\City.mm_backup

:FILEcivwin_back
if not exist ..\Original\Civwin_back.mm_backup goto FILEdialog
echo Restoring Civwin_back.bmp ...
copy ..\Original\Civwin_back.mm_backup ..\Original\Civwin_back.bmp
del ..\Original\Civwin_back.mm_backup

:FILEdialog
if not exist ..\Original\Dialog.mm_backup goto FILEgame
echo Restoring Dialog.bmp ...
copy ..\Original\Dialog.mm_backup ..\Original\Dialog.bmp
del ..\Original\Dialog.mm_backup

:FILEgame
if not exist ..\Original\Game.mm_backup goto FILElabels
echo Restoring Game.txt ...
copy ..\Original\Game.mm_backup ..\Original\Game.txt
del ..\Original\Game.mm_backup

:FILElabels
if not exist ..\Original\Labels.mm_backup goto FILEmenu
echo Restoring Labels.txt ...
copy ..\Original\Labels.mm_backup ..\Original\Labels.txt
del ..\Original\Labels.mm_backup

:FILEmenu
if not exist ..\Original\Menu.mm_backup goto FILErules
echo Restoring Menu.txt ...
copy ..\Original\Menu.mm_backup ..\Original\Menu.txt
del ..\Original\Menu.mm_backup

rem ********** SCENARIO FOLDER FILES **********
:FILErules
echo Finalizing uninstallation ...
copy Rules_base.txt Rules.txt

rem ********** COMPLETE **********
echo.
echo Medieval Millennium is no longer installed.
echo Run 'MM_install.bat' if you would like to play again!
echo.
pause
