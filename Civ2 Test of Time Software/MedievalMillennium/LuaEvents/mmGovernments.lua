-- mmGovernments.lua
-- by Knighttime

log.trace()

constant.mmGovernments = { }
constant.mmGovernments.CELEBRATION_GROWTH_CITY_SIZE_INCREASE_MIN = 0.8		-- Number of population points (expressed as a decimal) that a city needs to have in "unexplained growth"
																			--		in order for the code to conclude that the city grew due to the celebration benefit under
																			--		Constitutional Monarchy or Merchant Republic
constant.mmGovernments.CELEBRATION_CM_FREE_UNITS_MAX = 6					-- Under Constitutional Monarchy, a celebrating city is reimbursed for unit support up to the number of happy citizens,
																			--		but the max reimbursement is capped at this value (i.e., it will be the *smaller* of this number or the number
																			--		of happy citizens)
constant.mmGovernments.CELEBRATION_MR_FREE_UNITS_MAX = 3					-- Under Merchant Republic, a celebrating city is reimbursed for unit support up to the number of happy citizens,
																			--		but the max reimbursement is capped at this value (i.e., it will be the *smaller* of this number or the number
																			--		of happy citizens)
constant.mmGovernments.TRIBAL_INCOME_DEDUCTION_PCT = 0						-- Percent of a turn's net income that will be deducted to simulate costs of retaining power in a Tribal Monarchy.
																			-- 		Set to 0, after testing, since a monetary penalty on top of the research penalty seemed excessive.
constant.mmGovernments.CATHOLIC_TITHE_DONATION_PCT = 10						-- Percent of a turn's net income that will be "donated" to the church. This slows down treasury growth, at least slightly.
constant.mmGovernments.PEASANT_HEALTH_INCREASE_DEFERRED_YEARS = 20			-- Once the first Yeoman unit is produced during the game, by any nation, the support cost of all settler-type units
																			--		will increase from 1 to 2 Health per turn. The change is scheduled to take place in the future, this many
																			--		years after the first Yeoman production.
constant.mmGovernments.CONSTITUTIONAL_MONARCHY_FREE_UNITS = 1				-- This government always supports 0 units per the game engine, and there is no cosmic variable that can be
																			--		adjusted. The free unit support will be added directly to the Materials production box by event.
constant.mmGovernments.ROYAL_PALACE_UPKEEP_BY_GOVERNMENT_TYPE = {
	[0] = 0,		-- Interregnum
	[1] = 0,		-- Primitive Monarchy
	[2] = 0,		-- Enlightened Monarchy
	[3] = 0,		-- Feudal Monarchy
	[4] = 0,		-- Tribal Monarchy
	[5] = 6,		-- Constitutional Monarchy
	[6] = 1			-- Merchant Republic			-- This is the base fixed cost, but getRoyalPalaceUpkeep() contains the actual formula that calculates total cost this based on number of cities
}

-- See also mmAliases.MMGOVERNMENT
local governmentTech = {
	Interregnum = nil,
	TribalMonarchy = techutil.findByName("Tribal Religion"),
	PrimitiveMonarchy = techutil.findByName("Catholic Christianity"),
	FeudalMonarchy = techutil.findByName("Feudalism"),
	EnlightenedMonarchy = techutil.findByName("Enlightened Monarchy"),
	ConstitutionalMonarchy = techutil.findByName("Constitutional Monarchy"),
	MerchantRepublic = techutil.findByName("Merchant Republic")
}
local rulerTitleList = { "Lord", "Lady",
						 "King", "Queen",
						 "Enlightened King", "Enlightened Queen",
						 "Feudal King", "Feudal Queen",
						 "Tribal King", "Tribal Queen",
						 "Lawful King", "Lawful Queen",
						 "Elected Doge", "Elected Dogaressa"
}
local christianTechSet = techutil.getDependentSet(governmentTech.PrimitiveMonarchy)

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
local function getReducedHealthTilesUnderPrimitiveMonarchy (city)
	log.trace()
	local numReducedHealthTiles = 0
	if city.owner.government == MMGOVERNMENT.PrimitiveMonarchy then
		for _, tile in ipairs(tileutil.getAdjacentTiles(city.location, true)) do
			if civ.isTile(tile) == true then
				local terrainId = tileutil.getTerrainId(tile)
				if terrainId == MMTERRAIN.Arable or terrainId == MMTERRAIN.ArableLush or terrainId == MMTERRAIN.TerracedHills then
					numReducedHealthTiles = numReducedHealthTiles + 1
				end
			end
		end
	end
	return numReducedHealthTiles
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
-- This is also called internally by adjustProductionInPrimitiveMonarchy() and must be defined prior to it in this file:
local function getRateBonusesUnderPrimitiveMonarchy (tribe)
	log.trace()
	local bonusGold = 0
	local bonusScience = 0
	if tribe.government == MMGOVERNMENT.PrimitiveMonarchy then
		-- The tribe gets a default fixed value of 1 gold and 1 research point per turn.
		-- If either the tax or science rate is set to the maximum rate of 60%, then both credits are applied to that single destination instead.
		-- If a rate is set below 40%, then no credit is given in that category.
		bonusGold = 1
		bonusScience = 1
		if tribe.taxRate < 4 then
			bonusGold = 0
		elseif tribe.taxRate == 6 then			-- a value greater than 6 is not possible
			bonusGold = 2
			bonusScience = 0
		end
		if tribe.scienceRate < 4 then
			bonusScience = 0
		elseif tribe.scienceRate == 6 then		-- a value greater than 6 is not possible
			bonusGold = 0
			bonusScience = 2
		end
	end
	return bonusGold, bonusScience
