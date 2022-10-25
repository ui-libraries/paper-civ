-- mmUnits.lua
-- by Knighttime

log.trace()

constant.mmUnits = { }
constant.mmUnits.CAPTURE_SHIP_PCT = 33							-- Percent chance that a naval unit ("ship") will be captured by the winning unit if it is defeated
constant.mmUnits.CAPTURED_SHIP_DAMAGE_PCT = 90					-- Percent damage that is applied to the captured unit when it is recreated for its new owner
constant.mmUnits.MERCHANT_INIT_COST = 3							-- Initial cost at beginning of game for Merchant, multiplied by civ.cosmic.shieldRows
																--		Adjusted by year; see setTradeUnitCosts() function and table there
constant.mmUnits.COMMERCIAL_TRADER_CITY_SIZE_MIN = 8			-- Minimum size that a city must be in order to build a Commercial Trader (rather than a Merchant)
constant.mmUnits.COMMERCIAL_TRADER_INIT_COST = 5				-- Initial cost at beginning of game for Commercial Trader, multiplied by civ.cosmic.shieldRows
																--		Adjusted by year; see setTradeUnitCosts() function and table there
constant.mmUnits.YEARS_BETWEEN_TRADE_COST_INCREASES = 250		-- Every this many years, the cost of trade units increases by 1 x civ.cosmic.shieldRows
constant.mmUnits.SIEGE_TOWER_CITY_ACTIVATION_RANGE = 2			-- Within this number of tiles of an enemy city, a Siege Engineer becomes a Siege Tower
constant.mmUnits.SIEGE_TOWER_CASTLE_ACTIVATION_RANGE = 1		-- Within this number of tiles of an enemy castle, a Siege Engineer becomes a Siege Tower
constant.mmUnits.FIELD_UNITS_SUPPORTED_PER_HEALTH = 5			-- All human units with a role < 5 that are not located in a city must live "off the land". The number
																--		of units that each tile can support is determined by the number of Health that tile generates.
																--		A castle also increases the potential support by this value (i.e., the castle counts as a unit of Health)
constant.mmUnits.FIELD_UNITS_SUPPORTED_MIN = 1					-- This is the minimum number of units that each tile can support
constant.mmUnits.FIELD_UNITS_SUPPORTED_URBAN = 10				-- Special override of unit support for Urban tiles which produce no Health

local FRACTIONAL_MOVEMENT = {
	{ unittype = MMUNIT.CommercialTrader,	movement = 1.5 },
	{ unittype = MMUNIT.Couillard,			movement = 1.5 },
	{ unittype = MMUNIT.Demiculverin,		movement = 1.5 },
	{ unittype = MMUNIT.Fowler,				movement = 1.5 },
	{ unittype = MMUNIT.Inquisitor,			movement = 1.5 },
	{ unittype = MMUNIT.Saker,				movement = 2.5 },
	{ unittype = MMUNIT.Yeoman,				movement = 1.5 },
}

local UNITTYPE_FLAG_TEXT = {
	[1]  = "Can see units two tiles away.",
	[2]  = "Ignores enemy zones of control.",
	[3]  = "Can make naval assaults.",
	[4]  = "Cannot attack units on a land tile.",
	[5]  = "(Can attack aircraft in flight.)",
	[6]  = "Must end its turn adjacent to a land tile.",
	[7]  = "Ignores City Walls.",
	[8]  = "(Can carry friendly air units.)",
	[9]  = "(Can make paradrops.)",
	[10] = "Uses 1 movement point per tile over any terrain.",
	[11] = "Defense +50% vs land units with 2 MP and 1 HP.",
	[12] = "Only Tribal Monarchy governments can build.",
	[13] = "Destroyed after attacking.",
	[14] = "(Defense +100% vs air and missile units.)",
	[15] = " "
}

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
-- Copied from mmImproveWonders which is the native and expected home for this function
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

