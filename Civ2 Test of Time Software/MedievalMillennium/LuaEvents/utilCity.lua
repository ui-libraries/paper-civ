-- utilCity.lua
-- by Knighttime

-- Note: require log.lua in the main events.lua file first, in order to require and use this file.

log.trace()

local UTIL_FILE_NAME = "utilCity"
local UTIL_FILE_VERSION = 1.00

-- This table reflects calculations performed by the game engine. It should never be edited, since doing so would lead to
--		inconsistent and inaccurate results.
local DIFFICULTY_LEVEL_FACTOR = {
	 [0] = 1.5,
	 [1] = 1.3,
	 [2] = 1.2,
	 [3] = 1.0,
	 [4] = 0.9,
	 [5] = 0.8,
	 [6] = 0.7,
	 [7] = 0.6,
	 [8] = 0.5,
	 [9] = 0.4,
	[10] = 0.3,
	[11] = 0.2,
	[12] = 0.1
}

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
local function confirmLoad (requiredVersion) --> boolean
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " v" .. UTIL_FILE_VERSION .. " loaded successfully")
	if requiredVersion ~= nil and requiredVersion > UTIL_FILE_VERSION then
		log.error("Version " .. requiredVersion .. " of " .. UTIL_FILE_NAME .. ".lua is required, but a lower version (" .. UTIL_FILE_VERSION .. ") was found. Please download and install an updated version of this Lua utility file, and then restart the game. If you fail to do so, Lua events may crash or not work as intended.")
		log.action("")
		return false
	end
	log.info("")
	return true
end

-- ===========================================================
-- ••••••••••••••• STRICTLY INTERNAL FUNCTIONS •••••••••••••••
-- ===========================================================
-- Credit to SlowThinker via https://apolyton.net/forum/miscellaneous/archives/civ2-strategy-archive/62524-corruption-and-waste
local function calculateCorruption (city, totalTrade) --> integer
	log.trace()
	local factorByGovernment = {
		[0] = 3.750,	-- Anarchy			= 15 / 4
		[1] = 3.000,	-- Despotism		= 15 / 5
		[2] = 2.500,	-- Monarchy			= 15 / 6
		[3] = 2.143,	-- Communism		= 15 / 7
		[4] = 0.000,	-- Fundamentalism
		[5] = 1.875,	-- Republic			= 15 / 8
		[6] = 0.000		-- Democracy
	}
	local governmentId = city.owner.government

	-- Duplicates code found in utilTribe.findCapital()
	local capital = nil
	for altCity in civ.iterateCities() do
		if altCity.owner == city.owner and civ.hasImprovement(altCity, civ.getImprovement(1)) then
			capital = altCity
			break
		end
	end

	local distanceFromCapital = 0
	if governmentId == 3 then
		distanceFromCapital = civ.cosmic.communismPalaceDistance
		if capital ~= nil and city == capital then
			distanceFromCapital = distanceFromCapital / 2
		end
	elseif capital ~= nil and capital.location.z == city.location.z then
		-- Important note: this is NOT the same formula for distance found in utilTile.getDistance()
		-- That one measures distance as the number of moves required by a unit to move between the tiles
		-- By contrast, the formula for corruption uses distance that treats cardinal tiles as 1.5 apart,
		--		and intercardinal tiles as 1.0 apart.  This is an approximation of SQRT(2) = 1.414.
		-- The following formula is tested and confirmed to be correct for this purpose.
		local xdiff = math.abs(city.location.x - capital.location.x)
		local ydiff = math.abs(city.location.y - capital.location.y)
		distanceFromCapital = math.floor(math.min(xdiff, ydiff) + (math.abs(xdiff - ydiff) * 0.5 * 1.5))
	else
		distanceFromCapital = 32
	end

	local difficultyLevel = 0
	if governmentId <= 1 then
		difficultyLevel = civ.game.difficulty
	end

	local distanceFactor = math.min(distanceFromCapital + difficultyLevel, 32)
	local corruption = (totalTrade * distanceFactor * factorByGovernment[governmentId]) / 100
	if civ.hasImprovement(city, civ.getImprovement(7)) then
		corruption = corruption / 2
	end
	corruption = math.floor(corruption)
	return corruption
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
-- This is also called internally by getFoodMax() and must be declared prior to it in this file:
local function getFoodRows (tribe, humanIsSupreme) --> integer
	log.trace()
	local foodRows = civ.cosmic.foodRows
	if tribe.isHuman == false then
		local difficultyFactor = DIFFICULTY_LEVEL_FACTOR[civ.game.difficulty]
		if difficultyFactor == nil then
			log.error("ERROR! " .. UTIL_FILE_NAME .. ".getFoodRows() found difficultyFactor = nil for difficultyLevel = " .. tostring(civ.game.difficulty))
			difficultyFactor = 1.0
		end
		if civ.cosmic.foodRows == 10 then
			-- Odd or even numbers are valid for AI tribes:
			foodRows = math.floor((civ.cosmic.foodRows * difficultyFactor) + 0.5)
		else
			-- Only even numbers are valid for AI tribes:
			foodRows = math.floor((civ.cosmic.foodRows * difficultyFactor * 0.5) + 0.5) * 2
		end
		if civ.getTurn() >= 200 and humanIsSupreme then
			foodRows = foodRows - 2
		end
	end
	return foodRows
