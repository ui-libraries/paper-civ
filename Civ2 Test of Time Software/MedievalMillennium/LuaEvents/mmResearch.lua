-- mmResearch.lua
-- by Knighttime

log.trace()

constant.mmResearch = { }
constant.mmResearch.MAX_TECHS_DESIRED = 91							-- There are 93 techs that a nation can own by the end of the game; the human player will also always have "High Middle Ages"
																	--		meaning for them, the max is 94. This does not include "The Renaissance" which can be researched multiple times.
																	--		The other techs which will be unknown at game end are: Tribal Religion, SPECIAL, (UNUSED-T5), (UNUSED-T38), and (UNUSED-T66).
																	--		(There are 100 total tech slots, numbered 0 through 99.)
																	--		Because "Wheellocks" and "Muskets" did not appear historically until after 1500, they are excluded from this number.
																	--		However, nations could choose to research them before some techs which *are* included
constant.mmResearch.MAX_TECH_TURNS_DESIRED = 491					-- Number of turns within which MAX_TECHS_DESIRED are intended to be learned/acquired. If this is set to 500, the last tech
																	--		is learned at the very end of the game, before any benefits it provides can be utilized. By setting this to a lower
																	--		number, any benefits (such as new unit types) can be used for at least a few turns before the game ends.
constant.mmResearch.BASE_TECH_PARADIGM = 10							-- The tech paradigm used in a standard (base) game of Civ. Used in MM only for calculating relative percentages for onscreen display,
																	--		so that percentages are relative to what the player *expects* rather than to the following constant which MM actually uses.
constant.mmResearch.INITIAL_TECH_PARADIGM = 15						-- Initial tech paradigm set at the beginning of a new game. This overrides the value stored in Rules.txt, if there is a conflict.
constant.mmResearch.CONSTRAIN_TECH_PARADIGM_UNTIL_YEAR = 1000		-- The tech paradigm is constrained (both min and max) by the percent of the game that has elapsed, until this year.
																	--		After that point, the constraints are lifted and the true calculated paradigm is applied. (This does not prevent the
																	--		application of the following parameter, however.)  Note that changes in the tech rate are only announced up until this year
																	--		as well, since beyond that the extreme values may leave the player wondering what's going on!
constant.mmResearch.PARADIGM_REVERSE_ELAPSED_TURNS_MIN = 4			-- Number of turns that must have elapsed since the last tech paradigm change, before that change can be REVERSED and
																	-- 		head in the opposite direction. However, it can change again on the very next turn in the *same* direction as
																	-- 		the previous change, without restriction; this resets the counter. Set to 4 because this matches the frequency of Oedo years.
																	--		NOTE: This only applies up until the "constrain" year (prior constant); after that, since tech rate changes are not announced,
																	--		the rate is allowed to change every year, in any direction.
constant.mmResearch.TECH_GROUP_CHRISTIAN_THRESHOLD_PERCENT =		-- Once you have learned this percent of the techs in a tech group (I, II, or III) then you unlock the next tech group
	{ 70, 70, 80 }													-- 		These values apply if you have knowledge of Catholic Christianity. Unique numbers are due to varying numbers of techs,
																	--		likelihood of potential paths, etc.
constant.mmResearch.TECH_GROUP_TRIBAL_THRESHOLD_PERCENT =			-- Once you have learned this percent of the techs in a tech group (I, II, or III) then you unlock the next tech group
	{ 55, 45, 17.5 }												-- 		These values apply if you do NOT have knowledge of Catholic Christianity. Unique numbers are due to varying numbers of techs,
																	--		likelihood of potential paths, etc.