-- Copied from mmImproveWonders which is the native and expected home for this function
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

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
-- It is assumed that tribe is always equal to city.owner.
-- However this function supports being called with ONLY a tribe and nil as the city, in which case it will determine whether
--		that tribe *in general* (i.e., any city) can build that unit type.
local function canBuildUnit (tribe, city, unittype)
	log.trace()

	-- Units not in the game:
	if unittype.domain > domain.Sea or unittype.id >= civ.cosmic.numberOfUnitTypes then
		return false
	end

	local tribeHasPrereqTech = false
	if unittype.prereq == nil or civ.hasTech(tribe, unittype.prereq) == true or
		-- Special case:
		unittype == MMUNIT.SwissPikeman then
		tribeHasPrereqTech = true
	end
	local tribeHasObsoleteTech = false
	if unittype.expires ~= nil and civ.hasTech(tribe, unittype.expires) == true then
		tribeHasObsoleteTech = true
	end

	if tribeHasPrereqTech == true and tribeHasObsoleteTech == false then
		-- Basic requirements are met. But some unit types may still be blocked, per the following custom rules:

		-- These units are available to AI tribes (or barbarians) but not human tribes, since they would be duplicates:
		if unittype == MMUNIT.ArbalestierAI or
		   unittype == MMUNIT.ArcherAI or
		   unittype == MMUNIT.BowmanAI or
		   unittype == MMUNIT.CrossbowmanAI or
		   unittype == MMUNIT.DemilancerAI or
		   unittype == MMUNIT.HalberdierAI or
		   unittype == MMUNIT.LongbowmanAI then
			if tribe.isHuman == false then
				if unittype == MMUNIT.ArcherAI and civ.hasTech(tribe, techutil.findByName("Longbows", true)) then
					return false else return true
				end
			else return false end

		-- Special rules for "peasant"-type units:
		elseif unittype == MMUNIT.Peasant then
			local result = not(canBuildUnit(tribe, city, MMUNIT.Serf))
			return result
		elseif unittype == MMUNIT.Yeoman then
			local result = not(canBuildUnit(tribe, city, MMUNIT.Serf))
			return result
		elseif unittype == MMUNIT.Serf then
			if tribe.government == MMGOVERNMENT.PrimitiveMonarchy or tribe.government == MMGOVERNMENT.FeudalMonarchy then return true else return false end
		elseif unittype == MMUNIT.Refugee then
			return false
		elseif unittype == MMUNIT.PeasantMilitia then
			return false

		-- Other special rules:
		elseif unittype == MMUNIT.SwissPikeman then
			if civ.hasTech(tribe, techutil.findByName("Advanced Polearms", true)) and wonderutil.getOwner(MMWONDER.PalaceofthePopes) == tribe then return true else return false end
		elseif unittype == MMUNIT.MonasticKnight then
			if city == nil or civ.hasImprovement(city, MMIMP.Monastery) == true then return true else return false end
		elseif unittype == MMUNIT.Inquisitor then
			if city ~= nil then
				if civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == true or
				   civ.hasImprovement(city, MMIMP.GothicCathedral) == true or
				   MMWONDER.IconicRomanesqueCathedral.city == city or
				   MMWONDER.OpulentRomanesqueCathedral.city == city or
				   MMWONDER.GloriousGothicCathedral.city == city or
				   MMWONDER.MajesticGothicCathedral.city == city or
				   MMWONDER.BrunelleschisDome.city == city or
				   cityHasRomanesqueCathedralBenefit(city) == true
				then return true else return false end
			else
				return true
			end
		elseif unittype == MMUNIT.Envoy then
			if city ~= nil then
				if civ.hasTech(tribe, MMUNIT.Inquisitor.prereq) == false or
				   ( civ.hasImprovement(city, MMIMP.RomanesqueCathedral) == false and
					 civ.hasImprovement(city, MMIMP.GothicCathedral) == false and
					 MMWONDER.IconicRomanesqueCathedral.city ~= city and
					 MMWONDER.OpulentRomanesqueCathedral.city ~= city and
					 MMWONDER.GloriousGothicCathedral.city ~= city and
					 MMWONDER.MajesticGothicCathedral.city ~= city and
					 MMWONDER.BrunelleschisDome.city ~= city and
					 cityHasRomanesqueCathedralBenefit(city) == false
				   )
				then return true else return false end
			else
				return true
			end
		elseif unittype == MMUNIT.CommercialTrader then
			if city == nil or city.size >= constant.mmUnits.COMMERCIAL_TRADER_CITY_SIZE_MIN then return true else return false end
		elseif unittype == MMUNIT.Merchant then
			if city == nil or city.size < constant.mmUnits.COMMERCIAL_TRADER_CITY_SIZE_MIN or civ.hasTech(tribe, MMUNIT.CommercialTrader.prereq) == false then return true else return false end
		elseif unittype == MMUNIT.Archer then
			if civ.hasTech(tribe, techutil.findByName("Longbows", true)) then return false else return true end
		elseif unittype == MMUNIT.SiegeEngineer then
			if tribe.isHuman == true or (tribeutil.hasWarWithAny(tribe) == true and (city == nil or civ.hasImprovement(city, MMIMP.Barracks) == false)) then return true else return false end
		elseif unittype == MMUNIT.SiegeTower then
			if tribe.isHuman == false and tribeutil.hasWarWithAny(tribe) == true and (city == nil or civ.hasImprovement(city, MMIMP.Barracks) == true) then return true else return false end
		elseif unittype == MMUNIT.Springald then
			if city == nil or civ.hasImprovement(city, MMIMP.Barracks) == true then return true else return false end
		elseif unittype == MMUNIT.Couillard or unittype == MMUNIT.Trebuchet then
			if city == nil or
			   (hasSpecialist(MMUNIT.Smith, city) == false and hasSpecialist(MMUNIT.Forge, city) == false and civ.hasImprovement(city, MMIMP.Foundry) == false) or
			   (civ.hasTech(tribe, techutil.findByName("Bombards", true)) == false and
				civ.hasTech(tribe, techutil.findByName("Corned Gunpowder", true)) == false and
				civ.hasTech(tribe, techutil.findByName("Trunnions / Limbers", true)) == false)
			then return true else return false end
		elseif unittype == MMUNIT.Ribauldequin or unittype == MMUNIT.Potdefer then
			if (city == nil or civ.hasImprovement(city, MMIMP.Foundry) == true or hasSpecialist(MMUNIT.Smith, city) == true or hasSpecialist(MMUNIT.Forge, city) == true) and
				civ.hasTech(tribe, techutil.findByName("Bombards", true)) == false and
				civ.hasTech(tribe, techutil.findByName("Corned Gunpowder", true)) == false and
				civ.hasTech(tribe, techutil.findByName("Trunnions / Limbers", true)) == false
			then return true else return false end
		elseif unittype == MMUNIT.Fowler or unittype == MMUNIT.Serpentine or unittype == MMUNIT.Falconet then
			if city == nil or civ.hasImprovement(city, MMIMP.Foundry) == true or hasSpecialist(MMUNIT.Smith, city) == true or hasSpecialist(MMUNIT.Forge, city) == true
			then return true else return false end
		elseif unittype == MMUNIT.Bombard or unittype == MMUNIT.Demiculverin or unittype == MMUNIT.Saker then
			if city == nil or civ.hasImprovement(city, MMIMP.Foundry) == true or hasSpecialist(MMUNIT.Forge, city) == true
			then return true else return false end
		elseif unittype == MMUNIT.Basilisk or unittype == MMUNIT.Culverin or unittype == MMUNIT.FieldCulverin then
			if city == nil or civ.hasImprovement(city, MMIMP.Foundry) == true
			then return true else return false end
		elseif unittype == MMUNIT.ArmedCarrack then
			if city == nil or
			   (cityIsTrulyCoastal(city) and (civ.hasImprovement(city, MMIMP.Foundry) == true or hasSpecialist(MMUNIT.Forge, city) == true))
			then return true else return false end
		else
			-- unittype is not a specific type with custom rules
			if unittype.domain == domain.Sea then
				if city == nil or cityIsTrulyCoastal(city) then return true else return false end
			else
				return true
			end		-- i.e. unittype.domain ~= domain.Sea
		end		-- i.e. unittype is not a specific type with custom rules
	else
		-- tribeHasPrereqTech == false or tribeHasObsoleteTech == true:
		return false
	end		-- i.e. tribeHasPrereqTech == false or tribeHasObsoleteTech == true
