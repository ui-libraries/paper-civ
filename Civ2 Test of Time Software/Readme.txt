The Test Of Time Patch Project (TOTPP) is a free program that aims to remove some of the limitations and bugs in Civilization II: Test Of Time. It consists of a collection of patches that can be individually applied to the game.


Project information
===================
Currently, TOTPP contains over 80 patches. This section contains a brief overview of the available modifications. Detailed information about specific patches can be found in the launcher.

ToT bug fixes:
- Edit control fix: Fixes a crash on 64-bit operating systems when an edit control is created.
- AI Hostility fix: Fixes the general hostility of the AI in the game.
- Steal forbidden tech fix: Fixes the rule 2 restrictions in @LEADERS2 so that forbidden technologies cannot be stolen.
- Civilopedia movement rate fix: Fixes the movement rate listed for units in the Civilopedia so it displays correct numbers for cosmic road multipliers other than 3.
- Transform order check: Adds a check to the transform order to see if the terrain type can be transformed at all.
- Global warming fix: Fixes global warming, which had the tendency to skip cycles of terrain change due to improper bounds checking.
- Modify reputation event: Allows a negative reputation modifier for the ModifyReputation event action, as stated in the documentation.
- City screen unit selection: Allows selecting stationed units beyond the 16th in the city screen.
- City screen unit disband: Disables the "Disband" option in the city screen's "Supported units" box for non-disbandable units.
- Teleporter improvement map check: Adds a check to the teleporter city improvement so that units can not be teleported to cities on maps they are prohibited from entering.
- MoveUnit event: Allows a unit type name as the "unit" parameter of the MoveUnit event action, as was intended according to the documentation.
- Resource animation loop: Fixes a bug where the last frame of a looping resource animation would be rendered even when animated resources were disabled.
- Reset city name: Resets the city name counter when a new human-controlled civ is created.
- City working tiles: Fixes a bug where cities on opposite sides of the International Date Line (x-coordinate 0) could both work the same tiles.
- Native transport: Makes native transport respect "not allowed on map" settings from @UNITS_ADVANCED.
- Zoom level: Properly restores the zoom level from the saved game when loading a game.
- Disabled button rendering: Fixes graphical rendering of disabled buttons.
- Diplomacy screen crash: Fixes a potential crash (buffer overflow) in the diplomacy screen.
- End player turn: Updates remaining units when using "End player turn" (Ctrl-N).
- AI unit orientation: Fixes orientation of AI units when moving in a westerly direction.
- Build transporter: Fixes two bugs associated with building transporters.
- Map layout: Fixes a bug with rendering the status window when loading a game when the map layout is in classic mode.
- Activate unit scrollbar: Adds a scrollbar to the activate unit dialog, making it possible to select more than 9 units.
- Civilopedia wonder graphics: Fixes the rendering of wonder graphics in the Civilopedia.
- Pikemen flag: Fixes movement rate check of the pikemen flag.
- Ship disband: Fixes disbanding ships at sea.
- Take technology: Fixes two bugs when removing technologies through macro events / Lua.

Features / modifications:
- City and unit limits: New, configurable limits up to 32,000. Fixes the home cities of all units to handle things like support, trade routes, etc.
- Money, population & map limits: Increases the limits on money, population and map size.
- Decrease CPU Use: Decrease CPU use of the game by changing the event loop.
- No CD: Disables the CD check on startup.
- Enable throne room: Enables building of throne room improvements. This feature was never removed from TOT, just disabled.
- City/unit overview: Displays the number of cities and units for the player's tribe in the empire overview window.
- Transform requires tech: Associate a technology to the transformation of different terrain types.
- Custom resources: Play on maps with manually placed resources.
- Impassable terrain domain check: Makes air units respect impassable terrain too.
- Overridable health bars: Allows hiding of unit health bars for specific unit types by setting a flag in @UNITS
- Extra cosmic parameters: Configure previously hard-coded parameters on a per-scenario basis. Patches using this feature:
  - Trade revenue: Apply a percentage to the gold/science revenue of caravans.
  - Defense bonus: Configure multiple defensive bonuses.
  - City population loss: Configure whether a city suffers population loss after a successful attack/capture.
  - Unit shield colors: Make shield colors brighter / darker.
  - No stack kills: Configure stack kill mechanics.
  - Event heap: More (or less) memory for events.
  - Navigable rivers: Allows ships to sail on rivers.
  - Extra terrain types: 16 available terrain types instead of 11.
  - Incremental rush buying: The option to disable incremental rush buying.
  - Movement multipliers: Configure movement cost along roads, railroads and rivers.
  - Production carry-over: Determine what to do with excess shields after production is completed.
  - Leonardo's workshop settings: Workshop upgrades can preserve veterancy.
  - City sprites: City sprites per map and per tribe.
  - AI tweaks: Adds configurable tweaks for AI behaviour to @COSMIC2.
  - Playable tribes & difficulties: Limit playable tribes and difficulties in a scenario.
