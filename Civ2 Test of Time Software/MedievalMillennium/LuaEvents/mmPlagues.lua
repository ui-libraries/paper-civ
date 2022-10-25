-- mmPlagues.lua
-- by Knighttime

log.trace()

constant.mmPlagues = { }
constant.mmPlagues.COASTAL_CITY_CHANCE_FACTOR = 1.50			-- Relative chance of a coastal city to be hit by plague, compared to an inland city
constant.mmPlagues.SEWER_CONDUITS_CHANCE_REDUCTION_PCT = 20		-- Percent *reduction* in risk of a major plague strike occurring at all in a given city, due to Sewer Conduits improvement
constant.mmPlagues.CREATE_UNIT_VIRULENCE_PCT_MIN = 15			-- Minimum virulence of the plague strike (which is measured in percent) in order to create a plague (or Black Death) unit
constant.mmPlagues.HOSPITAL_VIRULENCE_REDUCTION_PCT = 60.00		-- Percent *reduction* in virulence (affecting both population reduction and unit mortality) due to Hospital improvement
constant.mmPlagues.HOSPITAL_COST_PER_CITIZEN_SAVED = 2			-- Maintenance surcharge for a Hospital when a plague strikes. This value is multiplied by the number of citizens saved,
																--		which is calculated by comparing "what would have happened" if no Hospital was present.
constant.mmPlagues.VIRULENCE_REDUCTION_PCT_FOR_UNITS = 37.50	-- Percent *reduction* in virulence when evaluating unit mortality (compared to population mortality)
																--		This stacks with the Hospital reduction (units can benefit from both) but they are multiplied not added
constant.mmPlagues.TILE_NATURAL_RECOVERY_YEARS = 40				-- Number of *years* (not turns)after a plague strike that the resulting plague pollution will be automatically removed
constant.mmPlagues.PLAGUE_TILES_TO_LIST_MAX = 24				-- Maximum number of plague tiles near human cities that can be listed for review by the human player

