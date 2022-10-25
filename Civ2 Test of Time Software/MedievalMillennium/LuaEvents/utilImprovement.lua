-- utilImprovement.lua
-- by Knighttime

-- Note: require log.lua in the main events.lua file first, in order to require and use this file.

log.trace()

local UTIL_FILE_NAME = "utilImprovement"
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
local function addImprovement (city, improvement) --> void
	log.trace()
	civ.addImprovement(city, improvement)
	log.action("Added " .. improvement.name .. " improvement to " .. city.owner.adjective .." city of " .. city.name)
end

local function removeImprovement (city, improvement) --> void
	log.trace()
	civ.removeImprovement(city, improvement)
	log.action("Removed " .. improvement.name .. " improvement from " .. city.owner.adjective .." city of " .. city.name)
end

local function findByName (impName, blockInfoMessage) --> improvement
	log.trace()
	local imp = nil
	for i = 1, 39 do
		local potentialImp = civ.getImprovement(i)
		if potentialImp.name == impName then
			imp = potentialImp
			break
		end
	end
	if imp ~= nil then
		if blockInfoMessage then
			-- Do nothing
		else
			log.info("Found improvement \"" .. impName .. "\" with ID " .. imp.id)
		end
	else
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".findByName() did not find improvement with name \"" .. tostring(impName) .. "\"")
	end
	return imp
end

local function isSpaceship (improvement) --> boolean
	log.trace()
	if improvement.id == 36 or improvement.id == 37 or improvement.id == 38 then
		return true
	else
		return false
	end
end

local function iterateImprovements () --> iterator (of improvement objects)
	log.trace()
	return coroutine.wrap(function ()
		-- Improvement 0 is "Nothing" so the first actual improvement has id 1
		for i = 1, 39 do
			local imp = civ.getImprovement(i)
			coroutine.yield(imp)
		end
	end)
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 10

return {
	confirmLoad = confirmLoad,

	addImprovement = addImprovement,
	removeImprovement = removeImprovement,
	findByName = findByName,
	isSpaceship = isSpaceship,
	iterateImprovements = iterateImprovements,
}