end

-- This is also called internally by getCurrentFood() and must be declared prior to it in this file:
local function getFoodMax (city, humanIsSupreme) --> integer
	log.trace()
	-- foodMax is equal to "rows" x "columns" per the following formula:
	local result = getFoodRows(city.owner, humanIsSupreme)
	return result * (city.size + 1)
end

local function getCurrentFood (city, humanIsSupreme) --> integer
	log.trace()
	local currentFood = city.food
	local maxFood = getFoodMax(city, humanIsSupreme)
	if currentFood > 65000 then
		-- This means that the city's food box is empty and the city has a food deficit, so the game will reduce the city in size next turn
		currentFood = 0
	elseif currentFood > maxFood then
		-- This means that the city's food box is "overfull", however it displays as full in the game, and the additional food does not carry over
		--		when the city increments in size
		currentFood = maxFood
	end
	return currentFood
end

-- This is also called internally by changeFood() and setSizeAsDecimal() and must be declared prior to them in this file:
local function changeSize (city, amount) --> boolean
	log.trace()
	log.info("Processing size change for " .. city.name .. ": " .. tostring(amount))
	if amount == 0 then
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".changeSize() called with amount = 0")
		return false
	end
	local success = true
	-- Note that this function will return true only if the *full* amount of the change is supported.
	-- Even in cases where it returns false, though, a *portion* of the change may have been supported and applied.
	local origCitySize = city.size
	local newCitySize = origCitySize + amount
	if amount > 0 then
		if newCitySize > civ.cosmic.sizeSewer and not(civ.hasImprovement(city, civ.getImprovement(23))) then
			newCitySize = civ.cosmic.sizeSewer
			success = false
		end
		if newCitySize > civ.cosmic.sizeAquaduct and not(civ.hasImprovement(city, civ.getImprovement(9))) then
			newCitySize = civ.cosmic.sizeAquaduct
			success = false
		end
		if newCitySize < origCitySize then
			newCitySize = origCitySize	-- never permit the city to *shrink* due to a failed gain (e.g., if an aqueduct/sewer was sold/destroyed)
		end
		city.size = newCitySize
		if newCitySize > origCitySize then
			log.action("Increased population of " .. city.owner.adjective .. " city of " .. city.name .. " from " .. origCitySize .. " to " .. newCitySize)
		end
		if newCitySize < (origCitySize + amount) then
			log.action("  Population should have increased by " .. amount .. " to " .. (origCitySize + amount) .. " but city does not have necessary improvement(s).")
		end
	else
		if newCitySize < 1 then
			newCitySize = 1
			success = false
		end
		city.size = newCitySize
		if newCitySize < origCitySize then
			log.action("Decreased population of " .. city.owner.adjective .. " city of " .. city.name .. " from " .. origCitySize .. " to " .. newCitySize)
			-- A population decrease to a human player's city seems to trigger a UI popup automatically, even when the decrease originates programmatically like this.
		end
		if newCitySize > (origCitySize + amount) then
			log.action("  Population should have decreased by " .. amount .. " to " .. (origCitySize + amount) .. " but decrease was halted at 1.")
		end
	end
	civ.ui.redrawTile(city.location)
	return success
