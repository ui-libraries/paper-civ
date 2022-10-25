-- utilTile.lua
-- by Knighttime

-- Note: require globalFunctions.lua in the main events.lua file first, in order to require and use this file.
-- Note: require log.lua in the main events.lua file first, in order to require and use this file.

log.trace()

local UTIL_FILE_NAME = "utilTile"
local UTIL_FILE_VERSION = 0.80

-- GLOBAL CONSTANTS:
-- Note that civlua defines "terrain" which is the same but uses lowercase keys.
-- Defining contants with these names here because they are more descriptive, and allow you to define
--		customized "terrainId" and "terrainName" constants within a scenario-specific events file if you wish.
baseTerrainId = {	Desert = 0,
					Plains = 1,
					Grassland = 2,
					Forest = 3,
					Hills = 4,
					Mountains = 5,
					Tundra = 6,
					Glacier = 7,
					Swamp = 8,
					Jungle = 9,
					Ocean = 10 }
baseTerrainName = {	[0] = "Desert",
					[1] = "Plains",
					[2] = "Grassland",
					[3] = "Forest",
					[4] = "Hills",
					[5] = "Mountains",
					[6] = "Tundra",
					[7] = "Glacier",
					[8] = "Swamp",
					[9] = "Jungle",
					[10] = "Ocean" }

WORKER_MASK_FOR_CITY_RADIUS_TILES = { [1] = 0x080000,
									  [2] = 0x001000,
									  [3] = 0x000800,
									  [4] = 0x000080,
									  [5] = 0x000100,
									  [6] = 0x040000,
									  [7] = 0x000040,
									  [8] = 0x000001,
									  [9] = 0x002000,
									 [10] = 0x000020,
									 [11] = 0x100000,	-- City tile
									 [12] = 0x000002,
									 [13] = 0x020000,
									 [14] = 0x000010,
									 [15] = 0x000004,
									 [16] = 0x004000,
									 [17] = 0x000400,
									 [18] = 0x000008,
									 [19] = 0x000200,
									 [20] = 0x010000,
									 [21] = 0x008000 }

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

-- ===========================================================
-- ••••••••••••••• STRICTLY INTERNAL FUNCTIONS •••••••••••••••
-- ===========================================================
-- Note that "radius" as used here is measuring map coordinate intervals, not movement distance
-- This is an internal function only to avoid confusion. Many external functions are defined which access this.
local function getTilesByRadius (tile, radius, includeOriginTile) --> table (of tile and possibly boolean objects)
	-- For an odd-numbered radius, we will use the next-larger even-numbered
	-- radius, and then ignore the four furthest cardinal points.
	log.trace()
	includeOriginTile = includeOriginTile or false
	local useRadius = radius + (radius % 2)
	local tileSet = { }
	for ycoord = tile.y - useRadius, tile.y + useRadius do
		for xcoord = tile.x - useRadius, tile.x + useRadius do
			local xdif = math.abs(xcoord - tile.x)
			local ydif = math.abs(ycoord - tile.y)
			if (xcoord + ycoord) % 2 == 0 and						-- all valid map coordinates sum to an even number
			   (xdif + ydif) <= useRadius and						-- limits to tiles with valid *combinations* of x and y
			   ( radius % 2 == 0 or									-- EITHER the true radius is an even number,
				 (xdif < useRadius and ydif < useRadius) ) then		--	   OR (the true radius is an odd number and) the tile is not a furthest cardinal point

				local thisTile = civ.getTile(xcoord, ycoord, tile.z)
				if thisTile ~= nil and
				   ((xdif == 0 and ydif == 0 and includeOriginTile) or (not(xdif == 0 and ydif == 0))) then		-- include origin tile only if requested
					table.insert(tileSet, thisTile)
				else
					table.insert(tileSet, false)
				end
			end
		end
	end
	return tileSet
end

-- This is a copy of utilCity.getSpecialistsByType(), copied here to avoid dependencies between utility modules, and renamed for context
local function getCitySpecialistsByType (city) --> integer, integer, integer
	-- Returns the number of Entertainers, Taxmen, and Scientists currently present in a city, in that order
	log.trace()
	local numEntertainers = 0
	local numTaxmen = 0
	local numScientists = 0
	local specialistsBitValue = city.specialists
	while specialistsBitValue > 0 do
		if specialistsBitValue & 0x03 == 0x01 then
			numEntertainers = numEntertainers + 1
		elseif specialistsBitValue & 0x03 == 0x02 then
			numTaxmen = numTaxmen + 1
		elseif specialistsBitValue & 0x03 == 0x03 then
			numScientists = numScientists + 1
		end
		specialistsBitValue = specialistsBitValue >> 2
	end
	return numEntertainers, numTaxmen, numScientists
end