constant.mmResearch.RESEARCH_BONUS = { 0, 0, 1, 1, 2, 2, 3 }		-- Number of research "points" (scrolls/beakers) silently awarded to a nation for free, every turn, based on their position
																	--		in the tech race. Nation with most techs known gets 0, etc. If fewer than 7 nations are active, bonuses for lower
																	--		positions are ignored. Note that these are static points, not a percentage of the cost of the next advance.
																	--		Thus, early in the game, this will have a much more substantial impact on keeping the tech race close;
																	--		but as the game advances and research costs increase, this will play a smaller and smaller role.

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
-- This is apparently the only supported way to change the tech paradigm in a mod. It does not use/recognize the value
--		that can be entered in Rules.txt, which is civ.cosmic.techParadigm
-- The values assigned here apply at the beginning of a new game, but will be overwritten when a saved game is loaded
--		with info from that saved game file.
civ.scen.params.techParadigm = constant.mmResearch.INITIAL_TECH_PARADIGM
db.gameData.TECH_PARADIGM = constant.mmResearch.INITIAL_TECH_PARADIGM

db.gameData.TECH_PARADIGM_LAST_DECREASE_TURN = 0
db.gameData.TECH_PARADIGM_LAST_INCREASE_TURN = 0

local function confirmLoad ()
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " loaded successfully")
	log.info("")
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function assignConstitutionalMonarchyTechGroup ()
	log.trace()
	local tech = techutil.findByName("Constitutional Monarchy", true)
	if wonderutil.hasBeenBuilt(MMWONDER.GreatCharter) then
		if tech.group == MMTECHGROUP.High then
			log.info("Confirmed Constitutional Monarchy in tech group " .. MMTECHGROUP.High .. " (" .. MMTECHGROUP[MMTECHGROUP.High] .. ")")
		else
			tech.group = MMTECHGROUP.High
			log.action("Assigned Constitutional Monarchy to tech group " .. MMTECHGROUP.High .. " (" .. MMTECHGROUP[MMTECHGROUP.High] .. ")")
		end
	else
		if tech.group == MMTECHGROUP.Never then
			log.info("Confirmed Constitutional Monarchy in tech group " .. MMTECHGROUP.Never .. " (" .. MMTECHGROUP[MMTECHGROUP.Never] .. ")")
		else
			tech.group = MMTECHGROUP.Never
			log.action("Assigned Constitutional Monarchy to tech group " .. MMTECHGROUP.Never .. " (" .. MMTECHGROUP[MMTECHGROUP.Never] .. ")")
		end
	end
end

local function boostResearchProgress ()
	log.trace()
	local researchData = { }
	for tribe in tribeutil.iterateActiveTribes(false) do
		table.insert(researchData, {
			tribeId = tribe.id,
			techsKnown = techutil.getNumTechsKnown(tribe)
		})
	end
	table.sort(researchData, function(a, b) return a.techsKnown > b.techsKnown end)
	local prevTribeTechsKnown = -1
	local prevTribeResearchBonus = 0
	for order, researchDetail in ipairs(researchData) do
		local tribe = civ.getTribe(researchDetail.tribeId)
		local researchBonus = 0
		if researchDetail.techsKnown < prevTribeTechsKnown then
			researchBonus = constant.mmResearch.RESEARCH_BONUS[order]
		else
			researchBonus = prevTribeResearchBonus
		end
		if researchBonus > 0 then
			tribeutil.changeResearchProgress(tribe, researchBonus)
		else
			log.info("No change to " .. tribe.adjective .. " research progress (currently " .. tribe.researchProgress .. ")")
		end
		prevTribeTechsKnown = researchDetail.techsKnown
		prevTribeResearchBonus = researchBonus
	end
end

