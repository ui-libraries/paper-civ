-- globalFunctions.lua
-- by Knighttime

-- Note: require log.lua in the main events.lua file first, in order to require and use this file.

log.trace()

local FILE_NAME = "globalFunctions"
local FILE_VERSION = 1.00

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
local function confirmLoad (requiredVersion) --> boolean
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " v" .. FILE_VERSION .. " loaded successfully")
	if requiredVersion ~= nil and requiredVersion > FILE_VERSION then
		log.error("Version " .. requiredVersion .. " of " .. FILE_NAME .. ".lua is required, but a lower version (" .. FILE_VERSION .. ") was found. Please download and install an updated version of this Lua utility file, and then restart the game. If you fail to do so, Lua events may crash or not work as intended.")
		log.action("")
		return false
	end
	log.info("")
	return true
end

-- ================================================
-- ••••••••••••••• GLOBAL FUNCTIONS •••••••••••••••
-- ================================================
-- Returns the median of the numeric values contained in a table, without modifying that original table
-- Credit to http://lua-users.org/wiki/SimpleStats
function median (myTable) --> decimal
	local tempTable = { }
	for _, value in pairs(myTable) do
		if type(value) == "number" then
			table.insert(tempTable, value)
		end
	end
	table.sort(tempTable)
	if math.fmod(#tempTable, 2) == 0 then
		return (tempTable[#tempTable / 2] + tempTable[(#tempTable / 2) + 1]) / 2
	else
		return tempTable[math.ceil(#tempTable / 2)]
	end
end

-- Rounds a numeric value to the nearest integer and returns the integer
function round (decimal) --> integer
	return math.floor(decimal + 0.5)
end

-- Replaces functions.split() by TheNamelessOne
-- Credit to https://stackoverflow.com/questions/19262761/lua-need-to-split-at-comma
-- Note that this looks for a *pattern* so some characters such as a period (.) may
-- 		need to be escaped with a % symbol
function string:split (inSplitPattern, outResults) --> table (of strings)
	if not outResults then
		outResults = { }
	end
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	while theSplitStart do
		table.insert( outResults, string.sub( self, theStart, theSplitStart - 1 ) )
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	end
	table.insert( outResults, string.sub( self, theStart ) )
	return outResults
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 4

return {
	confirmLoad = confirmLoad,
}