end

local function adjustProductionInPrimitiveMonarchy (tribe)
	log.trace()
	if tribe.government == MMGOVERNMENT.PrimitiveMonarchy then
		for city in civ.iterateCities() do
			if city.owner == tribe then
				local numReducedHealthTiles = getReducedHealthTilesUnderPrimitiveMonarchy(city)
				-- Even if there is more than one such tile, we're only going to add 1 Health or 1 Materials per turn back to the city.
				-- So there is still a penalty, but not as severe of one, and this approach scales the impact to disproportionately benefit
				--		small cities that only work a couple tiles.
				if numReducedHealthTiles > 0 then
					cityutil.changeFood(city, 1, humanIsSupreme())
				end
			end
		end

		-- Small bonuses to national treasury and research are also possible:
		local bonusGold = 0
		local bonusScience = 0
		bonusGold, bonusScience = getRateBonusesUnderPrimitiveMonarchy(tribe)
		if bonusGold > 0 then
			tribeutil.changeMoney(tribe, bonusGold)
		end
		if bonusScience > 0 then
			local origAmount = tribe.researchProgress
			tribe.researchProgress = tribe.researchProgress + bonusScience
			log.action("Added " .. bonusScience .. " points to " .. tribe.adjective .. " research progress (was " .. origAmount .. ", now " .. tribe.researchProgress .. ")")
		end
	end
end

