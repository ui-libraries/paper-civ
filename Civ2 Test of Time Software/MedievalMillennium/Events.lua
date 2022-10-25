-- Events.lua
-- Medieval Millennium, by Knighttime

-- ===========================================================
-- ••••••••••••••• MEDIEVAL MILLENNIUM VERSION •••••••••••••••
-- ===========================================================
MEDIEVAL_MILLENNIUM_VERSION = "1.0.0"
MEDIEVAL_MILLENNIUM_DATE = "2020-11-20"
REQUIRED_TOTPP_VERSION = "0.15.1"

-- ==============================================
-- ••••••••••••••• CONSOLE HEADER •••••••••••••••
-- ==============================================
print("========================================")
print("Medieval Millennium v" .. MEDIEVAL_MILLENNIUM_VERSION .. " (" .. MEDIEVAL_MILLENNIUM_DATE .. "), by Knighttime")
print("")
print("For Civilization II: Test of Time")
print("Requires TOTPP v" .. REQUIRED_TOTPP_VERSION .. ", by TheNamelessOne")
print("")
print("========================================")

-- =========================================
-- ••••••••••••••• CONSTANTS •••••••••••••••
-- =========================================
-- This provides a place for all external modules to register their constants, so they can be reviewed easily in a single table
-- This configuration makes all constants global, which means that they can be referenced in any module once defined
-- These constants are *not* stored as part of a saved game, however
constant = { }
constant.events = { }
constant.events.ADMINISTRATOR_MODE = false
constant.events.COASTAL_CITY_WATER_BODY_MIN = 21			-- There are 21 tiles in a city radius and this is set to match that
constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR = 2

-- ==============================================
-- ••••••••••••••• LUA FILE PATHS •••••••••••••••
-- ==============================================
constant.events.LUA_FOLDER = "LuaEvents"
local eventsPath = string.gsub(debug.getinfo(1, "S").source, "@", "")
print("Events file found: " .. eventsPath)
constant.events.SCENARIO_INSTALLATION_PATH = string.gsub(eventsPath, "events.lua", "")
local luaMainPath = string.gsub(eventsPath, "events.lua", "?.lua")
local appendedPackagePath = false
if string.find(package.path, luaMainPath, 1, true) == nil then
	package.path = package.path .. ";" .. luaMainPath
	appendedPackagePath = true
	print("Appended path: " .. luaMainPath)
end
if constant.events.LUA_FOLDER ~= nil and constant.events.LUA_FOLDER ~= "" and constant.events.LUA_FOLDER ~= "." then
	local luaAdditionalFilePath = string.gsub(luaMainPath, "?.lua", constant.events.LUA_FOLDER .. "\\?.lua")
	if string.find(package.path, luaAdditionalFilePath, 1, true) == nil then
		package.path = package.path .. ";" .. luaAdditionalFilePath
		appendedPackagePath = true
		print("Appended path: " .. luaAdditionalFilePath)
	end
end
print("")

-- ==================================================
-- ••••••••••••••• EXTERNAL LIBRARIES •••••••••••••••
-- ==================================================
-- These are global declarations, not local (with one exception), so these utility libraries can be used seamlessly within custom external modules
linesOfLuaCode = 0

-- Utility library created by TheNamelessOne:
-- In Medieval Millennium, this is only used for the serialization functions called by civ.scen.onLoad() and civ.scen.onSave()
-- Therefore this is a local variable, since it is never referenced outside of this file
local civlua = require("civlua")
linesOfLuaCode = linesOfLuaCode + 210

-- Utility libraries created by Knighttime:
package.loaded["log"] = nil				log			= require("log")
	log.addPathToTrim(constant.events.SCENARIO_INSTALLATION_PATH)
	log.setLogLevel(log.EnumLogLevel.Action)
	log.setAlertLevel(log.EnumLogLevel.Error)										log.confirmLoad(1.00)
package.loaded["globalfunc"] = nil		globalfunc	= require("globalFunctions")	globalfunc.confirmLoad(1.00)
package.loaded["cityutil"] = nil		cityutil	= require("utilCity")			cityutil.confirmLoad(1.00)
package.loaded["uiutil"] = nil			uiutil		= require("utilCivUI")			uiutil.confirmLoad(1.00)
package.loaded["imputil"] = nil			imputil		= require("utilImprovement")	imputil.confirmLoad(1.00)
package.loaded["techutil"] = nil		techutil	= require("utilTech")			techutil.confirmLoad(1.00)
package.loaded["tileutil"] = nil		tileutil	= require("utilTile")			tileutil.confirmLoad(0.80)
package.loaded["tribeutil"] = nil		tribeutil	= require("utilTribe")			tribeutil.confirmLoad(1.00)
package.loaded["unitutil"] = nil		unitutil	= require("utilUnit")			unitutil.confirmLoad(1.00)
package.loaded["wonderutil"] = nil		wonderutil	= require("utilWonder")			wonderutil.confirmLoad(1.00)
local utilityLibraryLinesOfLuaCode = linesOfLuaCode

log.info("@ events.(root)")
log.info("  Lines of Lua code found in utility libraries: " .. utilityLibraryLinesOfLuaCode)
log.info("")

-- ===========================================
-- ••••••••••••••• PERSISTENCE •••••••••••••••
-- ===========================================
-- These are global declarations, not local, so this table and functions can be used seamlessly within custom external modules
db = { }
function retrieve (key)
	if db[key] == nil then
		return { }
	else
		return db[key]
	end
end
function store (key, value)
	db[key] = value
--	log.update("Stored db." .. key)
end

-- Values initialized here will be used in new games
-- When loading a saved game, values are pulled from the saved game file, and any values entered here are overwritten
db.gameData = { }
db.gameData.UNITS_TO_DELETE_IMMEDIATELY = { }
db.gameData.AI_DIFFICULTY_LEVEL = civ.game.difficulty
db.gameData.AI_DIFFICULTY_LEVEL_INVALID = false
db.gameData.ALERT_LEVEL = log.getAlertLevel()
db.gameData.LOG_LEVEL = log.getLogLevel()
db.gameData.MM_VERSION = MEDIEVAL_MILLENNIUM_VERSION
db.gameData.YEARS_PER_TURN = civ.scen.params.yearIncrement

-- Common db tables that may be shared by multiple modules
db.cityData = { }
db.tileData = { }
db.tribeData = { }
--db.turnData = { }		-- placeholder for future revisions, not implemented yet
--db.unitData = { }		-- placeholder for future revisions, not implemented yet

log.update("  @ events.(root)")
log.update("Created 'db' table for persistent storage")
log.update("")

-- ================================================
-- ••••••••••••••• EXTERNAL MODULES •••••••••••••••
-- ================================================
-- Custom external modules for Medieval Millennium, which contain the bulk of the Lua code for this scenario
package.loaded["mmAliases"] = nil			local mmAliases			= require("mmAliases")			mmAliases.confirmLoad()
package.loaded["mmAwareness"] = nil			local mmAwareness		= require("mmAwareness")		mmAwareness.confirmLoad()
package.loaded["mmBarbarians"] = nil		local mmBarbarians		= require("mmBarbarians")		mmBarbarians.confirmLoad()
package.loaded["mmCastles"] = nil			local mmCastles			= require("mmCastles")			mmCastles.confirmLoad()
package.loaded["mmDifficulty"] = nil		local mmDifficulty		= require("mmDifficulty")		mmDifficulty.confirmLoad()
package.loaded["mmGovernments"] = nil		local mmGovernments		= require("mmGovernments")		mmGovernments.confirmLoad()
package.loaded["mmImproveWonders"] = nil	local mmImproveWonders	= require("mmImproveWonders")	mmImproveWonders.confirmLoad()
package.loaded["mmPlagues"] = nil			local mmPlagues			= require("mmPlagues")			mmPlagues.confirmLoad()
package.loaded["mmRangedUnits"] = nil		local mmRangedUnits		= require("mmRangedUnits")		mmRangedUnits.confirmLoad()
package.loaded["mmResearch"] = nil			local mmResearch		= require("mmResearch")			mmResearch.confirmLoad()
package.loaded["mmSurvivors"] = nil			local mmSurvivors		= require("mmSurvivors")		mmSurvivors.confirmLoad()
package.loaded["mmTerrain"] = nil			local mmTerrain			= require("mmTerrain")			mmTerrain.confirmLoad()
package.loaded["mmUnits"] = nil				local mmUnits			= require("mmUnits")			mmUnits.confirmLoad()
package.loaded["mmUpdateSave"] = nil		local mmUpdateSave		= require("mmUpdateSave")		mmUpdateSave.confirmLoad()
package.loaded["mmVeterancy"] = nil			local mmVeterancy		= require("mmVeterancy")		mmVeterancy.confirmLoad()

log.info("@ events.(root)")
log.info("  Lines of Lua code found in custom external modules: " .. (linesOfLuaCode - utilityLibraryLinesOfLuaCode))
log.info("")

-- ================================================
-- ••••••••••••••• GLOBAL FUNCTIONS •••••••••••••••
-- ================================================
-- These functions are declared as global, not local, so they can be used seamlessly within custom external modules

