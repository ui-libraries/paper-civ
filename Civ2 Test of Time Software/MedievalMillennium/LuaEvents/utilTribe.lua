-- utilTribe.lua
-- by Knighttime

-- Note: require log.lua in the main events.lua file first, in order to require and use this file.

log.trace()

local UTIL_FILE_NAME = "utilTribe"
local UTIL_FILE_VERSION = 1.00

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
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function changeMoney (tribe, amount) --> void
	-- If called with a negative amount that is larger than the tribe's treasury, it will set treasury to 0.
	-- If you want an event to be dependent on sufficient funds, this needs to be tested directly outside of this function.
	log.trace()
	local origAmount = tribe.money
	local changeAmount = math.floor(amount + 0.5)
	if amount > 0 then
		tribe.money = origAmount + changeAmount
		log.action("Added " .. changeAmount .. " gold to " .. tribe.adjective .. " treasury (was " .. origAmount .. ", now " .. tribe.money .. ")")
	elseif amount == 0 then
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".changeMoney() called with amount = 0")
	else
		-- amount < 0, intending to subtract money from treasury
		local absAmount = math.abs(changeAmount)
		if tribe.money == 0 then
			log.info("Attempted to deduct " .. absAmount .. " gold from " .. tribe.adjective .. "treasury but they had 0")
		else
			if origAmount < absAmount then
				tribe.money = 0
				log.action("Deducted " .. origAmount .. " gold from " .. tribe.adjective .. "treasury (was " .. origAmount .. ", now 0)")
				log.action("  Attempted to deduct " .. absAmount .. " but they only had " .. origAmount)
			else
				tribe.money = origAmount + changeAmount		-- adding a negative number
				log.action("Deducted " .. absAmount .. " gold from " .. tribe.adjective .. " treasury (was " .. origAmount .. ", now " .. tribe.money .. ")")
			end
		end
	end
end

local function changeResearchProgress (tribe, amount) --> void
	-- If called with a negative amount that is larger than the tribe's current research progress, it will set it to 0.
	log.trace()
	local origAmount = tribe.researchProgress
	local changeAmount = math.floor(amount + 0.5)
	if amount > 0 then
		tribe.researchProgress = origAmount + changeAmount
		log.action("Added " .. changeAmount .. " points to " .. tribe.adjective .. " research progress (was " .. origAmount .. ", now " .. tribe.researchProgress .. ")")
		-- NOTE: This may exceed the research cost of the next advance (tribe.researchCost), but this function doesn't take any further action even if that's the case
		--		 The actual granting of the advance is deferred to be handled by the game engine the next time it runs this comparison
	elseif amount == 0 then
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".changeResearchProgress() called with amount = 0")
	else
		-- amount < 0, intending to subtract points from current research progress
		local absAmount = math.abs(changeAmount)
		if tribe.researchProgress == 0 then
			log.info("Attempted to deduct " .. absAmount .. " points from " .. tribe.adjective .. "research progress but they had 0")
		else
			if origAmount < absAmount then
				tribe.researchProgress = 0
				log.action("Deducted " .. origAmount .. " points from " .. tribe.adjective .. "research progress (was " .. origAmount .. ", now 0)")
				log.action("  Attempted to deduct " .. absAmount .. " but they only had " .. origAmount)
			else
				tribe.researchProgress = origAmount + changeAmount		-- adding a negative number
				log.action("Deducted " .. absAmount .. " points from " .. tribe.adjective .. " research progress (was " .. origAmount .. ", now " .. tribe.researchProgress .. ")")
			end
		end
	end
end

-- Replaces civlua.iterateTribes() which always includes barbarians and does not check if the tribe is active.
-- This is also called internally by hasWarWithAny() and must be declared prior to it in this file:
local function iterateActiveTribes (includeBarbarians) --> iterator (of tribe objects)
	log.trace()
	return coroutine.wrap(function ()
		local firstTribeId = 1
		if includeBarbarians then
			firstTribeId = 0
		end
		for i = firstTribeId, 7 do
			local tribe = civ.getTribe(i)
			if tribe ~= nil and tribe.active then
				coroutine.yield(tribe)
			end
		end
	end)