local function applyCelebratingCityEffects (tribe, turnNumber)
	log.trace()
	local celebratingCities = retrieve("celebratingCities")
	celebratingCities["turn" .. (turnNumber - 2)] = nil
	local celebratingCitiesLastTurn = celebratingCities["turn" .. (turnNumber - 1)] or { }
	local celebratingCitiesThisTurn = celebratingCities["turn" .. turnNumber] or { }

	-- The following variables are only used for Constitutional Monarchy and Merchant Republic, but due to variable scoping,
	--		they need to be declared and initialized in all cases
	local numCelebratingCitiesForTribe = 0
	local totalUnitSupportReimbursed = 0
	local columnTable = {
		{label = "city"},
		{label = "size", align = "center"},
		{label = "sizeChange", align = "center"},
		{label = "happyCitizens", align = "center"},
		{label = "supportedUnits", align = "center"},
		{label = "reimbursed", align = "center"},
		{label = "unused", align = "center"}
	}
	local dataTable = { }
	table.insert(dataTable, {city = " ",	size = " ",		sizeChange = "SIZE",	happyCitizens = "HAPPY",	supportedUnits = "SUPPORTED",	reimbursed = "MATERIALS",	unused = " "})
	table.insert(dataTable, {city = "CITY", size = "SIZE",	sizeChange = "CHANGE",	happyCitizens = "CITIZENS", supportedUnits = "UNITS",		reimbursed = "REIMBURSED",	unused = "UNCLAIMED"})

	for city in civ.iterateCities() do
		if city.owner == tribe then
			if cityutil.hasAttributeWeLoveTheKing(city) == false then
				log.info("Checking " .. city.name .. "... not celebrating")
			else
				log.action("Checking " .. city.name .. "... celebrating!")
				celebratingCitiesThisTurn[city.id] = true
				if tribe.government == MMGOVERNMENT.ConstitutionalMonarchy or tribe.government == MMGOVERNMENT.MerchantRepublic then
					numCelebratingCitiesForTribe = numCelebratingCitiesForTribe + 1
					local celebratedLastTurn = celebratingCitiesLastTurn[city.id]

					-- 1. Reduce city size by one, if necesary to undo normal in-game effect of city growth:
					local reducedCitySize = "0"
					local forcedGrowth = false
					if celebratedLastTurn == true then
						local lastKnownSize = db.cityData[city.id].decimalSize
						local lastKnownFoodMax = cityutil.getFoodRows(city.owner, humanIsSupreme()) * (math.floor(lastKnownSize) + 1)
						local lastKnownFood = round((lastKnownSize - math.floor(lastKnownSize)) * lastKnownFoodMax)
						local foodSurplus = city.totalFood - (math.floor(lastKnownSize) * civ.cosmic.foodEaten) - (cityutil.getNumSettlersSupported(city) * 1)
						local expectedCurrentSize = math.floor(lastKnownSize) + ((lastKnownFood + foodSurplus) / lastKnownFoodMax)
						local currentSize = cityutil.getSizeAsDecimal(city, humanIsSupreme())
						local sizeDifference = currentSize - expectedCurrentSize
						log.info("  Was = " .. string.format("%.4f", lastKnownSize) .. ", expected = " .. string.format("%.4f", expectedCurrentSize) .. ", current = " .. string.format("%.4f", currentSize))
						log.info("  Difference = " .. string.format("%.4f", sizeDifference) .. "(threshold is " .. constant.mmGovernments.CELEBRATION_GROWTH_CITY_SIZE_INCREASE_MIN .. ")")
						if sizeDifference >= constant.mmGovernments.CELEBRATION_GROWTH_CITY_SIZE_INCREASE_MIN then
							forcedGrowth = true
						end
					end
					if forcedGrowth == true then
						changeCitySize(city, -1)
						reducedCitySize = "+/-"
					end

					-- 2. Reimburse Materials cost of units supported by this city, up to # of happy citizens, with max reimbursement capped by government type:
					local supportedUnits = cityutil.getNumUnitsSupported(city)
					log.info("Found " .. city.numHappy .. " happy citizens and " .. supportedUnits .. " supported units in " .. city.name)
					local maxReimbursement = 0
					if tribe.government == MMGOVERNMENT.ConstitutionalMonarchy then
						maxReimbursement = constant.mmGovernments.CELEBRATION_CM_FREE_UNITS_MAX
					elseif tribe.government == MMGOVERNMENT.MerchantRepublic then
						maxReimbursement = constant.mmGovernments.CELEBRATION_MR_FREE_UNITS_MAX
					end
					materialsToAdd = math.min(city.numHappy, supportedUnits, maxReimbursement)
					if materialsToAdd > 0 then
						if city.shields > 0 then
							cityutil.changeShields(city, materialsToAdd)
						else
							log.update("Found 0 accumulated Materials in " .. city.name .. ", adding " .. (materialsToAdd * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR) .. " gold to treasury instead")
							tribeutil.changeMoney(city.owner, materialsToAdd * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR)
						end
					end
					totalUnitSupportReimbursed = totalUnitSupportReimbursed + materialsToAdd
					table.insert(dataTable, {
						city = city.name,
						size = tostring(city.size),
						sizeChange = tostring(reducedCitySize),
						happyCitizens = tostring(city.numHappy),
						supportedUnits = tostring(supportedUnits),
						reimbursed = tostring(materialsToAdd),
						unused = tostring(math.min(city.numHappy, maxReimbursement) - materialsToAdd)
					})
				end		-- if tribe.government == MMGOVERNMENT.ConstitutionalMonarchy or tribe.government == MMGOVERNMENT.MerchantRepublic

				-- 3. Add one Health (applies for all governments):
				changeCityHealth(city, 1)

			end		-- if cityutil.hasAttributeWeLoveTheKing(city) == false
		end		-- if city.owner == tribe
	end		-- for city in civ.iterateCities()

	if tribe.government == MMGOVERNMENT.ConstitutionalMonarchy or tribe.government == MMGOVERNMENT.MerchantRepublic then
		table.insert(dataTable, {
			city = "=== TOTAL ===",
			size = " ",
			sizeChange = " ",
			happyCitizens = " ",
			supportedUnits = " ",
			reimbursed = tostring(totalUnitSupportReimbursed),
			unused = " "
		})
		if numCelebratingCitiesForTribe > 0 and tribe.isHuman == true then
			local rulerTitleIndex = (tribe.government * 2) + 1
			if tribe.leader.female == true then
				rulerTitleIndex = rulerTitleIndex + 1
			end
			local celebrationTitle = "We love the " .. rulerTitleList[rulerTitleIndex]
			local messageText = "The following cities are currently celebrating:||" .. uiutil.convertTableToMessageText(columnTable, dataTable, 4) .. "||Note: If a city shows '+/-' in the Size Change column, Civilization II added 1 population point to that city which was later removed by Lua events. Because of these changes, the set of tiles worked by that city may have reverted to the game default, rather than retaining customized selections you may have made."
			uiutil.messageDialog(celebrationTitle, messageText, 500)
		end
	end

	celebratingCities["turn" .. turnNumber] = celebratingCitiesThisTurn
	store("celebratingCities", celebratingCities)

end

