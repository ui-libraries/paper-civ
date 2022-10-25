-- mmTerrain.lua
-- by Knighttime

log.trace()

-- Key is terrainId
-- Global variable, can be called/accessed directly from any module
TERRAIN_DATA = {
	[0] = { id = 0, name = "Arable (poor)", movecost = 1, defensePct = 100, health = 1, materials = 0, trade = 0, irrigate = true, irrigateBonus = 1, irrigateTurns = 8, irrigateAi = 1, mine = false, mineBonus = 0, mineTurns = 0, mineAi = 0, transform = "Pasture", roadBonus = 1, roadTurns = 2, resource1 = "Clay, 1 / 2 / 0", resource2 = "Domestic Fowl, 2 / 0 / 1", impassable = false },

	[1] = { id = 1, name = "Arable", movecost = 1, defensePct = 100, health = 2, materials = 0, trade = 0, irrigate = true, irrigateBonus = 1, irrigateTurns = 6, irrigateAi = 1, mine = false, mineBonus = 0, mineTurns = 0, mineAi = 0, transform = "Woodland", roadBonus = 1, roadTurns = 2, resource1 = "Small Game, 3 / 0 / 1", resource2 = "Pigs, 3 / 1 / 0", impassable = false },

	[2] = { id = 2, name = "Pasture", movecost = 1, defensePct = 100, health = 2, materials = 0, trade = 0, irrigate = false, irrigateBonus = 0, irrigateTurns = 0, irrigateAi = 0, mine = false, mineBonus = 0, mineTurns = 0, mineAi = 0, transform = "Heathland", roadBonus = 1, roadTurns = 2, resource1 = "Pasture+, 2 / 1 / 0", resource2 = "Pasture+, 2 / 1 / 0", impassable = false },

	[3] = { id = 3, name = "Arable (lush)", movecost = 1, defensePct = 100, health = 2, materials = 1, trade = 1, irrigate = true, irrigateBonus = 2, irrigateTurns = 6, irrigateAi = 1, mine = false, mineBonus = 0, mineTurns = 0, mineAi = 0, transform = false, roadBonus = 0, roadTurns = 2, resource1 = "Honey, 3 / 1 / 2", resource2 = "Horses, 2 / 2 / 3", impassable = false },

	[4] = { id = 4, name = "Mountain Pass", movecost = 3, defensePct = 200, health = 0, materials = 1, trade = 0, irrigate = false, irrigateBonus = 1, irrigateTurns = 0, irrigateAi = 0, mine = true, mineBonus = 1, mineTurns = 12, mineAi = 1, transform = false, roadBonus = 0, roadTurns = 6, resource1 = "Iron Ore, 0 / 4 / 2", resource2 = "Silver, 0 / 2 / 5", impassable = false },

	[5] = { id = 5, name = "Mountains", movecost = 5, defensePct = 200, health = 0, materials = 0, trade = 0, irrigate = false, irrigateBonus = 0, irrigateTurns = 0, irrigateAi = 0, mine = "Mountain Pass", mineBonus = 0, mineTurns = 10, mineAi = 2, transform = false, roadBonus = 0, roadTurns = 10, resource1 = "Iron Ore, 0 / 2 / 1", resource2 = "Silver, 0 / 1 / 3", impassable = true },

	[6] = { id = 6, name = "Dense Forest", movecost = 3, defensePct = 150, health = 1, materials = 1, trade = 0, irrigate = "Woodland", irrigateBonus = 0, irrigateTurns = 10, irrigateAi = 1, mine = true, mineBonus = 2, mineTurns = 6, mineAi = 1, transform = false, roadBonus = 0, roadTurns = 6, resource1 = "Timber, 1 / 3 / 1", resource2 = "Red Deer, 3 / 1 / 2", impassable = false },

	[7] = { id = 7, name = "Pine Forest", movecost = 3, defensePct = 150, health = 1, materials = 1, trade = 0, irrigate = "Woodland", irrigateBonus = 0, irrigateTurns = 10, irrigateAi = 1, mine = true, mineBonus = 2, mineTurns = 6, mineAi = 1, transform = false, roadBonus = 0, roadTurns = 6, resource1 = "Amber, 1 / 1 / 4", resource2 = "Bears, 2 / 1 / 1", impassable = false },

	[8] = { id = 8, name = "Heathland", movecost = 1, defensePct = 100, health = 1, materials = 1, trade = 0, irrigate = "Pasture", irrigateBonus = 0, irrigateTurns = 8, irrigateAi = 1, mine = true, mineBonus = 1, mineTurns = 8, mineAi = 2, transform = false, roadBonus = 0, roadTurns = 2, resource1 = "Wild Fowl, 3 / 1 / 1", resource2 = "Goats, 3 / 1 / 1", impassable = false },

	[9] = { id = 9, name = "Marsh/Fen", movecost = 4, defensePct = 150, health = 0, materials = 0, trade = 0, irrigate = "Arable", irrigateBonus = 0, irrigateTurns = 12, irrigateAi = 2, mine = false, mineBonus = 0, mineTurns = 0, mineAi = 0, transform = false, roadBonus = 0, roadTurns = 8, resource1 = "Eels, 2 / 0 / 1", resource2 = "Reeds, 0 / 1 / 2", impassable = false },

	[10] = { id = 10, name = "Sea", movecost = 1, defensePct = 100, health = 1, materials = 0, trade = 2, irrigate = false, irrigateBonus = 1, irrigateTurns = 0, irrigateAi = 0, mine = false, mineBonus = 1, mineTurns = 0, mineAi = 0, transform = false, roadBonus = 0, roadTurns = "n/a", resource1 = "Herring, 3 / 0 / 3", resource2 = "Salmon, 3 / 0 / 3", impassable = false },

	[11] = { id = 11, name = "Woodland", movecost = 2, defensePct = 100, health = 1, materials = 1, trade = 0, irrigate = "Arable", irrigateBonus = 1, irrigateTurns = 8, irrigateAi = 1, mine = true, mineBonus = 1, mineTurns = 6, mineAi = 2, transform = false, roadBonus = 0, roadTurns = 4, resource1 = "Orchard, 3 / 1 / 1", resource2 = "Foxes, 1 / 2 / 2", impassable = false },

	[12] = { id = 12, name = "Hills", movecost = 4, defensePct = 150, health = 1, materials = 1, trade = 0, irrigate = "Terraced Hills", irrigateBonus = 0, irrigateTurns = 12, irrigateAi = 2, mine = true, mineBonus = 2, mineTurns = 10, mineAi = 1, transform = false, roadBonus = 0, roadTurns = 8, resource1 = "Limestone, 0 / 4 / 1", resource2 = "Wild Boar, 2 / 1 / 2", impassable = false },

	[13] = { id = 13, name = "Terraced Hills", movecost = 2, defensePct = 150, health = 2, materials = 0, trade = 0, irrigate = true, irrigateBonus = 1, irrigateTurns = 12, irrigateAi = 2, mine = true, mineBonus = 1, mineTurns = 10, mineAi = 2, transform = "Hills", roadBonus = 0, roadTurns = 4, resource1 = "Grapes, 3 / 0 / 2", resource2 = "Olives, 3 / 0 / 1", impassable = false },

	[14] = { id = 14, name = "Monastery", movecost = 2, defensePct = 150, health = 1, materials = 0, trade = 3, irrigate = false, irrigateBonus = 0, irrigateTurns = 0, irrigateAi = 0, mine = false, mineBonus = 0, mineTurns = 0, mineAi = 0, transform = false, roadBonus = 0, roadTurns = 4, resource1 = "Abbey Ale, 2 / 0 / 5", resource2 = "Goods and Tools, 1 / 1 / 5", impassable = false },

	[15] = { id = 15, name = "Urban", movecost = 1, defensePct = 100, health = 0, materials = 2, trade = 2, irrigate = false, irrigateBonus = 0, irrigateTurns = 0, irrigateAi = 0, mine = false, mineBonus = 0, mineTurns = 0, mineAi = 0, transform = false, roadBonus = 0, roadTurns = 2, resource1 = "Artesian Well, 2 / 2 / 2", resource2 = "Public Garden, 2 / 2 / 2", impassable = false },
}
log.update("Defined Medieval Millennium terrain data")

constant.mmTerrain = { }
constant.mmTerrain.ARABLELUSH_DECLINE_PCT = 18					-- The base percent chance that ArableLush will decline to Arable
constant.mmTerrain.ARABLE_DECLINE_PCT = 10						-- The base percent chance that Arable will decline to ArablePoor
constant.mmTerrain.ARABLE_IMPROVE_PCT = 8						-- The base percent chance that Arable will improve to ArableLush
constant.mmTerrain.ARABLEPOOR_IMPROVE_PCT = 14					-- The base percent chance that ArablePoor will improve to Arable
constant.mmTerrain.PINEFOREST_ARABLE_DETRIMENT_FACTOR = 1.5		-- The number of times more or less likely that any type of Arable terrain will decline or improve, if its native terrain is PineForest
																--		(i.e., the DECLINE percentage is multiplied by this, and the IMPROVE percentage is divided by this)
constant.mmTerrain.HEATHLAND_DECLINE_PCT = 0					-- The default percent chance that Heathland will decline (0 means no declining is possible)
constant.mmTerrain.HEATHLAND_IMPROVE_PCT = 6					-- The default percent chance that Heathland will improve to Woodland, only during periods of warming/improving climate
constant.mmTerrain.MARSHFEN_ARABLE_DISPARITY_FACTOR = 2			-- The number of times more likely that Marsh/Fen terrain will convert to either ArableLush or ArablePoor, rather than
																--		simply Arable (i.e., both the Arable DECLINE and IMPROVE percentages are multiplied by this)
constant.mmTerrain.HEATHLAND_MAX_INIT_PCT = 33.33				-- Maximum percentage of all land tiles on the map that can have a native terrain of Heathland
																--		Additional tiles that would *normally* be Heathland are initialized to ArablePoor instead
constant.mmTerrain.DRY_MAX_INIT_PCT = 50						-- Maximum percentage of all land tiles on the map that can have a native terrain of Heathland or Hills
																--		Additional tiles that would *normally* be Hills are initialized to Woodland instead
constant.mmTerrain.PINEFOREST_TO_WOODLAND_INIT_PCT = 9			-- Percentage of native PineForest that is initialized to Woodland
constant.mmTerrain.DENSEFOREST_TO_WOODLAND_INIT_PCT = 18		-- Percentage of native DenseForest that is initialized to Woodland
constant.mmTerrain.WOODLAND_TO_ARABLE_INIT_PCT = 56				-- Percentage of Woodland that is initialized to Arable (later partially diversified into small percentages of ArablePoor and ArableLush)
constant.mmTerrain.PLAINS_TO_PASTURE_INIT_PCT = 10				-- Percentage of Heathland resulting from Plains that is initialized to Pasture
constant.mmTerrain.HILLS_TO_TERRACEDHILLS_INIT_PCT = 10			-- Percentage of native Hills that is initialized to TerracedHills
constant.mmTerrain.FOREST_CLUSTER_MIN_ADJACENT_MATCH_QTY = 7	-- Number of tiles adjacent to a forest that must *also* be forest, for it to be considered a "cluster" (max possible is 8)
constant.mmTerrain.FOREST_CLUSTER_MIN_UNBROKEN_RADIUS = 2		-- Radius from a tile that is at the the center of a forest cluster which must NOT be the "cluster-breaking" terrain
constant.mmTerrain.PINEFOREST_CLUSTER_TO_MARSHFEN_PCT = 20		-- If a PineForest tile is at the center of a PineForest cluster, percent chance it will be converted to MarshFen
constant.mmTerrain.PINEFOREST_CLUSTER_TO_HEATHLAND_PCT = 20		-- If a PineForest tile is at the center of a PineForest cluster, percent chance it will be converted to Heathland
constant.mmTerrain.DENSEFOREST_CLUSTER_TO_HEATHLAND_PCT = 12	-- If a DenseForest tile is at the center of a *natively* DenseForest cluster, percent chance it will be converted to Heathland
constant.mmTerrain.DENSEFOREST_CLUSTER_TO_WOODLAND_PCT = 25		-- If a DenseForest tile is at the center of a *currently* DenseForest cluster, percent chance it will be converted to Woodland
constant.mmTerrain.HILLS_TO_DENSEFOREST_PCT_MIN = 2				-- The number of native Dense Forest tiles on the map, multiplied by this percentage, provides the *minimum* number of tiles on the map
																--		that must natively be Hills. If there are not enough Hills, native Dense Forest tiles are converted to native Hills until this
																--		percent is reached.
constant.mmTerrain.TILE_CLIMATE_CHANGE_CHANCE_PER_TURN = 4		-- Percent chance per turn (not per year) that an ArablePoor, Arable, ArableLush, or Heathland tile is eligible to be converted to a
																--		tile of different quality. This *only* applies during a Climate Change period of either warming or cooling; see table below.
constant.mmTerrain.TILE_CLIMATE_CHANGE_MIN_YEARS = 100			-- Number of years (not turns) since the last terrain type change for this tile, before there is a possibility it will experience
																--		warming or cooling.
constant.mmTerrain.URBAN_TILE_NUM_TO_MIN_CITY_SIZE_TABLE = {
	[1] = 10,													-- When a city reaches this population, the city square itself will become urban
	[2] = 14,													-- When a city reaches this population, a *second* nearby tile will become urban
	[3] = 16,													-- etc.
	[4] = 18,													-- Errors are likely if city sizes entered here do not increase sequentially
	[5] = 20													-- Use absurdly large city sizes (e.g., 200+) to block/limit behavior
}
constant.mmTerrain.DIFFICULTY_LEVEL_TO_AI_ROAD_CHANCE_TABLE = {	-- Percent chance that when the AI clears a tile to Pasture or any type of Arable terrain, they get a free road:
	[0] = 0,													-- Baron: 0% chance
	[1] = 16,													-- Earl: 16% chance
	[2] = 33,													-- Marquess: 33% chance
	[3] = 50,													-- Duke: 50% chance
	[4] = 67,													-- Prince: 67% chance
	[5] = 83,													-- King: 83% chance
	[6] = 100													-- Emperor: 100% chance
}
constant.mmTerrain.WOODED_TERRAIN_DEPLETION_TURNS = 75					-- Number of *turns* (not years) a wooded tile must be worked before its resources are depleted
																		--		Wooded tiles are Dense Forest, Pine Forest, and Woodland
constant.mmTerrain.OTHER_TERRAIN_DEPLETION_TURNS = 150					-- Number of *turns* (not years) a non-wooded tile must be worked before its resources are depleted
	-- NOTE: 150 turns is 300 years, so a tile that was worked from the beginning of the game could first experience depletion in AD 800
	-- 		 This aligns with the first year on which unworked land could revert, based on the constant values entered below
constant.mmTerrain.TERRAIN_USAGE_RECOVERY_RATE = 2						-- Number of *turns* of usage a tile *recovers*, if it is *not* worked on a given turn
	-- NOTE: This is based on the "three field system" where a land would be used for food two years (growing different crops) and then lie fallow
	--		 for one year. i.e. in that one year it "recovered" from being used for two years.
constant.mmTerrain.TERRAIN_DEPLETION_MIN_YEARS = 100					-- Number of years (not turns) since the last activity on the tile before there is a possibility it will suffer depletion
	-- NOTE: "Activity" means: (a) if the depletion action would be the removal of improvements, it must be this many years since the year last improved; and
	--		 (b) if the depletion action would be a change of terrain type, it must be this many years since the year of the last type change
constant.mmTerrain.TERRAIN_REVERT_DEFAULT_LAST_ACTIVITY_YEAR = 700		-- All tiles default to having last activity in the year 700
constant.mmTerrain.TERRAIN_REVERT_MIN_YEARS = 100						-- Number of years (not turns) since the last activity on the tile before there is a possibility it will revert
																		--		to/towards its native terrain
	-- NOTE: "Activity" means: (a) the tile was worked, or (b) its terrain type was changed, or (c) its usage level was decremented
	-- 		 Taken with the prior constant, this means that the first possibility for terrain reverting is in the year 800.
	--		 This aligns with the first year on which worked terrain could be depleted, based on the constant values entered above
	--		 For (c), the reason decrementing the usage level counts as activity is as follows:
	--			If terrain was worked for 149 turns, and then had no activity, its recovery would take 75 turns
	--			We don't want the years of no activity *that count towards reverting* to begin until the recovery period *ends*