end

-- Code here is quite similar to mmRangedUnits.captureArtilleryUnit(), but the formulas are somewhat different
local function captureNavalUnit (winningUnit, losingUnit, battleTile)
	log.trace()
	local captureOccurred = false
	if losingUnit.type.domain == domain.Sea and
	   unitutil.wasAttacker(losingUnit) == false and
	   winningUnit.type.domain == domain.Sea then
		log.info("Losing unit was defender (" .. losingUnit.type.name .. ") and winning unit was attacker (" .. winningUnit.type.name .. ")")
		if unitutil.tileContainsOtherUnit(battleTile, losingUnit) then
			log.info("Found additional defender(s) for " .. losingUnit.type.name .. ", no capture")
		elseif battleTile.city ~= nil and battleTile.city.owner ~= winningUnit.owner then
			log.info(losingUnit.type.name .. " was in another tribe's city, no capture")
		else
			local captureChance = constant.mmUnits.CAPTURE_SHIP_PCT
			local randomNumber = math.random(100)
			log.info("Naval unit capture chance = " .. captureChance .. ", randomNumber = " .. randomNumber)
			if randomNumber <= captureChance then
				log.info("No remaining defenders found for " .. losingUnit.type.name .. ", random check successful, initiating capture")
				local typeToCreate = losingUnit.type
				-- One exception:
				if typeToCreate == MMUNIT.VikingLongship then
					typeToCreate = MMUNIT.Longship
				end
				local capturedUnit = unitutil.createByType(typeToCreate, winningUnit.owner, winningUnit.location)
				if capturedUnit ~= nil then
					captureOccurred = true
					-- Captured unit is supported by the home city of the unit that captured it:
					capturedUnit.homeCity = winningUnit.homeCity
					local homeCityName = "NONE"
					if capturedUnit.homeCity ~= nil then
						homeCityName = capturedUnit.homeCity.name
					end
					log.action("  Set home city of " .. capturedUnit.owner.adjective .. " " .. capturedUnit.type.name .. " to " .. homeCityName)
					-- Captured unit is created with damage:
					capturedUnit.damage = round(capturedUnit.type.hitpoints * (constant.mmUnits.CAPTURED_SHIP_DAMAGE_PCT / 100))
					log.action("  Set HP of " .. capturedUnit.owner.adjective .. " " .. capturedUnit.type.name .. " to " .. constant.mmUnits.CAPTURED_SHIP_DAMAGE_PCT .. "%")
					-- Captured unit cannot move this turn:
					capturedUnit.moveSpent = capturedUnit.type.move
					if capturedUnit.owner.isHuman == true then
						uiutil.messageDialog("Admiral", "Good news! Our troops at " .. capturedUnit.x .. "," .. capturedUnit.y .. " have captured a " .. losingUnit.owner.adjective .. " " .. capturedUnit.type.name .. "!")
					elseif losingUnit.owner.isHuman == true then
						uiutil.messageDialog("Admiral", "Oh no! Enemy troops at " .. capturedUnit.x .. "," .. capturedUnit.y .. " have managed to capture our " .. capturedUnit.type.name .. "!")
					end
				end
			else
				log.info("No remaining defenders found for " .. losingUnit.type.name .. ", random check failed, no capture")
			end
		end
	end
	return captureOccurred
end

