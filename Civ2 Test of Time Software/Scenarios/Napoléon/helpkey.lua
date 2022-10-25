--[[
helpkey.lua, by Knighttime and tootall_2012
	for Napoléon, a scenario by tootall_2012
	based upon the module found in Over the Reich, by JPetroski and Prof. Garfield
]]

local func = require "functions"

local defaultFlagTextTable = {
	[1]  = "Two space visibility",
	[2]  = "Ignores zones of control",
	[3]  = "Can make amphibious assaults",
	[4]  = "Submarine advantages/disadvantages",
	[5]  = "Can attack air units (fighter)",
	[6]  = "Ship must stay near land (trireme)",
	[7]  = "Negates city walls (howitzer)",
	[8]  = "Can carry air units (carrier)",
	[9]  = "Can make paradrops",
	[10] = "Alpine (treats all squares as road)",
	[11] = "x2 on defense versus horse (pikemen)",
	[12] = "Free support for fundamentalism (fanatics)",
	[13] = "Destroyed after attacking (missiles)",
	[14] = "x2 on defense versus air (AEGIS)",
	[15] = "Unit can spot submarines"
}

-- Distance for flat map, ignore elevation distance between maps
local function flatDistance (tile1, tile2)
	return math.ceil((math.abs(tile1.x - tile2.x) + math.abs(tile1.y - tile2.y)) / 2)
end

-- The default unit text function will display the distance to the nearest friendly city.
-- To override/enhance/eliminate this, define a custom unit text function and provide it as a parameter to helpKey
local function defaultUnitTextFunction (unit)
	local nearestCity = nil
	local distanceToCity = 1000
	for city in civ.iterateCities() do
		if city.owner == unit.owner and city.location.z == unit.location.z then
			if flatDistance(unit.location,city.location) < distanceToCity then
				nearestCity = city
				distanceToCity = flatDistance(unit.location,city.location)
			end
		end
	end
	local nearestCityText = "No friendly city found on this map."
	if nearestCity then
		nearestCityText = "Nearest friendly city is " .. nearestCity.name .. " at a distance of " .. tostring(distanceToCity) .. "."
	end
	return nearestCityText
end

--[[
If a unit is active and keyCode matches helpKeyCode, then a dialog box displaying help
information for the unit is created. This only works for active units, since otherwise
it could be used to check any tile for an enemy unit (additional TOTPP Lua functionality
could potentially allow for visible enemy units to be checked)

customFlagTextTable is optional. If nil, defaultFlagTextTable (defined above) will be used instead.
	This is a table of strings to be displayed if the unittype has that particular flag
customUnitTypeTextTable is optional. If nil, no additional info is included.
	This is a table of strings to be displayed that give extra information about the unit if the creator specifies it.
	It can handle values consisting of either a single string, or a table of strings.
customUnitTextFunction is optional. If nil, defaultUnitTextFunction (defined above) will be used instead.
	This takes the specific unit as a parameter and returns a string giving extra information/help.
	E.g., a flying unit could return the distance to the nearest airbase, etc.
	It can handle return values consisting of either a single string, or a table of strings.
]]
local function helpKey (keyCode, helpKeyCode, customFlagTextTable, customUnitTypeTextTable, customUnitTextFunction)
	if keyCode == helpKeyCode and civ.getActiveUnit() then
		local activeUnit = civ.getActiveUnit()
		local helpWindow = civ.ui.createDialog()
		helpWindow.title = "Help for " .. activeUnit.type.name
		-- helpWindow:addText(func.splitlines("_______Attack Value: "..tostring(activeUnit.type.attack).." _____-____ " ..
			-- " Firepower: "..tostring(activeUnit.type.firepower), 21))
		helpWindow:addCheckbox("Attack Value: " .. tostring(activeUnit.type.attack) ..
			"            Firepower: " .. tostring(activeUnit.type.firepower), 21)
		helpWindow:addCheckbox("Defense Value: " .. tostring(activeUnit.type.defense) ..
			"        Hit Points: " .. tostring(activeUnit.hitpoints) .. " (out of " .. tostring(activeUnit.type.hitpoints) .. ")", 22)
		helpWindow:addCheckbox("Movement Rate: " .. string.format("%.2f", (activeUnit.type.move - activeUnit.moveSpent) / totpp.movementMultipliers.aggregate) ..
			" (out of " .. tostring(math.floor(activeUnit.type.move / totpp.movementMultipliers.aggregate)) .. ")", 23)

		local roleText = nil
		if activeUnit.type.domain == 1 then
			roleText = "Range: " .. tostring(activeUnit.type.range)
		elseif activeUnit.type.domain == 2 then
			roleText = "Carries: " .. tostring(activeUnit.type.hold)
		end
		if roleText then
			helpWindow:addCheckbox(roleText, 24)
		end

		for i = 1, 15 do
			if activeUnit.type.flags & 2^(i-1) == 2^(i-1) then
				if customFlagTextTable and customFlagTextTable[i] then
					helpWindow:addCheckbox("• " .. customFlagTextTable[i], i)
				else
					helpWindow:addCheckbox("• " .. defaultFlagTextTable[i], i)
				end
			end
		end

		if customUnitTypeTextTable and customUnitTypeTextTable[activeUnit.type.id] then
			if type(customUnitTypeTextTable[activeUnit.type.id]) == "table" then
				for key, value in ipairs(customUnitTypeTextTable[activeUnit.type.id]) do
					helpWindow:addCheckbox(value, 25 + (key * 100))
				end
			else
				helpWindow:addCheckbox(customUnitTypeTextTable[activeUnit.type.id], 25)
			end
		end
		-- Note: there is no defaultUnitTypeTextTable, so the above information is only displayed if a custom one is provided

		if customUnitTextFunction and customUnitTextFunction(activeUnit) then
			if type(customUnitTextFunction(activeUnit)) == "table" then
				for key, value in ipairs(customUnitTextFunction(activeUnit)) do
					helpWindow:addCheckbox(value, 26 + (key * 100))
				end
			elseif customUnitTextFunction(activeUnit) ~= "" then
				helpWindow:addCheckbox(customUnitTextFunction(activeUnit), 26)
			end
		else
			helpWindow:addCheckbox(defaultUnitTextFunction(activeUnit), 26)
		end

		helpWindow:show()
	end
end

return {
	helpKey = helpKey,
}
