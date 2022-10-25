-- utilTech.lua
-- by Knighttime

-- Note: require log.lua in the main events.lua file first, in order to require and use this file.

log.trace()

local UTIL_FILE_NAME = "utilTech"
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
-- This is also called internally by findByName() and getNumTechsKnown() and must be declared prior to them in this file:
local function iterateTechs () --> iterator (of tech objects)
	log.trace()
	return coroutine.wrap(function ()
		for i = 0, 99 do
			local tech = civ.getTech(i)
			coroutine.yield(tech)
		end
	end)
end

local function findByName (techName, blockInfoMessage) --> tech
	log.trace()
	local tech = nil
	for potentialTech in iterateTechs() do
		if potentialTech.name == techName then
			tech = potentialTech
			break
		end
	end
	if tech ~= nil then
		if blockInfoMessage then
			-- Do nothing
		else
			log.info("Found tech \"" .. techName .. "\" with ID " .. tech.id)
		end
	else
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".findByName() did not find tech with name \"" .. tostring(techName) .. "\"")
	end
	return tech
end

local function getNumTechsKnown (tribe) --> integer
	-- tribe.numTechs does not contain what the documentation says it does (which admittedly would be logical)
	-- The total count of techs known by a tribe must therefore be calculated
	log.trace()
	local techsKnown = 0
	if tribe ~= nil then
		for tech in iterateTechs() do
			if civ.hasTech(tribe, tech) then
				techsKnown = techsKnown + 1
			end
		end
	end
	return techsKnown
end

local function getTechResearchNumber (tribe) --> integer
	-- tribe.numTechs does not contain what the documentation says it does (which admittedly would be logical)
	-- Instead, this tells you what number tech you are trying to acquire *during* actual game turns
	-- That is, it is equal to your total techs known, minus any starting techs you received at the beginning of the game, plus 1
	log.trace()
	return tribe.numTechs
end

local function getDependentSet (tech) --> table (of tech objects)
	-- Returns the full set of all techs that are directly (child) or indirectly (descendent) dependent upon the parameter tech
	-- Ignores tech groups and any restrictions upon them, and ignores the ability to acquire a tech for which you do not have the prerequisite(s) by goody hut, stealing, or trading
	log.trace()
	local checkSet = { }
	if tech ~= nil and civ.isTech(tech) then
		table.insert(checkSet, tech)
	end
	local workingSet = { }
	while #checkSet > 0 do
		local tech = checkSet[1]
		table.remove(checkSet, 1)
		for i = 0, 99 do
			if workingSet[i] == nil then
				local check = civ.getTech(i)
				if check.prereq1 == tech or check.prereq2 == tech then
					workingSet[check.id] = true
					table.insert(checkSet, check)
				end
			end
		end
	end
	local dependentSet = { }
	for i = 0, 99 do
		if workingSet[i] == true then
			table.insert(dependentSet, civ.getTech(i))
		end
	end
	return dependentSet
end

local function getPrereqSet (tech) --> table (of tech objects)
	-- Returns the full set of all techs that are direct (parent) or indirect (ancestor) prerequisites for the parameter tech to be researched
	-- Ignores tech groups and any restrictions upon them, and ignores the ability to acquire a tech for which you do not have the prerequisite(s) by goody hut, stealing, or trading
	log.trace()
	local checkSet = { }
	if tech ~= nil and civ.isTech(tech) then
		table.insert(checkSet, tech)
	end
	local workingSet = { }
	while #checkSet > 0 do
		local tech = checkSet[1]
		table.remove(checkSet, 1)
		if tech.prereq1 ~= nil and workingSet[tech.prereq1.id] == nil then
			workingSet[tech.prereq1.id] = true
			table.insert(checkSet, tech.prereq1)
		end
		if tech.prereq2 ~= nil and workingSet[tech.prereq2.id] == nil then
			workingSet[tech.prereq2.id] = true
			table.insert(checkSet, tech.prereq2)
		end
	end
	local prereqSet = { }
	for i = 0, 99 do
		if workingSet[i] == true then
			table.insert(prereqSet, civ.getTech(i))
		end
	end
	return prereqSet
