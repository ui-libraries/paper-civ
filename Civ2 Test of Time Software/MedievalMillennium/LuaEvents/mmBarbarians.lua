-- mmBarbarians.lua
-- by Knighttime

log.trace()

constant.mmBarbarians = { }
constant.mmBarbarians.WORLD_UNIT_PCT_MAX = 50								-- Maximum percent of all military units in the world that can be barbarian (no more will be created if the current
																			--		number is equal to or greater than this)
constant.mmBarbarians.UNITS_PER_BAND_MIN = 2								-- Minimum number of barbarian units within a band (i.e., spawned on a single tile)
constant.mmBarbarians.UNITS_PER_BAND_MAX = 12								-- Maximum number of barbarian units within a single band (i.e., spawned on a single tile)
																			-- 		Multiple bands may be spawned on a single turn, though, on different tiles
constant.mmBarbarians.MAX_UNITS_PER_BAND_FACTOR = 1.205						-- Used in calculating the maximum number of units that can be spawned in a given band, in conjunction with the
																			--		calculated percent chance of that band appearing. A higher number causes larger bands.
constant.mmBarbarians.DISTANCE_FROM_CASTLE_MIN = 1							-- Barbarian units will not spawn within this many tiles of a castle defended by a human or AI unit.
																			--		"1" is equivalent to "will not spawn in a tile adjacent to a defended castle".
constant.mmBarbarians.DISTANCE_FROM_CITY_MIN = 3							-- Barbarian units will not spawn within this many tiles of a non-barbarian city
constant.mmBarbarians.LOCATIONS_TO_CHECK_MAX = 500							-- Maximum number of random tiles the game will analyze when attempting to find a valid tile on which to place new barbarians
constant.mmBarbarians.TERRAIN_BODY_SIZE_MIN = 21							-- Minimum terrain body size on which barbs can be created (sea tiles for naval units, land tiles for land units)
																			--		There are 21 tiles in a city radius and this is set to match that (also matches
																			--		constant.events.COASTAL_CITY_WATER_BODY_MIN)
constant.mmBarbarians.CITY_DEFENDERS_MIN = 3								-- Minimum number of units that will be kept within every barb city, if possible, to serve as defenders
constant.mmBarbarians.VALID_ROUTE_LENGTH_MAX = 20							-- Maximum number of tiles between the barbarian and a human/AI unit or city
constant.mmBarbarians.NO_VALID_ROUTE_DISBAND_PCT = 25						-- Percent chance, per turn, that a barbarian unit will disband if there is no target within the valid route length
constant.mmBarbarians.REWARD_KILL_WARLORD = {20, 30, 50, 65}				-- These amounts are about one-third of what is awarded in the base game, for each of the four valid barb activity levels
																			--		These values will also be adjusted for difficulty level within the code, at the time they are awarded to AI nations
constant.mmBarbarians.REWARD_KILL_LAST_UNIT =								-- These amounts are awarded to the human player only, when the last barbarian unit on a tile is killed, for each
	{ [0] = 0, [1] = 2, [2] = 4, [3] = 6, [4] = 8, [5] = 10, [6] = 12 }		--		of the seven difficulty levels. These are *not* adjusted for difficulty level again within the code; the values
																			--		prescribed here actually vary in reverse (normally adjustForDifficulty() would return a smaller reward
																			--		on a higher difficulty level). Instead, these values are based upon the fact that barbarian units receive an
																			--		attack bonus on higher difficulty levels, so defeating them is more challenging. Because this does not apply to
																			--		AI nations, and in fact the AI receives a *defense* bonus against barbarians, they do not receive a reward at all.
																			--		Also note that unlike reward for killing a Warlord, these values do not vary by barb activity level.
constant.mmBarbarians.TYPE_PATTERN = "PSPPSSPPPSSSPPPPSSSSPPPPPSSSSS"		-- P is primary, S is secondary, in order of creation within a band. If no secondary is defined, all will be primary.
constant.mmBarbarians.WEIGHTED_LOCATION_FACTOR = 1.667						-- This controls the distribution for weighted frequencies. 1.0 is a normal distribution, and
																			-- 		higher numbers will cause the random location to trend more strongly in the requested direction.
constant.mmBarbarians.CREATION_IMPROVES_TERRAIN_PCT = 75					-- Percent chance that when a new band of barbarians is created, the tile on which they are created will be 'improved'
																			--		to a better type (forest to woodland, woodland to arable, etc.)
																			--		Percent applies to Restless Tribes; is *increased* for Roving Bands (since bands will be created less often)
																			--		and *decreased* for Raging Hordes and (further) for Barbarian Wrath.
constant.mmBarbarians.CREATION_IMPROVES_TERRAIN_BEGIN_YEAR = 800			-- First game year on which tiles can be 'improved' when a band of barbarians is created there
																			--		Equal to constant.mmTerrain.TERRAIN_REVERT_DEFAULT_LAST_ACTIVITY_YEAR (700) +
																			--				 constant.mmTerrain.TERRAIN_REVERT_MIN_YEARS (100)
constant.mmBarbarians.CITY_CREATION_PER_INVADER_MAX = 10					-- Maximum number of cities that can be founded by each invader type (see INVADERS constant below)
																			--		This should match the number of city names entered for each invader type in INVADER_CITIES constant (also below)
constant.mmBarbarians.CITY_CREATION_SEARCH_RADIUS = 3.5						-- Region to search (tiles to analyze) when considering whether to found a barbarian city
																			-- 		See note about fractional values in utilTile.getTilesByDistance()
constant.mmBarbarians.CITY_CREATION_TILE_OWNERSHIP_MIN = 52					-- Number of tiles within the search radius (defined above) that must be 'owned' by barbarians, or be water tiles,
																			--		in order to consider building a city there. 'Owned' means the last unit to pass through that tile was a barbarian
																			--		unit. Max possible is (((math.floor(RADIUS + 0.5) * 2) + 1)^2) - ((RADIUS - math.floor(RADIUS)) * 8)
																			--		i.e. 1.5 = 21 (city radius), 2 = 25, 2.5 = 45, 3 = 49, 3.5 = 77, 4 = 81
constant.mmBarbarians.CITY_CREATION_LAND_TILE_MIN = 26						-- Number of tiles within the search radius that must be land tiles. This is important because water tiles are considered
																			--		to be owned by barbarians, so this prevents cities from appearing on coastal tiles with very little land nearby.
constant.mmBarbarians.CITY_CREATION_INVADER_COUNT_MIN = 8					-- Number of units of the same "invader type" as the one at the center of the radius which must exist within the search radius,
																			-- 		in order to consider building a city belonging to that invader type.
constant.mmBarbarians.TREASURY_GOLD_PER_CITY = 60							-- Each turn, the barbarian treasury is set to exactly this value * (the number of cities they own + 1). This provides a
																			--		moderate reward to any tribe conquering a barbarian city, and gives them funds to pay for city improvements if any
																			--		exist. Note that the maximum maintenance cost that any barb city could require is equal to (about) 59 which strongly
																			--		influences this figure.
constant.mmBarbarians.INVADER_CITY_WALLS_ELAPSED_YEARS_MIN = 100			-- After this many years have elapsed since an invader city was founded, it will choose to begin construction of City Walls
																			--		instead of building a unit.
constant.mmBarbarians.INVADER_CITY_IMPROVEMENT_MATERIALS_BONUS_PCT = 50		-- When an invader city begins building a city improvement rather than a unit, give it an immediate credit of this percent of
																			--		the build cost so that the improvement completes sooner (and it can resume building units more quickly)

local Barbarians = civ.getTribe(0)

