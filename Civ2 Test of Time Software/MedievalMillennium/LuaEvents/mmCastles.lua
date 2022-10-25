-- mmCastles.lua
-- by Knighttime

log.trace()

constant.mmCastles = { }
constant.mmCastles.CITIES_DATA_FILE_NAME = "CitiesMM.txt"		-- File name in the scenario folder where the game will store the version of the Cities.bmp file that is currently installed
constant.mmCastles.CITIES_IMAGE_FILE_FOLDER = "Resources"		-- Folder beneath the scenario folder where the full library of available Cities.bmp files reside

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
local function convertCastleTerrainImprovementToUnit (tribe, unitTypeToCreate)
	log.trace()
	local startTimestamp = os.clock()
	local castlesFound = 0
	local Barbarians = civ.getTribe(0)
	for tile in tileutil.iterateTiles() do
		if tile.improvements & 0x42 == 0x40 then
			if tile.owner == tribe then
				-- Convert castles last occupied by the tribe:
				tileutil.removeFortress(tile)
				-- Not necessary to run updateMapView() since the tribe will receive a unit on that tile
				local castleUnit = unitutil.createByType(unitTypeToCreate, tribe, tile)
				-- The new castle unit does not have any "order"; it deliberately is not fortified
				-- However, all new castles are created as veterans, since this prevents them from becoming veterans by surviving a battle (that produces a nonsensical popup message,
				--		and (coupled with a higher base defense) also increases their defense stat to a point where some AI projectiles refuse to attack it)
				castleUnit.veteran = true
				castlesFound = castlesFound + 1
			elseif tile.owner == Barbarians then
				-- Remove or convert castles last occupied by Barbarians:
				tileutil.removeFortress(tile)
				-- Unlike AI or human tribes, a Barbarian castle is only converted to a unit if it is *currently* defended by barbarians,
				--		not if they are simply the owner of the tile (last tribe to occupy it)
				if tile.defender == Barbarians then
					local castleUnit = unitutil.createByType(unitTypeToCreate, Barbarians, tile)
					-- The new castle unit does not have any "order"; it deliberately is not fortified
					-- However, all new castles are created as veterans, since this prevents them from becoming veterans by surviving a battle (that produces a nonsensical popup message,
					--		and (coupled with a higher base defense) also increases their defense stat to a point where some AI projectiles refuse to attack it)
					castleUnit.veteran = true
				else
					updateMapView(tile, Barbarians)
				end
				-- Not incrementing castlesFound, since that is considered to be castlesFound for the tribe sent as a parameter
			end
		end
	end
	log.info("convertCastleTerrainImprovementToUnit() completed in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")
	return castlesFound
end

local function getCorrectCitiesFile ()
	log.trace()
	local castleStyleCode = {
		"MB",
		"SC",
		"BF"
	}
	local cityStyleCode = {
		Visigothic = "SW",
		Frankish = "CE",
		German = "CE",
		Saxon = "NW",
		Bavarian = "CE",
		Burgundian = "CE",
		Lombard = "CE",
		Danish = "NW",
		Norman = "NW",
		Sicilian = "SW",
		Castilian = "SW",
		Aquitanian = "NW",
		Portuguese = "SW",
		French = "NW",
		Venetian = "EA",
		Aragonese = "SW",
		Scottish = "NW",
		Hungarian = "EA",
		Genovese = "SW",
		Bohemian = "EA",
		Polish = "EA",
	}
	local humanTribe = civ.getPlayerTribe()
	local humanCastleLevel = db.tribeData[humanTribe.id].castleLevel or 1
	local correctCitiesFile = "Cities" .. castleStyleCode[humanCastleLevel] .. (cityStyleCode[humanTribe.adjective] or "NW") .. ".bmp"
	log.info("correctCitiesFile = " .. correctCitiesFile)
	return correctCitiesFile
end

local function getInstalledCitiesFile ()
	log.trace()
	local citiesDataFilePath = constant.events.SCENARIO_INSTALLATION_PATH .. constant.mmCastles.CITIES_DATA_FILE_NAME
	local citiesFileInstalled = ""
	local fileContents = { }
	for line in io.lines(citiesDataFilePath) do
		table.insert(fileContents, line)
	end
	citiesFileInstalled = fileContents[1]
	log.info("citiesFileInstalled = " .. tostring(citiesFileInstalled))
	return citiesFileInstalled
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
-- This is also called internally by clearCastleOrders() and newCastlesBuilt() and must be defined prior to them in this file:
local function isCastleUnitType (unittype)
	log.trace()
	local isCastle = false
	if unittype == MMUNIT.MotteandBailey or
	   unittype == MMUNIT.StoneCastle then
		isCastle = true
	end
	return isCastle
end

local function clearCastleUnitOrders ()
	log.trace()
	for unit in civ.iterateUnits() do
		if isCastleUnitType(unit.type) then
			unitutil.clearOrders(unit)
		end
	end
end

local function deleteAllCastleUnitsInCities ()
	log.trace()
	for unit in civ.iterateUnits() do
		if isCastleUnitType(unit.type) and unit.location.city ~= nil then
			unitutil.deleteUnit(unit)
		end
	end
end