local function setCitySpecialistsByType (city, numEntertainers, numTaxmen, numScientists) --> void
	log.trace()
	if city.size < 5 then
		if numTaxmen > 0 then
			log.warning("WARNING: Could not assign specialist as Taxman in " .. city.name .. " (city " .. city.id .. ") because it only has " .. city.size .. " citizens")
			numEntertainers = numEntertainers + numTaxmen
			numTaxmen = 0
		end
		if numScientists > 0 then
			log.warning("WARNING: Could not assign specialist as Scientist in " .. city.name .. " (city " .. city.id .. ") because it only has " .. city.size .. " citizens")
			numEntertainers = numEntertainers + numScientists
			numScientists = 0
		end
	end
	local remainingEntertainers = numEntertainers
	local remainingTaxmen = numTaxmen
	local remainingScientists = numScientists
	local specialistsBitValue = 0x00
	while (remainingEntertainers + remainingTaxmen + remainingScientists) > 0 do
		local specialistType = 0x00
		if remainingScientists > 0 then
			specialistType = 0x03
			remainingScientists = remainingScientists - 1
		elseif remainingTaxmen > 0 then
			specialistType = 0x02
			remainingTaxmen = remainingTaxmen - 1
		else
			specialistType = 0x01
			remainingEntertainers = remainingEntertainers - 1
		end
		if specialistsBitValue ~= 0x00 then
			specialistsBitValue = specialistsBitValue << 2
		end
		specialistsBitValue = specialistsBitValue | specialistType
	end
	city.specialists = specialistsBitValue
	log.action("Assigned specialists in " .. city.name .. " (city " .. city.id .. "): " .. numEntertainers .. " entertainers, " .. numTaxmen .. " taxmen, " .. numScientists .. " scientists")
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function getMapTileCount () --> integer
	log.trace()
	local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()
	return (mapWidth * mapHeight) / 2
end

local function getTileId (tile) --> integer
	log.trace()
	if tile == nil then
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".getTileId() called with an invalid tile (input parameter is nil)")
		return nil
	end
	local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()
	local mapOffset = tile.z * mapWidth * mapHeight
	local tileOffset = tile.x + (tile.y * mapWidth)
	return mapOffset + tileOffset
end

local function getTileById (tileId) --> tile
	log.trace()
	local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()
	local mapOffset = mapWidth * mapHeight
	local z = math.floor(tileId / mapOffset)
	local tileOffset = tileId % mapOffset
	local x = tileOffset % mapWidth
	local y = math.floor((tileOffset - x) / mapWidth)
	local tile = civ.getTile(x, y, z)
	if tile == nil then
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".getTileById() did not find a valid tile (returning nil)")
	end
	return tile
end

-- Determines the battle tile after a battle is over; intended to be run in civ.scen.onUnitKilled() trigger
-- Determining the battle tile at an earlier point is also possible, in civ.scen.onResolveCombat(), in which case this function isn't needed
local function getBattleTile (winningUnit, losingUnit) --> tile
--[[
	The location of the winner is the tile on which the winner (whether attacker or defender) is standing when the battle is over.
		You don't move into the tile when you win a battle, even if you defeated the last/only defender there
	The location of the loser is SOMETIMES an invalid coordinate such as "65336, 65336" or "64536, 64536"
		Other times, it correctly shows the tile on which the loser was standing before they were killed
	Battle tile is always that of the DEFENDER. Therefore, we need to determine if the defender was the winner or loser.
	Based on testing: if the loser has a    valid coordinate, that means they were the DEFENDER.
					  if the loser has an INvalid coordinate, that means they were the ATTACKER.
]]
	log.trace()
	local isValidTile = civ.getTile(losingUnit.location.x, losingUnit.location.y, losingUnit.location.z)
	if isValidTile == nil then
		-- losingUnit was the attacker; battle occurred on the tile of the winning defender
		return winningUnit.location
	else
		-- losingUnit was the defender; battle occurred on the tile of the losing defender
		return losingUnit.location
	end
	-- Note that if the loser was the attacker, we are unable to calculate the tile they attacked FROM
	-- This information needs to be collected at the beginning of (or during) the battle, not after it is over
	--		i.e., in civ.scen.onResolveCombat() and not civ.scen.onUnitKilled()
end

local function getIntercardinalTiles (tile, includeOriginTile) --> table (of tile and possibly boolean objects)
--[[
	Returns the [up to] 5 tiles that share an *edge*, not just a point.
	Note that order is important here: top to bottom, and then left to right:
		1		2
			3
		4		5
	This allows you to look at the key in the returned tileset to know the relative location.
	Note that the first table element in Lua has index 1, not 0, so the above diagram is correct.

**	The returned table will always contain exactly 5 entries. If includeOriginTile is true,
	element 3 will contain the tile passed in as the first argument; otherwise, this element
	will contain false. If any other location is not a valid tile, the table will also store
	false in that entry. Use civ.isTile() to determine if each table entry is a tile or not.

	These are "intercardinal" because they align with the compass points NW, NE, SW, and SE on Civ2's diagonal grid.
]]
	log.trace()
	local result = getTilesByRadius(tile, 1, includeOriginTile)
	return result
end

local function getAdjacentTiles (tile, includeOriginTile) --> table (of tile and possibly boolean objects)
--[[
	Returns the [up to] 9 tiles that share either an edge or a point.
	Note that order is important here: top to bottom, and then left to right:
	-		1		-
		2		3
	4		5		6
		7		8
	-		9		-
	This allows you to look at the key in the returned tileset to know the relative location.
	Note that the first table element in Lua has index 1, not 0, so the above diagram is correct.

**	The returned table will always contain exactly 9 entries. If includeOriginTile is true,
	element 5 will contain the tile passed in as the first argument; otherwise, this element
	will contain false. If any other location is not a valid tile, the table will also store
	false in that entry. Use civ.isTile() to determine if each table entry is a tile or not.
]]
	log.trace()
	local result = getTilesByRadius(tile, 2, includeOriginTile)
	return result
end

