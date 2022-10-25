-- utilWonder.lua
-- by Knighttime

-- Note: require log.lua in the main events.lua file first, in order to require and use this file.

log.trace()

local UTIL_FILE_NAME = "utilWonder"
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
local function addWonder (city, wonder) --> void
	log.trace()
	if wonder.city ~= nil then
		log.warning("WARNING: Cannot add " .. wonder.name .. " wonder to " .. city.owner.adjective .. " city of " .. city.name .. " because it is already present in " .. wonder.city.owner.adjective .. " city of " .. wonder.city.name)
	elseif wonder.destroyed then
		log.warning("WARNING: Cannot add " .. wonder.name .. " wonder to " .. city.owner.adjective .. " city of " .. city.name .. " because it has previously been destroyed")
	else
		wonder.city = city
		log.action("Added " .. wonder.name .. " wonder to " .. city.owner.adjective .." city of " .. city.name)
	end
end

local function destroyWonder (wonder) --> void
	log.trace()
	if wonder.destroyed then
		log.info(wonder.name .. " wonder has already been destroyed")
	elseif wonder.city == nil then
		log.warning("WARNING: Cannot destroy " .. wonder.name .. " wonder because it has never been built")
	else
		local builtByCity = wonder.city
		civ.destroyWonder(wonder)
		log.action("Destroyed " .. wonder.name .. " wonder in " .. builtByCity.owner.adjective .. " city of " .. builtByCity.name)
	end
end

local function removeWonder (city, wonder) --> void
	log.trace()
	-- This "unbuilds" the wonder, enabling it to be constructed again (potentially elsewhere). See destroyWonder() for the alternative.
	if wonder.city == nil or wonder.city ~= city then
		log.warning("WARNING: Cannot remove " .. wonder.name .. " from " .. city.owner.adjective .. " city of " .. city.name .. " because it is not present there")
	else
		wonder.city = nil
		log.action("Removed " .. wonder.name .. " wonder from " .. city.owner.adjective .." city of " .. city.name)
	end
end

local function findByName (wonderName, blockInfoMessage) --> wonder
	log.trace()
	local wonder = nil
	for i = 0, 27 do
		local potentialWonder = civ.getWonder(i)
		if potentialWonder.name == wonderName then
			wonder = potentialWonder
			break
		end
	end
	if wonder ~= nil then
		if blockInfoMessage then
			-- Do nothing
		else
			log.info("Found wonder \"" .. wonderName .. "\" with ID " .. wonder.id)
		end
	else
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".findByName() did not find wonder with name \"" .. tostring(wonderName) .. "\"")
	end
	return wonder
end

local function getOwner (wonder) --> tribe
	log.trace()
	if wonder.city ~= nil then
		return wonder.city.owner
	else
		return nil
	end
end

local function hasBeenBuilt (wonder) --> boolean
	log.trace()
	if wonder.city ~= nil or wonder.destroyed then
		return true
	else
		return false
	end
end

local function isEffective (wonder) --> boolean
	-- A wonder is effective (in effect) if it has been built and has not expired
	log.trace()
	if getOwner(wonder) ~= nil and
	   (wonder.expires == nil or wonder.expires.researched == false) then
		return true
	else
		return false
	end
end

local function iterateWonders () --> iterator (of wonder objects)
	log.trace()
	return coroutine.wrap(function ()
		-- Unlike improvements, wonder ids are zero-based:
		for i = 0, 27 do
			local wonder = civ.getWonder(i)
			coroutine.yield(wonder)
		end
	end)
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 13

return {
	confirmLoad = confirmLoad,

	addWonder = addWonder,
	destroyWonder = destroyWonder,
	removeWonder = removeWonder,
	findByName = findByName,
	getOwner = getOwner,
	hasBeenBuilt = hasBeenBuilt,
	isEffective = isEffective,
	iterateWonders = iterateWonders,
}