local function displayInitialResearchMessages (turn)
	log.trace()
	if turn > 1 then
		local tribe = civ.getPlayerTribe()
		if tribeutil.getCurrentResearch(tribe) == nil then
			local totalScholarship = tribeutil.getTotalScholarship(tribe)
			if totalScholarship > 0 then

				if civ.hasTech(tribe, techutil.findByName("Catholic Christianity", true)) == false then
					uiutil.messageDialog("Game Concept: Governments", "All nations begin Medieval Millennium with a Tribal Monarchy government (in the base game, this type was known as \"Fundamentalism\"). At any point during the game, if you acquire knowledge of the Catholic Christianity advance or any advance which depends upon it (by research, hut, trade, or theft) you will be given a choice of how to proceed.||If you choose to accept this new religion, " .. tribe.name .. " will become a Christian nation. This immediately converts your form of government to Primitive Monarchy (in the base game, this type was known as \"Despotism\") and prevents you from reverting to Tribal Monarchy. Details of both governments are found in the Civilopedia, and you are encouraged to review details there. As a brief summary, Tribal Monarchy has superior production capabilities and no unhappy citizens, but entails a significant research penalty. Primitive Monarchy experiences tile production penalties and potentially unhappy citizens, but research will proceed more quickly and many more technological advances become available.||On the other hand, if you choose to reject Christianity, you will forfeit knowledge of it and any dependent advances, and remain a Tribal Monarchy. This may be advantageous in the short term, but most nations will eventually find it beneficial to accept Christianity because of the long-term benefits that it will make available.||Therefore, please consider carefully if/when you wish to research the Catholic Christianity advance, since this advance has an immediate and substantial impact on the status of your nation.", 640)
				end

				if civ.scen.params.techParadigm == constant.mmResearch.INITIAL_TECH_PARADIGM then
					uiutil.messageDialog("Game Concept: Research Time", "As the Roman empire declined and its influence in Europe diminished during prior centuries, scholarly activity declined to low levels. At the beginning of each game of Medieval Millennium, research costs are set to 150% of normal to reflect the extra time and effort required to acquire new advances. This cost will be adjusted dynamically throughout the game, with the potential to move either lower or higher, depending on the research actions and success of each nation in the game.", 640)
				end

			end
		end
	end
end

local function displayResearchRateDetails (govBonusScience)
	log.trace()
	local messageText = round((civ.scen.params.techParadigm / constant.mmResearch.BASE_TECH_PARADIGM) * 100) .. "% of "
	if civ.scen.params.techParadigm == constant.mmResearch.BASE_TECH_PARADIGM then
		messageText = ""
	end
	messageText = "Scholars report that the time required for research is currently " .. messageText .. " normal."
	local tribe = civ.getPlayerTribe()
	local totalScholarship = tribeutil.getTotalScholarship(tribe) + govBonusScience
	local researchPointsNeeded = math.max(tribe.researchCost - tribe.researchProgress, 0)
	local totalDiscoveryTurns = 0
	local nextDiscoveryTurns = 0
	if totalScholarship > 0 then
		totalDiscoveryTurns = math.max(math.ceil(tribe.researchCost / totalScholarship), 1)
		nextDiscoveryTurns = math.max(math.ceil(researchPointsNeeded / totalScholarship), 1)
	end
	local currentResearchProject = tribeutil.getCurrentResearch(tribe)
	if currentResearchProject ~= nil then
		if nextDiscoveryTurns > 1 then
			messageText = messageText .. "||They anticipate learning the secret of " .. currentResearchProject.name .. " in " .. tostring(nextDiscoveryTurns) .. " turns."
		elseif nextDiscoveryTurns == 1 then
			messageText = messageText .. "||They anticipate learning the secret of " .. currentResearchProject.name .. " in " .. tostring(nextDiscoveryTurns) .. " turn."
		else
			messageText = messageText .. "||No progress is currently being made towards the secret of " .. currentResearchProject.name .. "."
		end
	else
		messageText = messageText .. "||No research project is currently underway."
	end
	if totalDiscoveryTurns > 0 then
		messageText = messageText .. "|Overall, new discoveries are expected every " .. tostring(totalDiscoveryTurns) .. " turns."
	else
		messageText = messageText .. "|No scholarship is being generated, therefore no new discoveries are expected."
	end
	messageText = messageText ..
		"||Total Scholarship per Turn: " .. tostring(totalScholarship) .. " scrolls" ..
		"|Current Research Progress: " .. tostring(tribe.researchProgress) .. " scrolls" ..
		"|Required for Next Advance: " .. tostring(tribe.researchCost) .. " scrolls"
	uiutil.messageDialog("ARCHBISHOP (Scholarship Advisor)", messageText, 640)
end

local function loadTechParadigm ()
	log.trace()
	if db.gameData.TECH_PARADIGM == nil then
		db.gameData.TECH_PARADIGM = civ.scen.params.techParadigm
		log.update("Documented current tech paradigm of " .. civ.scen.params.techParadigm)
	elseif civ.scen.params.techParadigm ~= db.gameData.TECH_PARADIGM then
		log.action("Changed tech paradigm from " .. civ.scen.params.techParadigm .. " to " .. db.gameData.TECH_PARADIGM)
		civ.scen.params.techParadigm = db.gameData.TECH_PARADIGM
	else
		log.info("Confirmed tech paradigm of " .. civ.scen.params.techParadigm .. " in saved game file")
	end