local function getCardinalTiles (tile, includeOriginTile) --> table (of tile and possibly boolean objects)
--[[
	Returns the [up to] 5 tiles that share a *point*, excluding those that share an edge
	Note that order is important here: top to bottom, and then left to right:
	-		1		-
		-		-
	2		3		4
		-		-
	-		5		-
	This allows you to look at the key in the returned tileset to know the relative location.
	Note that the first table element in Lua has index 1, not 0, so the above diagram is correct.

**	The returned table will always contain exactly 5 entries. If includeOriginTile is true,
	element 3 will contain the tile passed in as the first argument; otherwise, this element
	will contain false. If any other location is not a valid tile, the table will also store
	false in that entry. Use civ.isTile() to determine if each table entry is a tile or not.

	These are "cardinal" because they align with the compass points N, W, E, and S on Civ2's diagonal grid.
]]
	log.trace()
	local adjacentTiles = getAdjacentTiles(tile, includeOriginTile)
	local tileSet = { }
		table.insert(tileSet, adjacentTiles[1])
		table.insert(tileSet, adjacentTiles[4])
		table.insert(tileSet, adjacentTiles[5])
		table.insert(tileSet, adjacentTiles[6])
		table.insert(tileSet, adjacentTiles[9])
	return tileSet
end

local function getCityRadiusTiles (object, includeOriginTile) --> table (of tile and possibly boolean objects)
--[[
	Object must be a city or tile.
	Returns the [up to] 21 tiles that fall within a standard city radius.
	Note that order is important here: top to bottom, and then left to right:
	-		1		2		-
		3		4		5
	6		7		8		9
		10		11		12
	13		14		15		16
		17		18		19
	-		20		21		-
	This allows you to look at the key in the returned tileset to know the relative location.
	Note that the first table element in Lua has index 1, not 0, so the above diagram is correct.

**	The returned table will always contain exactly 21 entries. If includeOriginTile is true,
	element 11 will contain the location of the object passed in as the first argument; otherwise,
	this element will contain false. If any other location is not a valid tile, the table will also store
	false in that entry. Use civ.isTile() to determine if each table entry is a tile or not.
]]
	log.trace()
	local tile = nil
	if civ.isCity(object) then
		tile = object.location
	elseif civ.isTile(object) then
		tile = object
	else
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".getCityRadiusTiles() called with an object that is not a city or tile")
		return { }
	end
	local result = getTilesByRadius(tile, 3, includeOriginTile)
	return result
end

local function getCityOuterRadiusTiles (object) --> table (of tile and possibly boolean objects)
--[[
	Object must be a city or tile.
	Returns all 12 city radius tiles (if valid map tiles) that are not directly adjacent.
	Does not include the location of the object itself.
	getAdjacentTiles + getCityOuterRadiusTiles = getCityRadiusTiles
	Note that order is important here: top to bottom, and then left to right:
	-		1		2		-
		3		-		4
	5		-		-		6
		-		X		-
	7		-		-		8
		9		-		10
	-		11		12		-
	This allows you to look at the key in the returned tileset to know the relative location.
	Note that the first table element in Lua has index 1, not 0, so the above diagram is correct.

**	The returned table will always contain exactly 12 entries. If any location is not a valid tile,
	the table will store false in that entry. Use civ.isTile() to determine if eacj table entry
	is a tile or not.
]]
	log.trace()
	local cityRadiusTiles = getCityRadiusTiles(object)
	local tileSet = { }
		table.insert(tileSet, cityRadiusTiles[1])
		table.insert(tileSet, cityRadiusTiles[2])
		table.insert(tileSet, cityRadiusTiles[3])
		table.insert(tileSet, cityRadiusTiles[5])
		table.insert(tileSet, cityRadiusTiles[6])
		table.insert(tileSet, cityRadiusTiles[9])
		table.insert(tileSet, cityRadiusTiles[13])
		table.insert(tileSet, cityRadiusTiles[16])
		table.insert(tileSet, cityRadiusTiles[17])
		table.insert(tileSet, cityRadiusTiles[19])
		table.insert(tileSet, cityRadiusTiles[20])
		table.insert(tileSet, cityRadiusTiles[21])
	return tileSet
end

local function getTilesByDistance (tile, distance, includeOriginTile) --> table (of tile and possibly boolean objects)
--[[
	Table elements contain tiles in sequential order, top to bottom and then left to right.
	The number of elements in the returned table is dependent on the distance parameter.
	If includeOriginTile is true, the tile passed as the first parameter will be included
	in the results; otherwise, the table element corresponding to that location will contain
	false. If any other location is not	a valid tile, the table will also store	false in that
	entry. Use civ.isTile() to determine if each table entry is a tile or not.

	Normal usage is to call this with integer values. Calling this with fractional values (specifically half-points) allows
	you to clip off cardinal corners from the returned tileset. For example, calling this with a distance of 1.5 would
	match the functionality of getCityRadiusTiles().
]]
	log.trace()
	if distance < 0 then
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".getTilesByDistance() called with distance of " .. distance)
		return nil
	elseif distance == 0 then
		local tileSet = { }
		if includeOriginTile then
			table.insert(tileSet, tile)
		end
		return tileSet
	else
		-- local tileSet = getTilesByRadius(tile, math.floor(distance) * 2, includeOriginTile)
		local tileSet = getTilesByRadius(tile, round(distance * 2), includeOriginTile)
		return tileSet
	end
end

local function getDistance (tile1, tile2) --> integer
	log.trace()
	if tile1 == nil or tile2 == nil or tile1.z ~= tile2.z then
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".getDistance() called with invalid tiles")
		return nil
	else
		local xMoves = math.abs(tile1.x - tile2.x) / 2
		local yMoves = math.abs(tile1.y - tile2.y) / 2
		return math.ceil(xMoves + yMoves)
	end