-- Probability estimates below assume that 50% of cities are coastal; ignore the city size threshold; ignore the effects of Sewer Conduits and Hospitals;
--		and ignore the diminished productivity of terrain resulting from plague pollution
local PLAGUE_OCCURRENCES = {
	{ startYear =  536, endYear =  550, 	minCitySize = 2,	minCityChance =  6.36, maxCityChance = 19.07, 		minVirulence = 10.86, maxVirulence = 23.24, 		unitType = MMUNIT.Plague	  },
	-- 8 turns; most common outcome is for a city to be struck 1x (37.85%); chance of 0x and 2x are the same at 25.04%; 3x or more is 12.07%
	-- Virulence should result in an overall population decrease of about 13% to 26%, ignoring natural growth during those 8 turns

	{ startYear =  551, endYear =  750, 	minCitySize = 2,	minCityChance =  1.37, maxCityChance =  4.12, 		minVirulence =  8.37, maxVirulence = 20.13, 		unitType = MMUNIT.Plague	  },
	-- 100 turns; most common outcome is for a city to be struck 3x (22.09%); chance of 2x and 4x are the same at 19.03%
	-- Virulence should result in an overall population decrease of about 25% to 50%, ignoring (the substantial) natural growth during those 100 turns

	-- No plagues from 751 through 1341 (59.1% of the game turns)

	{ startYear = 1342, endYear = 1343, 	minCitySize = 3,	minCityChance =  4.00, maxCityChance =  4.00, 		minVirulence = 15.00, maxVirulence = 35.00, 		unitType = MMUNIT.BlackDeath },
	-- 1 turn;  0x = 95.0%, 1x = 5.0%
	{ startYear = 1344, endYear = 1346,		minCitySize = 3,	minCityChance =  7.15, maxCityChance = 14.29, 		minVirulence = 18.90, maxVirulence = 48.20, 		unitType = MMUNIT.BlackDeath },
	-- 2 turns; 0x = 75.0%, 1x = 23.2%, 2x = 1.8%
	{ startYear = 1347, endYear = 1351, 	minCitySize = 3,	minCityChance = 32.00, maxCityChance = 48.00, 		minVirulence = 22.39, maxVirulence = 55.18, 		unitType = MMUNIT.BlackDeath },
	-- 2 turns; 0x = 25.0%, 1x = 50.0%, 2x = 25.0%
	{ startYear = 1352, endYear = 1355, 	minCitySize = 3,	minCityChance = 13.14, maxCityChance = 21.90, 		minVirulence = 18.90, maxVirulence = 48.20, 		unitType = MMUNIT.BlackDeath },
	-- 2 turns; 0x = 61.0%, 1x = 34.2%, 2x = 4.8%
	{ startYear = 1356, endYear = 1356, 	minCitySize = 3,	minCityChance =  8.00, maxCityChance =  8.00, 		minVirulence = 15.00, maxVirulence = 35.00, 		unitType = MMUNIT.BlackDeath },
	-- 1 turn;  0x = 90.0%, 1x = 10.0%
	-- 		Black Death totals:
	-- 8 turns; estimated common outcomes are for a city to be struck 2x (30.9%), then 1x (29.3%), then 3x (18.7%), then 0x (12.1%), then 4x (7.1%), then 5x or more (2.0%)
	-- Virulence should result in an overall population decrease of about 30% to 60%, ignoring natural growth during those 8 turns

	{ startYear = 1357, endYear = 1721, 	minCitySize = 3,	minCityChance =  1.90, maxCityChance =  5.70, 		minVirulence =  6.52, maxVirulence = 14.89, 		unitType = MMUNIT.Plague	  }
	-- 72 turns through 1500; most common outcome is for a city to be struck 3x (22.25%); chance of 2x and 4x are the same at 19.13%
	-- Virulence should result in an overall population decrease of about 20% to 40%, ignoring natural growth during those 72 turns
}

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
local function confirmLoad ()
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " loaded successfully")
	log.info("")
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function documentNaturalPlague ()
	log.trace()
	plagueTiles = retrieve("plagueTiles")
	for tile in tileutil.iterateTiles() do
		if tile.improvements & 0x82 == 0x80 then
			local tileId = tileutil.getTileId(tile)
			if plagueTiles[tileId] == nil then
				local lastYear = civ.getGameYear() - db.gameData.YEARS_PER_TURN
				plagueTiles[tileId] = lastYear
				log.update("Updated db.plagueTiles with naturally occurring strike at " .. tile.x .. "," .. tile.y .. " in " .. lastYear)
			end
		end
	end
	store("plagueTiles", plagueTiles)
end

-- This is also called by plagueStrike() and must be defined prior to it in this file:
local function isPlagueUnitType (unittype)
	log.trace()
	local isPlague = false
	if unittype == MMUNIT.BlackDeath or
	   unittype == MMUNIT.Plague then
		isPlague = true
	end
	return isPlague
end

local function listPlagueTiles ()
	log.trace()
	local plagueTiles = retrieve("plagueTiles")
	local plagueTilesFound = 0
	local columnTable = {
		{label = "city"},
		{label = "location"},
		{label = "status"},
		{label = "terrain"},
		{label = "recovery", align = "right"}
	}
	local dataTable = { }
	table.insert(dataTable, {city = "CITY", location = "LOCATION", status = "STATUS", terrain = "TERRAIN", recovery = "RECOVERY"})
	for city in civ.iterateCities() do
		if city.owner == civ.getPlayerTribe() then
			for _, tile in ipairs(tileutil.getCityRadiusTiles(city, false)) do
				if civ.isTile(tile) and tileutil.hasPollution(tile) then
					plagueTilesFound = plagueTilesFound + 1
					if plagueTilesFound <= constant.mmPlagues.PLAGUE_TILES_TO_LIST_MAX then
						local status = "Recent"
						for unit in tile.units do
							if isPlagueUnitType(unit.type) == true then
								status = "Active!"
							end
						end
						local tileId = tileutil.getTileId(tile)
						local lastStruckYear = plagueTiles[tileId]
						local recovery = "n/a"
						if lastStruckYear ~= nil then
							recovery = tostring(lastStruckYear + constant.mmPlagues.TILE_NATURAL_RECOVERY_YEARS)
						end
						table.insert(dataTable, {
							city = city.name,
							location = tile.x .. "," .. tile.y,
							status = status,
							terrain = MMTERRAIN[tileutil.getTerrainId(tile)],
							recovery = recovery
						})
					end
				end
			end
		end
	end
	if plagueTilesFound > 0 then
		if plagueTilesFound <= constant.mmPlagues.PLAGUE_TILES_TO_LIST_MAX then
			table.insert(dataTable, {
				city = "(" .. tostring(plagueTilesFound) .. " tiles found)",
				location = "",
				status = "",
				terrain = "",
				recovery = ""
			})
		else
			table.insert(dataTable, {
				city = "(" .. tostring(constant.mmPlagues.PLAGUE_TILES_TO_LIST_MAX) .. " tiles shown; " .. tostring(plagueTilesFound - constant.mmPlagues.PLAGUE_TILES_TO_LIST_MAX) .. " more tiles found)",
				location = "",
				status = "",
				terrain = "",
				recovery = ""
			})
		end
		uiutil.messageDialog("Plague Pollution", uiutil.convertTableToMessageText(columnTable, dataTable, 4))
	else
		uiutil.messageDialog("Plague Pollution", "No tiles near your cities are currently suffering from plague.")
	end