constant.mmTerrain.TERRAIN_REVERT_CHANCE_INCREASE_PER_TURN = 0.2		-- Percent rate at which the percentage chance of an unworked tile reverting goes up, per *turn*, once the minimum turn limit
																		--		is reached. The rate starts at 0% on the year the limit of unworked turns is reached.
constant.mmTerrain.FOREST_FIRE_BURNS_FOREST_PCT = 0.15					-- Percent of all forest tiles on the map (dense or pine) that will be burned to Woodland every turn, once reverting is underway
constant.mmTerrain.BATTLE_DESTROYS_ROAD_PCT = 40						-- Percent chance that a road will be destroyed when a battle occurs on that tile
constant.mmTerrain.CONQUEST_DESTROYS_CASTLE_PCT = 50					-- Percent chance that a castle will be destroyed when the last unit within it is killed
constant.mmTerrain.CLEARED_FOREST_MATERIALS = 20						-- Number of Materials sent to the nearest friendly city (cities) when Pine or Dense Forest is cleared to Woodland
																		--		Does not apply when the change is due to the terrain depleting, however.
constant.mmTerrain.CLEARED_HEATHLAND_MATERIALS = 10						-- Number of Materials sent to the nearest friendly city (cities) when Heathland is cleared to Pasture (ditto for depletion)
constant.mmTerrain.CLEARED_WOODLAND_MATERIALS = 10						-- Number of Materials sent to the nearest friendly city (cities) when Woodland is cleared to Arable (ditto for depletion)
constant.mmTerrain.CITY_GAIN_MATERIALS_MAX_DISTANCE = 3					-- The Materials bonus from clearing certain terrain can be sent to one or more cities up to this many tiles away
																		--		If there are no cities within that range, the Materials bonus is lost.
log.update("Defined Medieval Millennium terrain constants")

local CLIMATE_CHANGE = {
-- Roman Warm Period, 250 BC - AD 400/450
-- Predates start of Medieval Millennium

-- Dark Ages Cold Period, 400/450 - 900/950
-- Base climate constants are used for this period, without introducing turn-based change

-- Medieval Warm Period, 900/950/1000 - 1200/1250/1300 (years vary according to different sources)
	{ startYear =  950, endYear = 1250, peakYear = 1100, declineFactorAtPeak = 0.5, improveFactorAtPeak = 2.0 },

-- Little Ice Age, 1250/1275/1300 - 1850 (years vary according to different sources)
-- Many of these years extend past the official end of the game, just in case you decide to keep playing anyway
	{ startYear = 1275, endYear = 1454, peakYear = 1454, declineFactorAtPeak = 2.5, improveFactorAtPeak = 0.0 },
	{ startYear = 1455, endYear = 1549, peakYear = 1455, declineFactorAtPeak = 3.0, improveFactorAtPeak = 0.0 },
	{ startYear = 1550, endYear = 1649, peakYear = 1649, declineFactorAtPeak = 3.0, improveFactorAtPeak = 0.0 },
	{ startYear = 1650, endYear = 1709, peakYear = 1650, declineFactorAtPeak = 3.0, improveFactorAtPeak = 0.0 },
	{ startYear = 1710, endYear = 1769, peakYear = 1769, declineFactorAtPeak = 3.0, improveFactorAtPeak = 0.0 },
	{ startYear = 1770, endYear = 1850, peakYear = 1770, declineFactorAtPeak = 3.0, improveFactorAtPeak = 0.0 },
}
log.update("Defined Medieval Millennium climate change")

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
-- This is called internally by getLandDeclinePercentage() and must be defined prior to it in this file:
local function getCurrentYearsDeclineFactor () --> decimal
	log.trace()
	local declineFactor = 1.0
	local gameYear = civ.getGameYear()
	for _, climateChange in ipairs(CLIMATE_CHANGE) do
		if gameYear >= climateChange.startYear and gameYear <= climateChange.endYear then
			if gameYear < climateChange.peakYear then
				declineFactor = declineFactor +
					(((climateChange.declineFactorAtPeak - declineFactor) / (climateChange.peakYear - climateChange.startYear)) * (gameYear - climateChange.startYear))
			elseif gameYear == climateChange.peakYear then
				declineFactor = climateChange.declineFactorAtPeak
			elseif gameYear > climateChange.peakYear then
				declineFactor = climateChange.declineFactorAtPeak +
					(((declineFactor - climateChange.declineFactorAtPeak) / (climateChange.endYear - climateChange.peakYear)) * (gameYear - climateChange.peakYear))
			end
		end
	end
	return declineFactor
end

-- This is called internally by getLandImprovePercentage() and must be defined prior to it in this file:
local function getCurrentYearsImproveFactor () --> decimal
	log.trace()
	local improveFactor = 1.0
	local gameYear = civ.getGameYear()
	for _, climateChange in ipairs(CLIMATE_CHANGE) do
		if gameYear >= climateChange.startYear and gameYear <= climateChange.endYear then
			if gameYear < climateChange.peakYear then
				improveFactor = improveFactor +
					(((climateChange.improveFactorAtPeak - improveFactor) / (climateChange.peakYear - climateChange.startYear)) * (gameYear - climateChange.startYear))
			elseif gameYear == climateChange.peakYear then
				improveFactor = climateChange.improveFactorAtPeak
			elseif gameYear > climateChange.peakYear then
				improveFactor = climateChange.improveFactorAtPeak +
					(((improveFactor - climateChange.improveFactorAtPeak) / (climateChange.endYear - climateChange.peakYear)) * (gameYear - climateChange.peakYear))
			end
		end
	end
	return improveFactor
end

-- This is called internally by mayAdjustLandQuality() and must be defined prior to it in this file:
local function getLandDeclinePercentage (currentTerrainType, nativeTerrainType) --> decimal
	-- Independent of which nation is or intends to utilize the terrain (i.e., does not account for difficulty)
	-- Does not take latitude (Y-coordinate) into account
	log.trace()
	local landDecline = constant.mmTerrain.ARABLE_DECLINE_PCT
	if currentTerrainType == MMTERRAIN.ArableLush then
		landDecline = constant.mmTerrain.ARABLELUSH_DECLINE_PCT
	end
	if nativeTerrainType == MMTERRAIN.PineForest then
		landDecline = landDecline * constant.mmTerrain.PINEFOREST_ARABLE_DETRIMENT_FACTOR
	elseif nativeTerrainType == MMTERRAIN.MarshFen then
		landDecline = landDecline * constant.mmTerrain.MARSHFEN_ARABLE_DISPARITY_FACTOR
	elseif nativeTerrainType == MMTERRAIN.Heathland then
		landDecline = constant.mmTerrain.HEATHLAND_DECLINE_PCT
	end
	landDecline = landDecline * getCurrentYearsDeclineFactor()
	return landDecline
end

-- This is called internally by mayAdjustLandQuality() and must be defined prior to it in this file:
local function getLandImprovePercentage (currentTerrainType, nativeTerrainType) --> decimal
	-- Independent of which nation is or intends to utilize the terrain (i.e., does not account for difficulty)
	-- Does not take latitude (Y-coordinate) into account
	log.trace()
	local landImprove = constant.mmTerrain.ARABLE_IMPROVE_PCT
	if currentTerrainType == MMTERRAIN.ArablePoor then
		landImprove = constant.mmTerrain.ARABLEPOOR_IMPROVE_PCT
	end
	if nativeTerrainType == MMTERRAIN.PineForest then
		landImprove = landImprove / constant.mmTerrain.PINEFOREST_ARABLE_DETRIMENT_FACTOR
	elseif nativeTerrainType == MMTERRAIN.MarshFen then
		landImprove = landImprove * constant.mmTerrain.MARSHFEN_ARABLE_DISPARITY_FACTOR
	elseif nativeTerrainType == MMTERRAIN.Heathland then
		landImprove = constant.mmTerrain.HEATHLAND_IMPROVE_PCT
	end
	landImprove = landImprove * getCurrentYearsImproveFactor()
	return landImprove
end

local function getSourceForTerrainAction (tile) --> tribe, unit, int, table (of city objects)
	log.trace()
	local tribe = nil
	local workerUnit = nil
	for unit in tile.units do
		tribe = unit.owner
		if unit.type.role == 5 then
			workerUnit = unit
			break
		end
	end
	local closestCities = tileutil.getClosestCities(tile, tribe)
	local closestCityDistance = nil
	if #closestCities > 0 then
		closestCityDistance = tileutil.getDistance(tile, closestCities[1].location)
	end
	if tribe == nil then
		local closestCitiesAreFromDifferentTribes = false
		for _, city in ipairs(closestCities) do
			if tribe == nil then
				tribe = city.owner
			end
			if city.owner ~= tribe then
				closestCitiesAreFromDifferentTribes = true
			end
		end
		if closestCitiesAreFromDifferentTribes == true then
			tribe = nil
		end
		-- We will never allow the human tribe to be considered the (sole) source for the terrain action if there is no worker present
		if tribe ~= nil and tribe.isHuman == true then
			tribe = nil
		end
	end
	return tribe, workerUnit, closestCityDistance, closestCities
end

local function mayAdjustLandQuality (tile, nativeTerrainType, permitDecline, permitImprove) --> boolean
	-- Returns true if the terrain type was actually changed, false if it was not
	-- This should only be called for a tile that you are willing to change on the current turn;
	--		any limiting of the quantity/percentage of tiles on the map that may convert must be handled outside of this function
	log.trace()
	local currTT = tileutil.getTerrainId(tile)
	local newTT = currTT
	local randomNumber = math.random(100)
	local landDeclinePct = getLandDeclinePercentage(currTT, nativeTerrainType)
	local landImprovePct = getLandImprovePercentage(currTT, nativeTerrainType)
	log.info("Decline% = " .. landDeclinePct .. ", Improve% = " .. landImprovePct .. ", randomNumber = " .. randomNumber)
	if permitDecline == true and randomNumber <= landDeclinePct then
		if currTT == MMTERRAIN.ArableLush then
			newTT = MMTERRAIN.Arable
		elseif currTT == MMTERRAIN.Arable then
			newTT = MMTERRAIN.ArablePoor
		end
	elseif permitImprove == true and randomNumber > (100 - landImprovePct) then
		if currTT == MMTERRAIN.ArablePoor then
			newTT = MMTERRAIN.Arable
		elseif currTT == MMTERRAIN.Arable then
			newTT = MMTERRAIN.ArableLush
		elseif currTT == MMTERRAIN.Heathland then
			newTT = MMTERRAIN.Woodland
		end
	end
	if newTT ~= currTT then
		setTerrainType(tile, newTT, true)
		return true
	else
		return false
	end
end

