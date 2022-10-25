-- mmSurvivors.lua
-- by Knighttime

log.trace()

constant.mmSurvivors = { }
constant.mmSurvivors.RETURN_YEARS_MAX = 30					-- Maximum number of years that a survivor can take to get home
															--		Thus units can only be survivors if they are killed within this many tiles of their home city
constant.mmSurvivors.PER_CITIZEN_HEALTH_DEDUCTED = 6		-- Amount of Health in a city's growth box that is lost when a unit from that city is killed in battle
															-- 		This number is multiplied by the city size
constant.mmSurvivors.HEALTH_DEDUCTED_MAX = 24				-- Max amount of Health that can be lost when a unit from that city is killed in battle
															-- 		i.e., this is a cap on the formula described directly above. So:
constant.mmSurvivors.HEALTH_DEDUCTION_RESTORED_PCT = 50		-- Health in a city's growth box that is regained when a unit from that city is recreated as a survivor,
															-- 		*** as a percent of the amount *lost* when a unit is killed (see constants above) ***

db.pendingSurvivorData = { }

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
local function getHealthAmountLost (city)
	log.trace()
	return round(math.min(city.size * adjustForDifficulty(constant.mmSurvivors.PER_CITIZEN_HEALTH_DEDUCTED, city.owner, false),
						  adjustForDifficulty(constant.mmSurvivors.HEALTH_DEDUCTED_MAX, city.owner, false)))
end

local function getHealthAmountRestored (city)
	log.trace()
	return round(math.min(city.size * adjustForDifficulty(constant.mmSurvivors.PER_CITIZEN_HEALTH_DEDUCTED, city.owner, true),
						  adjustForDifficulty(constant.mmSurvivors.HEALTH_DEDUCTED_MAX, city.owner, true)) *
				 (constant.mmSurvivors.HEALTH_DEDUCTION_RESTORED_PCT / 100))
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function applyCasualtiesForDefeatedUnit (winningUnit, losingUnit)
	log.trace()
	-- In the @COSMIC2 section of Rules.txt, CityPopulationLossAttack is set to 1 meaning "No"
	local battleTile = tileutil.getBattleTile(winningUnit, losingUnit)
	local loserHomeCity = losingUnit.homeCity
	-- Note: peasant-type units do not result in a population loss, because their home city experienced a full point of population loss
	--		 already, at the time they were built
	if isHumanUnitType(losingUnit.type) and losingUnit.type.role ~= 5 and loserHomeCity ~= nil then
		changeCityHealth(loserHomeCity, getHealthAmountLost(loserHomeCity) * -1)
	else
		if loserHomeCity == nil then
			log.info("Unit that was killed did not have a home city")
		elseif losingUnit.type.role == 5 then
			log.info("Unit that was killed was a " .. losingUnit.type.name .. " (role 5)")
		else
			log.info("Unit that was killed was not a human unit")
		end
	end
end

local function clearSurvivorDataForCity (city)
	log.trace()
	local survivorsToRemove = { }
	for key, survivorData in ipairs(db.pendingSurvivorData) do
		if survivorData.homeCity == city then
			table.insert(survivorsToRemove, 1, key)
			log.info("Found entry for city " .. city.id .. " in the pendingSurvivorData db table (row " .. key .. ")")
		end
	end
	for _, rowNumber in ipairs(survivorsToRemove) do
		table.remove(db.pendingSurvivorData, rowNumber)
		log.update("Removed row " .. rowNumber .. " from list of pending survivors")
	end
end

local function clearSurvivorDataForTribe (tribe)
	log.trace()
	local survivorsToRemove = { }
	for key, survivorData in ipairs(db.pendingSurvivorData) do
		if survivorData.tribe == tribe then
			table.insert(survivorsToRemove, 1, key)
			log.info("Found entry for tribe " .. tribe.id .. " in the pendingSurvivorData db table (row " .. key .. ")")
		end
	end
	for _, rowNumber in ipairs(survivorsToRemove) do
		table.remove(db.pendingSurvivorData, rowNumber)
		log.update("Removed row " .. rowNumber .. " from list of pending survivors")
	end
end

local function createSurvivingUnits (tribe)
	log.trace()
	local survivorsToRemove = { }
	local gameYear = civ.getGameYear()
	for key, survivor in ipairs(db.pendingSurvivorData) do
		if survivor.tribe == tribe then
			if (survivor.year == gameYear or survivor.year == (gameYear - 1)) then
				if survivor.homeCity.owner == survivor.tribe then
					local returnedUnit = unitutil.createById(survivor.unitType.id, survivor.tribe, survivor.destinationTile, { homeCity = survivor.homeCity, veteran = true})
					if returnedUnit ~= nil then
						returnedUnit.damage = returnedUnit.type.hitpoints - 1
						log.action("Set HP of returned surviving " .. returnedUnit.type.name .. " to 1")
						cityutil.changeFood(survivor.homeCity, getHealthAmountRestored(survivor.homeCity), humanIsSupreme())
						if tribe.isHuman == true then
							civ.ui.centerView(returnedUnit.homeCity.location)
							uiutil.messageDialog("Constable", "Good news, Sire! Some members of a " .. returnedUnit.type.name ..
								" unit that survived a previous battle have returned home to the city of " .. returnedUnit.homeCity.name .. ".", 400)
						end
					end
				else
					log.info("Could not create surviving " .. survivor.tribe.adjective .. " " .. survivor.unitType.name .. " in " .. survivor.homeCity.name .. " since this city is now owned by " .. survivor.homeCity.owner.name)
				end
				table.insert(survivorsToRemove, 1, key)
			elseif survivor.year < gameYear then
				log.error("ERROR! Found outdated survivors who should have returned in " .. survivor.year .. " (row " .. key .. ")")
				table.insert(survivorsToRemove, 1, key)
			end
		end
	end
	for _, rowNumber in ipairs(survivorsToRemove) do
		table.remove(db.pendingSurvivorData, rowNumber)
		log.update("Removed row " .. rowNumber .. " from list of pending survivors")
	end