local function formatUnitInfo (unit)
	log.trace()
	local dataTable = { }
	if unit ~= nil then
		local specialTextTable = { }
		for i = 1, 15 do
			if unit.type.flags & 2 ^ (i - 1) == 2 ^ (i - 1) then
				table.insert(specialTextTable, UNITTYPE_FLAG_TEXT[i])
			end
		end
		local movementRate = string.format("%.2f", unitutil.getMovesRemaining(unit)) .. " out of " .. tostring(unitutil.getMovementPointsAsMoves(unit.type.move))
		if unit.type.move == 0 then
			movementRate = "Immobile"
		end
		local currAttack = tostring(unit.type.attack)
		if unit.type.attack ~= MM_BASE_UNIT_STATS[unit.type.id].baseAttack then
			currAttack = currAttack .. "  (reduced from " .. tostring(MM_BASE_UNIT_STATS[unit.type.id].baseAttack) .. ")"
		end
		local currFirepower = tostring(unit.type.firepower)
		if unit.type.firepower ~= MM_BASE_UNIT_STATS[unit.type.id].baseFirepower then
			currFirepower = currFirepower .. "  (reduced from " .. tostring(MM_BASE_UNIT_STATS[unit.type.id].baseFirepower) .. ")"
		end
		table.insert(dataTable, { statLabel = "Unit ID:",			statValue = tostring(unit.id),										space = " ",	specialText = specialTextTable[1] or " " })
		table.insert(dataTable, { statLabel = "Build Cost:",		statValue = tostring(unit.type.cost * civ.cosmic.shieldRows) ..
																				" Materials",											space = " ",	specialText = specialTextTable[2] or " " })
		table.insert(dataTable, { statLabel = "Attack Strength:",	statValue = currAttack,												space = " ",	specialText = specialTextTable[3] or " " })
		table.insert(dataTable, { statLabel = "Defense Strength:",	statValue = tostring(unit.type.defense),							space = " ",	specialText = specialTextTable[4] or " " })
		table.insert(dataTable, { statLabel = "Hit Points:",		statValue = tostring(unit.hitpoints) .. " out of " ..
																				tostring(unit.type.hitpoints),							space = " ",	specialText = specialTextTable[5] or " " })
		table.insert(dataTable, { statLabel = "Firepower:",			statValue = currFirepower,											space = " ",	specialText = specialTextTable[6] or " " })
		table.insert(dataTable, { statLabel = "Movement Rate:",		statValue = movementRate,											space = " ",	specialText = specialTextTable[7] or " " })
		if unit.type.domain == domain.Sea then
			table.insert(dataTable, { statLabel = "Carries:",		statValue = tostring(unit.type.hold),								space = " ",	specialText = specialTextTable[8] or " " })
		end
	end
	return dataTable
end

local function getStackAttritionValues (tile, tribe)
	log.trace()
	local tribeHumanUnitsOnTile = 0
	for unit in tile.units do
		if unit.owner == tribe and unit.type.role < 5 and isHumanUnitType(unit.type) then
			tribeHumanUnitsOnTile = tribeHumanUnitsOnTile + 1
		end
	end
	local terrainId = tileutil.getTerrainId(tile)
	local tileHealthProduction = TERRAIN_DATA[terrainId].health
	if tileutil.hasFarm(tile) then
		tileHealthProduction = round( (tileHealthProduction + TERRAIN_DATA[terrainId].irrigateBonus) * 1.49 )
	elseif tileutil.hasIrrigation(tile) then
		tileHealthProduction = tileHealthProduction + TERRAIN_DATA[terrainId].irrigateBonus
	end
	if tileutil.hasPollution(tile) then
		tileHealthProduction = round(tileHealthProduction * 0.5)
	end
	local unitSupportAvailable = math.max(tileHealthProduction * constant.mmUnits.FIELD_UNITS_SUPPORTED_PER_HEALTH, constant.mmUnits.FIELD_UNITS_SUPPORTED_MIN)
	if terrainId == MMTERRAIN.Urban then
		unitSupportAvailable = constant.mmUnits.FIELD_UNITS_SUPPORTED_URBAN
	end
	if hasCastle(tile) then
		unitSupportAvailable = unitSupportAvailable + constant.mmUnits.FIELD_UNITS_SUPPORTED_PER_HEALTH
	end
	return tribeHumanUnitsOnTile, unitSupportAvailable
end