end

local function hasEmbassy (tribe1, tribe2) --> boolean
	-- Returns true if tribe1 has an embassy with tribe2 (tests that direction only)
	log.trace()
	local embassy = tribe1.treaties[tribe2] & 0x80 > 0
	if embassy then
		log.info(tribe1.name .. " has an embassy with " .. tribe2.name)
	else
		log.info(tribe1.name .. " does not have an embassy with " .. tribe2.name)
	end
	return embassy
end

local function haveContact (tribe1, tribe2) --> boolean
	log.trace()
	if tribe1 == tribe2 then
		return true		-- you always have contact with yourself
	elseif tribe1.id == 0 or tribe2.id == 0 then
		return true		-- no special action occurs when you meet barbarians for the first time, so the behavior
						--		is the same as if you always have contact with them
	else
		return tribe1.treaties[tribe2] & 0x0001 == 0x0001
	end
end

-- This is also called internally by enforcePeace() and must be declared prior to it in this file:
local function havePeaceTreaty (tribe1, tribe2) --> boolean
	log.trace()
	if tribe1 == tribe2 then
		return false	-- you cannot have a peace treaty with yourself
	elseif tribe1.id == 0 or tribe2.id == 0 then
		return false	-- you cannot have a peace treaty with barbarians
	else
		return tribe1.treaties[tribe2] & 0x0004 == 0x0004 and tribe2.treaties[tribe1] & 0x0004 == 0x0004
	end
end

-- This is also called internally by enforceAlliance() and must be declared prior to it in this file:
local function haveAlliance (tribe1, tribe2) --> boolean
	log.trace()
	if tribe1 == tribe2 then
		return false	-- you cannot have an alliance with yourself
	elseif tribe1.id == 0 or tribe2.id == 0 then
		return false	-- you cannot have an alliance with barbarians
	else
		return tribe1.treaties[tribe2] & 0x0008 == 0x0008 and tribe2.treaties[tribe1] & 0x0008 == 0x0008
	end
end

-- This is also called internally by enforceWar() and hasWarWithAny() and must be declared prior to them in this file:
local function haveWar (tribe1, tribe2) --> boolean
	log.trace()
	if tribe1 == tribe2 then
		return false	-- you cannot be at war with yourself
	elseif tribe1.id == 0 or tribe2.id == 0 then
		return true		-- everyone is at war with barbarians
	else
		return tribe1.treaties[tribe2] & 0x2000 == 0x2000 or tribe2.treaties[tribe1] & 0x2000 == 0x2000
	end
end

local function hasWarWithAny (tribe) --> boolean
-- All tribes are always at war with the barbarians, so this only checks if the given tribe is at war with a different non-barbarian tribe
	log.trace()
	local hasWar = false
	for tribe2 in iterateActiveTribes(false) do
		if tribe2 ~= tribe then
			if haveWar(tribe, tribe2) then
				hasWar = true
				break
			end
		end
	end
	return hasWar
end

-- This is also called internally by enforceAlliance() and must be declared prior to it in this file:
local function enforcePeace (tribe1, tribe2, knownChange) --> void
	log.trace()
	if knownChange == nil then
		knownChange = true
	end
	local description = " peace between " .. tribe1.name .. " and " .. tribe2.name
	if knownChange then
		description = "Signed" .. description
		log.action(description)
	else
		if havePeaceTreaty(tribe1, tribe2) then
			description = "Confirmed" .. description
		else
			description = "REPAIRED" .. description
			log.action(description)
			civ.ui.text("DIPLOMACY UPDATE: A peace treaty between " .. tribe1.name .. " and " .. tribe2.name .. " has been restored by scenario events, effective immediately. If you recently received notification that these nations had declared war, please ignore that incorrect information.")
		end
	end
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] & ~0x2000		-- remove war (bitwise "and not")
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] & ~0x0010		-- remove vendetta (bitwise "and not")
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] | 0x0005		-- add contact and peace treaty (bitwise "or")
	tribe1.attitude[tribe2] = 0
	tribe1.reputation[tribe2] = 0
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] & ~0x2000		-- remove war (bitwise "and not")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] & ~0x0010		-- remove vendetta (bitwise "and not")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] | 0x0005		-- add contact and peace treaty (bitwise "or")
	tribe2.attitude[tribe1] = 0
	tribe2.reputation[tribe1] = 0