local function changeGovernmentType (tribe)
	log.trace()
	local dialog = civ.ui.createDialog()
	dialog.title = "Select Form of Government"
	dialog.width = 240
	dialog:addOption("EXIT (keep current government)", 0)
	if techutil.knownByTribe(tribe, governmentTech.PrimitiveMonarchy) == true then
		dialog:addOption(MMGOVERNMENT[MMGOVERNMENT.PrimitiveMonarchy], MMGOVERNMENT.PrimitiveMonarchy)
	end
	if techutil.knownByTribe(tribe, governmentTech.EnlightenedMonarchy) == true then
		dialog:addOption(MMGOVERNMENT[MMGOVERNMENT.EnlightenedMonarchy], MMGOVERNMENT.EnlightenedMonarchy)
	end
	if techutil.knownByTribe(tribe, governmentTech.FeudalMonarchy) == true then
		dialog:addOption(MMGOVERNMENT[MMGOVERNMENT.FeudalMonarchy], MMGOVERNMENT.FeudalMonarchy)
	end
	if techutil.knownByTribe(tribe, governmentTech.TribalMonarchy) == true then
		dialog:addOption(MMGOVERNMENT[MMGOVERNMENT.TribalMonarchy], MMGOVERNMENT.TribalMonarchy)
	end
	if techutil.knownByTribe(tribe, governmentTech.ConstitutionalMonarchy) == true then
		dialog:addOption(MMGOVERNMENT[MMGOVERNMENT.ConstitutionalMonarchy], MMGOVERNMENT.ConstitutionalMonarchy)
	end
	if techutil.knownByTribe(tribe, governmentTech.MerchantRepublic) == true then
		dialog:addOption(MMGOVERNMENT[MMGOVERNMENT.MerchantRepublic], MMGOVERNMENT.MerchantRepublic)
	end
	log.action("Dialog box displayed")
	local result = dialog:show()
	if result > 0 then
		tribe.government = result
		local rulerTitleIndex = (tribe.government * 2) + 1
		if tribe.leader.female == true then
			rulerTitleIndex = rulerTitleIndex + 1
		end
		civ.playSound("Newgovt.wav")
		uiutil.messageDialog("Long Live the " .. rulerTitleList[rulerTitleIndex] .. "!",
			tribe.leader.name .. " proclaimed " .. rulerTitleList[rulerTitleIndex] .. " of new " .. tribe.adjective .. " " .. MMGOVERNMENT[tribe.government] .. "!", 320)
	end
end