- Fertility: Select the terrain types the AI will settle.
- City view: Enables the city view from MGE by pressing 'v' in the city screen.
- Mouse wheel support: Enables mouse wheel support for all dialogs with scrollbars.
- Edit terrain hotkeys: Adds keyboard shortcuts for changing terrain.
- Major objective: Restores the x3 major objective for cities as in Fantastic Worlds.
- TOTPP configuration: In-game patch configuration.
- Civilopedia improvement icons: Uses the larger icons from Improvements.bmp for the improvements & wonders sections of the Civilopedia.
- Improvement flags: 8 binary flags per city improvement.
- Active unit indicators: Configurable active unit indicators through the TOTPP Configuration menu.
- Combat animation: Enables the 8-frame combat animation from Icons.bmp when animated units are disabled.
- Terrain overlays: Custom overlays from TERRAIN2.bmp for arbitrary terrain types.
- Save file extensions: Extends the saved game format allowing patches storing arbitrary. Patches using the extension:
  - Attacks per turn: Set the number of attacks per turn per unit type.
  - Extra unit types: 189 available unit types instead of 80.
  - Landmarks: Allows custom text to be added to map tiles.
  - Extra technologies: 253 available technologies instead of 100.
- DirectShow video: Video playback using the DirectX9 API.
- DirectShow sound: Sound effects using the DirectX9 API.
- DirectShow music: Music playback using the DirectX9 API. Replaces CD audio.
- Custom game mods: Allows modpacks to be launched from the main menu, without the need to overwrite the Original folder.
- Custom mod / scenario resources: Allows mods and scenarios to load custom resource DLLs and several other files that are ordinarily not customizable.
- Reporting options: Allows the player to configure various aspects of UI dialogs and delays.
- Difficulty levels: New difficulty levels above deity.
- Initial trade arrow for roads: Configurable initial trade arrow per terrain type.
- Extra settler flags: Disable settler flags for settler type units or enable them for regular units.
- Lua scripting: Enables Lua scripting, and the Lua console.
  - Lua scenario events: Enables Lua scripting as a replacement for scenario events.

Debug patches:
- Multiple instances: Allow multiple instances of the game to run simultaneously.
- Move debug: Render the tile scores used for path-finding on the map.
- Debug scripts: Adds an in-game menu from which scripts can be run.


Requirements
============
TOTPP requires Test Of Time v1.1 to run. Non-static builds also depend on the Microsoft C++ runtime libraries, which can be downloaded from https://aka.ms/vs/16/release/vc_redist.x86.exe.
For Windows XP an older version must be used: https://download.visualstudio.microsoft.com/download/pr/56f631e5-4252-4f28-8ecc-257c7bf412b8/D305BAA965C9CD1B44EBCD53635EE9ECC6D85B54210E2764C8836F4E9DEFA345/VC_redist.x86.exe


Installation
============
Extract the archive to the Test Of Time installation folder (containing civ2.exe) and run TOTLauncher.exe. Follow the instructions to patch civ2.exe to load TOTPP.dll, this only has to be done once. Afterwards, use the launcher to make changes in the patch selection. To run the game with your previous settings you can simply run civ2.exe.


License
=======
This software is provided as-is, without warranty of any kind. You may redistribute it as long as you give credit.