end

local function setTechParadigm (turn)
	log.trace()
	if db.gameData.TECH_PARADIGM ~= civ.scen.params.techParadigm then
		log.error("Tech paradigm mismatch! db.gameData.TECH_PARADIGM = " .. tostring(db.gameData.TECH_PARADIGM) .. ", civ.scen.params.techParadigm = " .. civ.scen.params.techParadigm)
	end
	if turn > 1 then
		if turn <= constant.mmResearch.MAX_TECH_TURNS_DESIRED then
			local mostTechsKnown = 1	-- Initializing to 1 instead of 0 to avoid a divide by 0 error about 18 lines below
			for tribe in tribeutil.iterateActiveTribes(false) do
				local numTechsKnown = techutil.getNumTechsKnown(tribe)
				-- Exclude "High Middle Ages" tech from the human player's count, it is only ever known by them (assigned in Events.lua)
				if tribe.isHuman and civ.hasTech(tribe, techutil.findByName("High Middle Ages", true)) then
					numTechsKnown = numTechsKnown - 1
				end
				-- Exclude "The Renaissance" (learnable multiple times) from all player's count, since it is not included in the constants related to max techs
				if civ.hasTech(tribe, techutil.findByName("The Renaissance", true)) then
					numTechsKnown = numTechsKnown - 1
				end
				if numTechsKnown > mostTechsKnown then
					mostTechsKnown = numTechsKnown
				end
			end
			local turnsElapsed = turn - 1
			local turnsRemaining = constant.mmResearch.MAX_TECH_TURNS_DESIRED - turnsElapsed
			local portionOfGameElapsed = turnsElapsed / constant.mmResearch.MAX_TECH_TURNS_DESIRED
			-- In the second part of the game, the tech paradigm range is essentially unconstrained
			local minParadigmAllowed = 5
			local maxParadigmAllowed = 99
			local elapsedTurnsMin = 1
			-- But in the first part of the game, it will bounded by the percentage of the game that has elapsed, to avoid wild swings in the early going
			if civ.getGameYear() < constant.mmResearch.CONSTRAIN_TECH_PARADIGM_UNTIL_YEAR then
				minParadigmAllowed = math.max(round((1 - portionOfGameElapsed) * constant.mmResearch.INITIAL_TECH_PARADIGM), 1)
				maxParadigmAllowed = math.max(round(portionOfGameElapsed * 100), constant.mmResearch.INITIAL_TECH_PARADIGM)
				elapsedTurnsMin = constant.mmResearch.PARADIGM_REVERSE_ELAPSED_TURNS_MIN
			end
			local historicalTurnsPerTech = turnsElapsed / mostTechsKnown
			local desiredTurnsPerTechFuture = constant.mmResearch.MAX_TECH_TURNS_DESIRED / constant.mmResearch.MAX_TECHS_DESIRED
			if mostTechsKnown < constant.mmResearch.MAX_TECHS_DESIRED then
				-- In other words, once any tribe has finished all pre-1500 techs, the rate will revert to a goal of the full-game average.
				-- This still permits some changes to occur, however, since the calculated rate depends on the historical rate as well, and this is continually recalculated
				desiredTurnsPerTechFuture = turnsRemaining / (constant.mmResearch.MAX_TECHS_DESIRED - mostTechsKnown)
			end
			local desiredCostFactor = (desiredTurnsPerTechFuture - historicalTurnsPerTech) / historicalTurnsPerTech
			local desiredTechParadigm = math.ceil((desiredCostFactor * constant.mmResearch.INITIAL_TECH_PARADIGM) + constant.mmResearch.INITIAL_TECH_PARADIGM)
			local allowedTechParadigm = math.min(math.max(desiredTechParadigm, minParadigmAllowed), maxParadigmAllowed)

			log.info("  turn = " .. turn)
			log.info("  maxTurns = " .. civ.scen.params.maxTurns)
			log.info("  MAX_TECH_TURNS_DESIRED = " .. constant.mmResearch.MAX_TECH_TURNS_DESIRED)
			log.info("  portionOfGameElapsed = " .. string.format("%.3f", portionOfGameElapsed))
			log.info("  allowedParadigmRange = " .. minParadigmAllowed .. " to " .. maxParadigmAllowed)
			log.info("  mostTechsKnown = " .. mostTechsKnown)
			log.info("  historicalTurnsPerTech = " .. string.format("%.3f", historicalTurnsPerTech))
			log.info("  desiredTurnsPerTechFuture = " .. string.format("%.3f", desiredTurnsPerTechFuture))
			log.info("  desiredCostFactor = " .. string.format("%.3f", desiredCostFactor))
			log.info("  desiredTechParadigm = " .. desiredTechParadigm)
			log.info("  allowedTechParadigm = " .. allowedTechParadigm)
			log.info("  lastDecreaseTurn = " .. db.gameData.TECH_PARADIGM_LAST_DECREASE_TURN)
			log.info("  lastIncreaseTurn = " .. db.gameData.TECH_PARADIGM_LAST_INCREASE_TURN)

			if allowedTechParadigm ~= civ.scen.params.techParadigm then
				local sufficientTimeElapsed = false
				local messageHeader, messageText = ""
				if allowedTechParadigm > civ.scen.params.techParadigm then
					if turn >= (db.gameData.TECH_PARADIGM_LAST_DECREASE_TURN + elapsedTurnsMin) then
						sufficientTimeElapsed = true
						db.gameData.TECH_PARADIGM_LAST_INCREASE_TURN = turn
						messageHeader = "Technology Progressing More Slowly"
						messageText = "Despite long hours of study, scholars throughout Europe are finding it more difficult than they anticipated to identify new ideas or useful inventions.||Time required for research increases to "
					end
				else
					if turn >= (db.gameData.TECH_PARADIGM_LAST_INCREASE_TURN + elapsedTurnsMin) then
						sufficientTimeElapsed = true
						db.gameData.TECH_PARADIGM_LAST_DECREASE_TURN = turn
						messageHeader = "Technology Progressing More Rapidly"
						messageText = "The great thinkers of this age are a blessing to us all, sire! Scholars across Europe are identifying new ideas and useful inventions more rapidly than in previous years.||Time required for research decreases to "
					end
				end
				if sufficientTimeElapsed == true then
					local newParadigmPct = round((allowedTechParadigm / constant.mmResearch.BASE_TECH_PARADIGM) * 100)
					if civ.getGameYear() <= constant.mmResearch.CONSTRAIN_TECH_PARADIGM_UNTIL_YEAR then
						uiutil.messageDialog(messageHeader, messageText .. newParadigmPct .. "% of normal.", 475)
					end
					log.action("Changed tech paradigm from " .. civ.scen.params.techParadigm .. " to " .. allowedTechParadigm)
					civ.scen.params.techParadigm = allowedTechParadigm
					db.gameData.TECH_PARADIGM = allowedTechParadigm
				end
			end
		else
			-- Once MAX_TECH_TURNS_DESIRED is reached, the tech paradigm for the remainder of the game (including beyond turn 500, if you choose to keep playing) will be set to the base value
			if civ.scen.params.techParadigm ~= constant.mmResearch.BASE_TECH_PARADIGM then
				if civ.scen.params.techParadigm > constant.mmResearch.BASE_TECH_PARADIGM then
					db.gameData.TECH_PARADIGM_LAST_INCREASE_TURN = turn
				else
					db.gameData.TECH_PARADIGM_LAST_DECREASE_TURN = turn
				end
				civ.scen.params.techParadigm = constant.mmResearch.BASE_TECH_PARADIGM
				db.gameData.TECH_PARADIGM = constant.mmResearch.BASE_TECH_PARADIGM
			end
		end
	else
		log.info("No tech paradigm adjustment permitted on turn " .. turn)
	end
	log.info("  civ.scen.params.techParadigm = " .. civ.scen.params.techParadigm)
