-- mmImproveWonders.lua
-- by Knighttime

log.trace()

constant.mmImproveWonders = { }
constant.mmImproveWonders.AI_EXPECTED_MATERIALS_PER_CITIZEN = 1.334		-- Multiply this by the city size (integer) and the result is the number of Materials that an AI city is expected
																		--		to produce, AFTER it pays unit support. If it actually produces fewer Materials, the city is classified as
																		--		"needing Materials" which may lead to an event adding relevant specialists or improvements.
constant.mmImproveWonders.AI_PURCHASE_BUDGET_MAX_PCT = 50				-- This is the maximum amount of their treasury that an AI will be forced to spend on needed city specialists or improvements
																		-- 		The actual max is the *lower* of this, or the largest city's percentage of total national population
constant.mmImproveWonders.AI_PURCHASE_REQUIRES_SUPPORT_FOR_TURNS = 25	-- Some specialists and improvements require maintenance cost each turn; this many turns of maintenance
																		--		are included when comparing the cost to the budget
constant.mmImproveWonders.CITIES_LISTED_PER_PAGE = 24					-- On the [F1] overlay, the number of cities that are shown at one time. Multiple pages will be used when necessary, since
																		--		it's possible to own more cities than usable rows within a single message box. The game's [F1] city list uses
																		--		12 cities per page, so 24 is exactly twice that, leading to a small degree of visual alignment.
constant.mmImproveWonders.TRADE_FAIR_CIRCUIT_RADIUS_SEA_TILES_MAX = 4	-- Maximum number of sea tiles that are allowed within a city radius before that city is blocked from building a Trade Fair Circuit
																		--		improvement. City is also blocked if it is adjacent to *any* sea tile, so all of the tiles referenced by this constant
																		--		would have to be in the city's outer radius.
constant.mmImproveWonders.TRADE_FAIR_CIRCUITS_MAX = 6					-- Each nation can build a maximum of this many Trade Fair Circuit improvements, across all their cities
constant.mmImproveWonders.TRADE_FAIR_INCOME_PER_GOVERNMENT = 			-- The amount of gold per turn awarded by each Trade Fair Circuit varies (inversely) by the nation's current form of government
	{ [0] = 8,		-- Interregnum										--		The concept here is that nations which produce a lot of Trade already gain a smaller *additional* benefit to their economy
	  [1] = 8,		-- Primitive Monarchy								--		from each Trade Fair Circuit improvement. On the other hand, nations which are almost sure to be producing less Trade
	  [2] = 4,		-- Enlightened Monarchy								--		should find a Trade Fair Circuit to be a much more significant economic boost.
	  [3] = 4,		-- Feudal Monarchy
	  [4] = 0,		-- Tribal Monarchy
	  [5] = 4,		-- Constitutional Monarchy
	  [6] = 1 }		-- Merchant Republic
constant.mmImproveWonders.CRAFTSMEN_IMP_CITY_SIZE_MIN = 8				-- Min city size required to build the Wood/Stone Craftsmen improvement (when the construction will yield the actual improvement
																		--		and not a specialist). Min city size to build the specialists associated with this improvement are in the table below.
constant.mmImproveWonders.FOUNDRY_IMP_CITY_SIZE_MIN = 8					-- Min city size required to build the Foundry improvement (when the construction will yield the actual improvement
																		--		and not a specialist). Min city size to build the specialists associated with this improvement are in the table below.
constant.mmImproveWonders.ROMANESQUE_CATHEDRAL_LEANING_TOWER_PCT = 5	-- Percent chance that the construction of a Romanesque Cathedral will automatically give that city the Leaning Tower wonder

local SPECIALIST_TABLE = {
-- Grist Mill improvement specialists:
	-- Bakery specialist is added alongside Miller specialist
	{baseImprovement = MMIMP.GristMill,				unittype = MMUNIT.Miller,			requiresMill = false,	health = 1,		materials = 0,		cumulativeBenefit = 1,	upkeep = 0,		minCitySizeToBuild = 1},
	{baseImprovement = MMIMP.GristMill,				unittype = MMUNIT.Bakery,			requiresMill = true,	health = 1,		materials = 0,		cumulativeBenefit = 2,	upkeep = 1,		minCitySizeToBuild = 3},
	-- Building the actual Grist Mill improvement (that you keep) allows you to keep both existing specialists
-- Wood/Stone Craftsmen improvement specialists:
	-- Stonecutter specialist is added alongside Carpenter specialist
	-- Sawmill specialist replaces Carpenter specialist, and Mason specialist replaces Stonecutter specialist
	{baseImprovement = MMIMP.WoodStoneCraftsmen,	unittype = MMUNIT.Carpenter,		requiresMill = false,	health = 0,		materials = 1,		cumulativeBenefit = 1,	upkeep = 0,		minCitySizeToBuild = 1},
	{baseImprovement = MMIMP.WoodStoneCraftsmen,	unittype = MMUNIT.Stonecutter,		requiresMill = false,	health = 0,		materials = 1,		cumulativeBenefit = 2,	upkeep = 0,		minCitySizeToBuild = 2},
	{baseImprovement = MMIMP.WoodStoneCraftsmen,	unittype = MMUNIT.Sawmill,			requiresMill = true,	health = 0,		materials = 2,		cumulativeBenefit = 3,	upkeep = 1,		minCitySizeToBuild = 4},
	{baseImprovement = MMIMP.WoodStoneCraftsmen,	unittype = MMUNIT.Mason,			requiresMill = true,	health = 0,		materials = 2,		cumulativeBenefit = 4,	upkeep = 1,		minCitySizeToBuild = 6},
	-- Building the actual Craftsmen improvement (that you keep) will replace both the Sawmill and Mason specialists; requires city size >= 8
-- Foundry improvement specialists:
	-- Forge specialist replaces Smith specialist
	{baseImprovement = MMIMP.Foundry,				unittype = MMUNIT.Smith,			requiresMill = false,	health = 0,		materials = 2,		cumulativeBenefit = 2,	upkeep = 1,		minCitySizeToBuild = 2},
	{baseImprovement = MMIMP.Foundry,				unittype = MMUNIT.Forge,			requiresMill = true,	health = 0,		materials = 4,		cumulativeBenefit = 4,	upkeep = 2,		minCitySizeToBuild = 6},
	-- Building the actual Foundry improvement (that you keep) will replace the Forge specialist; requires city size >= 8
}

local IMPROVEMENT_UPKEEP = {
	[0] = 0,    -- Nothing
	[1] = 0,    -- Royal Palace
	[2] = 1,    -- Barracks
	[3] = 2,    -- Grist Mill §
	[4] = 1,    -- Basilica
	[5] = 1,    -- Marketplace
	[6] = 0,    -- Monastery §
	[7] = 1,    -- Magistrate's Office
	[8] = 1,    -- City Walls
	[9] = 1,    -- Market Town Charter
	[10] = 3,    -- Textile Mill
	[11] = 2,    -- Romanesque Cathedral
	[12] = 2,    -- Cathedral School
	[13] = 2,    -- Sewer Conduits
	[14] = 3,    -- Gothic Cathedral
	[15] = 6,    -- Wood/Stone Craftsmen §
	[16] = 6,    -- Foundry §
	[17] = 4,    -- (UNUSED-SDI) (actual)
	[18] = 2,    -- Hospital
	[19] = 0,    -- Wind Mill
	[20] = 0,    -- Water Mill
	[21] = 2,    -- (UNUSED-Nuclear Plant) (actual)
	[22] = 5,    -- Bank
	[23] = 3,    -- Free City Charter
	[24] = 2,    -- Enclosed Fields
	[25] = 0,    -- Trade Fair Circuit
	[26] = 5,    -- University
	[27] = 2,    -- Bastion Fortress
	[28] = 0,    -- Trade Fair Circuit (actual)
	[29] = 3,    -- Guildhall
	[30] = 1,    -- Fishing Fleet §
	[31] = 4,    -- Harbor Crane
	[32] = 3,    -- (UNUSED-Airport) (actual)
	[33] = 4,    -- Chivalric Tournament
	[34] = 2,    -- Shipyard
	[35] = 3,    -- (UNUSED-Transporter)
	[36] = 0,    -- Atlantic Fleet: Crew
	[37] = 0,    -- Atlantic Fleet: Sails
	[38] = 0,    -- Atlantic Fleet: Ship/Cargo
	[39] = 0,    -- [Scutage]
}

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
for key, data in pairs(SPECIALIST_TABLE) do
	if data.baseImprovement == nil then
		log.error("ERROR! For SPECIALIST_TABLE row " .. key .. ", baseImprovement is nil (not found)")
	end
	if data.unittype == nil then
		log.error("ERROR! For SPECIALIST_TABLE row " .. key .. ", unittype is nil (not found)")
	end
end
log.update("Synchronized Medieval Millennium specialists")

local function confirmLoad ()
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " loaded successfully")
	log.info("")
end

-- ===========================================================
-- ••••••••••••••• STRICTLY INTERNAL FUNCTIONS •••••••••••••••
-- ===========================================================
local function getMinCitySizeForGristMill (tribe)
	log.trace()
	local minCitySizeForGristMill = civ.cosmic.sizeSewer
	if techutil.knownByTribe(tribe, techutil.findByName("Enclosure", true)) == true then
		minCitySizeForGristMill = minCitySizeForGristMill - 2
	end
	return minCitySizeForGristMill
end

local function getSpecialistCity (specialistUnit)
	log.trace()
	local specialists = retrieve("specialists")
	for cityKey, cityData in pairs(specialists) do
		for _, specialistData in ipairs(cityData) do
			if specialistData.unitId == specialistUnit.id and specialistData.unittypeId == specialistUnit.type.id then
				local cityId = tonumber(string.sub(cityKey, 5))
				local city = civ.getCity(cityId)
				if city == nil then
					log.error("ERROR! Found specialist unitId " .. specialistUnit.id .. " for " .. cityKey .. " (" .. cityData.cityName .. ") but that city could not be found!")
				else
					return city
				end
			end
		end
	end
	return nil		-- This will happen if the unit provided as a parameter was not a valid specialist unit
end

-- A copy of this function is present in mmUnits for use there
local function hasSpecialist (specialistType, city) --> boolean, tile
	log.trace()
	local specialists = retrieve("specialists")
	local cityKey = "city" .. tostring(city.id)
	local citySpecialists = specialists[cityKey] or { }
	local specialistFound = false
	local specialistUnitId = nil
	for _, citySpecialist in ipairs(citySpecialists) do
		if citySpecialist.unittypeId == specialistType.id then
			specialistFound = true
			specialistUnitId = citySpecialist.unitId
			break
		end
	end
	local specialistLocation = nil
	if specialistUnitId ~= nil then
		local specialistUnit = civ.getUnit(specialistUnitId)
		if specialistUnit ~= nil then
			specialistLocation = specialistUnit.location
		end
	end
	return specialistFound, specialistLocation
end

local function addSpecialist (specialistType, city, unitLocation)
	log.trace()
	local tribe = city.owner
	local createAsUnit = false
	local specialistUnitLocation = city.location
	if unitLocation ~= nil then
		specialistUnitLocation = unitLocation
		createAsUnit = true
	elseif tribe.isHuman == true then
		createAsUnit = true
	end
	local specialistHomeCity = nil
	if specialistType == MMUNIT.FishingFleet then
		specialistHomeCity = city
	end
	local createdUnitId = nil
	if createAsUnit == true then
		local createdUnit = unitutil.createByType(specialistType, tribe, specialistUnitLocation, {homeCity = specialistHomeCity})
		if createdUnit ~= nil then
			createdUnitId = createdUnit.id
		end
	end
	local specialists = retrieve("specialists")
	local cityKey = "city" .. tostring(city.id)
	local citySpecialists = specialists[cityKey] or { }
	citySpecialists.cityName = city.name
	citySpecialists.tribeId = city.owner.id
	table.insert(citySpecialists, {
		unittypeId = specialistType.id,
		unittypeName = specialistType.name,
		unitId = createdUnitId
	})
	log.update("Added specialist entry for " .. specialistType.name .. " in/for " .. city.name)
	specialists[cityKey] = citySpecialists
	store("specialists", specialists)
end

local function removeSpecialist (specialistType, city)
	-- This deletes associated specialist units, in all cases, if they exist
	-- But it does NOT delete separate Monastery and Fishing Fleet improvements as part of deleting a Monk or Fishing Fleet unit
	log.trace()
	if specialistType == nil then
		log.error("ERROR! removeSpecialist called with specialistType = nil")
	else
		local specialistUnitId = nil
		local specialists = retrieve("specialists")
		local cityKey = "city" .. tostring(city.id)
		local citySpecialists = specialists[cityKey] or { }
		local citySpecialistIdToRemove = nil
		for key, specialist in ipairs(citySpecialists) do
			if specialist.unittypeId == specialistType.id then
				citySpecialistIdToRemove = key
				specialistUnitId = specialist.unitId
				break
			end
		end
		if citySpecialistIdToRemove ~= nil then
			if specialistUnitId ~= nil then
				local unitToDelete = civ.getUnit(specialistUnitId)
				if unitToDelete ~= nil then
					if unitToDelete.type.id == specialistType.id then
						unitutil.deleteUnit(unitToDelete)
					else
						log.info("Found specialist unit ID " .. specialistUnitId .. " but it was a " .. unitToDelete.type.name .. " instead of a " .. specialistType.name .. " so it was not deleted")
					end
				else
					log.info("Specialist unit ID " .. specialistUnitId .. " was not found and therefore could not be deleted")
				end
			end
			table.remove(citySpecialists, citySpecialistIdToRemove)
			log.update("Removed specialist entry for " .. specialistType.name .. " in/for " .. city.name)
		else
			log.error("ERROR! Could not find " .. specialistType.name .. " in/for " .. city.name)
		end
		specialists[cityKey] = citySpecialists
		store("specialists", specialists)
	end
end

-- This is also called internally by cityHasMillPower() and must be defined prior to it in this file:
local function cityHasWaterMillPower (city)
	log.trace()
	local ownCistercianOrder = wonderutil.getOwner(MMWONDER.CistercianOrder) == city.owner
	local isEffectiveCistercianOrder = wonderutil.isEffective(MMWONDER.CistercianOrder) == true
	return civ.hasImprovement(city, MMIMP.WaterMill) == true or (ownCistercianOrder and isEffectiveCistercianOrder)
end

-- This is also called internally by lackOfMillPowerIsBlocker() and must be defined prior to it in this file:
local function cityHasMillPower (city)
	log.trace()
	local hasWaterMillPower = cityHasWaterMillPower(city) == true
	return hasWaterMillPower or civ.hasImprovement(city, MMIMP.WindMill) == true
end

local function cityHasCathedralWonder (city)
	log.trace()
	return MMWONDER.IconicRomanesqueCathedral.city == city or
		   MMWONDER.OpulentRomanesqueCathedral.city == city or
		   MMWONDER.GloriousGothicCathedral.city == city or
		   MMWONDER.MajesticGothicCathedral.city == city or
		   MMWONDER.BrunelleschisDome.city == city
end

local function cityHasRomanesqueChurchBuilding (city)
	log.trace()
	return civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == true or
		   MMWONDER.IconicRomanesqueCathedral.city == city or
		   MMWONDER.OpulentRomanesqueCathedral.city == city
	-- Does *not* check for MMWONDER.MagnificentCluniacAbbey since it would be permissible to have both this and a Romanesque Cathedral in the same city
end

-- A copy of this function is present in mmUnits for use there
local function cityHasRomanesqueCathedralBenefit (city)
	log.trace()
	if civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == true then
		return true
	else
		if wonderutil.getOwner(MMWONDER.IconicRomanesqueCathedral) == city.owner and wonderutil.isEffective(MMWONDER.IconicRomanesqueCathedral) == true then
			return true
		else
			return false
		end
	end
end

local function cityHasGothicChurchBuilding (city)
 	log.trace()
	return civ.hasImprovement(city, MMIMP.GothicCathedral) == true or
		   MMWONDER.GloriousGothicCathedral.city == city or
		   MMWONDER.MajesticGothicCathedral.city == city
end

local function isAffordableForAI (tribe, descriptionText, buildCostMaterials, storedCityMaterials, maintCostPerTurnGold, budgetGold)
	log.trace()
	local canAfford = false
	local useMaterials = 0
	local useGold = 0
	local adjustedBuildCostMaterials = buildCostMaterials * cityutil.getShieldColumns(tribe, humanIsSupreme())
	if adjustedBuildCostMaterials <= (storedCityMaterials + (budgetGold / constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR)) then
		useMaterials = math.min(adjustedBuildCostMaterials, storedCityMaterials)
		useGold = (adjustedBuildCostMaterials - useMaterials) * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR
		local remainingBudgetGold = budgetGold - useGold
		if (maintCostPerTurnGold * constant.mmImproveWonders.AI_PURCHASE_REQUIRES_SUPPORT_FOR_TURNS) <= remainingBudgetGold then
			canAfford = true
		else
			useMaterials = 0
			useGold = 0
		end
	end
	log.info(descriptionText .. ": " .. adjustedBuildCostMaterials .. "m + " .. maintCostPerTurnGold .. "gpt, canAfford = " .. tostring(canAfford) .. " using " .. useMaterials .. "m, " .. useGold .. "g; available = " .. storedCityMaterials .. "m, " .. budgetGold .. "g")
	return canAfford, useMaterials, useGold
end

local function millImprovementBuilt (city)
	log.trace()
	if wonderutil.getOwner(MMWONDER.DomesdayBook) == city.owner and		-- There is no check for whether the Domesday book is "effective" because it is always expired instantly when built
	   hasSpecialist(MMUNIT.Miller, city) == true and hasSpecialist(MMUNIT.Bakery, city) == false then
		addSpecialist(MMUNIT.Bakery, city)
	end
end