end

local function scheduleSurvivingUnitReturn (winningUnit, losingUnit, attackingUnit, battleTile)
	log.trace()
	local loserHomeCity = losingUnit.homeCity
	-- Survivors cannot be barbarians, must have a home city, cannot be immobile, must have an offensive attack value,
	--		must be a "human" unit or a Siege Tower, and cannot be Peasant Militia:
	if losingUnit.owner.id > 0 and loserHomeCity ~= nil and losingUnit.type.move > 0 and losingUnit.type.attack > 0 and
	   (isHumanUnitType(losingUnit.type) or losingUnit.type == MMUNIT.SiegeTower) and losingUnit.type ~= MMUNIT.PeasantMilitia then
		if tileutil.isLandTile(battleTile) or tileutil.isCoastalWaterTile(battleTile) then
			-- Survivor chance should depend on the HP with which the loser STARTED the battle, in conjunction with the HP with which the winner ENDED the battle
			-- The formula below produces a range from 0 to 90 percent
			-- Highest chance is if the losing unit started the battle without any damage, and after the battle the winning unit had only 1 HP remaining
			local loserStartHp = (losingUnit.type.hitpoints - defenderDamage) / (losingUnit.type.hitpoints / 10)
			if losingUnit == attackingUnit then
				loserStartHp = (losingUnit.type.hitpoints - attackerDamage) / (losingUnit.type.hitpoints / 10)
			end
			local winnerEndHp = winningUnit.hitpoints / (winningUnit.type.hitpoints / 10)
			local survivorChance = ((loserStartHp - 1) * 5) + ((10 - winnerEndHp) * 5)
			local randomNumber = math.random(100)
			log.info("  survivorChance = " .. string.format("%.2f", survivorChance) .. ", randomNumber = " .. randomNumber)
			if randomNumber <= survivorChance then
				local totalMovesToGetHome = tileutil.getDistance(battleTile, loserHomeCity.location)
				-- All units are given 2 moves per *turn*, i.e. 1 move per *year* (assumes gameplay rate of two years per turn)
				-- This purposely ignores all terrain types, terrain obstacles, improvements, etc.
				-- This also (intentionally) makes no reference to adjustForDifficulty()
				local yearsToReturnHome = math.max(totalMovesToGetHome, 1)
				if yearsToReturnHome > constant.mmSurvivors.RETURN_YEARS_MAX then
					log.info("Survivors would take " .. yearsToReturnHome .. " years to return home, exceeding max of " .. constant.mmSurvivors.RETURN_YEARS_MAX)
				else
					local yearToReturnHome = civ.getGameYear() + yearsToReturnHome
					local unitTypeToReturn = losingUnit.type
					if losingUnit.type == MMUNIT.SiegeTower then
						unitTypeToReturn = MMUNIT.SiegeEngineer
					end
					table.insert(db.pendingSurvivorData, {
						year = yearToReturnHome,
						unitType = unitTypeToReturn,
						tribe = losingUnit.owner,
						destinationTile = loserHomeCity.location,
						homeCity = loserHomeCity })
					log.update("Scheduled surviving " .. losingUnit.owner.adjective .. " " .. unitTypeToReturn.name .. " to return home in " .. yearToReturnHome)
				end
			end
		else
			log.info("No survivors; unit lost at sea on a non-coastal tile")
		end
	else
		messageText = "No survivors; "
		if losingUnit.owner.id == 0 then
			messageText = messageText .. "losing unit was " .. losingUnit.owner.adjective
		else
			messageText = messageText .. "loserHomeCity = "
			if loserHomeCity ~= nil then
				messageText = messageText .. loserHomeCity.name .. " but unit type does not qualify"
			else
				messageText = messageText .. "nil"
			end
		end
		log.info(messageText)
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 10

return {
	confirmLoad = confirmLoad,

	applyCasualtiesForDefeatedUnit = applyCasualtiesForDefeatedUnit,
	clearSurvivorDataForCity = clearSurvivorDataForCity,
	clearSurvivorDataForTribe = clearSurvivorDataForTribe,
	createSurvivingUnits = createSurvivingUnits,
	scheduleSurvivingUnitReturn = scheduleSurvivingUnitReturn,
}
