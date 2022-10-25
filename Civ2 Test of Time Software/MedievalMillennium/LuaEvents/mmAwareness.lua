-- mmAwareness.lua
-- by Knighttime

log.trace()

local powerRatingDesc = {"Pathetic", "Weak", "Inadequate", "Moderate", "Strong", "Mighty", "Supreme"}

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

-- Based on:
-- 		http://home.tiscali.cz:8080/~cz045662/civ2/statistic.htm
-- 		https://www.civfanatics.com/civ2/strategy/powergraph/
local function calculatePowerRatings (turn, forceOverride)
	log.trace()
	if turn % 4 == 0 or forceOverride == true then
		local powerRatings = { }
		for i = 1, 7 do
			local tribe = civ.getTribe(i)
			local tribeName = ""
			local points = 0
			local human = false
			if tribe ~= nil and tribe.active == true then
				tribeName = tribe.name
				if tribe.isHuman == true then
					human = true
				end
				points = tribe.money + (96 * (tribe.numTechs - 1)) + (256 * db.tribeData[tribe.id].powerRatingCitizens)
			end
			table.insert(powerRatings, {
				tribeId = i,
				tribeName = tribeName,
				human = human,
				points = points
			})
		end
		table.sort(powerRatings, function(a, b) return a.points < b.points end)
		for order, ratingData in ipairs(powerRatings) do
			ratingData.desc = powerRatingDesc[order]
			log.info(order .. ". " .. ratingData.tribeName .. " (tribe " .. ratingData.tribeId .. ") -- " .. ratingData.desc .. " (" .. ratingData.points .. " points)")
		end
		store("powerRatings", powerRatings)
		db.gameData.POWER_RATINGS_CALCULATED_YEAR = civ.getGameYear()
	end
end

local function displayGameplayReminders (turn, saveLoaded)
	log.trace()

	if saveLoaded == true then
		uiutil.messageDialog("Important Reminders", "If barbarian or AI turns are taking a long time due to the movement of many units, you can hold down the [Shift] key to make the moves instantaneous. (This might mean that you fail to notice moves which are actually significant, however.)||Remember to load 'MedievalMillenniumMusicPlayer.htm'|if you would like to listen to medieval music while you play!")
	else
		if turn == 1 then
			uiutil.messageDialog("Medieval Music", "If you would like to listen to a curated selection of ad-free medieval music|while you play, please uncheck 'Music' in the Game Options dialog, and load|the 'MedievalMillenniumMusicPlayer.htm' file found in the Music subfolder of|your Medieval Millennium installation folder.", 640)
		elseif turn == 3 then
			uiutil.messageDialog("Game Concept: Terrain Development", "At the beginning of each game, much of the map is covered with native terrain types that are relatively unproductive: Heathland, Dense Forest, Pine Forest, Marsh/Fen, and Hills. Each of these can be either converted to a more productive type, or improved with mining/woodcutting. In order to maximize productivity, each city should strive to only work tiles that have been improved in some way. You will need to maintain and direct Peasants, Serfs, and Yeomen to make appropriate and timely terrain changes or improvements near each city. For more information, please see the PDF Guide to Terrain, or review the Civilopedia entries for each Terrain Type.", 640)
		elseif turn == 4 then
			uiutil.messageDialog("Game Concept: New City Specialists", "Some city improvements provide benefits that have been dramatically altered from the base game, such as multiple levels of construction that permit new types of specialists. Within the list of improvements a city has the option to build, these are marked with a '§' symbol following their name -- for example, 'Grist Mill §'. These new specialists play a crucial role in developing the productivity of your city. For more information, please see the PDF Guide to Improvements, or the Civilopedia entry 'Medieval Millennium Concepts --> Specialists'.", 640)
		elseif turn == 5 then
			uiutil.messageDialog("Game Concept: Ranged Units", "Medieval Millennium contains a full set of ranged units that attack by firing projectiles. Within the list of units a city has the option to build, these are marked with one or more symbols following their name, corresponding to the type of projectile they fire -- for example, 'Archer –›'. For more information about ranged units, please see the PDF Guide to Units, or the following Civilopedia entries. Note that the entry for Artillery contains especially significant details related to that class of ranged units.||• Medieval Millennium Concepts --> Ranged Units (Overview)|• Medieval Millennium Concepts --> Ranged Infantry and Cavalry|• Medieval Millennium Concepts --> Artillery|• Unit Type entries for specific unit types that you currently have the option to build", 640)
		elseif turn == 18 then
			uiutil.messageDialog("Game Concept: Plague", "During much of the medieval era, outbreaks of plague were unfortunately common, and exacted a dreadful toll on citizens of all ages and occupations. Medieval Millennium models both major plague strikes as well as minor outbreaks, which can impact city health, population, units, and productivity. For more information, please see PDF Guide to Gameplay, or the Civilopedia entry 'Medieval Millennium Concepts --> Plague and Black Death'.", 640)
		end
	end