end

local function getTerrainId (tile) --> integer
--[[
	Returns a number in the range 0 to 15
		Desert is 0, Ocean is 10, additional TOTPP terrain types go on from there, 11 through 15
	Tiles with "specials" get the same type as tiles without specials
		TOTPP 0.15.1 does not support the ability to identify whether or not a tile has a special
]]
	log.trace()
	if tile == nil then
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".getTerrainId() called with an invalid tile (input parameter is nil)")
		return nil
	end
	return tile.terrainType & 0x0F
end

local function setTerrainId (tile, newTerrainId, terrainNameTable, redrawTile) --> void
	log.trace()
	local oldTerrainId = getTerrainId(tile)
	local oldTerrainName = baseTerrainName[oldTerrainId]
	local newTerrainName = baseTerrainName[newTerrainId]
	if terrainNameTable ~= nil then
		oldTerrainName = terrainNameTable[oldTerrainId]
		newTerrainName = terrainNameTable[newTerrainId]
	end
	if oldTerrainId == newTerrainId then
		log.info("Terrain at " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " is already " .. newTerrainName)
	else
		tile.terrainType = newTerrainId
		log.action("Converted terrain at " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " from " .. oldTerrainName .. " to " .. newTerrainName)
		if redrawTile then
			civ.ui.redrawTile(tile)
		end
	end
end

local function isLandTile (tile) --> boolean
	-- Intentionally repeats some logic from getTerrainId(), for efficiency
	log.trace()
	if tile == nil then
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".isLandTile() called with an invalid tile (input parameter is nil)")
		return false
	end
	if (tile.terrainType & 0x0F) ~= baseTerrainId.Ocean then
		return true
	else
		return false
	end
end

local function isWaterTile (tile) --> boolean
	-- Intentionally repeats some logic from getTerrainId(), for efficiency
	log.trace()
	if tile == nil then
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".isLandTile() called with an invalid tile (input parameter is nil)")
		return false
	end
	if (tile.terrainType & 0x0F) == baseTerrainId.Ocean then
		return true
	else
		return false
	end
end

local function getTerrainBodySize (tile, threshhold) --> integer
	-- For better performance, the threshhold parameter allows you to cap the terrain body size that needs to be checked
	-- Once the threshhold is met, the function will abandon calculations and return that number as the terrain body size
	log.trace()
	local matchingFunction = nil
	if isLandTile(tile) then
		matchingFunction = isLandTile
	else
		matchingFunction = isWaterTile
	end
	local terrainBodySize = 1
	local tilesEncountered = { }
	tilesEncountered[getTileId(tile)] = true
	local tilesNotYetConsidered = { }
	table.insert(tilesNotYetConsidered, tile)
	while #tilesNotYetConsidered > 0 do
		local consideringTile = tilesNotYetConsidered[1]
		table.remove(tilesNotYetConsidered, 1)
		for _, adjTile in ipairs(getAdjacentTiles(consideringTile, false)) do
			if civ.isTile(adjTile) then
				local adjTileId = getTileId(adjTile)
				if tilesEncountered[adjTileId] == nil then
					if matchingFunction(adjTile) then
						terrainBodySize = terrainBodySize + 1
						if terrainBodySize >= threshhold then
							break
						end
						tilesEncountered[adjTileId] = true
						table.insert(tilesNotYetConsidered, adjTile)
					end
				end
			end
		end
		if terrainBodySize >= threshhold then
			break
		end
	end
	return terrainBodySize
end

local function getCityRadiusLandTiles (object, includeOriginTile) --> table (of tile objects)
--[[
	Object must be a city or tile.
	Note that order/position is *not* important or significant here.
	The returned table will only contain valid city radius land tiles.
	The city tile itself is always a land tile; it will be included if includeOriginTile is true, otherwise not.
	The size of the table will therefore be 0 to 21 entries.
]]
	log.trace()
	local cityRadiusLandTiles = {}
	for _, tile in ipairs(getCityRadiusTiles(object, includeOriginTile)) do
		if civ.isTile(tile) then
			if isLandTile(tile) then
				table.insert(cityRadiusLandTiles, tile)
			end
		end
	end
	return cityRadiusLandTiles
end

local function getCityTilesWorked (city, includeOriginTile) --> table (of tile objects)
--[[
	Note that order/position is *not* important or significant here.
	The returned table will only contain valid city radius tiles (land or water).
	The city tile itself is always worked; it will be included if includeOriginTile is true, otherwise not.
	The size of the table will therefore be 0 to 21 entries.
]]
	log.trace()
	local tilesWorked = {}
	for tilePosition, tile in ipairs(getCityRadiusTiles(city, includeOriginTile)) do
		local hexMask = WORKER_MASK_FOR_CITY_RADIUS_TILES[tilePosition]
		if civ.isTile(tile) then
			if city.workers & hexMask == hexMask then
				table.insert(tilesWorked, tile)
			end
		end
	end
	return tilesWorked
end