local function managePeasantMilitia (tribe)
	log.trace()
	local canConscript = (MMUNIT.PeasantMilitia.prereq == nil or civ.hasTech(tribe, MMUNIT.PeasantMilitia.prereq) == true)		-- tribeHasPrereqTech = true
				  and not(MMUNIT.PeasantMilitia.expires ~= nil and civ.hasTech(tribe, MMUNIT.PeasantMilitia.expires) == true)	-- tribeHasObsoleteTech = false
	for city in civ.iterateCities() do
		if city.owner == tribe then
			local enemyUnitsFound = 0
			for _, tile in ipairs(tileutil.getTilesByDistance(city.location, 3, false)) do
				if civ.isTile(tile) and tileutil.isLandTile(tile) then
					for unit in tile.units do
						if unit.owner ~= city.owner and unit.type.domain == domain.Land and unit.type.attack > 0 then
							if tribeutil.haveWar(city.owner, unit.owner) then
								enemyUnitsFound = enemyUnitsFound + 1
							end
						end
					end
				end
			end
			local tribeUnitsFound = 0
			for _, tile in ipairs(tileutil.getAdjacentTiles(city.location, true)) do
				if civ.isTile(tile) and tileutil.isLandTile(tile) then
					for unit in tile.units do
						if unit.owner == city.owner and unit.type.domain == domain.Land and unit.type.defense > 0 and unit.type.role < 5 and
						   unit.type ~= MMUNIT.MotteandBailey and unit.type ~= MMUNIT.StoneCastle then
							tribeUnitsFound = tribeUnitsFound + 1
						end
					end
				end
			end
			local pmUnitIds = { }
			for unit in cityutil.iterateHomeCityUnits(city) do
				if unit.type == MMUNIT.PeasantMilitia then
					table.insert(pmUnitIds, unit.id)
				end
			end
			local pmUnitsSupported = #pmUnitIds

			if (enemyUnitsFound > 0 and canConscript == true) or pmUnitsSupported > 0 then
				log.info(city.name .. ": " .. enemyUnitsFound .. " enemy units, " .. tribeUnitsFound .. " tribe units")
				local pmUnitsNeeded = enemyUnitsFound - tribeUnitsFound
				-- Special case: Even a single enemy is sufficient to cause you to (a) conscript a second defender, or... (see below)
				if enemyUnitsFound == 1 and tribeUnitsFound == 1 then
					pmUnitsNeeded = 1
				end
				local pmUnitsPermitted = city.size
				log.info("  " .. pmUnitsNeeded .. " Peasant Militia needed, " .. pmUnitsPermitted .. " permitted, " .. pmUnitsSupported .. " found")
				local pmUnitsToConscript = math.min(pmUnitsNeeded, math.max(pmUnitsPermitted - pmUnitsSupported, 0))
				if canConscript == false then
					pmUnitsToConscript = 0
				end
				local pmUnitsToDischarge = math.max(math.max(pmUnitsSupported - pmUnitsPermitted, 0), math.min(math.abs(math.min(pmUnitsNeeded, 0)), pmUnitsSupported))
				-- Special case: Even a single enemy is sufficient to cause you to ... (see above, or...) (b) keep a second defender if that defender was conscripted on a previous turn
				if enemyUnitsFound == 1 and tribeUnitsFound == 2 and pmUnitsSupported == 1 and pmUnitsToDischarge == 1 and pmUnitsPermitted >= 1 then
					pmUnitsToDischarge = 0
				end
				if pmUnitsToConscript > 0 then
					local tribeGov = tribeutil.getCurrentGovernmentData(tribe, MMGOVERNMENT)
					local freeSupportByGov = tribeGov.support or city.size
					local unitSupportPaid = cityutil.getNumUnitsSupported(city) - freeSupportByGov
					local unitSupportAvailable = city.totalShield - unitSupportPaid
					local pmCost = MMUNIT.PeasantMilitia.cost * cityutil.getShieldColumns(tribe, humanIsSupreme()) * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR
					-- Following message should really be log.info, but making it action serves as a decent header for subsequent steps if the console is set to that level
					log.action("  " .. pmUnitsToConscript .. " Peasant Militia to conscript for " .. city.name .. "; " .. unitSupportAvailable .. " more unit(s) can be supported; each costs " .. pmCost .. " gold, have " .. tribe.money .. " gold")
					local pmUnitsConscripted = 0
					while pmUnitsToConscript > 0 and unitSupportAvailable > 0 and tribe.money >= pmCost do
						local militia = unitutil.createByType(MMUNIT.PeasantMilitia, tribe, city.location, {homeCity = city})
						if tribe.isHuman == false then
							-- Unit will not be allowed to move on the first turn after its creation (AI often moves these units out of the city immediately, which negates their primary purpose of defense)
							-- They should not be permanently immobile units, though, since that would permanently remove their ability to attack in any situation
							militia.moveSpent = militia.type.move
							log.action("Set " .. militia.type.name .. " moves remaining to 0")
							militia.order = 0x01
							log.action("Set " .. militia.type.name .. " order to Fortifying")
						end
						pmUnitsToConscript = pmUnitsToConscript - 1
						unitSupportAvailable = unitSupportAvailable - 1
						pmUnitsConscripted = pmUnitsConscripted + 1
						tribeutil.changeMoney(tribe, pmCost * -1)
					end
					if tribe.isHuman == true then
						civ.ui.centerView(city.location)
						local messageText = ""
						if pmUnitsConscripted > 0 then
							messageText = "We have been forced to conscript " .. tostring(pmUnitsConscripted) .. " Peasant Militia to aid in the defense of " .. city.name .. ", at a cost of " .. tostring(pmUnitsConscripted * pmCost) .. " gold."
							if pmUnitsToConscript > 0 then
								messageText = messageText .. "||We sought to conscript an additional " .. tostring(pmUnitsToConscript) .. " Peasant Militia, but insufficient resources were available to equip them! The city magistrate has requested that we send military units to " .. city.name .. " immediately."
							end
						else
							messageText = "We tried desperately to conscript " .. tostring(pmUnitsToConscript) .. " Peasant Militia to aid in the defense of " .. city.name .. ", but insufficient resources were available to equip them! The city magistrate is pleading for us to send military assistance at once!"
						end
						uiutil.messageDialog("Constable's Report", messageText, 420)
					end
				elseif pmUnitsToDischarge > 0 then
					log.info("  " .. pmUnitsToDischarge .. " Peasant Militia to discharge")
					if tribe.isHuman == true then
						civ.ui.centerView(city.location)
						uiutil.messageDialog("Constable's Report", "We have dismissed " .. tostring(pmUnitsToDischarge) .. " Peasant Militia from " .. city.name .. ", with thanks for their service, and they have returned to their normal occupations.", 420)
					end
					for _, unitId in ipairs(pmUnitIds) do
						if pmUnitsToDischarge > 0 then
							local unit = civ.getUnit(unitId)
							unitutil.deleteUnit(unit)
							pmUnitsToDischarge = pmUnitsToDischarge - 1
						end
					end
				end
			end
		end
	end
end