end

-- This is also called internally by grantTechByName() and must be declared prior to it in this file:
local function grantTech (tribe, tech) --> void
	log.trace()
	civ.giveTech(tribe, tech)
	log.action("Gave \"" .. tech.name .. "\" tech (ID " .. tech.id .. ") to " .. tribe.name)
end

local function grantTechByName (tribe, techName) --> void
	log.trace()
	local tech = findByName(techName, true)
	if tech ~= nil then
		grantTech(tribe, tech)
	end
end

-- This is also called internally by knownByAll() and knownByAny() and must be declared prior to them in this file:
local function knownByTribe (tribe, tech) --> boolean
	log.trace()
	return civ.hasTech(tribe, tech)
end

-- This repeats logic used in utilTribe.iterateActiveTribes(), to avoid interdependencies between utility files
local function knownByAll (tech) --> boolean
	log.trace()
	local result = true
	for i = 1, 7 do
		local tribe = civ.getTribe(i)
		if tribe ~= nil and tribe.active then
			if not(knownByTribe(tribe, tech)) then
				result = false
			end
		end
	end
	return result
end

-- This repeats logic used in utilTribe.iterateActiveTribes(), to avoid interdependencies between utility files
local function knownByAllOther (tribe, tech) --> boolean
	log.trace()
	local result = true
	for i = 1, 7 do
		local otherTribe = civ.getTribe(i)
		if otherTribe ~= nil and otherTribe ~= tribe and otherTribe.active then
			if not(knownByTribe(otherTribe, tech)) then
				result = false
			end
		end
	end
	return result
end

-- This repeats logic used in utilTribe.iterateActiveTribes(), to avoid interdependencies between utility files
-- tech.researched returns whether or not *any* tribe has researched the tech;
--		it's not obvious whether that could include inactive tribes, or whether it would remain true if the tech was programmatically taken away
-- This function returns true only if an *active* (non-barbarian) tribe *currently* possesses the tech
local function knownByAny (tech) --> boolean
	log.trace()
	local result = false
	for i = 1, 7 do
		local tribe = civ.getTribe(i)
		if tribe ~= nil and tribe.active then
			if knownByTribe(tribe, tech) then
				result = true
			end
		end
	end
	return result
end

-- This repeats logic used in utilTribe.iterateActiveTribes(), to avoid interdependencies between utility files
local function numTribesKnownBy (tech) --> integer
	log.trace()
	local count = 0
	for i = 1, 7 do
		local tribe = civ.getTribe(i)
		if tribe ~= nil and tribe.active and civ.hasTech(tribe, tech) then
			count = count + 1
		end
	end
	return count
end

-- This is also called internally by revokeTechByName() and must be declared prior to it in this file:
local function revokeTech (tribe, tech) --> void
	log.trace()
	civ.takeTech(tribe, tech)
	log.action("Removed \"" .. tech.name .. "\" tech (ID " .. tech.id .. ") from " .. tribe.name)
end

local function revokeTechByName (tribe, techName) --> void
	log.trace()
	local tech = findByName(techName, true)
	if tech ~= nil then
		revokeTech(tribe, tech)
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 21

-- Note: see utilTribe.lua for getCurrentResearch() and setTechGroupAccess()
return {
	confirmLoad = confirmLoad,

	iterateTechs = iterateTechs,
	findByName = findByName,
	getNumTechsKnown = getNumTechsKnown,
	getTechResearchNumber = getTechResearchNumber,
	getDependentSet = getDependentSet,
	getPrereqSet = getPrereqSet,
	grantTech = grantTech,
	grantTechByName = grantTechByName,
	knownByTribe = knownByTribe,
	knownByAll = knownByAll,
	knownByAllOther = knownByAllOther,
	knownByAny = knownByAny,
	numTribesKnownBy = numTribesKnownBy,
	revokeTech = revokeTech,
	revokeTechByName = revokeTechByName,
}