Lua, the scripting language used in the project, is licensed under the MIT license (https://www.lua.org/license.html)


Changelog
=========

v0.18.4
-------

Fixes:
- Fixed a crash bug in the 'Extra settler flags' patch caused by reading an uninitialized variable.


v0.18.3
-------

Fixes:
- Fixed a bug in the extra tech patch that made Fundamentalism unavailable.
- Fixed another bug that caused "Future Technology" not to be displayed correctly on the scoring screen.


v0.18.2
-------

Features:
- onCanFoundCity now fires for advanced tribes
- LUA: Added tile.hasGoodieHut

Fixes:
- Fixed city production upgrade after a unit type becomes obsolete.
- Fixed a bug in onGetFormattedDate where an incorrect turn was passed for the space ship screen.


v0.18.1
-------

Fixes:
- Fixed units unable to fortify.
- Changed civ.playMusic to accept absolute paths again.


v0.18
-----

Features:
- Added the 'Take technology' patch.
- Added the 'Extra technologies' patch.
- Added the 'Custom mod / scenario resources' patch.
- Increased the unit type limit to 189 in the 'Extra unit types' patch.
- Added a 'TradeWonderMultiplier' setting to the 'Trade revenue' patch.
- LUA: Added onGetFormattedDate, onUseNuclearWeapon, onSelectMusic, onTribeTurnBegin, onTribeTurnEnd, onCityProcessingComplete and onCanFoundCity.
- LUA: The onCityFounded callback can now return a function that is called to perform cleanup when the user presses Exit on the city naming dialog.
- LUA: Added unit.attackSpent and unittype.attacksPerTurn.

Fixes:
- Fixed a crash bug in the 'Extra settler flags' patch when automating settlers.
- Fixed a crash bug in the 'Activate unit scrollbar' patch.
- Fixed some bugs pertaining to the barbarian diplomat unit.
- Fixed a bug that caused 'title.gif' not to be displayed for scenarios.
- LUA: unit:activate() now triggers the onActivateUnit callback.
- LUA: Equality tests for objects in the civ namespace now return false instead of an error when the arguments have different types (and ~= returns true).


v0.17
-----

Features:
- Added the 'Pikemen flag' patch.
- Added the 'Ship disband' patch.
- Rewrote the 'Decrease CPU use' patch to be more responsive.
- LUA: Added trade routes and commodities.
- LUA: Added onChooseDefender to override the defender for a tile.
- LUA: Added onGetRushBuyCost to override the rush buy cost.
- LUA: onActivateUnit can now optionally fire after each movement.
- LUA: Added unit.visibility.

Fixes:
- Better handling for Lua errors outside of protected mode. Fixes crashes when returning unexpected types from Lua.
- Fixed handling of Lua return values in C when another Lua frame was already on the stack.
- The civilopedia will now show changes made by the 'Initial trade arrow for roads' patch.


v0.16
-----

Features:
- Mods will now load resource dlls and window graphics (dialog.bmp, city.bmp, civwin_back.bmp) from the mod directory.
- Mods will now reload text files from the mod directory when starting a new game (e.g. menu.txt).
- Added an 'advanced' mod parameter to support setting advanced rules when starting a new game.
- Added a 'BarbResearch' setting to the 'AI tweaks' patch.
- Added the 'Difficulty levels' patch.
- Added the 'Multiple instances' patch.
- Added the 'Initial trade arrow for roads' patch.
- Added the 'Extra settler flags' patch.
- Updated included Lua version to 5.3.6
- LUA: Added totpp.version.
- LUA: Added totpp.mod.premadeMap.
- LUA: Added tile.baseterrain, tile.terrain, tile.visibility, tile.river, tile.visibleImprovements.
- LUA: Added civ.scen.onCalculateCityYield, civ.scen.onInitiateCombat.
- LUA: Added city.currentProduction, improvement.upkeep, civ.game.rules, unit.domainSpec.
- LUA: Added unittype.tribeMayBuild, unittype.notAllowedOnMap, unittype.minimumBribe, unittype.advancedFlags.
- LUA: Added civ.getOpenCity.

Fixes:
- Fixed a bug in the initialization of the "Movement multipliers" patch if no custom multipliers were defined.
- Fixed game year calculation on pre-made maps for mods.
- Fixed some bugs in civlua.lua.
- The city & unit limit patch now uses a growable heap for the "Go To" dialog, this one was missed in the v0.6 release.


v0.15.1
-------

Features:
- The "Lua" patch exports a new library globally ("totpp"), where patches can register their own Lua tables to expose functionality.
- The "Movement multipliers" patch now registers the "totpp.movementMultipliers" table.

Fixes:
- Fixed a crash bug in civ.ui.loadTerrain.
- Fixed a bug in civ.scen.onCanBuild, where the callback was called twice for each wonder instead of once.


v0.15
-----

Features:
- Added the "Activate unit scrollbar" patch.
- Added two new options to the "Reporting options" patch.
- Tons of new ways of interacting with the game from Lua. See the civfanatics.com forums for details.
- The user can now opt to trust specific Lua event files during loading, removing the warning dialog in the future.


v0.14.3
-------

Fixes:
- Fixed a bug in the "Lua scenario events" patch where Lua events would not fire properly in some cases.
- Fixed a bug in the "Attacks per turn" patch which did not take into account the extra units from the Extra unit types patch.


v0.14.2
-------

Features:
- The Lua DLL is now compiled with the runtime library included statically, removing the dependency on MSVCR100.DLL, making installation easier.

Fixes:
- Fixed a crash bug that occurred when starting some scenarios if @TRANSPORTOPTIONS in Game.txt was not correctly separated from the next entry (buffer overflow).
- Fixed a bug in the "Defense bonus" patch where setting TerrainDefenseForSea or TerrainDefenseForAir to 0 caused such units to defend at half strength.
- Fixed a bug in the "Custom game mods" patch where the Tech paradigm was incorrectly initialized to 0.


v0.14.1
-------

Fixes:
- Fixed a bug in the "AI tweaks" patch where produced units didn't get the correct home city assigned.


v0.14
-----

Features:
- Added the "Build transporter" patch.
- Added the "Map layout" patch.
- Added the "Reporting options" patch.
- Added the "Lua scripting" patch.
- Added the "Lua scenario events" patch.
- Added two configurable keys to the "AI tweaks" patch.

Fixes:
- Fixed a bug in the "Extra unit types" patch where unused units would show up in the Civilopedia.


v0.13.1
-------

Fixes:
- Fixed a crash bug when updating city production from an obsolete unit type
- Fixed a bug where the barbarian diplomat sprite didn't show when having less than 127 unit types


v0.13
-----

Features:
- Added the "Extra unit types" patch
- Added the "Playable tribes & difficulties" patch
- Added the create unit script to the "Debug scripts" patch
- Added road and alpine movement multipliers to the "Movement multipliers" patch


v0.12.1
-------

Features:
- The "Defense bonus" patch now contains a key to disable the defensive bonus from terrain for naval units as well.

Fixes:
- Fixed a bug in the "Railroad & river multiplier" patch where rivers did no longer count as roads even with the MovementMultipliers key disabled.


v0.12
-----

Features:
- Added the "AI unit orientation" patch
- Added the "AI tweaks" patch
- Added the "Landmarks" patch
- The "Defense bonus" patch now contains a key to disable the defensive bonus from terrain for air units
- Increased the 30k limit for the ChangeMoney event in the "Money, population & map limits" patch
- The "Event Heap" patch now shows the used heap space for growable heaps

Fixes:
- Fixed overlay text not working when using the "DirectShow video" patch
- Fixed a potential crash bug in the "DirectShow sound" patch when processing long AI turns
- Fixed a bug in the "Extra terrain types" patch where impassable terrain did not work on additional maps


v0.11.2
-------

Fixes:
- Fixed a bug in TOTPP.dll that caused a game crash after loading events.
- TOTPP.dll doesn't rewrite its own code anymore, and should no longer crash when DEP (Data Execution Prevention) is enabled.


v0.11.1
-------

Fixes:
- Fixed a bug in the "City population loss" patch where cities were not properly removed upon reaching size 0.


v0.11
-----

Features:
- Added the "City sprites" patch
- Added the "DirectShow video" patch
- Added the "DirectShow sound" patch
- Added the "DirectShow music" patch
- Added the "Custom game mods" patch
- Added the "Debug scripts" patch
- Added tile improvement hotkeys to the "Edit terrain hotkeys" patch
- The "Impassable terrain for air domain" patch is no longer automatically active when enabled, but must be enabled through @COSMIC2 first.
- The "Railroad & river multiplier" patch now uses an additional key "MovementMultipliers".
- Changed the launcher to enable "safe" patches by default when no configuration is present.
- Changed the launcher to use rich text for the description box. Descriptions are loaded from the TOTPP\desc folder.

Fixes:
- Rewrote the CPU patch so it does not crash multiplayer games anymore.


v0.10
-----

Features:
- Added the "Railroad & river multiplier" patch
- Added the "Production carry-over" patch
- Added the "Leonardo's workshop settings" patch
- Added the "Save file extensions" patch
- Added the "Attacks per turn" patch
- Added 5 new keys to the "Defense bonus" patch


v0.9.1
------

Fixes:
- Fixed a crash bug in the "Extra terrain types" patch when playing with less than 16 terrain types.
- Fixed a graphical glitch in the "Active unit indicators" patch.


v0.9
----

Features:
- Added the "Fix: Disabled button rendering" patch
- Added the "Fix: Diplomacy screen crash" patch
- Added the "Fix: End player turn" patch
- Added the "Incremental rush buying" patch
- Added the "Improvement flags" patch
- Added the "Active unit indicators" patch
- Added the "Combat animation" patch
- Added the "Terrain overlays" patch
- The TOTPP configuration menu can now also be used in-game by pressing Ctrl-Shift-T.

Fixes:
- The mini-map didn't use correct colors for the five new terrain types. This has been fixed in the "Extra terrain types" patch.


v0.8
----

Features:
- Added the "Navigable rivers" patch
- Added the "Extra terrain types" patch
- Added the "Edit terrain hotkeys" patch
- Added the "Major objective" patch
- Added the "TOTPP configuration" patch
- Added the "Civilopedia improvement icons" patch
- The "Zoom level" and "Shield colors" patch can now be configured through the TOTPP configuration menu.
- Added smooth scrolling & Shift-scroll to the mouse wheel patch
- Added an option to preserve seeded resources to the custom resource patch.


v0.7
----

Features:
- The launcher can now patch civ2.exe to load TOTPP.dll.
- Added the "Fix: Native transport" patch
- Added the "Fix: Zoom level" patch
- Added the "No CD" patch
- Added the "City view" patch
- Added the "Mouse wheel" patch
- Custom resources can be placed in-game, removing the need for external tools.

Fixes:
- Fixed a bug in the "Custom resources" patch where unloading a map could cause a CTD.


v0.6
----
Features:
- Rewrote memory allocation to allow patches to use heap functions, replacing the obsolete Global* functions.
- The city & unit limit patch now uses growable heaps for the "Find City", "Supply & Demand", "Airlift", and "Transporter" dialogs, preventing crashes when playing with very large numbers of cities.
- Added the "Fix: MoveUnit event" patch
- Added the "Fix: Resource animation loop" patch
- Added the "Fix: Reset city name" patch
- Added the "Fix: City working tiles" patch
- Added the "Cosmic: Event heap" patch
- Added a second parameter to the "UnitShieldColor" key of the "Cosmic: Shield colors" patch

Fixes:
- Fixed a bug in the "Custom resources" patch where saving the game didn't restore the current map index correctly.
- Fixed a bug in the "Override health bars" patch where the overlapping shields indicating unit stacks didn't show up.


v0.5
----
Features:
- Added the "Fix: City screen unit selection" patch
- Added the "Fix: City screen unit disband" patch
- Added the "Fix: Teleporter improvement map check" patch
- Added the "Cosmic: Mountain height" patch
- Added the "Cosmic: No stack kills" patch
- Added the "Fertility" patch


v0.4
----
Features:
- Added the "Fix: Global warming" patch
- Added the "Fix: Modify reputation" patch
- Added the "Override health bars" patch
- Added the "Extra cosmic parameters" patch
- Added the "Cosmic: Trade revenue" patch
- Added the "Cosmic: Defense bonus" patch
- Added the "Cosmic: City population loss" patch
- Added the "Cosmic: Shield colors" patch
- Improved the patch selection window, adding separators and grouping
- The city & unit limit patch is no longer required to be enabled, and acts more like an ordinary patch now

Fixes:
- Fixed a bug where opening dialogs (e.g. "Find City") when playing with large numbers of cities caused the game to crash.


v0.3
----
Features:
- Added the "Fix: AI Hostility" patch
- Added the "Fix: Steal forbidden tech" patch
- Added the "Fix: Civilopedia movement rate" patch
- Added the "Fix: Transform check" patch
- Added the "Impassable terrain for air domain" patch

Fixes:
- Fixed a bug in the CPU patch where the multiplayer "Build World" phase hung indefinitely.


v0.2
----
Features:
- Added the "Decrease CPU Use" patch
- Added the "No Limits" patch
- Added the "Transform requires tech" patch
- Added the "Custom resources" patch

Fixes:
- Fixed a layout issue in the launcher causing some elements to overlap in Windows 8


v0.1 (Initial release)
----------------------
Features:
- Added the "City & unit limits" patch
- Added the "Fix: Edit Control" patch
- Added the "Enable throne room" patch
- Added the "City/unit overview" patch
