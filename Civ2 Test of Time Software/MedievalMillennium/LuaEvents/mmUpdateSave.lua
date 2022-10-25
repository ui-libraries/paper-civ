-- mmUpdateSave.lua
-- by Knighttime

log.trace()

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
local function confirmLoad ()
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " loaded successfully")
	log.info("")
end

-- ===========================================================
-- ••••••••••••••• STRICTLY INTERNAL FUNCTIONS •••••••••••••••
-- ===========================================================
local function increment (saveMajorVersion, saveMinorVersion, savePointRelease)
	log.trace()

	if saveMajorVersion == 0 and saveMinorVersion < 8 then
		log.error("ERROR! Could not find valid update logic for v" .. saveMajorVersion .. "." .. saveMinorVersion .. "." .. savePointRelease .. ". This saved game is not compatible with your currently installed version of Medieval Millennium. Do not proceed to play, as errors are almost certain to occur.")
	end

	return false, saveMajorVersion, saveMinorVersion, savePointRelease
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function updateSavedGame ()
	log.trace()

	local previousLogLevel = log.getLogLevel()
	log.setLogLevel(log.EnumLogLevel.Update)

	-- Convert to db.gameData structure:
	-- This check happens before/without comparing version numbers, because it's required in order for the version number comparison to work
	if db.gameData == nil and db.game ~= nil then
		db.gameData = { }
		for k,v in pairs(db.game) do
			db.gameData[k] = v
		end
		db.game = nil
	end

	-- Note that db.gameData.MM_VERSION and MEDIEVAL_MILLENNIUM_VERSION are stored as strings, not decimals, in order to support versioning such as 1.0.12
	local saveMajorVersion = 0
	local saveMinorVersion = 0
	local savePointRelease = 0
	if db.gameData.MM_VERSION ~= nil then
		local data = db.gameData.MM_VERSION:split("%.")
		if data[1] ~= nil and data[1] ~= "" then saveMajorVersion = tonumber(data[1]) end
		if data[2] ~= nil and data[2] ~= "" then saveMinorVersion = tonumber(data[2]) end
		if data[3] ~= nil and data[3] ~= "" then savePointRelease = tonumber(data[3]) end
	end
	db.gameData.MM_VERSION = tostring(saveMajorVersion) .. "." .. tostring(saveMinorVersion) .. "." .. tostring(savePointRelease)

	local currentMajorVersion = 0
	local currentMinorVersion = 0
	local currentPointRelease = 0
	if MEDIEVAL_MILLENNIUM_VERSION ~= nil then
		local data = MEDIEVAL_MILLENNIUM_VERSION:split("%.")
		if data[1] ~= nil and data[1] ~= "" then currentMajorVersion = tonumber(data[1]) end
		if data[2] ~= nil and data[2] ~= "" then currentMinorVersion = tonumber(data[2]) end
		if data[3] ~= nil and data[3] ~= "" then currentPointRelease = tonumber(data[3]) end
	end
	MEDIEVAL_MILLENNIUM_VERSION = tostring(currentMajorVersion) .. "." .. tostring(currentMinorVersion) .. "." .. tostring(currentPointRelease)

	if saveMajorVersion == currentMajorVersion and saveMinorVersion == currentMinorVersion and savePointRelease == currentPointRelease then
		log.info("Saved game was created with Medieval Millennium v" .. db.gameData.MM_VERSION .. ", matching current installation v" .. MEDIEVAL_MILLENNIUM_VERSION)
	elseif saveMajorVersion ~= 1 and saveMinorVersion ~= 0 and savePointRelease ~= 0 and
		   ( saveMajorVersion > currentMajorVersion or
			 (saveMajorVersion == currentMajorVersion and saveMinorVersion > currentMinorVersion) or
			 (saveMajorVersion == currentMajorVersion and saveMinorVersion == currentMinorVersion and savePointRelease > currentPointRelease) ) then
		log.error("ERROR! Saved game has a later version of Medieval Millennium than your current installation. Unable to back-port save file to current game version. Please update your current installation to at least v" .. db.gameData.MM_VERSION .. " in order to continue playing this saved game.")
	else
		log.update("Checking for update from v" .. db.gameData.MM_VERSION .. " to v" .. MEDIEVAL_MILLENNIUM_VERSION .. " ...")
		local success = true
		while
			success == true and
			( saveMajorVersion < currentMajorVersion or
			  (saveMajorVersion == currentMajorVersion and saveMinorVersion < currentMinorVersion) or
			  (saveMajorVersion == currentMajorVersion and saveMinorVersion == currentMinorVersion and savePointRelease < currentPointRelease) or
			  (saveMajorVersion == 1 and saveMinorVersion == 0 and savePointRelease == 0) )
		do
			success, saveMajorVersion, saveMinorVersion, savePointRelease = increment(saveMajorVersion, saveMinorVersion, savePointRelease)
		end
		-- Even if success = false, that doesn't mean there was an error, only that the current saved game version does not require an update
		if success == false then
			log.update("No update found for v" .. saveMajorVersion .. "." .. saveMinorVersion .. "." .. savePointRelease)
			saveMajorVersion = currentMajorVersion
			saveMinorVersion = currentMinorVersion
			savePointRelease = currentPointRelease
		end
	end

	if saveMajorVersion == currentMajorVersion and saveMinorVersion == currentMinorVersion and savePointRelease == currentPointRelease then
		db.gameData.MM_VERSION = MEDIEVAL_MILLENNIUM_VERSION
		log.update("Registered active game as v" .. MEDIEVAL_MILLENNIUM_VERSION)
	else
		log.error("ERROR! Unable to update saved game from v" .. db.gameData.MM_VERSION .. " to v" .. MEDIEVAL_MILLENNIUM_VERSION .. " -- events are unlikely to work correctly if you proceed!")
	end

	log.setLogLevel(previousLogLevel)
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 6

return {
	confirmLoad = confirmLoad,

	updateSavedGame = updateSavedGame,
}