end

local function enforceAlliance (tribe1, tribe2, knownChange) --> void
	log.trace()
	if knownChange == nil then
		knownChange = true
	end
	local description = " alliance between " .. tribe1.name .. " and " .. tribe2.name
	if knownChange then
		description = "Activated" .. description
		log.action(description)
	else
		if haveAlliance(tribe1, tribe2) then
			description = "Confirmed" .. description
		else
			description = "REPAIRED" .. description
			log.action(description)
			civ.ui.text("DIPLOMACY UPDATE: An alliance between " .. tribe1.name .. " and " .. tribe2.name .. " has been restored by scenario events, effective immediately. If you recently received notification that this alliance had been canceled, please ignore that incorrect information.")
		end
	end
	enforcePeace(tribe1, tribe2, knownChange)
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] | 0x0008	-- add alliance (bitwise "or")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] | 0x0008	-- add alliance (bitwise "or")
end

local function enforceWar (tribe1, tribe2, knownChange) --> void
	log.trace()
	if knownChange == nil then
		knownChange = true
	end
	local description = " war between " .. tribe1.name .. " and " .. tribe2.name
	if knownChange then
		description = "Declared" .. description
		log.action(description)
	else
		if haveWar(tribe1, tribe2) then
			description = "Confirmed" .. description
		else
			description = "REPAIRED" .. description
			log.action(description)
			civ.ui.text("DIPLOMACY UPDATE: A state of war between " .. tribe1.name .. " and " .. tribe2.name .. " has been restored by scenario events, effective immediately. If you recently received notification that these nations had signed a cease fire or peace treaty, please ignore that incorrect information.")
		end
	end
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] & ~0x0008		-- remove alliance (bitwise "and not")
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] & ~0x0004		-- remove peace treaty (bitwise "and not")
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] | 0x2001		-- add contact and war (bitwise "or")
	tribe1.attitude[tribe2] = 100
	tribe1.reputation[tribe2] = 100
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] & ~0x0008		-- remove alliance (bitwise "and not")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] & ~0x0004		-- remove peace treaty (bitwise "and not")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] | 0x2001		-- add contact and war (bitwise "or")
	tribe2.attitude[tribe1] = 100
	tribe2.reputation[tribe1] = 100
end

-- Replaces civlua.findTribe()
local function findByName (tribeName, blockInfoMessage) --> tribe
	log.trace()
	local tribe = nil
	for i = 0, 7 do
		local potentialTribe = civ.getTribe(i)
		if potentialTribe.name == tribeName then
			tribe = potentialTribe
			break
		end
	end
	if tribe ~= nil then
		if blockInfoMessage then
			-- Do nothing
		else
			log.info("Found tribe \"" .. tribeName .. "\" with ID " .. tribe.id)
		end
	else
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".findByName() did not find tribe with name \"" .. tostring(tribeName) .. "\"")
	end
	return tribe
end

-- Replaces civlua.findCapital()
local function findCapital (tribe) --> city
	log.trace()
	local capital = nil
	local capitalImprovement = civ.getImprovement(1)
	for city in civ.iterateCities() do
		if city.owner == tribe and civ.hasImprovement(city, capitalImprovement) then
			capital = city
			break
		end
	end
	if capital ~= nil then
		log.info("Identified " .. capital.name .. " as the " .. tribe.adjective .. " capital")
	else
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".findCapital() did not find a capital city for " .. tribe.name)
	end
	return capital
end