local function setTradeUnitCosts ()
	-- Cost of Merchant and Commercial Trader increase by 10 every 250 years (constant.mmUnits.YEARS_BETWEEN_TRADE_COST_INCREASES)
	-- Base game: Caravan = 50, Freight = 50
	log.trace()
	local newMerchantCost = math.floor((civ.getGameYear() - 500) / constant.mmUnits.YEARS_BETWEEN_TRADE_COST_INCREASES) + constant.mmUnits.MERCHANT_INIT_COST
	if newMerchantCost ~= MMUNIT.Merchant.cost then
		log.action("Adjusted cost of " .. MMUNIT.Merchant.name .." unit from " .. round(MMUNIT.Merchant.cost * civ.cosmic.shieldRows) .. " to " .. round(newMerchantCost * civ.cosmic.shieldRows) .. " Materials")
		MMUNIT.Merchant.cost = newMerchantCost
	else
		log.info("Confirmed cost of " .. MMUNIT.Merchant.name .." unit at " .. round(MMUNIT.Merchant.cost * civ.cosmic.shieldRows) .. " Materials")
	end
	local newTraderCost = math.floor((civ.getGameYear() - 500) / constant.mmUnits.YEARS_BETWEEN_TRADE_COST_INCREASES) + constant.mmUnits.COMMERCIAL_TRADER_INIT_COST
	if newTraderCost ~= MMUNIT.CommercialTrader.cost then
		log.action("Adjusted cost of " .. MMUNIT.CommercialTrader.name .." unit from " .. round(MMUNIT.CommercialTrader.cost * civ.cosmic.shieldRows) .. " to " .. round(newTraderCost * civ.cosmic.shieldRows) .. " Mterials")
		MMUNIT.CommercialTrader.cost = newTraderCost
	else
		log.info("Confirmed cost of " .. MMUNIT.CommercialTrader.name .. " unit at " .. round(MMUNIT.CommercialTrader.cost * civ.cosmic.shieldRows) .. " Materials")
	end
end

local function setFractionalMovement ()
	log.trace()
	for _, data in ipairs(FRACTIONAL_MOVEMENT) do
		data.unittype.move = round(data.movement * totpp.movementMultipliers.aggregate)
		log.action("Set " .. data.unittype.name .. " movement to " .. tostring(data.movement) .. " tiles per turn")
	end
end

local function setShipAttackRule (tribe, unit)
	-- "tribe" is required, "unit" is optional; if nil, attack rule will be set for all ships with attack potential
	log.trace()
	if unit ~= nil and (unit.type.domain ~= domain.Sea or unit.type.attack == 0) then
		return
	end
	local seaAttacksOnly = false
	if tribe.isHuman == true then
		seaAttacksOnly = true
	elseif unit ~= nil and unit.location.city == nil then
		for _, adjTile in ipairs(tileutil.getAdjacentTiles(unit.location, false)) do
			if civ.isTile(adjTile) and tileutil.isLandTile(adjTile) and unitutil.tileContainsOtherTribeUnit(adjTile, unit.owner) then
				seaAttacksOnly = true
				break
			end
		end
	end
	if unit ~= nil then
		if seaAttacksOnly == true and unitutil.hasFlagSubmarineAdvantagesDisadvantages(unit.type) == false then
			unitutil.addFlagSubmarineAdvantagesDisadvantages(unit.type)
		elseif seaAttacksOnly == false and unitutil.hasFlagSubmarineAdvantagesDisadvantages(unit.type) == true then
			unitutil.removeFlagSubmarineAdvantagesDisadvantages(unit.type)
		end
	else
		for unittype in unitutil.iterateUnitTypes() do
			if unittype.domain == domain.Sea and unittype.attack > 0 then
				if seaAttacksOnly == true and unitutil.hasFlagSubmarineAdvantagesDisadvantages(unittype) == false then
					unitutil.addFlagSubmarineAdvantagesDisadvantages(unittype)
				elseif seaAttacksOnly == false and unitutil.hasFlagSubmarineAdvantagesDisadvantages(unittype) == true then
					unitutil.removeFlagSubmarineAdvantagesDisadvantages(unittype)
				end
			end
		end
	end
end

local function setupInitialUnits ()
	log.trace()
	-- All nations begin the game with 2 Peasants. If the game engine gave them 2 Peasants already, due to a disadvantageous starting position,
	-- 		give them a free Spearman instead of a third Peasant. (Note that the game engine may also/instead have given them a free Axeman.)
	for tribe in tribeutil.iterateActiveTribes(false) do
		local peasantCount = 0
		local startingLocation = nil
		for unit in civ.iterateUnits() do
			if unit.owner == tribe and unit.type.role == 5 then
				peasantCount = peasantCount + 1
				startingLocation = unit.location
			end
		end
		if peasantCount == 1 then
			unitutil.createByType(MMUNIT.Peasant, tribe, startingLocation, {homeCity = nil})
		else
			unitutil.createByType(MMUNIT.Spearman, tribe, startingLocation, {homeCity = nil})
		end
	end
end