local function setCityTilesWorked (city, tileSet) --> void
	log.trace()
	local numTilesToWork = 0
	if type(tileSet) == "table" then
		numTilesToWork = #tileSet
	end
	local numCitizens = city.size
	if numTilesToWork > numCitizens then
		log.error("ERROR! Attempted to set " .. city.name .. " (ID " .. city.id .. ") to work " .. numTilesToWork .. " tiles, but it only has " .. numCitizens .. " citizens")
	else
		local numSpecialists = city.size
		local numTilesWorked = 0
		local tilesWorked = 0x100000
		for tilePosition, tile in ipairs(getCityRadiusTiles(city, includeOriginTile)) do
			local hexMask = WORKER_MASK_FOR_CITY_RADIUS_TILES[tilePosition]
			if civ.isTile(tile) then
				local presentInTileSet = false
				if type(tileSet) == "table" then
					for _, workTile in ipairs(tileSet) do
						if workTile == tile then
							presentInTileSet = true
							break
						end
					end
				end
				if presentInTileSet then
					tilesWorked = tilesWorked | hexMask
					numSpecialists = numSpecialists - 1
					numTilesWorked = numTilesWorked + 1
					if numSpecialists < 0 then
						log.error("ERROR! Calculated that " .. city.name .. " (ID " .. city.id .. ") should have " .. numSpecialists .. " specialists, which is impossible")
					end
				end
			end
		end
		-- Retrieve current specialist assignments before writing anything back to the city object:
		local currEntertainers, currTaxmen, currScientists = getCitySpecialistsByType(city)
		-- Calculate and assign the "workers" value:
		local specialistsAsWorkers = numSpecialists * 4 * (16 ^ 6)
		local combinedWorkers = specialistsAsWorkers + tilesWorked
		city.workers = combinedWorkers
		log.action("Assigned " .. city.name .. " (city " .. city.id .. ") to work " .. numTilesWorked .. " tiles, with " .. numSpecialists .. " specialists")
		-- Calculate the desired quantity of each specialist:
		local specialistsToAssign = numSpecialists
		local newEntertainers = math.min(currEntertainers, specialistsToAssign)
		specialistsToAssign = specialistsToAssign - newEntertainers
		local newTaxmen = math.min(currTaxmen, specialistsToAssign)
		specialistsToAssign = specialistsToAssign - newTaxmen
		local newScientists = math.min(currScientists, specialistsToAssign)
		specialistsToAssign = specialistsToAssign - newScientists
		newEntertainers = newEntertainers + specialistsToAssign
		-- Calculate and assign the "specialists" value:
		if newEntertainers ~= currEntertainers or newTaxmen ~= currTaxmen or newScientists ~= currScientists then
			setCitySpecialistsByType(city, newEntertainers, newTaxmen, newScientists)
		end
	end
end

local function isMapEdge (tile) --> boolean
	log.trace()
	local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()
	if	tile.y == 0 or tile.y == 1 or
		tile.y == mapHeight - 1 or tile.y == mapHeight - 2 or
		tile.x == 0 or tile.x == 1 or
		tile.x == mapWidth - 1 or tile.x == mapWidth - 2 then
		return true
	else
		return false
	end
end

local function isPriorTile (tile1, tile2) --> boolean
	-- Read as, "is [tile1] prior to [tile2]"
	-- "prior to" means that it occurs on a prior row, or on the same row but to the left, of the same map
	log.trace()
	local isPrior = false
	if tile1 == nil or tile2 == nil then
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".isPriorTile() called with an invalid tile (input parameter is nil)")
		return nil
	else
		if tile1.z ~= tile2.z then
			log.error("ERROR! " .. UTIL_FILE_NAME .. ".isPriorTile() called with tiles from two different maps")
			return nil
		else
			if tile1.x == tile2.x and tile1.y == tile2.y then
				log.warning("WARNING: " .. UTIL_FILE_NAME .. ".isPriorTile() called with the same tile twice")
			else
				if tile1.y < tile2.y or (tile1.y == tile2.y and tile1.x < tile2.x) then
					isPrior = true
				end
			end
		end
	end
	return isPrior
end

local function isCoastalLandTile (tile) --> boolean
	log.trace()
	if not isLandTile then
		return false
	else
		for _, adjTile in ipairs(getAdjacentTiles(tile, false)) do
			if civ.isTile(adjTile) and isWaterTile(adjTile) then
				return true
			end
		end
		return false
	end
end

local function isCoastalWaterTile (tile) --> boolean
	log.trace()
	if not isWaterTile then
		return false
	else
		for _, adjTile in ipairs(getAdjacentTiles(tile, false)) do
			if civ.isTile(adjTile) and isLandTile(adjTile) then
				return true
			end
		end
		return false
	end
end

local function hasRiver (tile) --> boolean
--	In decimal format, a river causes 128 to be subtracted from the tile.terrainType value
	log.trace()
	return tile.terrainType & 0x80 == 0x80
end

-- Replaces civlua.iterateTiles() which yields the x and y (but not z) coordinates of a tile, instead of an actual tile object
local function iterateTiles (mapNumber) --> iterator (of tile objects)
	-- Note: the mapNumber parameter is optional; if nil, then the function will iterate over tiles on all maps (in map number order)
	log.trace()
	return coroutine.wrap(function ()
		local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()
		for z = 0, mapQuantity - 1 do
			if z == mapNumber or mapNumber == nil then
				for y = 0, mapHeight - 1 do
					for x = y & 1, mapWidth - 1, 2 do
						coroutine.yield(civ.getTile(x, y, z))
					end
				end
			end
		end
	end)
end