-- This is also called internally by convertCastlesToUnits() and must be defined prior to it in this file:
local function installCorrectCitiesFile ()
	log.trace()
	local correctCitiesFile = getCorrectCitiesFile()
	if getInstalledCitiesFile() ~= correctCitiesFile then
		local sourcePath = constant.events.SCENARIO_INSTALLATION_PATH
		if constant.mmCastles.CITIES_IMAGE_FILE_FOLDER ~= nil then
			sourcePath = sourcePath .. constant.mmCastles.CITIES_IMAGE_FILE_FOLDER .. "\\"
		end
		sourcePath = sourcePath .. correctCitiesFile
		local targetPath = constant.events.SCENARIO_INSTALLATION_PATH .. "Cities.bmp"
		local osCommand = "copy \"" .. sourcePath .. "\" \"" .. targetPath .. "\""
		local result, errorMessage = os.execute(osCommand)
		if result == true then
			log.action("Executed OS command: " .. osCommand)
			if civ.getTurn() > 1 then
				uiutil.messageDialog("Medieval Millennium", "One or more scenario graphics files have been updated. Please save your game and then reload the saved game to continue playing.")
			end
			local citiesDataFilePath = constant.events.SCENARIO_INSTALLATION_PATH .. constant.mmCastles.CITIES_DATA_FILE_NAME
			local out = io.open(citiesDataFilePath, "w")
			out:write(correctCitiesFile)
			out:close()
			log.action("Updated " .. citiesDataFilePath)
		else
			log.error("ERROR! Command did not execute successfully: " .. osCommand .. " (Result: " .. errorMessage .. ")")
		end
	end
end

local function convertCastlesToUnits (tribe)
	log.trace()
	local tribeCastleLevel = db.tribeData[tribe.id].castleLevel or 1
	if tribeCastleLevel == 1 and civ.hasTech(tribe, techutil.findByName("Stone Castles", true)) then
		local castlesFound = convertCastleTerrainImprovementToUnit(tribe, MMUNIT.MotteandBailey)
		db.tribeData[tribe.id].castleLevel = 2
		if tribe.isHuman then
			if castlesFound > 0 then
				uiutil.messageDialog("Stone Castles", "With the acquisition of Stone Castle technology, your advisors regretfully inform you that the existing Motte and Bailey castles in your territory are outdated. These have been converted to Motte and Bailey units, and the castle terrain improvement has been removed from each location. You will need to rebuild new Stone Castles where appropriate.", 500)
			end
			installCorrectCitiesFile()
		end
	end
	if tribeCastleLevel == 2 and civ.hasTech(tribe, techutil.findByName("Corned Gunpowder", true)) then
		local castlesFound = convertCastleTerrainImprovementToUnit(tribe, MMUNIT.StoneCastle)
		local motteandBaileyDeleted = 0
		for unit in civ.iterateUnits() do
			if unit.type == MMUNIT.MotteandBailey and unit.owner == tribe then
				unitutil.deleteUnit(unit)
				motteandBaileyDeleted = motteandBaileyDeleted + 1
			end
		end
		db.tribeData[tribe.id].castleLevel = 3
		if tribe.isHuman then
			if castlesFound > 0 then
				uiutil.messageDialog("Bastion Fortresses", "With the acquisition of Corned Gunpowder technology, your advisors regretfully inform you that the existing Stone Castles in your territory are outdated. These have been converted to Stone Castle units, and the castle terrain improvement has been removed from each location. You will need to rebuild new Bastion Fortress castles where appropriate.", 500)
			end
			if motteandBaileyDeleted > 0 then
				uiutil.messageDialog("Motte and Bailey", "As castle technology continues to advance, the old Motte and Bailey castles remaining in your territory have crumbled away. These units have been removed from the game.", 500)
			end
			installCorrectCitiesFile()
		end
	end
end

local function newCastlesBuilt ()
	log.trace()
	local startTimestamp = os.clock()
	for tile in tileutil.iterateTiles() do
		if tile.improvements & 0x42 == 0x40 then
			for unit in tile.units do
				if isCastleUnitType(unit.type) then
					unitutil.deleteUnit(unit)
					if unit.owner.isHuman == true then
						civ.ui.centerView(tile)
						uiutil.messageDialog("Castle Construction", "The new castle that has been completed at " .. tile.x .. "," .. tile.y .. " has replaced the old " .. unit.type.name .. " at that location.", 400)
					end
				end
			end
			if tileutil.getTerrainId(tile) == MMTERRAIN.Monastery then
				-- It is not permitted for a human or AI tribe to build a castle on a monastery tile!
				local messageText = "Removing castle on a Monastery tile at " .. tile.x .. "," .. tile.y
				local guiltyTribe = tile.defender
				if guiltyTribe ~= nil then
					messageText = "Removing castle built by " .. guiltyTribe.name .. " on a Monastery tile at " .. tile.x .. "," .. tile.y
				end
				log.action(messageText)
				tileutil.removeFortress(tile)
				if guiltyTribe ~= nil then
					updateMapView(tile, guiltyTribe)
					if guiltyTribe.isHuman == true then
						civ.ui.centerView(tile)
						uiutil.messageDialog("Head Abbot","You should be ashamed of yourself, Sire! Monastery land belongs to the church, and you are not permitted to authorize castle construction there! Consider yourself fortunate that we are allowing your workers at " .. tile.x .. "," .. tile.y .. " to go free rather than turning them over to church authorities for prosecution!", 400)
					end
				end
			end
		end
	end
	log.info("newCastlesBuilt() completed in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 11

return {
	confirmLoad = confirmLoad,

	isCastleUnitType = isCastleUnitType,
	clearCastleUnitOrders = clearCastleUnitOrders,
	deleteAllCastleUnitsInCities = deleteAllCastleUnitsInCities,
	installCorrectCitiesFile = installCorrectCitiesFile,
	convertCastlesToUnits = convertCastlesToUnits,
	newCastlesBuilt = newCastlesBuilt,
}