local function stackAttrition (tribe)
	log.trace()
	if tribe.isHuman == true then
		local locationResults = { }
		for unit in civ.iterateUnits() do
			if unit.owner == tribe and unit.type.role < 5 and isHumanUnitType(unit.type) then
				local tile = unit.location
				local terrainId = tileutil.getTerrainId(tile)
				if tile.city == nil and terrainId ~= MMTERRAIN.Sea then
					local tileId = tileutil.getTileId(tile)
					if locationResults[tileId] == nil then
						locationResults[tileId] = {
							x = tile.x,
							y = tile.y,
							unitDetails = { }
						}
						local tribeHumanUnitsOnTile, unitSupportAvailable = getStackAttritionValues(tile, tribe)
						locationResults[tileId].hpLost = math.min(unitSupportAvailable - tribeHumanUnitsOnTile, 0) * -1
						locationResults[tileId].summary = "My lord, attrition has taken place at " .. tile.x .. "," .. tile.y .. " due to a lack of food and fresh water for our troops! The " .. MMTERRAIN[terrainId] .. " terrain at this location can support " .. unitSupportAvailable .. " units, but " .. tribeHumanUnitsOnTile .. " units are currently camped there. Each has suffered " .. locationResults[tileId].hpLost .. " HP of damage due to insufficient supplies:|"
					end
					if locationResults[tileId].hpLost > 0 then
						local newUnitDamage = unit.damage + locationResults[tileId].hpLost
						local detailText = ""
						if unit.veteran == true then
							detailText = "Veteran "
						end
						detailText = detailText .. unit.type.name
						if unit.homeCity ~= nil then
							detailText = detailText .. " (" .. unit.homeCity.name .. ")"
						else
							detailText = detailText .. " (NONE)"
						end
						detailText = detailText .. " reduced from " .. unit.hitpoints .. " HP to " .. tostring(math.max(unit.type.hitpoints - newUnitDamage, 0)) .. " HP"
						if newUnitDamage >= unit.type.hitpoints then
							detailText = detailText .. " -- unit lost!"
							unitutil.deleteUnit(unit)
						else
							unit.damage = newUnitDamage
						end
						table.insert(locationResults[tileId].unitDetails, detailText)
					end
				end
			end
		end
		for _, result in pairs(locationResults) do
			if result.hpLost > 0 then
				local messageText = result.summary
				for _, detailText in ipairs(result.unitDetails) do
					messageText = messageText .. "|" .. detailText
				end
				uiutil.messageDialog("Military Commander", messageText)
			end
		end
	end
end

local function stackDamage (losingUnit, defendingUnit, battleTile, captureOccurred)
	log.trace()
	if losingUnit == defendingUnit and (tileutil.getTerrainId(battleTile) ~= MMTERRAIN.Sea or losingUnit.domain == domain.Sea) then
		local messageText = "Our "
		if losingUnit.veteran == true then
			messageText = messageText .. "veteran "
		end
		messageText = messageText .. losingUnit.type.name .. " "
		if losingUnit.homeCity ~= nil then
			messageText = messageText .. "from " .. losingUnit.homeCity.name .. " "
		end
		if tileutil.getTerrainId(battleTile) ~= MMTERRAIN.Sea then
			messageText = messageText .. "has been defeated in battle!"
		else
			messageText = messageText .. "has been defeated in a naval battle!"
		end
		local appliedDamage = false

		if tileutil.getTerrainId(battleTile) ~= MMTERRAIN.Sea then
			for unit in battleTile.units do
				if unit.id ~= losingUnit.id and unit.type.domain == 0 and isCitySpecialistUnitType(unit.type) == false then
					-- The colors in a units health bar mean: Green 8-10 HP, Yellow 5-7 HP, Red 1-4 HP (actually as percents of max HP though)
					-- Those ranges are used as guidelines for the following behavior. Intentionally using raw HP and not percents.
					-- (Note that healing may allow units that suffer damage to recover before their next turn.)
					local damageToApply = 0
					if unit.hitpoints >= 8 then
							damageToApply = 2
					elseif unit.hitpoints >= 5 then
						damageToApply = 1
					end
					if damageToApply > 0 then
						if appliedDamage == false then
							messageText = messageText .. "||The following units also suffered collateral damage:|"
							appliedDamage = true
						end
						messageText = messageText .. "|"
						if unit.veteran == true then
							messageText = messageText .. "Veteran "
						end
						messageText = messageText .. unit.type.name .. " "
						if unit.homeCity ~= nil then
							messageText = messageText .. "from " .. unit.homeCity.name .. " "
						end
						messageText = messageText .. "reduced from " .. unit.hitpoints .. " HP to " .. (unit.hitpoints - damageToApply) .. " HP"
						unit.damage = unit.damage + damageToApply
						log.action("Added " .. damageToApply .. " HP damage to " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") at " .. unit.x .. "," .. unit.y)
					end
				end
			end
		end

		if losingUnit.owner.isHuman == true and (captureOccurred == false or appliedDamage == true) then
			uiutil.messageDialog("Military Commander", messageText)
		end
	end
end