end

local function humanIsSupreme ()
	log.trace()
	local powerRatings = retrieve("powerRatings")
	local humanTribe = civ.getPlayerTribe()
	local isSupreme = false
	for _, tribePowerRating in ipairs(powerRatings) do
		if tribePowerRating.tribeId == humanTribe.id and tribePowerRating.desc == "Supreme" then
			isSupreme = true
		end
	end
	return isSupreme
end

local function listPowerRatings ()
	log.trace()
	local columnTable = {
		{label = "rank", align = "right"},
		{label = "desc"},
		{label = "nation"},
		{label = "points", align = "right"}
	}
	local dataTable = { {rank = "RANK", desc = "DESCRIPTION", nation = "NATION", points = "POINTS"} }
	local messageHeader = "Power Ratings"
	local powerRatings = retrieve("powerRatings")
	local playerTribe = civ.getPlayerTribe()
	if powerRatings[7] ~= nil then
		for i = 7, 1, -1 do
			if powerRatings[i].tribeName ~= "" then
				local tribe = civ.getTribe(powerRatings[i].tribeId)
				local humanIndicator = ""
				if powerRatings[i].human == true then
					humanIndicator = "=>  "
				end
				if tribeutil.haveContact(playerTribe, tribe) or constant.events.ADMINISTRATOR_MODE == true then
					table.insert(dataTable, {
						rank = humanIndicator .. tostring(8 - i) .. ".",
						desc = powerRatings[i].desc,
						nation = powerRatings[i].tribeName,
						points = tostring(powerRatings[i].points)
					})
				else
					table.insert(dataTable, {
						rank = humanIndicator .. tostring(8 - i) .. ".",
						desc = powerRatings[i].desc,
						nation = "",
						points = ""
					})
				end
			end
		end
		if db.gameData.POWER_RATINGS_CALCULATED_YEAR ~= nil then
			messageHeader = messageHeader .. " as of A.D. " .. tostring(db.gameData.POWER_RATINGS_CALCULATED_YEAR)
		end
		uiutil.messageDialog(messageHeader, uiutil.convertTableToMessageText(columnTable, dataTable, 5) .. "||Note: These power ratings are calculated exclusively by Lua events, using information posted online regarding the correct formula. However, they are not a real-time view of the ratings actually generated by the game, which are visible within the Chancellor [F3] screen. As a result, minor variations may exist.", 525)
	else
		uiutil.messageDialog(messageHeader, "Information not currently available. Power ratings are calculated every fourth turn.", 525)
	end
end