local function getCurrentGovernmentData (tribe, governmentNameTable) --> table (see custom definition below)
--
-- Returns a table with the following fields, containing values for the tribe's current form of government:
--	id
--	maxRate
--	maxScience
--	name
--	palaceDistance
--	scienceLost
--	settlersEat
--	support
--
	log.trace()
	local maxRateTable = { [0] = 60, [1] = 60, [2] = 70, [3] = 80, [4] = 80, [5] = 80, [6] = 100 }
	local supportTable = {
		[0] = nil,		-- varies for each city, support is equal to city.size
		[1] = nil,		-- varies for each city, support is equal to city.size
		[2] = civ.cosmic.supportMonarchy,
		[3] = civ.cosmic.supportCommunism,
		[4] = civ.cosmic.supportFundamentalism,
		[5] = 0,
		[6] = 0
	}
	local gov = {
		id = tribe.government,
		maxRate = maxRateTable[tribe.government],
		support = supportTable[tribe.government]
	}
	if governmentNameTable ~= nil then
		gov.name = governmentNameTable[tribe.government]
	end
	if tribe.government <= 2 then
		gov.settlersEat = civ.cosmic.settlersEatLow
	else
		gov.settlersEat = civ.cosmic.settlersEatHigh
	end
	if tribe.government == 3 then
		gov.palaceDistance = civ.cosmic.communismPalaceDistance
	else
		gov.palaceDistance = nil
	end
	if tribe.government == 4 then
		gov.maxScience = civ.cosmic.scienceRateFundamentalism
		gov.scienceLost = civ.cosmic.scienceLostFundamentalism
	else
		gov.maxScience = gov.maxRate
		gov.scienceLost = 0
	end
	return gov
end

-- In TOTPP 0.15.1, there is a bug in tribe.researching which can cause a crash when a tribe is not researching anything
-- The following function serves as a workaround and returns nil (as one would expect) if the tribe isn't currently researching anything
-- See https://forums.civfanatics.com/threads/totpp-lua-function-reference.557527/#post-15638458
local function getCurrentResearch (tribe) --> tech
	log.trace()
	local currentResearch = nil
	for i = 0, 99 do
		if tribe.researching == civ.getTech(i) then
			currentResearch = civ.getTech(i)
			break
		end
	end
	return currentResearch
end

local function getTotalScholarship (tribe) --> integer
	log.trace()
	local totalScholarship = 0
	for city in civ.iterateCities() do
		if city.owner == tribe and cityutil.hasAttributeCivilDisorder(city) == false then
			totalScholarship = totalScholarship + city.science
		end
	end
	return totalScholarship
end

local function isBarbarian (tribe) --> boolean
	log.trace()
	return tribe.id == 0
end

local function setTechGroupAccess (tribe, techGroup, value) --> void
	log.trace()
	local valueDesc = {
		[0] = "can research, can own",
		[1] = "can't research, can own",
		[2] = "can't research, can't own"
	}
	if tribe ~= nil and techGroup >= 0 and techGroup <= 7 and value >= 0 and value <= 2 then
		civ.enableTechGroup(tribe, techGroup, value)
		-- Note: there is no function which allows us to *check* the current value of a tech group
		-- So although this is logged as an action, it isn't necessarily making a change, but we can't be certain
		log.action("Set status of Tech Group " .. tostring(techGroup) .. " to <" .. tostring(valueDesc[value]) .. "> for " .. tribe.name)
	else
		log.error("Invalid parameters: could not set status of Tech Group " .. tostring(techGroup) .. " to " .. tostring(value) .. "> for " .. tostring(tribe.name))
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 24

return {
	confirmLoad = confirmLoad,

	changeMoney = changeMoney,
	changeResearchProgress = changeResearchProgress,
	iterateActiveTribes = iterateActiveTribes,
	hasEmbassy = hasEmbassy,
	haveContact = haveContact,
	havePeaceTreaty = havePeaceTreaty,
	haveAlliance = haveAlliance,
	haveWar = haveWar,
	hasWarWithAny = hasWarWithAny,
	enforcePeace = enforcePeace,
	enforceAlliance = enforceAlliance,
	enforceWar = enforceWar,
	findByName = findByName,
	findCapital = findCapital,
	getCurrentGovernmentData = getCurrentGovernmentData,
	getCurrentResearch = getCurrentResearch,
	getTotalScholarship = getTotalScholarship,
	isBarbarian = isBarbarian,
	setTechGroupAccess = setTechGroupAccess,
}