-- Map local module references to global variables to enable seamless cross-module referencing:
adjustForDifficulty = mmDifficulty.adjustForDifficulty
assignConstitutionalMonarchyTechGroup = mmResearch.assignConstitutionalMonarchyTechGroup
getCostToMove = mmTerrain.getCostToMove
getExpectedHealthBenefitForCity = mmGovernments.getExpectedHealthBenefitForCity
humanIsSupreme = mmAwareness.humanIsSupreme
isCastleUnitType = mmCastles.isCastleUnitType
isCitySpecialistUnitType = mmImproveWonders.isCitySpecialistUnitType
isProjectileUnitType = mmRangedUnits.isProjectileUnitType
isSpecialistUnitType = mmImproveWonders.isSpecialistUnitType
updateMapView = mmAwareness.updateMapView

function canBuildUnitType (tribe, city, unittype)
-- It is assumed that tribe is always equal to city.owner
-- However, this function supports being called with ONLY a tribe and nil as the city, in which case it will determine whether
--		that tribe *in general* (i.e., any city) can build that unit type
	log.trace()
	local result = nil
	-- Gather info from external modules, since these cannot be called from mmUnits:
	if mmBarbarians.isBarbarianOnlyUnitType(unittype) == true or
	   mmCastles.isCastleUnitType(unittype) == true or
	   mmImproveWonders.isSpecialistUnitType(unittype) == true or
	   mmPlagues.isPlagueUnitType(unittype) == true or
	   mmRangedUnits.isProjectileUnitType(unittype) == true then
		result = false
	else
		-- All further rules are found within mmUnits:
		result = mmUnits.canBuildUnit(tribe, city, unittype)
	end
	return result
end

function changeCityHealth (city, quantity)
-- The significance of this function (as opposed to calling cityutil.changeFood directly) is that this also updates db.cityData
	log.trace()
	cityutil.changeFood(city, quantity, humanIsSupreme())
	if db.cityData[city.id] == nil then
		db.cityData[city.id] = { }
	end
	db.cityData[city.id].decimalSize = cityutil.getSizeAsDecimal(city, humanIsSupreme())
	log.update("Updated db.cityData[].decimalSize for " .. city.name)
end

function changeCitySize (city, amount)
-- The significance of this function (as opposed to calling cityutil.changeSize directly) is that this also updates db.cityData
	log.trace()
	local result = cityutil.changeSize(city, amount)
	if db.cityData[city.id] == nil then
		db.cityData[city.id] = { }
	end
	db.cityData[city.id].decimalSize = cityutil.getSizeAsDecimal(city, humanIsSupreme())
	log.update("Updated db.cityData[].decimalSize for " .. city.name)
	return result
end

function cityIsTrulyCoastal (city)
	log.trace()
	if city.coastal == false then
		return false
	else
		local largestAdjacentWaterBody = 0
		for _, adjTile in ipairs(tileutil.getAdjacentTiles(city.location, false)) do
			if civ.isTile(adjTile) and tileutil.isWaterTile(adjTile) then
				local waterBodySize = tileutil.getTerrainBodySize(adjTile, constant.events.COASTAL_CITY_WATER_BODY_MIN)
				if waterBodySize > largestAdjacentWaterBody then
					largestAdjacentWaterBody = waterBodySize
				end
			end
			if largestAdjacentWaterBody >= constant.events.COASTAL_CITY_WATER_BODY_MIN then
				break
			end
		end
		if largestAdjacentWaterBody >= constant.events.COASTAL_CITY_WATER_BODY_MIN then
			return true
		else
			return false
		end
	end
end

function clearCityData (city)
	log.trace()

	db.cityData[city.id] = nil
	log.update("Cleared db.cityData for city ID " .. city.id)

	for tileId, data in pairs(db.tileData) do
		if data.lastWorkedByCityId == city.id then
			db.tileData[tileId].lastWorkedByCityId = nil
			db.tileData[tileId].lastWorkedByCityName = nil
			db.tileData[tileId].lastWorkedByTribeId = nil
			log.update("Updated db.tileData.lastWorkedBy... data for tile ID " .. tileId)
		end
	end

	-- Each of the following modules is using its *own* storage for city data
	-- If/once each one is combined into sharing db.cityData[city.id] then it won't need its own method for clearing its city data storage
	mmImproveWonders.removeSpecialistsForCity(city)
	mmSurvivors.clearSurvivorDataForCity(city)
	mmVeterancy.clearUnitBuiltDataForCity(city)
end

function hasCastle (tile)
	log.trace()
	if tileutil.hasFortress(tile) == true or
	   unitutil.tileContainsUnitType(tile, MMUNIT.MotteandBailey) == true or
	   unitutil.tileContainsUnitType(tile, MMUNIT.StoneCastle) == true then
		return true
	else
		return false
	end
end

function isHumanUnitType (unittype)
	log.trace()
	local isHuman = nil
	if unittype.domain == domain.Land then
		if unittype == MMUNIT.Bakery or unittype == MMUNIT.Sawmill or unittype == MMUNIT.Forge then
			isHuman = false
		elseif unittype == MMUNIT.SiegeTower or unittype == MMUNIT.MotteandBailey or unittype == MMUNIT.StoneCastle then
			isHuman = false
		else
			-- Some ranged units are human, others are not, and there are also non-human land projectile units
			-- Utilize definitions stored in that module to make the correct determination
			isHuman = mmRangedUnits.isHumanRangedUnitType(unittype)
			if isHuman == nil then
				isHuman = true
			end
		end
	else
		-- All domain 1 (air) or domain 2 (sea) units are non-human:
		isHuman = false
	end
	return isHuman
end

function processPendingUnitDeletions ()
	log.trace()
	if #db.gameData.UNITS_TO_DELETE_IMMEDIATELY > 0 then
		for n = 1, #db.gameData.UNITS_TO_DELETE_IMMEDIATELY do
			unitutil.deleteUnit(db.gameData.UNITS_TO_DELETE_IMMEDIATELY[1])
			table.remove(db.gameData.UNITS_TO_DELETE_IMMEDIATELY, 1)
		end
	end
end

function setCitySize (city, sizeAsDecimal)
-- The significance of this function (as opposed to calling cityutil.setSizeAsDecimal directly) is that this also updates db.cityData
	log.trace()
	cityutil.setSizeAsDecimal(city, sizeAsDecimal, humanIsSupreme())
	if db.cityData[city.id] == nil then
		db.cityData[city.id] = { }
	end
	db.cityData[city.id].decimalSize = cityutil.getSizeAsDecimal(city, humanIsSupreme())
	log.update("Updated db.cityData[].decimalSize for " .. city.name)
end

function setTerrainType (tile, newTerrainId, redrawTileOverride)
-- The significance of this function (as opposed to calling tileutil.setTerrainId directly) is that this also updates db.tileData
	log.trace()
	local redrawTile = true
	if redrawTileOverride == false then
		redrawTile = false
	end
	tileutil.setTerrainId(tile, newTerrainId, MMTERRAIN, redrawTile)

	local tileId = tileutil.getTileId(tile)
	db.tileData[tileId].currentTerrainType = newTerrainId
	db.tileData[tileId].lastTerrainTypeChangeYear = civ.getGameYear()
	db.tileData[tileId].usageLevel = 0

	log.update("Updated db.tileData for " .. tile.x .. "," .. tile.y)
end

-- =======================================================
-- ••••••••••••••• LOCAL TRIGGER FUNCTIONS •••••••••••••••
-- =======================================================
local attackerTile = nil

local function getPreviousActiveTribeAndTurn (currentTribe, currentTribeTurn)
-- The previous tribe is the next *lower-numbered* one that is also active
-- Tribe 0, barbarians, is always active
-- The previous tribe to tribe 0 is the *highest-numbered* tribe that is also active, on the *previous* turn
	log.trace()
	local prevTribe = nil
	local prevTribeTurn = currentTribeTurn
	local startId = currentTribe.id - 1
	if startId >= 0 then
		for i = startId, 0, -1 do
			local tribe = civ.getTribe(i)
			if tribe ~= nil and tribe.active then
				prevTribe = tribe
				break
			end
		end
	end
	if prevTribe == nil then
		startId = 7
		prevTribeTurn = currentTribeTurn - 1
		for i = startId, 0, -1 do
			local tribe = civ.getTribe(i)
			if tribe ~= nil and tribe.active then
				prevTribe = tribe
				break
			end
		end
	end
	if prevTribe == nil then
		log.error("ERROR! getPreviousActiveTribeAndTurn() returned nil")
	end
	return prevTribe, prevTribeTurn
end

-- Declared now, defined later. This is necessary because the three onTribeTurn___ functions call each other with circular recursion
local onTribeTurnEnd

