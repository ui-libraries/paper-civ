-- mmDifficulty.lua
-- by Knighttime

log.trace()

local DIFFICULTY_LEVEL_NAME = {
-- civ.game.difficulty	MM LEVEL			ORIG LEVEL
			[0] 	=	"Baron",		--	Chieftain
			[1] 	=	"Earl",			--	Warlord
			[2] 	=	"Marquess",		--	Prince
			[3] 	=	"Duke",			--	King
			[4] 	=	"Prince",		--	Emperor
			[5] 	=	"King",			--	Deity
			[6]		=	"Emperor"		--	n/a, "Deity +1"
}

-- In the following table, higher numbers serve as a penalty to the AI, and result in an easier game
-- 100 means a truly level playing field, no bonus or penalty for AI tribes
-- Lower numbers provide a bonus to the AI, and result in a more challenging game
local DIFFICULTY_LEVEL_PERCENT = {
-- civ.game.difficulty	MM EVENTS %		MM LEVEL	AI HEALTH ROWS	AI MATERIALS COLS	BARB ATTACK STR		ORIG LEVEL
			[0] 	=		140,	--	Baron			18				15					 25%			Chieftain
			[1] 	=		125,	--	Earl			16				13					 50%			Warlord
			[2] 	=		110,	--	Marquess		14				12					 75%			Prince
			[3] 	=		100,	--	Duke			12				10					100%			King
			[4] 	=		 90,	--	Prince			10				 9					125%			Emperor
			[5] 	=		 80,	--	King			10				 8					150%			Deity
			[6]		=		 70		--	Emperor			 8				 7				possibly 175%		n/a, "Deity +1"
}
-- The values for in the "MM EVENTS %" column are *intentionally* different than the adjustments made by the game to Health/Materials box sizes

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
local function confirmLoad ()
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " loaded successfully")
	log.info("")
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function adjustForDifficulty (inputValue, tribe, higherIsAdvantageous)
	log.trace()
	-- Note: "higherIsAdvantageous" means advantageous from the perspective of *that tribe*, not from the perspective of the human player
	-- Due to the values within DIFFICULTY_LEVEL_PERCENT, an inputValue of 1 will always evaluate to an outputValue of 1 regardless of difficulty level
	-- Therefore, this function will not always be called when inputValue is known (guaranteed) to be 1
	local outputValue = nil
	if tribe.isHuman == true then
		outputValue = inputValue
	else
		if higherIsAdvantageous == true then
			outputValue = round(inputValue / (DIFFICULTY_LEVEL_PERCENT[civ.game.difficulty] / 100))
		else
			outputValue = round(inputValue * (DIFFICULTY_LEVEL_PERCENT[civ.game.difficulty] / 100))
		end
	end
	if tribe.active == false then
		local info = debug.getinfo(1, "Sn")
		log.warning("WARNING: " .. string.gsub(string.match(string.gsub(info.source, "@", ""), ".*\\(.*)"), ".lua", ".") .. info.name .. " called for " .. tribe.name .. " which is not an active tribe.")
	end
	return outputValue
end

local function displayHighDifficultyLevelInstructions ()
	log.trace()
	if db.gameData.AI_DIFFICULTY_LEVEL > 5 then
		uiutil.messageDialog("Game Concept: Emperor Difficulty", "Congratulations, you have selected to play Medieval Millennium at its highest difficulty level! As documented in 'Readme-Emperor.txt', support for this level in Civilization II: Test of Time is limited, and therefore some additional steps on your part are required in order to create valid saved game files.||1. First, please note that any saved games created automatically by the game ('auto-saves') will crash Civilization II if you attempt to load them.||2. Before you manually save a game, every time, press [Ctrl]-[Shift]-[S] to temporarily downgrade your difficulty level to one that can be stored safely within a saved game file. Don't worry, you can keep playing immediately after this and your chosen difficulty level of 'Emperor' will be restored promptly (and invisibly) by events, before further game action takes place. The level of 'Emperor' will also be restored if you reload the saved game file and start playing.||3. Never save a game by selecting 'Game' in the menubar at the top of the screen and then selecting the option that says 'Press Ctrl+S to Save Game'. Instead, follow those instructions and use the [Ctrl]-[S] keyboard combination instead to bring up the save game dialog box. This provides an extra level of security for you: if you ever forget step #2 and save a game by pressing [Ctrl]-[S] WITHOUT pressing [Ctrl]-[Shift]-[S] first, a dialog box will warn you that the saved game file you just created is invalid. However, this warning is only available when the save is triggered by the [Ctrl]-[S] keyboard combination||Have fun -- and good luck!",640)
	end