end

local function changeFood (city, quantity, humanIsSupreme) --> void
	log.trace()
	log.info("Processing food change for " .. city.name .. ": " .. tostring(quantity))
	if quantity == 0 then
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".changeFood() called with quantity = 0")
		return
	end
	if humanIsSupreme == nil and civ.getTurn() >= 200 then
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".changeFood() called with humanIsSupreme = nil; calculations may not be accurate")
	end
	local origCitySize = city.size
	local origCityFood = getCurrentFood(city, humanIsSupreme)
	local remainingQuantity = quantity
	while math.abs(remainingQuantity) > 0 do
		if remainingQuantity > 0 then
			local foodGainCapacity = getFoodMax(city, humanIsSupreme) - getCurrentFood(city, humanIsSupreme)
			local changeAmount = math.min(remainingQuantity, foodGainCapacity)
			city.food = getCurrentFood(city, humanIsSupreme) + changeAmount
			remainingQuantity = remainingQuantity - changeAmount
			if remainingQuantity > 0 then
				local success = changeSize(city, 1)					-- increase the city size, if possible
				if success then
					city.food = 0
					local hasGranaryBenefit = false
					local granaryImprovement = civ.getImprovement(3)
					if civ.hasImprovement(city, granaryImprovement) then
						hasGranaryBenefit = true
						log.info("  Found " .. granaryImprovement.name .. " in " .. city.name)
					else
						local granaryWonder = civ.getWonder(0)
						if granaryWonder.city ~= nil then
							if granaryWonder.city.owner == city.owner and (granaryWonder.expires == nil or granaryWonder.expires.researched == false) then
								hasGranaryBenefit = true
								log.info("  Found " .. granaryWonder.name .. " belonging to " .. city.owner.name)
							end
						end
					end
					if hasGranaryBenefit then
						local updatedFoodMax = getFoodMax(city, humanIsSupreme)
						city.food = updatedFoodMax / 2
						log.info("  Added " .. tostring(updatedFoodMax / 2) .. " food to " .. city.name .. " to fill 50% of box")
					else
						log.info("  Did not apply " .. granaryImprovement.name .. " benefit to " .. city.name)
					end
					log.info("Food change remaining: " .. tostring(remainingQuantity))
				else
					remainingQuantity = 0
				end
			end
		else
			local foodLossCapacity = getCurrentFood(city, humanIsSupreme) * -1
			local changeAmount = math.max(remainingQuantity, foodLossCapacity)
			city.food = getCurrentFood(city, humanIsSupreme) + changeAmount
			remainingQuantity = remainingQuantity - changeAmount
			if remainingQuantity < 0 then
				local success = changeSize(city, -1)				-- decrease the city size, if possible
				if success then
					city.food = getFoodMax(city, humanIsSupreme)
					log.info("Food change remaining: " .. tostring(remainingQuantity))
				else
					remainingQuantity = 0
				end
			end
		end
	end
	log.action("Completed food change for " .. city.owner.adjective .. " city of " .. city.name .. ";")
	log.action("  was size " .. origCitySize .. ", food " .. origCityFood .. "; now size " .. city.size .. ", food " .. city.food)
end