-- This function runs as early as possible in a given tribe's turn. This means the city processing phase has begun, and at least one city has already been processed
local function onTribeTurnBegin (tribe, turnNumber, source)
	log.trace()

	mmDifficulty.restoreHighDifficultyLevel()

	-- 1. If this function was already run for this tribe and turn, exit immediately:
	local turnHistory = retrieve("turnHistory")
	local tribeKey = "tribe" .. tribe.id
	local thisTurnHistory = turnHistory[turnNumber] or { }
	local thisTribeTurnHistory = thisTurnHistory[tribeKey] or { }
	if thisTribeTurnHistory.ttBegin == true then
		return
	end

	-- 2. If the previous function was not run, do so before proceeding:
	local prevTribe, prevTribeTurnNumber = getPreviousActiveTribeAndTurn(tribe, turnNumber)
	local prevTribeKey = "tribe" .. prevTribe.id
	local prevTurnHistory = turnHistory[prevTribeTurnNumber] or { }
	local prevTribeTurnHistory = prevTurnHistory[prevTribeKey] or { }
	if prevTribeTurnNumber >= 0 and prevTribeTurnHistory.ttEnd == nil then
		onTribeTurnEnd(prevTribe, prevTribeTurnNumber, source)
		turnHistory = retrieve("turnHistory")
		thisTurnHistory = turnHistory[turnNumber] or { }
		thisTribeTurnHistory = thisTurnHistory[tribeKey] or { }
	end

	-- 3. If this tribe was not previously known (to events) as being in the game, make necesary updates to initialize:
	if tribe.name ~= db.tribeData[tribe.id].name then
		log.update("Tribe " .. tribe.id .. " was formerly " .. db.tribeData[tribe.id].name .. " but they have been destroyed!")

		-- Clear data for previous tribe from db:
		db.tribeData[tribe.id] = nil
		mmSurvivors.clearSurvivorDataForTribe(tribe)

		-- Set up new tribe:
		db.tribeData[tribe.id] = { }
		db.tribeData[tribe.id].name = tribe.name
		log.update("Set name of tribe " .. tribe.id .. " to " .. tribe.name)

		techutil.grantTechByName(tribe, "Tribal Religion")
		tribe.government = 4
		log.action("Changed government of " .. tribe.name .. " to Tribal Monarchy")

		mmGovernments.initializeTreasury(tribe, true)

		-- A tribe "restart" will immediately trigger a recalculation of power ratings, including populations. This eliminates the need to clear out
		--		the old power rating data (with the old tribe name and score) since that data is overwritten by the new calculations.
		-- This should also cover the case of a civil war, unless the newly split-off tribe has the same name as a tribe that was *previously* in the game
		--		but was destroyed. (More specifically, has the same name as the most recent tribe *of that new color* to be previously in the game.
		--		However, the game logic should pick a tribe name that is intentionally NOT that of the most recent tribe to use the new color.)
		mmAwareness.storeTribePopulations(turnNumber, true)
		mmAwareness.calculatePowerRatings(turnNumber, true)
	end

	-- 4. Console output
	local consoleMessage = "Processing turn " .. turnNumber .. " BEGIN for tribe " .. tribe.id .. " (" .. tribe.name .. ") due to " .. source .. "..."
	log.action(consoleMessage)

	-- 5. CODE TO RUN AT THIS TIME

	mmUnits.setShipAttackRule(tribe, nil)

	-- 6. Document the fact that this function was run for this tribe, so we don't do so again
	thisTribeTurnHistory.ttBegin = true
	thisTurnHistory[tribeKey] = thisTribeTurnHistory
	turnHistory[turnNumber] = thisTurnHistory
	store("turnHistory", turnHistory)

end		-- end of function "onTribeTurnBegin()"

-- This function runs when a tribe's first unit is activated, which serves as the earliest notification that all city processing is complete:
local function onTribeTurnCitiesDone (tribe, turnNumber, source)
	log.trace()

	mmDifficulty.restoreHighDifficultyLevel()

	-- 1. If this function was already run for this tribe and turn, exit immediately:
	local turnHistory = retrieve("turnHistory")
	local tribeKey = "tribe" .. tribe.id
	local thisTurnHistory = turnHistory[turnNumber] or { }
	local thisTribeTurnHistory = thisTurnHistory[tribeKey] or { }
	if thisTribeTurnHistory.ttCitiesDone == true then
		return
	end

	-- 2. If the previous function was not run, do so before proceeding:
	if thisTribeTurnHistory.ttBegin == nil then
		onTribeTurnBegin(tribe, turnNumber, source)
		turnHistory = retrieve("turnHistory")
		thisTurnHistory = turnHistory[turnNumber] or { }
		thisTribeTurnHistory = thisTurnHistory[tribeKey] or { }
	end

	-- 3. Console output
	local consoleMessage = "Processing turn " .. turnNumber .. " AFTER CITIES for tribe " .. tribe.id .. " (" .. tribe.name .. ") due to " .. source .. "..."
	log.action(consoleMessage)

	-- 4. CODE TO RUN AT THIS TIME

	mmCastles.convertCastlesToUnits(tribe)
	mmCastles.deleteAllCastleUnitsInCities()

	if tribe.id == 0 then

		mmBarbarians.createInvaderCities()
		mmBarbarians.processInvaderCities()

	else

		mmGovernments.adjustProductionInPrimitiveMonarchy(tribe)
		mmGovernments.provideUnitSupportInConstitutionalMonarchy(tribe)
		mmGovernments.applyCelebratingCityEffects(tribe, turnNumber)
		mmGovernments.payRoyalPalaceUpkeep(tribe)
		mmGovernments.deductExpensesOrTithes(tribe)

		-- Because all cities have already been processed, under the government that the tribe had when the turn
		--		began, this is the last function within mmGovernments that will run here. If a tribe converts
		--		to Primitive Monarchy, the first processing (and running of the above functions) will take place
		--		at the beginning of *next* turn.
		mmGovernments.checkConversionToChristianity(tribe)

		mmBarbarians.spreadInvasionTech(tribe)

		mmImproveWonders.processCustomImproveWonderBenefits(tribe)
		mmImproveWonders.providePrereqsOrSpecialistsForAI(tribe)
		mmImproveWonders.removeFreeCityCharters(tribe)

		mmUnits.swapAllSiegeEngineersTowers(tribe)
		mmUnits.stackAttrition(tribe)

		--This should definitely run before managePeasantMilitia() so that the support cost of survivors is taken into account there
		mmSurvivors.createSurvivingUnits(tribe)

		mmUnits.managePeasantMilitia(tribe)

	end

	mmTerrain.convertTerrainForLargeCities(tribe)

	mmRangedUnits.fireImmobileOrCityUnits(tribe)

	-- 5. Document the fact that this function was run for this tribe, so we don't do so again
	thisTribeTurnHistory.ttCitiesDone = true
	thisTurnHistory[tribeKey] = thisTribeTurnHistory
	turnHistory[turnNumber] = thisTurnHistory
	store("turnHistory", turnHistory)
end

-- The definition of this function looks unusual because it is predefined above, to accommodate circular recursion
-- This function runs as soon as the beginning of the *following* tribe's turn begins, or else (for the last tribe) when onTurn() detects
--		that a new turn is beginning.
onTribeTurnEnd = function (tribe, turnNumber, source)
	log.trace()

	mmDifficulty.restoreHighDifficultyLevel()

	-- 1. If this function was already run for this tribe and turn, exit immediately:
	local turnHistory = retrieve("turnHistory")
	local tribeKey = "tribe" .. tribe.id
	local thisTurnHistory = turnHistory[turnNumber] or { }
	local thisTribeTurnHistory = thisTurnHistory[tribeKey] or { }
	if thisTribeTurnHistory.ttEnd == true then
		return
	end

	-- 2. If the previous function was not run, do so before proceeding:
	if thisTribeTurnHistory.ttCitiesDone == nil then
		onTribeTurnCitiesDone(tribe, turnNumber, source)
		turnHistory = retrieve("turnHistory")
		thisTurnHistory = turnHistory[turnNumber] or { }
		thisTribeTurnHistory = thisTurnHistory[tribeKey] or { }
	end

	-- 3. Console output
	local consoleMessage = "Processing turn " .. turnNumber .. " END for tribe " .. tribe.id .. " (" .. tribe.name .. ") due to " .. source .. "..."
	log.action(consoleMessage)

	-- Just in case:
	mmRangedUnits.resetAllUnitStats("events.onTribeTurnEnd", false)

	-- 4. CODE TO RUN AT THIS TIME
	processPendingUnitDeletions()

	mmBarbarians.disbandBarbariansLostAtSea()

	mmRangedUnits.destroyAllProjectiles()
	mmRangedUnits.clearHistoryForAllUnits()
	mmRangedUnits.provideProjectileSummary(tribe)

	mmGovernments.documentCitySizes(tribe)

	if tribe.id > 0 then
		mmResearch.unlockTechGroups(tribe)
	end

	mmTerrain.processTerrainTypeChanges(tribe)

	-- The following will catch units that aren't/can't be/weren't activated, most likely because they are immobile:
	mmVeterancy.applyIntendedVetStatusForTribeUnits(tribe)

	-- The following will block you from contriving to carry over a Siege Tower into the next player's turn, if it ought to revert to a Siege Engineer:
	mmUnits.swapAllSiegeEngineersTowers(tribe)

	-- 5. Document the fact that this function was run for this tribe, so we don't do so again
	thisTribeTurnHistory.ttEnd = true
	thisTurnHistory[tribeKey] = thisTribeTurnHistory
	turnHistory[turnNumber] = thisTurnHistory
	store("turnHistory", turnHistory)