local function iterateTilesSpiralIn (mapNumber) --> iterator (of tile objects)
	-- Note: the mapNumber parameter is required and this function will not work if the parameter is nil or invalid
	log.trace()
	return coroutine.wrap(function ()
		local mapWidth, mapHeight = civ.getMapDimensions()
		local circuitsComplete = 0
		while circuitsComplete < round(math.min(mapWidth, mapHeight) / 2) do
			for x = circuitsComplete, mapWidth - circuitsComplete - 1 do
				local y = circuitsComplete
				if (x + y) % 2 == 0 then
					coroutine.yield(civ.getTile(x, y, mapNumber))
				end
			end
			for y = circuitsComplete + 1, mapHeight - circuitsComplete - 1 do
				local x = mapWidth - circuitsComplete - 1
				if (x + y) % 2 == 0 then
					coroutine.yield(civ.getTile(x, y, mapNumber))
				end
			end
			if (mapHeight - circuitsComplete - 1) > circuitsComplete then
				for x = mapWidth - circuitsComplete - 2, circuitsComplete, -1 do
					local y = mapHeight - circuitsComplete - 1
					if (x + y) % 2 == 0 then
						coroutine.yield(civ.getTile(x, y, mapNumber))
					end
				end
			end
			if (mapWidth - circuitsComplete - 1) > circuitsComplete then
				for y = mapHeight - circuitsComplete - 2, circuitsComplete + 1, -1 do
					local x = circuitsComplete
					if (x + y) % 2 == 0 then
						coroutine.yield(civ.getTile(x, y, mapNumber))
					end
				end
			end
			circuitsComplete = circuitsComplete + 1
		end
	end)
end

--[[
BITMASK VALUES FOR TILE IMPROVEMENTS:
					Hex		Decimal	TOTPP reports	Notes
Nothing				0x00	0		0
Unit				0x01	1		1
City				0x02	2		2
Irrigation			0x04	4		4
Mining				0x08	8		8
Farm				0x0C	12		12				Irrigation + Mining
Road				0x10	16		16
Railroad (+ Road)	0x30	48		48				The railroad is actually 0x20 = 32, but only exists simultaneous with a road
Fortress			0x40	64		64
Airbase				0x42	66		66				Fortress + City
Pollution			0x80	128		-128
]]
local function hasCity (tile) --> boolean
-- There are two ways of checking this:
--	return tile.improvements & 0x02 == 0x02 and tile.improvements & 0x40 == 0x00 and tile.improvements & 0x80 == 0x80
	log.trace()
	local hasCityCheck1 = tile.improvements & 0x42 == 0x02 and tile.improvements & 0x82 == 0x02
	local hasCityCheck2 = tile.city ~= nil
	if hasCityCheck1 == hasCityCheck2 then
		return hasCityCheck1
	else
		log.error("ERROR! Conflicting information about whether or not a city exists! (improvements = " .. tostring(hasCityCheck1) .. ", city = " .. tostring(hasCityCheck2) .. ")")
		return hasCityCheck2
	end
end

local function isWithinCityRadius (tile, city) --> boolean
	log.trace()
	local nearCity = false
	for _, radiusTile in ipairs(getCityRadiusTiles(city, true)) do
		if civ.isTile(radiusTile) then
			if radiusTile == tile then
				nearCity = true
				break
			end
		end
	end
	return nearCity
end

local function isWithinAnyCityRadius (tile) --> boolean
-- This may not perform well due to the amount of checking involved.
-- Note that this does not identify *which* city's radius the tile is within, and it may be within the radius of more than one city.
-- See also isWithinTribeCityRadius()
	log.trace()
	local nearCity = false
	local exitLoop = false
	for city in civ.iterateCities() do
		for _, radiusTile in ipairs(getCityRadiusTiles(city, true)) do
			if civ.isTile(radiusTile) then
				if radiusTile == tile then
					nearCity = true
					exitLoop = true
					break
				end
			end
		end
		if exitLoop then
			break
		end
	end
	return nearCity
end

local function isWithinOtherCityRadius (tile, city) --> boolean
-- This may not perform well due to the amount of checking involved.
-- Note that this does not identify *which* other city's radius the tile is within, or which tribe it belongs to,
--		and it may very well be within the radius of more than one other city
	log.trace()
	local nearCity = false
	local exitLoop = false
	for otherCity in civ.iterateCities() do
		if otherCity ~= city then
			for _, radiusTile in ipairs(getCityRadiusTiles(otherCity, true)) do
				if civ.isTile(radiusTile) then
					if radiusTile == tile then
						nearCity = true
						exitLoop = true
						break
					end
				end
			end
			if exitLoop then
				break
			end
		end
	end
	return nearCity
end

local function isWithinTribeCityRadius (tile, tribe) --> boolean
-- This may not perform well due to the amount of checking involved.
-- Note that this does not identify *which* city's radius the tile is within, and it may be within the radius of more than one city belonging to this tribe.
--		Also, regardless of the result, the tile may be within the radius of a city belonging to a different tribe.
-- See also isWithinAnyCityRadius()
	log.trace()
	local nearCity = false
	local exitLoop = false
	for city in civ.iterateCities() do
		if city.owner == tribe then
			for _, radiusTile in ipairs(getCityRadiusTiles(city, true)) do
				if civ.isTile(radiusTile) then
					if radiusTile == tile then
						nearCity = true
						exitLoop = true
						break
					end
				end
			end
			if exitLoop then
				break
			end
		end
	end
	return nearCity
end