end

local function plagueStrike ()
	log.trace()
	local gameYear = civ.getGameYear()

	-- First, remove any Plague or Black Death units that are leftover from the previous turn:
	for unit in civ.iterateUnits() do
		if isPlagueUnitType(unit.type) then
			unitutil.deleteUnit(unit)
		end
	end

	local plagueTiles = retrieve("plagueTiles")
	for tileId, lastStruckYear in pairs(plagueTiles) do
		local tile = tileutil.getTileById(tileId)

		-- Second, remove db entry for any plague pollution that was cleaned up (prior to its natural recovery) by worker action:
		if tileutil.hasPollution(tile) == false then
			plagueTiles[tileId] = nil
		else
			-- Third, remove plague pollution from any plague tiles that have naturally recovered since the last strike:
			-- Note: not using adjustForDifficulty() on PLAGUE_NATURAL_RECOVERY_YEARS, since the "owner" of the tile could shift during those years,
			--		 and as a more natural rather than civ-driven process, difficulty level seems less relevant anyway
			if gameYear >= (lastStruckYear + constant.mmPlagues.TILE_NATURAL_RECOVERY_YEARS) then
				local bypassTile = false
				for unit in tile.units do
					if unit.type.role == 5 and unitutil.isCleaningUpPollution(unit) == true then
						bypassTile = true
					end
				end
				if bypassTile == true then
					log.info("Bypassed former plague tile " .. tile.x .. "," .. tile.y .. " since a worker is currently cleansing plague there")
				else
					if tileutil.hasPollution(tile) then
						log.update("Found plague on terrain at " .. tile.x .. "," .. tile.y .. " from " .. lastStruckYear .. ", which has now recovered naturally")
						tileutil.removePollution(tile)
						for tribe in tribeutil.iterateActiveTribes(true) do
							if tileutil.isWithinTribeCityRadius(tile, tribe) then
								updateMapView(tile, tribe)
							end
						end
					end
					plagueTiles[tileId] = nil
				end
			end
		end
	end

	-- Fourth, apply new plague strikes:
	local humanHospitalsUsed = 0
	local humanHospitalsCost = 0
	for _, plagueOccurrence in ipairs(PLAGUE_OCCURRENCES) do
		if gameYear >= plagueOccurrence.startYear and gameYear <= plagueOccurrence.endYear then
			local chanceToStrikeInland = math.random(round(plagueOccurrence.minCityChance * 100), round(plagueOccurrence.maxCityChance * 100))
			-- Note: not using adjustForDifficulty() separately on PLAGUE_CHANCE_COASTAL_FACTOR, since we will be applying this on the overall chance
			local chanceToStrikeCoastal = round(chanceToStrikeInland * constant.mmPlagues.COASTAL_CITY_CHANCE_FACTOR)
			log.info("Chance for plague to strike this year: " .. chanceToStrikeInland / 100 .. "% inland, " .. chanceToStrikeCoastal / 100 .. "% coastal")
			local thisYearVirulence = math.random(round(plagueOccurrence.minVirulence * 100), round(plagueOccurrence.maxVirulence * 100))
			log.info("  thisYearVirulence = " .. thisYearVirulence / 100 .. "%")

			for city in civ.iterateCities() do
				local cityChance = chanceToStrikeInland
				if city.coastal == true then
					cityChance = chanceToStrikeCoastal
				end
				if civ.hasImprovement(city, MMIMP.SewerConduits) then
					cityChance = cityChance * ((100 - constant.mmPlagues.SEWER_CONDUITS_CHANCE_REDUCTION_PCT) / 100)
				end
				cityChance = adjustForDifficulty(cityChance, city.owner, false)
				if city.size < plagueOccurrence.minCitySize then
					cityChance = 0
				end

				local randomNumber = math.random(10000)
				log.info(city.owner.adjective .. " city of " .. city.name .. ": " .. cityChance / 100 .. ", randomNumber = " .. randomNumber / 100)
				if randomNumber <= cityChance then
					-- Plague has struck this city!
					local cityVirulence = adjustForDifficulty(thisYearVirulence, city.owner, false)
					log.action("Plague strikes city of " .. city.name .. " with native virulence of " .. cityVirulence / 100 .. "%")

					local createUnitType = nil
					-- Note: deliberately not using adjustForDifficulty() on PLAGUE_VIRULENCE_THRESHOLD_FOR_UNIT
					if cityVirulence >= (constant.mmPlagues.CREATE_UNIT_VIRULENCE_PCT_MIN * 100) then
						createUnitType = plagueOccurrence.unitType
					end

					local aiCityMessageText = "Sad news, sire. "
					if tribeutil.haveWar(city.owner, civ.getPlayerTribe()) then
						aiCityMessageText = "Sire, the sad tidings of our enemies may be to our benefit. "
					end
					local humanCityMessageText = ""
					if createUnitType == nil then
						aiCityMessageText = aiCityMessageText .. "Our embassy in the nation of " .. city.owner.name .. " reports that a plague has struck the city of " .. city.name .. "."
						humanCityMessageText = "Sire, we have received reports of a most dreadful plague near our city of " .. city.name .. "!"
					elseif createUnitType == MMUNIT.Plague then
						aiCityMessageText = aiCityMessageText .. "Our embassy in the nation of " .. city.owner.name .. " reports that a horrific plague has struck the city of " .. city.name .. "."
						humanCityMessageText = "Dreadful news, sire! A horrific plague has struck our city of " .. city.name .. "!"
					else
						aiCityMessageText = aiCityMessageText .. "Our embassy in the nation of " .. city.owner.name .. " reports that the Black Death has struck the city of " .. city.name .. "."
						humanCityMessageText = "Dreadful news, sire! The merciless Black Death has struck our city of " .. city.name .. "!"
					end

					local oldCitySize = city.size
					local oldCitySizeDecimal = cityutil.getSizeAsDecimal(city, humanIsSupreme())
					if civ.hasImprovement(city, MMIMP.Hospital) then
						-- Note: not using adjustForDifficulty() on HOSPITAL_VIRULENCE_REDUCTION_PCT, since the overall city virulence is already
						--		 being adjusted appropriately and the formula is multiplicative not additive
						local predictedSizeWithoutHospital = math.max(oldCitySizeDecimal * (1 - (cityVirulence / 10000)), 1.00)
						local predictedCityVirulence = cityVirulence * ((100 - constant.mmPlagues.HOSPITAL_VIRULENCE_REDUCTION_PCT) / 100)
						local predictedSizeWithHospital = math.max(oldCitySizeDecimal * (1 - (predictedCityVirulence / 10000)), 1.00)
						local hospitalCharge = math.ceil((predictedSizeWithHospital - predictedSizeWithoutHospital) * constant.mmPlagues.HOSPITAL_COST_PER_CITIZEN_SAVED)
						if city.owner.money >= hospitalCharge then
							tribeutil.changeMoney(city.owner, (hospitalCharge * -1))
							cityVirulence = cityVirulence * ((100 - constant.mmPlagues.HOSPITAL_VIRULENCE_REDUCTION_PCT) / 100)
							aiCityMessageText = aiCityMessageText .. " However, the city contains a hospital which significantly reduced casualties."
							humanCityMessageText = humanCityMessageText .. " Fortunately, the city contains a hospital which has reduced potential casualties by " .. round(constant.mmPlagues.HOSPITAL_VIRULENCE_REDUCTION_PCT) .. " percent, at a cost of " .. hospitalCharge .. " gold."
							if city.owner.isHuman == true then
								humanHospitalsUsed = humanHospitalsUsed + 1
								humanHospitalsCost = humanHospitalsCost + hospitalCharge
							end
						else
							local hospitalValue = MMIMP.Hospital.cost * civ.cosmic.shieldRows
							imputil.removeImprovement(city, MMIMP.Hospital)
							tribeutil.changeMoney(city.owner, hospitalValue)
							if city.owner.isHuman == true then
								uiutil.messageDialog("Chief Justiciar's Report", "The Hospital in " .. city.name .. " is unable to cope with a sudden surge in patients, and our treasury does not contain the funds required to support its operation. We have been forced to close and sell this Hospital for " .. hospitalValue .. " gold, in order to provide cash flow for basic operations in our nation.", 425)
							end
						end
					end
					local newCitySizeDecimal = math.max(oldCitySizeDecimal * (1 - (cityVirulence / 10000)), 1.00)

					-- 1. Select the tile on which the plague should strike:
					local candidateTiles = { }
					-- Primary group is non-mountain land tiles that the city is currently working (not including the city tile itself), which are not already polluted with plague
					local tilesWorked = tileutil.getCityTilesWorked(city, false)
					for _, tile in ipairs(tilesWorked) do
						if tileutil.isLandTile(tile) and tileutil.getTerrainId(tile) ~= MMTERRAIN.Mountains and tileutil.hasPollution(tile) == false then
							table.insert(candidateTiles, tile)
						end
					end
					if #candidateTiles == 0 then
						-- Secondary group is non-mountain land tiles that the city is currently working, but which are already polluted with plague
						for _, tile in ipairs(tilesWorked) do
							if tileutil.isLandTile(tile) and tileutil.getTerrainId(tile) ~= MMTERRAIN.Mountains then
								table.insert(candidateTiles, tile)
							end
						end
					end
					local adjacentTiles = tileutil.getAdjacentTiles(city.location, false)
					if #candidateTiles == 0 then
						-- Tertiary group is non-mountain land tiles adjacent to the city, which are not already polluted with plague
						for _, tile in ipairs(adjacentTiles) do
							if civ.isTile(tile) and tileutil.isLandTile(tile) and tileutil.getTerrainId(tile) ~= MMTERRAIN.Mountains and tileutil.hasPollution(tile) == false then
								table.insert(candidateTiles, tile)
							end
						end
					end
					if #candidateTiles == 0 then
						-- Quarternary group is non-mountain land tiles adjacent to the city, but which are already polluted with plague
						for _, tile in ipairs(adjacentTiles) do
							if civ.isTile(tile) and tileutil.isLandTile(tile) and tileutil.getTerrainId(tile) ~= MMTERRAIN.Mountains then
								table.insert(candidateTiles, tile)
							end
						end
					end
					-- If all of these checks fail, then the city is on a single-tile island, and any land tiles in the outer radius of the city are not being worked
					--		or all other land tiles are mountain and therefore impassable (plus generate no Health)
					-- In this case, the destination tile will be nil, so no plague pollution or plague unit will be added
					-- However, the city and its units are still subjected to the plague virulence
					local destinationTile = nil
					if #candidateTiles > 0 then
						local logString = "Found " .. tostring(#candidateTiles) .. " candidate tile(s): "
						for _, ctile in ipairs(candidateTiles) do
							logString = logString .. ctile.x .. "," .. ctile.y .. "; "
						end
						log.info(logString)
						destinationTile = candidateTiles[math.random(#candidateTiles)]
					end

					local humanUnitKilledByAiCityStrike = false
					local unitsKilled = { }

					if destinationTile ~= nil then
						-- 2. Document this tile, and then add plague pollution to it:
						local destinationTileId = tileutil.getTileId(destinationTile)
						plagueTiles[destinationTileId] = gameYear
						log.update("Updated db.plagueTiles with strike at " .. destinationTile.x .. "," .. destinationTile.y .. " in " .. gameYear)
						tileutil.addPollution(destinationTile)
						updateMapView(destinationTile, city.owner)

						-- 3. If appropriate, create the Plague or Black Death unit:
						if createUnitType ~= nil then
							for blockingUnit in destinationTile.units do
								if blockingUnit.owner == city.owner and blockingUnit.type.move > 0 then
									-- 3a. If there are any movable units on the tile belonging to the city owner, move them into the city:
									unitutil.clearOrders(blockingUnit)
									unitutil.teleportUnit(blockingUnit, city.location)
								else
									-- 3b. If there are any units on the tile belonging to OTHER tribes, including other barbarians,
									--	   or if there are any immobile units belonging to the city owner (such as a Monks unit, or a Motte and Bailey Castle unit or
									--	   Stone Castle unit), kill them outright:
									if blockingUnit.owner.isHuman == true then
										local unitDesc = blockingUnit.type.name
										if blockingUnit.veteran == true then
											unitDesc = "Veteran " .. unitDesc
										end
										if blockingUnit.homeCity ~= nil and blockingUnit.homeCity ~= city then
											unitDesc = unitDesc .. " from " .. blockingUnit.homeCity.name
										end
										unitDesc = unitDesc .. " at " .. blockingUnit.x .. "," .. blockingUnit.y
										table.insert(unitsKilled, unitDesc)
										if city.owner.isHuman == false then
											humanUnitKilledByAiCityStrike = true
										end
									end
									-- Does not run mmSurvivors.applyCasualtiesForDefeatedUnit() to remove Health from the home city of the deleted unit
									-- This would exacerbate the impact of the plague, and might invalidate messages about the size reduction experienced
									-- by the city. Also it would apply to a unit's home city, which may or may not be the city victimized by this plague
									-- strike, but could be (or have been) victimized by a different plague strike.
									unitutil.deleteUnit(blockingUnit)
									-- If the unit that is deleted is Monks, the Monastery will be removed in mmImproveWonders.syncSpecialistsWithGameStatus()
									--		which runs immediately after this.
								end
							end

							-- 3c. Create the plague unit:
							unitutil.createByType(createUnitType, civ.getTribe(0), destinationTile, {homeCity = nil})
						end
					else
						destinationTile = city.location
					end

					-- 4. Strike nearby units:
					-- This happens before the city population loss, which may in turn cause *additional* units to be disbanded if they can no longer be supported
					-- But what we don't want is to lose some units *first* due to city population loss, and then to apply the virulence to *remaining* units,
					--		since that could be a more severe impact on units than intended.
					local unitVirulence = cityVirulence * ((100 - constant.mmPlagues.VIRULENCE_REDUCTION_PCT_FOR_UNITS) / 100)
					local tilesWithAffectedUnits = tileutil.getAdjacentTiles(destinationTile, true)
					local foundCityTile = false
					for _, affectedTile in ipairs(tilesWithAffectedUnits) do
						if affectedTile == city.location then
							foundCityTile = true
							break
						end
					end
					if foundCityTile == false then
						table.insert(tilesWithAffectedUnits, city.location)
					end
					for _, affectedTile in ipairs(tilesWithAffectedUnits) do
						if civ.isTile(affectedTile) and tileutil.isLandTile(affectedTile) then
							for unit in affectedTile.units do
								if isHumanUnitType(unit.type) == true and isCitySpecialistUnitType(unit.type) == false and unit.homeCity ~= nil then
									local unitRandomNumber = math.random(10000)
									log.info(unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y .. ": virulence = " .. unitVirulence / 100 .. ", unitRandomNumber = " .. unitRandomNumber / 100)
									if unitRandomNumber <= unitVirulence then
										if unit.owner.isHuman == true then
											local unitDesc = unit.type.name
											if unit.veteran == true then
												unitDesc = "Veteran " .. unitDesc
											end
											if unit.homeCity ~= city then
												unitDesc = unitDesc .. " from " .. unit.homeCity.name
											end
											unitDesc = unitDesc .. " at " .. unit.x .. "," .. unit.y
											table.insert(unitsKilled, unitDesc)
											if city.owner.isHuman == false then
												humanUnitKilledByAiCityStrike = true
											end
										end
										-- Does not run mmSurvivors.applyCasualtiesForDefeatedUnit() to remove Health from the home city of the deleted unit
										-- This would exacerbate the impact of the plague, and might invalidate messages about the size reduction experienced
										-- by the city. Also it would apply to a unit's home city, which may or may not be the city victimized by this plague
										-- strike, but could be (or have been) victimized by a different plague strike.
										unitutil.deleteUnit(unit)
										-- If the unit that is deleted is Monks, the Monastery will be removed in mmImproveWonders.syncSpecialistsWithGameStatus()
										--		which runs immediately after this.
									end
								end
							end
						end
					end
					if humanUnitKilledByAiCityStrike == true then
						if tribeutil.haveWar(city.owner, civ.getPlayerTribe()) then
							aiCityMessageText = aiCityMessageText .. " Alas, our own troops in that area have also fallen victim to this indiscriminate killer!"
						else
							aiCityMessageText = aiCityMessageText .. " Worse yet, our own troops in that area have fallen victim to this indiscriminate killer!"
						end
						aiCityMessageText = aiCityMessageText .. "||The following units were lost:|"
						for _, unitKilledDesc in ipairs(unitsKilled) do
							aiCityMessageText = aiCityMessageText .. "|" .. unitKilledDesc
						end
					end

					-- 5. Strike city population:
					setCitySize(city, newCitySizeDecimal)
					if city.owner.isHuman == true then
						if city.size < oldCitySize then
							humanCityMessageText = humanCityMessageText .. "||The population has been reduced from " .. oldCitySize .. " to " .. city.size
						else
							humanCityMessageText = humanCityMessageText .. "||Although the city's Health has declined, the population has not changed"
						end
					end

					-- 6. Append message about units killed in step 5
					if city.owner.isHuman == true then
						if #unitsKilled >= 1 then
							if #unitsKilled == 1 then
								humanCityMessageText = humanCityMessageText .. ", and 1 unit has been lost:|"
							else
								humanCityMessageText = humanCityMessageText .. ", and " .. #unitsKilled .. " units have been lost:|"
							end
							for _, unitKilledDesc in ipairs(unitsKilled) do
								humanCityMessageText = humanCityMessageText .. "|" .. unitKilledDesc
							end
						else
							if city.size < oldCitySize then
								humanCityMessageText = humanCityMessageText .. ", but"
							else
								humanCityMessageText = humanCityMessageText .. ", and"
							end
							humanCityMessageText = humanCityMessageText .. " no units have been lost."
						end
					end

					-- 7. Message to user:
					if city.owner.isHuman == true then
						civ.ui.centerView(city.location)
						uiutil.messageDialog("Chief Justiciar", humanCityMessageText, 500)
					elseif tribeutil.hasEmbassy(civ.getPlayerTribe(), city.owner) or humanUnitKilledByAiCityStrike == true then
						if humanUnitKilledByAiCityStrike == true and tribeutil.hasEmbassy(civ.getPlayerTribe(), city.owner) == false then
							aiCityMessageText = string.gsub(aiCityMessageText, "embassy", "commander")
						end
						uiutil.messageDialog("Chancellor", aiCityMessageText, 500)
					end
				end
			end
		end
	end
	if humanHospitalsUsed > 0 or humanHospitalsCost > 0 then
		local impName = MMIMP.Hospital.name
		if humanHospitalsUsed > 1 then
			impName = impName .. "s"
		end
		uiutil.messageDialog("Treasurer's Report", "Our national treasury funded the operation of " .. humanHospitalsUsed .. " " .. impName ..
			" caring for plague patients, at a total cost of " .. humanHospitalsCost .. " gold.", 500)
	end
	store("plagueTiles", plagueTiles)
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 9

return {
	confirmLoad = confirmLoad,

	documentNaturalPlague = documentNaturalPlague,
	isPlagueUnitType = isPlagueUnitType,
	listPlagueTiles = listPlagueTiles,
	plagueStrike = plagueStrike,
}
