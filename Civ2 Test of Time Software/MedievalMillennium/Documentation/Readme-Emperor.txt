Civilization II has historically provided six difficulty levels.  In the base game, these are named: Chieftain, Warlord, Prince, King, Emperor, and Deity.

The original version of Civilization II, and possibly some versions after that, permitted the game setup to be configured to provide one or more additional levels of even higher difficulty.  These are often referred to in the Civ2 community as "Deity +1", "Deity +2", etc.  These provide even greater bonuses and advantages to the AI tribes and thus an even greater challenge to the human player.

However, Civilization II: Test of Time crippled this "feature".  While the game setup can still be configured to show additional levels when beginning a new game, and the game can be PLAYED successfully at those levels, attempting to save or load a game which uses one of those higher difficulty levels will immediately cause the entire game to crash.

By using Lua events, Medieval Millennium is able to reintroduce support for higher difficulty levels to Civilization II: Test of Time, and one additional level is currently supported by this modpack, bringing the total to seven.  These are named: Baron, Earl, Marquess, Duke, Prince, King, and Emperor.

Playing a game at any of the first six levels (Baron through King) does not require any special event activity, nor any special steps on your part.  However, the new seventh and highest level, Emperor, comes with some special instructions that must be obeyed in order for the Lua events that enable this level to work correctly.

First and foremost, play this level at your own risk.  Although the game *appears* to play correctly at Emperor level, it's possible that there are some corner-case situations in which behavior may not be correct, predictable, or reliable.  Since the designers of the game itself did not intend to fully support this level, the creator of Medieval Millennium can't make any commitments about its behavior.

If you wish to proceed, the special rules are as follows:

1. First, please note that any saved games created automatically by the game ('auto-saves') while playing at the Emperor level will crash Civilization II if you attempt to load them.  There is currently no solution for this; only manually-saved games will be usable.  It isn't necessary to disable the auto-save feature, but since those games will be useless to you, you'll need to train yourself to perform manual saves more often in case something goes awry.

2. Before you manually save a game, every time, press [Ctrl]-[Shift]-[S] to temporarily downgrade your difficulty level to one that can be stored safely within a saved game file. Don't worry, you can keep playing immediately after this and your chosen difficulty level of 'Emperor' will be restored promptly (and invisibly) by events, before further game action takes place. The level of 'Emperor' will also be restored if you reload the saved game file and start playing. (Technical details: this is achieved by storing your desired level of 'Emperor' as part of the game "state", rather than as the actual difficulty level, in the saved game file.  When the file is reloaded and the game "state" is parsed, the actual difficulty level is raised again before play resumes.)

3. Never save a game by selecting 'Game' in the menubar at the top of the screen and then selecting the option that says 'Press Ctrl+S to Save Game'.  Instead, follow those instructions and use the [Ctrl]-[S] keyboard combination instead to bring up the save game dialog box. This provides an extra level of security for you: if you ever forget step #2 and save a game by pressing [Ctrl]-[S] WITHOUT pressing [Ctrl]-[Shift]-[S] first, a dialog box will warn you that the saved game file you just created is invalid. However, this warning is only available when the save is triggered by the [Ctrl]-[S] keyboard combination; triggering the save dialog box via the menu will prevent this cross-check and warning from occurring.

A shortened form of these three steps will be displayed on the screen whenever you begin a new game at the Emperor level.

-- Knighttime