end

-- =======================================================
-- ••••••••••••••• TRIGGER: onActivateUnit •••••••••••••••
-- =======================================================
function onActivateUnitFunction (unit, source)
	log.trace()

	local messageText = unit.owner.adjective .. " " .. unit.type.name .. " (" .. unit.id .. ") at " .. unit.x .. "," .. unit.y
	if (unit.order ~= nil and unit.order ~= -1) or unit.gotoTile ~= nil then
		if unit.order ~= nil and unit.order ~= 0x0C then
			messageText = messageText .. " (order = " .. tostring(unit.order)
		end
		if unit.gotoTile ~= nil then
			messageText = messageText .. ": GoTo " .. unit.gotoTile.x .. "," .. unit.gotoTile.y
		end
		if unit.order ~= nil and unit.order ~= 0x0C then
			messageText = messageText .. ")"
		end
	end
	log.info(messageText)

	onTribeTurnCitiesDone(unit.owner, civ.getTurn(), "onActivateUnit(tribe" .. unit.owner.id .. ")")

	processPendingUnitDeletions()

	mmGovernments.setKingsCrusadeExpiration(tribe)

	mmVeterancy.applyIntendedVetStatusForUnit(unit)
	mmUnits.setShipAttackRule(unit.owner, unit)
	mmUnits.swapSiegeEngineerTower(unit, true)

	local inputUnitContinuesTurn = mmRangedUnits.fireOrMove(unit, true)
	if inputUnitContinuesTurn then

		mmTerrain.processPeasantActivity(unit)
		mmTerrain.documentVisibleTiles(unit)

		mmBarbarians.fortifyDeleteOrMove(unit)

	end
end
civ.scen.onActivateUnit(function (unit, source)
	local messageText = unit.owner.adjective .. " " .. unit.type.name .. " (" .. unit.id .. ") at " .. unit.x .. "," .. unit.y
	if (unit.order ~= nil and unit.order ~= -1) or unit.gotoTile ~= nil then
		if unit.order ~= nil and unit.order ~= 0x0C then
			messageText = messageText .. " (order = " .. tostring(unit.order)
		end
		if unit.gotoTile ~= nil then
			messageText = messageText .. ": GoTo " .. unit.gotoTile.x .. "," .. unit.gotoTile.y
		end
		if unit.order ~= nil and unit.order ~= 0x0C then
			messageText = messageText .. ")"
		end
	end

	log.trace("onActivateUnit() trigger: " .. messageText)
	log.info()

	onActivateUnitFunction(unit, source)
end)

-- ====================================================
-- ••••••••••••••• TRIGGER: onBribeUnit •••••••••••••••
-- ====================================================
--	All normal unit bribing functionality or behavior is permitted
--	Note that some units are blocked from being bribed due to their attributes in rules.txt
-- civ.scen.onBribeUnit(function(unit, previousOwner)	end)	-- end of onBribeUnit

-- ===================================================
-- ••••••••••••••• TRIGGER: onCanBuild •••••••••••••••
-- ===================================================
civ.scen.onCanBuild(function (defaultBuildFunction, city, item)

	if city.id == -1 and civ.isUnitType(item) and item.id == 1 then
		return true
	end

	log.setPendingTriggerName("onCanBuild() trigger...")	-- (" .. city.name .. " / " .. item.name .. ")")

	-- Only run the following code for the FIRST one (or two) items in the Unit and Improvement lists, for efficiency:
	if item.id <= 1 then
		if city.owner.isHuman == true then
			onTribeTurnBegin(city.owner, civ.getTurn(), "onCanBuild(tribe" .. city.owner.id .. ")")
		end

		mmRangedUnits.resetAllUnitStats("events.onCanBuild / " .. city.name .. " / " .. item.name, false)
	end

	local result = nil
	if city.owner.id == 0 then
		result = defaultBuildFunction(city, item)
	else
		if civ.isUnitType(item) == true then
			result = canBuildUnitType(city.owner, city, item)
		elseif civ.isImprovement(item) == true then
			result = mmImproveWonders.canBuildImprovement(defaultBuildFunction, city, item)
		else
			result = mmImproveWonders.canBuildWonder(defaultBuildFunction, city, item)
		end
	end

	if result == nil then
		result = false
	end
	return result
end)	-- end of onCanBuild

-- ==========================================================
-- ••••••••••••••• TRIGGER: onCentauriArrival •••••••••••••••
-- ==========================================================
-- Centauri arrival has been repurposed as New World arrival, with normal game behavior
-- civ.scen.onCentauriArrival(function(tribe)	end)	-- end of onCentauriArrival

-- ========================================================
-- ••••••••••••••• TRIGGER: onCityDestroyed •••••••••••••••
-- ========================================================
civ.scen.onCityDestroyed(function(city)
	log.trace("onCityDestroyed() trigger...")
	log.info("  " .. city.owner.adjective .. " city of " .. city.name .. " has vanished")

	-- Since city IDs can be reused, delete any city ID references from db:
	clearCityData(city)
end)	-- end of onCityDestroyed

-- ======================================================
-- ••••••••••••••• TRIGGER: onCityFounded •••••••••••••••
-- ======================================================
civ.scen.onCityFounded(function(city)
	log.trace("onCityFounded() trigger...")
	local tribe = city.owner
	log.info("  City of " .. city.name .. " founded by " .. tribe.name .. " at " .. city.location.x .. "," .. city.location.y)

	-- The ID of this new city should not be referenced in db, if it was properly cleared out
	-- But just in case, we will do that again here:
	clearCityData(city)
	-- Then we will initialize db to store data for this new city:
	db.cityData[city.id] = { }

	-- The following event is written to accommodate for the defect mentioned above:
	mmTerrain.convertTerrainForNewCity(city)
end)	-- end of onCityFounded

-- =========================================================
-- ••••••••••••••• TRIGGER: onCityProduction •••••••••••••••
-- =========================================================
civ.scen.onCityProduction(function(city, prod)

	onTribeTurnBegin(city.owner, civ.getTurn(), "onCityProduction(tribe" .. city.owner.id .. ")")

	log.trace("onCityProduction() trigger...")

	local prodType = nil
	if civ.isUnit(prod) then prodType = prod.type else prodType = prod end
	log.info("  " .. city.owner.adjective .. " city of " .. city.name .. " produced " .. prodType.name)

	if civ.isUnit(prod) then
		local unit = prod

		mmRangedUnits.preventCityFromBuildingProjectile(city, unit)

		mmGovernments.documentPeasantBuilt(city, unit)
		mmGovernments.scheduleIncreasedPeasantHealthCost(city, unit)

		mmTerrain.provideMineWoodcutForAI(city, unit)

		-- This should run before documentUnitBuilt(), so that the vet chance is calculated based on *prior* units built
		mmVeterancy.documentIntendedVetStatus(city, unit)
		mmVeterancy.documentUnitBuilt(city, unit)

		-- Calling this after mmVeterancy, so that the message can report whether or not the unit is a veteran:
		mmAwareness.unitBuilt(city, unit)

	elseif civ.isImprovement(prod) then
		mmImproveWonders.improvementBuilt(city, prod)
	else	-- i.e., civ.isWonder(prod)
		mmImproveWonders.wonderBuilt(city, prod)
	end

end)	-- end of onCityProduction

-- ====================================================
-- ••••••••••••••• TRIGGER: onCityTaken •••••••••••••••
-- ====================================================
civ.scen.onCityTaken(function(city, previousOwner)
	log.trace("onCityTaken() trigger...")
	local conqueringUnit = city.owner.adjective
	for unit in city.location.units do
		conqueringUnit = conqueringUnit .. " " .. unit.type.name
	end
	log.info("  " .. previousOwner.adjective .. " city of " .. city.name .. " conquered by " .. conqueringUnit)

	mmRangedUnits.cityTakenByProjectile(city)

	mmImproveWonders.updateSpecialistsOnCityTaken(city)

	mmBarbarians.cityTakenByBarbarians(city, previousOwner)
	mmBarbarians.cityTakenFromBarbarians(city, previousOwner)

end)	-- end of onCityTaken

-- ===================================================
-- ••••••••••••••• TRIGGER: onGameEnds •••••••••••••••
-- ===================================================
-- Special game-end functionality is not necessary
-- civ.scen.onGameEnds(function(reason)	end)	-- end of onGameEnds