local function changeShields (city, quantity) --> void
	-- If called with a negative quantity that exceeds the city's quantity of accumulated shields, it will set city.shields to 0.
	log.trace()
	local origCityShields = city.shields
	if quantity > 0 then
		city.shields = origCityShields + quantity
		log.action("Added " .. quantity .. " shield(s) to " .. city.owner.adjective .. " city of " .. city.name .. " (was " .. origCityShields .. ", now " .. city.shields .. ")")
		-- NOTE: This may overflow the shield box; since we don't know what a city is building, we have no way to tell if that's the case
		--		 Fortunately this does not seem to cause issues within the game
	elseif quantity == 0 then
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".changeShields() called with quantity = 0")
	else
		-- quantity < 0, intending to subtract shields from city's shield box
		local absQuantity = math.abs(quantity)
		if city.shields == 0 then
			log.info("Attempted to remove " .. absQuantity .. " shields from " .. city.owner.adjective .. " city of " .. city.name .. " but they had 0")
		else
			if origCityShields < absQuantity then
				city.shields = 0
				log.action("Removed " .. origCityShields .. " shields from " .. city.owner.adjective .. " city of " .. city.name .. " (was " .. origCityShields .. ", now 0)")
				log.action("  Attempted to remove " .. absQuantity .. " shields but city only had " .. origCityShields)
			else
				city.shields = city.shields + quantity		-- adding a negative number
				log.action("Removed " .. absQuantity .. " shields from " .. city.owner.adjective .. " city of " .. city.name .. " (was " .. origCityShields .. ", now " .. city.shields .. ")")
			end
		end
	end
end

local function createCity (name, tribe, tile) --> city
	log.trace()
	local city = civ.createCity(tribe, tile)
	if city == nil then
		log.warning("WARNING: could not create city of " .. name .. " for " .. tribe.name .. " at " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	else
		city.name = name
		log.action("Created " .. city.owner.adjective .. " city of " .. city.name .. " (ID " .. city.id .. ") at " .. tile.x .. "," .. tile.y .. "," .. tile.z)
	end
	return city
end

-- This is also called internally by deleteCity(), getNumSettlersSupported(), and getNumUnitsSupported(), and must be declared prior to them in this file:
local function iterateHomeCityUnits (city) --> iterator (of unit objects)
	log.trace()
	return coroutine.wrap(function ()
		if city ~= nil and civ.isCity(city) then
			for unit in civ.iterateUnits() do
				if unit.homeCity == city then
					coroutine.yield(unit)
				end
			end
		end
	end)
end

local function deleteCity (city, preserveSupportedUnits, newSupportCity) --> void
-- Deleting a city will automatically delete any units that are supported by that city.
-- The second and third parameters provide you with the option to override that behavior by reassigning them first.
-- If units will be deleted, the function deletes them manually first, in order to log this action.
	log.trace()
	local newHomeCity = nil
	if newSupportCity ~= nil and civ.isCity(newSupportCity) and newSupportCity ~= city and newSupportCity.owner == city.owner then
		newHomeCity = newSupportCity
	end
	for unit in iterateHomeCityUnits(city) do
		if preserveSupportedUnits then
			local newHomeCityName = "nil"
			if newHomeCity ~= nil then
				newHomeCityName = newHomeCity.name
			end
			log.action("Changed home city of " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") from " .. unit.homeCity.name .. " to " .. newHomeCityName)
			unit.homeCity = newHomeCity
		else
			log.action("Deleted " .. unit.owner.adjective .. " " .. unit.type.name .. " (ID " .. unit.id .. ") from " .. unit.x .. "," .. unit.y .. "," .. unit.z)
			civ.deleteUnit(unit)
		end
	end
	local cityLocation = city.location
	log.action("Deleted " .. city.owner.adjective .. " city of " .. city.name .. " (ID " .. city.id .. ") from " .. cityLocation.x .. "," .. cityLocation.y .. "," .. cityLocation.z)
	civ.deleteCity(city)
	civ.ui.redrawTile(cityLocation)
end

-- Replaces civlua.findCity()
local function findByName (cityName, blockInfoMessage) --> city
	log.trace()
	local city = nil
	for potentialCity in civ.iterateCities() do
		if potentialCity.name == cityName then
			city = potentialCity
			break
		end
	end
	if city ~= nil then
		if blockInfoMessage then
			-- Do nothing
		else
			log.info("Found city \"" .. cityName .. "\" with ID " .. city.id)
		end
	else
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".findByName() did not find city with name \"" .. tostring(cityName) .. "\"")
	end
	return city
end