local function checkConversionToChristianity (tribe)
	log.trace()
	-- If you know Tribal Religion, then you haven't officially adopted Christianity, even if you have knowledge of one or more Christian techs
	-- This function detects that conflict and resolves it
	-- For the AI, it is resolved by always adopting Christianity; the human player is given a choice of doing so or not

	local hasTribalReligionTech = techutil.knownByTribe(tribe, governmentTech.TribalMonarchy)
	local hasCatholicChristianityTech = false
	local knownChristianTechs = { }
	if techutil.knownByTribe(tribe, governmentTech.PrimitiveMonarchy) == true then
		hasCatholicChristianityTech = true
		table.insert(knownChristianTechs, governmentTech.PrimitiveMonarchy)
	end

	if hasTribalReligionTech == false and hasCatholicChristianityTech == false then
		log.warning("WARNING: " .. tribe.name .. " did not have knowledge of " .. governmentTech.TribalMonarchy.name .. " or " .. governmentTech.PrimitiveMonarchy.name ..
			", which should not be possible. They have received " .. governmentTech.TribalMonarchy.name .. " to resolve this situation.")
		techutil.grantTech(tribe, governmentTech.TribalMonarchy)
		hasTribalReligionTech = true
	end

	if hasTribalReligionTech == true then
		for _, christianTech in ipairs(christianTechSet) do
			if techutil.knownByTribe(tribe, christianTech) == true then
				table.insert(knownChristianTechs, christianTech)
			end
		end
		if #knownChristianTechs > 0 then
			-- Conflict detected between Tribalism and Christianity, proceed to resolve:
			local acceptChristianity = true
			local christianTechString = ""
			for i = 1, #knownChristianTechs do
				if i > 1 then
					if #knownChristianTechs == 2 then
						christianTechString = christianTechString .. " and "
					elseif i == #knownChristianTechs then
						christianTechString = christianTechString .. ", and "
					else
						christianTechString = christianTechString .. ", "
					end
				end
				christianTechString = christianTechString .. knownChristianTechs[i].name
			end
			if tribe.isHuman == true then
				local dialog = civ.ui.createDialog()
				dialog.title = "Knowledge of Christianity"
				dialog.width = 500
				dialog:addText("Your spiritual leaders have recently acquired knowledge of " .. christianTechString .. ". Do you, " .. tribe.leader.name .. ", agree to be baptized and adopt Christianity as the official religion of the nation of " .. tribe.name .. "?")
				dialog:addOption("Yes, I agree", 1)
				dialog:addOption("No, I reject these new teachings", 0)
				log.action("Dialog box displayed")
				local result = dialog:show()
				if result == 0 then
					acceptChristianity = false
				end
			end
			if acceptChristianity == true then
				local messageText = ""

				-- It is possible to acquire one or more techs which are *dependent* upon Catholic Christianity without acquiring it first
				-- In this case, you must give up exactly one of those techs *in exchange for* receiving Catholic Christianity itself
				-- If you acquire Catholic Christianity and a dependent tech at the same time, however, this is fine and no change is required
				if hasCatholicChristianityTech == false then
					local techToExchange = knownChristianTechs[math.random(#knownChristianTechs)]
					messageText = "The knowledge of " .. techToExchange.name .. " made little sense at the time we acquired it, in the context of " .. governmentTech.TribalMonarchy.name ..
						". Now that we have accepted " .. governmentTech.PrimitiveMonarchy.name .. " (and received this advance), we will need to learn or acquire " .. techToExchange.name .. " once again.||"
					techutil.revokeTech(tribe, techToExchange)
					techutil.grantTech(tribe, governmentTech.PrimitiveMonarchy)
					-- If your current research project was dependent upon the tech you gave up in exchange, this will be adjusted back to the prerequisite you are now missing:
					local currentResearch = tribeutil.getCurrentResearch(tribe)
					if currentResearch ~= nil and (currentResearch.prereq1 == techToExchange or currentResearch.prereq2 == techToExchange) then
						tribe.researching = techToExchange
						messageText = messageText .. "Our current research project has therefore been changed from " .. currentResearch.name .. " to " .. techToExchange.name .. ".||"
					end
				end

				-- Message about government change:
				local messageText = messageText .. "With the adoption of Christianity, citizens gradually begin to view their monarch as a leader chosen by God, rather than as a title bestowed by the people on their most worthy chieftain. As a result, the Tribal Monarchy form of government is no longer available to us"
				if tribe.government == MMGOVERNMENT.TribalMonarchy then
					messageText = messageText .. ", and our form of government has been changed to Primitive Monarchy"
				end
				local Manorialism = techutil.findByName("Manorialism", false)
				local hasManorialism = techutil.knownByTribe(tribe, Manorialism)
				if hasManorialism == true then
					messageText = messageText .. ".||Furthermore, our knowledge of Manorialism was adapted to the structure of our society under Tribal Monarchy, and is no longer able to be applied in the same way. Our knowledge of this advance has been removed, and we will need to research or acquire this knowledge again. Complete information regarding all advances and all forms of government can be found in the Civilopedia."
					techutil.revokeTech(tribe, Manorialism)
				else
					messageText = messageText .. ". Complete information regarding all forms of government can be found in the Civilopedia."
				end

				-- Remove Tribal Religion advance:
				techutil.revokeTech(tribe, governmentTech.TribalMonarchy)

				-- Make Feudalism advance available to be researched or acquired:
				tribeutil.setTechGroupAccess(tribe, MMTECHGROUP.Feudalism, 0)

				-- Adjust treasury due to tithes:
				local deductAmount = round(tribe.money * (adjustForDifficulty(constant.mmGovernments.CATHOLIC_TITHE_DONATION_PCT, tribe, false) / 100))
				if deductAmount > 0 then
					tribeutil.changeMoney(tribe, deductAmount * -1)
					messageText = messageText .. "||In gratitude for your conversion, you have elected to donate " .. constant.mmGovernments.CATHOLIC_TITHE_DONATION_PCT .. "% of your entire treasury to the church, to support its work and mission. After this initial gift, a similar tithe will be paid from your treasury every turn; however, it will be calculated based only on your treasury's Net Income since the previous turn (rather than its total value). If your treasury experiences a Net Loss, no tithe is expected."
					db.tribeData[tribe.id].treasuryAfterCitiesProcessed = tribe.money
				end

				-- Message to the human player:
				if tribe.isHuman == true then
					uiutil.messageDialog("Adoption of Christianity", messageText, 575)
				end

				-- Change form of government. This brings up the dialog box in which Tax/Science/Luxury rates can be adjusted,
				--		so this is deliberately placed at the end in order for the message to appear first.
				if tribe.government == MMGOVERNMENT.TribalMonarchy then
					tribe.government = MMGOVERNMENT.PrimitiveMonarchy
					log.action("Changed government of " .. tribe.name .. " to Primitive Monarchy")
				end

			else
				-- Rejection of Christianity causes the tribe to forfeit any and all Christian techs they have acquired to this point
				-- Note that only the human player can ever reject Christianity
				for _, christianTech in ipairs(knownChristianTechs) do
					techutil.revokeTech(tribe, christianTech)
				end
				local messageText = "We have abandoned the knowledge of " .. christianTechString .. ". Our scholars will need to study "
				if #knownChristianTechs == 1 then
					messageText = messageText .. "this advance at a later time if you wish to reacquire it."
				else
					messageText = messageText .. "these advances at a later time if you wish to reacquire them."
				end

				-- Furthermore, it's possible that you could already have started researching something *dependent* upon one of the Christian techs that were removed:
				local currentResearch = tribeutil.getCurrentResearch(tribe)
				if currentResearch ~= nil then
					local setCurrentResearchToTribalReligion = false
					for _, christianTech in ipairs(knownChristianTechs) do
						if currentResearch.prereq1 == christianTech or currentResearch.prereq2 == christianTech then
							setCurrentResearchToTribalReligion = true
						end
					end
					-- If so, reset your research to (re-)learn Tribal Religion. Note that it is apparently not supported to set tribe.researching to nil.
					if setCurrentResearchToTribalReligion == true then
						techutil.revokeTech(tribe, governmentTech.TribalMonarchy)
						tribe.researching = governmentTech.TribalMonarchy
						tribe.researchProgress = tribe.researchCost
						messageText = messageText .. "||Our research into " .. currentResearch.name .. ", which was dependent upon knowledge of Christianity, has been abandoned as well. " ..
							tribe.adjective .. " scholars rededicate themselves to the study of the " .. governmentTech.TribalMonarchy.name .. " our nation has followed since its earliest days."
					end
				end
				uiutil.messageDialog("Rejection of Christianity", messageText, 500)
			end
		else
			-- Tribe only has knowledge of Tribal Religion, and no Christian techs
			-- Enforce Tribal Monarchy government (switching to Primitive Monarchy is not permitted prior to adoption of Christianity)
			if tribe.government ~= MMGOVERNMENT.TribalMonarchy then
				if tribe.isHuman == true then
					uiutil.messageDialog("Game Concept: Tribal Monarchy", "You are not permitted to adopt any form of government other than Tribal Monarchy until you acquire the Catholic Christianity advance. This signifies your nation's conversion to Christianity and will eventually make other forms of government available.")
				end
				-- Change form of government. This brings up the dialog box in which Tax/Science/Luxury rates can be adjusted,
				--		so this is deliberately placed at the end in order for the message to appear first.
				tribe.government = MMGOVERNMENT.TribalMonarchy
				log.action("Changed government of " .. tribe.name .. " to Tribal Monarchy")
			end
		end
	end
end

local function deductExpensesOrTithes (tribe)
	log.trace()
	local prevGold = 0
	local currGold = tribe.money
	if db.tribeData[tribe.id].treasuryAfterCitiesProcessed ~= nil then
		prevGold = db.tribeData[tribe.id].treasuryAfterCitiesProcessed
	end
	local treasuryDesc = tribe.adjective .. " treasury had " .. prevGold .. " gold last turn, now has " .. currGold .. " gold"
	local gainThisTurn = currGold - prevGold
	local deductAmount = 0
	if gainThisTurn > 0 then
		if tribe.government == MMGOVERNMENT.TribalMonarchy then
			deductAmount = math.floor((gainThisTurn * (adjustForDifficulty(constant.mmGovernments.TRIBAL_INCOME_DEDUCTION_PCT, tribe, false) / 100)))	-- truncates (always rounds down)
		else
			deductAmount = math.floor((gainThisTurn * (adjustForDifficulty(constant.mmGovernments.CATHOLIC_TITHE_DONATION_PCT, tribe, false) / 100)) + 0.5)	-- rounds normally
				-- Leaving the code in place and not using my custom round() function, to illustrate the difference with similar line just above
		end
	end
	if deductAmount > 0 then
		log.info(treasuryDesc)
		tribeutil.changeMoney(tribe, deductAmount * -1)
	end
	db.tribeData[tribe.id].treasuryAfterCitiesProcessed = tribe.money
end

local function documentCitySizes (tribe)
	log.trace()
	for city in civ.iterateCities() do
		if city.owner == tribe then
			if db.cityData[city.id] == nil then
				db.cityData[city.id] = { }
			end
			db.cityData[city.id].decimalSize = cityutil.getSizeAsDecimal(city, humanIsSupreme())
		end
	end
	log.update("Updated db.cityData[].decimalSize for all " .. tribe.adjective .. " cities")
end

local function documentPeasantBuilt (city, unit)
	log.trace()
	if unit.type.role == 5 then
		-- If a city celebrates under Constitutional Monarchy or Merchant Republic, and gains a population point, but builds a settler,
		--		that would remove that point back again, and my analysis in mmGovernments.revertCelebratingCityGrowth() would conclude
		--		that they hadn't celebrated.
		-- Technically, the reduction is not a full population point, since an equal amount of Health in a smaller city gives a higher
		-- 		decimal value. The following logic was copied from cityutil and modified:
		if db.cityData[city.id] ~= nil and db.cityData[city.id].decimalSize ~= nil then
			local cityFoodRows = cityutil.getFoodRows(city.owner, humanIsSupreme())
			local previousSize = math.floor(db.cityData[city.id].decimalSize)
			local previousMaxFood = cityFoodRows * (previousSize + 1)
			local previousFood = (db.cityData[city.id].decimalSize - previousSize) * previousMaxFood
			local newSize = previousSize - 1
			local newMaxFood = cityFoodRows * (newSize + 1)
			local newFood = math.min(previousFood, newMaxFood)
			local newDecimalSize = newSize + (newFood / newMaxFood)
			if newFood == newMaxFood then
				newDecimalSize = newDecimalSize - 0.001
			end
			db.cityData[city.id].decimalSize = newDecimalSize
		end
	end
end

local function getExpectedHealthBenefitForCity (city)
	log.trace()
	local healthBenefit = 0
	local numReducedHealthTiles = getReducedHealthTilesUnderPrimitiveMonarchy(city)
	if numReducedHealthTiles > 0 then
		healthBenefit = healthBenefit + 1
	end
	if cityutil.hasAttributeWeLoveTheKing(city) == true then
		healthBenefit = healthBenefit + 1
	end
	return healthBenefit
end

local function getRoyalPalaceUpkeep (tribe)
	log.trace()
	local upkeep = constant.mmGovernments.ROYAL_PALACE_UPKEEP_BY_GOVERNMENT_TYPE[tribe.government]
	if tribe.government == MMGOVERNMENT.MerchantRepublic then
		local thisCityCost = 0
		for city in civ.iterateCities() do
			if city.owner == tribe then
				thisCityCost = thisCityCost + 0.1
				upkeep = upkeep + thisCityCost
			end
		end
		upkeep = round(upkeep * 0.9)
	end
	return upkeep
end

local function increasePeasantHealthCost ()
	log.trace()
	if (civ.cosmic.settlersEatLow == 1 or civ.cosmic.settlersEatHigh == 1) and db.gameData.PEASANT_FOOD_INCREASE_YEAR ~= nil and civ.getGameYear() >= db.gameData.PEASANT_FOOD_INCREASE_YEAR then
		civ.cosmic.settlersEatLow = 2
		log.action("Increased civ.cosmic.settlersEatLow from 1 to 2")
		civ.cosmic.settlersEatHigh = 2
		log.action("Increased civ.cosmic.settlersEatHigh from 1 to 2")
		if civ.getGameYear() == db.gameData.PEASANT_FOOD_INCREASE_YEAR then
			uiutil.messageDialog("Peasant Health", "Every Peasant, Serf, Yeoman, and Refugee now requires support equal to 2 Health per turn.")
		end
	end
end

local function initializeTreasury (tribe, respawn)
	log.trace()
	local tribeKey = "tribe" .. tribe.id
	local initialGoldAmount = 75
	if respawn == true then
		for activeTribe in tribeutil.iterateActiveTribes(true) do
			if activeTribe.money > initialGoldAmount then
				initialGoldAmount = activeTribe.money
			end
		end
	end
	local humanInitialGold = { 150, 125, 100, 75, 50, 25, 0 }
	if tribe.isHuman then
		initialGoldAmount = humanInitialGold[civ.game.difficulty + 1]
		if initialGoldAmount == nil then
			initialGoldAmount = 0
		end
	end
	log.action("Set " .. tribe.adjective .. " treasury to " .. initialGoldAmount .. " gold (was " .. tribe.money .. ")")
	tribe.money = initialGoldAmount
	-- This prevents the game from deducting expenses or tithes from this initial amount next turn:
	db.tribeData[tribe.id].treasuryAfterCitiesProcessed = initialGoldAmount
end

local function initializeTribalMonarchy ()
	log.trace()
	-- Note: the "true" in the following call means this applies to Barbarians as well
	-- They will stay Tribal Monarchy the whole game
	for tribe in tribeutil.iterateActiveTribes(true) do
		techutil.grantTech(tribe, governmentTech.TribalMonarchy)
		tribe.government = MMGOVERNMENT.TribalMonarchy
		log.action("Changed government of " .. tribe.name .. " to Tribal Monarchy")
		initializeTreasury(tribe, false)
	end
end

local function payRoyalPalaceUpkeep (tribe)
	log.trace()
	local firstCity = nil
	local hasCapital = false
	for city in civ.iterateCities() do
		if city.owner == tribe then
			if firstCity == nil then
				firstCity = city
			end
			if civ.hasImprovement(city, MMIMP.RoyalPalace) then
				hasCapital = true
				break
			end
		end
	end
	if hasCapital == false and firstCity ~= nil then
		-- A tribe that doesn't have a Royal Palace gets one for free:
		imputil.addImprovement(firstCity, MMIMP.RoyalPalace)
		hasCapital = true
	end
	if hasCapital == true then
		-- Upkeep cost for other buildings does not vary by difficulty level, so this won't either
		local royalPalaceUpkeep = getRoyalPalaceUpkeep(tribe)
		if royalPalaceUpkeep > 0 then
			tribeutil.changeMoney(tribe, royalPalaceUpkeep * -1)
		end
	end
end

local function provideUnitSupportInConstitutionalMonarchy (tribe)
	log.trace()
	if tribe.government == MMGOVERNMENT.ConstitutionalMonarchy then
		for city in civ.iterateCities() do
			if city.owner == tribe then
				local supportedUnits = cityutil.getNumUnitsSupported(city)
				local materialsToAdd = math.min(constant.mmGovernments.CONSTITUTIONAL_MONARCHY_FREE_UNITS, supportedUnits)
				if materialsToAdd > 0 then
					if city.shields > 0 then
						cityutil.changeShields(city, materialsToAdd)
					else
						log.update("Found 0 accumulated Materials in " .. city.name .. ", adding " .. (materialsToAdd * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR) .. " gold to treasury instead")
						tribeutil.changeMoney(city.owner, materialsToAdd * constant.events.MATERIALS_TO_GOLD_CONVERSION_FACTOR)
					end
				end
			end
		end
	end
end

local function scheduleIncreasedPeasantHealthCost (city, unit)
	log.trace()
	if unit.type == MMUNIT.Yeoman and db.gameData.PEASANT_FOOD_INCREASE_YEAR == nil then
		local increaseYear = civ.getGameYear() + constant.mmGovernments.PEASANT_HEALTH_INCREASE_DEFERRED_YEARS
		db.gameData.PEASANT_FOOD_INCREASE_YEAR = increaseYear
		uiutil.messageDialog("Peasant Health", "The understanding of Enlightened Monarchy in the nation of " .. city.owner.name .. " has enabled the formation of a new class of free laborers. The appearance of a Yeoman in the city of " .. city.name .. " signifies that changes affecting all levels of society are underway across Europe. Beginning in " .. constant.mmGovernments.PEASANT_HEALTH_INCREASE_DEFERRED_YEARS .. " years (A.D. " .. increaseYear .. "), every Peasant, Serf, Yeoman, and Refugee in Europe will require support equal to 2 Health per turn instead of the current support of 1 Health. This change is applicable to all nations and all forms of government.||Please review your cities that are supporting one or more of these units, to ensure that they are generating enough Health to accommodate this change.")
	end
end

local function setCatholicChristianityPrereq ()
	log.trace()
	governmentTech.PrimitiveMonarchy.prereq1 = nil
end

local function setKingsCrusadeExpiration (tribe)
	log.trace()
	if tribe ~= nil then
		if MMWONDER.KingsHolyLandCrusade.city ~= nil and MMWONDER.KingsHolyLandCrusade.city.owner == tribe then
			if tribe.government == MMGOVERNMENT.MerchantRepublic then
				if MMWONDER.KingsHolyLandCrusade.expires ~= governmentTech.MerchantRepublic then
					MMWONDER.KingsHolyLandCrusade.expires = governmentTech.MerchantRepublic
					log.action("Set expiration of " .. MMWONDER.KingsHolyLandCrusade.name .. " to " .. governmentTech.MerchantRepublic.name)
				end
			else
				if MMWONDER.KingsHolyLandCrusade.expires ~= nil then
					MMWONDER.KingsHolyLandCrusade.expires = nil
					log.action("Set expiration of " .. MMWONDER.KingsHolyLandCrusade.name .. " to nil")
				end
			end
		end
	else
		for tribe in tribeutil.iterateActiveTribes(false) do
			if MMWONDER.KingsHolyLandCrusade.city ~= nil and MMWONDER.KingsHolyLandCrusade.city.owner == tribe then
				if tribe.government == MMGOVERNMENT.MerchantRepublic then
					if MMWONDER.KingsHolyLandCrusade.expires ~= governmentTech.MerchantRepublic then
						MMWONDER.KingsHolyLandCrusade.expires = governmentTech.MerchantRepublic
						log.action("Set expiration of " .. MMWONDER.KingsHolyLandCrusade.name .. " to " .. governmentTech.MerchantRepublic.name)
					end
				else
					if MMWONDER.KingsHolyLandCrusade.expires ~= nil then
						MMWONDER.KingsHolyLandCrusade.expires = nil
						log.action("Set expiration of " .. MMWONDER.KingsHolyLandCrusade.name .. " to nil")
					end
				end
			end
		end
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 23

return {
	confirmLoad = confirmLoad,

	getRateBonusesUnderPrimitiveMonarchy = getRateBonusesUnderPrimitiveMonarchy,
	adjustProductionInPrimitiveMonarchy = adjustProductionInPrimitiveMonarchy,
	applyCelebratingCityEffects = applyCelebratingCityEffects,
	changeGovernmentType = changeGovernmentType,
	checkConversionToChristianity = checkConversionToChristianity,
	deductExpensesOrTithes = deductExpensesOrTithes,
	documentCitySizes = documentCitySizes,
	documentPeasantBuilt = documentPeasantBuilt,
	getExpectedHealthBenefitForCity = getExpectedHealthBenefitForCity,
	getRoyalPalaceUpkeep = getRoyalPalaceUpkeep,
	increasePeasantHealthCost = increasePeasantHealthCost,
	initializeTreasury = initializeTreasury,
	initializeTribalMonarchy = initializeTribalMonarchy,
	payRoyalPalaceUpkeep = payRoyalPalaceUpkeep,
	provideUnitSupportInConstitutionalMonarchy = provideUnitSupportInConstitutionalMonarchy,
	scheduleIncreasedPeasantHealthCost = scheduleIncreasedPeasantHealthCost,
	setCatholicChristianityPrereq = setCatholicChristianityPrereq,
	setKingsCrusadeExpiration = setKingsCrusadeExpiration,
}