-- ===================================================
-- ••••••••••••••• TRIGGER: onKeyPress •••••••••••••••
-- ===================================================
local showNextKeyPress = -1
civ.scen.onKeyPress(function(keyCode)
	local onKeyPressMessage = "onKeyPress() trigger for key code " .. tostring(keyCode) .. "..."
	if showNextKeyPress >= 0 and showNextKeyPress <= 3 then
		print("Detected key code " .. tostring(keyCode))
		showNextKeyPress = showNextKeyPress + 1
	end
	if showNextKeyPress == 3 then
		showNextKeyPress = -1
	end

	-- [k] key is not used to fire ranged units, as in some other recent Lua scenarios, so display a message to that effect
	-- However, it *will* automate a settler-type unit; this is normal (default) Civ behavior and cannot be removed
	if keyCode == 75 then
		log.trace(onKeyPressMessage)
		log.info()
		local unit = civ.getActiveUnit()
		if unit ~= nil then
			if unit.type.role ~= 5 then
				uiutil.messageDialog("Game Concept: Ranged Units", "Unlike the behavior found in some other scenarios, pressing [k] within Medieval Millennium does not cause an active ranged unit to fire its projectile. Please see the \"Ranged Units\" entry in the Civilopedia (within \"Medieval Millennium Concepts\") for further information.", 450)
			end
		end
	end

	-- Num [*] available for testing purposes
	if keyCode == 170 then
--		log.trace(onKeyPressMessage)
--		log.info()
	end

	-- Num [+] available for testing purposes
	if keyCode == 171 then
--		log.trace(onKeyPressMessage)
--		log.info()
	end

	-- Num [-] available for testing purposes
	if keyCode == 173 then
--		log.trace(onKeyPressMessage)
--		log.info()
	end

	-- Num [/] available for testing purposes
	if keyCode == 175 then
--		log.trace(onKeyPressMessage)
--		log.info()
	end

	-- [F1] key has an overlay of city productivity not shown on the normal popup screen
	if keyCode == 176 then
		log.trace(onKeyPressMessage)
		log.info()
		mmImproveWonders.listNetHealthAndMaterials()
	end

	-- [F5] key has an overlay of national expenses not shown on the normal popup screen
	-- [Shift]-[t] has an overlay with a summary form of the same data
	-- Much of the code remains here because it combines data from several separate modules
	if keyCode == 180 or keyCode == 340 then
		log.trace(onKeyPressMessage)
		log.info()

		local f5messageText = "The following list contains additional Taxes, Research, and Maintenance Expenses that are the result of Medieval Millennium events, and therefore cannot be shown on the game's default display."
		local shiftTmessageText = ""
		local playerTribe = civ.getPlayerTribe()
		local incomeHeader = false

		-- A. Additional income
		local incomeTable = { }
		mmImproveWonders.getCustomImproveWonderBenefits(playerTribe, incomeTable)
		local govBonusGold = 0
		local govBonusScience = 0
		govBonusGold, govBonusScience = mmGovernments.getRateBonusesUnderPrimitiveMonarchy(playerTribe)
		if govBonusGold > 0 or govBonusScience > 0 then
			incomeTable[-1] = {
				name = MMGOVERNMENT[MMGOVERNMENT.PrimitiveMonarchy],
				tax = govBonusGold,
				research = govBonusScience
			}
		end
		local incomeHeader = false
		local totalIncome = 0
		for key = -1, 67 do
			if incomeTable[key] ~= nil then
				local thisIncome = (incomeTable[key].quantity or 1) * incomeTable[key].tax
				totalIncome = totalIncome + thisIncome
				if incomeHeader == false then
					f5messageText = f5messageText .. "||INCOME"
					incomeHeader = true
				end
				f5messageText = f5messageText .. "|"
				if incomeTable[key].quantity ~= nil and incomeTable[key].quantity > 0 then
					f5messageText = f5messageText .. tostring(incomeTable[key].quantity) .. " "
				end
				f5messageText = f5messageText .. incomeTable[key].name .. ": " .. thisIncome .. " gold"
				if incomeTable[key].research ~= nil and incomeTable[key].research > 0 then
					f5messageText = f5messageText .. ", " .. incomeTable[key].research .. " research"
				end
			end
		end

		-- B. Additional expenses
		local expenseTable = { }
		mmImproveWonders.getTotalSpecialistCosts(expenseTable)
		local royalPalaceUpkeep = mmGovernments.getRoyalPalaceUpkeep(playerTribe)
		if royalPalaceUpkeep > 0 then
			expenseTable[-1] = {
				name = MMIMP.RoyalPalace.name,
				cost = royalPalaceUpkeep
			}
		end
		local expenseHeader = false
		local totalExpense = 0
		for key = -1, civ.cosmic.numberOfUnitTypes do
			if expenseTable[key] ~= nil then
				local thisCost = (expenseTable[key].quantity or 1) * expenseTable[key].cost
				totalExpense = totalExpense + thisCost
				if expenseHeader == false then
					f5messageText = f5messageText .. "||EXPENSES"
					expenseHeader = true
				end
				f5messageText = f5messageText .. "|"
				if expenseTable[key].quantity ~= nil and expenseTable[key].quantity > 0 then
					f5messageText = f5messageText .. tostring(expenseTable[key].quantity) .. " "
				end
				f5messageText = f5messageText .. expenseTable[key].name .. " (Cost: " .. tostring(thisCost) .. " gold)"
			end
		end

		-- C. Net adjustment
		if totalIncome > 0 or totalExpense > 0 then
			local netChange = totalIncome - totalExpense

			f5messageText = f5messageText .. "|"
			if totalIncome > 0 then
				f5messageText = f5messageText .. "|Total Additional Income: " .. tostring(totalIncome) .. " gold"
			end
			if totalExpense > 0 then
				f5messageText = f5messageText .. "|Total Additional Expenses: " .. tostring(totalExpense) .. " gold"
			end
			if netChange >= 0 then
				f5messageText = f5messageText .. "|Net Adjustment: +" .. netChange .. " gold"
			else
				f5messageText = f5messageText .. "|Net Adjustment: " .. netChange .. " gold"
			end

			if totalExpense == 0 then
				shiftTmessageText = "Please note that there is additional income that is the result of Medieval Millennium events, and therefore could not be shown on the previous screen.|"
			elseif totalIncome == 0 then
				shiftTmessageText = "Please note that there are additional expenses that are the result of Medieval Millennium events, and therefore could not be shown on the previous screen.|"
			else
				shiftTmessageText = "Please note that both income and expenses are increased as a result of Medieval Millennium events, and these are not included in the numbers shown on the previous screen.|"
			end
			if totalIncome > 0 then
				shiftTmessageText = shiftTmessageText .. "|Total Additional Income: " .. tostring(totalIncome) .. " gold"
			end
			if totalExpense > 0 then
				shiftTmessageText = shiftTmessageText .. "|Total Additional Expenses: " .. tostring(totalExpense) .. " gold"
			end
			if totalIncome > 0 and totalExpense > 0 then
				if netChange >= 0 then
					shiftTmessageText = shiftTmessageText .. "|Net Adjustment: +" .. netChange .. " gold"
				else
					shiftTmessageText = shiftTmessageText .. "|Net Adjustment: " .. netChange .. " gold"
				end
			end
		end

		if keyCode == 180 and (govBonusScience > 0 or totalIncome > 0 or totalExpense > 0) then
			uiutil.messageDialog("TREASURER (Finance Minister)", f5messageText, 575)
		elseif keyCode == 340 and (totalIncome > 0 or totalExpense > 0) then
			uiutil.messageDialog("TREASURER (Finance Minister)", shiftTmessageText, 575)
		end

	end

	-- [F6] key has an overlay showing the current tech paradigm
	if keyCode == 181 then
		log.trace(onKeyPressMessage)
		log.info()
		local govBonusGold = 0
		local govBonusScience = 0
		govBonusGold, govBonusScience = mmGovernments.getRateBonusesUnderPrimitiveMonarchy(civ.getPlayerTribe())
		mmResearch.displayResearchRateDetails(govBonusScience)
	end

	-- [Tab] key turns off administrator mode, and activates in-game menu
	-- [Ctrl]-[Shift]-[Tab] turns on administrator mode, and activates in-game menu with additional options
	if keyCode == 211 or keyCode == 979 then
		log.trace(onKeyPressMessage)
		log.info()
		if keyCode == 211 then
			constant.events.ADMINISTRATOR_MODE = false
		elseif keyCode == 979 then
			constant.events.ADMINISTRATOR_MODE = true
		end
		local dialog = civ.ui.createDialog()
		dialog.title = "Medieval Millennium: Additional Menu Options"
		dialog.width = 520
		dialog:addText("(As a reminder, you can also press [Backspace] for context-sensitive help about the selected unit and/or tile.)")
		dialog:addOption("EXIT", 0)
		dialog:addOption("Display tile usage levels for your cities", 1)
		dialog:addOption("Display tiles near your cities with plague pollution", 2)
		dialog:addOption("Display your chances of producing new veteran units", 3)
		dialog:addOption("Display build status for city improvements", 4)
		dialog:addOption("Display technology trading possibilities", 5)
		dialog:addOption("Display power ratings for all (contacted) nations", 6)
		dialog:addOption("Close one or more Basilicas", 7)
		dialog:addOption("Sell one or more Specialist buildings", 8)
		if wonderutil.getOwner(MMWONDER.GreatCharter) == civ.getPlayerTribe() then
			dialog:addOption("Revolution! Adopt a new government (Great Charter benefit)", 9)
		end
		if constant.events.ADMINISTRATOR_MODE == true then
			dialog:addOption("-----", 0)
			dialog:addOption("ADMIN: Change console logging level", 101)
			dialog:addOption("ADMIN: Change alert box level", 102)
			dialog:addOption("ADMIN: Print 'constant' table to Lua console", 103)
			dialog:addOption("ADMIN: Print 'db' table, except tileData, to Lua console", 104)
			dialog:addOption("ADMIN: Print 'db.tileData' table to Lua console", 105)
			dialog:addOption("ADMIN: Print 'db.tileData', currentTerrainType and nativeTerrainType only, to Lua console", 106)
			dialog:addOption("ADMIN: Print 'db.tileData', worked tiles only, to Lua console", 107)
			dialog:addOption("ADMIN: Print key codes of next three keys to Lua console", 108)
		end
		log.action("Dialog box displayed")
		local result = dialog:show()

		if result == 1 then
			mmTerrain.listCurrentLandUsage()

		elseif result == 2 then
			mmPlagues.listPlagueTiles()

		elseif result == 3 then
			mmVeterancy.listVeteranChances()

		elseif result == 4 then
			mmImproveWonders.listCityImprovementStatus()

		elseif result == 5 then
			mmAwareness.listTechTradingPossibilities()

		elseif result == 6 then
			mmAwareness.listPowerRatings()

		elseif result == 7 then
			mmImproveWonders.closeBasilicas()

		elseif result == 8 then
			mmImproveWonders.sellSpecialistBuildings()

		elseif result == 9 then
			mmGovernments.changeGovernmentType(civ.getPlayerTribe())

		-- Administative options, enabled with constant.events.ADMINISTRATOR_MODE:
		elseif result == 101 then
			local dialog2 = civ.ui.createDialog()
			dialog2.title = "Set Console Logging Level"
			dialog2.width = 300
			dialog2:addText("Current level is: " .. tostring(log.EnumLogLevel[log.getLogLevel()]))
			dialog2:addOption("Set level to Trace", 0)
			dialog2:addOption("Set level to Info", 1)
			dialog2:addOption("Set level to Update", 2)
			dialog2:addOption("Set level to Action", 3)
			dialog2:addOption("Set level to Warning", 4)
			dialog2:addOption("Set level to Error", 5)
			dialog2:addOption("Set level to None", 6)
			log.action("Dialog box displayed")
			local result2 = dialog2:show()
			log.setLogLevel(result2)
			db.gameData.LOG_LEVEL = result2
		elseif result == 102 then
			local dialog2 = civ.ui.createDialog()
			dialog2.title = "Set Alert Box Level"
			dialog2.width = 300
			dialog2:addText("Current level is: " .. tostring(log.EnumLogLevel[log.getAlertLevel()]))
			dialog2:addOption("Set level to Trace", 0)
			dialog2:addOption("Set level to Info", 1)
			dialog2:addOption("Set level to Update", 2)
			dialog2:addOption("Set level to Action", 3)
			dialog2:addOption("Set level to Warning", 4)
			dialog2:addOption("Set level to Error", 5)
			dialog2:addOption("Set level to None", 6)
			log.action("Dialog box displayed")
			local result2 = dialog2:show()
			log.setAlertLevel(result2)
			db.gameData.ALERT_LEVEL = result2
		elseif result == 103 then
			uiutil.printTable("constant", constant)
		elseif result == 104 then
			uiutil.printTable("db", db, {"tileData"})
		elseif result == 105 then
			uiutil.printTable("db.tileData", db.tileData)
		elseif result == 106 then
			uiutil.printTable("db.tileData", db.tileData, {"cityTerrainConversion", "currentImprovement", "lastDecrementedUsageLevelYear", "lastImprovementChangeYear", "lastPlagueStrikeYear", "lastTerrainTypeChangeYear", "lastWorkedByCityId", "lastWorkedByCityName", "lastWorkedByTribeId", "lastWorkedYear", "usageLevel"})
		elseif result == 107 then
			local workedTileData = { }
			for tileId, data in pairs(db.tileData) do
				if data.lastWorkedYear ~= nil then
					workedTileData[tileId] = data
				end
			end
			uiutil.printTable("db.tileData *", workedTileData)
		elseif result == 108 then
			print("  Key codes of next three keys will be printed here:")
			showNextKeyPress = 0
		end
	end

	-- [Backspace] key activates unit help popup
	-- Much of the code remains here because it combines data from several separate modules
	if keyCode == 214 then
		log.trace(onKeyPressMessage)
		log.info()
		local tribe = civ.getPlayerTribe()

		-- A. Unit information
		local unit = civ.getActiveUnit()
		local unitsFound = 0
		local tile = nil
		if unit ~= nil then
			unitsFound = 1
			tile = unit.location
		else
			tile = civ.getCurrentTile()
			for potentialUnit in tile.units do
				if potentialUnit.owner == tribe then
					unitsFound = unitsFound + 1
					if unitsFound == 1 then
						unit = potentialUnit
					else
						unit = nil
					end
				end
			end
		end
		local messageHeader = ""
		local columnTable = {
			{label = "statLabel"},
			{label = "statValue"},
			{label = "space"},
			{label = "specialText"}
		}
		local dataTable = { }
		if unit ~= nil then
			if unit.veteran == true then
				messageHeader = "Veteran "
			end
			messageHeader = messageHeader .. unit.owner.adjective .. " " .. unit.type.name .. " at "
			dataTable = mmUnits.formatUnitInfo(unit)
			local rangedUnitInfoTable = mmRangedUnits.formatRangedUnitInfo(unit)
			local rangedDataRows = #rangedUnitInfoTable
			if rangedDataRows > 0 then
				local baseDataRows = #dataTable
				for i = baseDataRows, 1, -1 do
					if i > rangedDataRows then
						dataTable[i].specialText = dataTable[i - rangedDataRows].specialText
					else
						dataTable[i].specialText = rangedUnitInfoTable[i]
					end
				end
			end
		else
			if unitsFound > 1 then
				messageHeader = "Multiple Units at "
				table.insert(dataTable, { statLabel = "Multiple units found.", statValue = " ", space = " ", specialText = " " })
			else
				messageHeader = "Terrain Information for "
				table.insert(dataTable, { statLabel = "No " .. tribe.adjective .. " units found.", statValue = " ", space = " ", specialText = " " })
			end
		end

		-- B. Terrain information, incl. stack support
		local tileIsVisible = false
		if tile ~= nil then
			messageHeader = messageHeader .. tile.x .. "," .. tile.y
			table.insert(dataTable, { statLabel = " ", statValue = " ", space = " ", specialText = " " })

			local tileId = tileutil.getTileId(tile)
			if tile.owner.isHuman == true then
				tileIsVisible = true
				db.tileData[tileId].visible = true
			else
				tileIsVisible = db.tileData[tileId].visible
			end
			if tileIsVisible == false then
				for _, adjTile in ipairs(tileutil.getAdjacentTiles(tile, false)) do
					if civ.isTile(adjTile) and adjTile.owner.isHuman == true then
						tileIsVisible = true
						db.tileData[tileId].visible = true
					end
				end
			end
			if tileIsVisible == true then

				-- B.1. Stack attrition information
				local terrainId = tileutil.getTerrainId(tile)
				if terrainId ~= MMTERRAIN.Sea and tile.city == nil then
					local tribeHumanUnitsOnTile, unitSupportAvailable = mmUnits.getStackAttritionValues(tile, tribe)
					local descriptor = " units"
					if tribeHumanUnitsOnTile == 1 then
						descriptor = " unit"
					end
					table.insert(dataTable, { statLabel = tribe.adjective .. " Military Support:", statValue = tribeHumanUnitsOnTile .. descriptor .. " (max is " .. unitSupportAvailable .. ")", space = " ", specialText = " " })
					table.insert(dataTable, { statLabel = " ", statValue = " ", space = " ", specialText = " " })
				end

				-- B.2 Terrain information
				local terrainDataTable = mmTerrain.getFormattedTerrainData(tile)
				for _, terrainData in ipairs(terrainDataTable) do
					table.insert(dataTable, terrainData)
				end
			else
				table.insert(dataTable, { statLabel = "Terrain help not available.", statValue = " ", space = " ", specialText = " " })
			end
		end

		local messageText = uiutil.convertTableToMessageText(columnTable, dataTable, 5)
		if tileIsVisible == true then
			messageText = messageText .. "|   *Note: Base terrain statistics (Health, Materials, and Trade) do not include any bonuses|   resulting from a special resource on this tile, but do include any applicable effects of a river."
		end
		messageText = messageText .. "||(As a reminder, you can also press [Tab] for a menu of additional options.)"
		uiutil.messageDialog(messageHeader, messageText)
	end

	-- [Ctrl]-[S] key combination and [Ctrl]-[Shift]-[S] key combination
	if keyCode == 595 or keyCode == 851 then
		mmDifficulty.setOrConfirmValidDifficultyForSave(keyCode)
	end

end)	-- end of onKeyPress