local INVADERS = {
	[1] = "Berber",
	[2] = "Viking",
	[3] = "Arab",
	[4] = "Mongol",
	[5] = "Turkish",
	Berber = 1,
	Viking = 2,
	Arab = 3,
	Mongol = 4,
	Turkish = 5
}
local INVADER_CITIES = {
	[INVADERS.Berber] = {"Sevilla", "Córdoba", "Granada", "Gibraltar", "Guadix", "Baza", "Almería", "Marbella", "Antequera", "Ronda"},
	[INVADERS.Viking] = {"Avaldsnes", "Jelling", "Uppsala", "Nidaros", "Birka", "Hedeby", "Kaupang", "Paviken", "Köpingsvik", "Sigtuna"},
	[INVADERS.Arab] = {"Tyre", "Acre", "Tripoli", "Antioch", "Ascalon", "Arsuf", "Caesarea", "Haifa", "Sidon", "Beirut"},
	[INVADERS.Mongol] = {"Sarai", "Azov", "Tsaritsyn", "Astrakhan", "Urgench", "Bukhara", "Qarshi", "Samarkand", "Tashkent", "Otrar"},
	[INVADERS.Turkish] = {"Gallipoli", "Adrianople", "Varna", "Salonika", "Philippopolis", "Sofia", "Niš", "Nikopol", "Skopje", "Kosovo" }
}
db.gameData.barbInvaderCitiesFounded = { }
log.update("Defined Medieval Millennium barbarian invading tribes")

local INVADER_UNITS = {
	[MMUNIT.BerberCavalry.id] = INVADERS.Berber,
	[MMUNIT.BerberInfantry.id] = INVADERS.Berber,
	[MMUNIT.VikingBerserker.id] = INVADERS.Viking,
	[MMUNIT.VikingRaider.id] = INVADERS.Viking,
	[MMUNIT.ArabCavalry.id] = INVADERS.Arab,
	[MMUNIT.ArabInfantry.id] = INVADERS.Arab,
	[MMUNIT.MongolCavalry.id] = INVADERS.Mongol,
	[MMUNIT.TurkishJanissary.id] = INVADERS.Turk,
}
local INVADER_CITY_DEFENDER = {
	[1] = MMUNIT.BerberInfantry,
	[2] = MMUNIT.VikingRaider,
	[3] = MMUNIT.ArabInfantry,
	[4] = MMUNIT.HalberdierAI,
	[5] = MMUNIT.Pikeman,
}
log.update("Defined Medieval Millennium barbarian invading units")

local BARBARIAN_OCCURRENCES = {
-- PART I: TYPICAL GAME BARBARIANS:
-- These replace the game's default calculations for barbarians, since that setup option will always utilize the value of "Villages Only"
-- Both land and sea barbarians normally appear on every fourth Oedo year, i.e. beginning on game turn 16 and every 16th turn thereafter (16, 32, 48, ...)

-- minChance and maxChance in the tables below are per turn, and are for an "average" game, meaning
--		Barbarian Activity Level of "Restless Tribes" and Game Difficulty Level of "Duke"
-- They are adjusted within each game by both db.gameData.BARBARIAN_ACTIVITY_LEVEL and mmDifficulty.DIFFICULTY_LEVEL_PERCENT

	{ startYear =  532,	endYear =  838,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.Horseman,		secondaryLandType = MMUNIT.Axeman,			seaType = nil },
	{ startYear =  840,	endYear = 1068,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.Lancer,		secondaryLandType = MMUNIT.Spearman,		seaType = nil },
	{ startYear = 1070,	endYear = 1198,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.Lancer,		secondaryLandType = MMUNIT.CrossbowmanAI,	seaType = nil },
	{ startYear = 1200,	endYear = 1278,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.ManatArms,		secondaryLandType = MMUNIT.CrossbowmanAI,	seaType = nil },
	{ startYear = 1280,	endYear = 1500,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.ManatArms,		secondaryLandType = MMUNIT.SpearmanII,		seaType = nil },

	{ startYear =  532,	endYear =  598,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.ArcherAI,		secondaryLandType = MMUNIT.ArcherAI,		seaType = MMUNIT.CarvelGalley },
	{ startYear =  600,	endYear =  758,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.SeaxSwordsman,	secondaryLandType = MMUNIT.SeaxSwordsman,	seaType = MMUNIT.ClinkerGalley },
	{ startYear =  760,	endYear =  898,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.ArcherAI,		secondaryLandType = MMUNIT.ArcherAI,		seaType = MMUNIT.Dromon },
	{ startYear =  900,	endYear =  968,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.Swordsman,		secondaryLandType = MMUNIT.Swordsman,		seaType = MMUNIT.Longship },
	{ startYear =  970,	endYear = 1098,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.CrossbowmanAI,	secondaryLandType = MMUNIT.CrossbowmanAI,	seaType = MMUNIT.Balinger },
	{ startYear = 1100,	endYear = 1278,	minChance = 15.9,	veteranChance = 10.0,	primaryLandType = MMUNIT.SwordsmanII,	secondaryLandType = MMUNIT.SwordsmanII,		seaType = MMUNIT.Balinger },

-- PART II: SPECIAL INVASIONS:
-- These are large-scale invasions that occurred during the medieval era
-- startYear and endYear are defined to extend 25 years (landbased) and 15 years (seaborne) on either side of the actual historical invasions, to reduce predictability

	{ startYear = 696,	endYear = 772,	peakYear = 720,	minChance = 7.5,	maxChance = 60,		northSouth = "S",	eastWest = "W",
		veteranChance = 33.3,	primaryLandType = MMUNIT.BerberInfantry,	secondaryLandType = MMUNIT.BerberCavalry,	seaType = MMUNIT.CarvelGalley },

	{ startYear = 696,	endYear = 730,	peakYear = 730,	minChance = 6,		maxChance = 40,		northSouth = "S",	eastWest = "W",
		veteranChance = 33.3,	primaryLandType = MMUNIT.BerberCavalry,		secondaryLandType = MMUNIT.BerberInfantry,	seaType = nil },
	{ startYear = 732,	endYear = 954,	peakYear = 732,	minChance = 10,		maxChance = 27.5,	northSouth = "S",	eastWest = "W",
		veteranChance = 66.7,	primaryLandType = MMUNIT.BerberCavalry,		secondaryLandType = MMUNIT.BerberInfantry,	seaType = nil },

	{ startYear = 778,	endYear = 1010,	peakYear = 864,	minChance = 10,	maxChance = 86.6,	northSouth = "N",	eastWest = nil,
		veteranChance = 50.0,	primaryLandType = MMUNIT.VikingRaider,		secondaryLandType = MMUNIT.VikingBerserker,	seaType = MMUNIT.VikingLongship },

	{ startYear = 1006,	endYear = 1516,	peakYear = 1236,	minChance = 10,	maxChance = 40,	northSouth = "S",	eastWest = "W",
		veteranChance = 66.7,	primaryLandType = MMUNIT.BerberCavalry,		secondaryLandType = MMUNIT.BerberInfantry,	seaType = nil },

	{ startYear = 1064,	endYear = 1296,	peakYear = 1092,	minChance = 10,	maxChance = 37,	northSouth = "S",	eastWest = "E",
		veteranChance = 33.3,	primaryLandType = MMUNIT.Lancer,			secondaryLandType = MMUNIT.Lancer,			seaType = nil },

	{ startYear = 1070,	endYear = 1316,	peakYear = 1098,	minChance = 10,	maxChance = 63.4,	northSouth = "S",	eastWest = nil,
		veteranChance = 50.0,	primaryLandType = MMUNIT.ArabCavalry,		secondaryLandType = MMUNIT.ArabInfantry,	seaType = nil },

	{ startYear = 1080,	endYear = 1306,	peakYear = 1098,	minChance = 5,	maxChance = 31.7,	northSouth = "S",	eastWest = nil,
		veteranChance = 25.0,	primaryLandType = MMUNIT.ArabInfantry,		secondaryLandType = MMUNIT.ArabCavalry,	seaType = MMUNIT.Dromon },

	{ startYear = 1204,	endYear = 1308,	peakYear = 1230,	minChance = 10,	maxChance =  50,	northSouth = "N",	eastWest = "E",
		veteranChance = 25.0,	primaryLandType = MMUNIT.SwordsmanII,		secondaryLandType = MMUNIT.SpearmanII,		seaType = nil },

	{ startYear = 1216,	endYear = 1268,	peakYear = 1242,	minChance = 15.9, maxChance =  152.6, northSouth = nil,	eastWest = "E",
		veteranChance = 66.7,	primaryLandType = MMUNIT.MongolCavalry,		secondaryLandType = MMUNIT.MongolCavalry,	seaType = nil },

	{ startYear = 1438, endYear = 1566, peakYear = 1462,	minChance = 10,	maxChance =  29.3,	northSouth = "S",	eastWest = "E",
		veteranChance = 33.3,	primaryLandType = MMUNIT.TurkishJanissary,	secondaryLandType = MMUNIT.Bombard,	seaType = nil },

-- Part III: OTHER CUSTOM
-- Some special late-game barbarian units
-- startYear and endYear are exact, without 25-year extension on either side

	{ startYear = 1294, endYear = 1706, peakYear = 1500, minChance = 8, maxChance = 16,	northSouth = nil,	eastWest = "W",
		veteranChance = 25.0,	primaryLandType = MMUNIT.ArbalestierAI,		secondaryLandType = MMUNIT.ArbalestierAI,	seaType = MMUNIT.Privateer },

	{ startYear = 1314, endYear = 1648, peakYear = 1452, minChance = 4.6, maxChance =  25,	northSouth = nil,	eastWest = nil,
		veteranChance = 50.0,	primaryLandType = MMUNIT.SwissPikeman,		secondaryLandType = MMUNIT.SwissPikeman,	seaType = nil },
}

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
for key, data in pairs(BARBARIAN_OCCURRENCES) do
	if data.primaryLandType == nil then
		log.error("ERROR! On BARBARIAN_OCCURRENCES row " .. key .. ", primaryLandType is nil (not found)")
	end
	if data.secondaryLandType == nil then
		log.error("ERROR! On BARBARIAN_OCCURRENCES row " .. key .. ", secondaryLandType is nil (not found)")
	end