end

-- This is also called from within setOrConfirmValidDifficultyForSave() and must be defined prior to it within this file:
local function preventCrashOnSave ()
	log.trace()
	if civ.game.difficulty > 5 then
		log.action("Changed game difficulty level from " .. DIFFICULTY_LEVEL_NAME[civ.game.difficulty] .. " (" .. civ.game.difficulty .. ") to " .. DIFFICULTY_LEVEL_NAME[5] .. " (5) to prevent game crash when saving")
		civ.game.difficulty = 5
		db.gameData.AI_DIFFICULTY_LEVEL_INVALID = true
	end
end

local function restoreHighDifficultyLevel ()
	log.trace()
	if db.gameData.AI_DIFFICULTY_LEVEL == nil then
		db.gameData.AI_DIFFICULTY_LEVEL = civ.game.difficulty
		log.update("Documented current game difficulty level of " .. DIFFICULTY_LEVEL_NAME[civ.game.difficulty] .. " (" .. civ.game.difficulty .. ")")
	elseif civ.game.difficulty < db.gameData.AI_DIFFICULTY_LEVEL then
		civ.game.difficulty = db.gameData.AI_DIFFICULTY_LEVEL
		log.action("Restored game difficulty level of " .. DIFFICULTY_LEVEL_NAME[civ.game.difficulty] .. " (" .. civ.game.difficulty .. ")")
	end
	db.gameData.AI_DIFFICULTY_LEVEL_INVALID = false
end

local function setOrConfirmValidDifficultyForSave (keyCode)
	log.trace()
	if keyCode == 595 then	-- Ctrl-S
		if db.gameData.AI_DIFFICULTY_LEVEL_INVALID == true then
			uiutil.messageDialog("Game Concept: Emperor Difficulty", "The game you just saved (or attempted to save) is not valid and will cause the game to crash when reloaded!||You must press [Ctrl]-[Shift]-[S] FIRST, and then save your game, in order to create a valid save file.||As a reminder, auto-saves created by the game itself are also not valid when played at this difficulty level.", 450)
			civ.game.difficulty = db.gameData.AI_DIFFICULTY_LEVEL
		end
	elseif keyCode == 851 then	-- Ctrl-Shift-S
		if civ.game.difficulty > 5 then
			preventCrashOnSave()
			db.gameData.AI_DIFFICULTY_LEVEL_INVALID = false
			uiutil.messageDialog("Game Concept: Emperor Difficulty", "Successfully downgraded difficulty level in order to create valid saved game. Please save your game by pressing [Ctrl]-[S] IMMEDIATELY after you close this dialog box, before taking any other game actions.||Difficulty level will be restored to '" .. DIFFICULTY_LEVEL_NAME[db.gameData.AI_DIFFICULTY_LEVEL] .. "' once you resume playing, or if you reload this saved game file.", 450)
		end
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 10

return {
	confirmLoad = confirmLoad,

	adjustForDifficulty = adjustForDifficulty,
	displayHighDifficultyLevelInstructions = displayHighDifficultyLevelInstructions,
	preventCrashOnSave = preventCrashOnSave,
	restoreHighDifficultyLevel = restoreHighDifficultyLevel,
	setOrConfirmValidDifficultyForSave = setOrConfirmValidDifficultyForSave,
}