-- ===============================================
-- ••••••••••••••• TRIGGER: onLoad •••••••••••••••
-- ===============================================
civ.scen.onLoad (function (buffer)
	log.trace("onLoad() trigger...")
	log.info()
	db = civlua.unserialize(buffer)
	if log.getLogLevel() <= log.EnumLogLevel.Info then
		uiutil.printTable("db", db, {"tileData"})
	end
end)	-- end of onLoad

-- ======================================================
-- ••••••••••••••• TRIGGER: onNegotiation •••••••••••••••
-- ======================================================
-- All normal negotiation between all AI and human tribes is permitted
-- civ.scen.onNegotiation(function(talker, listener)	end)	-- end of onNegotiation

-- ========================================================
-- ••••••••••••••• TRIGGER: onResolveCombat •••••••••••••••
-- ========================================================
civ.scen.onResolveCombat(function (defaultResolutionFunction, defender, attacker)
	if attackerTile == nil then
		log.trace("onResolveCombat() trigger...")
		attackerTile = attacker.location
		log.update("Documented location of attacking unit")

		-- New global variables, only defined here. This allows them to be referenced by any function called from this trigger, even in another module:
		attackerDamage = attacker.damage
		defenderDamage = defender.damage
		defenderHpThreshold = mmRangedUnits.getDefenderHpThreshold(attacker, defender)
		attackerInflictedMaxDamage = false
		-- The following line should be log.info instead of log.action, but more visibility to this is probably useful
		log.action("Initial HP: attacker = " .. attacker.hitpoints .. ", defender = " .. defender.hitpoints .. ", defender HP threshold = " .. defenderHpThreshold)
	end

	local continueCombat = true
	if defenderHpThreshold > 0 and defender.hitpoints <= defenderHpThreshold and attacker.hitpoints > 0 then
		attackerInflictedMaxDamage = true
		defender.damage = defender.type.hitpoints - defenderHpThreshold		-- i.e., defender.hitpoints = defenderHpThreshold
		log.action("Defender HP threshold reached; set defender HP to " .. defender.hitpoints)
		attacker.damage = attacker.type.hitpoints							-- i.e., attacker.hitpoints = 0
		log.action("  Set attacker HP to " .. attacker.hitpoints)
	end
	if attacker.hitpoints <= 0 or defender.hitpoints <= 0 then
		continueCombat = false
	end
	return continueCombat
end)	-- end of onResolveCombat

