Darklord, a Civ2 Scenario by Carl Fritz
EMAIL: cfritz@angelfire.com 

See readme2.txt for a description of the scenario.

INSTALLATION:
 This scenario requires the Fantastic Worlds (FW) add-on for Civilization II.
If you have FW then you probably already know that these files should be
installed in a subdirectory of the SCENARIO directory. This package contains
the files for the SOUND subdirectory for use in the scenario. If you use
WINZIP, use the "use folder names" option when you EXTRACT and you'll be
done. It will create a directory named DARKLORD. Otherwise, you'll have to
create a DARKLORD directory (or whatever you want) and SOUND directory
in the DARKLORD directory and move the .wav files and the file copysnd.bat
there. 
 To help you with the new units, wonders and technologies, a pedia.txt
file has been included so that the help in the game will be correct.

SOUND DIRECTORY SETUP:
 Assuming that you have created the SOUND directory for the scenarion and
that the .wav files and COPYSND.BAT are there, you need to execute
COPYSND.BAT from the SOUND directory to complete the SOUND directory setup.
This batch file was included instead of the actual sounds to save space
(about 2 MEG!) in the distribution file.

 Most of the scenario sounds are standard sounds from the game being used
in a non-standard way. They will be copied with the new name so that the
sounds are appropriate for the units. 

TROUBLESHOOTING SOUND SETUP:
 If you got the message "The CIV2\SOUND directory could not be found.",
it is probably because the CIV2 directory is not 3 levels below the
DARKLORD\SOUND directory. Make sure DARKLORD\SOUND is the current directory
when running copysnd.bat and that the DARKLORD directory is a subdirectory
of the CIV2\SCENARIO directory. If this was not the case, you may want
give it another shot.
 If you had other copy errors, there may be missing files in the 
CIV2\SOUND directory. Restore them and try copysnd.bat again if that was
the problem.
 If all of this fails, you can still do this manually. Here are the new
sounds in the SOUND directory you have to create and the source.

NEW SOUND		SOURCE
volcano.wav            	civ2\sound\volcano.wav 
infantry.wav        	civ2\sound\swordfgt.wav 
mchnguns.wav            civ2\sound\swordfgt.wav 
cavalry.wav		civ2\sound\swrdhors.wav
navbttle.wav		civ2\sound\biggun.wav
nukexplo.wav		civ2\sound\largexpl.wav
jetbomb.wav         	jetcombt.wav (already in this directory)
helishot.wav		jetcombt.wav (already in this directory)
divebomb.wav		aircombt.wav (already in this directory)
custom1.wav		missile.wav (already in this directory)
custom2.wav		missile.wav (already in this directory)
custom3.wav		missile.wav (already in this directory)
engnsput.wav        	divcrash.wav (already in this directory)
jetsputr.wav        	jetcrash.wav (already in this directory)
extra1.wav		missile.wav (already in this directory)
extra2.wav		civ2\sound\cavalry.wav
extra3.wav		civ2\sound\cavalry.wav
extra4.wav		civ2\sound\cavalry.wav
extra5.wav		missile.wav (already in this directory)
extra6.wav		missile.wav (already in this directory)
extra7.wav		missile.wav (already in this directory)
extra8.wav		missile.wav (already in this directory)
medgun.wav		missile.wav (already in this directory)

WARNING: Don't edit the Events.txt file with the FW editor. Barbarian
units are created by events, and the FW editor doesn't allow that, but
text editing it does allow that.