local function listTechTradingPossibilities ()
	log.trace()
	local humanTribe = civ.getPlayerTribe()
	repeat
		local dialog = civ.ui.createDialog()
		dialog.title = "Technology Trading Possibilities"
		dialog.width = 360
		dialog:addText(humanTribe.name .. " has established an embassy with each of the nations listed below.")
		dialog:addOption("EXIT", 0)
		for tribe in tribeutil.iterateActiveTribes(false) do
			if tribe ~= humanTribe and 
				(tribeutil.hasEmbassy(humanTribe, tribe) or (wonderutil.getOwner(MMWONDER.TravelsofMarcoPolo) == humanTribe and wonderutil.isEffective(MMWONDER.TravelsofMarcoPolo))) then
				dialog:addOption(tribe.name, tribe.id)
			end
		end
		log.action("Dialog box displayed")
		local result = dialog:show()
		if result > 0 then
			local tribe = civ.getTribe(result)
			local techsYouCanGet = { }
			local techsYouCanGive = { }
			for tech in techutil.iterateTechs() do
				if tech.name ~= "High Middle Ages" then
					if civ.hasTech(humanTribe, tech) == true and civ.hasTech(tribe, tech) == false then
						table.insert(techsYouCanGive, tech.name)
					elseif civ.hasTech(humanTribe, tech) == false and civ.hasTech(tribe, tech) == true then
						table.insert(techsYouCanGet, tech.name)
					end
				end
			end
			table.sort(techsYouCanGet)
			table.sort(techsYouCanGive)
			local columnTable = {
				{label = "get"},
				{label = "give"}
			}
			local dataTable = { }
			table.insert(dataTable, {get = "ADVANCES YOU CAN ACQUIRE", give = "ADVANCES YOU CAN OFFER"} )
			table.insert(dataTable, {get = "––––––––––––––––––––––––––––––", give = "––––––––––––––––––––––––––––––"} )
			local maxRows = math.max(#techsYouCanGet, #techsYouCanGive)
			for i = 1, maxRows do
				local getString = ""
				local giveString = ""
				if techsYouCanGet[i] ~= nil then
					getString = techsYouCanGet[i]
				end
				if techsYouCanGive[i] ~= nil then
					giveString = techsYouCanGive[i]
				end
				table.insert(dataTable, {get = getString, give = giveString} )
			end
			uiutil.messageDialog("Technology Trading Possibilities with " .. tribe.name, uiutil.convertTableToMessageText(columnTable, dataTable, 10), 480)
		end
	until
		result == 0
end

local function storeTribePopulations (turn, forceOverride)
	log.trace()
	if turn % 4 == 3 or forceOverride == true then
		for i = 1, 7 do
			local tribe = civ.getTribe(i)
			local citizens = 0
			if tribe ~= nil and tribe.active == true then
				for city in civ.iterateCities() do
					if city.owner == tribe then
						citizens = citizens + city.size
					end
				end
				db.tribeData[tribe.id].powerRatingCitizens = citizens
			end
		end
		log.update("Updated tribe populations")
	end
end

local function unitBuilt (city, unit)
	log.trace()
	-- Always display a message when a non-settler and non-trade unit is built,
	-- 		just like the game does for settlers, caravans, improvements, and wonders
	-- Exception: game also notifies you if the unit that is built has 0 MP
	if city.owner.isHuman == true and unit.type.role <= 4 and unit.type.move > 0 then
		local messageText = city.name .. " builds "
		local isVeteran = false
		local vets = retrieve("veterans")
		if vets[unit.id] ~= nil then
			isVeteran = vets[unit.id]
		end
		if isVeteran == true then
			messageText = messageText .. "veteran "
		end
		messageText = messageText .. unit.type.name .. "."
		civ.ui.centerView(city.location)
		uiutil.messageDialog("Constable's Report", messageText)
	end
end

local function updateMapView (tile, tribe)
	log.trace()
	if tribe.active == true then
		local tempUnitType = MMUNIT.Peasant
		if unitutil.isValidUnitLocation(tempUnitType, tribe, tile) then
			local tempUnit = unitutil.createByType(tempUnitType, tribe, tile, {homeCity = nil})
			unitutil.deleteUnit(tempUnit)
		end
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 13

return {
	confirmLoad = confirmLoad,

	calculatePowerRatings = calculatePowerRatings,
	displayGameplayReminders = displayGameplayReminders,
	humanIsSupreme = humanIsSupreme,
	listPowerRatings = listPowerRatings,
	listTechTradingPossibilities = listTechTradingPossibilities,
	storeTribePopulations = storeTribePopulations,
	unitBuilt = unitBuilt,
	updateMapView = updateMapView,
}