end

local function unlockTechGroups (tribe)
	log.trace()

	-- Groups 0 through 3: Dark, Early, High, Late
	local totalTechs = { [MMTECHGROUP.Dark] = 0, [MMTECHGROUP.Early] = 0, [MMTECHGROUP.High] = 0, [MMTECHGROUP.Late] = 0 }
	local knownTechs = { [MMTECHGROUP.Dark] = 0, [MMTECHGROUP.Early] = 0, [MMTECHGROUP.High] = 0, [MMTECHGROUP.Late] = 0 }
	for tech in techutil.iterateTechs() do
		if tech.group <= MMTECHGROUP.Late and tech.name ~= "High Middle Ages" then
			totalTechs[tech.group] = totalTechs[tech.group] + 1
			if civ.hasTech(tribe, tech) == true then
				knownTechs[tech.group] = knownTechs[tech.group] + 1
			end
		end
	end
	for techGroup = MMTECHGROUP.Dark, MMTECHGROUP.Late do
		local pctKnown = round((knownTechs[techGroup] / totalTechs[techGroup]) * 100)
		log.info("Tech Group '" .. MMTECHGROUP[techGroup] .. "' has " .. totalTechs[techGroup] .. " techs, " .. knownTechs[techGroup] .. " known (" .. pctKnown .. "%)")
		if techGroup <= MMTECHGROUP.High then
			local tribeDesc = " (Tribal) "
			local requiredPct = constant.mmResearch.TECH_GROUP_TRIBAL_THRESHOLD_PERCENT[techGroup + 1]
			if civ.hasTech(tribe, techutil.findByName("Catholic Christianity", true)) then
				tribeDesc = " (Christian) "
				requiredPct = constant.mmResearch.TECH_GROUP_CHRISTIAN_THRESHOLD_PERCENT[techGroup + 1]
			end
			if pctKnown >= requiredPct then
				log.info(tribe.name .. tribeDesc .. "reached " .. requiredPct .. "% of Tech Group " .. techGroup)
				tribeutil.setTechGroupAccess(tribe, techGroup + 1, 0)
			end
		end
	end

	-- Group 4: Ships
	if techutil.knownByTribe(tribe, techutil.findByName("Portolan Charts", true)) == true then
		log.info("Allowing full access to Carvel/Clinker Shipbuilding...")
		tribeutil.setTechGroupAccess(tribe, MMTECHGROUP.Ships, 0)
	elseif techutil.knownByTribe(tribe, techutil.findByName("Carvel Shipbuilding", true)) == true or
		   techutil.knownByTribe(tribe, techutil.findByName("Clinker Shipbuilding", true)) == true or
		   tribe.researching == techutil.findByName("Carvel Shipbuilding", true) or
		   tribe.researching == techutil.findByName("Clinker Shipbuilding", true)
	then
		log.info("Blocking research of Carvel/Clinker Shipbuilding...")
		tribeutil.setTechGroupAccess(tribe, MMTECHGROUP.Ships, 1)
	else
		log.info("Allowing full access to Carvel/Clinker Shipbuilding...")
		tribeutil.setTechGroupAccess(tribe, MMTECHGROUP.Ships, 0)
	end

	-- Group 5 (Feudalism) is unlocked in the mmGovernments module at the time a nation accepts Christianity

	-- Group 6 remains at 1 the entire game, and group 7 remains at 2 the entire game

	-- Unique case: Constitutional Monarchy
	-- Instead of changing each tribe's ability for a group containing this tech (and nothing else), we will conditionally move the tech to a different group
	--		This affects its availability to all tribes at once, instead of each tribe at different points
	-- This is handled in assignConstitutionalMonarchyTechGroup()
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 12

return {
	confirmLoad = confirmLoad,

	assignConstitutionalMonarchyTechGroup = assignConstitutionalMonarchyTechGroup,
	boostResearchProgress = boostResearchProgress,
	displayInitialResearchMessages = displayInitialResearchMessages,
	displayResearchRateDetails = displayResearchRateDetails,
	loadTechParadigm = loadTechParadigm,
	setTechParadigm = setTechParadigm,
	unlockTechGroups = unlockTechGroups,
}