end
log.update("Synchronized Medieval Millennium barbarians")

local function confirmLoad ()
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " loaded successfully")
	log.info("")
end

-- ===========================================================
-- ••••••••••••••• STRICTLY INTERNAL FUNCTIONS •••••••••••••••
-- ===========================================================
local function isValidEnemyTarget (tile, cityValid, unitValid)
	log.trace()
	local hasHumanOrAiCity = false
	local hasHumanOrAiUnit = false
	if cityValid == true and tile.city ~= nil and tile.city.owner.id ~= 0 then
		hasHumanOrAiCity = true
	end
	if unitValid == true then
		for unit in tile.units do
			if unit.owner.id ~= 0 then
				hasHumanOrAiUnit = true
				break
			end
		end
	end
	if hasHumanOrAiCity == true or hasHumanOrAiUnit == true then
		local description = "valid enemy target at " .. tile.x .. "," .. tile.y .. "," .. tile.z
		if tile.city ~= nil then
			description = description .. " (city of " .. tile.city.name .. ")"
		end
		return tile, description
	end
end

local function getClosestBarbarianTarget (barbLocation, cityValid, unitValid)
	log.trace()
	local startTimestamp = os.clock()
	local validEnemyTargetTile = nil
	local description = ""
	local targetRouteFound = false
	local tilesEncountered = { }
	local tileId = tileutil.getTileId(barbLocation)
	tilesEncountered[tileId] = 0
	local tilesNotYetConsidered = { }
	table.insert(tilesNotYetConsidered, { tile = barbLocation, path = { } })
	local countConsidered = 0

	while #tilesNotYetConsidered > 0 do
		local consideringTile = tilesNotYetConsidered[1]["tile"]
		local consideringTilePath = {table.unpack(tilesNotYetConsidered[1]["path"])}
		local consideringTileDistance = #consideringTilePath
		table.insert(consideringTilePath, consideringTile)
		countConsidered = countConsidered + 1
		table.remove(tilesNotYetConsidered, 1)
		validEnemyTargetTile, description = isValidEnemyTarget(consideringTile, cityValid, unitValid)
		if validEnemyTargetTile ~= nil then
			targetRouteFound = true
			log.info("Found " .. description .. " at a distance of " .. tostring(#consideringTilePath - 1) .. " tiles")
			break
		elseif constant.mmBarbarians.VALID_ROUTE_LENGTH_MAX == nil or constant.mmBarbarians.VALID_ROUTE_LENGTH_MAX > consideringTileDistance then
			for _, adjTile in ipairs(tileutil.getAdjacentTiles(consideringTile, false)) do
				if civ.isTile(adjTile) and tileutil.getTerrainId(adjTile) ~= MMTERRAIN.Sea and tileutil.getTerrainId(adjTile) ~= MMTERRAIN.Mountains then
					tileId = tileutil.getTileId(adjTile)
					if tilesEncountered[tileId] == nil or tilesEncountered[tileId] > (consideringTileDistance + 1) then
						tilesEncountered[tileId] = consideringTileDistance + 1
						table.insert(tilesNotYetConsidered, { tile = adjTile, path = consideringTilePath })
					end
				end
			end
		end
	end

	if targetRouteFound == false then
		local message = "No target found"
		if constant.mmBarbarians.VALID_ROUTE_LENGTH_MAX >= 0 then
			message = message .. " within " .. constant.mmBarbarians.VALID_ROUTE_LENGTH_MAX .. " tiles"
		else
			message = message .. " on this map"
		end
		log.info(message)
	end
	log.info("getClosestBarbarianTarget() analyzed " .. countConsidered .. " tiles in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")

	return validEnemyTargetTile
end

local function getValidBarbarianLocation (landType, seaType, northSouth, eastWest)
	log.trace()
	local startTimestamp = os.clock()
	local mapWidth, mapHeight, mapQuantity = civ.getMapDimensions()
	local maxXdim = (mapWidth / 2) - 1
	local maxYdim = mapHeight - 1
	local destinationTile = nil
	local foundValidLocation = false
	local messageText = "Testing "
	local locationsEvaluated = 0
	while foundValidLocation == false and locationsEvaluated < constant.mmBarbarians.LOCATIONS_TO_CHECK_MAX do
		local uniformX = math.random(mapWidth / 2) - 1
		local weightedX = round( (uniformX ^ constant.mmBarbarians.WEIGHTED_LOCATION_FACTOR) / (maxXdim ^ (constant.mmBarbarians.WEIGHTED_LOCATION_FACTOR - 1)) )
		local randomX = uniformX * 2
		if eastWest == "W" then
			randomX = weightedX * 2
		elseif eastWest == "E" then
			randomX = (maxXdim - weightedX) * 2
		end
		local uniformY = math.random(mapHeight) - 1
		local weightedY = round( (uniformY ^ constant.mmBarbarians.WEIGHTED_LOCATION_FACTOR) / (maxYdim ^ (constant.mmBarbarians.WEIGHTED_LOCATION_FACTOR - 1)) )
		local randomY = uniformY
		if northSouth == "N" then
			randomY = weightedY
		elseif northSouth == "S" then
			randomY = maxYdim - weightedY
		end
		if randomY % 2 == 1 then
			randomX = randomX + 1
		end
		randomX = round(randomX)	-- just to make it an integer such as  10  instead of a decimal such as  10.0
		local randomTile = civ.getTile(randomX, randomY, 0)
		if randomTile ~= nil then
			locationsEvaluated = locationsEvaluated + 1
			messageText = messageText .. randomX .. "," .. randomY .. "; "
			-- Never create barbarians in a city, even one owned by the barbarians:
			if randomTile.city == nil then
				-- Naval barbarians must be created on a sea tile; land barbarians must be created on a land tile
				if (seaType ~= nil and tileutil.isWaterTile(randomTile)) or
				   (seaType == nil and tileutil.isLandTile(randomTile)) then
					-- Destination tile for barbarians must not contain any other units at the present time, even other barbarians!
					-- Prevents overstacking, and prevents creating land barbarians on a sea tile that happens to contain unrelated sea barbarians.
					local foundUnit = false
					for unit in randomTile.units do
						foundUnit = true
						break
					end
					if foundUnit == false then
						-- Do not create naval barbarians on small lakes, or land barbarians on small islands:
						if tileutil.getTerrainBodySize(randomTile, constant.mmBarbarians.TERRAIN_BODY_SIZE_MIN) >= constant.mmBarbarians.TERRAIN_BODY_SIZE_MIN then

							if (seaType ~= nil and unitutil.isValidUnitLocation(seaType, Barbarians, randomTile)) or
							   (seaType == nil and unitutil.isValidUnitLocation(landType, Barbarians, randomTile)) then
							   -- The location is valid; however, some special cases below will still reject the tile
								foundValidLocation = true

							   -- Barbs are prevented from appearing within DISTANCE_FROM_CITY_MIN tiles of a non-barbarian city:
								for _, nearbyTile in ipairs(tileutil.getTilesByDistance(randomTile, constant.mmBarbarians.DISTANCE_FROM_CITY_MIN, false)) do
									if civ.isTile(nearbyTile) and nearbyTile.city ~= nil and nearbyTile.city.owner ~= Barbarians then
										foundValidLocation = false
										break
									end
								end
								-- Barbs are also prevented from appearing within DISTANCE_FROM_CASTLE_MIN tiles of a castle defended by a non-barbarian unit:
								if foundValidLocation == true then
									for _, nearbyTile in ipairs(tileutil.getTilesByDistance(randomTile, constant.mmBarbarians.DISTANCE_FROM_CASTLE_MIN, false)) do
										if civ.isTile(nearbyTile) and hasCastle(nearbyTile) == true then
											for occupier in nearbyTile.units do
												-- The check for movement prevents a castle unit from serving as its own defender:
												if occupier.owner ~= Barbarians and occupier.type.defense > 0 and occupier.type.move > 0 then
													foundValidLocation = false
													break
												end
											end
										end
									end
								end
							   -- The base game will not create barbarians on a tile which is "improved" (road etc., irrigation etc., mine) but that restriction is intentionally not implemented
								if foundValidLocation == true then
									destinationTile = randomTile
								end
							end
						end
					end
				end
			end
		end
	end

	log.info(messageText)
	if destinationTile == nil then
		log.info("No valid location found after evaluating " .. locationsEvaluated .. " tiles in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")
	else
		log.info("Found valid location: " .. destinationTile.x .. "," .. destinationTile.y)
		log.info("Evaluated " .. locationsEvaluated .. " tiles in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")
	end

	return destinationTile
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
-- This is also called internally by createBarbarianUnits() and must be defined prior to it in this file:
local function getBarbarianActivityLevel ()
	log.trace()
	local dialog = civ.ui.createDialog()
	dialog.title = "Select Level of Barbarian Activity"
	dialog.width = 400
	dialog:addText("To provide an authentic medieval experience, the barbarian activity level of \"Villages Only\" is not available. (Note that regardless of which level you select, your official game score will always include '-50' for Barbarians. This is unavoidable and simply something you must overcome through your score in other categories.)")
--	dialog:addOption("Villages Only", 0)
	dialog:addOption("Roving Bands", 1)
	dialog:addOption("Restless Tribes", 2)
	dialog:addOption("Raging Hordes", 3)
	dialog:addOption("Barbarian Wrath", 4)
	log.action("Dialog box displayed")
	db.gameData.BARBARIAN_ACTIVITY_LEVEL = dialog:show()
end

local function barbarianUnitKilled (winningUnit, losingUnit, battleTile)
	log.trace()
	-- Only consider cases where the losing unit belonged to tribe 0:
	if losingUnit.owner.id == 0 then
		log.info()
		if isHumanUnitType(losingUnit.type) == true then
			-- Plunder is not possible if the battle tile contains a city or castle:
			if battleTile.city ~= nil or hasCastle(battleTile) then
				log.info("Battle tile contains a city or castle; plunder not available")
			elseif tileutil.getTerrainId(battleTile) == MMTERRAIN.Sea then
				log.info("Battle occurred on a Sea tile; plunder not available")
			else
				-- Plunder is not possible if the battle tile contains another barbarian defender:
				local foundOtherBarbarianDefender = false
				for otherUnit in battleTile.units do
					if otherUnit.owner.id == 0 and otherUnit.type.defense > 0 and otherUnit.id ~= losingUnit.id then
						foundOtherBarbarianDefender = true
						break
					end
				end
				if foundOtherBarbarianDefender == true then
					log.info("Battle tile is occupied by another Barbarian unit and could not be plundered")
				else
					-- Plunder successful!
					local rewardAmount = 0
					if losingUnit.type == MMUNIT.Warlord then
						rewardAmount = adjustForDifficulty(constant.mmBarbarians.REWARD_KILL_WARLORD[db.gameData.BARBARIAN_ACTIVITY_LEVEL], winningUnit.owner, true)
						if rewardAmount > 0 and winningUnit.owner.isHuman == true then
							uiutil.messageDialog("Military Commander's Report", "Barbarian leader captured! The " .. rewardAmount .. " gold in his possession has been added to your treasury.", 320)
						end
					else
						-- Only the human player receives a bonus for killing other barb units (see notes in constant definition)
						if winningUnit.owner.isHuman == true then
							rewardAmount = constant.mmBarbarians.REWARD_KILL_LAST_UNIT[civ.game.difficulty]
						end
						if rewardAmount > 0 then
							uiutil.messageDialog("Military Commander's Report", "Barbarian warriors defeated! " .. rewardAmount .. " gold worth of plunder has been collected from the battlefield.", 320)
						end
					end
					if rewardAmount > 0 then
						tribeutil.changeMoney(winningUnit.owner, rewardAmount)
					else
						log.info("Plunder amount calculated as 0, no change necessary")
					end
				end
			end
		else
			log.info("Losing barbarian unit was not a human unit and could not be plundered")
		end

		if isHumanUnitType(winningUnit.type) == true then
			if losingUnit.type == MMUNIT.BerberCavalry or losingUnit.type == MMUNIT.BerberInfantry then
				local berberInvasionTech = techutil.findByName("Berber Invasion", true)
				if techutil.knownByTribe(winningUnit.owner, berberInvasionTech) == false then
					techutil.grantTech(winningUnit.owner, berberInvasionTech)
					if winningUnit.owner.isHuman == true then
						uiutil.messageDialog("Berber Invasion", "With your defeat of invading Berber forces, you have received the \"Berber Invasion\" technology. This makes additional research options available to you.")
					end
				end
			elseif losingUnit.type == MMUNIT.VikingBerserker or losingUnit.type == MMUNIT.VikingRaider then
				local vikingInvasionTech = techutil.findByName("Viking Invasion", true)
				if techutil.knownByTribe(winningUnit.owner, vikingInvasionTech) == false then
					techutil.grantTech(winningUnit.owner, vikingInvasionTech)
					if winningUnit.owner.isHuman == true then
						uiutil.messageDialog("Viking Invasion", "With your defeat of invading Viking forces, you have received the \"Viking Invasion\" technology. This makes additional research options available to you.")
					end
				end
			elseif losingUnit.type == MMUNIT.MongolCavalry then
				local mongolInvasionTech = techutil.findByName("Mongol Invasion", true)
				if techutil.knownByTribe(winningUnit.owner, mongolInvasionTech) == false then
					techutil.grantTech(winningUnit.owner, mongolInvasionTech)
					if winningUnit.owner.isHuman == true then
						uiutil.messageDialog("Mongol Invasion", "With your defeat of invading Mongol forces, you have received the \"Mongol Invasion\" technology. This makes additional research options available to you.")
					end
				end
			end
		end

	end
end

local function cityTakenByBarbarians (city, previousOwner)
	log.trace()
	if city.owner == Barbarians and previousOwner.isHuman == false then
		for potentialInvader in city.location.units do
			if potentialInvader.owner == city.owner and INVADER_UNITS[potentialInvader.type.id] ~= nil then
				local barbInvaderPresent = INVADER_UNITS[potentialInvader.type.id]
				uiutil.messageDialog("Chancellor", "Your Majesty, distressing news from abroad! The invading " .. INVADERS[barbInvaderPresent] .. " forces have established themselves in Western Europe by conquering the " .. previousOwner.adjective .. " city of " .. city.name .. "! All civilized nations must work together to protect ourselves from these barbarians and drive them from our lands!", 450)
			end
		end
	end
end

local function cityTakenFromBarbarians (city, previousOwner)
	log.trace()
	local barbInvaderCities = retrieve("barbInvaderCities")
	if previousOwner == Barbarians and city.owner.isHuman == false then
		local barbInvaderCity = barbInvaderCities[city.id]
		if barbInvaderCity ~= nil then
			uiutil.messageDialog("Chancellor", "Your Majesty, major tidings have reached us from abroad. The nation of " .. city.owner.name .. " has won a major victory and taken the " .. INVADERS[barbInvaderCity.invader] .. " city of " .. city.name .. "! While it's a relief to hear that civilized nations are repelling these barbarian invaders, this conquest does increase the strength of the " .. city.owner.adjective .. " nation, which deserves further consideration...", 450)
			barbInvaderCities[city.id] = nil
			store("barbInvaderCities", barbInvaderCities)
		end
	end
end

local function createBarbarianUnits ()
	log.trace()

	if db.gameData.BARBARIAN_ACTIVITY_LEVEL == nil then
		getBarbarianActivityLevel ()
	end

	if db.gameData.BARBARIAN_ACTIVITY_LEVEL > 0 then
		local activeBarbarians = 0
		local activeNonBarbarians = 0
		for unit in civ.iterateUnits() do
			if unit.type.role <= 4 then
				if unit.owner.id == 0 then
					activeBarbarians = activeBarbarians + 1
				else
					activeNonBarbarians = activeNonBarbarians + 1
				end
			end
		end
		local maxBarbsAllowed = round(activeNonBarbarians / (1 - (constant.mmBarbarians.WORLD_UNIT_PCT_MAX / 100))) - activeNonBarbarians
		local maxBarbariansToCreate = maxBarbsAllowed - activeBarbarians
		log.info("Current barbarians: " .. activeBarbarians .. ", non-barbarians: " .. activeNonBarbarians .. ", potential new barbarians: " .. maxBarbariansToCreate)

		if maxBarbariansToCreate >= 1 then
			for entry, barbOccurrence in ipairs(BARBARIAN_OCCURRENCES) do
				if barbOccurrence.primaryLandType == nil then
					log.error("ERROR! primaryLandType = nil for row " .. entry)
				else
					local gameYear = civ.getGameYear()
					if gameYear >= barbOccurrence.startYear and gameYear <= barbOccurrence.endYear then
						local baseChance = 0
						if barbOccurrence.peakYear == nil then
							baseChance = barbOccurrence.minChance / 2
						elseif gameYear < barbOccurrence.peakYear then
							baseChance = (barbOccurrence.minChance / 2) +
								( (((barbOccurrence.maxChance - barbOccurrence.minChance) / 2) / ((barbOccurrence.peakYear - barbOccurrence.startYear) / 2)) *
								  ((gameYear - barbOccurrence.startYear) / 2) )
						elseif gameYear == barbOccurrence.peakYear then
							baseChance = barbOccurrence.maxChance / 2
						elseif gameYear > barbOccurrence.peakYear then
							baseChance = (barbOccurrence.minChance / 2) +
								( (((barbOccurrence.maxChance - barbOccurrence.minChance) / 2) / ((barbOccurrence.endYear - barbOccurrence.peakYear) / 2)) *
								  ((barbOccurrence.endYear - gameYear) / 2) )
						end

						local pctChance = adjustForDifficulty(baseChance * db.gameData.BARBARIAN_ACTIVITY_LEVEL, Barbarians, true)

						while pctChance > 0 and maxBarbariansToCreate >= 1 do
							local randomNumber = math.random(100)
							log.info("Barbarian_Occurrences " .. entry .. ": " .. barbOccurrence.primaryLandType.name .. ", baseChance = " .. (baseChance * 2) .. ", pctChance = " .. pctChance .. ", randomNumber = " .. randomNumber)
							if randomNumber <= pctChance then
								local landUnitsToCreateMin = constant.mmBarbarians.UNITS_PER_BAND_MIN
								-- Not using adjustForDifficulty() here, since this is used in calculating pctChance already:
								local landUnitsToCreateMax = math.min(round( (db.gameData.BARBARIAN_ACTIVITY_LEVEL ^ constant.mmBarbarians.MAX_UNITS_PER_BAND_FACTOR) + 1 +
																			 (pctChance / adjustForDifficulty(100, Barbarians, false)) * constant.mmBarbarians.MAX_UNITS_PER_BAND_FACTOR ),
																	  constant.mmBarbarians.UNITS_PER_BAND_MAX)
								local landUnitsToCreate = math.random(landUnitsToCreateMin, landUnitsToCreateMax)
								log.info("landUnitsToCreate = " .. landUnitsToCreate .. ", random between " .. landUnitsToCreateMin .. " and " .. landUnitsToCreateMax)
								local destinationTile = getValidBarbarianLocation(barbOccurrence.primaryLandType, barbOccurrence.seaType, barbOccurrence.northSouth, barbOccurrence.eastWest)
								-- Destination tile could be nil if constant.mmBarbarians.LOCATIONS_TO_CHECK_MAX tiles were evaluated and none of them were acceptable to place barbs
								if destinationTile ~= nil then

									local seaUnit = nil
									if barbOccurrence.seaType ~= nil then

										seaUnit = civ.createUnit(barbOccurrence.seaType, Barbarians, destinationTile)
										if seaUnit == nil then
											log.error("ERROR! Failed to create " .. Barbarians.adjective .. " " .. barbOccurrence.seaType.name .. " at " .. destinationTile.x .. "," .. destinationTile.y .. "," .. destinationTile.z)
										else
											seaUnit.homeCity = nil
											log.action("Created " .. seaUnit.owner.adjective .. " " .. seaUnit.type.name .. " at " .. seaUnit.x .. "," .. seaUnit.y .. "," .. seaUnit.z .. " (" .. seaUnit.id .. ")")
											local randomVeteran = math.random(100)
											log.info(seaUnit.owner.adjective .. " " .. seaUnit.type.name .. ": veteran pctChance = " .. barbOccurrence.veteranChance .. ", randomNumber = " .. randomVeteran)
											if randomVeteran <= barbOccurrence.veteranChance then
												seaUnit.veteran = true
												log.action("  Added veteran status to " .. seaUnit.owner.adjective .. " " .. seaUnit.type.name .. " (ID " .. seaUnit.id .. ")")
											end
										end
										-- Deliberately not assigning a target tile to the ship; current behavior of ships seems to play well
									end
									-- Land units should not be created if we tried and failed to create a ship;
									--		only proceed if we didn't try to create a ship, or if we tried and succeeded:
									if barbOccurrence.seaType == nil or seaUnit ~= nil then

										local createdLandUnits = {}
										local numCreatedUnits = 0
										for unitNumber = 1, landUnitsToCreate do
											local typeToCreate = barbOccurrence.primaryLandType
											if barbOccurrence.secondaryLandType ~= nil and string.sub(constant.mmBarbarians.TYPE_PATTERN, unitNumber, unitNumber) == "S" then
												typeToCreate = barbOccurrence.secondaryLandType
											end
											local unit = civ.createUnit(typeToCreate, Barbarians, destinationTile)
											if unit ~= nil then
												unit.homeCity = nil
												table.insert(createdLandUnits, unit)
											end
										end
										if createdLandUnits == nil or #createdLandUnits == 0 then
											log.error("ERROR! Failed to create " .. Barbarians.adjective .. " " .. barbOccurrence.primaryLandType.name .. " at " .. destinationTile.x .. "," .. destinationTile.y .. "," .. destinationTile.z)
										else
											local targetTile = nil
											-- Land units should only be given a GoTo order if they are not aboard a ship
											if barbOccurrence.seaType == nil then
												targetTile = getClosestBarbarianTarget(destinationTile, true, true)

												-- Potentially change terrain on the target tile
												if gameYear >= constant.mmBarbarians.CREATION_IMPROVES_TERRAIN_BEGIN_YEAR then
													local terrainId = tileutil.getTerrainId(destinationTile)
													if terrainId == MMTERRAIN.DenseForest or terrainId == MMTERRAIN.PineForest or terrainId == MMTERRAIN.Woodland or
													   terrainId == MMTERRAIN.Heathland or terrainId == MMTERRAIN.Hills
													
													then
														-- This is the *inverse* of the calculation used for pctChance. It reacts to the frequency of barbarian creation by making it more likely
														--		to change terrain if there are fewer barb creation events, and vice versa.
														-- changeTerrainChance could be >100% but that's OK
														-- Not calling adjustForDifficulty() here; it's not clear who exactly benefits from more cleared wilderness terrain.
														local changeTerrainChance = (constant.mmBarbarians.CREATION_IMPROVES_TERRAIN_PCT * 2) / db.gameData.BARBARIAN_ACTIVITY_LEVEL
														local randomImprove = math.random(100)
														log.info("Barb destination " .. destinationTile.x .. "," .. destinationTile.y .. ": changeTerrainChance = " .. changeTerrainChance .. ", randomNumber = " .. randomImprove)
														if randomImprove <= changeTerrainChance then
															if terrainId == MMTERRAIN.DenseForest or terrainId == MMTERRAIN.PineForest then
																setTerrainType(destinationTile, MMTERRAIN.Woodland)
															elseif terrainId == MMTERRAIN.Woodland then

																-- setTerrainType(destinationTile, MMTERRAIN.Arable)
																tileutil.setTerrainId(destinationTile, MMTERRAIN.Arable, MMTERRAIN, true)
															elseif terrainId == MMTERRAIN.Heathland then
																setTerrainType(destinationTile, MMTERRAIN.Pasture)
															elseif terrainId == MMTERRAIN.Hills then
																setTerrainType(destinationTile, MMTERRAIN.TerracedHills)
															end
														end
													end
												end

											end
											for _, unit in pairs(createdLandUnits) do
												numCreatedUnits = numCreatedUnits + 1
												log.action("Created " .. unit.owner.adjective .. " " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. " (" .. unit.id .. ")")

												local randomVeteran = math.random(100)
												log.info(unit.owner.adjective .. " " .. unit.type.name .. ": veteran pctChance = " .. barbOccurrence.veteranChance .. ", randomNumber = " .. randomVeteran)
												if randomVeteran <= barbOccurrence.veteranChance then
													unit.veteran = true
													log.action("  Added veteran status to " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ")")
												end

												if targetTile ~= nil then
													-- Commenting this out because it doesn't work anyway! Barbarians play by their own rules and seem to ignore .gotoTile instructions:
													-- unit.order = 0x0C
													-- unit.gotoTile = targetTile
													-- log.action("  Ordered unit to GoTo " .. targetTile.x .. "," .. targetTile.y)
												elseif barbOccurrence.seaType ~= nil then
													unitutil.sleepUnit(unit)	-- Land units created on a sea tile with a ship will "sleep" so the game is more likely to think of them as "on board"
												end
											end
											if targetTile ~= nil then
												local nearestHumanCity = nil
												if targetTile.city ~= nil then
													if targetTile.city.owner.isHuman == true then
														nearestHumanCity = targetTile.city
													end
												else
													-- i.e., targetTile.city = nil
													local targetTileClosestCity = getClosestBarbarianTarget(destinationTile, true, false)
													if targetTileClosestCity ~= nil and targetTileClosestCity.city ~= nil and targetTileClosestCity.city.owner.isHuman == true then
														nearestHumanCity = targetTileClosestCity.city
													end
												end
												if nearestHumanCity ~= nil then
													civ.ui.centerView(nearestHumanCity.location)
													uiutil.messageDialog("Constable", "My Lord, barbarians have been spotted near " .. nearestHumanCity.name .. ". Citizens are panicking!", 320)
												end
											end
										end
										if numCreatedUnits >= 3 then
											local unit = civ.createUnit(MMUNIT.Warlord, Barbarians, destinationTile)
											unit.homeCity = nil
											if unit == nil then
												log.error("ERROR! Failed to create unit: " .. MMUNIT.Warlord.name .. ", " .. Barbarians.name)
											else
												numCreatedUnits = numCreatedUnits + 1
												log.action("Created " .. unit.owner.adjective .. " " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. " (" .. unit.id .. ")")
												-- All warlords will be set as veterans (not sure if this will affect their behavior in any way, but it seems realistic):
												unit.veteran = true
												log.action("  Added veteran status to " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ")")
												-- Deliberately not assigning a target tile to the warlord; will see if they follow main land units
												-- But it should sleep if it was created on a sea tile:
												if barbOccurrence.seaType ~= nil then
													unitutil.sleepUnit(unit)
												end
											end
										end
										-- This is handled at the end so that a ship does not influence the decision about adding a Warlord
										-- But the ship should be counted alongside land units when recalculating maxBarbariansToCreate, since the original calculation included
										--		both sea and land units (both for barbarians and AI/human nations)
										if seaUnit ~= nil then
											numCreatedUnits = numCreatedUnits + 1
										end
										maxBarbariansToCreate = maxBarbariansToCreate - numCreatedUnits
									end		-- barbOccurrence.seaType == nil or seaUnit ~= nil
								end		-- destinationTile ~= nil
							end		-- randomNumber <= pctChance
							pctChance = pctChance - 100
						end		-- while pctChance > 0 and maxBarbariansToCreate >= 1

					end		-- date is within range
				end		-- barbOccurrence.primaryLandType ~= nil
			end		-- for entry, barbOccurrence in ipairs(BARBARIAN_OCCURRENCES)
		end		-- maxBarbariansToCreate >= 1
	end		-- barbarian activity is higher than Villages Only
end

local function createInvaderCities ()
	log.trace()
	local startTimestamp = os.clock()
	local barbCitiesFoundedThisTurn = 0
	for tile in tileutil.iterateTilesSpiralIn(0) do
		local terrainId = tileutil.getTerrainId(tile)
		if terrainId ~= MMTERRAIN.MountainPass and
		   terrainId ~= MMTERRAIN.Mountains and
		   terrainId ~= MMTERRAIN.MarshFen and
		   terrainId ~= MMTERRAIN.Sea and
		   terrainId ~= MMTERRAIN.Monastery and
		   terrainId ~= MMTERRAIN.Urban and
		   tile.defender == Barbarians then
			for unit in tile.units do
				local barbInvaderPresent = INVADER_UNITS[unit.type.id]
				if barbInvaderPresent ~= nil then
					if (db.gameData.barbInvaderCitiesFounded[barbInvaderPresent] or 0) < constant.mmBarbarians.CITY_CREATION_PER_INVADER_MAX then
						local barbTileOwnershipCount = 0
						local landTileCount = 0
						local invaderTypeCount = 0
						local cityNearby = false
						for _, regionTile in ipairs(tileutil.getTilesByDistance(tile, constant.mmBarbarians.CITY_CREATION_SEARCH_RADIUS, true)) do
							if civ.isTile(regionTile) then
								if regionTile.city ~= nil then
									cityNearby = true
									break
								end
								if (regionTile.owner == Barbarians or tileutil.isWaterTile(regionTile)) then
									barbTileOwnershipCount = barbTileOwnershipCount + 1
									if tileutil.isLandTile(regionTile) then
										landTileCount = landTileCount + 1
									end
								end
								for potentialInvader in regionTile.units do
									if INVADER_UNITS[potentialInvader.type.id] ~= nil and INVADER_UNITS[potentialInvader.type.id] == barbInvaderPresent then
										invaderTypeCount = invaderTypeCount + 1
									end
								end
							end
						end
						if cityNearby == true then
							log.info("Analyzed " .. tile.x .. "," .. tile.y .. ": cityNearby = " .. tostring(cityNearby))
						else
							log.info("Analyzed " .. tile.x .. "," .. tile.y .. ": " .. barbTileOwnershipCount .. " region tiles are water or owned by barbs, " .. landTileCount .. " region land tiles, " .. invaderTypeCount .. " invaders of same type in region")
							if barbTileOwnershipCount >= constant.mmBarbarians.CITY_CREATION_TILE_OWNERSHIP_MIN and
							   landTileCount >= constant.mmBarbarians.CITY_CREATION_LAND_TILE_MIN and
							   invaderTypeCount >= constant.mmBarbarians.CITY_CREATION_INVADER_COUNT_MIN then
								-- "Build!"
								local barbInvaderCities = retrieve("barbInvaderCities")
								local invaderCity = {
									invader = barbInvaderPresent,
									yearFounded = civ.getGameYear(),
									producing = nil,
									materials = 0
								}
								db.gameData.barbInvaderCitiesFounded[invaderCity.invader] = (db.gameData.barbInvaderCitiesFounded[invaderCity.invader] or 0) + 1
								invaderCity.name = INVADER_CITIES[invaderCity.invader][db.gameData.barbInvaderCitiesFounded[invaderCity.invader]]
								if invaderCity.name == nil then

									invaderCity.name = INVADERS[invaderCity.invader] .. " City " .. tostring(db.gameData.barbInvaderCitiesFounded[invaderCity.invader])
								end
								local newCity = cityutil.createCity(invaderCity.name, Barbarians, tile)

								-- If the city that is built is the *first* Barbarian city in the game (meaning that they haven't conquered any others yet)
								-- 		then the game creates it like it would a respawning nation's first city: it's greater than size 1, has a Royal Palace and potentially
								-- 		other improvements, it may have one or more supported units as defenders, etc.
								for improvement in imputil.iterateImprovements() do
									if civ.hasImprovement(newCity, improvement) then
										civ.removeImprovement(newCity, improvement)
									end
								end
								for supportedUnit in cityutil.iterateHomeCityUnits(newCity) do
									civ.deleteUnit(supportedUnit)
								end
								newCity.size = 1
								-- Add one custom defender and fortify him:
								local defender = unitutil.createByType(INVADER_CITY_DEFENDER[barbInvaderPresent], Barbarians, tile, {homeCity = nil})
								unitutil.fortifyUnit(defender)

								barbInvaderCities[newCity.id] = invaderCity
								log.update("Documented new barbarian invader city: " .. INVADERS[invaderCity.invader] .. " city of " .. invaderCity.name)
								barbCitiesFoundedThisTurn = barbCitiesFoundedThisTurn + 1
								store("barbInvaderCities", barbInvaderCities)
								uiutil.messageDialog("Chancellor", "Your Majesty, distressing news from abroad! The invading " .. INVADERS[barbInvaderPresent] .. " forces have established themselves in Western Europe by founding the city of " .. invaderCity.name .. "! All civilized nations must work together to protect ourselves from these barbarians and drive them from our lands!", 450)
							end
						end
					end
				end
			end
		end
	end
	log.info("Reviewed entire map and founded " .. barbCitiesFoundedThisTurn .. " barbarian cities in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")
end

local function processInvaderCities ()
	log.trace()
	local barbInvaderCities = retrieve("barbInvaderCities")
	for cityId, invaderCity in pairs(barbInvaderCities) do
		local city = civ.getCity(cityId)
		if city ~= nil and city.owner == Barbarians and city.name == invaderCity.name then
			-- In some circumstances, city will not retain generated Materials. For consistency, this event will *always* zero out Materials and track it all internally:
			if city.shields ~= 0 then
				cityutil.changeShields(city, city.shields * -1)
			end
			-- If city produces Materials, add them to internal tracking:
			if city.totalShield > 0 then
				log.update("Documented " .. city.totalShield .. " Material(s) added to " .. INVADERS[invaderCity.invader] .. " city of " .. invaderCity.name .. " (was " .. invaderCity.materials .. ", now " .. (invaderCity.materials + city.totalShield) .. ")")
				invaderCity.materials = invaderCity.materials + city.totalShield
			else
				log.info(INVADERS[invaderCity.invader] .. " city of " .. invaderCity.name .. " does not currently produce any Materials")
			end
			-- If accumulated Materials is >= cost of item being produced, it is complete:
			if invaderCity.producing ~= nil then
				-- Not using adjustForDifficulty(), since the shield columns are already being adjusted to account for that:
				local costToCompleteItem = invaderCity.producing.cost * cityutil.getShieldColumns(Barbarians, humanIsSupreme())
				if invaderCity.materials > costToCompleteItem then
					-- Production complete!
					if civ.isUnitType(invaderCity.producing) then
						unitutil.createByType(invaderCity.producing, Barbarians, city.location, {homeCity = city})
					elseif civ.isImprovement(invaderCity.producing) then
						imputil.addImprovement(city, invaderCity.producing)
					else
						log.error("ERROR! Barbarian invader city of " .. invaderCity.name .. " attempted to build an object that was not a unit type or improvement.")
					end
					invaderCity.producing = nil
					invaderCity.materials = 0
					log.update("Cleared build queue and accumulated Materials from " .. invaderCity.name .. " due to completed item")
				else
					log.info(INVADERS[invaderCity.invader] .. " city of " .. invaderCity.name .. " has " .. invaderCity.materials .. " Materials, needs a total of " .. costToCompleteItem .. " to build " .. invaderCity.producing.name)
				end
			end
			-- If city is not producing anything, assign the appropriate item:
			if invaderCity.producing == nil then
				if city.size >= civ.cosmic.sizeAquaduct and civ.hasImprovement(city, MMIMP.MarketTownCharter) == false then
					-- If city will soon be blocked from growing larger, set it to produce Market Town Charter and grant a 50% boost towards completion
					invaderCity.producing = MMIMP.MarketTownCharter
					invaderCity.materials = round(MMIMP.MarketTownCharter.cost * cityutil.getShieldColumns(Barbarians, humanIsSupreme()) * (constant.mmBarbarians.INVADER_CITY_IMPROVEMENT_MATERIALS_BONUS_PCT / 100))
				elseif civ.getGameYear() >= (invaderCity.yearFounded + constant.mmBarbarians.INVADER_CITY_WALLS_ELAPSED_YEARS_MIN) and civ.hasImprovement(city, MMIMP.CityWalls) == false then
					-- If a fixed amount of years have elapsed since the city was founded, set it to produced City Walls and grant a 50% boost towards completion
					invaderCity.producing = MMIMP.CityWalls
					invaderCity.materials = round(MMIMP.CityWalls.cost * cityutil.getShieldColumns(Barbarians, humanIsSupreme()) * (constant.mmBarbarians.INVADER_CITY_IMPROVEMENT_MATERIALS_BONUS_PCT / 100))
				else
					local potentialUnitTypesToBuild = { }
					for key, value in pairs(INVADER_UNITS) do
						if value == invaderCity.invader then
							table.insert(potentialUnitTypesToBuild, key)
						end
					end
					if #potentialUnitTypesToBuild > 0 then
						invaderCity.producing = civ.getUnitType(potentialUnitTypesToBuild[math.random(#potentialUnitTypesToBuild)])
						if invaderCity.producing ~= nil then
							log.update("Assigned shadow-" .. invaderCity.name .. " to produce " .. invaderCity.producing.name)
						else
							log.error("ERROR! Barbarian invader city of " .. invaderCity.name .. " found a unit type to produce but failed to assign it correctly.")
						end
					else
						log.error("ERROR! Barbarian invader city of " .. invaderCity.name .. " could not find a valid unit type to produce.")
					end
				end
			end
		else
			-- City is not owned by Barbs anymore, or reference is to a different city entirely:
			log.update("Cleared out reference to invader city ID " .. cityId .. ", no longer present as expected in game")
			barbInvaderCities[cityId] = nil
		end
	end
end

local function disbandBarbariansLostAtSea ()
	log.trace()

	for unit in civ.iterateUnits() do
		if unit.owner.id == 0 and unit.type.domain == domain.Land and tileutil.getTerrainId(unit.location) == MMTERRAIN.Sea then
			-- If unit is trapped at sea without a ship, disband it:
			local foundShip = false
			for otherUnit in unit.location.units do
				if otherUnit.id ~= unit.id and otherUnit.type.domain == domain.Sea then
					foundShip = true
					break
				end
			end
			if foundShip == false then
				log.action("Disbanded Barbarian " .. unit.type.name .. " abandoned at sea with no ship, at " .. unit.x .. "," .. unit.y .. ".")
				unitutil.deleteUnit(unit)
			end
		end
	end
end

local function fortifyDeleteOrMove (unit)
	log.trace()
	-- Special handling applies at time of activation to all Barbarian land units except for Warlords, which are not aboard a ship:
	if unit.owner.id == 0 and unit.type.domain == domain.Land and tileutil.getTerrainId(unit.location) ~= MMTERRAIN.Sea then
		if unit.location.city ~= nil then
			-- First set of rules is for barbarian units that activate in one of their own cities:
			local otherDefenders = 0
			local otherWarlords = 0
			for otherUnit in unit.location.units do
				if otherUnit.id ~= unit.id then
					if otherUnit.type.defense > 0 then
						otherDefenders = otherDefenders + 1
					end
					if otherUnit.type.role == 6 then
						otherWarlords = otherWarlords + 1
					end
				end
			end
			if unit.type.role == 6 then
				-- Each city is permitted to hold at most one Warlord (they often flee to cities for safety and accumulate there):
				if otherWarlords > 0 then
					unitutil.deleteUnit(unit)
				end
			elseif otherDefenders < math.max(unit.location.city.size, constant.mmBarbarians.CITY_DEFENDERS_MIN) then
				-- If the city currently has insufficient defenders, the current unit will fortify and not move, since the barbarians
				--		tend to provide insufficient defense for their cities (which makes them easy pickings, especially for AI nations due to their bonuses)
				-- Exception: if the unit is best suited to attacking, and a human or AI unit is adjacent to the city, do not prevent them from attacking
				local enableAttack = false
				if unit.type.attack > unit.type.defense then
					for _, adjTile in ipairs(tileutil.getAdjacentTiles(unit.location, false)) do
						if civ.isTile(adjTile) then
							for potentialTarget in adjTile.units do
								if potentialTarget.owner ~= Barbarians then
									enableAttack = true
									break
								end
							end
						end
					end
				end
				if enableAttack == false then
					unit.moveSpent = unit.type.move
					log.action("Set remaining movement to 0 for " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y)
					unitutil.fortifyUnit(unit)
				end
			end
			-- If it starts its turn within, or passes through, a friendly city and is permitted to leave it, the unit will be allowed to leave with no check for potential deletion
		elseif unit.type.role ~= 6 then
			local targetTile = getClosestBarbarianTarget(unit.location, true, true)
			-- It would be nice to send the unit towards the identified target via a GoTo order, but after testing, barbarian units
			--		ignore values set into unit.gotoTile; they seem to have their own logic
			if targetTile == nil then
				local randomNumber = math.random(100)
				log.info("No valid target for Barbarian; disbandPct = " .. constant.mmBarbarians.NO_VALID_ROUTE_DISBAND_PCT .. ", randomNumber = " .. randomNumber)
				if randomNumber <= constant.mmBarbarians.NO_VALID_ROUTE_DISBAND_PCT then
					unitutil.deleteUnit(unit)
				end
			end
		end
	end
end

local function isBarbarianOnlyUnitType (unittype)
	log.trace()
	-- NOTE: this identifies units that *only* appear as barbarians.
	-- Some other unit types will *sometimes* appear as barbarians, but are also buildable by human or AI tribes.

	local isBarbarianOnly = false
	if INVADER_UNITS[unittype.id] ~= nil or
	   unittype == MMUNIT.Privateer or
	   unittype == MMUNIT.Warlord then
		isBarbarianOnly = true
	end
	return isBarbarianOnly
end

local function setBarbarianTreasuryAndResearch()
	log.trace()
	local numBarbCities = 0
	for city in civ.iterateCities() do
		if city.owner == Barbarians then
			numBarbCities = numBarbCities + 1
		end
	end
	local newBarbTreasuryAmount = (numBarbCities + 1) * constant.mmBarbarians.TREASURY_GOLD_PER_CITY
	if Barbarians.money ~= newBarbTreasuryAmount then
		log.action("Changed barbarian treasury from " .. Barbarians.money .. " to " .. newBarbTreasuryAmount)
		Barbarians.money = newBarbTreasuryAmount
	end
	Barbarians.researchProgress = 0
end

local function spreadInvasionTech (tribe)
	log.trace()
	local invasionTechNames = {	"Berber Invasion", "Viking Invasion", "Mongol Invasion" }
	for _, invasionTechName in ipairs(invasionTechNames) do
		local invasionTech = techutil.findByName(invasionTechName, true)
		if techutil.knownByTribe(tribe, invasionTech) == false then
			if (tribeutil.getCurrentResearch(tribe) == nil and techutil.knownByAny(invasionTech)) or techutil.knownByAllOther(tribe, invasionTech) then
				local totalScholarship = tribeutil.getTotalScholarship(tribe)
				if totalScholarship > 0 then
					techutil.grantTech(tribe, invasionTech)
					if tribe.isHuman == true then
						uiutil.messageDialog(invasionTechName, "After wandering minstrels spread tales of a major " .. invasionTechName .. " in other lands, some soldiers passing through your realm provide more useful information about how other the nations of western Europe have developed successful defenses.||You have received the \"" .. invasionTechName .. "\" technology, which makes additional research options available to you.", 450)
					end
				end
			end
		end
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 17

return {
	confirmLoad = confirmLoad,

	getBarbarianActivityLevel = getBarbarianActivityLevel,
	barbarianUnitKilled = barbarianUnitKilled,
	cityTakenByBarbarians = cityTakenByBarbarians,
	cityTakenFromBarbarians = cityTakenFromBarbarians,
	createBarbarianUnits = createBarbarianUnits,
	createInvaderCities = createInvaderCities,
	disbandBarbariansLostAtSea = disbandBarbariansLostAtSea,
	fortifyDeleteOrMove = fortifyDeleteOrMove,
	isBarbarianOnlyUnitType = isBarbarianOnlyUnitType,
	processInvaderCities = processInvaderCities,
	setBarbarianTreasuryAndResearch = setBarbarianTreasuryAndResearch,
	spreadInvasionTech = spreadInvasionTech,
}