local function getCorruption (city) --> integer
	log.trace()
	-- Unfortunately city.totalTrade actually contains the *net* trade left *after* corruption has been deducted
	-- We can run the calculation multiple times for improved accuracy, but it is still imperfect and will be
	--		incorrect (too low, usually by 1 or maybe 2) in some cases.
	local corruption = { [0] = 0 }
	local finalIteration = 1
	for n = 1, 20 do	-- 20 iterations is arbitrary, but it's hard to imagine that being insufficient
		corruption[n] = calculateCorruption(city, city.totalTrade + corruption[n - 1])
		if corruption[n] == corruption[n - 1] then
			finalIteration = n
			break
		end
	end
	return corruption[finalIteration]
end

-- This is also called internally by getCurrentFoodSurplus() and must be declared prior to it in this file:
local function getNumSettlersSupported (city) --> integer
	log.trace()
	local settlersSupported = 0
	for unit in iterateHomeCityUnits(city) do
		if unit.type.role == 5 then
			settlersSupported = settlersSupported + 1
		end
	end
	return settlersSupported
end

local function getCurrentFoodSurplus (city) --> integer
	log.trace()
	local settlerFoodPerTurn = civ.cosmic.settlersEatLow
	if city.owner.government >= 3 then
		settlerFoodPerTurn = civ.cosmic.settlersEatHigh
	end
	local currentFoodSurplus = city.totalFood - (city.size * civ.cosmic.foodEaten) - (getNumSettlersSupported(city) * settlerFoodPerTurn)
	return currentFoodSurplus
end

local function getNumUnitsSupported (city) --> integer
	log.trace()
	local unitsSupported = 0
	for unit in iterateHomeCityUnits(city) do
		-- Cities never pay support for units with role 6 or role 7
		if unit.type.role <= 5 then
			unitsSupported = unitsSupported + 1
		end
	end
	return unitsSupported
end

local function getShieldColumns (tribe, humanIsSupreme) --> integer
	log.trace()
	if humanIsSupreme == nil and civ.getTurn() >= 200 then
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".getShieldColumns() called with humanIsSupreme = nil; calculations may not be accurate")
	end
	local shieldColumns = civ.cosmic.shieldRows
	if tribe.isHuman == false then
		local difficultyFactor = DIFFICULTY_LEVEL_FACTOR[civ.game.difficulty]
		if difficultyFactor == nil then
			log.error("ERROR! " .. UTIL_FILE_NAME .. ".getShieldColumns() found difficultyFactor = nil for difficultyLevel = " .. tostring(civ.game.difficulty))
			difficultyFactor = 1.0
		end
		if civ.cosmic.shieldRows == 10 then
			-- Odd or even numbers are valid for AI tribes:
			shieldColumns = math.floor((civ.cosmic.shieldRows * difficultyFactor) + 0.5)
		else
			-- Only even numbers are valid for AI tribes:
			shieldColumns = math.floor((civ.cosmic.shieldRows * difficultyFactor * 0.5) + 0.5) * 2
		end
		if civ.getTurn() >= 200 and humanIsSupreme then
			shieldColumns = shieldColumns - 2
		end
	end
	return shieldColumns
end

local function getSizeAsDecimal (city, humanIsSupreme) --> decimal
	log.trace()
	if humanIsSupreme == nil and civ.getTurn() >= 200 then
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".getSizeAsDecimal() called with humanIsSupreme = nil; calculations may not be accurate")
	end
	local currentFood = getCurrentFood(city, humanIsSupreme)
	local maxFood = getFoodMax(city, humanIsSupreme)
	local sizeAsDecimal = city.size + (currentFood / maxFood)
	if currentFood == maxFood then
		-- Set the city to be 1/1000th below the actual size
		-- Without this tweak, a size 1 city with a full food box and a size 2 city with an empty food box would both report as 2.0 (for example)
		-- Now they will report as 1.999 and 2.0 respectively, to differentiate
		sizeAsDecimal = sizeAsDecimal - 0.001
	end
	return sizeAsDecimal
end

