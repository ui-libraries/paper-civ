+-----------------------+
INSTALLATION INSTRUCTIONS
+-----------------------+
This modpack is for Civilization II: Test of Time only, and also requires the Test of Time Patch Project (TOTPP) v0.15.1.
If you do not have both of those installed and confirmed to be working correctly, please do not proceed with the installation.

(The following instructions use the terms "directory" and "subdirectory" -- I apologize if you prefer "folder" and "subfolder" instead. In this context the meanings are the same.)

Create a directory that is *directly beneath* your main TOT install directory, with a name such as "MedievalMillennium". (You can give this directory any name that you want, as long as it does NOT contain a period.) For example, on my computer, my installation directory is "C:\Games\Civ2ToT" so the modpack directory is "C:\Games\Civ2ToT\MedievalMillennium".

Extract all contents of this zip file directly into that directory. (Do not nest them one directory deeper.) Continuing with the above example, the path to this Readme file ought to be "C:\Games\Civ2ToT\MedievalMillennium\Readme.txt".

IMPORTANT NOTE: The zip file contains 5 .dll files which should be found in the InstallToParent subdirectory after you have unzipped the file:
	civ2art.dll
	intro.dll
	mk.dll
	ss.dll
	tiles.dll
If they are not present there, it's possible that they were blocked or quarantined by your anti-virus program. Check that software to see if it prevented the files from being unzipped correctly. You may need to tag them as trustworthy in your anti-virus program and/or manually place them into the correct InstallToParent subdirectory. Note that the installation batch file (see below) also needs to copy these files, so your anti-virus program also needs to permit that operation. (These files contain updated images that will appear in the game, but no other custom code or logic.)

Make sure Test of Time is completely closed and Civ2.exe is not running on your system before proceeding.

Some files which have been customized for Medieval Millennium need to be placed *outside* of the modpack directory itself, and take the place of base files in either the main install directory or the Original subdirectory. You can run "MM_install.bat" (which is present in the main modpack directory) in order to safely back up any affected files and place the custom ones into those locations. However, if you prefer to do this manually, the files that need to be installed are present in the "InstallToParent" directory (these belong in the base game directory, e.g. "C:\Games\Civ2ToT") and the "InstallToOriginal" directory (these belong in the Original subdirectory, e.g. "C:\Games\Civ2ToT\Original"). If you do not use the batch installation program, YOU ARE ENTIRELY RESPONSIBLE for backing up the contents of those directories ON YOUR OWN before copying the custom Medieval Millennium files!

Installing these files correctly (either using the batch program, or manually) is required for proper modpack operation. Do not attempt to begin a game of Medieval Millennium without completing the full installation process.

Once the installation is successful, start Test of Time as you normally do. If the very first game screen (with the opening menu) shows the stylized words "Medieval Millennium", you should be all set!

Note for advanced users only: Rather than installing Medieval Millennium in your current Test of Time directory, you may find it beneficial to have multiple independent installations of Test of Time on your computer. For example, you could copy your entire Test of Time directory, install Medieval Millennium beneath that directory, and then leave it permanently installed there. You could then use your current Test of Time installation as you currently do, while having a completely independent setup for Medieval Millennium.


+--------------+
BEGINNING A GAME
+--------------+
To begin a new game of Medieval Millennium, select "Single Player Game" on the main menu, then select the option labeled "Play a Mod". If this option does not appear, you may not have TOTPP 0.15.1 installed correctly.

After selecting this option, you should see a menu (which may only have a single entry) that allows you to select the current version of Medieval Millennium. (If this menu contains an entry that says "Run 'MM_install.bat' to play Medieval Millennium" then this modpack is not correctly installed. Please review the instructions in the previous section.)

Test of Time will then begin the sequence of menus that normally appear when you begin a new game of Civilization, many of which have been customized. Choose the options that you wish, paying special attention to entries that may be listed as "RECOMMENDED", "NOT RECOMMENDED", or "REQUIRED". Selecting options that are not recommended, or failing to select those that are required, may result in game errors or a poor gameplay experience.

After completing all of the selections, you will likely see a dialog box entitled "Warning" that begins with the words "This scenario uses Lua events." You must choose one of the first two "Yes" options in order to proceed. Do NOT choose the third "No" option.

After several more dialog boxes, you will eventually find yourself with an active Peasant surrounded by a few tiles of visible terrain. You are ready to begin playing!


+-------------------------+
UNINSTALLATION INSTRUCTIONS
+-------------------------+
If you have exited Medieval Millennium and wish to return to playing the base game, or play a different scenario, the modpack must be uninstalled first! Just like installation, this requires that you completely close Test of Time so that Civ2.exe is not running on your system. If you used the "MM_install.bat" program to install Medieval Millennium, you can use the "MM_uninstall.bat" program to reverse the process and put the game's standard files back in place. If you installed the modpack manually without the batch file, then you are likewise responsible for uninstalling it and restoring the game's standard files.


+-----------+
DOCUMENTATION
+-----------+
Additional documentation with many details about the modpack is present in the Documentation subdirectory (e.g., "C:\Games\Civ2ToT\MedievalMillennium\Documentation"). The documentation is in PDF format and can be viewed with Adobe Acrobat Reader, which can be downloaded for free. As much as possible, the information there is also present within the Civilopedia once you have begun a game.

At minimum, you are strongly encouraged to read "Guide - 1. Overview.pdf". Studying the remainder of the documentation in advance of playing is not required, but is likely to prove beneficial. There are many new and unexpected features in Medieval Millennium, and mastering the game will probably require you to study the documentation at some point, either in the PDF format or within the Civilopedia.


+-------------------------------------------+
LIMITATIONS AND POTENTIAL FUTURE ENHANCEMENTS
+-------------------------------------------+
1. This modpack is intended for single-player games only. The events will not work correctly in a hotseat game or any other type of game involving more than one human player.
2. This modpack does not currently support the use of custom pre-built maps when starting a new game. All games begin with a new randomly-generated map.

You are welcome to submit other feature requests or ideas for consideration.


Happy Civing!
Knighttime
