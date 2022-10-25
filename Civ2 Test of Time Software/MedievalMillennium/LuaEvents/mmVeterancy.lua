-- mmVeterancy.lua
-- by Knighttime

log.trace()

constant.mmVeterancy = { }
constant.mmVeterancy.BARRACKS_GAIN_PCT = 50				-- Percent increase in veterancy chance for land units provided by a Barracks improvement.
														-- 		This is the chance that the first land unit of a given type produced in a city with a Barracks will be a veteran.
constant.mmVeterancy.WHITE_TOWER_GAIN_PCT = 50			-- Percent increase in veterancy chance for land units provided by the White Tower Fortress wonder to all cities.
constant.mmVeterancy.SHIPYARD_GAIN_PCT = 50				-- Percent increase in veterancy chance for sea units provided by a Shipyard improvement.
														-- 		This is the chance that the first sea unit of a given type produced in a city with a Shipyard will be a veteran.
constant.mmVeterancy.TAPESTRY_GAIN_PCT = 50				-- Percent increase in veterancy chance for sea units provided by the Commemorative Tapestry wonder to all cities.
constant.mmVeterancy.UNIT_TYPE_BUILT_GAIN_PCT = 10		-- For every unit built in a city, percent increase to the likelihood that the *next* unit of this type will be a veteran.
constant.mmVeterancy.LONGBOWMAN_BASE_PCT = 50			-- Starting veterancy percent chance for Longbowman units (all other units have a 0% base chance)

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
local function getVeteranPercent (city, unittype)
	log.trace()
	local vetPercent = 0
	if unittype.role <= 4 then
		local unitsBuilt = retrieve("unitsBuilt")
		local cityKey = "city" .. city.id
		local cityUnitsBuilt = unitsBuilt[cityKey] or { }
		local unitKey = "unittype" .. unittype.id
		local unitQuantity = cityUnitsBuilt[unitKey] or 0
		vetPercent = math.min(unitQuantity * adjustForDifficulty(constant.mmVeterancy.UNIT_TYPE_BUILT_GAIN_PCT, city.owner, true), 100)
		if unittype.domain == domain.Land then
			if isHumanUnitType(unittype) then
				if civ.hasImprovement(city, MMIMP.Barracks) then
					vetPercent = math.min(vetPercent + adjustForDifficulty(constant.mmVeterancy.BARRACKS_GAIN_PCT, city.owner, true), 100)
				end
				if wonderutil.getOwner(MMWONDER.WhiteTowerFortress) == city.owner and wonderutil.isEffective(MMWONDER.WhiteTowerFortress) then
					vetPercent = math.min(vetPercent + adjustForDifficulty(constant.mmVeterancy.WHITE_TOWER_GAIN_PCT, city.owner, true), 100)
				end
			end
		elseif unittype.domain == domain.Sea then
			if civ.hasImprovement(city, MMIMP.Shipyard) then
				vetPercent = math.min(vetPercent + adjustForDifficulty(constant.mmVeterancy.SHIPYARD_GAIN_PCT, city.owner, true), 100)
			end
			if wonderutil.getOwner(MMWONDER.CommemorativeTapestry) == city.owner and wonderutil.isEffective(MMWONDER.CommemorativeTapestry) then
				vetPercent = math.min(vetPercent + adjustForDifficulty(constant.mmVeterancy.TAPESTRY_GAIN_PCT, city.owner, true), 100)
			end
		end
	end
	if unittype == MMUNIT.Longbowman or unittype == MMUNIT.LongbowmanAI then
		vetPercent = vetPercent + constant.mmVeterancy.LONGBOWMAN_BASE_PCT
	end
	local roundedVetPercent = round(vetPercent)
	return roundedVetPercent
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function applyIntendedVetStatusForUnit (unit)
	log.trace()
	local veterans = retrieve("veterans")
	if veterans[unit.id] ~= nil then
		if veterans[unit.id] == true then
			if unit.veteran == false then
				log.action("Added veteran status to " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ")")
				unit.veteran = true
			else
				log.info("Did not add veteran status to " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. "), already veteran")
			end
		else
			if unit.veteran == true then
				log.action("Removed veteran status from " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ")")
				unit.veteran = false
			else
				log.info("Did not remove veteran status from " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. "), already non-veteran")
			end
		end
		veterans[unit.id] = nil
		store("veterans", veterans)
	end
end

local function applyIntendedVetStatusForTribeUnits (tribe)
	log.trace()
	local veterans = retrieve("veterans")
	for unitId, vetStatus in pairs(veterans) do
		local unit = civ.getUnit(unitId)
		if unit == nil then
			veterans[unitId] = nil
		elseif unit.owner == tribe then
			if vetStatus == true then
				if unit.veteran == false then
					log.action("Added veteran status to " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ")")
					unit.veteran = true
				else
					log.info("Did not add veteran status to " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. "), already veteran")
				end
			else
				if unit.veteran == true then
					log.action("Removed veteran status from " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ")")
					unit.veteran = false
				else
					log.info("Did not remove veteran status from " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. "), already non-veteran")
				end
			end
			veterans[unitId] = nil
		end
	end
	store("veterans", veterans)
end

local function clearUnitBuiltDataForCity (city)
	log.trace()
	local cityKey = "city" .. city.id
	local unitsBuilt = retrieve("unitsBuilt")
	if unitsBuilt[cityKey] ~= nil then
		unitsBuilt[cityKey] = nil
		log.update("Removed entry for " .. cityKey .. " from the unitsBuilt db table")
		store("unitsBuilt", unitsBuilt)
	end
end