local function processTerrainTypeChange (tile, permitAddingMaterialsToEmptyBox)
	log.trace()
	local terrainId = tileutil.getTerrainId(tile)
	if terrainId ~= MMTERRAIN.Sea then
		local tileId = tileutil.getTileId(tile)
		if terrainId ~= db.tileData[tileId].currentTerrainType then
			local formerTerrainId = db.tileData[tileId].currentTerrainType
			local tribe, workerUnit, closestCityDistance, closestCities = getSourceForTerrainAction(tile)

			if tribe ~= nil then
				-- A. and B. can only be done if we know which tribe is responsible for the change

				-- A. Provide Materials for clearing wooded terrain and generate message for human player (if applicable)
				if (formerTerrainId == MMTERRAIN.DenseForest or formerTerrainId == MMTERRAIN.PineForest or formerTerrainId == MMTERRAIN.Woodland or formerTerrainId == MMTERRAIN.Heathland) and
				   (terrainId == MMTERRAIN.Woodland or terrainId == MMTERRAIN.ArablePoor or terrainId == MMTERRAIN.Arable or terrainId == MMTERRAIN.ArableLush or terrainId == MMTERRAIN.Pasture)
				then
					local totalMaterialsBenefit = 0
					local materialsType = ""
					if formerTerrainId == MMTERRAIN.DenseForest or formerTerrainId == MMTERRAIN.PineForest then
						if terrainId == MMTERRAIN.Woodland then
							totalMaterialsBenefit = constant.mmTerrain.CLEARED_FOREST_MATERIALS
						else
							-- It's possible the AI, or even a human player with enough workers, could clear all the way from forest to arable in a single turn
							totalMaterialsBenefit = constant.mmTerrain.CLEARED_FOREST_MATERIALS + constant.mmTerrain.CLEARED_WOODLAND_MATERIALS
						end
						materialsType = "fine timber"
					elseif formerTerrainId == MMTERRAIN.Woodland then
						totalMaterialsBenefit = constant.mmTerrain.CLEARED_WOODLAND_MATERIALS
						materialsType = "wood"
					elseif formerTerrainId == MMTERRAIN.Heathland then
						totalMaterialsBenefit = constant.mmTerrain.CLEARED_HEATHLAND_MATERIALS
						materialsType = "rocks and firewood"
					end
					totalMaterialsBenefit = adjustForDifficulty(totalMaterialsBenefit, tribe, true)
					local workerDesc = "citizens have"
					if workerUnit ~= nil then
						workerDesc = workerUnit.type.name .. " has"
					end
					local messageText = "Our " .. workerDesc .. " cleared the " .. MMTERRAIN[formerTerrainId] .. " at " .. tile.x .. "," .. tile.y .. " to " .. MMTERRAIN[terrainId] .. " terrain, and generated " .. materialsType .. " equivalent to " .. totalMaterialsBenefit .. " Materials.|"
					log.info("Closest city or cities: " .. tostring(closestCityDistance) .. " tiles away (max is " .. constant.mmTerrain.CITY_GAIN_MATERIALS_MAX_DISTANCE .. ")")
					if closestCityDistance ~= nil and closestCityDistance <= constant.mmTerrain.CITY_GAIN_MATERIALS_MAX_DISTANCE and #closestCities >= 1 then
						local materialsBenefitPerCity = math.floor(totalMaterialsBenefit / #closestCities)
						for _, city in ipairs(closestCities) do
							if city.shields > 0 or permitAddingMaterialsToEmptyBox == true then
								cityutil.changeShields(city, materialsBenefitPerCity)
								messageText = messageText .. "|" .. materialsBenefitPerCity .. " Materials were sent to " .. city.name
							else
								log.update("Found 0 accumulated Materials in " .. city.name .. ", adding " .. (materialsBenefitPerCity * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR) .. " gold to treasury instead")
								tribeutil.changeMoney(tribe, (materialsBenefitPerCity * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR))
								messageText = messageText .. "|" .. materialsBenefitPerCity .. " Materials were sold in " .. city.name .. " for " .. (materialsBenefitPerCity * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR) .. " gold"
							end
						end
					else
						messageText = messageText .. "|Unfortunately, there is no city within " .. constant.mmTerrain.CITY_GAIN_MATERIALS_MAX_DISTANCE .. " tiles to receive these Materials, so they have been lost."
					end
					if tribe.isHuman then
						uiutil.messageDialog("Clearing Land", messageText, 480)
					end
				end		-- of A. "wooded terrain was cleared"

				-- B. Possibly provide free road to non-barbarian AI nations, if this will allow the tile to generate its first Trade
				-- Note that we can't tell if the tile has a special, though, so it might get a road even if it does and is already generating Trade as a result
				if tribe.isHuman == false and tribe.id > 0 and
				   (terrainId == MMTERRAIN.ArablePoor or terrainId == MMTERRAIN.Arable or terrainID == MMTERRAIN.ArableLush or terrainId == MMTERRAIN.Pasture) and
				   tileutil.hasRiver(tile) == false and tileutil.hasCity(tile) == false and tileutil.canAddRoad(tile) == true
				then
					local chanceToAddRoad = constant.mmTerrain.DIFFICULTY_LEVEL_TO_AI_ROAD_CHANCE_TABLE[civ.game.difficulty]
					local randomNumber = math.random(100)
					log.info("chanceToAddRoad = " .. chanceToAddRoad .. ", randomNumber = " .. randomNumber)
					if randomNumber <= chanceToAddRoad then
						tileutil.addRoad(tile)
						log.action("Provided free road at " .. tile.x .. "," .. tile.y .. " due to land cleared to " .. MMTERRAIN[terrainId] .. " by " .. tribe.name)
					end
				end		-- of B. "free road when it adds first Trade for AI"

			end		-- of tribe ~= nil

			-- In contrast to A. and B., C. and following can be done even if it's impossible to tell which tribe is responsible for the change
			--		It's only the message in D. that requires tribe knowledge

			-- C. If tile was cleared from Woodland to Arable, and contains a river, and contains irrigation, then this is probably the remaining
			--		irrigation that was provided automatically to Woodland with river
			-- It needs to be removed, and irrigation would need to be rebuilt by the tribe. The irrigation on Woodland isn't meant to be true
			--		"irrigation", it's essentially a workaround to make some Woodland tiles better than forest tiles
			if formerTerrainId == MMTERRAIN.Woodland and (terrainId == MMTERRAIN.ArablePoor or terrainId == MMTERRAIN.Arable or terrainId == MMTERRAIN.ArableLush) and
			   tileutil.hasRiver(tile) == true and tileutil.hasIrrigation(tile) == true then
				tileutil.removeIrrigation(tile)
				db.tileData[tileId].currentImprovement = nil
				for tribe in tribeutil.iterateActiveTribes(false) do
					if tileutil.isWithinTribeCityRadius(tile, tribe) then
						updateMapView(tile, tribe)
					end
				end
			end

			-- D. Test for climate change on cleared land and provide message for human player (if applicable)
			local landQualityChanged = false
			if terrainId == MMTERRAIN.Arable then
				landQualityChanged = mayAdjustLandQuality(tile, db.tileData[tileId].nativeTerrainType, true, true)
				if landQualityChanged == true then
					terrainId = tileutil.getTerrainId(tile)
					if tribe ~= nil and tribe.isHuman == true then
						if terrainId == MMTERRAIN.ArablePoor then
							uiutil.messageDialog("Poor Quality Arable Land", "Sire, we have discovered that the soil of the recently cleared terrain at " .. tile.x .. "," .. tile.y .. " is unfortunately of poor quality, worse than we had expected.")
						elseif terrainId == MMTERRAIN.ArableLush then
							uiutil.messageDialog("Lush Arable Land", "Great news, Sire! We have learned that the recently cleared terrain at " .. tile.x .. "," .. tile.y .. " is highly fertile and a perfect location for growing a variety of crops.")
						end
					end
				end
			end

			-- E. Update db.tileData with current terrain info
			if workerUnit ~= nil then
				log.update("Documented " .. MMTERRAIN[formerTerrainId] .. " changed to " .. MMTERRAIN[terrainId] .. " at " .. tile.x .. "," .. tile.y)
			else
				log.update("Documented " .. MMTERRAIN[formerTerrainId] .. " changed to " .. MMTERRAIN[terrainId] .. " WITHOUT A WORKER PRESENT at " .. tile.x .. "," .. tile.y)
			end
			db.tileData[tileId].currentTerrainType = terrainId
			db.tileData[tileId].lastTerrainTypeChangeYear = civ.getGameYear()

			-- F. Marsh/Fen that has been drained will no longer have that as its native terrain type
			if formerTerrainId == MMTERRAIN.MarshFen and db.tileData[tileId].nativeTerrainType == MMTERRAIN.MarshFen then
				if terrainId == MMTERRAIN.ArableLush or terrainId == MMTERRAIN.Arable then
					db.tileData[tileId].nativeTerrainType = MMTERRAIN.DenseForest
				elseif terrainId == MMTERRAIN.ArablePoor then
					db.tileData[tileId].nativeTerrainType = MMTERRAIN.PineForest
				end
			end

		end
	end
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function applyClimateChangeToMap () --> void
	log.trace()
	local startTimestamp = os.clock()
	local climateIsCooling = false
	local climateIsWarming = false
	local gameYear = civ.getGameYear()
	for _, climateChange in ipairs(CLIMATE_CHANGE) do
		if gameYear >= climateChange.startYear and gameYear <= climateChange.endYear then
			if climateChange.declineFactorAtPeak < climateChange.improveFactorAtPeak then
				climateIsWarming = true
			elseif climateChange.declineFactorAtPeak > climateChange.improveFactorAtPeak then
				climateIsCooling = true
			end
		end
	end
	log.info("climateIsWarming = " .. tostring(climateIsWarming) .. ", climateIsCooling = " .. tostring(climateIsCooling))
	-- Terrain quality is only able to get better or worse if the climate is gradually warming or cooling
	-- If there is no climate change, quality will also be unchanged
	if climateIsCooling == true or climateIsWarming == true then
		local modulus = round(100 / constant.mmTerrain.TILE_CLIMATE_CHANGE_CHANCE_PER_TURN)
		for tile in tileutil.iterateTiles() do
			if tileutil.hasCity(tile) == false then
				local currTT = tileutil.getTerrainId(tile)
				if currTT == MMTERRAIN.ArablePoor or currTT == MMTERRAIN.Arable or currTT == MMTERRAIN.ArableLush or currTT == MMTERRAIN.Heathland then
					local tileId = tileutil.getTileId(tile)
					if db.tileData[tileId] == nil or 																						-- No stored data for this tile (shouldn't occur)
					   db.tileData[tileId].lastTerrainTypeChangeYear == nil or 																-- No record of terrain type change for this tile (after map initialization)
					   (db.tileData[tileId].lastTerrainTypeChangeYear + constant.mmTerrain.TILE_CLIMATE_CHANGE_MIN_YEARS) < gameYear		-- Record of terrain type change, but enough time has elapsed
					then
						local randomNumber = math.random(1000)
						log.info("randomNumber = " .. randomNumber .. ", modulus = " .. modulus)
						if randomNumber % modulus == 0 then
							-- Note that mayAdjustLandQuality() may call events.setTerrainType, which updates tileData.currentTerrainType and tileData.yearLastTypeChange
							local landQualityChanged = mayAdjustLandQuality(tile, db.tileData[tileId].nativeTerrainType, climateIsCooling, climateIsWarming)
							if landQualityChanged == true then
								-- In maps with an overall dry climate, some terrain can *natively* be ArablePoor
								-- If such terrain changed to Arable during a warm period, it could conceivably change back to ArablePoor during a cool period
								-- Both progressions would require updating the native terrain as well, so that the code to revert unworked terrain doesn't
								--		make a change that should only be caused by a climate difference.
								-- Also, if Heathland is improved to Woodland by warming, change the native terrain type as well, to PineForest
								local newTT = tileutil.getTerrainId(tile)
								if newTT == MMTERRAIN.Arable and currTT == MMTERRAIN.ArablePoor and db.tileData[tileId].nativeTerrainType == MMTERRAIN.ArablePoor then
									db.tileData[tileId].nativeTerrainType = MMTERRAIN.Arable
								elseif newTT == MMTERRAIN.ArablePoor and currTT == MMTERRAIN.Arable and db.tileData[tileId].nativeTerrainType == MMTERRAIN.Arable then
									db.tileData[tileId].nativeTerrainType = MMTERRAIN.ArablePoor
								elseif newTT == MMTERRAIN.Woodland and currTT == MMTERRAIN.Heathland and db.tileData[tileId].nativeTerrainType == MMTERRAIN.Heathland then
									db.tileData[tileId].nativeTerrainType = MMTERRAIN.PineForest
								end
								local cityNameForPopupMessage = nil
								-- The following code will only show the *first* city whose radius contains the tile, if there is more than one
								for city in civ.iterateCities() do
									if city.owner.isHuman == true then
										for _, radiusTile in ipairs(tileutil.getCityRadiusTiles(city), true) do
											if civ.isTile(radiusTile) == true and tile == radiusTile then
												cityNameForPopupMessage = city.name
												break
											end
										end
									end
									if cityNameForPopupMessage ~= nil then
										break
									end
								end
								if cityNameForPopupMessage ~= nil then
									civ.ui.centerView(tile)
									if  newTT == MMTERRAIN.ArablePoor then
										uiutil.messageDialog("Poor Quality Arable Land", "Sire, unfortunately the cooler temperatures in recent years have resulted in lower yields from the arable land at " .. tile.x .. "," .. tile.y .. " near our city of " .. cityNameForPopupMessage .. ", and we must accept that this land is now of relatively poor quality.")
									elseif currTT == MMTERRAIN.ArableLush and newTT == MMTERRAIN.Arable then
										uiutil.messageDialog("Declining Arable Land", "Sire, unfortunately the cooler temperatures in recent years have affected the previously lush terrain at " .. tile.x .. "," .. tile.y .. " near our city of " .. cityNameForPopupMessage .. ", and it is now producing only average yields.")
									elseif currTT == MMTERRAIN.ArablePoor and newTT == MMTERRAIN.Arable then
										uiutil.messageDialog("Improving Arable Land", "Good news, Sire! Due to improved weather patterns in recent years, the previously poor soil at " .. tile.x .. "," .. tile.y .. " near our city of " .. cityNameForPopupMessage .. " is now generating quite respectable yields.")
									elseif  newTT == MMTERRAIN.ArableLush then
										uiutil.messageDialog("Lush Arable Land", "Great news, Sire! Due to improved weather patterns in recent years, the arable land at " .. tile.x .. "," .. tile.y .. " near our city of " .. cityNameForPopupMessage .. " is now generating exceptional yields.")
									elseif  newTT == MMTERRAIN.Woodland then
										uiutil.messageDialog("Better Woodland Quality", "Good news, Sire! Due to improved weather patterns in recent years, small trees have taken root in the heathland at " .. tile.x .. "," .. tile.y .. " near our city of " .. cityNameForPopupMessage .. ", and this can now be considered a decent woodland.")
									end
								end
							end
						end
					end
				end
			end
		end
	end
	log.info("applyClimateChangeToMap() completed in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")
end

local function convertTerrainForLargeCities (tribe) --> void
	log.trace()
	for city in civ.iterateCities() do
		if city.owner == tribe and city.size >= constant.mmTerrain.URBAN_TILE_NUM_TO_MIN_CITY_SIZE_TABLE[1] then
			local currentUrbanTiles = db.cityData[city.id].urbanizationLevel or 0
			local requiredUrbanTiles = 0
			for loop = 1, #constant.mmTerrain.URBAN_TILE_NUM_TO_MIN_CITY_SIZE_TABLE do
				if city.size >= constant.mmTerrain.URBAN_TILE_NUM_TO_MIN_CITY_SIZE_TABLE[loop] then
					requiredUrbanTiles = requiredUrbanTiles + 1
				end
			end
			if requiredUrbanTiles > currentUrbanTiles then
				log.info("Need to add Urban terrain for " .. tribe.adjective .. " city of " .. city.name ..
					" (" .. requiredUrbanTiles .. " > " .. currentUrbanTiles .. ")")
				if currentUrbanTiles == 0 then
					setTerrainType(city.location, MMTERRAIN.Urban)
					currentUrbanTiles = currentUrbanTiles + 1
					if tribe.isHuman == true then
						civ.ui.centerView(city.location)
						uiutil.messageDialog("Urbanization",
							"The city of " .. city.name .. " has grown to size " .. city.size ..
							",|and the underlying terrain type has been changed|to reflect the increased urbanization.", 250)
					end
				end
				while requiredUrbanTiles > currentUrbanTiles do
					local candidateTiles = { }
					local intercardinalTiles = tileutil.getIntercardinalTiles(city.location, false)
					-- 1a. Intercardinal Arable Poor
					for _, tile in pairs(intercardinalTiles) do
						if civ.isTile(tile) then
							if tileutil.isLandTile(tile) == true and
							   tileutil.getTerrainId(tile) == MMTERRAIN.ArablePoor then
								log.info(tile.x .. "," .. tile.y .. " is a candidate")
								table.insert(candidateTiles, tile)
							end
						end
					end
					-- 1b. Intercardinal Arable
					if #candidateTiles == 0 then
						for _, tile in pairs(intercardinalTiles) do
							if civ.isTile(tile) then
								if tileutil.isLandTile(tile) == true and
								   tileutil.getTerrainId(tile) == MMTERRAIN.Arable then
									log.info(tile.x .. "," .. tile.y .. " is a candidate")
									table.insert(candidateTiles, tile)
								end
							end
						end
					end
					-- 1c. Intercardinal Woodland
					if #candidateTiles == 0 then
						for _, tile in pairs(intercardinalTiles) do
							if civ.isTile(tile) then
								if tileutil.isLandTile(tile) == true and
								   tileutil.getTerrainId(tile) == MMTERRAIN.Woodland then
									log.info(tile.x .. "," .. tile.y .. " is a candidate")
									table.insert(candidateTiles, tile)
								end
							end
						end
					end
					-- 1d. Intercardinal other
					if #candidateTiles == 0 then
						for _, tile in pairs(intercardinalTiles) do
							if civ.isTile(tile) then
								local currTT = tileutil.getTerrainId(tile)
								if tileutil.isLandTile(tile) == true and
								   currTT ~= MMTERRAIN.Mountains and currTT ~= MMTERRAIN.MountainPass and
								   currTT ~= MMTERRAIN.Monastery and currTT ~= MMTERRAIN.Urban then
									log.info(tile.x .. "," .. tile.y .. " is a candidate")
									table.insert(candidateTiles, tile)
								end
							end
						end
					end

					local cardinalTiles = tileutil.getCardinalTiles(city.location, false)
					-- 2a. Cardinal Arable Poor
					if #candidateTiles == 0 then
						for _, tile in pairs(cardinalTiles) do
							if civ.isTile(tile) then
								if tileutil.isLandTile(tile) == true and
								   tileutil.getTerrainId(tile) == MMTERRAIN.ArablePoor then
									log.info(tile.x .. "," .. tile.y .. " is a candidate")
									table.insert(candidateTiles, tile)
								end
							end
						end
					end
					-- 2b. Cardinal Arable
					if #candidateTiles == 0 then
						for _, tile in pairs(cardinalTiles) do
							if civ.isTile(tile) then
								if tileutil.isLandTile(tile) == true and
								   tileutil.getTerrainId(tile) == MMTERRAIN.Arable then
									log.info(tile.x .. "," .. tile.y .. " is a candidate")
									table.insert(candidateTiles, tile)
								end
							end
						end
					end
					-- 2c. Cardinal Woodland
					if #candidateTiles == 0 then
						for _, tile in pairs(cardinalTiles) do
							if civ.isTile(tile) then
								if tileutil.isLandTile(tile) == true and
								   tileutil.getTerrainId(tile) == MMTERRAIN.Woodland then
									log.info(tile.x .. "," .. tile.y .. " is a candidate")
									table.insert(candidateTiles, tile)
								end
							end
						end
					end
					-- 2d. Cardinal other
					if #candidateTiles == 0 then
						for _, tile in pairs(cardinalTiles) do
							if civ.isTile(tile) then
								local currTT = tileutil.getTerrainId(tile)
								if tileutil.isLandTile(tile) == true and
								   currTT ~= MMTERRAIN.Mountains and currTT ~= MMTERRAIN.MountainPass and
								   currTT ~= MMTERRAIN.Monastery and currTT ~= MMTERRAIN.Urban then
									log.info(tile.x .. "," .. tile.y .. " is a candidate")
									table.insert(candidateTiles, tile)
								end
							end
						end
					end

					if #candidateTiles > 0 then
						local randomKey = math.random(#candidateTiles)
						local urbanTile = candidateTiles[randomKey]
						tileutil.removeFarm(urbanTile)
						tileutil.removeIrrigation(urbanTile)
						tileutil.removeMine(urbanTile)
						tileutil.removeFortress(urbanTile)
						setTerrainType(urbanTile, MMTERRAIN.Urban)
						tileutil.addRoad(urbanTile)
						for unit in urbanTile.units do
							if unit.type.role == 5 then
								unitutil.clearOrders(unit)
							end
							if unit.type == MMUNIT.MotteandBailey or unit.type == MMUNIT.StoneCastle then
								unitutil.deleteUnit(unit)
							end
						end
						updateMapView(urbanTile, tribe)
						if tribe.isHuman == true then
							civ.ui.centerView(city.location)
							uiutil.messageDialog("Urbanization",
								"^The city of " .. city.name .. " has grown to size " .. city.size ..
								",|and the urbanization has spread into the|surrounding region.", 150)
						end
					else
						log.info("No adjacent tile is eligible to be converted to Urban; no action taken")
					end
					-- This will be incremented even if no eligible tile was found, to avoid an infinite loop
					-- and to avoid re-checking this every single turn
					currentUrbanTiles = currentUrbanTiles + 1
				end		-- end of "while requiredUrbanTiles > currentUrbanTiles do"
				db.cityData[city.id].urbanizationLevel = currentUrbanTiles
			end
		end
	end
end

local function convertTerrainForNewCity (city) --> void
	log.trace()
	local tile = city.location
	local currTT = tileutil.getTerrainId(tile)
	local newTT = currTT

--			currTT == MMTERRAIN.ArablePoor			OK
--			currTT == MMTERRAIN.Arable				OK
--			currTT == MMTERRAIN.Pasture				OK
--			currTT == MMTERRAIN.ArableLush			OK
--			currTT == MMTERRAIN.MountainPass		Not listed in @FERTILITY, but will not auto-convert to something else; normally generates no Health, +1 with city
		if	currTT == MMTERRAIN.Mountains			then newTT = MMTERRAIN.MountainPass		-- Not listed in @FERTILITY
	elseif	currTT == MMTERRAIN.DenseForest			then newTT = MMTERRAIN.Arable
	elseif	currTT == MMTERRAIN.PineForest			then newTT = MMTERRAIN.Arable
	elseif	currTT == MMTERRAIN.Heathland			then newTT = MMTERRAIN.Pasture
	elseif	currTT == MMTERRAIN.MarshFen			then newTT = MMTERRAIN.Arable			-- Not listed in @FERTILITY
--			currTT == MMTERRAIN.Sea					Not possible
	elseif	currTT == MMTERRAIN.Woodland			then newTT = MMTERRAIN.Arable
	elseif	currTT == MMTERRAIN.Hills 				then newTT = MMTERRAIN.TerracedHills
--			currTT == MMTERRAIN.TerracedHills		OK
--			currTT == MMTERRAIN.Monastery			Not listed in @FERTILITY, unsupported, will be removed in a different function
--			currTT == MMTERRAIN.Urban				Not listed in @FERTILITY, but will not auto-convert to something else; generates no Health
													-- Does not occur naturally, only possible if a previous size-10+ city is completely destroyed
	end
	if newTT == MMTERRAIN.TerracedHills and tileutil.hasRiver(tile) == false and city.owner.isHuman == false then
		-- This terrain will not produce any Trade, even with the road that is given to all city tiles (unless it has a special, but this information is not accessible by Lua)
		-- If this is a human player, it's their decision and no changes will be made.
		-- If this is an AI player, this is not acceptable, and the terrain will be converted further, to Arable.
		newTT = MMTERRAIN.Arable
	end

	if newTT ~= currTT then
		setTerrainType(tile, newTT, true)
		log.action("Converted location of " .. city.name .. " from " .. MMTERRAIN[currTT] .. " to " .. MMTERRAIN[newTT])
		local tileId = tileutil.getTileId(tile)

		if newTT == MMTERRAIN.Arable then
			-- City tile will sometimes be converted to Arable(lush), but it will never become Arable(poor)
			-- In part, this would simply tempt the human player to cancel the city build, wait a turn, and try again for a more favorable result
			local landQualityChanged = mayAdjustLandQuality(tile, db.tileData[tileId].nativeTerrainType, false, true)
			if landQualityChanged == true then
				newTT = tileutil.getTerrainId(tile)
				if city.owner.isHuman == true and newTT == MMTERRAIN.ArableLush then
					uiutil.messageDialog("Lush Arable Land", "Great news, Sire! We have learned that the terrain on the site of this new city is highly fertile, and a perfect location on which to begin construction.")
				end
			end
		end

		-- There is a potential exploit for the human player, where they could cancel building the city AFTER this function has changed the terrain
		-- This would essentially give them a way to fully clear forest to Arable (potentially even Arable(lush), with no risk of Arable(poor)) in a single turn, for any tile
		-- To prevent this, we'll track the tile which we converted, and convert it *back* on the following turn, if it does not contain a city.
		db.tileData[tileId].cityTerrainConvertedFrom = currTT
		log.update("Stored former terrain type (" .. MMTERRAIN[currTT] .. ") for review next turn")
	end
end

local function documentVisibleTiles (unit) --> void
	log.trace()
	if unit.owner.isHuman == true then
		local visibleDistance = 1
		if unitutil.hasFlagTwoSpaceVisibility(unit.type) then
			visibleDistance = 2
		end
		for _, visibleTile in ipairs(tileutil.getTilesByDistance(unit.location, visibleDistance, true)) do
			if civ.isTile(visibleTile) then
				local tileId = tileutil.getTileId(visibleTile)
				db.tileData[tileId].visible = true
			end
		end
	end
end

local function getCostToMove (unittype, fromTile, toTile) --> decimal
	log.trace()
	local movementPointCost = 1
	if unittype.domain ~= domain.Air then
		movementPointCost = TERRAIN_DATA[tileutil.getTerrainId(toTile)].movecost * totpp.movementMultipliers.aggregate
		if tileutil.hasRailroad(fromTile) == true and tileutil.hasRailroad(toTile) == true then
			movementPointCost = round(totpp.movementMultipliers.aggregate / totpp.movementMultipliers.railroad)
		elseif tileutil.hasRoad(fromTile) == true and (tileutil.hasRailroad(toTile) == true or tileutil.hasRoad(toTile) == true) then
			movementPointCost = round(totpp.movementMultipliers.aggregate / totpp.movementMultipliers.road)
		elseif tileutil.hasRiver(fromTile) == true and tileutil.hasRiver(toTile) == true then
			movementPointCost = round(totpp.movementMultipliers.aggregate / totpp.movementMultipliers.river)
		elseif unitutil.hasFlagAlpine(unittype) then
			movementPointCost = round(totpp.movementMultipliers.aggregate / totpp.movementMultipliers.alpine)
		end
	end
	return movementPointCost
end

-- This is called internally by getFormattedTerrainData() and must be defined prior to it in this file:
local function getTerrainData (tile) --> table

	log.trace()
	local terrainId = tileutil.getTerrainId(tile)
	-- The following approach copies the table by value, instead of by reference:
	local terrainData = { }
	for key, value in pairs(TERRAIN_DATA[terrainId]) do
		terrainData[key] = value
	end
	terrainData.terrainId = terrainId
	return terrainData
end

local function getFormattedTerrainData (tile) --> table
	log.trace()
	local dataTable = { }
	if tile ~= nil then
		local terrainData = getTerrainData(tile)

		local river = tileutil.hasRiver(tile)
		if river == true then
			terrainData.name = terrainData.name .. " + River"
			terrainData.movecost = 1
			terrainData.defensePct = terrainData.defensePct + 50
			terrainData.trade = terrainData.trade + 1
			if terrainData.terrainId == MMTERRAIN.Woodland then
				terrainData.health = terrainData.health + 1
			end
		end

		local unitDefense = "Normal"
		if terrainData.defensePct ~= 100 then
			unitDefense = tostring(terrainData.defensePct - 100) .. "%"
			if terrainData.defensePct > 100 then
				unitDefense = "+" .. unitDefense
			end
		end
		local irrigationEffect = " "
		local irrigationTurns = " "
		if terrainData.irrigate == true then
			irrigationEffect = "+" .. tostring(terrainData.irrigateBonus) .. " Health"
			irrigationTurns = tostring(terrainData.irrigateTurns)
		elseif terrainData.irrigate == false then
			irrigationEffect = "(N/A)"
			irrigationTurns = "(N/A)"
		else
			irrigationEffect = tostring(terrainData.irrigate)
			if river == true then
				irrigationEffect = irrigationEffect .. " + River"
			end
			irrigationTurns = tostring(terrainData.irrigateTurns)
		end
		local mineWoodcutEffect = " "
		local mineWoodcutTurns = " "
		if terrainData.mine == true then
			mineWoodcutEffect = "+" .. tostring(terrainData.mineBonus) .. " Materials"
			if terrainData.terrainId == MMTERRAIN.Woodland and river == true then
				mineWoodcutEffect = mineWoodcutEffect .. ", -1 Health"
			end
			mineWoodcutTurns = tostring(terrainData.mineTurns)
		elseif terrainData.mine == false then
			mineWoodcutEffect = "(N/A)"
			mineWoodcutTurns = "(N/A)"
		else
			mineWoodcutEffect = tostring(terrainData.mine)
			if river == true then
				mineWoodcutEffect = mineWoodcutEffect .. " + River"
			end
			mineWoodcutTurns = tostring(terrainData.mineTurns)
		end

		local specialTextTable = { }
		table.insert(specialTextTable, "Terraform Effect:")
		local terraformEffect = "   "
		if terrainData.transform == false then
			terraformEffect = terraformEffect .. "(N/A)"
		else
			terraformEffect = terraformEffect .. tostring(terrainData.transform)
			if river == true then
				terraformEffect = terraformEffect .. " + River"
			end
		end
		table.insert(specialTextTable, terraformEffect)
		if type(terrainData.roadTurns) == "number" then
			table.insert(specialTextTable, "Effect of Road:")
			table.insert(specialTextTable, "   Movement Cost: 1/" .. tostring(totpp.movementMultipliers.road) .. " of a point")
			if terrainData.roadBonus == 1 or terrainData.trade > 0 or river == true then
				table.insert(specialTextTable, "   Trade: +1")
			end
		end
		table.insert(specialTextTable, "Possible Resources:")
		table.insert(specialTextTable, "   " .. terrainData.resource1)
		table.insert(specialTextTable, "   " .. terrainData.resource2)

		table.insert(dataTable, { statLabel = "Terrain Type:",			statValue = terrainData.name,					space = " ",	specialText = specialTextTable[1] or " " })
		table.insert(dataTable, { statLabel = "Movement Cost:",			statValue = tostring(terrainData.movecost),		space = " ",	specialText = specialTextTable[2] or " " })
		table.insert(dataTable, { statLabel = "Unit Defense:",			statValue = unitDefense,						space = " ",	specialText = specialTextTable[3] or " " })
		table.insert(dataTable, { statLabel = "*Health:",				statValue = tostring(terrainData.health),		space = " ",	specialText = specialTextTable[4] or " " })
		table.insert(dataTable, { statLabel = "*Materials:",			statValue = tostring(terrainData.materials),	space = " ",	specialText = specialTextTable[5] or " " })
		table.insert(dataTable, { statLabel = "*Trade:",				statValue = tostring(terrainData.trade),		space = " ",	specialText = specialTextTable[6] or " " })
		table.insert(dataTable, { statLabel = "Irrigation Effect:",		statValue = irrigationEffect,					space = " ",	specialText = specialTextTable[7] or " " })
		table.insert(dataTable, { statLabel = "Irrigation Turns:",		statValue = irrigationTurns,					space = " ",	specialText = specialTextTable[8] or " " })
		table.insert(dataTable, { statLabel = "Mine/Woodcut Effect:",	statValue = mineWoodcutEffect,					space = " ",	specialText = " " })
		table.insert(dataTable, { statLabel = "Mine/Woodcut Turns:",	statValue = mineWoodcutTurns,					space = " ",	specialText = " " })
	end
	return dataTable
end

local function incrementTileUsageData () --> void
	log.trace()
	local startTimestamp = os.clock()
	local gameYear = civ.getGameYear()
	for city in civ.iterateCities() do
		for _, tile in ipairs(tileutil.getCityTilesWorked(city, true)) do		-- Also includes the city tile itself, which is always worked
			-- In db.tileData, usage of Monastery tiles is handled separately since conceptually, they aren't worked by a city's citizens, they are worked by the monks who live there.
			-- We will also ignore Sea tiles, since they can never be depleted or revert
			local terrainId = tileutil.getTerrainId(tile)
			if terrainId ~= MMTERRAIN.Monastery and terrainId ~= MMTERRAIN.Sea then
				local tileId = tileutil.getTileId(tile)
				local previousUsageLevel = db.tileData[tileId].usageLevel or 0
				local newUsageLevel = previousUsageLevel

				-- Improved tiles have their usage incremented, except for Woodland which has irrigation added automatically:
				if tileutil.hasFarm(tile) == true or (tileutil.hasIrrigation(tile) == true and terrainId ~= MMTERRAIN.Woodland) or tileutil.hasMine(tile) == true then
					newUsageLevel = newUsageLevel + 1
				elseif tileutil.hasCity(tile) == true then
					-- City tiles have their usage incremented, IF AND ONLY IF they are on a terrain type that can change due to depletion:
					if terrainId == MMTERRAIN.ArableLush or terrainId == MMTERRAIN.Arable then
						newUsageLevel = newUsageLevel + 1
					end
				end
				-- Other tiles that are worked WITHOUT being improved do not accrue usage (the usage is less intense and does not lead to depletion)

				db.tileData[tileId].lastWorkedByCityId = city.id
				db.tileData[tileId].lastWorkedByCityName = city.name
				db.tileData[tileId].lastWorkedByTribeId = city.owner.id
				db.tileData[tileId].lastWorkedYear = gameYear
				db.tileData[tileId].usageLevel = newUsageLevel

				if newUsageLevel > previousUsageLevel then
					log.update("Increased usage level of " .. tile.x .. "," .. tile.y .. " by " .. city.name .. " from " .. previousUsageLevel .. " to " .. newUsageLevel)
				else
					log.update("Documented usage of " .. tile.x .. "," .. tile.y .. " by " .. city.name)
				end
			end
		end
	end
	for unit in civ.iterateUnits() do
		if unit.type == MMUNIT.Monks then
			local tile = unit.location
			if tileutil.getTerrainId(tile) == MMTERRAIN.Monastery then
				local tileId = tileutil.getTileId(tile)
				db.tileData[tileId].lastWorkedByTribeId = unit.owner.id
				db.tileData[tileId].lastWorkedYear = gameYear
				log.update("Documented usage of Monastery at " .. tile.x .. "," .. tile.y .. " by " .. unit.type.name)
			end
		end
	end
	log.info("incrementTileUsageData() completed in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")
end

local function initializeNewMap () --> void
	log.trace()
	uiutil.messageDialog("Custom Medieval Terrain", "Medieval Millennium will now analyze and adjust the world map.||This process may take several seconds, depending on the map size and your computer's capabilities.||Press OK to begin, and wait for a second message confirming that the map adjustments are complete.")

	local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()

	local previousLogLevel = log.getLogLevel()
	log.setLogLevel(log.EnumLogLevel.Warning)

	-- PART 1: Special prep
	-- Not needed for current version

	-- PART 2: Analyze current map
	local tileCount = 0
	local terrainCount = { }
	for i = 0, 15 do
		terrainCount[i] = 0
	end
	local riverTileCount = 0
	for tile in tileutil.iterateTiles() do
		tileCount = tileCount + 1
		local oldTT = tileutil.getTerrainId(tile)
		terrainCount[oldTT] = terrainCount[oldTT] + 1
		if tileutil.hasRiver(tile) then
			riverTileCount = riverTileCount + 1
		end
	end
	local landTiles = tileCount - terrainCount[baseTerrainId.Ocean]
	log.info("Map analysis: " .. tileCount .. " tiles, " .. landTiles .. " land tiles")
	for i = 0, 15 do
		if i <= 10 then
			log.info("  " .. baseTerrainName[i] .. " = " .. terrainCount[i])
		elseif terrainCount[i] ~= 0 then
			log.info("  [Slot " .. i .. "] = " .. terrainCount[i])
		end
	end

	local pctPlainsToArablePoor = 0
	if ((terrainCount[baseTerrainId.Desert] + terrainCount[baseTerrainId.Plains]) / landTiles) * 100 > constant.mmTerrain.HEATHLAND_MAX_INIT_PCT then
		pctPlainsToArablePoor = math.min( ( (terrainCount[baseTerrainId.Plains] - ((round(landTiles * (constant.mmTerrain.HEATHLAND_MAX_INIT_PCT / 100))) - terrainCount[baseTerrainId.Desert])) /
			terrainCount[baseTerrainId.Plains] ) * 100, 100)
	end
	log.info("pctPlainsToArablePoor = " .. tostring(pctPlainsToArablePoor))

	local pctHillsToWoodland = 0
	if ((terrainCount[baseTerrainId.Desert] + terrainCount[baseTerrainId.Plains] + terrainCount[baseTerrainId.Hills]) / landTiles) * 100 > constant.mmTerrain.DRY_MAX_INIT_PCT then
		local dryTilesFromDesertAndPlains = terrainCount[baseTerrainId.Desert] + (terrainCount[baseTerrainId.Plains] * (1 - (pctPlainsToArablePoor / 100)))
		local maxDryTilesPermitted = round(landTiles * (constant.mmTerrain.DRY_MAX_INIT_PCT / 100))
		local dryTilesAvailable = maxDryTilesPermitted - dryTilesFromDesertAndPlains
		if dryTilesAvailable < terrainCount[baseTerrainId.Hills] then
			pctHillsToWoodland = math.min(((terrainCount[baseTerrainId.Hills] - dryTilesAvailable) / terrainCount[baseTerrainId.Hills]) * 100, 100)
		end
	end
	log.info("pctHillsToWoodland = " .. tostring(pctHillsToWoodland))

	-- PART 3: Main conversion

	for tile in tileutil.iterateTiles() do
		local tileId = tileutil.getTileId(tile)
		local latitudePercent = (tile.y / mapHeight) * 100
		local pctForestToPine = math.min(math.max((100 - (latitudePercent * 2)), 0), 100)
		local oldTT = tileutil.getTerrainId(tile)
		local nativeTT = oldTT
		local currTT = oldTT

		if oldTT == baseTerrainId.Desert then
			nativeTT = MMTERRAIN.Heathland
			currTT = nativeTT
		elseif oldTT == baseTerrainId.Plains then
			nativeTT = MMTERRAIN.Heathland
			currTT = nativeTT
			if math.random(100) <= pctPlainsToArablePoor then
				nativeTT = MMTERRAIN.ArablePoor
				currTT = nativeTT
			elseif math.random(100) <= constant.mmTerrain.PLAINS_TO_PASTURE_INIT_PCT then
				currTT = MMTERRAIN.Pasture
			end
		elseif oldTT == baseTerrainId.Grassland then
			nativeTT = MMTERRAIN.DenseForest
			if math.random(100) <= pctForestToPine then
				nativeTT = MMTERRAIN.PineForest
			end
			currTT = nativeTT
			if currTT == MMTERRAIN.PineForest then
				if math.random(100) <= constant.mmTerrain.PINEFOREST_TO_WOODLAND_INIT_PCT then
					currTT = MMTERRAIN.Woodland
				end
				-- Some PineForest will be converted to MarshFen in a separate loop
			elseif currTT == MMTERRAIN.DenseForest then
				if math.random(100) <= constant.mmTerrain.DENSEFOREST_TO_WOODLAND_INIT_PCT then
					currTT = MMTERRAIN.Woodland
				end
				-- Some DenseForest will also be converted to PineForest or Woodland in a separate loop
			end
			if currTT == MMTERRAIN.Woodland then
				if math.random(100) <= constant.mmTerrain.WOODLAND_TO_ARABLE_INIT_PCT then
					currTT = MMTERRAIN.Arable
				end
			end
			-- Some Arable will be converted to Poor or Lush in a separate loop
		elseif oldTT == baseTerrainId.Forest then
			nativeTT = MMTERRAIN.DenseForest
			if math.random(100) <= pctForestToPine then
				nativeTT = MMTERRAIN.PineForest
				-- Some PineForest will be converted to MarshFen in a separate loop
			end
			-- Some DenseForest will also be converted to PineForest or Woodland in a separate loop
			currTT = nativeTT
		elseif oldTT == baseTerrainId.Hills then
			nativeTT = MMTERRAIN.Hills
			currTT = nativeTT
			if math.random(100) <= pctHillsToWoodland then
				nativeTT = MMTERRAIN.Woodland
				currTT = nativeTT
			elseif math.random(100) <= constant.mmTerrain.HILLS_TO_TERRACEDHILLS_INIT_PCT then
				currTT = MMTERRAIN.TerracedHills
			end
		elseif oldTT == baseTerrainId.Mountains then
			nativeTT = MMTERRAIN.Mountains
			currTT = nativeTT
			-- Convert currTT to MountainPass for some
		elseif oldTT == baseTerrainId.Tundra then
			nativeTT = MMTERRAIN.PineForest
			currTT = nativeTT
			-- Some PineForest will be converted to MarshFen in a separate loop
		elseif oldTT == baseTerrainId.Glacier then
			nativeTT = MMTERRAIN.PineForest
			currTT = nativeTT
			-- Some PineForest will be converted to MarshFen in a separate loop
		elseif oldTT == baseTerrainId.Swamp then
			nativeTT = MMTERRAIN.MarshFen
			currTT = nativeTT
		elseif oldTT == baseTerrainId.Jungle then
			nativeTT = MMTERRAIN.DenseForest
			currTT = nativeTT
			-- Some DenseForest will be converted to PineForest or Woodland in a separate loop
		elseif oldTT == baseTerrainId.Ocean then
			nativeTT = MMTERRAIN.Sea
			currTT = nativeTT
		end

		-- Convert terrain on map:
		if currTT ~= oldTT then
			tileutil.setTerrainId(tile, currTT, MMTERRAIN, false)
		end

		-- Initialize storage for this tile:
		db.tileData[tileId] = { }
		db.tileData[tileId].visible = false

		-- Store native and current terrain type:
		if nativeTT ~= MMTERRAIN.Sea then
			db.tileData[tileId].nativeTerrainType = nativeTT
		end
		if currTT ~= MMTERRAIN.Sea then
			db.tileData[tileId].currentTerrainType = currTT
		end
	end

	-- PART 4: convert DenseForest intercardinally adjacent to Mountains to PineForest, and convert some clustered PineForest to MarshFen or Heathland (changes native type)
	for tile in tileutil.iterateTiles() do
		local currTT = tileutil.getTerrainId(tile)
		if currTT == MMTERRAIN.DenseForest then
			local adjacentToMountains = false
			for _, adjTile in ipairs(tileutil.getIntercardinalTiles(tile), false) do
				if civ.isTile(adjTile) then
					local adjTT = tileutil.getTerrainId(adjTile)
					if adjTT == MMTERRAIN.Mountains then
						adjacentToMountains = true
						break
					end
				end
			end
			if adjacentToMountains == true then
				tileutil.setTerrainId(tile, MMTERRAIN.PineForest, MMTERRAIN, false)
				local tileId = tileutil.getTileId(tile)
				db.tileData[tileId].nativeTerrainType = MMTERRAIN.PineForest
				db.tileData[tileId].currentTerrainType = MMTERRAIN.PineForest
			end
		elseif currTT == MMTERRAIN.PineForest then
			local adjacentToPineOnly = true
			local adjacentToPineCount = 0
			for _, adjTile in ipairs(tileutil.getAdjacentTiles(tile), false) do
				if civ.isTile(adjTile) then
					local adjTT = tileutil.getTerrainId(adjTile)
					if adjTT == MMTERRAIN.PineForest then
						adjacentToPineCount = adjacentToPineCount + 1
					elseif adjTT ~= MMTERRAIN.Sea then
						adjacentToPineOnly = false
						break
					end
				end
			end
			if adjacentToPineOnly == true and adjacentToPineCount >= constant.mmTerrain.FOREST_CLUSTER_MIN_ADJACENT_MATCH_QTY then
				local hasNearbyMarshOrHeath = false
				for _, closeTile in ipairs(tileutil.getTilesByDistance(tile, constant.mmTerrain.FOREST_CLUSTER_MIN_UNBROKEN_RADIUS), false) do
					if civ.isTile(closeTile) then
						if tileutil.getTerrainId(closeTile) == MMTERRAIN.MarshFen or tileutil.getTerrainId(closeTile) == MMTERRAIN.Heathland then
							hasNearbyMarshOrHeath = true
							break
						end
					end
				end
				if hasNearbyMarshOrHeath == false then
					local randomNumber = math.random(100)
					if randomNumber <= constant.mmTerrain.PINEFOREST_CLUSTER_TO_MARSHFEN_PCT then
						tileutil.setTerrainId(tile, MMTERRAIN.MarshFen, MMTERRAIN, false)
						local tileId = tileutil.getTileId(tile)
						db.tileData[tileId].nativeTerrainType = MMTERRAIN.MarshFen
						db.tileData[tileId].currentTerrainType = MMTERRAIN.MarshFen
					elseif randomNumber > (100 - constant.mmTerrain.PINEFOREST_CLUSTER_TO_HEATHLAND_PCT) then
						tileutil.setTerrainId(tile, MMTERRAIN.Heathland, MMTERRAIN, false)
						local tileId = tileutil.getTileId(tile)
						db.tileData[tileId].nativeTerrainType = MMTERRAIN.Heathland
						db.tileData[tileId].currentTerrainType = MMTERRAIN.Heathland
					end
				end
			end
		end
	end

	-- PART 5: convert some clustered Dense Forest to Heathland (changes native type)
	--		   Only converts tiles that are *currently* Dense Forest, but checks for ones that are in a radius of *native* Dense Forest
	for tile in tileutil.iterateTiles() do
		local currTT = tileutil.getTerrainId(tile)
		if currTT == MMTERRAIN.DenseForest then
			local adjacentToNativeDenseCount = 0
			local adjacentToNativeDenseOnly = true
			for _, adjTile in ipairs(tileutil.getAdjacentTiles(tile), false) do
				if civ.isTile(adjTile) then
					local adjTileId = tileutil.getTileId(adjTile)
					local adjNativeTT = db.tileData[adjTileId].nativeTerrainType
					if adjNativeTT == MMTERRAIN.DenseForest then
						adjacentToNativeDenseCount = adjacentToNativeDenseCount + 1
					elseif adjNativeTT ~= MMTERRAIN.Sea then
						adjacentToNativeDenseOnly = false
						break
					end
				end
			end
			if adjacentToNativeDenseOnly == true and adjacentToNativeDenseCount >= constant.mmTerrain.FOREST_CLUSTER_MIN_ADJACENT_MATCH_QTY then
				local hasNearbyHeath = false
				for _, closeTile in ipairs(tileutil.getTilesByDistance(tile, constant.mmTerrain.FOREST_CLUSTER_MIN_UNBROKEN_RADIUS), false) do
					if civ.isTile(closeTile) then
						if tileutil.getTerrainId(closeTile) == MMTERRAIN.Heathland then
							hasNearbyHeath = true
							break
						end
					end
				end
				if hasNearbyHeath == false then
					if math.random(100) <= constant.mmTerrain.DENSEFOREST_CLUSTER_TO_HEATHLAND_PCT then
						tileutil.setTerrainId(tile, MMTERRAIN.Heathland, MMTERRAIN, false)
						local tileId = tileutil.getTileId(tile)
						db.tileData[tileId].nativeTerrainType = MMTERRAIN.Heathland
						db.tileData[tileId].currentTerrainType = MMTERRAIN.Heathland
					end
				end
			end
		end
	end

	-- PART 6: convert some Arable to Poor or Lush, and convert some clustered DenseForest to Woodland (doesn't change native type)
	for tile in tileutil.iterateTiles() do
		local currTT = tileutil.getTerrainId(tile)
		if currTT == MMTERRAIN.Arable then
			local tileId = tileutil.getTileId(tile)
			mayAdjustLandQuality(tile, db.tileData[tileId].nativeTerrainType, true, true)
			-- The above function returns true or false, to indicate if a change was actually made, but that info actually isn't necessary in this case
			db.tileData[tileId].currentTerrainType = tileutil.getTerrainId(tile)
		elseif currTT == MMTERRAIN.DenseForest then
			local adjacentToDenseOnly = true
			local adjacentToDenseCount = 0
			for _, adjTile in ipairs(tileutil.getAdjacentTiles(tile), false) do
				if civ.isTile(adjTile) then
					local adjTT = tileutil.getTerrainId(adjTile)
					if adjTT == MMTERRAIN.DenseForest then
						adjacentToDenseCount = adjacentToDenseCount + 1
					elseif adjTT ~= MMTERRAIN.Sea then
						adjacentToDenseOnly = false
						break
					end
				end
			end
			if adjacentToDenseOnly == true and adjacentToDenseCount >= constant.mmTerrain.FOREST_CLUSTER_MIN_ADJACENT_MATCH_QTY then
				local hasNearbyWoodland = false
				for _, closeTile in ipairs(tileutil.getTilesByDistance(tile, constant.mmTerrain.FOREST_CLUSTER_MIN_UNBROKEN_RADIUS), false) do
					if civ.isTile(closeTile) then
						if tileutil.getTerrainId(closeTile) == MMTERRAIN.Woodland then
							hasNearbyWoodland = true
							break
						end
					end
				end
				if hasNearbyWoodland == false then
					if math.random(100) <= constant.mmTerrain.DENSEFOREST_CLUSTER_TO_WOODLAND_PCT then
						tileutil.setTerrainId(tile, MMTERRAIN.Woodland, MMTERRAIN, false)
						local tileId = tileutil.getTileId(tile)
						db.tileData[tileId].currentTerrainType = MMTERRAIN.Woodland
					end
				end
			end
		end
	end

	-- PART 7: convert some native Dense Forest to Hills (changes native type)
	local nativeTerrainCount = { }
	for tile in tileutil.iterateTiles() do
		local tileId = tileutil.getTileId(tile)
		if db.tileData[tileId] ~= nil and db.tileData[tileId].nativeTerrainType ~= nil then
			nativeTerrainCount[db.tileData[tileId].nativeTerrainType] = (nativeTerrainCount[db.tileData[tileId].nativeTerrainType] or 0) + 1
		end
	end
	log.info("Map analysis (stage 7): native Dense Forest = " .. nativeTerrainCount[MMTERRAIN.DenseForest] .. ", native Hills = " .. nativeTerrainCount[MMTERRAIN.Hills])
	local hillsNeeded = round(nativeTerrainCount[MMTERRAIN.DenseForest] * (constant.mmTerrain.HILLS_TO_DENSEFOREST_PCT_MIN / 100))
	local numHills = nativeTerrainCount[MMTERRAIN.Hills]
	log.info("  " .. tostring(hillsNeeded - numHills) .. " tiles will be converted")
	local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()
	while numHills < hillsNeeded do
		local randomX = math.random(mapWidth) - 1
		local randomY = math.random(mapHeight) - 1
		local randomTile = civ.getTile(randomX, randomY, 0)
		if civ.isTile(randomTile) then
			if tileutil.hasRiver(randomTile) == false then
				local tileId = tileutil.getTileId(randomTile)
				local nativeTT = db.tileData[tileId].nativeTerrainType
				if nativeTT == MMTERRAIN.DenseForest then
					local currTT = tileutil.getTerrainId(randomTile)
					if currTT == MMTERRAIN.DenseForest then
						tileutil.setTerrainId(randomTile, MMTERRAIN.Hills, MMTERRAIN, false)
						db.tileData[tileId].currentTerrainType = MMTERRAIN.Hills
					else
						tileutil.setTerrainId(randomTile, MMTERRAIN.TerracedHills, MMTERRAIN, false)
						db.tileData[tileId].currentTerrainType = MMTERRAIN.TerracedHills
					end
					db.tileData[tileId].nativeTerrainType = MMTERRAIN.Hills
					numHills = numHills + 1
				end
			end
		end
	end

	log.setLogLevel(previousLogLevel)

end

local function listCurrentLandUsage () --> void
	-- Note: not using adjustForDifficulty() here, since this applies only to the human player
	log.trace()
	local playerTribe = civ.getPlayerTribe()
	local nationalUsage = { }
	for tileId, data in pairs(db.tileData) do
		if data.usageLevel ~= nil and data.usageLevel > 0 and data.lastWorkedByTribeId == playerTribe.id then
			local cityStillOwned = true
			if data.lastWorkedByCityId ~= nil then
				local lastWorkedByCity = civ.getCity(data.lastWorkedByCityId)
				if lastWorkedByCity.owner ~= playerTribe then
					cityStillOwned = false
				end
			end
			if cityStillOwned == true then
				local maxUsageLevel = constant.mmTerrain.OTHER_TERRAIN_DEPLETION_TURNS
				local terrainId = tileutil.getTerrainId(tileutil.getTileById(tileId))
				if terrainId == MMTERRAIN.DenseForest or terrainId == MMTERRAIN.PineForest or terrainId == MMTERRAIN.Woodland then
					maxUsageLevel = constant.mmTerrain.WOODED_TERRAIN_DEPLETION_TURNS
				end
				table.insert(nationalUsage, {
					tileKey = tileId,
					byCityId = data.lastWorkedByCityId,
					byCityName = data.lastWorkedByCityName,
					remaining = math.max(maxUsageLevel - data.usageLevel, 0)
				})
			end
		end
	end
	table.sort(nationalUsage, function (a, b) return a.remaining < b.remaining end)
	local columnTable = {
		{label = "turns", align = "right"},
		{label = "trend", align = "center"},
		{label = "location"},
		{label = "city"},
		{label = "terrain"}
	}
	local dataTable = { }

	table.insert(dataTable, {turns = "TURNS", trend = " ", location = " ", city = " ", terrain = " "})
	table.insert(dataTable, {turns = "REMAINING", trend = "USAGE", location = "LOCATION", city = "CITY", terrain = "TERRAIN"})
	for key, usage in ipairs(nationalUsage) do
		if key <= 20 then
			local tile = tileutil.getTileById(usage.tileKey)
			local terrainId = tileutil.getTerrainId(tile)
			local currentUsage = ""

			local city = civ.getCity(usage.byCityId)
			if city ~= nil then
				for _, workedTile in ipairs(tileutil.getCityTilesWorked(city, false)) do
					if workedTile == tile then
						if tileutil.hasFarm(tile) == true or (tileutil.hasIrrigation(tile) == true and terrainId ~= MMTERRAIN.Woodland) or tileutil.hasMine(tile) == true then
							currentUsage = "+"
						else
							currentUsage = "="
						end
						break
					end
				end
			end

			local cityName = usage.byCityName or ""
			if tile.city ~= nil then
				cityName = cityName .. " (city tile)"
				currentUsage = "[+]"
			end
			table.insert(dataTable, {
				turns = tostring(usage.remaining),
				trend = currentUsage,
				location = tile.x .. ", " .. tile.y,
				city = cityName,
				terrain = MMTERRAIN[terrainId]
			})
		end
	end
	local messageText = "An improved tile becomes 'depleted' after being worked for " .. constant.mmTerrain.OTHER_TERRAIN_DEPLETION_TURNS .. " turns (" .. constant.mmTerrain.WOODED_TERRAIN_DEPLETION_TURNS .. " turns|     for mine/woodcut improvements on Dense Forest, Pine Forest, or Woodland).|However, for every turn that it is NOT worked, it recovers the equivalent of " .. constant.mmTerrain.TERRAIN_USAGE_RECOVERY_RATE .. " turns.||" .. uiutil.convertTableToMessageText(columnTable, dataTable, 4)

	uiutil.messageDialog("Terrain Usage", messageText)
end

local function processMapChanges () --> void
	log.trace()
	local startTimestamp = os.clock()
	local gameYear = civ.getGameYear()
	local terrainCount = { }
	for tile in tileutil.iterateTiles() do
		local terrainId = tile.terrainType & 0x0F
		if terrainId ~= MMTERRAIN.Sea then

			local tileId = tileutil.getTileId(tile)

			-- 1. Confirm proper storage structure
			if db.tileData[tileId] == nil then
				log.error("ERROR! db.tileData was nil for tileId " .. tileId .. " (" .. tile.x .. "," .. tile.y .. ")")
				db.tileData[tileId] = { }
			end

			-- 2. Document visibility (to human player)
			if tile.owner.isHuman == true then
				db.tileData[tileId].visible = true
			end

			-- 3. Remove city built on Monastery terrain
			if terrainId == MMTERRAIN.Monastery and tile.city ~= nil then
				-- It is not permitted for a human or AI tribe to found a city on a monastery tile!
				local tribe = tile.city.owner
				log.info("Detected " .. tribe.adjective .. " city built on Monastery terrain, which is not permitted")
				clearCityData(tile.city)
				cityutil.deleteCity(tile.city, false, nil)
				unitutil.createByType(MMUNIT.Peasant, tribe, tile)
				if tribe.isHuman == true then
					civ.ui.centerView(tile)
					uiutil.messageDialog("Head Abbot","You should be ashamed of yourself, Sire! Monastery land belongs to the church, and you are not permitted to found a city there! Consider yourself fortunate that we are allowing your peasants at " .. tile.x .. "," .. tile.y .. " to go free rather than turning them over to church authorities for prosecution!", 400)
				end
			end

			-- 4. Confirm city still exists on terrain converted due to city founding; if not, undo conversion and generate warning
			if db.tileData[tileId].cityTerrainConvertedFrom ~= nil then
				if tile.city ~= nil then
					log.info("Confirmed that a city exists at " .. tile.x .. "," .. tile.y .. " where terrain was converted")
				else
					log.warning("WARNING: Did not find expected city at ".. tile.x .. "," .. tile.y .. " - city creation apparently canceled")
					local formerTerrainId = db.tileData[tileId].cityTerrainConvertedFrom
					if terrainId ~= formerTerrainId then
						setTerrainType(tile, formerTerrainId, true)
						terrainId = formerTerrainId
						log.action("Converted " .. tile.x .. "," .. tile.y .. " from " .. MMTERRAIN[terrainId] .. " back to " .. MMTERRAIN[formerTerrainId])
					end
				end
				db.tileData[tileId].cityTerrainConvertedFrom = nil
			end

			-- 5. Remove unsupported tile improvements and generate warning
			-- One way this can occur is if wooded terrain has a mine and is "cheat-cleared" by the AI (without direct worker action)

			-- Only four terrains support irrigation, plus it is automatically added to Woodland if it has a river:
			if terrainId ~= MMTERRAIN.ArablePoor and terrainId ~= MMTERRAIN.Arable and terrainId ~= MMTERRAIN.ArableLush and terrainId ~= MMTERRAIN.TerracedHills and
			   not(terrainId == MMTERRAIN.Woodland and tileutil.hasRiver(tile)) then
				if tileutil.hasFarm(tile) then
					log.action("Unsupported tile improvement removed: enclosed fields on " .. MMTERRAIN[terrainId] .. " at " .. tile.x .. "," .. tile.y)
					tileutil.removeFarm(tile)
					-- Do not change db.tileData.currentImprovement or db.tileData.lastImprovementChangeYear
				end
				if tileutil.hasIrrigation(tile) then
					log.action("Unsupported tile improvement removed: irrigation on " .. MMTERRAIN[terrainId] .. " at " .. tile.x .. "," .. tile.y)
					tileutil.removeIrrigation(tile)
					-- Do not change db.tileData.currentImprovement or db.tileData.lastImprovementChangeYear
				end
			end
			-- Only seven terrains support mine/woodcut:
			if terrainId ~= MMTERRAIN.MountainPass and terrainId ~= MMTERRAIN.DenseForest and terrainId ~= MMTERRAIN.PineForest and
			   terrainId ~= MMTERRAIN.Heathland and terrainId ~= MMTERRAIN.Woodland and terrainId ~= MMTERRAIN.Hills and terrainId ~= MMTERRAIN.TerracedHills then
				if tileutil.hasMine(tile) then
					log.action("Unsupported tile improvement removed: mine/woodcut on " .. MMTERRAIN[terrainId] .. " at " .. tile.x .. "," .. tile.y)
					tileutil.removeMine(tile)
					-- Do not change db.tileData.currentImprovement or db.tileData.lastImprovementChangeYear
				end
			end

			-- 6. Convert road or castle improvement in Mountains to Mountain Pass terrain; set pending message for human player
			if terrainId == MMTERRAIN.Mountains then
				if tileutil.hasRoad(tile) == true then
					tileutil.removeRoad(tile)
					setTerrainType(tile, MMTERRAIN.MountainPass, true)
					terrainId = MMTERRAIN.MountainPass
					log.action("Converted road on Mountain terrain at " .. tile.x .. "," .. tile.y .. " to Mountain Pass terrain")
					if tile.defender ~= nil and tile.defender.isHuman then
						uiutil.messageDialog("Mountain Pass", "You have identified a route through impassable mountains|at " .. tile.x .. "," .. tile.y ..
							". The resulting mountain pass can now be traversed|by all unit types.", 150)
					end
				end
				if tileutil.hasFortress(tile) == true then
					tileutil.removeFortress(tile)
					setTerrainType(tile, MMTERRAIN.MountainPass, true)
					terrainId = MMTERRAIN.MountainPass
					log.action("Converted castle on Mountain terrain at " .. tile.x .. "," .. tile.y .. " to Mountain Pass terrain")
					if tile.defender ~= nil and tile.defender.isHuman then
						uiutil.messageDialog("Mountain Pass", "You have constructed a route through impassable mountains|at " .. tile.x .. "," .. tile.y ..
							". The resulting mountain pass can now be accessed|by all unit types.", 150)
					end
				end
			end		-- of terrainId == MMTERRAIN.Mountains

			-- 7. Detect new terrain type changes and update tileData
			-- Code pulled out into a separate function in order to be able to call it one tile at a time from other functions
			if terrainId ~= db.tileData[tileId].currentTerrainType then

				processTerrainTypeChange(tile, true)
				-- Update this variable since it's used in future sections of the current function:
				terrainId = db.tileData[tileId].currentTerrainType
			end		-- of 7. Detect new terrain type changes and update tileData, i.e., terrainId ~= db.tileData[tileId].currentTerrainType

			-- 8. Add irrigation to Woodland if it contains a river
			if terrainId == MMTERRAIN.Woodland and tileutil.hasRiver(tile) == true then
				if tileutil.hasCity(tile) == false and tileutil.hasMine(tile) == false and tileutil.hasIrrigation(tile) == false then
					tileutil.addIrrigation(tile)
					db.tileData[tileId].currentImprovement = "Irrigation"
					for tribe in tribeutil.iterateActiveTribes(false) do
						if tileutil.isWithinTribeCityRadius(tile, tribe) then
							updateMapView(tile, tribe)
						end
					end
				end
			end

			-- 9. Detect unknown terrain improvements and update tileData
			local currImp = nil
			if tileutil.hasIrrigation(tile) == true then currImp = "Irrigation"
			elseif tileutil.hasMine(tile) == true then currImp = "MineWoodcut"
			elseif tileutil.hasFarm(tile) == true then currImp = "EnclosedFields" end
			if currImp ~= db.tileData[tileId].currentImprovement then
				-- Terrain improvements on this tile do not match what has been documented
				if currImp == nil or (currImp == "Irrigation" and db.tileData[tileId].currentImprovement == "EnclosedFields") then
					-- Decrease of improvements is possible due to pillaging, update stored info
					log.update("Documented tile improvement change at " .. tile.x .. "," .. tile.y .. ": was " .. tostring(db.tileData[tileId].currentImprovement) .. ", now " .. tostring(currImp))
				else
					-- Increase in improvements can be due to a worker, or due to AI "cheats"
					local tribe, workerUnit, closestCityDistance, closestCities = getSourceForTerrainAction(tile)
					if workerUnit ~= nil then
						log.update("Documented tile improvement change at " .. tile.x .. "," .. tile.y .. ": was " .. tostring(db.tileData[tileId].currentImprovement) .. ", now " .. tostring(currImp))
					else
						log.update("Documented tile improvement change WITHOUT A WORKER PRESENT at " .. tile.x .. "," .. tile.y .. ": was " .. tostring(db.tileData[tileId].currentImprovement) .. ", now " .. tostring(currImp))
					end
				end
				db.tileData[tileId].currentImprovement = currImp
				db.tileData[tileId].lastImprovementChangeYear = gameYear
			end

			-- 10. Convert depleted terrain

			-- 10a. Determine the max usage level for this type of terrain
			local maxUsageLevel = constant.mmTerrain.OTHER_TERRAIN_DEPLETION_TURNS
			if terrainId == MMTERRAIN.DenseForest or terrainId == MMTERRAIN.PineForest or terrainId == MMTERRAIN.Woodland then
				maxUsageLevel = constant.mmTerrain.WOODED_TERRAIN_DEPLETION_TURNS
			end

			-- 10b. Confirm that the tile has enough usage to potentially deplete
			local tribe = nil
			if db.tileData[tileId].lastWorkedByTribeId ~= nil then
				tribe = civ.getTribe(db.tileData[tileId].lastWorkedByTribeId)
				if tribe.active == false or tribe.active == nil then
					tribe = nil
				end
			end
			if db.tileData[tileId].usageLevel ~= nil and tribe ~= nil and db.tileData[tileId].usageLevel >= adjustForDifficulty(maxUsageLevel, tribe, true) then

				-- 10c. Identify the depletion actions that are possible
				local canRemoveIrrigation = false
				local canRemoveMineWoodcut = false
				local canChangeTerrain = false

					if terrainId == MMTERRAIN.ArablePoor		then canRemoveIrrigation = true
				elseif terrainId == MMTERRAIN.Arable			then 														canChangeTerrain = true
--				elseif terrainId == MMTERRAIN.Pasture			then -- NO DEPLETION
				elseif terrainId == MMTERRAIN.ArableLush		then 														canChangeTerrain = true
				elseif terrainId == MMTERRAIN.MountainPass		then 							canRemoveMineWoodcut = true
--				elseif terrainId == MMTERRAIN.Mountains			then -- NO DEPLETION
				elseif terrainId == MMTERRAIN.DenseForest		then 														canChangeTerrain = true
				elseif terrainId == MMTERRAIN.PineForest		then 														canChangeTerrain = true
				elseif terrainId == MMTERRAIN.Heathland			then 							canRemoveMineWoodcut = true
--				elseif terrainId == MMTERRAIN.MarshFen			then -- NO DEPLETION
--				elseif terrainId == MMTERRAIN.Sea				then -- NO DEPLETION
				elseif terrainId == MMTERRAIN.Woodland			then 							canRemoveMineWoodcut = true
				elseif terrainId == MMTERRAIN.Hills				then 							canRemoveMineWoodcut = true
				elseif terrainId == MMTERRAIN.TerracedHills		then canRemoveIrrigation = true
--				elseif terrainId == MMTERRAIN.Monastery			then -- NO DEPLETION
--				elseif terrainId == MMTERRAIN.Urban				then -- NO DEPLETION
				end

				-- 10d. Block specific actions if not enough years have elapsed since the previous instance of that action type
				local lastImproved = 500
				if db.tileData[tileId].lastImprovementChangeYear ~= nil and db.tileData[tileId].lastImprovementChangeYear > lastImproved then
					lastImproved = db.tileData[tileId].lastImprovementChangeYear
				end
				if (lastImproved + constant.mmTerrain.TERRAIN_DEPLETION_MIN_YEARS) > gameYear then
					canRemoveIrrigation = false
					canRemoveMineWoodcut = false
				end
				local lastTypeChange = 500
				if db.tileData[tileId].lastTerrainTypeChangeYear ~= nil and db.tileData[tileId].lastTerrainTypeChangeYear > lastTypeChange then
					lastTypeChange = db.tileData[tileId].lastTerrainTypeChangeYear
				end
				if (lastTypeChange + constant.mmTerrain.TERRAIN_DEPLETION_MIN_YEARS) > gameYear then
					canChangeTerrain = false
				end

				-- 10e. Block specific actions if the tile does not have the relevant improvement feature
				local canRemoveEnclosedFields = false
				if canRemoveIrrigation == true then
					if tileutil.hasFarm(tile) == true then
						canRemoveEnclosedFields = true
						canRemoveIrrigation = false
					elseif tileutil.hasIrrigation(tile) == false then
						canRemoveIrrigation = false
					end
				end
				if canRemoveMineWoodcut == true and tileutil.hasMine(tile) == false then
					canRemoveMineWoodcut = false
				end

				-- 10f. Identify a new valid terrain type
				local depletedTerrainId = terrainId
				if canChangeTerrain == true then
						if terrainId == MMTERRAIN.Arable		then depletedTerrainId = MMTERRAIN.ArablePoor
					elseif terrainId == MMTERRAIN.ArableLush	then depletedTerrainId = MMTERRAIN.Arable
					elseif terrainId == MMTERRAIN.DenseForest	then depletedTerrainId = MMTERRAIN.Woodland
					elseif terrainId == MMTERRAIN.PineForest	then depletedTerrainId = MMTERRAIN.Woodland
					end
				end

				-- 10g. Depletion is not influenced by the presence of a worker unit on the tile

				if canRemoveEnclosedFields == true or canRemoveIrrigation == true or canRemoveMineWoodcut == true or canChangeTerrain == true then

					-- 10h. No probability test; terrain which is eligible to deplete will always do so

					-- 10i. Depleting will proceed
					local baseLocationDescriptor = ""
					if tileutil.hasCity(tile) == true then
						baseLocationDescriptor = " which is the site of"
					else
						baseLocationDescriptor = " near"
					end
					local consoleLocationDescriptor = baseLocationDescriptor .. " the " .. tribe.adjective .. " city of " .. db.tileData[tileId].lastWorkedByCityName
					local messageLocationDescriptor = baseLocationDescriptor .. " " .. db.tileData[tileId].lastWorkedByCityName
					log.action("Depletion occurs at " .. tile.x .. "," .. tile.y .. consoleLocationDescriptor)
					local messageHeader = "Terrain Depletion"
					local messageText = "Due to heavy usage over a long period of time, "

					-- Note a difference here, compared to very similar code in "12. Revert unworked terrain"
					-- In this instance, the various blocks are independent, using "if/then/end", so that multiple (all possible) will execute

					if canRemoveEnclosedFields == true then
						tileutil.removeFarm(tile)
						updateMapView(tile, tribe)
						db.tileData[tileId].currentImprovement = "Irrigation"
						db.tileData[tileId].lastImprovementChangeYear = gameYear
						messageText = messageText .. " the enclosed fields at " .. tile.x .. "," .. tile.y .. messageLocationDescriptor .. " have degraded and the land is now merely irrigated."
					end
					if canRemoveIrrigation == true then
						tileutil.removeIrrigation(tile)
						updateMapView(tile, tribe)
						db.tileData[tileId].currentImprovement = nil
						db.tileData[tileId].lastImprovementChangeYear = gameYear
						messageText = messageText .. " the irrigation at " .. tile.x .. "," .. tile.y .. messageLocationDescriptor .. " has eroded away and will need to be rebuilt."
					end
					if canRemoveMineWoodcut == true then
						tileutil.removeMine(tile)
						updateMapView(tile, tribe)
						db.tileData[tileId].currentImprovement = nil
						db.tileData[tileId].lastImprovementChangeYear = gameYear
						local operationName = "mine"
						local operationEffect = " has been exhausted and a new mine will need to be dug at this location."
						if terrainId == MMTERRAIN.Woodland then
							operationName = "woodcutting operation"
							operationEffect = " has cut down the majority of the usable timber and is no longer viable."
						end
						messageText = messageText .. " the " .. operationName .. " at " .. tile.x .. "," .. tile.y .. messageLocationDescriptor .. operationEffect
					end
					if canChangeTerrain == true then
						local operationDesc = ""
						if canRemoveEnclosedFields == true or canRemoveIrrigation == true or canRemoveMineWoodcut == true then
							operationDesc = " In addition, this terrain has become " .. MMTERRAIN[depletedTerrainId] .. " instead of " .. MMTERRAIN[terrainId] .. "."
						elseif depletedTerrainId == MMTERRAIN.Woodland then
							operationDesc = " many of the large trees at " .. tile.x .. "," .. tile.y .. messageLocationDescriptor .. " have been cut down, and this site must now be considered " .. MMTERRAIN[depletedTerrainId] .. " instead of " .. MMTERRAIN[terrainId] .. "."
						else
							operationDesc = " " .. tile.x .. "," .. tile.y .. messageLocationDescriptor .. " has become " .. MMTERRAIN[depletedTerrainId] .. " instead of " .. MMTERRAIN[terrainId] .. "."
						end
						messageText = messageText .. operationDesc
						setTerrainType(tile, depletedTerrainId)
						terrainId = depletedTerrainId
					end

					db.tileData[tileId].usageLevel = 0
					log.update("Reset usage level of " .. tile.x .. "," .. tile.y .. " to 0")

					if (tribe ~= nil and tribe.isHuman == true) or (tile.defender ~= nil and tile.defender.isHuman == true) then
						-- Since land depletion isn't based on the action or presence of a worker, the message will be shown immediately and not deferred to your turn
						civ.ui.centerView(tile)
						uiutil.messageDialog(messageHeader, messageText, 400)
					end

				end		-- one of the changes is possible
			end		-- tile has enough usage to potentially deplete

			-- 11. Decrement tile usage data
			if db.tileData[tileId].lastWorkedYear ~= nil and db.tileData[tileId].lastWorkedYear < civ.getGameYear() and
			   db.tileData[tileId].usageLevel ~= nil and db.tileData[tileId].usageLevel > 0 then
				local previousUsageLevel = db.tileData[tileId].usageLevel
				local newUsageLevel = previousUsageLevel - constant.mmTerrain.TERRAIN_USAGE_RECOVERY_RATE
				if newUsageLevel < 0 then
					newUsageLevel = 0
				end
				db.tileData[tileId].usageLevel = newUsageLevel
				db.tileData[tileId].lastDecrementedUsageLevelYear = civ.getGameYear()
				local messageText = "Reduced usage level of " .. tile.x .. "," .. tile.y
				if db.tileData[tileId].lastWorkedByCityName ~= nil then
					messageText = messageText .. " near " .. db.tileData[tileId].lastWorkedByCityName
				end
				messageText = messageText .. " from " .. previousUsageLevel .. " to " .. newUsageLevel
				log.update(messageText)
			end

			-- 12. Revert unworked terrain

			-- 12a. No adjustments made to reverting limits based on terrain type

			-- 12b. Confirm that the tile has been unworked for enough years to potentially revert
			--		The number of years elapsed is measured since the *later* of the year the tile was last worked, or the year its usage level was decremented to zero
			--		Because the tile is NOT currently being worked, there is no valid tribe to use in a call to adjustForDifficulty(), so that function is not relevant
			local lastWorked = constant.mmTerrain.TERRAIN_REVERT_DEFAULT_LAST_ACTIVITY_YEAR
			if db.tileData[tileId].lastWorkedYear ~= nil and db.tileData[tileId].lastWorkedYear > lastWorked then
				lastWorked = db.tileData[tileId].lastWorkedYear
			end
			local lastDecrement = constant.mmTerrain.TERRAIN_REVERT_DEFAULT_LAST_ACTIVITY_YEAR
			if db.tileData[tileId].lastDecrementedUsageLevelYear ~= nil and db.tileData[tileId].lastDecrementedUsageLevelYear > lastDecrement then
				lastDecrement = db.tileData[tileId].lastDecrementedUsageLevelYear
			end
			if (lastWorked + constant.mmTerrain.TERRAIN_REVERT_MIN_YEARS) < gameYear and (lastDecrement + constant.mmTerrain.TERRAIN_REVERT_MIN_YEARS) < gameYear then

				-- 12c. Identify the reverting actions that are possible
				local canRemoveIrrigation = false
				local canRemoveMineWoodcut = false
				local canChangeTerrain = false

					if terrainId == MMTERRAIN.ArablePoor		then canRemoveIrrigation = true								canChangeTerrain = true
				elseif terrainId == MMTERRAIN.Arable			then canRemoveIrrigation = true								canChangeTerrain = true
				elseif terrainId == MMTERRAIN.Pasture			then 														canChangeTerrain = true
				elseif terrainId == MMTERRAIN.ArableLush		then canRemoveIrrigation = true								canChangeTerrain = true
				elseif terrainId == MMTERRAIN.MountainPass		then 							canRemoveMineWoodcut = true
--				elseif terrainId == MMTERRAIN.Mountains			then -- CANNOT REVERT
				elseif terrainId == MMTERRAIN.DenseForest		then 							canRemoveMineWoodcut = true
				elseif terrainId == MMTERRAIN.PineForest		then 							canRemoveMineWoodcut = true
				elseif terrainId == MMTERRAIN.Heathland			then 							canRemoveMineWoodcut = true
--				elseif terrainId == MMTERRAIN.MarshFen			then -- CANNOT REVERT
--				elseif terrainId == MMTERRAIN.Sea				then -- CANNOT REVERT
				elseif terrainId == MMTERRAIN.Woodland			then 														canChangeTerrain = true
				elseif terrainId == MMTERRAIN.Hills				then 							canRemoveMineWoodcut = true
				elseif terrainId == MMTERRAIN.TerracedHills		then canRemoveIrrigation = true								canChangeTerrain = true
				elseif terrainId == MMTERRAIN.Monastery			then 														canChangeTerrain = true
--				elseif terrainId == MMTERRAIN.Urban				then -- CANNOT REVERT
				end

				-- 12d. Block specific actions if not enough years have elapsed since the previous instance of that action type
				local lastImproved = constant.mmTerrain.TERRAIN_REVERT_DEFAULT_LAST_ACTIVITY_YEAR
				if db.tileData[tileId].lastImprovementChangeYear ~= nil and db.tileData[tileId].lastImprovementChangeYear > lastImproved then
					lastImproved = db.tileData[tileId].lastImprovementChangeYear
				end
				if (lastImproved + constant.mmTerrain.TERRAIN_REVERT_MIN_YEARS) >= gameYear then
					canRemoveIrrigation = false
					canRemoveMineWoodcut = false

					canChangeTerrain = false
				end
				local lastTypeChange = constant.mmTerrain.TERRAIN_REVERT_DEFAULT_LAST_ACTIVITY_YEAR
				if db.tileData[tileId].lastTerrainTypeChangeYear ~= nil and db.tileData[tileId].lastTerrainTypeChangeYear > lastTypeChange then
					lastTypeChange = db.tileData[tileId].lastTerrainTypeChangeYear
				end
				if (lastTypeChange + constant.mmTerrain.TERRAIN_REVERT_MIN_YEARS) >= gameYear then

					canChangeTerrain = false
				end

				-- 12e. Block specific actions if the tile does not have the relevant improvement feature
				local canRemoveEnclosedFields = false
				if canRemoveIrrigation == true then
					if tileutil.hasFarm(tile) == true then
						canRemoveEnclosedFields = true
						canRemoveIrrigation = false
					elseif tileutil.hasIrrigation(tile) == false then
						canRemoveIrrigation = false
					end
				end
				if canRemoveMineWoodcut == true and tileutil.hasMine(tile) == false then
					canRemoveMineWoodcut = false
				end

				-- 12f. Identify a new valid terrain type
				local revertedTerrainId = terrainId
				if canChangeTerrain == true then
					if db.tileData[tileId].nativeTerrainType == nil then
						log.error("ERROR! Could not find native terrain for " .. tile.x .. "," .. tile.y .. " (tileId = " .. tileId .. ")")
						canChangeTerrain = false
					elseif db.tileData[tileId].nativeTerrainType == terrainId then
						canChangeTerrain = false
					else
						revertedTerrainId = db.tileData[tileId].nativeTerrainType
						-- Insert additional step;
						if (terrainId == MMTERRAIN.ArablePoor or terrainId == MMTERRAIN.Arable or terrainId == MMTERRAIN.ArableLush or terrainId == MMTERRAIN.Monastery) and
						   (revertedTerrainId == MMTERRAIN.DenseForest or revertedTerrainId == MMTERRAIN.PineForest) then
							revertedTerrainId = MMTERRAIN.Woodland
						end
					end
				end

				if canRemoveEnclosedFields == true or canRemoveIrrigation == true or canRemoveMineWoodcut == true or canChangeTerrain == true then
				-- 12g. If the tile currently contains a peasant-type unit, we will assume that they are actively improving it
				--		or have just completed that action and the city will begin working the tile soon.
				--		The tile will have a temporary reprieve from reverting.
				--		Putting this code here because it's relatively expensive, and we only want to run it if all other tests have passed
				--		This is a portion of the code that exists in getSourceForTerrainAction()
					local workerUnit = nil
					for unit in tile.units do
						if unit.type.role == 5 then
							workerUnit = unit
							break
						end
					end
					if workerUnit ~= nil then
						canRemoveEnclosedFields = false
						canRemoveIrrigation = false
						canRemoveMineWoodcut = false
						canChangeTerrain = false
					end
				end

				if canRemoveEnclosedFields == true or canRemoveIrrigation == true or canRemoveMineWoodcut == true or canChangeTerrain == true then

					-- 12h. Probability test
					local turnsEligibleToRevert = (gameYear - (lastWorked + constant.mmTerrain.TERRAIN_REVERT_MIN_YEARS)) / db.gameData.YEARS_PER_TURN
					local percentChanceToRevert = math.min(turnsEligibleToRevert * constant.mmTerrain.TERRAIN_REVERT_CHANCE_INCREASE_PER_TURN, 100)
					-- Tiles within the city radius of the *human player only* will revert right away, to more dramatically illustrate this feature without
					-- radically adjusting the landscape of the entire map and imposing a burden on the AI that they won't be able to proactively protect against
					if tileutil.isWithinTribeCityRadius(tile, civ.getPlayerTribe()) == true then
						percentChanceToRevert = 100
					end
					local randomNumber = math.random(100)
					log.info(tile.x .. "," .. tile.y .. ": percentChanceToRevert = " .. percentChanceToRevert .. ", randomNumber = " .. randomNumber)
					if randomNumber <= percentChanceToRevert then

						-- 12i. Reverting will proceed
						local tribe = nil
						if db.tileData[tileId].lastWorkedByTribeId ~= nil then
							tribe = civ.getTribe(db.tileData[tileId].lastWorkedByTribeId)
							if tribe.active == false or tribe.active == nil then
								tribe = nil
							end
						end
						local consoleLocationDescriptor = ""
						local messageLocationDescriptor = ""
						if db.tileData[tileId].lastWorkedByCityName ~= nil and db.tileData[tileId].lastWorkedByCityName ~= "" then
							consoleLocationDescriptor = " near the "
							if tribe ~= nil then
								consoleLocationDescriptor = consoleLocationDescriptor .. tribe.adjective .. " "
							end
							consoleLocationDescriptor = consoleLocationDescriptor .. "city of " .. db.tileData[tileId].lastWorkedByCityName
							messageLocationDescriptor = " near " .. db.tileData[tileId].lastWorkedByCityName
						else
							local cityNameForPopupMessage = nil
							for city in civ.iterateCities() do
								if city.owner.isHuman == true then
									for _, radiusTile in ipairs(tileutil.getCityRadiusTiles(city, true)) do
										if civ.isTile(radiusTile) and tile == radiusTile then
											cityNameForPopupMessage = city.name
											break
										end
									end
								end
								if cityNameForPopupMessage ~= nil then
									break
								end
							end
							if cityNameForPopupMessage ~= nil then
								messageLocationDescriptor = " near " .. cityNameForPopupMessage
							end
						end
						log.action("Terrain reverts at " .. tile.x .. "," .. tile.y .. consoleLocationDescriptor)
						local messageHeader = ""
						local messageText = ""

						local yearLastWorkedDescriptor = ""
						if db.tileData[tileId].lastWorkedYear ~= nil then
							yearLastWorkedDescriptor = " since A.D. " .. db.tileData[tileId].lastWorkedYear
						end

						-- Note a difference here, compared to very similar code in "11. Convert depleted terrain"
						-- In this instance, the various blocks are "elseif" so that only one can ever execute
						-- Terrains with enclosed fields or irrigation need to revert that away first, and then restart the counter
						-- Only after another full cycle can the type change
						if canRemoveEnclosedFields == true then
							tileutil.removeFarm(tile)
							if tribe ~= nil then
								updateMapView(tile, tribe)
							end
							db.tileData[tileId].currentImprovement = "Irrigation"
							db.tileData[tileId].lastImprovementChangeYear = gameYear
							messageHeader = "Abandoned Farm"
							messageText = "The terrain at " .. tile.x .. "," .. tile.y .. messageLocationDescriptor .. " has not been worked" .. yearLastWorkedDescriptor .. ", and the enclosed fields at this location have been lost so that the land is now merely irrigated."
						elseif canRemoveIrrigation == true then
							tileutil.removeIrrigation(tile)
							if tribe ~= nil then
								updateMapView(tile, tribe)
							end
							db.tileData[tileId].currentImprovement = nil
							db.tileData[tileId].lastImprovementChangeYear = gameYear
							messageHeader = "Irrigation Lost"
							messageText = "The terrain at " .. tile.x .. "," .. tile.y .. messageLocationDescriptor .. " has not been worked" .. yearLastWorkedDescriptor .. ", and the irrigation at this location has now been lost."
						elseif canRemoveMineWoodcut == true then
							tileutil.removeMine(tile)
							if tribe ~= nil then
								updateMapView(tile, tribe)
							end
							db.tileData[tileId].currentImprovement = nil
							db.tileData[tileId].lastImprovementChangeYear = gameYear
							messageHeader = "Mining/Woodcutting Lost"
							messageText = "The terrain at " .. tile.x .. "," .. tile.y .. messageLocationDescriptor .. " has not been worked" .. yearLastWorkedDescriptor .. ", and the mine or woodcutting operation at this location has now been lost."
						elseif canChangeTerrain == true then
							-- Woodland is auto-irrigated if it's on a river, but it isn't removed in a separate stage; it's just lost when the terrain changes
							-- The irrigation needs to be removed manually, though, or it will cause an error when this function detects an irrigated Dense/Pine Forest
							if terrainId == MMTERRAIN.Woodland and tileutil.hasIrrigation(tile) == true then
								tileutil.removeIrrigation(tile)
								if tribe ~= nil then
									updateMapView(tile, tribe)
								end
								db.tileData[tileId].currentImprovement = nil
								-- Intentionally not updating db.tileData[tileId].lastImprovementChangeYear
							end
							setTerrainType(tile, revertedTerrainId)
							messageHeader = "Native Vegetation"
							messageText = "The terrain at " .. tile.x .. "," .. tile.y .. messageLocationDescriptor .. " has not been worked" .. yearLastWorkedDescriptor .. ", and has now reverted from " .. MMTERRAIN[terrainId] .. " to " .. MMTERRAIN[revertedTerrainId] .. "."
						end
						if (tribe ~= nil and tribe.isHuman == true) or (tile.defender ~= nil and tile.defender.isHuman == true) then
							civ.ui.centerView(tile)
							uiutil.messageDialog(messageHeader, messageText, 400)
						end
					end		-- randomNumber <= percentChanceToRevert
				end		-- one of the changes is possible
			end		-- tile has been unworked long enough to potentially revert

		end		-- of terrainId ~= MMTERRAIN.Sea

		terrainCount[terrainId] = (terrainCount[terrainId] or 0) + 1

		if tileutil.hasRiver(tile) then
			terrainCount[99] = (terrainCount[99] or 0) + 1
		end

	end		-- of for tile in tileutil.iterateTiles()

	-- 13. Forest fires

	if gameYear > (constant.mmTerrain.TERRAIN_REVERT_DEFAULT_LAST_ACTIVITY_YEAR + constant.mmTerrain.TERRAIN_REVERT_MIN_YEARS + 50) then
		local forestTilesFound = terrainCount[MMTERRAIN.PineForest] + terrainCount[MMTERRAIN.DenseForest]
		local forestFiresNeeded = round(forestTilesFound * (constant.mmTerrain.FOREST_FIRE_BURNS_FOREST_PCT / 100))
		if forestFiresNeeded > 0 then
			log.action("Found " .. forestTilesFound .. " forest tiles, fires will burn " .. forestFiresNeeded .. " of them")
		end
		local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()
		while forestFiresNeeded > 0 do
			local randomX = math.random(mapWidth) - 1
			local randomY = math.random(mapHeight) - 1
			local tile = civ.getTile(randomX, randomY, 0)
			if civ.isTile(tile) then
				local terrainId = tileutil.getTerrainId(tile)
				if terrainId == MMTERRAIN.PineForest or terrainId == MMTERRAIN.DenseForest then
					local tribe = tile.defender
					local closestCities = nil
					if tribe == nil then
						local playerTribe = civ.getPlayerTribe()
						if tileutil.isWithinTribeCityRadius(tile, playerTribe) == true then
							tribe = playerTribe
							closestCities = tileutil.getClosestCities(tile, tribe)
						end
					end
					local messageText = "A recent fire has burned much of the old forest at " .. tile.x .. "," .. tile.y
					if closestCities ~= nil then
						if #closestCities == 1 then
							messageText = messageText .. " near our city of " .. closestCities[1].name .. ","
						else
							messageText = messageText .. " between our cities of " .. closestCities[1].name .. " and " .. closestCities[2].name .. ","
						end
					end
					messageText = messageText .. " and it is now a Woodland consisting of young trees."
					if tile.defender ~= nil then
						messageText = messageText .. " The cause of the fire is unclear, however a careless campfire may be to blame!"
					else
						messageText = messageText .. " The fire was most likely caused by lightning, but we can't know for certain."
					end
					setTerrainType(tile, MMTERRAIN.Woodland)
					if tileutil.hasMine(tile) then
						tileutil.removeMine(tile)
						local tileId = tileutil.getTileId(tile)
						db.tileData[tileId].currentImprovement = nil
						db.tileData[tileId].lastImprovementChangeYear = gameYear
						messageText = messageText .. " The woodcutting operation on this tile is no longer functional due to the fire and has been abandoned."
					end
					if tileutil.hasRailroad(tile) then
						tileutil.removeRailroad(tile)
						messageText = messageText .. " Furthermore, the royal highway at this location has been damaged and reduced to a mere road."
					elseif tileutil.hasRoad(tile) then
						tileutil.removeRoad(tile)
						messageText = messageText .. " Travelers report that the road at this location is now impassable and will need to be rebuilt."
					end
					if tribe ~= nil then
						updateMapView(tile, tribe)
						if tribe.isHuman == true then
							civ.ui.centerView(tile)
							uiutil.messageDialog("Forest Fire!", messageText, 480)
						end
					end
					forestFiresNeeded = forestFiresNeeded - 1
				end
			end
		end
	end

	log.info("Current terrain counts at beginning of " .. gameYear .. ":")
	local landTiles = 0
	for terrainId = 0, 15 do
		log.info("  " .. MMTERRAIN[terrainId] .. " = " .. (terrainCount[terrainId] or 0))
		if terrainId ~= MMTERRAIN.Sea then
			landTiles = landTiles + (terrainCount[terrainId] or 0)
		end
	end
	log.info("  -- LAND TILES = " .. landTiles)
	log.info("    River Tiles = " .. (terrainCount[99] or 0))
	log.info("processMapChanges() completed in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")

end		-- of function processMapChanges ()

local function processPeasantActivity (unit)
	log.trace()
	if unit.type.role == 5 and unitutil.getMovesRemaining(unit) > 0 then
		processTerrainTypeChange(unit.location, false)
	end
end

local function processTerrainTypeChanges (tribe)
	log.trace()
	for unit in civ.iterateUnits() do
		if unit.owner == tribe and unit.type.role == 5 then
			processTerrainTypeChange(unit.location, true)
		end
	end
end

local function provideMineWoodcutForAI (city, unit)
	log.trace()
	if city.owner.isHuman == false and unit.type.role == 5 then
		local candidateTiles = { }
		local cityInnerRadiusTiles = tileutil.getAdjacentTiles(city.location, false)
		for key, tile in ipairs(cityInnerRadiusTiles) do
			if civ.isTile(tile) then
				local blockedByUnit = false
				for unit in tile.units do
					if unit.owner ~= city.owner or unit.type.role == 5 then
						blockedByUnit = true
						break
					end
				end
				if tileutil.hasMine(tile) or blockedByUnit == true then
					cityInnerRadiusTiles[key] = false
				end
			end
		end
		local cityOuterRadiusTiles = tileutil.getCityOuterRadiusTiles(city.location)
		for key, tile in ipairs(cityOuterRadiusTiles) do
			if civ.isTile(tile) then
				local blockedByUnit = false
				for unit in tile.units do
					if unit.owner ~= city.owner or unit.type.role == 5 then
						blockedByUnit = true
						break
					end
				end
				if tileutil.hasMine(tile) or blockedByUnit == true then
					cityOuterRadiusTiles[key] = false
				end
			end
		end
		for i = 1, 14 do
			if #candidateTiles == 0 then
				if i == 1 then
					for _, tile in ipairs(cityInnerRadiusTiles) do
						if civ.isTile(tile) and ((tile.terrainType & 0x0F) == MMTERRAIN.DenseForest or (tile.terrainType & 0x0F) == MMTERRAIN.PineForest) and tileutil.hasRiver(tile) then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 2 then
					for _, tile in ipairs(cityOuterRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Hills and tileutil.hasRiver(tile) then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 3 then
					for _, tile in ipairs(cityInnerRadiusTiles) do
						if civ.isTile(tile) and ((tile.terrainType & 0x0F) == MMTERRAIN.DenseForest or (tile.terrainType & 0x0F) == MMTERRAIN.PineForest) then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 4 then
					for _, tile in ipairs(cityOuterRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Hills then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 5 then
					for _, tile in ipairs(cityOuterRadiusTiles) do
						if civ.isTile(tile) and ((tile.terrainType & 0x0F) == MMTERRAIN.DenseForest or (tile.terrainType & 0x0F) == MMTERRAIN.PineForest) and tileutil.hasRiver(tile) then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 6 then
					for _, tile in ipairs(cityInnerRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Hills and tileutil.hasRiver(tile) then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 7 then
					for _, tile in ipairs(cityOuterRadiusTiles) do
						if civ.isTile(tile) and ((tile.terrainType & 0x0F) == MMTERRAIN.DenseForest or (tile.terrainType & 0x0F) == MMTERRAIN.PineForest) then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 8 then
					for _, tile in ipairs(cityInnerRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Hills then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 9 then
					for _, tile in ipairs(cityInnerRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Woodland and tileutil.hasRiver(tile) == false then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 10 then
					for _, tile in ipairs(cityOuterRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Woodland and tileutil.hasRiver(tile) == false then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 11 then
					for _, tile in ipairs(cityOuterRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Heathland and tileutil.hasRiver(tile) then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 12 then
					for _, tile in ipairs(cityInnerRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Heathland and tileutil.hasRiver(tile) then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 13 then
					for _, tile in ipairs(cityOuterRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Heathland then
							table.insert(candidateTiles, tile)
						end
					end
				elseif i == 14 then
					for _, tile in ipairs(cityInnerRadiusTiles) do
						if civ.isTile(tile) and (tile.terrainType & 0x0F) == MMTERRAIN.Heathland then
							table.insert(candidateTiles, tile)
						end
					end
				end
			end
		end
		if #candidateTiles > 0 then
			local randomKey = math.random(#candidateTiles)
			local tileToImprove = candidateTiles[randomKey]
			tileutil.addMine(tileToImprove)
			updateMapView(tileToImprove, city.owner)
		else
			log.info("Found 0 candidate tiles near " .. city.name .. " to add mine/woodcut")
		end
	end
end

local function tileImprovementsDestroyedByBattle (winningUnit, losingUnit, attackerTile, defenderTile) --> void

	log.trace()
	if isProjectileUnitType(winningUnit.type) or isProjectileUnitType(losingUnit.type) then
		log.info("No tile improvements destroyed since battle involved projectile unit")
	elseif hasCastle(defenderTile) and (unitutil.wasAttacker(losingUnit) or unitutil.tileContainsOtherUnit(defenderTile, losingUnit)) then
		log.info("No tile improvements destroyed since battle tile is protected by an unconquered castle")
	elseif tileutil.hasCity(defenderTile) and hasCastle(attackerTile) then
		-- There is a castle directly adjacent to a city, but the castle is occupied by enemy forces and they attacked the city from there
		-- In this case, we will not test for the destruction of improvements on the attacker's tile as we normally would
		log.info("No tile improvements destroyed since battle was an attack from a castle tile to a city tile")
	else
		local actionTile = defenderTile
		if tileutil.hasCity(defenderTile) and attackerTile ~= nil then
			actionTile = attackerTile
		end
		local terrainId = tileutil.getTerrainId(actionTile)
		local tileId = tileutil.getTileId(actionTile)
		local destroyedSomething = false

		if tileutil.hasFarm(actionTile) then
			tileutil.removeFarm(actionTile)
			log.action("Destroyed farm due to battle at " .. actionTile.x .. "," .. actionTile.y)
			destroyedSomething = true
			db.tileData[tileId].currentImprovement = "Irrigation"
			db.tileData[tileId].yearLastImproved = civ.getGameYear()
		end
		-- A battle will destroy both enclosed fields (farm) and irrigation in one fell swoop
		-- Irrigation on Woodland is ignored, this is a special case
		if tileutil.hasIrrigation(actionTile) and terrainId ~= MMTERRAIN.Woodland then
			tileutil.removeIrrigation(actionTile)
			log.action("Destroyed irrigation due to battle at " .. actionTile.x .. "," .. actionTile.y)
			destroyedSomething = true
			db.tileData[tileId].currentImprovement = nil
			db.tileData[tileId].yearLastImproved = nil
		end

		-- A battle will not destroy mine/woodcut

		if tileutil.hasRailroad(actionTile) then
			tileutil.removeRailroad(actionTile)
			log.action("Destroyed royal highway due to battle at " .. actionTile.x .. "," .. actionTile.y)
			destroyedSomething = true
		end
		-- A battle might destroy both royal highway (railroad) and road in one fell swoop
		if tileutil.hasRoad(actionTile) then
			local roadDestructionChance = 0
			if terrainId == MMTERRAIN.ArablePoor or terrainId == MMTERRAIN.Arable or terrainId == MMTERRAIN.ArableLush or terrainId == MMTERRAIN.Pasture then
				roadDestructionChance = constant.mmTerrain.BATTLE_DESTROYS_ROAD_PCT
			end
			if tileutil.hasRiver(actionTile) and actionTile == defenderTile then
				roadDestructionChance = 100
			end
			local randomNumber = math.random(100)
			log.info("Road destruction chance = " .. roadDestructionChance .. ", randomNumber = " .. randomNumber)
			if randomNumber <= roadDestructionChance then
				tileutil.removeRoad(actionTile)
				log.action("Destroyed road due to battle at " .. actionTile.x .. "," .. actionTile.y)
				destroyedSomething = true
			end
		end

		-- Here, actionTile must be defender tile; it can only flip to attacker tile if the defender tile has a city,
		--		and we already have a special-case check above for when that happens and attacker tile has a castle.
		-- Note also that tileutil.hasFortress() is correct, rather than hasCastle() -- this code is intended to apply
		--		to the tile improvement and isn't relevant for castle units.
		if tileutil.hasFortress(actionTile) and losingUnit.location == actionTile and unitutil.wasAttacker(losingUnit) == false and unitutil.tileContainsOtherUnit(actionTile, losingUnit) == false then
			local randomNumber = math.random(100)
			log.info("Castle destruction chance = " .. constant.mmTerrain.CONQUEST_DESTROYS_CASTLE_PCT .. ", randomNumber = " .. randomNumber)
			if randomNumber <= constant.mmTerrain.CONQUEST_DESTROYS_CASTLE_PCT then
				tileutil.removeFortress(actionTile)
				log.action("Destroyed castle due to battle at " .. actionTile.x .. "," .. actionTile.y)
				if winningUnit.owner.isHuman == true or losingUnit.owner.isHuman == true then
					uiutil.messageDialog("Castle Destroyed", "The castle at " .. actionTile.x .. "," .. actionTile.y .. " has been destroyed along with its final defender.")
				end
				destroyedSomething = true
			end
		end

		if destroyedSomething == true then
			updateMapView(actionTile, winningUnit.owner)
			updateMapView(actionTile, losingUnit.owner)
		else
			log.info("No tile improvements exist, or ones that do exist were not destroyed")
		end
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 20

return {
	confirmLoad = confirmLoad,

	applyClimateChangeToMap = applyClimateChangeToMap,
	convertTerrainForLargeCities = convertTerrainForLargeCities,
	convertTerrainForNewCity = convertTerrainForNewCity,
	documentVisibleTiles = documentVisibleTiles,
	getCostToMove = getCostToMove,
	getTerrainData = getTerrainData,
	getFormattedTerrainData = getFormattedTerrainData,
	incrementTileUsageData = incrementTileUsageData,
	initializeNewMap = initializeNewMap,
	listCurrentLandUsage = listCurrentLandUsage,
	processMapChanges = processMapChanges,
	processPeasantActivity = processPeasantActivity,
	processTerrainTypeChanges = processTerrainTypeChanges,
	provideMineWoodcutForAI = provideMineWoodcutForAI,
	tileImprovementsDestroyedByBattle = tileImprovementsDestroyedByBattle,
}