-- This is also called internally by swapAllSiegeEngineersTowers() and must be defined prior to it in this file:
local function swapSiegeEngineerTower (unit, activateImmediately)
	log.trace()
	if (unit.type == MMUNIT.SiegeEngineer and tileutil.isLandTile(unit.location) == true) or unit.type == MMUNIT.SiegeTower then
		local nearEnemyStronghold = false
		if tileutil.isLandTile(unit.location) == true then
			for _, tile in ipairs(tileutil.getTilesByDistance(unit.location, constant.mmUnits.SIEGE_TOWER_CITY_ACTIVATION_RANGE, false)) do
				if civ.isTile(tile) and tile.city ~= nil and tribeutil.haveWar(unit.owner, tile.city.owner) then
					nearEnemyStronghold = true
					break
				end
			end
			if nearEnemyStronghold == false then
				for _, tile in ipairs(tileutil.getTilesByDistance(unit.location, constant.mmUnits.SIEGE_TOWER_CASTLE_ACTIVATION_RANGE, false)) do
					if civ.isTile(tile) then
						for otherUnit in tile.units do
							if tribeutil.haveWar(unit.owner, otherUnit.owner) and otherUnit.type.domain == 0 and (tileutil.hasFortress(tile) == true or isCastleUnitType(otherUnit.type) == true) then
								nearEnemyStronghold = true
								break
							end
						end
					end
					if nearEnemyStronghold == true then
						break
					end
				end
			end
		end
		local unitTypeToSwap = nil
		if unit.type == MMUNIT.SiegeEngineer and nearEnemyStronghold == true then
			unitTypeToSwap = MMUNIT.SiegeTower
		elseif unit.type == MMUNIT.SiegeTower and nearEnemyStronghold == false then
			unitTypeToSwap = MMUNIT.SiegeEngineer
		end
		if unitTypeToSwap ~= nil then
			local swapUnit = civ.createUnit(unitTypeToSwap, unit.owner, unit.location)
			if swapUnit ~= nil then
				log.action("Created " .. swapUnit.owner.adjective .. " " .. swapUnit.type.name .. " at " .. swapUnit.x .. "," .. swapUnit.y .. "," .. swapUnit.z .. " (" .. swapUnit.id .. ")")
				-- Swap damage by percent, since HP are not equal; round in favor of less damage i.e. more HP remaining
				swapUnit.damage = math.floor((unit.damage / unit.type.hitpoints) * swapUnit.type.hitpoints)
				-- swapUnit.gotoTile = unit.gotoTile
				swapUnit.homeCity = unit.homeCity
				swapUnit.moveSpent = unit.moveSpent
				swapUnit.order = unit.order
				swapUnit.veteran = unit.veteran

				if unit.owner.isHuman == true then
					-- Deleting the unit at this point, while it is the active unit, causes the interface to flip from 'Move pieces' mode to 'View pieces' mode
					-- Instead, we will set db variable, and the onActivateUnit() trigger will delete the unit the next time it runs
					table.insert(db.gameData.UNITS_TO_DELETE_IMMEDIATELY, unit)
					-- Then we will set the unit order to 'Sleep' which forces the game to select another unit (if one exists) to become the new active unit
					unitutil.sleepUnit(unit)
					-- The combination of these two commands prevents the mode from flipping and deletes the unit at the earliest possible opportunity
				else
					-- Deleting the unit at this point is fine if the owner is an AI tribe; an interface mode flip is of no concern
					-- In fact, using the same approach as for the human player doesn't work! The AI doesn't honor the "sleep" request and will continue using the unit.
					unitutil.deleteUnit(unit)
				end

			end
		end
	end
end

local function swapAllSiegeEngineersTowers (tribe)
	log.trace()
	for unit in civ.iterateUnits() do
		if unit.owner == tribe and (unit.type == MMUNIT.SiegeEngineer or unit.type == MMUNIT.SiegeTower) then
			swapSiegeEngineerTower(unit, false)
		end
	end
end

local function tradeUnitKilled (winningUnit, losingUnit, battleTile)
	log.trace()
	if losingUnit.type == MMUNIT.Merchant or losingUnit.type == MMUNIT.CommercialTrader then
		-- Plunder is not possible if the battle tile contains a city or castle:
		if battleTile.city ~= nil or hasCastle(battleTile) then
			log.info("Battle tile contains a city or castle; plunder not available in this situation")
		else
			-- Plunder is not possible if the battle tile contains another defending unit:
			local foundOtherDefendingUnit = false
			for unit in battleTile.units do
				if unit.id ~= losingUnit.id then
					foundOtherDefendingUnit = true
					break
				end
			end
			if foundOtherDefendingUnit == true then
				log.info("Battle tile is occupied by another defending unit and could not be plundered")
			else
				-- Plunder successful!
				-- Plunder amount is gold equal to the current Materials build cost for the unit, adjusted for difficulty level
				-- Intentionally does *not* use constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR
				local plunderAmount = adjustForDifficulty(round(losingUnit.type.cost * civ.cosmic.shieldRows), winningUnit.owner, true)
				if winningUnit.owner.isHuman == true then
					uiutil.messageDialog("Military Commander", "We have captured a " .. losingUnit.owner.adjective .. " " .. losingUnit.type.name .. " and relieved him of his burdensome cargo. The " .. plunderAmount .. " gold obtained by selling the goods to our own people has been added to your treasury.", 360)
				end
				tribeutil.changeMoney(winningUnit.owner, plunderAmount)
			end
		end
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 19

return {
	confirmLoad = confirmLoad,

	canBuildUnit = canBuildUnit,
	captureNavalUnit = captureNavalUnit,
	formatUnitInfo = formatUnitInfo,
	getStackAttritionValues = getStackAttritionValues,
	managePeasantMilitia = managePeasantMilitia,
	setTradeUnitCosts = setTradeUnitCosts,
	setFractionalMovement = setFractionalMovement,
	setShipAttackRule = setShipAttackRule,
	setupInitialUnits = setupInitialUnits,
	stackAttrition = stackAttrition,
	stackDamage = stackDamage,
	swapSiegeEngineerTower = swapSiegeEngineerTower,
	swapAllSiegeEngineersTowers = swapAllSiegeEngineersTowers,
	tradeUnitKilled = tradeUnitKilled,
}