local function getClosestCities (tile, tribe) --> table (of city objects)
-- This may not perform well due to the amount of checking involved.
-- Returns a table with the closest city or cities to the given tile.
-- The second parameter, tribe, is optional; it will constrain the result set to cities belonging to that tribe if provided. In other words, the returned
--		city/cities may not be the closest *overall*, but simply the closest one(s) belonging to that tribe.
--		If this parameter is nil, then the closest city/cities may be from *different* tribes.
	log.trace()
	local closestCities = { }
	local closestCityDistance = 1000
	for city in civ.iterateCities() do
		if city.owner == tribe or tribe == nil then
			local distanceToCity = tileutil.getDistance(tile, city.location)
			if distanceToCity < closestCityDistance then
				local tableSize = #closestCities
				for i = 1, tableSize do
					closestCities[i] = nil
				end
				table.insert(closestCities, city)
				closestCityDistance = distanceToCity
			elseif distanceToCity == closestCityDistance then
				table.insert(closestCities, city)
			end
		end
	end
	return closestCities
end

local function hasIrrigation (tile) --> boolean
	log.trace()
	return tile.improvements & 0x0C == 0x04
end
local function removeIrrigation (tile) --> void
	-- You cannot remove irrigation as a next step if you have a farm; the farm must be removed first
	log.trace()
	if not(hasIrrigation(tile)) then
		log.info("Could not remove irrigation from " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it does not currently have irrigation")
	else
		tile.improvements = tile.improvements ~ 0x04
		civ.ui.redrawTile(tile)
		log.action("Removed irrigation from " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
end
local function canAddIrrigation (tile) --> boolean
	log.trace()
	if hasCity(tile) then
		log.warning("WARNING: Cannot add irrigation to " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it has a city")
		return false
	elseif tile.improvements & 0x0C ~= 0x00 then
		log.warning("WARNING: Cannot add irrigation to " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it already has irrigation, mine, or farm")
		return false
	else
		-- No message
		return true
	end
end
local function addIrrigation (tile) --> void
	log.trace()
	if canAddIrrigation(tile) then
		tile.improvements = tile.improvements | 0x04
		civ.ui.redrawTile(tile)
		log.action("Added irrigation to " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
end

local function hasFarm (tile) --> boolean
	log.trace()
	return tile.improvements & 0x0C == 0x0C
end
local function removeFarm (tile) --> void
	-- Removing a farm will leave irrigation
	log.trace()
	if not(hasFarm(tile)) then
		log.info("Could not remove farm from " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it does not currently have farm")
	else
		tile.improvements = tile.improvements ~ 0x08
		civ.ui.redrawTile(tile)
		log.action("Removed farm from " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " leaving irrigation")
	end
end
-- local function canAddFarm (tile)
-- local function addFarm (tile)

local function hasMine (tile) --> boolean
	log.trace()
	return tile.improvements & 0x0C == 0x08
end
local function removeMine (tile) --> void
	log.trace()
	if not(hasMine(tile)) then
		log.info("Could not remove mine from " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it does not currently have mine")
	else
		tile.improvements = tile.improvements ~ 0x08
		civ.ui.redrawTile(tile)
		log.action("Removed mine from " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
end
local function canAddMine (tile) --> boolean
	log.trace()
	if hasCity(tile) then
		log.warning("WARNING: Cannot add mine to " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it has a city")
		return false
	elseif tile.improvements & 0x0C ~= 0x00 then
		log.warning("WARNING: Cannot add mine to " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it already has irrigation, mine, or farm")
		return false
	else
		-- No message
		return true
	end
end
local function addMine (tile) --> void
	log.trace()
	if canAddMine(tile) then
		tile.improvements = tile.improvements | 0x08
		civ.ui.redrawTile(tile)
		log.action("Added mine to " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
end

local function hasRoad (tile) --> boolean
	log.trace()
	return tile.improvements & 0x30 == 0x10
end
local function removeRoad (tile) --> void
	-- You cannot remove road as a next step if you have railroad; the railroad must be removed first
	log.trace()
	if not(hasRoad(tile)) then
		log.info("Could not remove road from " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it does not currently have road")
	else
		tile.improvements = tile.improvements ~ 0x10
		civ.ui.redrawTile(tile)
		log.action("Removed road from " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
end
local function canAddRoad (tile) --> boolean
	log.trace()
	if hasCity(tile) then
		log.warning("WARNING: Cannot add road to " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it has a city")
		return false
	elseif tile.improvements & 0x30 ~= 0x00 then
		log.info("Cannot add road to " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it already has road or railroad")
		return false
	else
		-- No message
		return true
	end
end
local function addRoad (tile) --> void
	log.trace()
	if canAddRoad(tile) then
		tile.improvements = tile.improvements | 0x10
		civ.ui.redrawTile(tile)
		log.action("Added road to " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
end

local function hasRailroad (tile) --> boolean
	log.trace()
	return tile.improvements & 0x30 == 0x30
end
local function removeRailroad (tile) --> void
	-- Removing railroad will leave road
	log.trace()
	if not(hasRailroad(tile)) then
		log.info("Could not remove railroad from " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it does not currently have railroad")
	else
		tile.improvements = tile.improvements ~ 0x20
		civ.ui.redrawTile(tile)
		log.action("Removed railroad from " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " leaving road")
	end
end
-- local function canAddRailroad (tile)
-- local function addRailroad (tile)

local function hasFortress (tile) --> boolean
	log.trace()
	return tile.improvements & 0x42 == 0x40
end
local function removeFortress (tile) --> void
	log.trace()
	if not(hasFortress(tile)) then
		log.info("Could not remove Fortress from " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it does not currently have Fortress")
	else
		tile.improvements = tile.improvements ~ 0x40
		civ.ui.redrawTile(tile)
		log.action("Removed Fortress from " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
end
-- local function canAddFortress (tile)
-- local function addFortress (tile)

local function hasAirbase (tile) --> boolean
	log.trace()
	return tile.improvements & 0x42 == 0x42
end
-- local function removeAirbase (tile)
-- local function canAddAirbase (tile)
-- local function addAirbase (tile)

local function hasPollution (tile) --> boolean
	log.trace()
	return tile.improvements & 0x82 == 0x80
end
local function removePollution (tile) --> void
	log.trace()
	if not(hasPollution(tile)) then
		log.info("Could not remove pollution from " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it does not currently have pollution")
	else
		tile.improvements = tile.improvements ~ 0x80
		civ.ui.redrawTile(tile)
		log.action("Removed pollution from " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
end
local function canAddPollution (tile) --> boolean
	log.trace()
	if hasCity(tile) then
		log.warning("WARNING: Cannot add pollution to " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it has a city")
		return false
	elseif hasAirbase(tile) then
		log.warning("WARNING: Cannot add pollution to " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it has an airbase")
		return false
	elseif hasPollution(tile) then
		log.info("Cannot add pollution to " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because it already has pollution")
		return false
	else
		-- No message
		return true
	end
end
local function addPollution (tile) --> void
	log.trace()
	if canAddPollution(tile) then
		tile.improvements = tile.improvements | 0x80
		civ.ui.redrawTile(tile)
		log.action("Added pollution to " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
end

-- local function hasTransporter (tile)
-- local function removeTransporter (tile)
-- local function canAddTransporter (tile)
-- local function addTransporter (tile)

local function printTileDetails (tile) --> void
	-- Does not display tile.units (which is an iterator) but does display all other tile attributes
	log.trace()
	print("----------------------------------")
	print("TILE DETAILS:")
	print("    Tile ID: " .. getTileId(tile))
	print("    x, y, z: " .. tile.x, tile.y, tile.z)
	print("    landmass: " .. tile.landmass)
	print("    terrainType: " .. tile.terrainType)
	print("    fertility: " .. tile.fertility)
	print("    improvements: " .. tile.improvements)
	if tile.city ~= nil then	-- returns a city object
		print("    city: " .. tile.city.name .. "(" .. tile.city.owner.adjective .. ")")
	end
	if tile.owner ~= nil then	-- returns a tribe object
		print("    owner: " .. tile.owner.name)
	else
		print("    owner: nil")
	end
	if tile.defender ~= nil then	-- returns a tribe object
		print("    defender: " .. tile.defender.name)
	else
		print("    defender: nil")
	end
	print("----------------------------------")
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 100

return {
	baseTerrainId = baseTerrainId,
	baseTerrainName = baseTerrainName,
	WORKER_MASK_FOR_CITY_RADIUS_TILES = WORKER_MASK_FOR_CITY_RADIUS_TILES,

	confirmLoad = confirmLoad,

	getMapTileCount = getMapTileCount,
	getTileId = getTileId,
	getTileById = getTileById,

	getBattleTile = getBattleTile,

	getIntercardinalTiles = getIntercardinalTiles,
	getAdjacentTiles = getAdjacentTiles,
	getCardinalTiles = getCardinalTiles,
	getCityRadiusTiles = getCityRadiusTiles,
	getCityOuterRadiusTiles = getCityOuterRadiusTiles,
	getTilesByDistance = getTilesByDistance,
	getDistance = getDistance,

	getTerrainId = getTerrainId,
	setTerrainId = setTerrainId,

	isLandTile = isLandTile,
	isWaterTile = isWaterTile,
	getTerrainBodySize = getTerrainBodySize,

	getCityRadiusLandTiles = getCityRadiusLandTiles,

	getCityTilesWorked = getCityTilesWorked,
	setCityTilesWorked = setCityTilesWorked,

	isMapEdge = isMapEdge,
	isPriorTile = isPriorTile,
	isCoastalLandTile = isCoastalLandTile,
	isCoastalWaterTile = isCoastalWaterTile,

	hasRiver = hasRiver,

	iterateTiles = iterateTiles,
	iterateTilesSpiralIn = iterateTilesSpiralIn,

	hasCity = hasCity,

	isWithinCityRadius = isWithinCityRadius,
	isWithinAnyCityRadius = isWithinAnyCityRadius,
	isWithinOtherCityRadius = isWithinOtherCityRadius,
	isWithinTribeCityRadius = isWithinTribeCityRadius,
	getClosestCities = getClosestCities,

	hasIrrigation = hasIrrigation,
	removeIrrigation = removeIrrigation,
	canAddIrrigation = canAddIrrigation,
	addIrrigation = addIrrigation,

	hasFarm = hasFarm,
	removeFarm = removeFarm,
--	canAddFarm
--	addFarm

	hasMine = hasMine,
	removeMine = removeMine,
	canAddMine = canAddMine,
	addMine = addMine,

	hasRoad = hasRoad,
	removeRoad = removeRoad,
	canAddRoad = canAddRoad,
	addRoad = addRoad,

	hasRailroad = hasRailroad,
	removeRailroad = removeRailroad,
--	canAddRailroad
--	addRailroad

	hasFortress = hasFortress,
	removeFortress = removeFortress,
--	canAddFortress
--	addFortress

	hasAirbase = hasAirbase,
--	removeAirbase
--	canAddAirbase
--	addAirbase

	hasPollution = hasPollution,
	removePollution = removePollution,
	canAddPollution = canAddPollution,
	addPollution = addPollution,

--	hasTransporter
--	removeTransporter
--	canAddTransporter
--	addTransporter

	printTileDetails = printTileDetails,
}
