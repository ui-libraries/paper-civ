-- utilUnit.lua
-- by Knighttime

-- Note: require globalFunctions.lua in the main events.lua file first, in order to require and use this file.
-- Note: require log.lua in the main events.lua file first, in order to require and use this file.

log.trace()

local UTIL_FILE_NAME = "utilUnit"
local UTIL_FILE_VERSION = 1.00

-- GLOBAL CONSTANT:
-- Note that civlua defines "domain" which is the same but uses lowercase keys,
-- 		and uses the word "ground" instead of "land" which is more of a de facto standard.
-- This overwrites and replaces that definition, by virtue of being processed later.
domain = {
	Land = 0,
	Air = 1,
	Sea = 2
}

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
local function confirmLoad (requiredVersion) --> boolean
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " v" .. UTIL_FILE_VERSION .. " loaded successfully")
	if requiredVersion ~= nil and requiredVersion > UTIL_FILE_VERSION then
		log.error("Version " .. requiredVersion .. " of " .. UTIL_FILE_NAME .. ".lua is required, but a lower version (" .. UTIL_FILE_VERSION .. ") was found. Please download and install an updated version of this Lua utility file, and then restart the game. If you fail to do so, Lua events may crash or not work as intended.")
		log.action("")
		return false
	end
	log.info("")
	return true
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTION •••••••••••••••
-- ==============================================================
-- Replaces civlua.isValidUnitLocation() which had multiple defects that rendered it inaccurate.
-- This is also called internally by createUnitByType() and must be declared prior to it in this file:
local function isValidUnitLocation (unittype, tribe, tile) --> boolean
	log.trace()
	local isValid = false
	if tile ~= nil and civ.canEnter(unittype, tile) and (tile.defender == nil or tile.defender == tribe) then
		local city = tile.city
		if unittype.domain == domain.Sea then
			isValid = (tile.terrainType & 0x0F) == 0x0A or (city ~= nil and city.coastal and city.owner == tribe)
		else
			isValid = ((tile.terrainType & 0x0F) ~= 0x0A or unittype.domain == domain.Air) and (city == nil or city.owner == tribe)
		end
	end
--	if isValid then
--		log.info(tile.x .. "," .. tile.y .. "," .. tile.z .. " is a valid location for " .. tribe.adjective .. " " .. unittype.name)
--	else
--		log.info(tile.x .. "," .. tile.y .. "," .. tile.z .. " is NOT a valid location for " .. tribe.adjective .. " " .. unittype.name)
--	end
	return isValid
end