-- ===============================================
-- ••••••••••••••• TRIGGER: onSave •••••••••••••••
-- ===============================================
civ.scen.onSave (function ()
	log.trace("onSave() trigger...")
	log.info()
	mmDifficulty.preventCrashOnSave()
	local result = civlua.serialize(db)
	return result
end)	-- end of onSave

-- =========================================================
-- ••••••••••••••• TRIGGER: onScenarioLoaded •••••••••••••••
-- =========================================================
civ.scen.onScenarioLoaded(function()
	log.trace("onScenarioLoaded() trigger...")
	log.info()

	mmUpdateSave.updateSavedGame()

	log.info("  Game turn: " .. civ.getTurn())
	if db.gameData.ALERT_LEVEL ~= nil then
		log.setAlertLevel(db.gameData.ALERT_LEVEL)
	end
	if db.gameData.LOG_LEVEL ~= nil then
		log.setLogLevel(db.gameData.LOG_LEVEL)
	end

	for tribeId, thisTribeData in ipairs(db.tribeData) do
		local femaleLeader = false
		if thisTribeData.leaderGender == "female" then
			femaleLeader = true
		end
		local tribe = civ.getTribe(tribeId)
		if tribe.active == true and tribe.leader.female ~= femaleLeader then
			log.action("Corrected leader gender for " .. tribe.leader.name .. " of " .. tribe.name .. ": was female = " .. tostring(tribe.leader.female))
			tribe.leader.female = femaleLeader
			log.action("  now set to female = " .. tostring(tribe.leader.female))
		end
	end

	mmCastles.installCorrectCitiesFile()

	mmGovernments.increasePeasantHealthCost()

	mmGovernments.setCatholicChristianityPrereq()
	mmGovernments.setKingsCrusadeExpiration()
	mmImproveWonders.setImprovementCosts()
	mmImproveWonders.setConstitutionalMonarchyExpiration()
	mmResearch.assignConstitutionalMonarchyTechGroup()
	mmResearch.loadTechParadigm()
	mmUnits.setTradeUnitCosts()
	mmUnits.setFractionalMovement()

	mmAwareness.displayGameplayReminders(civ.getTurn(), true)

end)	-- end of onScenarioLoaded

-- =================================================
-- ••••••••••••••• TRIGGER: onSchism •••••••••••••••
-- =================================================
-- All normal schisms are permitted
-- civ.scen.onSchism(function(tribe)	end)	-- end of onSchism

-- ===============================================
-- ••••••••••••••• TRIGGER: onTurn •••••••••••••••
-- ===============================================
civ.scen.onTurn(function (turn)
	log.action("========================================")
	log.trace("onTurn() trigger...")

	local gameYear = civ.getGameYear()
	-- Min and max years are required because the game will switch to 1 year per turn when the Atlantic Fleet is launched
	local expectedYearMin = 500 + (turn - 1)
	local expectedYearMax = 500 + ((turn - 1) * 2)

	if gameYear < expectedYearMin or gameYear > expectedYearMax then
		uiutil.messageDialog("GAME BUG: civ.scen.onTurn()", "This game of Medieval Millennium did not assign the year correctly. The Civilization game engine believes the year is " .. gameYear .. " which is invalid.||If you were starting a new game, please quit immediately and try again. IMPORTANT TIP THAT MAY AVOID THIS BUG: If you attempted to begin a new game using the 'Load a previously created map' option, please begin a new game FIRST with one of the other two options. Once the game begins, quit immediately back to the starting program screen, but do not exit Civilization II: Test of Time completely. Then begin a new game again, this time selecting 'Load a previously created map' as you originally intended.||If you just restored a saved game, please exit immediately and try restoring that saved game again. If the problem persists, you may need to go back to an older saved game and try restoring it instead.||If this message appears while in the middle of a play session, please exit immediately and restore from your most recent saved game. You may be able to restore from an auto-save game (unless you are playing at Emperor difficulty level). If the problem persists, you may need to go back to an older saved game and try restoring it instead.", 600)
		civ.endGame({endscreens=false})
	else

		if turn == 1 then

			civ.ui.setZoom(6)

			mmBarbarians.getBarbarianActivityLevel()

			mmTerrain.initializeNewMap()

			for i = 0, 7 do
				db.tribeData[i] = { }
				db.tribeData[i].name = "nil"
			end
			-- Special handling for Barbarians, who don't begin the game with any units:
			db.tribeData[0].name = civ.getTribe(0).name
			log.update("Set name of tribe 0 to " .. db.tribeData[0].name)
			-- Find all non-Barbarian tribes by looking at active units:
			for unit in civ.iterateUnits() do
				local tribe = unit.owner
				-- Some tribes may receive multiple units to begin the game
				if db.tribeData[tribe.id].name == "nil" then
					db.tribeData[tribe.id].name = tribe.name
					log.update("Set name of tribe " .. tribe.id .. " to " .. tribe.name)
					if tribe.leader.female then
						db.tribeData[tribe.id].leaderGender = "female"
					else
						db.tribeData[tribe.id].leaderGender = "male"
					end
				end
			end

			mmGovernments.initializeTribalMonarchy()

			mmCastles.installCorrectCitiesFile()

			mmDifficulty.displayHighDifficultyLevelInstructions()

			mmUnits.setFractionalMovement()

			uiutil.messageDialog("Medieval Millennium", "Please note that in addition to the standard Civilization II shortcut keys, pressing the [Tab] key will bring up a menu of additional options, and pressing the [Backspace] key will bring up context-sensitive help information about the selected unit and/or tile.", 550)

			mmUnits.setupInitialUnits()

			mmGovernments.setCatholicChristianityPrereq()

		end		-- end of turn == 1

		-- Process any tribes that were missed in the *previous* turn, because they did not activate any units or complete any city production:
		-- At minimum, this will always run onTribeTurnEnd for the last active tribe of the previous turn,
		-- 		but it will work backwards from there to catch any others that were missed and run them in order
		for i = 7, 0, -1 do
			local tribe = civ.getTribe(i)
			if tribe ~= nil and tribe.active then
				onTribeTurnEnd(tribe, turn - 1, "onTurn()")
				break
			end
		end

		-- Document inactive tribes as not currently in the game:
		for i = 1, 7 do
			local tribe = civ.getTribe(i)
			if (tribe == nil or tribe.active == false) and db.tribeData[tribe.id] ~= nil then
				log.update("Documented tribe " .. i .. " (" .. db.tribeData[tribe.id].name .. ") as not currently active in the game")
				db.tribeData[tribe.id] = nil
				if tribe ~= nil then
					mmSurvivors.clearSurvivorDataForTribe(tribe)
				end
			end
		end

		mmAwareness.storeTribePopulations(turn, false)
		mmAwareness.calculatePowerRatings(turn, false)
		mmAwareness.displayGameplayReminders(turn, false)

		mmResearch.displayInitialResearchMessages(turn)

		if db.gameData.YEARS_PER_TURN > 1 then
			local anyFleetLaunched = false
			for tribe in tribeutil.iterateActiveTribes(false) do
				if tribe.spaceship.launched == true then
					anyFleetLaunched = true
					break
				end
			end
			if anyFleetLaunched == true then
				db.gameData.YEARS_PER_TURN = 1
				log.info("  Detected first launch of an Atlantic Fleet")
				log.update("Set db.gameData.YEARS_PER_TURN = 1")
				uiutil.messageDialog("Game Concept: Years Per Turn",
					"With the launch of the first Atlantic Fleet, Civilization II has automatically altered the pace of the game to one year per turn.", 400)
			end
		end

		if log.getLogLevel() <= log.EnumLogLevel.Info then
			uiutil.printTable("db", db, {"tileData"})
		end

		-- Delete turn history that is at least 3 turns old
		if turn - 3 >= 0 then
			local turnHistory = retrieve("turnHistory")
			turnHistory[turn - 3] = nil
			store("turnHistory", turnHistory)
		end

		log.action("----------------------------------------")
		log.action("")
		log.action("=== Beginning turn " .. turn .. " (A.D. " .. gameYear .. ") ===")
		log.action("")

		-- The following game-wide events take place before *any* tribe takes their turn

		local turnMessage = "Beginning of turn " .. turn .. ". The game is " .. ((turn - 1) / 5) .. "% complete." .. "||"
		local customMessage = nil
		if gameYear == 1000 then
			techutil.grantTechByName(civ.getPlayerTribe(), "High Middle Ages")
			civ.playSound("Fanfare6.wav")
			customMessage = "Citizens throughout Europe celebrate one thousand years since the birth of Christ. As a new millennium dawns, a spirit of optimism sweeps through the land. People sense that the dark times of the past five centuries are behind them, and are inspired to look to the future. The High Middle Ages have begun!"
		end
		if customMessage ~= nil then
			turnMessage = turnMessage .. customMessage
		else
			turnMessage = turnMessage .. "The year is now A.D. " .. gameYear .. "."
		end
		uiutil.messageDialog("Medieval Millennium", turnMessage, 480)

		mmResearch.setTechParadigm(turn)

		mmGovernments.increasePeasantHealthCost()

		mmImproveWonders.setImprovementCosts()

		mmUnits.setTradeUnitCosts()

		mmTerrain.applyClimateChangeToMap()
		mmTerrain.incrementTileUsageData()
		mmTerrain.processMapChanges()

		mmCastles.clearCastleUnitOrders()
		mmCastles.newCastlesBuilt()

		mmRangedUnits.clearHistoryForAllUnits()

		mmResearch.boostResearchProgress()

		mmPlagues.documentNaturalPlague()
		mmPlagues.plagueStrike()

		-- This runs after the plague strike, since the plague strike could kill Monks. That way the Monastery is removed immediately
		--		instead of at the beginning of the *next* turn.
		mmImproveWonders.syncSpecialistsWithGameStatus()

		-- It's a little odd to process this *after* the plague strike, when it feels like it's the middle of the barbarian turn,
		--		but it should run after syncSpecialistsWithGameStatus() which is placed late for reasons noted above
		mmImproveWonders.processSpecialistBenefits()

		mmBarbarians.setBarbarianTreasuryAndResearch()
		mmBarbarians.createBarbarianUnits()

		log.action("----------------------------------------")
		log.action("Processing turn " .. turn .. " for tribe 0 (Barbarians) in onTurn()...")

		-- Following this, events which apply to each tribe individually will take place as that tribe plays,
		--		in onTribeTurnBegin(), onTribeTurnCitiesDone(), and onTribeTurnEnd() respectively
	end

end)	-- end of onTurn