local function documentIntendedVetStatus (city, unit)
	log.trace()
	local vets = retrieve("veterans")
	local setAsVeteran = false
	local vetPercent = getVeteranPercent(city, unit.type)
	local randomNumber = math.random(100)
	log.info("vetPercent = " .. vetPercent .. ", randomNumber = " .. randomNumber)
	if randomNumber <= vetPercent then
		setAsVeteran = true
	end
	vets[unit.id] = setAsVeteran
	log.update("Tagged new " .. city.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") as veteran = " .. tostring(setAsVeteran))
	store("veterans", vets)
end

local function documentUnitBuilt (city, unit)
	log.trace()
	local unitsBuilt = retrieve("unitsBuilt")
	local cityKey = "city" .. city.id
	local cityUnitsBuilt = unitsBuilt[cityKey] or { }
	local unitKey = "unittype" .. unit.type.id
	local unitQuantity = cityUnitsBuilt[unitKey] or 0
	unitQuantity = unitQuantity + 1
	log.info(city.name .. " has produced " .. unitQuantity .. " " .. unit.type.name .. " units to date")
	cityUnitsBuilt[unitKey] = unitQuantity
	unitsBuilt[cityKey] = cityUnitsBuilt
	store("unitsBuilt", unitsBuilt)
end

local function listVeteranChances ()
	-- Note: no need to use adjustForDifficulty() here, since this only applies to the human player:
	log.trace()
	local humanTribe = civ.getPlayerTribe()
	local vetDialog1 = civ.ui.createDialog()
	vetDialog1.title = "Military Advisor"
	vetDialog1.width = 500
	vetDialog1:addText("Units with special abilities as settlers, diplomats, or merchants will never receive veteran status at the time they are built. For all other unit types, each unit built within a city makes it " .. constant.mmVeterancy.UNIT_TYPE_BUILT_GAIN_PCT .. "% more likely that the next unit of the same type, built in that city, will be a veteran. The percent chance for human land units (i.e., excluding artillery) is increased by " .. constant.mmVeterancy.BARRACKS_GAIN_PCT .. "% in a city that contains a Barracks, and is also increased by " .. constant.mmVeterancy.WHITE_TOWER_GAIN_PCT .. "% in every city if your nation has the White Tower Fortress wonder. Similarly, the percent chance for naval units is increased by " .. constant.mmVeterancy.SHIPYARD_GAIN_PCT .. "% in a city that contains a Shipyard, and is also increased by " .. constant.mmVeterancy.TAPESTRY_GAIN_PCT .. "% in every city if your nation has the Commemorative Tapestry wonder.")
	vetDialog1:addOption("EXIT", 0)
	vetDialog1:addOption("Display veteran chances by city", 1)
	vetDialog1:addOption("Display veteran chances by unit type", 2)
	log.action("Dialog box displayed")
	local vetResult1 = vetDialog1:show()
	if vetResult1 == 1 then
		local showCityPage = 1
		repeat
			local staticOptions = { [-1] = "EXIT" }
			local pagedOptions = { }
			for city in civ.iterateCities() do
				if city.owner == humanTribe then
					pagedOptions[city.id] = city.name
				end
			end
			local vetResult2 = -1	-- moving the "local" declaration to the following line will also define showCityPage as a (new) local variable, which is not what I want
			vetResult2, showCityPage = uiutil.optionDialog("Select a City", nil, 250, staticOptions, pagedOptions, 26, showCityPage)
			if vetResult2 ~= -1 then
				-- Player selected a city; display all unit types which can be built in that city:
				-- Unit types will be listed in ID order, as they appear on the build option list
				local city = civ.getCity(vetResult2)
				local messageText = ""
				for unittype in unitutil.iterateUnitTypes() do
					if unittype.role <= 4 and canBuildUnitType(humanTribe, city, unittype) then
						messageText = messageText .. unittype.name .. ": " .. tostring(math.min(getVeteranPercent(city, unittype), 100)) .. "%|"
					end
				end
				uiutil.messageDialog("Veteran Unit Chances in " .. city.name, messageText, 350)
			end
		until
			vetResult2 == -1
	elseif vetResult1 == 2 then
		local showUnittypePage = 1
		repeat
			local staticOptions = { [-1] = "EXIT" }
			local pagedOptions = { }
			for unittype in unitutil.iterateUnitTypes() do
				if unittype.role <= 4 and canBuildUnitType(humanTribe, nil, unittype) then
					pagedOptions[unittype.id] = unittype.name
				end
			end
			local vetResult2 = -1	-- moving the "local" declaration to the following line will also define showUnittypePage as a (new) local variable, which is not what I want
			vetResult2, showUnittypePage = uiutil.optionDialog("Select a Unit Type", nil, 250, staticOptions, pagedOptions, 26, showUnittypePage)
			if vetResult2 ~= -1 then
				-- Player selected a unit type; display all cities which can build that unit type:
				-- Cities will be listed in ID order, as they are in most game screens
				local unittype = civ.getUnitType(vetResult2)
				local messageText = ""
				for city in civ.iterateCities() do
					if city.owner == humanTribe and canBuildUnitType(city.owner, city, unittype) then
						messageText = messageText .. city.name .. ": " .. tostring(math.min(getVeteranPercent(city, unittype), 100)) .. "%|"
					end
				end
				uiutil.messageDialog("Veteran Unit Chances for " .. unittype.name, messageText, 350)
			end
		until
			vetResult2 == -1
	end
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 11

return {
	confirmLoad = confirmLoad,

	applyIntendedVetStatusForUnit = applyIntendedVetStatusForUnit,
	applyIntendedVetStatusForTribeUnits = applyIntendedVetStatusForTribeUnits,
	clearUnitBuiltDataForCity = clearUnitBuiltDataForCity,
	documentIntendedVetStatus = documentIntendedVetStatus,
	documentUnitBuilt = documentUnitBuilt,
	listVeteranChances = listVeteranChances,
}