local function setSizeAsDecimal (city, sizeAsDecimal, humanIsSupreme) --> void
	log.trace()
	if humanIsSupreme == nil and civ.getTurn() >= 200 then
		log.warning("WARNING: " .. UTIL_FILE_NAME .. ".setSizeAsDecimal() called with humanIsSupreme = nil; calculations may not be accurate")
	end
	local origSizeAsDecimal = getSizeAsDecimal(city, humanIsSupreme)
	local origPopulation = city.size
	local origFood = getCurrentFood(city, humanIsSupreme)
	local newPopulation = math.floor(sizeAsDecimal)
	local success = true
	if newPopulation ~= origPopulation then
		city.food = 0
		success = changeSize(city, newPopulation - origPopulation)
		if success == false then
			city.food = origFood
		end
	end
	if success then
		-- Either there was no population change, or it was successful
		-- Also set food:
		local maxFood = getFoodMax(city, humanIsSupreme)
		local newFood = math.floor(((sizeAsDecimal - newPopulation) * maxFood) + 0.5)
		city.food = newFood
		log.action("Set size of " .. city.name .. " to " .. string.format("%.4f", sizeAsDecimal) .. " (" .. newPopulation .. " + " .. newFood .. " food); was " ..
			string.format("%.4f", origSizeAsDecimal) .. " (" .. origPopulation .. " + " .. origFood .. " food)")
	else
		log.error("ERROR! " .. UTIL_FILE_NAME .. ".setSizeAsDecimal() could not set size of " .. city.name .. " to " .. string.format("%.4f", sizeAsDecimal))
	end
end

local function hasAttributeCivilDisorder (city) --> boolean
	log.trace()
	return city.attributes & 0x01 == 0x01
end

local function hasAttributeWeLoveTheKing (city) --> boolean
	log.trace()
	return city.attributes & 0x02 == 0x02
end

local function isCapital (city) --> boolean
	log.trace()
	local hasPalace = civ.hasImprovement(city, civ.getImprovement(1))
	return hasPalace
end

-- This function is copied as utilTile.getCitySpecialistsByType() where it is a strictly internal function, and renamed there for context,
-- 		to avoid dependencies between utility modules
-- Note that there is no setSpecialistsByType() here; instead, utilTile.setCitySpecialistsByType() is a strictly internal function,
--		which is called by the external-facing function utilTile.setCityTilesWorked()
-- It would be possible to add setSpecialistsByType() here, as long as this was limited to changing the type of existing specialists
-- Adding or removing specialists overall gets into the topic of tiles worked, which is more appropriately in the domain of utilTile.
local function getSpecialistsByType (city) --> integer, integer, integer
	-- Returns the number of Entertainers, Taxmen, and Scientists currently present in a city, in that order
	log.trace()
	local numEntertainers = 0
	local numTaxmen = 0
	local numScientists = 0
	local specialistsBitValue = city.specialists
	while specialistsBitValue > 0 do
		if specialistsBitValue & 0x03 == 0x01 then
			numEntertainers = numEntertainers + 1
		elseif specialistsBitValue & 0x03 == 0x02 then
			numTaxmen = numTaxmen + 1
		elseif specialistsBitValue & 0x03 == 0x03 then
			numScientists = numScientists + 1
		end
		specialistsBitValue = specialistsBitValue >> 2
	end
	return numEntertainers, numTaxmen, numScientists
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 26

return {
	confirmLoad = confirmLoad,

	getFoodRows = getFoodRows,
	getFoodMax = getFoodMax,
	getCurrentFood = getCurrentFood,
	changeSize = changeSize,
	changeFood = changeFood,
	changeShields = changeShields,
	createCity = createCity,
	iterateHomeCityUnits = iterateHomeCityUnits,
	deleteCity = deleteCity,
	findByName = findByName,
	getCurrentFoodSurplus = getCurrentFoodSurplus,
	getCorruption = getCorruption,
	getNumSettlersSupported = getNumSettlersSupported,
	getNumUnitsSupported = getNumUnitsSupported,
	getShieldColumns = getShieldColumns,
	getSizeAsDecimal = getSizeAsDecimal,
	setSizeAsDecimal = setSizeAsDecimal,
	hasAttributeCivilDisorder = hasAttributeCivilDisorder,
	hasAttributeWeLoveTheKing = hasAttributeWeLoveTheKing,
	isCapital = isCapital,
	getSpecialistsByType = getSpecialistsByType,
}