-- =====================================================
-- ••••••••••••••• TRIGGER: onUnitKilled •••••••••••••••
-- =====================================================
civ.scen.onUnitKilled(function(losingUnit, winningUnit)
	log.trace("onUnitKilled() trigger...")

-- Note: the following global variables are populated in onResolveCombat(), and are therefore available
--		within this trigger or to any function in another module, *without* being passed as parameters:
--		attackerTile
--		attackerDamage
--		defenderDamage
--		defenderHpThreshold

	local attackingUnit = winningUnit
	local defendingUnit = losingUnit
	local outcomeDesc = "Attacking "
	if unitutil.wasAttacker(losingUnit) then
		attackingUnit = losingUnit
		defendingUnit = winningUnit
		outcomeDesc = "Defending "
	end
	local battleTile = tileutil.getBattleTile(winningUnit, losingUnit)

	local attackerHomeCity = "NONE"
	if attackingUnit.homeCity ~= nil then
		attackerHomeCity = attackingUnit.homeCity.name
	end
	local defenderHomeCity = "NONE"
	if defendingUnit.homeCity ~= nil then
		defenderHomeCity = defendingUnit.homeCity.name
	end

	-- The following battle details should be log.info in each case; setting to log.action to aid console review
	log.action("  ¤------------BATTLE RESULTS------------¤")
	log.action("  ¦ Attacker: " .. attackingUnit.owner.adjective .. " " .. attackingUnit.type.name .. " (ID " .. attackingUnit.id .. ", home = " .. attackerHomeCity .. ")")
	if attackerTile ~= nil then
		log.action("  ¦     from: " .. attackerTile.x .. "," .. attackerTile.y)
	else
		log.action("  ¦     from: [same]")
	end
	log.action("  ¦ Defender: " .. defendingUnit.owner.adjective .. " " .. defendingUnit.type.name .. " (ID " .. defendingUnit.id .. ", home = " .. defenderHomeCity .. ")")
	log.action("  ¦       at: " .. battleTile.x .. "," .. battleTile.y .. " (Terrain: " .. MMTERRAIN[tileutil.getTerrainId(battleTile)] .. ")")
	log.action("  ¦   Winner: " .. outcomeDesc .. winningUnit.owner.adjective .. " " .. winningUnit.type.name .. " (" .. winningUnit.hitpoints .. " HP remaining)")
	log.action("  ¤--------------------------------------¤")

	mmRangedUnits.resetAllUnitStats("events.onUnitKilled", true)

	mmImproveWonders.specialistUnitKilled(winningUnit, losingUnit)

	local artilleryCaptureOccurred = mmRangedUnits.captureArtilleryUnit(winningUnit, losingUnit, attackerTile, battleTile)
	local navalCaptureOccurred = mmUnits.captureNavalUnit(winningUnit, losingUnit, battleTile)
	local captureOccurred = artilleryCaptureOccurred or navalCaptureOccurred

	mmUnits.stackDamage(losingUnit, defendingUnit, battleTile, captureOccurred)

	mmSurvivors.applyCasualtiesForDefeatedUnit(winningUnit, losingUnit)
	mmSurvivors.scheduleSurvivingUnitReturn(winningUnit, losingUnit, attackingUnit, battleTile)

	mmRangedUnits.improvementDestroyedByAttack(attackingUnit, defendingUnit, winningUnit, battleTile)
	mmTerrain.tileImprovementsDestroyedByBattle(winningUnit, losingUnit, attackerTile, battleTile)

	mmBarbarians.barbarianUnitKilled(winningUnit, losingUnit, battleTile)
	mmUnits.tradeUnitKilled(winningUnit, losingUnit, battleTile)

	mmRangedUnits.firingUnitBecomesVeteran(winningUnit, attackingUnit)

	mmRangedUnits.clearFireHistoryForUnit(losingUnit)
	mmRangedUnits.clearProjectileHistoryForUnit(losingUnit)
	mmRangedUnits.clearProjectileHistoryForUnit(winningUnit)
	mmRangedUnits.destroyProjectile(winningUnit)

	-- Reset global variables to default values prior to next battle:
	attackerTile = nil
	attackerDamage = 0
	defenderDamage = 0
	defenderHpThreshold = 0
	attackerInflictedMaxDamage = false

end)	-- end of onUnitKilled

-- Initialize the random number generator each time this file is parsed:
local randomizer = (os.time() % 100)
randomizer = ((randomizer * randomizer * 111) + 111) % 10000
math.randomseed(randomizer)
for i = 1, randomizer do math.random() end
log.update("  @ events.(root)")
log.update("Initialized the random number generator using " .. randomizer)

if log.getLogLevel() <= log.EnumLogLevel.Info then
	uiutil.printTable("constant", constant)
end
log.info("@ events.(root)")
log.info("  civ.scen.params.techParadigm = " .. civ.scen.params.techParadigm)
log.info("")
log.action("  events.lua parsed successfully at " .. os.date("%c"))
log.info("    Lines found: " .. debug.getinfo(1, "l").currentline + 4)
log.info("")
linesOfLuaCode = linesOfLuaCode + debug.getinfo(1, "l").currentline + 2
log.action("  Total lines of Lua code found: " .. linesOfLuaCode)
log.action("========================================")