local function monasteryImprovementBuilt (city)
	log.trace()
	local tribe = city.owner
	local candidateTiles = { }
	-- Rules that are always true:
	--		1. A monastery cannot be built on a tile that contains another city, or is within the city radius of another city (of any tribe, including your own)
	--		2. A monastery cannot be built on a tile that contains a castle (fortress)
	--		3. A monastery cannot be built on Mountain or Urban terrain
	-- Round 1: former/abandoned monastery (terrain type is monastery but no monks)
	for _, tile in pairs(tileutil.getCityRadiusTiles(city, false)) do
		if civ.isTile(tile) and
		   tileutil.isWithinOtherCityRadius(tile, city) == false and
		   tileutil.getTerrainId(tile) == MMTERRAIN.Monastery and
		   unitutil.isValidUnitLocation(MMUNIT.Monks, tribe, tile) == true then
			local tileHasMonks = false
			for otherUnit in tile.units do
				if otherUnit.type == MMUNIT.Monks then
					tileHasMonks = true
					break
				end
			end
			if tileHasMonks == false then
				log.info(tile.x .. "," .. tile.y .. " is a former monastery")
				table.insert(candidateTiles, tile)
			end
		end
	end
	-- Round 2: unimproved land tiles in outer radius
	if #candidateTiles == 0 then
		for _, tile in pairs(tileutil.getCityOuterRadiusTiles(city)) do
			if civ.isTile(tile) then
				if tileutil.isLandTile(tile) == true and
				   tileutil.hasCity(tile) == false and
				   hasCastle(tile) == false and
				   tileutil.hasFarm(tile) == false and
				   tileutil.hasIrrigation(tile) == false and
				   tileutil.hasMine(tile) == false and
				   tileutil.isWithinOtherCityRadius(tile, city) == false and
				   tileutil.getTerrainId(tile) ~= MMTERRAIN.Mountains and
				   tileutil.getTerrainId(tile) ~= MMTERRAIN.Monastery and
				   tileutil.getTerrainId(tile) ~= MMTERRAIN.Urban and
				   unitutil.isValidUnitLocation(MMUNIT.Monks, tribe, tile) == true then
					log.info(tile.x .. "," .. tile.y .. " is a candidate")
					table.insert(candidateTiles, tile)
				end
			end
		end
	end
	-- Round 3: unimproved adjacent land tile
	if #candidateTiles == 0 then
		for _, tile in ipairs(tileutil.getAdjacentTiles(city.location, false)) do
			if civ.isTile(tile) then
				if tileutil.isLandTile(tile) == true and
				   tileutil.hasCity(tile) == false and
				   hasCastle(tile) == false and
				   tileutil.hasFarm(tile) == false and
				   tileutil.hasIrrigation(tile) == false and
				   tileutil.hasMine(tile) == false and
				   tileutil.isWithinOtherCityRadius(tile, city) == false and
				   tileutil.getTerrainId(tile) ~= MMTERRAIN.Mountains and
				   tileutil.getTerrainId(tile) ~= MMTERRAIN.Monastery and
				   tileutil.getTerrainId(tile) ~= MMTERRAIN.Urban and
				   unitutil.isValidUnitLocation(MMUNIT.Monks, tribe, tile) == true then
					log.info(tile.x .. "," .. tile.y .. " is a candidate")
					table.insert(candidateTiles, tile)
				end
			end
		end
	end
	-- Round 4: improved land tile anywhere in city radius
	if #candidateTiles == 0 then
		for _, tile in pairs(tileutil.getCityRadiusTiles(city, false)) do
			if civ.isTile(tile) then
				if tileutil.isLandTile(tile) == true and
				   tileutil.hasCity(tile) == false and
				   hasCastle(tile) == false and
				   tileutil.isWithinOtherCityRadius(tile, city) == false and
				   tileutil.getTerrainId(tile) ~= MMTERRAIN.Mountains and
				   tileutil.getTerrainId(tile) ~= MMTERRAIN.Monastery and
				   tileutil.getTerrainId(tile) ~= MMTERRAIN.Urban and
				   unitutil.isValidUnitLocation(MMUNIT.Monks, tribe, tile) == true then
					log.info(tile.x .. "," .. tile.y .. " is a candidate")
					table.insert(candidateTiles, tile)
				end
			end
		end
	end
	if #candidateTiles > 0 then
		local randomKey = math.random(#candidateTiles)
		local destinationTile = candidateTiles[randomKey]
		if tileutil.getTerrainId(destinationTile) == MMTERRAIN.Monastery then
			log.info("Found abandoned monastery nearby at " .. destinationTile.x .. "," .. destinationTile.y)
			addSpecialist(MMUNIT.Monks, city, destinationTile)
			if tribe.isHuman == true then
				civ.ui.centerView(destinationTile)
				uiutil.messageDialog("Monastery", "Monks have once again occupied the|abandoned monastery at " ..
					destinationTile.x .. "," .. destinationTile.y .. ".", 350)
			end
		else
			log.action("Converted nearby tile at " .. destinationTile.x .. "," .. destinationTile.y .. " from " ..
				MMTERRAIN[tileutil.getTerrainId(destinationTile)] .. " to Monastery")
			tileutil.removeFarm(destinationTile)
			tileutil.removeIrrigation(destinationTile)
			tileutil.removeMine(destinationTile)
			tileutil.removePollution(destinationTile)
			setTerrainType(destinationTile, MMTERRAIN.Monastery, true)
			addSpecialist(MMUNIT.Monks, city, destinationTile)
			if tribe.isHuman == true then
				civ.ui.centerView(destinationTile)
				uiutil.messageDialog("Monastery", "The city of " .. city.name .. " has donated nearby land at " ..
					destinationTile.x .. "," .. destinationTile.y .. " to a new monastery, and monks have taken up residence there.")
			end
			-- Tile can't contain units belonging to another tribe, or it would fail the unitutil.isValidUnitLocation() check
			-- But if it contains one or more units (of your own tribe) capable of altering the terrain, cancel the unit(s) orders
			--		and relocate them to the city
			for unit in destinationTile.units do
				if unit.type.role == 5 then
					unitutil.clearOrders(unit)
					unitutil.teleportUnit(unit, city.location)
					if tribe.isHuman == true then
						uiutil.messageDialog(unit.type.name .. " Relocated", "A " .. unit.type.name .. " that was present on the donated land has returned to " .. city.name .. ".")
					end
				end
			end
		end
	else
		log.info("No tile in the city radius is eligible to be converted to a Monastery")
		addSpecialist(MMUNIT.Monks, city)
		if tribe.isHuman == true then
			civ.ui.centerView(city.location)
			uiutil.messageDialog("Monastery", "The city of " .. city.name ..
				" has constructed a new monastery within the city itself, and monks have taken up residence there.")
		end
	end
end

local impBuildCriteriaMet = {
	[MMIMP.RoyalPalace.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then return true else return false end
		end,
	[MMIMP.Barracks.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then return true else return false end
		end,
	[MMIMP.GristMill.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				-- Deliberately not checking imp.prereq since this is SPECIAL which no tribe will have
				local currentCumulativeBenefit = 0
				local nextConstructionRowKey = nil
				for rowKey, data in ipairs(SPECIALIST_TABLE) do
					if data.baseImprovement == imp then
						if hasSpecialist(data.unittype, city) == true then
							currentCumulativeBenefit = data.cumulativeBenefit
							nextConstructionRowKey = nil
						elseif nextConstructionRowKey == nil then
							nextConstructionRowKey = rowKey
						end
					end
				end
				if nextConstructionRowKey ~= nil then
					-- Next construction would be a specialist
					if city.size >= SPECIALIST_TABLE[nextConstructionRowKey].minCitySizeToBuild and
					   (SPECIALIST_TABLE[nextConstructionRowKey].requiresMill == false or cityHasMillPower(city) == true) then
						return true
					else
						return false
					end
				else
					-- Next construction would be the actual improvement
					if (civ.hasImprovement(city, MMIMP.RoyalPalace) or
						city.size >= getMinCitySizeForGristMill(city.owner) or
						wonderutil.getOwner(MMWONDER.DomesdayBook) == city.owner) and	-- There is no check for whether the Domesday book is "effective" because it is always expired instantly when built
					   cityHasMillPower(city) == true then
						return true
					else
						return false
					end
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.Basilica.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then return true else return false end
		end,
	[MMIMP.Marketplace.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then return true else return false end
		end,
	[MMIMP.Monastery.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then return true else return false end
		end,
	[MMIMP.MagistratesOffice.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   civ.hasImprovement(city, MMIMP.RoyalPalace) == false and
				   civ.hasImprovement(city, MMIMP.MarketTownCharter) == true then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.CityWalls.id] = function (defaultBuildFunction, city, imp)
			-- Ownership of Offa's Dyke does not prevent you from building City Walls, since Offa's Dyke eventually expires
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then return true else return false end
		end,
	[MMIMP.MarketTownCharter.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   city.size >= (civ.cosmic.sizeAquaduct - 1) then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.TextileMill.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   civ.hasImprovement(city, MMIMP.Marketplace) == true and
				   civ.hasImprovement(city, MMIMP.MarketTownCharter) == true and
				   cityHasMillPower(city) == true then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.RomanesqueCathedral.id] = function (defaultBuildFunction, city, imp)
			-- Ownership of Iconic Romanesque Cathedral does not prevent you from building Romanesque Cathedral, since Iconic Romanesque Cathedral eventually expires
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   MMWONDER.IconicRomanesqueCathedral.city ~= city and
				   MMWONDER.OpulentRomanesqueCathedral.city ~= city and
				   cityHasGothicChurchBuilding(city) == false then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.CathedralSchool.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   (cityHasRomanesqueCathedralBenefit(city) == true or
				    cityHasGothicChurchBuilding(city) == true) then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.SewerConduits.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then
					if civ.hasImprovement(city, MMIMP.FreeCityCharter) == true then
						local hasAdjacentWater = city.coastal
						if hasAdjacentWater == false then
							for _, tile in ipairs(tileutil.getAdjacentTiles(city, true)) do
								if civ.isTile(tile) and tileutil.hasRiver(tile) then
									hasAdjacentWater = true
									break
								end
							end
						end
						if hasAdjacentWater == true then
							return true
						else
							return false
						end
					else
						return false
					end
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.GothicCathedral.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then return true else return false end
		end,
	[MMIMP.WoodStoneCraftsmen.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then
					local currentCumulativeBenefit = 0
					local nextConstructionRowKey = nil
					for rowKey, data in ipairs(SPECIALIST_TABLE) do
						if data.baseImprovement == imp then
							if hasSpecialist(data.unittype, city) == true then
								currentCumulativeBenefit = data.cumulativeBenefit
								nextConstructionRowKey = nil
							elseif nextConstructionRowKey == nil then
								nextConstructionRowKey = rowKey
							end
						end
					end
					if nextConstructionRowKey ~= nil then
						-- Next construction would be a specialist
						if city.size >= SPECIALIST_TABLE[nextConstructionRowKey].minCitySizeToBuild and
						   (SPECIALIST_TABLE[nextConstructionRowKey].requiresMill == false or cityHasMillPower(city) == true) then
							return true
						else
							return false
						end
					else
						-- Next construction would be the actual improvement
						local expectedBenefit = math.floor(city.totalShield / 2) * 2		-- Because of mill power, improvement gives a 50% * 2 shield boost instead of base 50%
						if civ.hasImprovement(city, MMIMP.Foundry) == true then
							expectedBenefit = math.floor(round(city.totalShield / 2) / 2)	-- If you already have the Foundry improvement, mill power boost is already accounted for
						end
						log.info("Craftsmen imp: currentCumulativeBenefit = " .. currentCumulativeBenefit .. ", expectedBenefit = " .. expectedBenefit)
						if city.size >= constant.mmImproveWonders.CRAFTSMEN_IMP_CITY_SIZE_MIN and
						   cityHasMillPower(city) == true and
						   civ.hasTech(city.owner, techutil.findByName("Guilds", true)) == true and
						   (city.owner.isHuman == true or expectedBenefit > currentCumulativeBenefit) then
							return true
						else
							return false
						end
					end
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.Foundry.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then
					local currentCumulativeBenefit = 0
					local nextConstructionRowKey = nil
					for rowKey, data in ipairs(SPECIALIST_TABLE) do
						if data.baseImprovement == imp then
							if hasSpecialist(data.unittype, city) == true then
								currentCumulativeBenefit = data.cumulativeBenefit
								nextConstructionRowKey = nil
							elseif nextConstructionRowKey == nil then
								nextConstructionRowKey = rowKey
							end
						end
					end
					if nextConstructionRowKey ~= nil then
						-- Next construction would be a specialist
						if city.size >= SPECIALIST_TABLE[nextConstructionRowKey].minCitySizeToBuild and
						   ( SPECIALIST_TABLE[nextConstructionRowKey].requiresMill == false or
							 (cityHasMillPower(city) == true and civ.hasTech(city.owner, techutil.findByName("Catalan Forges", true)) == true)
						   ) then
							return true
						else
							return false
						end
					else
						-- Next construction would be the actual improvement
						local expectedBenefit = math.floor(city.totalShield / 2) * 2		-- Because of mill power, improvement gives a 50% * 2 shield boost instead of base 50%
						if civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) == true then
							expectedBenefit = math.floor(round(city.totalShield / 2) / 2)	-- If you already have the Craftsmen improvement, mill power boost is already accounted for
						end
						log.info("Foundry imp: currentCumulativeBenefit = " .. currentCumulativeBenefit .. ", expectedBenefit = " .. expectedBenefit)
						if city.size >= constant.mmImproveWonders.FOUNDRY_IMP_CITY_SIZE_MIN and
						   cityHasMillPower(city) == true and
						   civ.hasTech(city.owner, techutil.findByName("Blast Furnace", true)) == true and
						   (city.owner.isHuman == true or expectedBenefit > currentCumulativeBenefit) then
							return true
						else
							return false
						end
					end
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[17] = function (defaultBuildFunction, city, imp)
			-- Improvement 17 (SDI Defense) not in game
			return false
		end,
	[MMIMP.Hospital.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   (civ.hasImprovement(city, MMIMP.Monastery) == true or
				    civ.hasImprovement(city, MMIMP.FreeCityCharter) == true) then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.WindMill.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   civ.hasImprovement(city, MMIMP.WaterMill) == false and
				   not(wonderutil.getOwner(MMWONDER.CistercianOrder) == city.owner and wonderutil.isEffective(MMWONDER.CistercianOrder) == true) then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.WaterMill.id] = function (defaultBuildFunction, city, imp)
			-- Ownership of Cistercian Order prevents you from building Water Mill, since Cistercian Order never expires
			-- Note that this *is* available to build even if you already have a Wind Mill, because this can lower pollution
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				-- Deliberately not checking imp.prereq since this is SPECIAL which no tribe will have
				if not(wonderutil.getOwner(MMWONDER.CistercianOrder) == city.owner and wonderutil.isEffective(MMWONDER.CistercianOrder) == true) then
					local hasAdjacentWater = cityIsTrulyCoastal(city)						-- A large enough body of adjacent water permits a tidal mill
					if hasAdjacentWater == false then
						for _, tile in ipairs(tileutil.getAdjacentTiles(city, true)) do
							if civ.isTile(tile) and tileutil.hasRiver(tile) then			-- An adjacent river allows a traditional Water Mill
								hasAdjacentWater = true
								break
							end
						end
					end
					if hasAdjacentWater == true then
						return true
					else
						return false
					end
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[21] = function (defaultBuildFunction, city, imp)
			-- Improvement 21 (Nuclear Plant) not in game
			return false
		end,
	[MMIMP.Bank.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   civ.hasImprovement(city, MMIMP.Marketplace) == true and
				   civ.hasImprovement(city, MMIMP.FreeCityCharter) == true then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.FreeCityCharter.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if civ.hasImprovement(city, MMIMP.MarketTownCharter) and
				(
					-- Option 1:
					( ( imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true ) and
					  ( city.owner.government == MMGOVERNMENT.EnlightenedMonarchy or
						city.owner.government == MMGOVERNMENT.ConstitutionalMonarchy or
						city.owner.government == MMGOVERNMENT.MerchantRepublic ) and
					  city.size >= (civ.cosmic.sizeSewer - 2) ) or
					-- Option 2:
					( civ.hasImprovement(city, MMIMP.RoyalPalace) == true and
					  city.size >= civ.cosmic.sizeSewer ) or
					-- Option 3:
					( civ.hasImprovement(city, MMIMP.RoyalPalace) == true and
					  ( city.owner.government == MMGOVERNMENT.EnlightenedMonarchy or
						city.owner.government == MMGOVERNMENT.ConstitutionalMonarchy or
						city.owner.government == MMGOVERNMENT.MerchantRepublic ) and
					  city.size >= (civ.cosmic.sizeSewer - 2) )
				) then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.EnclosedFields.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   civ.hasImprovement(city, MMIMP.GristMill) == true then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.TradeFairCircuit.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, MMIMP.TradeFairCircuitActual) == false then
				if imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then
					local numTribeImpsFound = 0
					for altCity in civ.iterateCities() do
						if altCity.owner == city.owner then
							if altCity.id ~= city.id and civ.hasImprovement(altCity, MMIMP.TradeFairCircuitActual) then
								numTribeImpsFound = numTribeImpsFound + 1
							end
						end
					end
					local seaTilesInCityRadius = 0
					for _, tile in pairs(tileutil.getCityRadiusTiles(city)) do
						if civ.isTile(tile) and tileutil.getTerrainId(tile) == MMTERRAIN.Sea then
							seaTilesInCityRadius = seaTilesInCityRadius + 1
						end
					end
					if civ.hasImprovement(city, MMIMP.Marketplace) == true and
					   civ.hasImprovement(city, MMIMP.MarketTownCharter) == true and
					   numTribeImpsFound < constant.mmImproveWonders.TRADE_FAIR_CIRCUITS_MAX and
					   cityIsTrulyCoastal(city) == false and
					   seaTilesInCityRadius <= constant.mmImproveWonders.TRADE_FAIR_CIRCUIT_RADIUS_SEA_TILES_MAX then
						return true
					else
						return false
					end
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.University.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   city.size >= 8 and
				   civ.hasImprovement(city, MMIMP.CathedralSchool) == true and
				   not(wonderutil.getOwner(MMWONDER.IconicUniversity) == city.owner and wonderutil.isEffective(MMWONDER.IconicUniversity) == true) then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.BastionFortress.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   civ.hasImprovement(city, MMIMP.CityWalls) == true then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.TradeFairCircuitActual.id] = function (defaultBuildFunction, city, imp)
			return false
		end,
	[MMIMP.Guildhall.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) == true and
				   civ.hasImprovement(city, MMIMP.FreeCityCharter) == true then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.FishingFleet.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				-- Deliberately not checking imp.prereq since this is SPECIAL which no tribe will have
				if city.coastal == true and
				   ( civ.hasTech(city.owner, techutil.findByName("Carvel Shipbuilding", true)) == true or
					 civ.hasTech(city.owner, techutil.findByName("Clinker Shipbuilding", true)) == true ) then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[MMIMP.HarborCrane.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and
				   civ.hasImprovement(city, MMIMP.MarketTownCharter) == true and
				   cityIsTrulyCoastal(city) == true then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[32] = function (defaultBuildFunction, city, imp)
			-- Improvement 32 (Airport) not in game
			return false
		end,
	[MMIMP.ChivalricTournament.id] = function (defaultBuildFunction, city, imp)
			-- Ownership of King's Holy Land Crusade does not prevent you from building Chivalric Tournament, since King's Holy Land Crusade "expires" under Merchant Republic
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then return true else return false end
		end,
	[MMIMP.Shipyard.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction == nil or civ.hasImprovement(city, imp) == false then
				-- Deliberately not checking imp.prereq since this is SPECIAL which no tribe will have
				if ( civ.hasTech(city.owner, techutil.findByName("Carvel Shipbuilding", true)) == true or
					 civ.hasTech(city.owner, techutil.findByName("Clinker Shipbuilding", true)) == true ) and
				   cityIsTrulyCoastal(city) == true then
					return true
				else
					return false
				end
			else
				-- i.e., defaultBuildFunction ~= nil and civ.hasImprovement(city, imp) == true
				return false
			end
		end,
	[35] = function (defaultBuildFunction, city, imp)
			-- Improvement 35 (Transporter) not in game
			return false
		end,
	[MMIMP.AtlanticFleetCrew.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and wonderutil.hasBeenBuilt(MMWONDER.SeaRoutetoIndia) and city.owner.spaceship.launched == false then
				return true
			else
				return false
			end
		end,
	[MMIMP.AtlanticFleetSails.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and wonderutil.hasBeenBuilt(MMWONDER.SeaRoutetoIndia) and city.owner.spaceship.launched == false then
				return true
			else
				return false
			end
		end,
	[MMIMP.AtlanticFleetShipCargo.id] = function (defaultBuildFunction, city, imp)
			if (imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true) and wonderutil.hasBeenBuilt(MMWONDER.SeaRoutetoIndia) and city.owner.spaceship.launched == false and
			   cityIsTrulyCoastal(city) == true then
				return true
			else
				return false
			end
		end,
	[MMIMP.Scutage.id] = function (defaultBuildFunction, city, imp)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, imp)
			elseif imp.prereq == nil or civ.hasTech(city.owner, imp.prereq) == true then return true else return false end
		end
}

local wonderBuildCriteriaMet = {
	[MMWONDER.DomesdayBook.id] = function (defaultBuildFunction, city, wonder)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, wonder)
			elseif wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true then return true else return false end
		end,
	[MMWONDER.GloriousGothicCathedral.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   civ.hasImprovement(city, MMIMP.GothicCathedral) == false and
			   MMWONDER.IconicRomanesqueCathedral.city ~= city and
			   MMWONDER.OpulentRomanesqueCathedral.city ~= city and
			   MMWONDER.MajesticGothicCathedral.city ~= city and
			   MMWONDER.BrunelleschisDome.city ~= city then
				return true
			else
				return false
			end
		end,
	[MMWONDER.HanseaticLeagueCapital.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   civ.hasImprovement(city, MMIMP.HarborCrane) == true then
				return true
			else
				return false
			end
		end,
	[MMWONDER.CommemorativeTapestry.id] = function (defaultBuildFunction, city, wonder)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, wonder)
			elseif wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true then return true else return false end
		end,
	[MMWONDER.PilgrimmageRoute.id] = function (defaultBuildFunction, city, wonder)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, wonder)
			elseif wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true then return true else return false end
		end,
	[MMWONDER.PalatineChapel.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   civ.hasImprovement(city, MMIMP.RoyalPalace) == true then
				return true
			else
				return false
			end
		end,
	[MMWONDER.OffasDyke.id] = function (defaultBuildFunction, city, wonder)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, wonder)
			elseif wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true then return true else return false end
		end,
	[MMWONDER.WhiteTowerFortress.id] = function (defaultBuildFunction, city, wonder)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, wonder)
			elseif wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true then return true else return false end
		end,
	[MMWONDER.NavalIndustrialArsenal.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   cityIsTrulyCoastal(city) == true then
				return true
			else
				return false
			end
		end,
	[MMWONDER.TravelsofMarcoPolo.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   city ~= nil and city.owner.government ~= MMGOVERNMENT.TribalMonarchy then
				return true
			else
				return false
			end
		end,
	[MMWONDER.IconicRomanesqueCathedral.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == false and
			   cityHasGothicChurchBuilding(city) == false and
			   MMWONDER.OpulentRomanesqueCathedral.city ~= city and
			   MMWONDER.BrunelleschisDome.city ~= city then
				return true
			else
				return false
			end
		end,
	[MMWONDER.SchoolofMedicine.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   civ.hasImprovement(city, MMIMP.Monastery) == true then
				return true
			else
				return false
			end
		end,
	[MMWONDER.MountofStMichael.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   cityIsTrulyCoastal(city) == true then
				return true
			else
				return false
			end
		end,
	[MMWONDER.DecoratedOctagonalBasilica.id] = function (defaultBuildFunction, city, wonder)
			-- Deliberately not checking wonder.prereq since this is SPECIAL which no tribe will have
			if civ.hasTech(city.owner, techutil.findByName("Byzantine Influence", true)) == true and
			   civ.hasTech(city.owner, techutil.findByName("Catholic Christianity", true)) == true and
			   civ.hasTech(city.owner, techutil.findByName("Wood/Stone Craftsmanship", true)) == true then
				return true
			else
				return false
			end
		end,
	[MMWONDER.BrunelleschisDome.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   MMWONDER.IconicRomanesqueCathedral.city ~= city and
			   MMWONDER.OpulentRomanesqueCathedral.city ~= city and
			   MMWONDER.GloriousGothicCathedral.city ~= city and
			   MMWONDER.MajesticGothicCathedral.city ~= city then
				return true
			else
				return false
			end
		end,
	[MMWONDER.OpulentRomanesqueCathedral.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == false and
			   cityHasGothicChurchBuilding(city) == false and
			   MMWONDER.IconicRomanesqueCathedral.city ~= city and
			   MMWONDER.BrunelleschisDome.city ~= city then
				return true
			else
				return false
			end
		end,
	[MMWONDER.MagnificentCluniacAbbey.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   cityHasGothicChurchBuilding(city) == false and
			   MMWONDER.CistercianOrder.city ~= city and
			   civ.hasImprovement(city, MMIMP.Monastery) == true then
				return true
			else
				return false
			end
		end,
	[MMWONDER.MediciBank.id] = function (defaultBuildFunction, city, wonder)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, wonder)
			elseif wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true then return true else return false end
		end,
	[MMWONDER.OrnateGospelBook.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   civ.hasImprovement(city, MMIMP.Monastery) == true then
				return true
			else
				return false
			end
		end,
	[MMWONDER.GreatCharter.id] = function (defaultBuildFunction, city, wonder)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, wonder)
			elseif wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true then return true else return false end
		end,
	[MMWONDER.HolyRomanEmperor.id] = function (defaultBuildFunction, city, wonder)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, wonder)
			elseif wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true then return true else return false end
		end,
	[MMWONDER.KingsHolyLandCrusade.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   city.owner.government ~= MMGOVERNMENT.MerchantRepublic then
				return true
			else
				return false
			end
		end,
	[MMWONDER.CistercianOrder.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   MMWONDER.MagnificentCluniacAbbey.city ~= city and
			   civ.hasImprovement(city, MMIMP.Monastery) == true then
				local hasAdjacentWater = cityIsTrulyCoastal(city)
				if hasAdjacentWater == false then
					for _, tile in ipairs(tileutil.getAdjacentTiles(city, true)) do
						if civ.isTile(tile) and tileutil.hasRiver(tile) then
							hasAdjacentWater = true
							break
						end
					end
				end
				if hasAdjacentWater == true then
					return true
				else
					return false
				end
			else
				return false
			end
		end,
	[MMWONDER.PalaceofthePopes.id] = function (defaultBuildFunction, city, wonder)
			if defaultBuildFunction ~= nil then return defaultBuildFunction(city, wonder)
			elseif wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true then return true else return false end
		end,
	[MMWONDER.LeaningTower.id] = function (defaultBuildFunction, city, wonder)
			-- Awarded by event but cannot be built intentionally by any nation
			if defaultBuildFunction == nil then return true else return false end
		end,
	[MMWONDER.SeaRoutetoIndia.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   cityIsTrulyCoastal(city) == true and
			   civ.getGameYear() >= 1415 then
				return true
			else
				return false
			end
		end,
	[MMWONDER.IconicUniversity.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   city.size >= 8 and
			   civ.hasImprovement(city, MMIMP.CathedralSchool) == true and
			   civ.hasImprovement(city, MMIMP.University) == false then
				return true
			else
				return false
			end
		end,
	[MMWONDER.MajesticGothicCathedral.id] = function (defaultBuildFunction, city, wonder)
			if (wonder.prereq == nil or civ.hasTech(city.owner, wonder.prereq) == true) and
			   civ.hasImprovement(city, MMIMP.GothicCathedral) == false and
			   MMWONDER.IconicRomanesqueCathedral.city ~= city and
			   MMWONDER.OpulentRomanesqueCathedral.city ~= city and
			   MMWONDER.GloriousGothicCathedral.city ~= city and
			   MMWONDER.BrunelleschisDome.city ~= city then
				return true
			else
				return false
			end
		end
}

-- =============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTION •••••••••••••••
-- =============================================================
-- This is also called internally by lackOfMillPowerIsBlocker() and providePrereqsOrSpecialistsForAI() and must be defined prior to them in this file:
local function canBuildImprovement (defaultBuildFunction, city, imp)
	log.trace()
	return impBuildCriteriaMet[imp.id](defaultBuildFunction, city, imp)
end

-- ==========================================================
-- ••••••••••••••• STRICTLY INTERNAL FUNCTION •••••••••••••••
-- ==========================================================
local function lackOfMillPowerIsBlocker (city)
	log.trace()
	local isBlocker = false
	if cityHasMillPower(city) == false then
		if civ.hasImprovement(city, MMIMP.GristMill) == false and
		   canBuildImprovement(nil, city, MMIMP.GristMill) == false and
		   hasSpecialist(MMUNIT.Miller, city) == true and
		   hasSpecialist(MMUNIT.Bakery, city) == true and
		   ( civ.hasImprovement(city, MMIMP.RoyalPalace) or
			 city.size >= getMinCitySizeForGristMill(city.owner) or
			 wonderutil.getOwner(MMWONDER.DomesdayBook) == city.owner
		   ) then
			log.info("Lack of mill power is blocking Grist Mill improvement")
			isBlocker = true
		elseif civ.hasImprovement(city, MMIMP.TextileMill) == false and
			   canBuildImprovement(nil, city, MMIMP.TextileMill) == false and
			   civ.hasTech(city.owner, MMIMP.TextileMill.prereq) == true and
			   civ.hasImprovement(city, MMIMP.Marketplace) == true and
			   civ.hasImprovement(city, MMIMP.MarketTownCharter) == true then
			log.info("Lack of mill power is blocking Textile Mill improvement")
			isBlocker = true
		elseif civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) == false and
			   canBuildImprovement(nil, city, MMIMP.WoodStoneCraftsmen) == false and
			   hasSpecialist(MMUNIT.Carpenter, city) == true and
			   hasSpecialist(MMUNIT.Stonecutter, city) == true and
			   hasSpecialist(MMUNIT.Sawmill, city) == false and
			   city.size >= 4 then
			log.info("Lack of mill power is blocking Sawmill specialist")
			isBlocker = true
		elseif civ.hasImprovement(city, MMIMP.Foundry) == false and
			   canBuildImprovement(nil, city, MMIMP.Foundry) == false and
			   hasSpecialist(MMUNIT.Smith, city) == true and
			   hasSpecialist(MMUNIT.Forge, city) == false and
			   civ.hasTech(city.owner, techutil.findByName("Catalan Forges", true)) == true and
			   city.size >= 6 then
			log.info("Lack of mill power is blocking Forge specialist")
			isBlocker = true
		end
	end
	return isBlocker
end

-- ==========================================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS (continued) •••••••••••••••
-- ==========================================================================
local function canBuildWonder (defaultBuildFunction, city, wonder)
	log.trace()
	-- The game won't permit any wonder to be completed more than once
	-- This first check is therefore to eliminate completed wonders from appearing in the list of build options:
	if wonderutil.hasBeenBuilt(wonder) == true then
		return false
	else
		-- All wonder criteria are stored in a table of functions, which allows the criteria to be referenced at multiple points in time
		--		and from different functions.
		return wonderBuildCriteriaMet[wonder.id](defaultBuildFunction, city, wonder)
	end
end

local function closeBasilicas ()
	log.trace()
	local tribe = civ.getPlayerTribe()
	local closeableBasilicas = { }
	for city in civ.iterateCities() do
		if city.owner == tribe and civ.hasImprovement(city, MMIMP.Basilica) and
		   (cityHasRomanesqueCathedralBenefit(city) or civ.hasImprovement(city, MMIMP.GothicCathedral)) then
			table.insert(closeableBasilicas, city)
		end
	end
	local dialog = civ.ui.createDialog()
	dialog.title = "Close Basilicas"
	dialog.width = 600
	local dialogText = "A Basilica may not be sold, but it may be closed if the city in which it is located contains a Cathedral, or is receiving the benefit of one via a wonder. This will remove it (and its normal benefit) from that city, and you will no longer pay upkeep for it each turn.||"
	if #closeableBasilicas == 0 then
		dialogText = dialogText .. "No Basilicas in any of your cities are currently eligible to be closed."
		uiutil.addTextToDialog(dialog, dialogText)
	else
		dialogText = dialogText .. "Select the cities in which you wish to close the Basilica:"
		uiutil.addTextToDialog(dialog, dialogText)
		for key, city in ipairs(closeableBasilicas) do
			dialog:addCheckbox(city.name, key)
		end
	end
	log.action("Dialog box displayed")
	local result = dialog:show()
	local basilicasRemoved = 0
	if result == 0 then
		for key, city in ipairs(closeableBasilicas) do
			if dialog:getCheckboxState(key) == true then
				imputil.removeImprovement(city, MMIMP.Basilica)
				basilicasRemoved = basilicasRemoved + 1
			end
		end
	end
	local messageText = basilicasRemoved .. " Basilicas in " .. tribe.name .. " have been permanently closed."
	if basilicasRemoved == 1 then
		messageText = basilicasRemoved .. " Basilica in " .. tribe.name .. " has been permanently closed."
	end
	uiutil.messageDialog("Close Basilicas", messageText)
end

-- This is also called internally by processCustomImproveWonderBenefits(), as well as being called directly from Events.lua
-- It gathers the total tax benefits available due to improvements and wonders, both for actual processing and for the human player to review their own tribe's data
-- Compare to getTotalSpecialistCosts() below
local function getCustomImproveWonderBenefits (tribe, dataTable)
	log.trace()
	for city in civ.iterateCities() do
		if city.owner == tribe then
			if civ.hasImprovement(city, MMIMP.TradeFairCircuit) == true then
				-- This should not be possible
				log.error(city.owner.adjective .. " city of " .. city.name .. " has the list-only version of Trade Fair Circuit which should not be possible. This improvement has been removed.")
				imputil.removeImprovement(city, MMIMP.TradeFairCircuit)
			end
			if civ.hasImprovement(city, MMIMP.TradeFairCircuitActual) == true and constant.mmImproveWonders.TRADE_FAIR_INCOME_PER_GOVERNMENT[tribe.government] > 0 then
				local impData = dataTable[MMIMP.TradeFairCircuitActual.id] or { }
				local previousQty = impData.quantity or 0
				impData.quantity = previousQty + 1
				impData.name = MMIMP.TradeFairCircuitActual.name
				impData.tax = constant.mmImproveWonders.TRADE_FAIR_INCOME_PER_GOVERNMENT[tribe.government]
				dataTable[MMIMP.TradeFairCircuitActual.id] = impData
			end
			if MMWONDER.LeaningTower.city == city then
				local wonderBenefit = 0
				if civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == true then
					wonderBenefit = wonderBenefit + IMPROVEMENT_UPKEEP[MMIMP.RomanesqueCathedral.id]
				end
				if civ.hasImprovement(city, MMIMP.CathedralSchool) == true then
					wonderBenefit = wonderBenefit + IMPROVEMENT_UPKEEP[MMIMP.CathedralSchool.id]
				end
				if civ.hasImprovement(city, MMIMP.GothicCathedral) == true then
					wonderBenefit = wonderBenefit + IMPROVEMENT_UPKEEP[MMIMP.GothicCathedral.id]
				end
				if wonderBenefit > 0 then
					local wonderData = { }
					wonderData.name = MMWONDER.LeaningTower.name .. " wonder"
					wonderData.tax = wonderBenefit
					dataTable[MMWONDER.LeaningTower.id + 40] = wonderData
				end
			end
		end
	end
end

-- Note that this function doesn't take a tribe as a parameter, and always returns the specialist costs for the *human* player
-- This is not used when actually processing specialists, but only when generating data for the human player to review concerning their own tribe.
-- Compare to getCustomImproveWonderBenefits() above
local function getTotalSpecialistCosts (dataTable)
	log.trace()
	local specialists = retrieve("specialists")
	for city in civ.iterateCities() do
		if city.owner.isHuman == true then
			for _, specialist in ipairs(SPECIALIST_TABLE) do
				local requiredUpkeep = specialist.upkeep
				if requiredUpkeep == 1 and wonderutil.getOwner(MMWONDER.MediciBank) == city.owner and wonderutil.isEffective(MMWONDER.MediciBank) == true then
					requiredUpkeep = 0
				end
				if requiredUpkeep > 0 and hasSpecialist(specialist.unittype, city) == true then
					local specialistData = dataTable[specialist.unittype.id] or { }
					specialistData.name = specialist.unittype.name
					specialistData.cost = requiredUpkeep
					local previousQty = specialistData.quantity or 0
					specialistData.quantity = previousQty + 1
					dataTable[specialist.unittype.id] = specialistData
				end
			end
		end
	end
end

local function improvementBuilt (city, imp)
	log.trace()
	local tribe = city.owner

	local buildApproved = true
	if tribe.isHuman == true then
		buildApproved = impBuildCriteriaMet[imp.id](nil, city, imp)
	end
	if buildApproved == false then
		imputil.removeImprovement(city, imp)
		uiutil.messageDialog("Chief Justiciar", "Sire, I regret to inform you that a serious problem has come to my attention. I truly believed we were ready to complete the " .. imp.name .. " in " .. city.name .. ", but unfortunately this city does not fulfill all necessary requirements for this project. Please review the situation and provide instructions for how to proceed. (We may need to revise our plans and select a different project instead.)")
		local itemCost = imp.cost * civ.cosmic.shieldRows
		city.shields = itemCost
		log.action("Set Materials to " .. itemCost .. " in " .. tribe.adjective .. " city of " .. city.name)
	else
		if imp == MMIMP.GristMill then
			if hasSpecialist(MMUNIT.Bakery, city) == true then
				-- Do not remove any specialists, keep improvement
			elseif hasSpecialist(MMUNIT.Miller, city) == true then
				-- Create Bakery specialist, remove improvement
				addSpecialist(MMUNIT.Bakery, city)
				imputil.removeImprovement(city, imp)
			else
				-- Create Miller specialist
				addSpecialist(MMUNIT.Miller, city)
				-- If city belongs to tribe that has the Domesday Book wonder plus mill power, also create Bakery specialist
				if wonderutil.getOwner(MMWONDER.DomesdayBook) == tribe and 		-- There is no check for whether the Domesday book is "effective" because it is always expired instantly when built
				   cityHasMillPower(city) == true then
					addSpecialist(MMUNIT.Bakery, city)
				end
				-- Remove improvement
				imputil.removeImprovement(city, imp)
			end
		elseif imp == MMIMP.Marketplace then
			-- A capital city gets a free Market Town Charter if it builds a Marketplace
			if civ.hasImprovement(city, MMIMP.RoyalPalace) == true and civ.hasImprovement(city, MMIMP.MarketTownCharter) == false then
				imputil.addImprovement(city, MMIMP.MarketTownCharter)
				if city.owner.isHuman == true then
					uiutil.messageDialog(city.name .. " is a Market Town", "The addition of a Marketplace within the capital city of " .. city.name .. " automatically grants it a Market Town Charter. This improvement has been added to the city.", 360)
				end
			end
		elseif imp == MMIMP.Monastery then
			-- Pulled out into an internal function so it can also be called from providePrereqsOrSpecialistsForAI()
			monasteryImprovementBuilt(city)
		elseif imp == MMIMP.RomanesqueCathedral then
			if MMWONDER.LeaningTower.city == nil and MMWONDER.LeaningTower.destroyed == false then
				local randomNumber = math.random(100)
				log.info("Leaning Tower pct = " .. constant.mmImproveWonders.ROMANESQUE_CATHEDRAL_LEANING_TOWER_PCT .. ", randomNumber = " .. randomNumber)
				if randomNumber <= constant.mmImproveWonders.ROMANESQUE_CATHEDRAL_LEANING_TOWER_PCT then
					uiutil.messageDialog("Archbishop's Report", "Architects and church leaders in the " .. tribe.adjective .. " city of " .. city.name .. " are concerned that the free-standing bell tower (campanile) adjacent to their new " .. MMIMP.RomanesqueCathedral.name .. " is leaning at a precarious angle! However, this is turning out to be a blessing in disguise: the tower is quickly becoming famous and attracting visitors from far and wide. It may even be one of the wonders of the world!||" .. city.name .. " receives " .. MMWONDER.LeaningTower.name .. " wonder.", 480)
					MMWONDER.LeaningTower.city = city
				end
			end
		elseif imp == MMIMP.WoodStoneCraftsmen then
			if hasSpecialist(MMUNIT.Mason, city) == true then
				-- Remove Mason and Sawmill specialists, keep improvement
				removeSpecialist(MMUNIT.Mason, city)
				removeSpecialist(MMUNIT.Sawmill, city)
			elseif hasSpecialist(MMUNIT.Sawmill, city) == true then
				-- Upgrade Stonecutter specialist to Mason specialist, remove improvement
				removeSpecialist(MMUNIT.Stonecutter, city)
				addSpecialist(MMUNIT.Mason, city)
				imputil.removeImprovement(city, imp)
			elseif hasSpecialist(MMUNIT.Stonecutter, city) == true then
				-- Upgrade Carpenter specialist to Sawmill specialist, remove improvement
				removeSpecialist(MMUNIT.Carpenter, city)
				addSpecialist(MMUNIT.Sawmill, city)
				imputil.removeImprovement(city, imp)
			elseif hasSpecialist(MMUNIT.Carpenter, city) == true then
				-- Create Stonecutter specialist, remove improvement
				addSpecialist(MMUNIT.Stonecutter, city)
				imputil.removeImprovement(city, imp)
			else
				-- Create Carpenter specialist, remove improvement
				addSpecialist(MMUNIT.Carpenter, city)
				imputil.removeImprovement(city, imp)
			end
		elseif imp == MMIMP.Foundry then
			if hasSpecialist(MMUNIT.Forge, city) == true then
				-- Remove Forge specialist, keep improvement
				removeSpecialist(MMUNIT.Forge, city)
			elseif hasSpecialist(MMUNIT.Smith, city) == true then
				-- Upgrade Smith specialist to Forge specialist, remove improvement
				removeSpecialist(MMUNIT.Smith, city)
				addSpecialist(MMUNIT.Forge, city)
				imputil.removeImprovement(city, imp)
			else
				-- Create Smith specialist, remove improvement
				addSpecialist(MMUNIT.Smith, city)
				imputil.removeImprovement(city, imp)
			end
		elseif imp == MMIMP.WindMill then
			-- Pulled out into an internal function so it can also be called from providePrereqsOrSpecialistsForAI()
			millImprovementBuilt(city)
		elseif imp == MMIMP.WaterMill then
			-- Pulled out into an internal function so it can also be called from providePrereqsOrSpecialistsForAI()
			millImprovementBuilt(city)
		elseif imp == MMIMP.TradeFairCircuit then
			-- Take away the improvement they just finished, which appears in the list but is never truly buildable, and replace it with the intended one:
			imputil.removeImprovement(city, imp)
			imputil.addImprovement(city, MMIMP.TradeFairCircuitActual)
		elseif imp == MMIMP.TradeFairCircuitActual then
			-- This should not be possible
			log.error(city.owner.adjective .. " city of " .. city.name .. " built the event-managed version of Trade Fair Circuit which should not be possible. This improvement has been removed.")
			imputil.removeImprovement(city, imp)
		elseif imp == MMIMP.FishingFleet then
			local adjacentTiles = tileutil.getAdjacentTiles(city.location, false)

			local adjacentTilePreferenceOrder = { 7, 8, 3, 2, 9, 6, 4, 1}
			local destinationTile = nil
			for _, preferred in ipairs(adjacentTilePreferenceOrder) do
				if civ.isTile(adjacentTiles[preferred]) == true and
				   unitutil.isValidUnitLocation(MMUNIT.FishingFleet, tribe, adjacentTiles[preferred]) == true then
					destinationTile = adjacentTiles[preferred]
					break
				end
			end
			if destinationTile ~= nil then
				addSpecialist(MMUNIT.FishingFleet, city, destinationTile)
			else
				log.info("Could not create " .. MMUNIT.FishingFleet.name .. " unit on a sea tile adjacent to " .. city.name .. "!")
				imputil.removeImprovement(city, imp)
				city.shields = imp.cost * cityutil.getShieldColumns(tribe, humanIsSupreme())
				log.action("Reset production box in " .. city.name .. " to " .. city.shields .. " Materials")
				if tribe.isHuman == true then
					uiutil.messageDialog("Game Concept: " .. imp.name, city.name .. " is unable to build a " .. imp.name .. " because it does not currently control any adjacent sea tiles.")
				end
			end
		end
	end
end

-- This is also called internally by wonderBuilt(), as well as being called directly from Events.lua
local function setConstitutionalMonarchyExpiration ()
	log.trace()
	if wonderutil.hasBeenBuilt(MMWONDER.GreatCharter) then
		MMWONDER.GreatCharter.expires = techutil.findByName("Constitutional Monarchy", true)
		log.action("Set expiration of " .. MMWONDER.GreatCharter.name .. " as Constitutional Monarchy")
	end
end

local function wonderBuilt (city, wonder)
	log.trace()
	local tribe = city.owner

	local buildApproved = true
	if tribe.isHuman == true then
		buildApproved = wonderBuildCriteriaMet[wonder.id](nil, city, wonder)
	end
	if buildApproved == false then
		wonder.city = nil
		log.action("Removed " .. wonder.name .. " wonder from " .. tribe.adjective .." city of " .. city.name)
		uiutil.messageDialog("Chief Justiciar", "Sire, I regret to inform you that a serious problem has come to my attention. I truly believed we were ready to complete the " .. wonder.name .. " in " .. city.name .. ", but unfortunately this city does not fulfill all necessary requirements for this project. Please review the situation and provide instructions for how to proceed. (We may need to revise our plans and select a different project instead.)")
		local itemCost = wonder.cost * civ.cosmic.shieldRows
		city.shields = itemCost
		log.action("Set Materials to " .. itemCost .. " in " .. tribe.adjective .. " city of " .. city.name)
	else
		if wonder == MMWONDER.DomesdayBook then
			-- Give the tech that makes this wonder expire, to negate its standard effect
			techutil.grantTech(tribe, wonder.expires)
			if tribe.isHuman == true then
				uiutil.messageDialog("Domesday Book Clarification", "The original (base) effect of this wonder has been canceled, in order to override this with custom effects via Lua events. The wonder will correctly provide all benefits as stated in the Civilopedia.||All other nations will receive the knowledge of " .. wonder.expires.name .. " as well.", 420)
			end
			-- By giving it to all tribes, it makes sure that it stays expired even if the tribe that builds it is eliminated from the game (unsure if necessary, but can't hurt)
			for otherTribe in tribeutil.iterateActiveTribes(false) do
				if otherTribe ~= tribe then
					techutil.grantTech(otherTribe, wonder.expires)
				end
			end
			-- Give free Miller specialist, free Bakery specialist, and free Grist Mill improvement to the city that built the wonder
			if hasSpecialist(MMUNIT.Miller, city) == false then
				addSpecialist(MMUNIT.Miller, city)
			end
			if hasSpecialist(MMUNIT.Bakery, city) == false then
				addSpecialist(MMUNIT.Bakery, city)
			end
			if civ.hasImprovement(city, MMIMP.GristMill) == false then
				imputil.addImprovement(city, MMIMP.GristMill)
			end
			-- This wonder also provides the benefit that any city with mill power that builds a Miller gets a free Bakery, *but this is not retroactive*
			--		i.e., existing cities with a mill power and a miller don't get a bakery instantly
			-- It also provides the benefit that any city with a Miller that builds mill power gets a free Bakery
			--		This is not "retroactive" but it's possible to acquire mill power in all cities simultaneously via the Cisterician Order; see the entry below for that wonder
		elseif wonder == MMWONDER.GloriousGothicCathedral then
			-- Give a free Gothic Cathedral to the city that built the wonder
			if civ.hasImprovement(city, MMIMP.GothicCathedral) == false then
				imputil.addImprovement(city, MMIMP.GothicCathedral)
			end
		elseif wonder == MMWONDER.PilgrimmageRoute then
			-- Immediately provide the builder of this wonder with the full set of techs that are already known by two other tribes

			for tech in techutil.iterateTechs() do
				if tech.group == MMTECHGROUP.Never then
					-- Do nothing, these are special techs
				elseif techutil.knownByTribe(tribe, tech) == false and techutil.numTribesKnownBy(tech) >= 2 then
					techutil.grantTech(tribe, tech)
					uiutil.messageDialog("", tribe.name .. " acquired " .. tech.name .. " from Pilgrimmage Route!", 400)
				end
			end
		elseif wonder == MMWONDER.IconicRomanesqueCathedral then
			-- Give a free Romanesque Cathedral to the city that built the wonder
			-- This isn't needed while the wonder is active, but its affect is applied when the wonder expires
			if civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == false then
				imputil.addImprovement(city, MMIMP.RomanesqueCathedral)
			end
		elseif wonder == MMWONDER.DecoratedOctagonalBasilica then
			-- Give a free Basilica to the city that built the wonder
			-- This isn't needed while the wonder is active, but its affect is applied when the wonder expires
			if civ.hasImprovement(city, MMIMP.Basilica) == false then
				imputil.addImprovement(city, MMIMP.Basilica)
			end
		elseif wonder == MMWONDER.OpulentRomanesqueCathedral then
			-- Give a free Romanesque Cathedral to the city that built the wonder
			if civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == false then
				imputil.addImprovement(city, MMIMP.RomanesqueCathedral)
			end
		elseif wonder == MMWONDER.GreatCharter then
			-- Give all tribes the ability to research or acquire Constitutional Monarchy
			assignConstitutionalMonarchyTechGroup()
			-- Grant the following four techs to the tribe that built the wonder
			techutil.grantTechByName(tribe, "Feudalism")
			techutil.grantTechByName(tribe, "Merchant Republic")
			techutil.grantTechByName(tribe, "Enlightened Monarchy")
			techutil.grantTechByName(tribe, "Constitutional Monarchy")
			-- Change the expiration tech of the wonder so that it instantly expires

			setConstitutionalMonarchyExpiration()
			-- Give three free Yeomean units to the city that built the wonder, requiring no support
			unitutil.createByType(MMUNIT.Yeoman, tribe, city.location, {count = 3, homeCity = nil})
		elseif wonder == MMWONDER.CistercianOrder then
			-- There is a nice synchronicity with this and the Domesday Book wonder; see the entry above for that wonder
			-- This provides mill power to every city *that doesn't have it already*
			for tribeCity in civ.iterateCities() do
				if tribeCity.owner == city.owner and
				   civ.hasImprovement(tribeCity, MMIMP.WindMill) == false and
				   civ.hasImprovement(tribeCity, MMIMP.WaterMill) == false then
					-- This code should run only for cities that acquire mill power as a result of this wonder being built
					millImprovementBuilt(tribeCity)
				end
			end
		elseif wonder == MMWONDER.PalaceofthePopes then
			-- Give four free Swiss Pikeman units to the city that built the wonder, requiring no support
			unitutil.createByType(MMUNIT.SwissPikeman, tribe, city.location, {count = 4, homeCity = nil})
		elseif wonder == MMWONDER.SeaRoutetoIndia then
			uiutil.messageDialog("Complete Map of Europe", "Now that the entire map of Europe has been revealed, you may have visibility to more barbarian units. If it is taking a long time for them to move each turn, remember that you can hold down the [Shift] key to make the moves instantaneous. (This might mean that you fail to notice moves which are actually significant, however.)")
			-- Mark all tiles on the map as visible to the human player, so that [Backspace] help works for them
			for tileId, thisTileData in pairs(db.tileData) do
				thisTileData.visible = true
			end
		elseif wonder == MMWONDER.MajesticGothicCathedral then
			-- Give a free Gothic Cathedral to the city that built the wonder
			if civ.hasImprovement(city, MMIMP.GothicCathedral) == false then
				imputil.addImprovement(city, MMIMP.GothicCathedral)
			end
		end
	end
end

local function isCitySpecialistUnitType (unittype)
	log.trace()
	local isCitySpecialist = false
	for _, data in pairs(SPECIALIST_TABLE) do
		if data.unittype == unittype then
			isCitySpecialist = true
			break
		end
	end
	return isCitySpecialist
end

local function isSpecialistUnitType (unittype)
	log.trace()
	local isSpecialist = isCitySpecialistUnitType (unittype)
	if unittype == MMUNIT.Monks or unittype == MMUNIT.FishingFleet then
		isSpecialist = true
	end
	return isSpecialist
end

local function listCityImprovementStatus ()
	log.trace()
	local humanTribe = civ.getPlayerTribe()
	local showImpPage = 1

	repeat
		local staticOptions = { [0] = "EXIT" }
		local pagedOptions = { }
		for improvement in imputil.iterateImprovements() do
			if improvement.id >= 2 and improvement.id <= 34 and string.find(improvement.name, "UNUSED") == nil and
			   (improvement.prereq == nil or improvement.prereq.name == "SPECIAL" or techutil.knownByTribe(humanTribe, improvement.prereq) == true) and
			   improvement ~= MMIMP.TradeFairCircuit  then
				pagedOptions[improvement.id] = improvement.name
			end
		end
		local impResult = 0
		impResult, showImpPage = uiutil.optionDialog("Select a City Improvement", nil, 360, staticOptions, pagedOptions, 26, showImpPage)
		local improvement = civ.getImprovement(impResult)
		if impResult ~= 0 and improvement ~= nil then
			local messageHeader = "Report of " .. improvement.name .. " locations"
			local columnTable = {
				{label = "builtSize", align = "right"},			{label = "builtCity"},									{label = "builtSpace"},
				{label = "possibleSize", align = "right"},		{label = "possibleCity"},	{label = "possibleYield"},	{label = "possibleSpace"},
				{label = "unsupportedSize", align = "right"},	{label = "unsupportedCity"}
			}
			local dataTable = { {
				builtSize = "–––",			builtCity = "BUILT   –––",										builtSpace = "    ",
				possibleSize = "–––",		possibleCity = "POSSIBLE",				possibleYield = "–––",	possibleSpace = "    ",
				unsupportedSize = "–––",	unsupportedCity = "UNAVAILABLE   –––"
			} }
			-- These are initialized to 1 in order to account for the header row:
			local builtCount = 1
			local possibleCount = 1
			local unsupportedCount = 1
			for city in civ.iterateCities() do
				if city.owner == humanTribe then
					local tableRows = math.max(builtCount, possibleCount, unsupportedCount)
					local sizeValue = tostring(city.size)
					if improvement == MMIMP.Marketplace or improvement == MMIMP.TextileMill or improvement == MMIMP.Bank or
					   improvement == MMIMP.Monastery or improvement == MMIMP.CathedralSchool or improvement == MMIMP.University then
						sizeValue = sizeValue .. " : " .. tostring(city.totalTrade)
					elseif improvement == MMIMP.MagistratesOffice then
						sizeValue = sizeValue .. " : " .. tostring(cityutil.getCorruption(city))
					end
					if civ.hasImprovement(city, improvement) == true then
						builtCount = builtCount + 1
						if builtCount > tableRows then
							table.insert(dataTable, {
								builtSize = sizeValue,	builtCity = city.name,							builtSpace = " ",
								possibleSize = " ",		possibleCity = " ",		possibleYield = " ",	possibleSpace = " ",
								unsupportedSize = " ",	unsupportedCity = " "
							})
						else
							dataTable[builtCount].builtSize = sizeValue
							dataTable[builtCount].builtCity = city.name
						end
					else
						local testBuildImprovement = improvement
						if improvement == MMIMP.TradeFairCircuitActual then
							testBuildImprovement = MMIMP.TradeFairCircuit
						end
						if canBuildImprovement(nil, city, testBuildImprovement) == true then
							local yield = " "
							if improvement == MMIMP.GristMill then
								if hasSpecialist(MMUNIT.Miller, city) == false then
									yield = MMUNIT.Miller.name .. " (I)"
								elseif hasSpecialist(MMUNIT.Bakery, city) == false then
									yield = MMUNIT.Bakery.name .. " (II)"
								end
							elseif improvement == MMIMP.WoodStoneCraftsmen then
								yield = MMUNIT.Carpenter.name .. " (I)"
								if hasSpecialist(MMUNIT.Carpenter, city) == true then yield = MMUNIT.Stonecutter.name .. " (II)" end
								if hasSpecialist(MMUNIT.Stonecutter, city) == true then yield = MMUNIT.Sawmill.name .. " (III)" end
								if hasSpecialist(MMUNIT.Sawmill, city) == true then yield = MMUNIT.Mason.name .. " (IV)" end
								if hasSpecialist(MMUNIT.Mason, city) == true then yield = " " end
							elseif improvement == MMIMP.Foundry then
								yield = MMUNIT.Smith.name .. " (I)"
								if hasSpecialist(MMUNIT.Smith, city) == true then yield = MMUNIT.Forge.name .. " (II)" end
								if hasSpecialist(MMUNIT.Forge, city) == true then yield = " " end
							end
							possibleCount = possibleCount + 1
							if possibleCount > tableRows then
								table.insert(dataTable, {
									builtSize = " ",			builtCity = " ",									builtSpace = " ",
									possibleSize = sizeValue,	possibleCity = city.name,	possibleYield = yield,	possibleSpace = " ",
									unsupportedSize = " ",		unsupportedCity = " "
								})
							else
								dataTable[possibleCount].possibleSize = sizeValue
								dataTable[possibleCount].possibleCity = city.name
								dataTable[possibleCount].possibleYield = yield
							end
						else
							unsupportedCount = unsupportedCount + 1
							if unsupportedCount > tableRows then
								table.insert(dataTable, {
									builtSize = " ",				builtCity = " ",									builtSpace = " ",
									possibleSize = " ",				possibleCity = " ",			possibleYield = " ",	possibleSpace = " ",
									unsupportedSize = sizeValue,	unsupportedCity = city.name
								})
							else
								dataTable[unsupportedCount].unsupportedSize = sizeValue
								dataTable[unsupportedCount].unsupportedCity = city.name
							end
						end
					end
				end
			end
			uiutil.messageDialog(messageHeader, uiutil.convertTableToMessageText(columnTable, dataTable, 4), 480)
		end
	until
		impResult == 0
end

local function listNetHealthAndMaterials ()
	log.trace()
	local tribeGov = tribeutil.getCurrentGovernmentData(civ.getPlayerTribe(), MMGOVERNMENT)
	local columnTable = {
		{label = "size", align = "right"},
		{label = "name"},
		{label = "status", align = "center"},
		{label = "line1", align = "center"},
		{label = "healthBase", align = "right"},
		{label = "healthSpec", align = "right"},
		{label = "healthEvnt", align = "right"},
		{label = "healthTot", align = "right"},
		{label = "healthSupp", align = "right"},
		{label = "healthNet", align = "right"},
		{label = "line2", align = "center"},
		{label = "matBase", align = "right"},
		{label = "matSpec", align = "right"},
		{label = "matTot", align = "right"},
		{label = "matSupp", align = "right"},
		{label = "matNet", align = "right"}
	}
	local specialists = retrieve("specialists")
	local specialistFound = false
	local dataTable = { }
	local citiesFound = 0
	local page = 0
	local newPage = false
	local totalCitizens = 0
	local totalNetHealth = 0
	local totalNetMaterials = 0

	for city in civ.iterateCities() do
		if city.owner.isHuman == true then

			citiesFound = citiesFound + 1
			if citiesFound % constant.mmImproveWonders.CITIES_LISTED_PER_PAGE == 1 then
				page = page + 1
				newPage = true
			end
			if newPage == true then
				dataTable[page] = { }
				table.insert(dataTable[page], {size = " ",	name = " ",			status = " ",
					line1 = "¦",	healthBase = "––––",	healthSpec = "––––",	healthEvnt = "––––",	healthTot = "HLTH",	healthSupp = "––––",	healthNet = "––––",
					line2 = " ¦",	matBase = "––––",		matSpec = "––––",	 							matTot = "MTRL",	matSupp = "––––",		matNet = "––––"})
				table.insert(dataTable[page], {size = "SIZE", name = "CITY",			status = "STATUS",
					line1 = "¦",	healthBase = "BASE",	healthSpec = "SPEC",	healthEvnt = "EVNT",	healthTot = "TOT",		healthSupp = "SUP",	healthNet = "NET",
					line2 = " ¦",	matBase = "BASE",		matSpec = "SPEC",	 							matTot = "TOT",	 		matSupp = "SUP",		matNet = "NET"})
				newPage = false
			end

			totalCitizens = totalCitizens + city.size

			local moraleStatus = " "
			if cityutil.hasAttributeWeLoveTheKing(city) == true then
				moraleStatus = "Celeb"
			elseif cityutil.hasAttributeCivilDisorder(city) == true then
				moraleStatus = "Riot"
			end
			local healthGainEvents = getExpectedHealthBenefitForCity(city)

			local healthGainSpec = 0
			local materialsGainSpec = 0
			for _, specialist in ipairs(SPECIALIST_TABLE) do
				specialistFound = true
				if hasSpecialist(specialist.unittype, city) == true then
					healthGainSpec = healthGainSpec + specialist.health
					materialsGainSpec = materialsGainSpec + specialist.materials
				end
			end

			local healthGainSpecString = " "
			if healthGainSpec > 0 then
				if moraleStatus ~= "Riot" then
					healthGainSpecString = "+" .. tostring(healthGainSpec)
				else
					healthGainSpec = 0
					healthGainSpecString = "n/a"
				end
			end
			if civ.hasImprovement(city, MMIMP.GristMill) then
				healthGainSpecString = healthGainSpecString .. "*"
			end
			local healthGainEventsString = " "
			if healthGainEvents > 0 then
				healthGainEventsString = "+" .. tostring(healthGainEvents)
			end
			local peasantHealth = cityutil.getNumSettlersSupported(city) * tribeGov.settlersEat
			local peasantHealthString = " "
			if peasantHealth > 0 then
				peasantHealthString = "-" .. tostring(peasantHealth)
			end
			local netHealth = city.totalFood + healthGainSpec + healthGainEvents - (city.size * civ.cosmic.foodEaten) - peasantHealth
			totalNetHealth = totalNetHealth + netHealth
			local netHealthString = tostring(netHealth)
			if netHealth > 0 then
				netHealthString = "+" .. netHealthString
			end

			local materialsGainSpecString = " "
			if materialsGainSpec > 0 then
				if moraleStatus ~= "Riot" then
					materialsGainSpecString = "+" .. tostring(materialsGainSpec)
				else
					materialsGainSpec = 0
					materialsGainSpecString = "n/a"
				end
			end
			if civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) then
				materialsGainSpecString = materialsGainSpecString .. "*"
			end
			if civ.hasImprovement(city, MMIMP.Foundry) then
				materialsGainSpecString = materialsGainSpecString .. "*"
			end

			local numSupportedUnits = cityutil.getNumUnitsSupported(city)
			local freeSupportBasicGov = tribeGov.support or city.size
			-- This section rereferences three global constants defined in mmGovernments:
			if city.owner.government == MMGOVERNMENT.ConstitutionalMonarchy then
				freeSupportBasicGov = constant.mmGovernments.CONSTITUTIONAL_MONARCHY_FREE_UNITS
			end
			-- This repeats some logic from mmGovernments.applyCelebratingCityEffects()
			local freeSupportAdvancedGov = 0
			if city.owner.government == MMGOVERNMENT.ConstitutionalMonarchy and cityutil.hasAttributeWeLoveTheKing(city) == true then
				freeSupportAdvancedGov = math.min(city.numHappy, numSupportedUnits, constant.mmGovernments.CELEBRATION_CM_FREE_UNITS_MAX)
			elseif city.owner.government == MMGOVERNMENT.MerchantRepublic and cityutil.hasAttributeWeLoveTheKing(city) == true then
				freeSupportAdvancedGov = math.min(city.numHappy, numSupportedUnits, constant.mmGovernments.CELEBRATION_MR_FREE_UNITS_MAX)
			end

			local unitSupport = math.max(numSupportedUnits - freeSupportBasicGov - freeSupportAdvancedGov, 0)
			local unitSupportString = " "
			if unitSupport > 0 then
				unitSupportString = "-" .. tostring(unitSupport)
			end
			local netMaterials = city.totalShield + materialsGainSpec - unitSupport
			totalNetMaterials = totalNetMaterials + netMaterials
			local netMaterialsString = tostring(netMaterials)
			if moraleStatus == "Riot" then
				netMaterialsString = "n/a"
			end

			table.insert(dataTable[page], {
				size = tostring(city.size),
				name = city.name,
				status = moraleStatus,
				line1 = "¦",
				healthBase = tostring(city.totalFood),
				healthSpec = healthGainSpecString,
				healthEvnt = healthGainEventsString,
				healthTot = tostring(city.totalFood + healthGainSpec + healthGainEvents),
				healthSupp = peasantHealthString,
				healthNet = netHealthString,
				line2 = " ¦",
				matBase = tostring(city.totalShield),
				matSpec = materialsGainSpecString,
				matTot = tostring(city.totalShield + materialsGainSpec),
				matSupp = unitSupportString,
				matNet = netMaterialsString
			})
		end
	end
	if citiesFound > 0 then
		table.insert(dataTable[page], {			size = tostring(totalCitizens), name = "== TOTAL ==",	status = tostring(citiesFound) .. " cities",
			line1 = "¦",	healthBase = "===",	healthSpec = "===",				healthEvnt = "===",		healthTot = "===",		healthSupp = "===",	healthNet = tostring(totalNetHealth),
			line2 = " ¦",	matBase = "===",	matSpec = "===",	 									matTot = "===",	 		matSupp = "===",	matNet = tostring(totalNetMaterials)})

		if specialistFound == true then
			for showPage = 1, page do
				local messageText = "The following table includes additions to Health and Materials production that are the result of Medieval Millennium events, and therefore cannot be shown on the game's default display. It also contains columns showing unit support costs, and the resulting net gain that can be expected for both Health and Materials each turn.| " .. uiutil.convertTableToMessageText(columnTable, dataTable[showPage], 3) .. "||An asterisk in the 'SPEC' (Specialists) column reflects the presence of a Grist Mill improvement (Health),|or a Wood/Stone Craftsmen and/or Foundry improvement (Materials)."
				if showPage < page then
					messageText = messageText .. "||"
				end
				local dialog = civ.ui.createDialog()
				dialog.title = "CHIEF JUSTICIAR (Domestic Production)"
				uiutil.addTextToDialog(dialog, messageText)
				if showPage < page then
					dialog:addCheckbox("Continue to page " .. tostring(showPage + 1) .. " of " .. tostring(page), 1, true)
				end
				dialog:show()
				if dialog:getCheckboxState(1) == false then
					break
				end
			end
		end
	end
end

local function processCustomImproveWonderBenefits (tribe)
	log.trace()
	local dataTable = { }
	getCustomImproveWonderBenefits(tribe, dataTable)
	for key, value in pairs(dataTable) do
		local thisIncome = (value.quantity or 1) * value.tax
		log.action("Processing income of " .. thisIncome .. " gold from " .. tostring(value.quantity or 1) .. " " .. value.name)
		tribeutil.changeMoney (tribe, thisIncome)
	end
end

local function processSpecialistBenefits ()
	log.trace()
	local startTimestamp = os.clock()
	for city in civ.iterateCities() do
		local tribe = city.owner
		if cityutil.hasAttributeCivilDisorder(city) == true then
			log.info(city.name .. " is in Civil Disorder, specialists not processed")
		else
			for _, specialist in ipairs(SPECIALIST_TABLE) do
				if hasSpecialist(specialist.unittype, city) == true then
					-- The following line could arguably be log.info, but as action it serves as an explanatory heading for the legitimate actions which follow
					log.action(specialist.unittype.name .. " detected in " .. city.name .. " (+" .. specialist.health .. " health, +" .. specialist.materials .. " Materials, -" .. specialist.upkeep .. " gold)")
					local requiredUpkeep = specialist.upkeep
					local paidUpkeep = false
					if requiredUpkeep == 1 and wonderutil.getOwner(MMWONDER.MediciBank) == tribe and wonderutil.isEffective(MMWONDER.MediciBank) == true then
						requiredUpkeep = 0
						log.info(specialist.unittype.name .. " upkeep reduced to 0 gold due to " .. MMWONDER.MediciBank.name)
					end
					if requiredUpkeep == 0 then
						paidUpkeep = true
					elseif tribe.money >= requiredUpkeep then
						tribeutil.changeMoney(tribe, (requiredUpkeep * -1))
						paidUpkeep = true
					else
						-- i.e., requiredUpkeep > 0 and tribe.money < requiredUpkeep
						messageText = tribe.adjective .. " treasury is unable to fund the operation of the " .. specialist.unittype.name .. " in " .. city.name
						log.info(messageText)
						if tribe.isHuman == true then
							-- AI has no way to delete specialists it can't afford, but the human can sell or downgrade specialists with an upkeep cost
							-- The human also can understand the costs of these and adjust treasury balance and/or income to compensate
							-- Therefore, for the human player, any specialists you can't pay simply do nothing that turn, and a popup appears pointing this out
							civ.ui.centerView(city.location)
							uiutil.messageDialog("Treasurer", "I'm dismayed to report that the " .. messageText .. ".", 450)
						else
							-- But for the AI, the specialist is reduced back by one layer
							-- They receive as compensation the cost it took to build it,
							--		plus a bonus to account for the newly reduced specialist which won't actually be processed until next turn

							-- Because the downgraded specialist will not be processed this turn, *also* give the AI the benefit of the downgraded specialist *in gold* this turn
							local specialistValue = specialist.unittype.cost * cityutil.getShieldColumns(tribe, humanIsSupreme())
							if specialist.unittype == MMUNIT.Bakery then
								-- This could leave them with a large Grist Mill improvement, no Bakery, and a Miller

								removeSpecialist(specialist.unittype, city)
								tribeutil.changeMoney(tribe, specialistValue)
							elseif specialist.unittype == MMUNIT.Sawmill then
								-- This is complicated. If they have both a Sawmill and a Mason, but can't afford either, we will process the sawmill first
								-- If we downgrade it to a Carpenter, then they will be able to pay their Mason, leaving their specialists out of order
								-- Therefore, if they have a Mason, we will downgrade *that* to a Stonecutter instead, and thus be able to pay the Sawmill
								-- If they do not have a Mason, we are safe to downgrade the Sawmill
								if hasSpecialist(MMUNIT.Mason, city) == true then
									removeSpecialist(MMUNIT.Mason, city)
									tribeutil.changeMoney(tribe, specialistValue)	-- Value of the Sawmill and Mason should be the same so this is OK
									addSpecialist(MMUNIT.Stonecutter, city)
									tribeutil.changeMoney(tribe, 1 * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR)	-- 1 is hardcoded value of .materials for Stonecutter
									-- Now they *are* able to pay the Sawmill:
									tribeutil.changeMoney(tribe, (specialist.upkeep * -1))
									paidUpkeep = true
									-- Sawmill benefit will be provided below
								else
									removeSpecialist(specialist.unittype, city)
									tribeutil.changeMoney(tribe, specialistValue)
									addSpecialist(MMUNIT.Carpenter, city)
									tribeutil.changeMoney(tribe, 1 * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR)	-- 1 is hardcoded value of .materials for Carpenter
								end
							elseif specialist.unittype == MMUNIT.Mason then
								removeSpecialist(specialist.unittype, city)
								tribeutil.changeMoney(tribe, specialistValue)
								addSpecialist(MMUNIT.Stonecutter, city)
								tribeutil.changeMoney(tribe, 1 * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR)		-- 1 is hardcoded value of .materials for Stonecutter
							elseif specialist.unittype == MMUNIT.Smith then
								removeSpecialist(specialist.unittype, city)
								tribeutil.changeMoney(tribe, specialistValue)
								-- This can't be downgraded further, so no specialist is added in its place
							elseif specialist.unittype == MMUNIT.Forge then
								removeSpecialist(specialist.unittype, city)
								tribeutil.changeMoney(tribe, specialistValue)
								-- We will downgrade this to a Smith, which they *also* may not able to afford, but we will analyze that next turn and deal with it then
								addSpecialist(MMUNIT.Smith, city)
								tribeutil.changeMoney(tribe, (2 * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR) - 1)		-- 2 is hardcoded value of .materials and
																																-- 1 is hardcoded value of .upkeep, both for Smith
							end
						end
					end
					if paidUpkeep == true then
						if specialist.health > 0 then

							cityutil.changeFood(city, specialist.health, humanIsSupreme())
						end
						if specialist.materials > 0 then
							-- Because this function is called from civ.scen.onTurn(), it runs at the time the turn number increments, before any tribe plays.
							--		Therefore, it's permissible to add Materials even to an empty production box, since there isn't the potential of a pending
							--		change to the currently-produced item (which could cause a 50% loss in accumulated Materials).
							cityutil.changeShields(city, specialist.materials)
						end
					end
				end
			end
		end
	end
	log.info("processSpecialistBenefits() completed in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")
end

local function providePrereqsOrSpecialistsForAI (tribe)
	log.trace()
	if tribe.isHuman == false then
		local startTimestamp = os.clock()
		local largestCitySize = 0
		local nationalCitizens = 0
		for city in civ.iterateCities() do
			if city.owner == tribe then
				if city.size > largestCitySize then
					largestCitySize = city.size
				end
				nationalCitizens = nationalCitizens + city.size
			end
		end
		local budgetGold = round(tribe.money * math.min(constant.mmImproveWonders.AI_PURCHASE_BUDGET_MAX_PCT / 100, largestCitySize / nationalCitizens))
		log.info(tribe.adjective .. " treasury: " .. tribe.money .. "; budgetGold: " .. budgetGold)

		for city in civ.iterateCities() do
			if city.owner == tribe then
				local currentMaterialsForConstruction = city.totalShield
				for _, specialist in ipairs(SPECIALIST_TABLE) do
					if hasSpecialist(specialist.unittype, city) == true then
						currentMaterialsForConstruction = currentMaterialsForConstruction + specialist.materials
					end
				end
				local paysSupportForUnits = 0
				for unit in civ.iterateUnits() do
					if unit.owner == tribe and unit.homeCity == city and unit.type.role <= 5 then
						paysSupportForUnits = paysSupportForUnits + 1
					end
				end
				local tribeGov = tribeutil.getCurrentGovernmentData(tribe, MMGOVERNMENT)
				local freeUnitsForGovernment = tribeGov.support or city.size
				paysSupportForUnits = math.max(paysSupportForUnits - freeUnitsForGovernment, 0)
				currentMaterialsForConstruction = currentMaterialsForConstruction - paysSupportForUnits
				local needsMaterials = false
				if currentMaterialsForConstruction < round(city.size * constant.mmImproveWonders.AI_EXPECTED_MATERIALS_PER_CITIZEN) then
					needsMaterials = true
				end
				log.info("Processing " .. city.name .. " (size: " .. city.size .. ", storedMaterials: " .. city.shields .. ", needsMaterials = " .. tostring(needsMaterials) .. ":" .. currentMaterialsForConstruction ..")")

				-- Any improvements added this way do *NOT* fire the onCityProduction() trigger or (therefore) the improvementBuilt() function here
				-- Any ancillary effects or actions that should accompany an improvement's creation need to be explicitly managed, e.g. see calls to millImprovementBuilt() and monasteryImprovementBuilt()

				local canAfford = false
				local useMaterials = 0
				local useGold = 0

				-- 0. After the acquisition of Gunpowder or cannon-related techs which follow, priority is given to Smith, Forge, and Foundry
				--	  The criteria of "needsMaterials == true" is not included, since these are built not because the city needs Materials, but because it needs the ability
				--			to build [large[r]] cannons
				--	  There are separate checks below for Smith and Forge under all other circumstances, which have a lower priority by virtue of being checked later,
				--			but this is the only check for the Foundry improvement itself
				if civ.hasTech(tribe, techutil.findByName("Gunpowder", true)) or
				   civ.hasTech(tribe, techutil.findByName("Primitive Cannons", true)) or
				   civ.hasTech(tribe, techutil.findByName("Blast Furnace", true)) or
				   civ.hasTech(tribe, techutil.findByName("Bombards", true)) or
				   civ.hasTech(tribe, techutil.findByName("Corned Gunpowder", true)) or
				   civ.hasTech(tribe, techutil.findByName("Trunnions / Limbers", true)) or
				   civ.hasTech(tribe, techutil.findByName("Gun Decks", true)) then
					-- 0a. Smith specialist
					canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Smith", MMIMP.Foundry.cost, city.shields, 1, budgetGold)	-- 1 is hardcoded value of .upkeep for Smith
					if canAfford == true and
					   -- needsMaterials == true and
					   civ.hasImprovement(city, MMIMP.Foundry) == false and
					   canBuildImprovement(nil, city, MMIMP.Foundry) == true and
					   hasSpecialist(MMUNIT.Smith, city) == false and
					   hasSpecialist(MMUNIT.Forge, city) == false then
						addSpecialist(MMUNIT.Smith, city)
						if useMaterials ~= 0 then
							cityutil.changeShields(city, useMaterials * -1)
						end
						if useGold ~= 0 then
							tribeutil.changeMoney(tribe, useGold * -1)
						end
						break
					end
					-- 0b. Forge specialist
					canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Forge", MMIMP.Foundry.cost, city.shields, 1, budgetGold)	-- 1 is hardcoded difference between .upkeep for Forge and .upkeep for Smith
					if canAfford == true and
					   -- needsMaterials == true and
					   civ.hasImprovement(city, MMIMP.Foundry) == false and
					   canBuildImprovement(nil, city, MMIMP.Foundry) == true and
					   hasSpecialist(MMUNIT.Smith, city) == true and
					   hasSpecialist(MMUNIT.Forge, city) == false then
						removeSpecialist(MMUNIT.Smith, city)
						addSpecialist(MMUNIT.Forge, city)
						if useMaterials ~= 0 then
							cityutil.changeShields(city, useMaterials * -1)
						end
						if useGold ~= 0 then
							tribeutil.changeMoney(tribe, useGold * -1)
						end
						break
					end
					-- 0c. Foundry improvement
					canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Foundry", MMIMP.Foundry.cost, city.shields, IMPROVEMENT_UPKEEP[MMIMP.Foundry.id] - 2, budgetGold)	-- 2 is hardcoded value of .upkeep for Forge
					if canAfford == true and
					   -- needsMaterials == true and
					   civ.hasImprovement(city, MMIMP.Foundry) == false and
					   canBuildImprovement(nil, city, MMIMP.Foundry) == true and
					   hasSpecialist(MMUNIT.Forge, city) == true then
						removeSpecialist(MMUNIT.Forge, city)
						imputil.addImprovement(city, MMIMP.Foundry)
						if useMaterials ~= 0 then
							cityutil.changeShields(city, useMaterials * -1)
						end
						if useGold ~= 0 then
							tribeutil.changeMoney(tribe, useGold * -1)
						end
						break
					end
				end

				-- 1. Carpenter specialist
				-- AI tends to not build "Wood/Stone Craftsmen" in small cities, presumably because it thinks it will receive the actual improvement and the maint cost outweighs the shield benefit
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Carpenter", MMIMP.WoodStoneCraftsmen.cost, city.shields, 0, budgetGold)	-- 0 is hardcoded value of .upkeep for Carpenter
				if canAfford == true and
				   needsMaterials == true and
				   civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) == false and
				   canBuildImprovement(nil, city, MMIMP.WoodStoneCraftsmen) == true and
				   hasSpecialist(MMUNIT.Carpenter, city) == false and
--				   hasSpecialist(MMUNIT.Stonecutter, city) == false and
				   hasSpecialist(MMUNIT.Sawmill, city) == false
--				   hasSpecialist(MMUNIT.Mason, city) == false
				   then
					addSpecialist(MMUNIT.Carpenter, city)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 2. Stonecutter specialist
				-- AI tends to not build "Wood/Stone Craftsmen" in small cities, presumably because it thinks it will receive the actual improvement and the maint cost outweighs the shield benefit
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Stonecutter", MMIMP.WoodStoneCraftsmen.cost, city.shields, 0, budgetGold)	-- 0 is hardcoded value of .upkeep for Stonecutter
				if canAfford == true and
				   needsMaterials == true and
				   civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) == false and
				   canBuildImprovement(nil, city, MMIMP.WoodStoneCraftsmen) == true and
				   hasSpecialist(MMUNIT.Carpenter, city) == true and
				   hasSpecialist(MMUNIT.Stonecutter, city) == false and
--				   hasSpecialist(MMUNIT.Sawmill, city) == false and
				   hasSpecialist(MMUNIT.Mason, city) == false then
					addSpecialist(MMUNIT.Stonecutter, city)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 3. Water Mill improvement
				-- AI tends to not build this in cities without "Wood/Stone Craftsmen" or "Foundry" improvements, because in the base game it has no effect without them,
				--		but in MM it is actually a prerequisite to them (as well as Grist Mill and Textile Mill)
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Water Mill", MMIMP.WaterMill.cost, city.shields, IMPROVEMENT_UPKEEP[MMIMP.WaterMill.id], budgetGold)
				if canAfford == true and
				   civ.hasImprovement(city, MMIMP.WaterMill) == false and
				   canBuildImprovement(nil, city, MMIMP.WaterMill) == true and
				   lackOfMillPowerIsBlocker(city) == true then
					imputil.addImprovement(city, MMIMP.WaterMill)
					millImprovementBuilt(city)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 4. Wind Mill improvement
				-- AI tends to not build this in cities without "Wood/Stone Craftsmen" or "Foundry" improvements, because in the base game it has no effect without them,
				--		but in MM it is actually a prerequisite to them (as well as Grist Mill and Textile Mill)
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Wind Mill", MMIMP.WindMill.cost, city.shields, IMPROVEMENT_UPKEEP[MMIMP.WindMill.id], budgetGold)
				if canAfford == true and
				   civ.hasImprovement(city, MMIMP.WindMill) == false and
				   canBuildImprovement(nil, city, MMIMP.WindMill) == true and
				   lackOfMillPowerIsBlocker(city) == true then
					imputil.addImprovement(city, MMIMP.WindMill)
					millImprovementBuilt(city)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 5. Smith specialist
				-- AI tends to not build "Foundry" in small cities, perhaps because it thinks it will receive the actual improvement and the maint cost outweighs the shield benefit
				--		or perhaps because it does not yet have the "Wood/Stone Craftsmen" improvement
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Smith", MMIMP.Foundry.cost, city.shields, 1, budgetGold)	-- 1 is hardcoded value of .upkeep for Smith
				if canAfford == true and
				   needsMaterials == true and
				   civ.hasImprovement(city, MMIMP.Foundry) == false and
				   canBuildImprovement(nil, city, MMIMP.Foundry) == true and
				   hasSpecialist(MMUNIT.Smith, city) == false and
				   hasSpecialist(MMUNIT.Forge, city) == false then
					addSpecialist(MMUNIT.Smith, city)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 6. Sawmill specialist
				-- AI tends to not build "Wood/Stone Craftsmen" in small cities, presumably because it thinks it will receive the actual improvement and the maint cost outweighs the shield benefit
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Sawmill", MMIMP.WoodStoneCraftsmen.cost, city.shields, 1, budgetGold)		-- 1 is hardcoded difference between .upkeep for Sawmill and .upkeep for Carpenter
				if canAfford == true and
				   needsMaterials == true and
				   civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) == false and
				   canBuildImprovement(nil, city, MMIMP.WoodStoneCraftsmen) == true and
--				   hasSpecialist(MMUNIT.Carpenter, city) == true and
				   hasSpecialist(MMUNIT.Stonecutter, city) == true and
				   hasSpecialist(MMUNIT.Sawmill, city) == false
--				   hasSpecialist(MMUNIT.Mason, city) == false
				   then
					removeSpecialist(MMUNIT.Carpenter, city)
					addSpecialist(MMUNIT.Sawmill, city)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 7. Mason specialist
				-- AI tends to not build "Wood/Stone Craftsmen" in small cities, presumably because it thinks it will receive the actual improvement and the maint cost outweighs the shield benefit
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Mason", MMIMP.WoodStoneCraftsmen.cost, city.shields, 1, budgetGold)	-- 1 is hardcoded difference between .upkeep for Mason and .upkeep for Stonecutter
				if canAfford == true and
				   needsMaterials == true and
				   civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) == false and
				   canBuildImprovement(nil, city, MMIMP.WoodStoneCraftsmen) == true and
--				   hasSpecialist(MMUNIT.Carpenter, city) == true and
--				   hasSpecialist(MMUNIT.Stonecutter, city) == true and
				   hasSpecialist(MMUNIT.Sawmill, city) == true and
				   hasSpecialist(MMUNIT.Mason, city) == false then
					removeSpecialist(MMUNIT.Stonecutter, city)
					addSpecialist(MMUNIT.Mason, city)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 8. Forge specialist
				-- AI tends to not build "Foundry" in small cities, perhaps because it thinks it will receive the actual improvement and the maint cost outweighs the shield benefit
				--		or perhaps because it does not yet have the "Wood/Stone Craftsmen" improvement
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Forge", MMIMP.Foundry.cost, city.shields, 1, budgetGold)		-- 1 is hardcoded difference between .upkeep for Forge and .upkeep for Smith
				if canAfford == true and
				   needsMaterials == true and
				   civ.hasImprovement(city, MMIMP.Foundry) == false and
				   canBuildImprovement(nil, city, MMIMP.Foundry) == true and
				   hasSpecialist(MMUNIT.Smith, city) == true and
				   hasSpecialist(MMUNIT.Forge, city) == false then
					removeSpecialist(MMUNIT.Smith, city)
					addSpecialist(MMUNIT.Forge, city)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 9. Gothic Cathedral improvement
				-- AI may not build this in cities where unhappiness can be controlled by other means, but a cathedral is a prerequisite to Cathedral School which the AI wouldn't expect,
				--		and they shouldn't be cut off from increasing their research rate
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Gothic Cathedral", MMIMP.GothicCathedral.cost, city.shields, IMPROVEMENT_UPKEEP[MMIMP.GothicCathedral.id], budgetGold)
				if canAfford == true and
				   civ.hasImprovement(city, MMIMP.GothicCathedral) == false and
				   canBuildImprovement(nil, city, MMIMP.GothicCathedral) == true and
				   canBuildImprovement(nil, city, MMIMP.CathedralSchool) == false and
				   civ.hasImprovement(city, MMIMP.Monastery) == true and
				   civ.hasTech(city.owner, MMIMP.CathedralSchool.prereq) == true and
				   civ.hasImprovement(city, MMIMP.CathedralSchool) == false and
				   city.numUnhappy >= 1 then
					imputil.addImprovement(city, MMIMP.GothicCathedral)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 10. Romanesque Cathedral improvement
				-- AI may not build this in cities where unhappiness can be controlled by other means, but a cathedral is a prerequisite to Cathedral School which the AI wouldn't expect,
				--		and they shouldn't be cut off from increasing their research rate
				-- A Romanesque Cathedral provided this way can never trigger the Leaning Tower wonder, which is fine
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Romanesque Cathedral", MMIMP.RomanesqueCathedral.cost, city.shields, IMPROVEMENT_UPKEEP[MMIMP.RomanesqueCathedral.id], budgetGold)
				if canAfford == true and
				   civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == false and
				   canBuildImprovement(nil, city, MMIMP.RomanesqueCathedral) == true and
				   canBuildImprovement(nil, city, MMIMP.CathedralSchool) == false and
				   civ.hasImprovement(city, MMIMP.Monastery) == true and
				   civ.hasTech(city.owner, MMIMP.CathedralSchool.prereq) == true and
				   civ.hasImprovement(city, MMIMP.CathedralSchool) == false and
				   city.numUnhappy >= 1 then
					imputil.addImprovement(city, MMIMP.RomanesqueCathedral)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 11. Monastery improvement
				-- AI tends not to build this in towns that produce only a little Trade, because the research gains would be negligible.
				--		But in MM, it's a prerequisite for Hospital, three Wonders, and building Monastic Knight units, none of which would be expected by the AI.
				--		This code seeks to minimize the additions by setting a min city size of 5, which isn't one of the building prerequisites
				--		In other words, the city has to be large enough to *need* a Market Town Charter, even if it hasn't built one yet
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Monastery", MMIMP.Monastery.cost, city.shields, IMPROVEMENT_UPKEEP[MMIMP.Monastery.id], budgetGold)
				if canAfford == true and
				   civ.hasImprovement(city, MMIMP.Monastery) == false and
				   canBuildImprovement(nil, city, MMIMP.Monastery) == true and
				   city.size >= civ.cosmic.sizeAquaduct then
					imputil.addImprovement(city, MMIMP.Monastery)
					monasteryImprovementBuilt(city)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 12. Hospital improvement
				-- AI tends to not build "Hospital" because it typically reduces pollution, and AI tribes seem to be mostly immune from pollution and/or its effects
				--		In MM it also protects from plague, which is more akin to the benefit typically gained from SDI Defense, which the AI prioritizes highly
				--		This code will only do this for the AI shortly before the Black Death will hit, and only in cities
				--			with a Market Town Charter (that's not part of the pre-reqs for building the Hospital)
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Hospital", MMIMP.Hospital.cost, city.shields, IMPROVEMENT_UPKEEP[MMIMP.Hospital.id], budgetGold)
				if canAfford == true and
				   civ.hasImprovement(city, MMIMP.Hospital) == false and
				   canBuildImprovement(nil, city, MMIMP.Hospital) == true and
				   civ.hasImprovement(city, MMIMP.MarketTownCharter) == true and
				   civ.getGameYear() >= 1300 then
					imputil.addImprovement(city, MMIMP.Hospital)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 13. Harbor Crane improvement
				-- AI tends not to build this in many cities, for unknown reasons. Most of the time it's simply that the AI doesn't develop its cities as thoroughly
				--		because it is too focused on military units. In MM, this is a prerequisite for the Hanseatic League Capital wonder, though, so it's added to
				--		this list to facilitate that.
				--		This code seeks to minimize the additions by setting a min city size of 5, which isn't one of the building prerequisites
				--		In other words, the city has to be large enough to *need* a Market Town Charter, even if it hasn't built one yet
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Harbor Crane", MMIMP.HarborCrane.cost, city.shields, IMPROVEMENT_UPKEEP[MMIMP.HarborCrane.id], budgetGold)
				if canAfford == true and
				   needsMaterials == true and
				   civ.hasImprovement(city, MMIMP.HarborCrane) == false and
				   canBuildImprovement(nil, city, MMIMP.HarborCrane) == true and
				   city.size >= civ.cosmic.sizeAquaduct then
					imputil.addImprovement(city, MMIMP.HarborCrane)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break
				end
				-- 14. Trade Fair Circuit improvement
				-- The improvement *that appears in the can-build list* provides 50% more Trade (rounded down) to all tiles in the city's radius with roads (or royal highways).
				-- 		This means that on governments below Constitutional Monarchy, the only tiles that can benefit are those with rivers or specials.
				-- 		But the improvement benefit *that the nation actually receives* is a fixed amount of gold per turn, which is *higher* under early governments.
				--		Will only be provided if the city does *NOT* need Materials and is under one of the three governments where it provides the most benefit.
				-- Because the actual improvement is assigned directly, it isn't necessary to run the code that normally runs when the can-build one is finished and they are swapped.
				canAfford, useMaterials, useGold = isAffordableForAI(tribe, "Harbor Crane", MMIMP.HarborCrane.cost, city.shields, IMPROVEMENT_UPKEEP[MMIMP.HarborCrane.id], budgetGold)
				if canAfford == true and
				   needsMaterials == false and
				   (tribe.government == MMGOVERNMENT.PrimitiveMonarchy or tribe.government == MMGOVERNMENT.FeudalMonarchy or tribe.government == MMGOVERNMENT.EnlightenedMonarchy) and
				   civ.hasImprovement(city, MMIMP.TradeFairCircuitActual) == false and
				   canBuildImprovement(nil, city, MMIMP.TradeFairCircuit) == true then
					imputil.addImprovement(city, MMIMP.TradeFairCircuitActual)
					if useMaterials ~= 0 then
						cityutil.changeShields(city, useMaterials * -1)
					end
					if useGold ~= 0 then
						tribeutil.changeMoney(tribe, useGold * -1)
					end
					break	-- no benefit to breaking from the last check, but keeping it for consistency or in case more entries are added
				end

			end
		end
		log.info("providePrereqsOrSpecialistsForAI() completed in " .. string.format("%.4f", os.clock() - startTimestamp) .. " seconds")
	end
end

local function removeFreeCityCharters (tribe)
	log.trace()
	for city in civ.iterateCities() do
		if city.owner == tribe and city.size <= civ.cosmic.sizeAquaduct and civ.hasImprovement(city, MMIMP.FreeCityCharter) then
			imputil.removeImprovement(city, MMIMP.FreeCityCharter)
			if tribe.isHuman == true then
				uiutil.messageDialog("Free City Charter Revoked", "The city of " .. city.name .. " has diminished to size " .. city.size .. " and is no longer qualified to hold the distinction of a Free City. The " .. MMIMP.FreeCityCharter.name .. " in this city has been removed, and its maintenance cost of " .. IMPROVEMENT_UPKEEP[MMIMP.FreeCityCharter.id] .. " gold per turn will no longer be charged to the treasury.")
			end
		end
	end
end

-- This is also called by updateSpecialistsOnCityTaken() and must be defined prior to it in this file
local function removeSpecialistsForCity (city)
	log.trace()
	local specialistUnitId = nil
	local specialists = retrieve("specialists")
	local cityKey = "city" .. tostring(city.id)
	local citySpecialists = specialists[cityKey] or { }
	local unitIdsToDelete = { }
	for key, specialist in ipairs(citySpecialists) do
		if specialist.unitId ~= nil then
			table.insert(unitIdsToDelete, specialist.unitId)
		end
	end
	for _, specialistUnitId in ipairs(unitIdsToDelete) do
		local unitToDelete = civ.getUnit(specialistUnitId)
		if unitToDelete ~= nil then
			unitutil.deleteUnit(unitToDelete)
		end
	end
	specialists[cityKey] = nil
	store("specialists", specialists)
end

local function sellSpecialistBuildings ()
	log.trace()
	local tribe = civ.getPlayerTribe()
	local showCityPage = 1

	repeat
		local validCities = { }
		for city in civ.iterateCities() do
			if city.owner == tribe and
			   (civ.hasImprovement(city, MMIMP.GristMill) or hasSpecialist(MMUNIT.Bakery, city) or
				civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) or hasSpecialist(MMUNIT.Mason, city) or hasSpecialist(MMUNIT.Sawmill, city) or
				civ.hasImprovement(city, MMIMP.Foundry) or hasSpecialist(MMUNIT.Forge, city) or hasSpecialist(MMUNIT.Smith, city))
			then
				table.insert(validCities, city)
			end
		end
		local dialogText = "City production specialists exist as units that may not be disbanded on the city screen (which would reimburse Materials). However, if they have an upkeep cost, they may be sold or downgraded via this menu (which will reimburse gold).||In any city, a Grist Mill improvement may be sold for " .. (MMIMP.GristMill.cost * civ.cosmic.shieldRows) .. " gold, a Wood/Stone Craftsmen improvement may be sold for " .. (MMIMP.WoodStoneCraftsmen.cost * civ.cosmic.shieldRows) .. " gold, and a Foundry improvement may be sold for " .. (MMIMP.Foundry.cost * civ.cosmic.shieldRows) .. " gold. These actions can be taken here or directly on the city screen. In this menu, you have the additional options of DOWNGRADING a Wood/Stone Craftsmen improvement or a Foundry improvement to the previous level of specialists, in exchange for a smaller amount of gold.||"
		local staticOptions = { [-1] = "EXIT" }
		local pagedOptions = { }
		if #validCities == 0 then
			dialogText = dialogText .. "None of your cities contain any specialist buildings that can be sold or downgraded."
		else
			dialogText = dialogText .. "Select the city in which you wish to sell or downgrade a specialist building:"
			for _, city in ipairs(validCities) do
				pagedOptions[city.id] = city.name
			end
		end
		local result = -1
		result, showCityPage = uiutil.optionDialog("Sell Specialist Buildings", dialogText, 640, staticOptions, pagedOptions, 18, showCityPage)

		if result >= 0 then
			repeat
				local city = civ.getCity(result)
				local dialog2 = civ.ui.createDialog()
				dialog2.title = "Sell Specialist Buildings in " .. city.name
				dialog2.width = 640
				dialog2:addOption("EXIT (no changes)", 0)
				local goldGenerated = { }
					table.insert(goldGenerated, (MMIMP.GristMill.cost * civ.cosmic.shieldRows))							--  1: Sell Grist Mill improvement
					table.insert(goldGenerated, (MMIMP.GristMill.cost * civ.cosmic.shieldRows))							--  2: Sell Bakery
					table.insert(goldGenerated, (MMIMP.WoodStoneCraftsmen.cost * civ.cosmic.shieldRows))				--  3: Sell WoodStoneCraftsmen improvement
					table.insert(goldGenerated, round((MMIMP.WoodStoneCraftsmen.cost * civ.cosmic.shieldRows) / 5))		--  4: Downgrade WoodStoneCraftsmen improvement (5 is # of build iterations)
					table.insert(goldGenerated, round((MMIMP.WoodStoneCraftsmen.cost * civ.cosmic.shieldRows) / 5))		--  5: Downgrade Mason
					table.insert(goldGenerated, round((MMIMP.WoodStoneCraftsmen.cost * civ.cosmic.shieldRows) / 5))		--  6: Downgrade Sawmill
					table.insert(goldGenerated, (MMIMP.Foundry.cost * civ.cosmic.shieldRows))							--  7: Sell Foundry improvement
					table.insert(goldGenerated, round((MMIMP.Foundry.cost * civ.cosmic.shieldRows) / 3))				--  8: Downgrade Foundry improvement (3 is # of build iterations)
					table.insert(goldGenerated, round((MMIMP.Foundry.cost * civ.cosmic.shieldRows) / 3))				--  9: Downgrade Forge
					table.insert(goldGenerated, round((MMIMP.Foundry.cost * civ.cosmic.shieldRows) / 3))				-- 10: Sell Smith

				if civ.hasImprovement(city, MMIMP.GristMill) then
					dialog2:addOption("Sell " .. MMIMP.GristMill.name .. " improvement and receive " .. goldGenerated[1] .. " gold", 1)
				end
				if hasSpecialist(MMUNIT.Bakery, city) == true and civ.hasImprovement(city, MMIMP.GristMill) == false then
					-- Note that you cannot sell the Bakery without first selling the Grist Mill improvement, to preserve the order in which they were built
					dialog2:addOption("Sell " .. MMUNIT.Bakery.name .. " and receive " .. goldGenerated[2] .. " gold", 2)
				end
				if civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) then
					dialog2:addOption("Sell " .. MMIMP.WoodStoneCraftsmen.name .. " improvement and receive " .. goldGenerated[3] .. " gold", 3)
					dialog2:addOption("Downgrade " .. MMIMP.WoodStoneCraftsmen.name .. " improvement to " .. MMUNIT.Mason.name .. " + " .. MMUNIT.Sawmill.name .. " and receive " .. goldGenerated[4] .. " gold", 4)
				end
				if hasSpecialist(MMUNIT.Mason, city) then
					dialog2:addOption("Downgrade " .. MMUNIT.Mason.name .. " to " .. MMUNIT.Stonecutter.name .. " and receive " .. goldGenerated[5] .. " gold", 5)
				end
				if hasSpecialist(MMUNIT.Sawmill, city) == true and hasSpecialist(MMUNIT.Mason, city) == false then
					-- Note that you cannot downgrade the Sawmill without first downgrading the Mason, to preseve the order in which they were built
					dialog2:addOption("Downgrade " .. MMUNIT.Sawmill.name .. " to " .. MMUNIT.Carpenter.name .. " and receive " .. goldGenerated[6] .. " gold", 6)
				end
				if civ.hasImprovement(city, MMIMP.Foundry) then
					dialog2:addOption("Sell " .. MMIMP.Foundry.name .. " improvement and receive " .. goldGenerated[7] .. " gold", 7)
					dialog2:addOption("Downgrade " .. MMIMP.Foundry.name .. " improvement to " .. MMUNIT.Forge.name .. " and receive " .. goldGenerated[8] .. " gold", 8)
				end
				if hasSpecialist(MMUNIT.Forge, city) then
					dialog2:addOption("Downgrade " .. MMUNIT.Forge.name .. " to " .. MMUNIT.Smith.name .. " and receive " .. goldGenerated[9] .. " gold", 9)
				end
				if hasSpecialist(MMUNIT.Smith, city) then
					dialog2:addOption("Sell " .. MMUNIT.Smith.name .. " and receive " .. goldGenerated[10] .. " gold", 10)
				end
				local result2 = dialog2:show()
				if result2 == 1 then
					imputil.removeImprovement(city, MMIMP.GristMill)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				elseif result2 == 2 then
					removeSpecialist(MMUNIT.Bakery, city)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				elseif result2 == 3 then
					imputil.removeImprovement(city, MMIMP.WoodStoneCraftsmen)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				elseif result2 == 4 then
					imputil.removeImprovement(city, MMIMP.WoodStoneCraftsmen)
					addSpecialist(MMUNIT.Mason, city)
					addSpecialist(MMUNIT.Sawmill, city)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				elseif result2 == 5 then
					removeSpecialist(MMUNIT.Mason, city)
					addSpecialist(MMUNIT.Stonecutter, city)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				elseif result2 == 6 then
					removeSpecialist(MMUNIT.Sawmill, city)
					addSpecialist(MMUNIT.Carpenter, city)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				elseif result2 == 7 then
					imputil.removeImprovement(city, MMIMP.Foundry)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				elseif result2 == 8 then
					imputil.removeImprovement(city, MMIMP.Foundry)
					addSpecialist(MMUNIT.Forge, city)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				elseif result2 == 9 then
					removeSpecialist(MMUNIT.Forge, city)
					addSpecialist(MMUNIT.Smith, city)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				elseif result2 == 10 then
					removeSpecialist(MMUNIT.Smith, city)
					tribeutil.changeMoney(tribe, goldGenerated[result2])
				end
			until
				result2 == 0
		end
	until
		result == nil or result == -1
end

local function setImprovementCosts ()

	log.trace()
	local gameYear = civ.getGameYear()

	local prevRoyalPalaceCost = MMIMP.RoyalPalace.cost
	MMIMP.RoyalPalace.cost = math.floor(gameYear / 100)
	if MMIMP.RoyalPalace.cost ~= prevRoyalPalaceCost then
		log.action("Adjusted cost of Royal Palace improvement from " .. round(prevRoyalPalaceCost * civ.cosmic.shieldRows) .. " to " .. round(MMIMP.RoyalPalace.cost * civ.cosmic.shieldRows) .. " Materials")
	else
		log.info("Confirmed cost of Royal Palace improvement at " .. round(MMIMP.RoyalPalace.cost * civ.cosmic.shieldRows) .. " Materials")
	end

	local prevMonasteryCost = MMIMP.Monastery.cost
	MMIMP.Monastery.cost = 8
	if wonderutil.hasBeenBuilt(MMWONDER.MagnificentCluniacAbbey) then
		MMIMP.Monastery.cost = MMIMP.Monastery.cost + 2
	end
	if wonderutil.hasBeenBuilt(MMWONDER.CistercianOrder) then
		MMIMP.Monastery.cost = MMIMP.Monastery.cost + 2
	end
	if MMIMP.Monastery.cost ~= prevMonasteryCost then
		log.action("Adjusted cost of Monastery improvement from " .. round(prevMonasteryCost * civ.cosmic.shieldRows) .. " to " .. round(MMIMP.Monastery.cost * civ.cosmic.shieldRows) .. " Materials")
	else
		log.info("Confirmed cost of Monastery improvement at " .. round(MMIMP.Monastery.cost * civ.cosmic.shieldRows) .. " Materials")
	end
	MMUNIT.Monks.cost = MMIMP.Monastery.cost

	local prevCraftsmenCost = MMIMP.WoodStoneCraftsmen.cost
	if gameYear < 800 then
		MMIMP.WoodStoneCraftsmen.cost = 4
	elseif gameYear < 1200 then
		MMIMP.WoodStoneCraftsmen.cost = 5
	else
		MMIMP.WoodStoneCraftsmen.cost = 6
	end
	if MMIMP.WoodStoneCraftsmen.cost ~= prevCraftsmenCost then
		log.action("Adjusted cost of Wood/Stone Craftsmen improvement from " .. round(prevCraftsmenCost * civ.cosmic.shieldRows) .. " to " .. round(MMIMP.WoodStoneCraftsmen.cost * civ.cosmic.shieldRows) .. " Materials")
	else
		log.info("Confirmed cost of Wood/Stone Craftsmen improvement at " .. round(MMIMP.WoodStoneCraftsmen.cost * civ.cosmic.shieldRows) .. " Materials")
	end
	-- Cost of Wood/Stone Craftsmen specialists is handled together with Foundry specialists below

	local prevFoundryCost = MMIMP.Foundry.cost
	MMIMP.Foundry.cost = 6
	if techutil.knownByAny(techutil.findByName("Catalan Forges", true)) == true then
		MMIMP.Foundry.cost = 7
	end
	if techutil.knownByAny(techutil.findByName("Wolf Furnace", true)) == true then
		MMIMP.Foundry.cost = 8
	end
	if techutil.knownByAny(techutil.findByName("Blast Furnace", true)) == true then
		MMIMP.Foundry.cost = 10
	end
	if MMIMP.Foundry.cost > prevFoundryCost then
		log.action("Adjusted cost of Foundry improvement from " .. round(prevFoundryCost * civ.cosmic.shieldRows) .. " to " .. round(MMIMP.Foundry.cost * civ.cosmic.shieldRows) .. " Materials")
	else
		log.info("Confirmed cost of Foundry improvement at " .. round(MMIMP.Foundry.cost * civ.cosmic.shieldRows) .. " Materials")
	end
	-- Cost of Foundry specialists is handled together with Wood/Stone Craftsmen specialists below

	for _, data in ipairs(SPECIALIST_TABLE) do
		if data.unittype.cost ~= data.baseImprovement.cost then
			log.action("Adjusted cost of " .. data.unittype.name .. " unit from " .. round(data.unittype.cost * civ.cosmic.shieldRows) .. " to " .. round(data.baseImprovement.cost * civ.cosmic.shieldRows) .. " Materials")
			data.unittype.cost = data.baseImprovement.cost
		end
	end
end

local function specialistUnitKilled (winningUnit, losingUnit)
	log.trace()
	local specialistCity = getSpecialistCity(losingUnit)
	if specialistCity ~= nil then
		removeSpecialist(losingUnit.type, specialistCity)
		if losingUnit.type == MMUNIT.Monks then
			if civ.hasImprovement(specialistCity, MMIMP.Monastery) == true then
				imputil.removeImprovement(specialistCity, MMIMP.Monastery)
				if losingUnit.owner.isHuman == true then
					uiutil.messageDialog("Game Concept: Monastery", "The destruction of the Monks unit outside " .. specialistCity.name .. " has been reflected in-game by the removal of the Monastery improvement from within this city. You will need to reconstruct it, in order to regain its benefit.")
				end
			else
				log.warning("WARNING: Could not remove " .. MMIMP.Monastery.name .. " improvement from " .. specialistCity.name .. " since it did not exist")
			end
		elseif losingUnit.type == MMUNIT.FishingFleet then
			if civ.hasImprovement(specialistCity, MMIMP.FishingFleet) == true then
				imputil.removeImprovement(specialistCity, MMIMP.FishingFleet)
				if losingUnit.owner.isHuman == true then
					uiutil.messageDialog("Game Concept: Fishing Fleet", "The destruction of the Fishing Fleet unit outside " .. specialistCity.name .. " has been reflected in-game by the removal of the Fishing Fleet improvement from within this city. You will need to reconstruct it, in order to regain its benefit.")
				end
			else
				log.warning("WARNING: Could not remove " .. MMIMP.FishingFleet.name .. " improvement from " .. specialistCity.name .. " since it did not exist")
			end
		else
			-- Unit that was killed is a CITY specialist, must belong to the human player
			-- Since the human player doesn't have to defeat AI city specialists in order to take a city, the AI shouldn't have to do this when attacking a human city
			-- Therefore, we already removed this specialist from the table above, but we will now delete *all* city specialists for this city
			--		and then restore 1 MP to the victorious AI unit, permitting it to take the city
			for _, specialist in ipairs(SPECIALIST_TABLE) do
				if hasSpecialist(specialist.unittype, specialistCity) == true then
					removeSpecialist(specialist.unittype, specialistCity)
				end
			end
			if winningUnit.moveSpent >= 1 then
				winningUnit.moveSpent = winningUnit.moveSpent - 1
			else
				log.error("ERROR! Could not restore 1 MP to " .. winningUnit.owner.adjective .. " " .. winningUnit.type.name .. " because it had spent " .. winningUnit.moveSpent .. " MP this turn!")
			end

		end
	else
		local unitIsSpecialistType = false
		if losingUnit.type == MMUNIT.Monks or losingUnit.type == MMUNIT.FishingFleet then
			unitIsSpecialistType = true
		end
		for _, specialist in ipairs(SPECIALIST_TABLE) do
			if losingUnit.type == specialist.unittype then
				unitIsSpecialistType = true
			end
		end
		if unitIsSpecialistType == true then
			log.error("ERROR! " .. losingUnit.type.name .. " is a specialist unit, but no entry was found for it in db.specialists!")
		end
	end
end

local function syncSpecialistsWithGameStatus ()
	-- Syncs the table in memory with the actual units, improvements, and wonders found in the game
	log.trace()
	local specialists = retrieve("specialists")

	-- PART I:
	for cityKey, cityData in pairs(specialists) do
		local cityNotFound = false
		local cityId = tonumber(string.sub(cityKey, 5))
		local city = civ.getCity(cityId)
		if city == nil then
			log.error("ERROR! Found specialist cityKey " .. cityKey .. " (" .. cityData.cityName .. ") but that city could not be found!")
			cityNotFound = true
		else
			-- Confirm city owner. Cities that change hands should already be handled in updateSpecialistsOnCityTaken() however, where we delete the citySpecialist entry entirely
			--		and then recreate one for the new city owner.
			if city.owner.id ~= cityData.tribeId then

				cityData.tribeId = city.owner.id
			end
			-- Confirm stored name, since cities can be renamed by the human player:
			if cityData.cityName ~= city.name then
				log.update("Updated name of " .. cityKey .. " from " .. cityData.cityName .. " to " .. city.name)
				cityData.cityName = city.name
			end
		end
		local specialistsToDelete = { }
		for specialistKey, specialistData in ipairs(cityData) do
			local specialistUnit = nil
			if specialistData.unitId ~= nil then
				specialistUnit = civ.getUnit(specialistData.unitId)
			end
			if cityNotFound == true then
				if specialistUnit ~= nil and specialistUnit.type.id == specialistData.unittypeId then
					unitutil.deleteUnit(specialistUnit)
				end
			else

				if specialistData.unittypeId == MMUNIT.Monks.id then
					-- Unit and improvement must always exist:
					local hasMonastery = civ.hasImprovement(city, MMIMP.Monastery)
					local removeThis = false
					if specialistUnit == nil or specialistUnit.type.id ~= specialistData.unittypeId or specialistUnit.owner.id ~= cityData.tribeId then
						local specialistUnitDesc = "not found"
						if specialistUnit ~= nil then
							specialistUnitDesc = specialistUnit.owner.adjective .. " " .. specialistUnit.type.name
						end
						log.action("Removing specialist due to unit discrepancy found for " .. cityData.cityName .. " (" .. cityKey .. "): unit ID " .. tostring(specialistData.unitId) .. " should be " .. civ.getTribe(cityData.tribeId).adjective .. " " .. civ.getUnitType(specialistData.unittypeId).name .. " but is " .. specialistUnitDesc .. ".")
						removeThis = true
					elseif specialistUnit.order ~= -1 then
						-- Monks unit is not allowed to be fortified (thereby gaining a defensive bonus); clear any orders it may have
						unitutil.clearOrders(specialistUnit)
					end
					if hasMonastery == false then
						log.action("Removing specialist due to missing improvement: " .. MMIMP.Monastery.name .. " not found in " .. cityData.cityName .. " (" .. cityKey .. ")")
						removeThis = true
					end
					if removeThis == true then
						if hasMonastery == true then
							imputil.removeImprovement(city, MMIMP.Monastery)
							-- The following message was added because the human player's Monks unit can be lost due to a plague strike, not just an enemy attack
							-- In that case onUnitKilled() does not fire, so specialistUnitKilled() doesn't run, and the Monastery removal happens here instead.
							if specialistUnit ~= nil and specialistUnit.owner.isHuman == true then
								uiutil.messageDialog("Game Concept: Monastery", "The loss of the Monks unit outside " .. city.name .. " has been reflected in-game by the removal of the Monastery improvement from within this city. You will need to reconstruct it, in order to regain its benefit.")
							end
						end
						table.insert(specialistsToDelete, {st = MMUNIT.Monks, c = city})
					end
				elseif specialistData.unittypeId == MMUNIT.FishingFleet.id then

					-- Unit and improvement must always exist:
					local hasFishingFleetImp = civ.hasImprovement(city, MMIMP.FishingFleet)
					local removeThis = false
					if specialistUnit == nil or specialistUnit.type.id ~= specialistData.unittypeId or specialistUnit.owner.id ~= cityData.tribeId then
						local specialistUnitDesc = "not found"
						if specialistUnit ~= nil then
							specialistUnitDesc = specialistUnit.owner.adjective .. " " .. specialistUnit.type.name
						end
						log.action("Removing specialist due to unit discrepancy found for " .. cityData.cityName .. " (" .. cityKey .. "): unit ID " .. tostring(specialistData.unitId) .. " should be " .. civ.getTribe(cityData.tribeId).adjective .. " " .. civ.getUnitType(specialistData.unittypeId).name .. " but is " .. specialistUnitDesc .. ".")
						-- If the fishing fleet unit is disbanded by the AI or the game engine, it will not be restored, and the city will also lose the fishing fleet improvement
						removeThis = true
					elseif specialistUnit.order ~= -1 then
						-- Fishing Fleet unit is not allowed to be fortified (thereby gaining a defensive bonus); clear any orders it may have
						unitutil.clearOrders(specialistUnit)
					end
					if hasFishingFleetImp == false then
						log.action("Removing specialist due to missing improvement: " .. MMIMP.FishingFleet.name .. " not found in " .. cityData.cityName .. " (" .. cityKey .. ")")
						removeThis = true
					end
					if removeThis == true then
						if hasFishingFleetImp == true then

							imputil.removeImprovement(city, MMIMP.FishingFleet)
							tribeutil.changeMoney(city.owner, MMIMP.FishingFleet.cost * cityutil.getShieldColumns(city.owner, humanIsSupreme()) * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR)
						end
						table.insert(specialistsToDelete, {st = MMUNIT.FishingFleet, c = city})
					end
				elseif specialistData.unitId ~= nil then
					-- Other specialists won't have units for AI tribes, so unitId == nil is acceptable
					-- But (for the human tribe), if unitId is *not* nil, that unit must exist and its data must match
					if specialistUnit == nil or specialistUnit.type.id ~= specialistData.unittypeId or specialistUnit.owner.id ~= cityData.tribeId then
						local specialistUnitDesc = "not found"
						if specialistUnit ~= nil then
							specialistUnitDesc = specialistUnit.owner.adjective .. " " .. specialistUnit.type.name
						end
						log.action("Removing specialist due to unit discrepancy found for " .. cityData.cityName .. " (" .. cityKey .. "): unit ID " .. tostring(specialistData.unitId) .. " should be " .. civ.getTribe(cityData.tribeId).adjective .. " " .. civ.getUnitType(specialistData.unittypeId).name .. " but is " .. specialistUnitDesc .. ".")
						table.insert(specialistsToDelete, {st = specialistData.unittype, c = city})
					elseif specialistUnit.order ~= -1 then
						-- Specialist unit is not allowed to be fortified (thereby gaining a defensive bonus); clear any orders it may have
						unitutil.clearOrders(specialistUnit)
					end
				end
			end
		end
		for _, data in ipairs(specialistsToDelete) do
			removeSpecialist(data.st, data.c)
		end
		if cityNotFound == true then
			log.update("Clearing all specialist data for " .. cityKey .. " because that city could not be found")
			specialists[cityKey] = nil
			store("specialists", specialists)
		end
	end

	-- PART II:
	for city in civ.iterateCities() do
		-- If Monastery improvement is present, but there is no specialist information for a Monks unit in db, delete the Monastery improvement
		if civ.hasImprovement(city, MMIMP.Monastery) == true then
			if hasSpecialist(MMUNIT.Monks, city) == false then
				log.info("City has " .. MMIMP.Monastery.name .. " but no corresponding " .. MMUNIT.Monks.name .. " specialist entry was found")
				imputil.removeImprovement(city, MMIMP.Monastery)
			end
		end
		-- If Fishing Fleet improvement is present, but there is no specialist information for a Fishing Fleet unit in db, delete the Fishing Fleet improvement
		if civ.hasImprovement(city, MMIMP.FishingFleet) == true then
			if hasSpecialist(MMUNIT.FishingFleet, city) == false then
				log.info("City has " .. MMIMP.FishingFleet.name .. " but no corresponding " .. MMUNIT.FishingFleet.name .. " specialist entry was found")
				imputil.removeImprovement(city, MMIMP.FishingFleet)
			end
		end
		-- If water/wind mill power is missing, all specialists that depend on this need to be downgraded to the ones that can be supported without it
		-- 		This benefit could be lost due to losing control of a wonder and thus affect multiple cities
		-- Based on the way improvements function in the base game, I will NOT delete improvements that could only be built because mill power existed at time of construction
		--		For example, if you sell your Marketplace, the base game does not remove your Bank
		if cityHasMillPower(city) == false then
			if hasSpecialist(MMUNIT.Sawmill, city) == true then
				log.info("No mill power present in " .. city.owner.adjective .. " city of " .. city.name)
				removeSpecialist(MMUNIT.Sawmill, city)
				addSpecialist(MMUNIT.Carpenter, city)
			end
			if hasSpecialist(MMUNIT.Mason, city) == true then
				log.info("No mill power present in " .. city.owner.adjective .. " city of " .. city.name)
				removeSpecialist(MMUNIT.Mason, city)
				addSpecialist(MMUNIT.Stonecutter, city)
			end
			if hasSpecialist(MMUNIT.Forge, city) == true then
				log.info("No mill power present in " .. city.owner.adjective .. " city of " .. city.name)
				removeSpecialist(MMUNIT.Forge, city)
				addSpecialist(MMUNIT.Smith, city)
			end
		end
	end
end

local function updateSpecialistsOnCityTaken (city)
	log.trace()

	local takenByBarbarians = false
	if city.owner.id == 0 then
		takenByBarbarians = true
	end

	local hasBakery = hasSpecialist(MMUNIT.Bakery, city)
	local hasMiller = hasSpecialist(MMUNIT.Miller, city)
	local hasMason = hasSpecialist(MMUNIT.Mason, city)
	local hasSawmill = hasSpecialist(MMUNIT.Sawmill, city)
	local hasForge = hasSpecialist(MMUNIT.Forge, city)

	-- The following specialists will be deleted (since they belonged to the city's previous owner)
	-- and then replaced, if their city improvement is still present:
	local _, monksLocation = hasSpecialist(MMUNIT.Monks, city)
	local _, fishingFleetLocation = hasSpecialist(MMUNIT.FishingFleet, city)

	-- Clear all specialists for the city/tribe:
	removeSpecialistsForCity(city)

	-- The location of the previous units, owned by the city's FORMER owner, might be occupied by other units belonging to that FORMER owner
	-- If so, it wouldn't be permissible to create a unit for the city's NEW owner on that tile
	if monksLocation ~= nil and unitutil.isValidUnitLocation(MMUNIT.Monks, city.owner, monksLocation) == false then
		monksLocation = nil				-- This will cause the Monks unit to be created in the city itself
	end
	if fishingFleetLocation ~= nil and unitutil.isValidUnitLocation(MMUNIT.FishingFleet, city.owner, fishingFleetLocation) == false then
		fishingFleetLocation = nil		-- This will cause the Fishing Fleet unit to be created in the city itself
	end

	-- Grist Mill:
	-- Never directly destroyed on city capture, but improvement and specialists are all downgraded one level:
	if civ.hasImprovement(city, MMIMP.GristMill) == true then
		imputil.removeImprovement(city, MMIMP.GristMill)
		if takenByBarbarians == false then
			if cityHasMillPower(city) == false then
				if canBuildImprovement(nil, city, MMIMP.WaterMill) then
					imputil.addImprovement(city, MMIMP.WaterMill)
				elseif canBuildImprovement(nil, city, MMIMP.WindMill) then
					imputil.addImprovement(city, MMIMP.WindMill)
				end
			end
			addSpecialist(MMUNIT.Bakery, city)
			addSpecialist(MMUNIT.Miller, city)
		end
	elseif hasBakery == true and takenByBarbarians == false then
		addSpecialist(MMUNIT.Miller, city, unitLocation)
	end

	-- Wood/Stone Craftsmen:
	-- Never directly destroyed on city capture, but improvement and specialists are all downgraded one level:
	if civ.hasImprovement(city, MMIMP.WoodStoneCraftsmen) == true then
		imputil.removeImprovement(city, MMIMP.WoodStoneCraftsmen)
		if takenByBarbarians == false then
			if cityHasMillPower(city) == false then
				if canBuildImprovement(nil, city, MMIMP.WaterMill) then
					imputil.addImprovement(city, MMIMP.WaterMill)
				elseif canBuildImprovement(nil, city, MMIMP.WindMill) then
					imputil.addImprovement(city, MMIMP.WindMill)
				end
			end
			addSpecialist(MMUNIT.Mason, city)
			addSpecialist(MMUNIT.Sawmill, city)
		end
	else
		if hasMason == true and takenByBarbarians == false then
			addSpecialist(MMUNIT.Stonecutter, city, unitLocation)
		end
		if hasSawmill == true and takenByBarbarians == false then
			addSpecialist(MMUNIT.Carpenter, city, unitLocation)
		end
	end

	-- Foundry
	-- Never directly destroyed on city capture, but improvement and specialists are all downgraded one level:
	if civ.hasImprovement(city, MMIMP.Foundry) == true then
		imputil.removeImprovement(city, MMIMP.Foundry)
		if takenByBarbarians == false then
			if cityHasMillPower(city) == false then
				if canBuildImprovement(nil, city, MMIMP.WaterMill) then
					imputil.addImprovement(city, MMIMP.WaterMill)
				elseif canBuildImprovement(nil, city, MMIMP.WindMill) then
					imputil.addImprovement(city, MMIMP.WindMill)
				end
			end
			addSpecialist(MMUNIT.Forge, city)
		end
	elseif hasForge == true and takenByBarbarians == false then
		addSpecialist(MMUNIT.Smith, city, unitLocation)
	end

	-- Monastery
	-- Never directly destroyed on city capture:
	if civ.hasImprovement(city, MMIMP.Monastery) == true then
		addSpecialist(MMUNIT.Monks, city, monksLocation)
	end

	-- Fishing Fleet
	-- Randomly destroyed on city capture:
	if civ.hasImprovement(city, MMIMP.FishingFleet) == true then
		addSpecialist(MMUNIT.FishingFleet, city, fishingFleetLocation)
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 27

return {
	confirmLoad = confirmLoad,

	canBuildImprovement = canBuildImprovement,
	canBuildWonder = canBuildWonder,
	closeBasilicas = closeBasilicas,
	getCustomImproveWonderBenefits = getCustomImproveWonderBenefits,
	getTotalSpecialistCosts = getTotalSpecialistCosts,
	improvementBuilt = improvementBuilt,
	setConstitutionalMonarchyExpiration = setConstitutionalMonarchyExpiration,
	wonderBuilt = wonderBuilt,
	isCitySpecialistUnitType = isCitySpecialistUnitType,
	isSpecialistUnitType = isSpecialistUnitType,
	listCityImprovementStatus = listCityImprovementStatus,
	listNetHealthAndMaterials = listNetHealthAndMaterials,
	processCustomImproveWonderBenefits = processCustomImproveWonderBenefits,
	processSpecialistBenefits = processSpecialistBenefits,
	providePrereqsOrSpecialistsForAI = providePrereqsOrSpecialistsForAI,
	removeFreeCityCharters = removeFreeCityCharters,
	removeSpecialistsForCity = removeSpecialistsForCity,
	sellSpecialistBuildings = sellSpecialistBuildings,
	setImprovementCosts = setImprovementCosts,
	specialistUnitKilled = specialistUnitKilled,
	syncSpecialistsWithGameStatus = syncSpecialistsWithGameStatus,
	updateSpecialistsOnCityTaken = updateSpecialistsOnCityTaken,
}