-- ===========================================================
-- ••••••••••••••• STRICTLY INTERNAL FUNCTIONS •••••••••••••••
-- ===========================================================
-- Replaces civlua.createUnit() which had multiple defects that rendered it inaccurate.
-- Note: third parameter is a single tile object, like civ.createUnit(), whereas the civlua function takes a list of x,y,z coordinates
-- This function also supports only three options: "count", "homeCity", and "veteran"
-- 		It does not support "inCapital" or "randomize" which are supported by civlua.createUnit()
-- Note that if you provide a count > 1 (in options) the function will return all of them in a table,
--		but if only one unit is created, it will return a unit object (rather than a table with a single entry)
local function createUnitByType (unittype, tribe, tile, options) --> unit or table
	log.trace()
	local options = options or { }
	local createdUnits = { }
	if isValidUnitLocation(unittype, tribe, tile) then
		local unitsToCreate = options.count or 1
		for i = 1, unitsToCreate do
			local unit = civ.createUnit(unittype, tribe, tile)
			if options.veteran ~= nil then
				unit.veteran = options.veteran
			end
			unit.homeCity = options.homeCity
			table.insert(createdUnits, unit)
		end
		if #createdUnits == 0 then
			log.error("ERROR! Failed to create unit(s) on a tile deemed valid by " .. UTIL_FILE_NAME .. ".isValidUnitLocation()")
		end
	end
	if #createdUnits == 0 then
		log.error("ERROR! Failed to create unit: " .. unittype.name .. " could not be created for " .. tribe.name .. " at " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	else
		for _, unit in pairs(createdUnits) do
			log.action("Created " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
		end
		if #createdUnits == 1 then
			return createdUnits[1]
		else
			return createdUnits
		end
	end
end

-- ==========================================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS (continued) •••••••••••••••
-- ==========================================================================
-- Replaces civlua.findUnitType() which had a defect
-- This is also called internally by createUnitsByName() and must be declared prior to it in this file:
local function findTypeByName (unitName, blockInfoMessage) --> unittype
	log.trace()
	local unittype = nil
	for i = 0, civ.cosmic.numberOfUnitTypes - 1 do
		local potentialUnittype = civ.getUnitType(i)
		if potentialUnittype.name == unitName then
			unittype = potentialUnittype
			break
		end
	end
	if unittype ~= nil then
		if blockInfoMessage then
			-- Do nothing
		else
			log.info("Found unittype \"" .. unitName .. "\" with ID " .. unittype.id)
		end
	else
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".findTypeByName() did not find unittype with name \"" .. unitName .. "\"")
	end
	return unittype
end

local function createById (unittypeId, owner, location, options) --> unit or table
	-- Note: first parameter is a unit type's ID as an integer, not a unit type object
	log.trace()
	local result = createUnitByType(civ.getUnitType(unittypeId), owner, location, options)
	return result
end

local function createByName (unitName, owner, location, options) --> unit or table
	-- Note: first parameter is a unit type's name as a string, not a unit type object
	log.trace()
	local result = createUnitByType(findTypeByName(unitName, true), owner, location, options)
	return result
end

local function createByType (unittype, owner, location, options) --> unit or table
	-- Note: first parameter is a unit type object
	log.trace()
	local result = createUnitByType(unittype, owner, location, options)
	return result
end

local function deleteUnit (unit) --> void
	log.trace()
	log.action("Deleted " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") from " .. unit.x .. "," .. unit.y .. "," .. unit.z)
	civ.deleteUnit(unit)
end

-- Credit to generalLibary.lua by Prof. Garfield
-- Note: "wait" status is stored as a unit *attribute*, not a unit *order* (even though it's issued as an order during gameplay)
local function isWaiting (unit) --> boolean
	log.trace()
	return unit.attributes & 0x4000 == 0x4000
end

-- Credit to generalLibary.lua by Prof. Garfield
-- Note that calling this for the human player's currently active unit does not seem to behave the same as pressing the 'w' key.
--		The unit continues to be active and the game doesn't select the next unit and activate it instead.
local function setToWaiting (unit) --> void
	log.trace()
	unit.attributes = unit.attributes | 0x4000
	log.action("Set status of " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. " to Wait")
end

-- Credit to generalLibary.lua by Prof. Garfield
-- Note that this does not immediately activate the unit, it simply clears its "waiting" attribute
local function setToNotWaiting (unit) --> void
	log.trace()
	unit.attributes = unit.attributes ~ 0x4000
	log.action("Set status of " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. " to Not Wait")
end

local function isFortifying (unit) --> boolean
	log.trace()
	return unit.order & 0xFF == 0x01
end

local function isFortified (unit) --> boolean
	log.trace()
	return unit.order & 0xFF == 0x02
end

local function fortifyUnit (unit) --> void
	log.trace()
	if unit.type.domain == domain.Land and unit.location.terrainType & 0x0F == 0x10 then
		log.warning("WARNING: Unsupported attempt to fortify a land unit (" .. unit.owner.adjective .. " " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. ") which is not on a land tile")
	elseif unit.type.domain == domain.Air and unit.location.city == nil and unit.location.improvements & 0x42 ~= 0x42 then
		log.warning("WARNING: Unsupported attempt to fortify an air unit (" .. unit.owner.adjective .. " " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. ") which is not in a city or airbase")
	elseif unit.type.domain == domain.Sea and unit.location.city == nil then
		log.warning("WARNING: Unsupported attempt to fortify a sea unit (" .. unit.owner.adjective .. " " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. ") which is not in a city")
	elseif unit.type.role == 5 then
		log.warning("WARNING: Unsupported attempt to fortify a settler-type unit (" .. unit.owner.adjective .. " " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. ")")
	else
		unit.order = 0x02
		log.action("Fortified " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
	end
end

local function isSleeping (unit) --> boolean
	log.trace()
	return unit.order & 0xFF == 0x03
end

local function sleepUnit (unit) --> void
	log.trace()
	unit.order = 0x03
	log.action("Slept " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
end

local function isCleaningUpPollution (unit) --> boolean
	log.trace()
	return unit.order & 0xFF == 0x09
end

local function cleanUpPollution (unit) --> void
	log.trace()
	if unit.type.role ~= 5 then
		log.warning("WARNING: Unsupported attempt to order a non-settler-type unit (" .. unit.owner.adjective .. " " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. ") to clean up pollution")
	elseif unit.location.improvements & 0x82 ~= 0x80 then
		log.warning("WARNING: Unsupported attempt to order a unit (" .. unit.owner.adjective .. " " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. ") to clean up pollution on a tile which does not have pollution")
	else
		unit.order = 0x09
		log.action("Ordered " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. " to clean up pollution")
	end
end

local function clearOrders (unit) --> void
	log.trace()
	log.action("Cleared orders for " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. " (old orders: " .. unit.order .. ")")
	unit.order = 0xFF
end

local function hasFlagTwoSpaceVisibility (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0001 == 0x0001
end

local function hasFlagIgnoreZonesOfControl (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0002 == 0x0002
end

local function hasFlagCanMakeAmphibiousAssaults (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0004 == 0x0004
end

local function hasFlagSubmarineAdvantagesDisadvantages (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0008 == 0x0008
end
local function addFlagSubmarineAdvantagesDisadvantages (unittype) --> void
	log.trace()
	unittype.flags = unittype.flags | 0x0008
	log.action("Added flag 'Submarine Advantages/Disadvantages' to " .. unittype.name .. " (unit type " .. unittype.id .. ")")
end
local function removeFlagSubmarineAdvantagesDisadvantages (unittype) --> void
	log.trace()
	unittype.flags = unittype.flags ~ 0x0008
	log.action("Removed flag 'Submarine Advantages/Disadvantages' from " .. unittype.name .. " (unit type " .. unittype.id .. ")")
end

local function hasFlagCanAttackAirUnits (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0010 == 0x0010
end

-- This is also called internally by getMovesRemaining() and must be declared prior to it in this file:
local function hasFlagShipMustStayNearLand (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0020 == 0x0020
end

local function hasFlagNegatesCityWalls (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0040 == 0x0040
end

local function hasFlagCanCarryAirUnits (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0080 == 0x0080
end

local function hasFlagCanMakeParadrops (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0100 == 0x0100
end

local function hasFlagAlpine (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0200 == 0x0200
end

local function hasFlagX2OnDefenseVersusHorse (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0400 == 0x0400
end

local function hasFlagFreeSupportForFundamentalism (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x0800 == 0x0800
end

local function hasFlagDestroyedAfterAttacking (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x1000 == 0x1000
end
local function addFlagDestroyedAfterAttacking (unittype) --> void
	log.trace()
	unittype.flags = unittype.flags | 0x1000
	log.action("Added flag 'Destroyed After Attacking' to " .. unittype.name .. " (unit type " .. unittype.id .. ")")
end
local function removeFlagDestroyedAfterAttacking (unittype) --> void
	log.trace()
	unittype.flags = unittype.flags ~ 0x1000
	log.action("Removed flag 'Destroyed After Attacking' from " .. unittype.name .. " (unit type " .. unittype.id .. ")")
end

local function hasFlagX2OnDefenseVersusAir (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x2000 == 0x2000
end

local function hasFlagUnitCanSpotSubmarines (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x4000 == 0x4000
end

local function hasFlagOverrideHealthBars (unittype) --> boolean
	log.trace()
	return unittype.flags & 0x8000 == 0x8000
end

local function getMovesAsMovementPoints (moves) --> integer
	log.trace()
	local result = round(moves * totpp.movementMultipliers.aggregate)	-- civ.cosmic.roadMultiplier
	return result
end

local function getMovementPointsAsMoves (movementPoints) --> decimal
	log.trace()
	return movementPoints / totpp.movementMultipliers.aggregate			-- civ.cosmic.roadMultiplier
end

-- The movement points available at the beginning of a healthy unit's turn is equal to unittype.move, but
--		this may be reduced for a unit that is damaged.
-- Credit to Prof. Garfield via https://forums.civfanatics.com/threads/damage-and-movement.646447/
-- This is also called internally by canMove() and must be declared prior to it in this file:
local function getMovesRemaining (unit) --> decimal
	log.trace()
	local movementPoints = nil
	-- Step 1: Calculate movement points possible at the beginning of this unit's turn:
	local damageAdjustedMovementPoints = math.floor((unit.hitpoints * unit.type.move) / unit.type.hitpoints)
	-- Step 2: Moves are always presented as a whole number, so movement points must be a multiple of the aggregate multiplier:
	local remainder = damageAdjustedMovementPoints % totpp.movementMultipliers.aggregate
	if remainder > 0 then
		damageAdjustedMovementPoints = damageAdjustedMovementPoints - remainder + totpp.movementMultipliers.aggregate
	end
	-- Step 3: Incorporate damage adjustment based on unit domain:
	if unit.type.domain == domain.Land then
		-- A land unit always receives at least 1 move, unless its type has 0 moves
		movementPoints = math.min(math.max(damageAdjustedMovementPoints, totpp.movementMultipliers.aggregate), unit.type.move)
	elseif unit.type.domain == domain.Air then
		-- An air unit never has its movement reduced due to damage
		movementPoints = unit.type.move
	elseif unit.type.domain == domain.Sea then
		-- A sea unit always receives at least 2 moves, unless its type has 0 or 1 moves
		movementPoints = math.min(math.max(damageAdjustedMovementPoints, totpp.movementMultipliers.aggregate * 2), unit.type.move)
		-- One advance grant a ship movement increase:
		if civ.hasTech(unit.owner, civ.getTech(59)) then
			movementPoints = movementPoints + totpp.movementMultipliers.aggregate	-- +1 for "Nuclear Power"
		end
		-- Two wonders grant a movement increase:
		if hasFlagShipMustStayNearLand(unit.type) == false then
			local wonder03 = civ.getWonder(3)
			if wonder03.city ~= nil and wonder03.city.owner == unit.owner and (wonder03.expires == nil or wonder03.expires.researched == false) then
				movementPoints = movementPoints + totpp.movementMultipliers.aggregate	-- +1 for "Lighthouse" if ship doesn't have "Trireme" flag
			end
		end
		local wonder12 = civ.getWonder(12)
		if wonder12.city ~= nil and wonder12.city.owner == unit.owner and (wonder12.expires == nil or wonder12.expires.researched == false) then
			movementPoints = movementPoints + (totpp.movementMultipliers.aggregate * 2)	-- +2 for "Magellan's Expedition"
		end
	end
	if movementPoints ~= nil then
		-- Step 4: Subtract movement spent this turn from movement points possible
		-- Step 5: Divide by the aggregate multiplier, to return moves rather than movement points
		return math.max(movementPoints - unit.moveSpent, 0) / totpp.movementMultipliers.aggregate
	else
		return nil
	end
end

local function canMove (unit) --> boolean
	log.trace()
	local result = getMovesRemaining(unit)
	return result > 0
end

local function iterateUnitTypes () --> iterator (of unittype objects)
	log.trace()
	return coroutine.wrap(function ()
		for i = 0, civ.cosmic.numberOfUnitTypes - 1 do
			local unittype = civ.getUnitType(i)
			coroutine.yield(unittype)
		end
	end)
end

local function teleportUnit (unit, tile) --> void
	log.trace()
	log.action("Moved " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") from " .. unit.x .. "," .. unit.y .. "," .. unit.z .. " to " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	civ.teleportUnit(unit, tile)
end

local function tileContainsOtherTribeUnit (tile, tribe) --> boolean
	log.trace()
	local foundOtherTribeUnit = false
	for unit in tile.units do
		if unit.owner ~= tribe then
			foundOtherTribeUnit = true
			break
		end
	end
	return foundOtherTribeUnit
end

local function tileContainsOtherUnit (tile, unit) --> boolean
	log.trace()
	local foundOtherUnit = false
	for otherUnit in tile.units do
		if otherUnit.id ~= unit.id then
			foundOtherUnit = true
			break
		end
	end
	return foundOtherUnit
end

local function tileContainsTribeUnit (tile, tribe) --> boolean
	log.trace()
	local foundTribeUnit = false
	for unit in tile.units do
		if unit.owner == tribe then
			foundTribeUnit = true
			break
		end
	end
	return foundTribeUnit
end

local function tileContainsUnitType (tile, unittype) --> boolean
	log.trace()
	local foundUnitType = false
	for unit in tile.units do
		if unit.type == unittype then
			foundUnitType = true
			break
		end
	end
	return foundUnitType
end

local function wasAttacker (losingUnit) --> boolean
	log.trace()
	local testValidTile = civ.getTile(losingUnit.location.x, losingUnit.location.y, losingUnit.location.z)
	if testValidTile == nil then
		return true
	else
		return false
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 60

return {
	confirmLoad = confirmLoad,

	isValidUnitLocation = isValidUnitLocation,

	findTypeByName = findTypeByName,
	createById = createById,
	createByName = createByName,
	createByType = createByType,
	deleteUnit = deleteUnit,
	isWaiting = isWaiting,
	setToWaiting = setToWaiting,
	setToNotWaiting = setToNotWaiting,
	isFortifying = isFortifying,
	isFortified = isFortified,
	fortifyUnit = fortifyUnit,
	isSleeping = isSleeping,
	sleepUnit = sleepUnit,
	isCleaningUpPollution = isCleaningUpPollution,
	cleanUpPollution = cleanPollution,
	clearOrders = clearOrders,

	hasFlagTwoSpaceVisibility = hasFlagTwoSpaceVisibility,
	hasFlagIgnoreZonesOfControl = hasFlagIgnoreZonesOfControl,
	hasFlagCanMakeAmphibiousAssaults = hasFlagCanMakeAmphibiousAssaults,

	hasFlagSubmarineAdvantagesDisadvantages = hasFlagSubmarineAdvantagesDisadvantages,
	addFlagSubmarineAdvantagesDisadvantages = addFlagSubmarineAdvantagesDisadvantages,
	removeFlagSubmarineAdvantagesDisadvantages = removeFlagSubmarineAdvantagesDisadvantages,

	hasFlagCanAttackAirUnits = hasFlagCanAttackAirUnits,
	hasFlagShipMustStayNearLand = hasFlagShipMustStayNearLand,
	hasFlagNegatesCityWalls = hasFlagNegatesCityWalls,
	hasFlagCanCarryAirUnits = hasFlagCanCarryAirUnits,
	hasFlagCanMakeParadrops = hasFlagCanMakeParadrops,
	hasFlagAlpine = hasFlagAlpine,
	hasFlagX2OnDefenseVersusHorse = hasFlagX2OnDefenseVersusHorse,
	hasFlagFreeSupportForFundamentalism = hasFlagFreeSupportForFundamentalism,

	hasFlagDestroyedAfterAttacking = hasFlagDestroyedAfterAttacking,
	addFlagDestroyedAfterAttacking = addFlagDestroyedAfterAttacking,
	removeFlagDestroyedAfterAttacking = removeFlagDestroyedAfterAttacking,

	hasFlagX2OnDefenseVersusAir = hasFlagX2OnDefenseVersusAir,
	hasFlagUnitCanSpotSubmarines = hasFlagUnitCanSpotSubmarines,
	hasFlagOverrideHealthBars = hasFlagOverrideHealthBars,

	getMovesAsMovementPoints = getMovesAsMovementPoints,
	getMovementPointsAsMoves = getMovementPointsAsMoves,
	getMovesRemaining = getMovesRemaining,
	canMove = canMove,
	iterateUnitTypes = iterateUnitTypes,
	teleportUnit = teleportUnit,
	tileContainsOtherTribeUnit = tileContainsOtherTribeUnit,
	tileContainsOtherUnit = tileContainsOtherUnit,
	tileContainsTribeUnit = tileContainsTribeUnit,
	tileContainsUnitType = tileContainsUnitType,
	wasAttacker = wasAttacker,
}
