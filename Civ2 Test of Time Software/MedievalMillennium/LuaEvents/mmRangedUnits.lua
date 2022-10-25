-- mmRangedUnits.lua
-- by Knighttime

log.trace()

constant.mmRangedUnits = { }

constant.mmRangedUnits.CAPTURED_ARTILLERY_ADDTL_DAMAGE_PCT = 50		-- Percent of *base* HP that are applied as damage to a captured unit when it is recreated for its new owner. This is
																	--		*in addition* to damage it had at the beginning of the battle. If the cumulative damage is enough to destroy
																	--		the unit, then the capture fails.
constant.mmRangedUnits.CAPTURED_ARTILLERY_HUMAN_PLAYER_PCT = 67		-- Percent chance that the human player is able to capture an artillery unit, if all other criteria are met.
																	--		The AI has a 100% chance of capturing artillery defeated in battle.
constant.mmRangedUnits.FIRING_UNIT_VETERANCY_PCT = 16				-- Percent chance that a projectile which *wins* its combat will result in the firing ranged unit becoming a veteran (one-sixth, about)
constant.mmRangedUnits.FIRING_UNIT_WHITE_TOWER_VETERANCY_PCT = 33	-- Percent chance that a projectile which *wins* its combat will result in the firing ranged unit becoming a veteran,
																	--		if the ranged unit's owner controls the White Tower wonder (one-third, about)
constant.mmRangedUnits.GUNPOWDER_ARTILLERY_FIRING_DAMAGE_HP = 1		-- Number of HP damage that every gunpowder artillery weapon (isHandheld = false, isGunpowder = true) receives each time it fires
constant.mmRangedUnits.ARTILLERY_DAMAGE_PCT_MAX = 50				-- A non-handheld artillery projectile is not allowed to kill an enemy unit outright; at most, it can reduce the HP of the defending
																	--		unit by this percent. Rounding favors the defender though, i.e., we actually calculate and round the defender HP
																	--		that must *remain*, not the damage that can be *taken*.
constant.mmRangedUnits.LOSING_PROJECTILE_IMPACT_PCT = 33.33			-- PROJECTILE_DATA_TABLE contains the chances that a projectile which *wins* its combat (that is, inflicts the max possible damage)
																	--		will result in the destruction of various city improvements. If the projectile *loses*, that chance is multiplied by this
																	--		percentage (e.g., 50 = half as likely, 33.33 = one-third as likely)

db.projectileSources = { }
db.projectileSummary = { }
db.rangedUnitsFired = { }

local RANGED_UNIT_DATA_TABLE = {
	[MMUNIT.ArcherAI.id]			= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.BroadheadArrows,	maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0.5
	[MMUNIT.Archer.id]				= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.BroadheadArrows,	maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0.5
	[MMUNIT.CrossbowmanAI.id]		= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.Bolts,				maxQuantityFired = 1,	moveCostPerProj = 2.0 },	-- moveAfterAllFire = 0
	[MMUNIT.Crossbowman.id]			= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.Bolts,				maxQuantityFired = 1,	moveCostPerProj = 2.0 },	-- moveAfterAllFire = 0
	[MMUNIT.LongbowmanAI.id]		= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.BodkinArrows,		maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0.5
	[MMUNIT.Longbowman.id]			= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.BodkinArrows,		maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0.5
	[MMUNIT.BowmanAI.id]			= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.BodkinArrows,		maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0.5
	[MMUNIT.Bowman.id]				= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.BodkinArrows,		maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0.5
	[MMUNIT.MongolCavalry.id]		= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.BodkinArrows,		maxQuantityFired = 1,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 3.0
	[MMUNIT.ArbalestierAI.id]		= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.Quarrels,			maxQuantityFired = 1,	moveCostPerProj = 2.0 },	-- moveAfterAllFire = 0
	[MMUNIT.Arbalestier.id]			= { isHandheld = true,		isGunpowder = false,	projectileType = MMUNIT.Quarrels,			maxQuantityFired = 1,	moveCostPerProj = 2.0 },	-- moveAfterAllFire = 0

	[MMUNIT.Springald.id]			= { isHandheld = false,		isGunpowder = false,	projectileType = MMUNIT.ArtillArrow,		maxQuantityFired = 1,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 0
	[MMUNIT.TorsionCatapult.id]		= { isHandheld = false,		isGunpowder = false,	projectileType = MMUNIT.Rock,				maxQuantityFired = 1,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 0
	[MMUNIT.Mangonel.id]			= { isHandheld = false,		isGunpowder = false,	projectileType = MMUNIT.Rock,				maxQuantityFired = 1,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 0
	[MMUNIT.Couillard.id]			= { isHandheld = false,		isGunpowder = false,	projectileType = MMUNIT.Rock,				maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0
	[MMUNIT.Trebuchet.id]			= { isHandheld = false,		isGunpowder = false,	projectileType = MMUNIT.Boulder,			maxQuantityFired = 1,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 0

	[MMUNIT.HandCannoneer.id]		= { isHandheld = true,		isGunpowder = true,		projectileType = MMUNIT.Pebbles,			maxQuantityFired = 1,	moveCostPerProj = 2.0 },	-- moveAfterAllFire = 0
	[MMUNIT.HandCulveriner.id]		= { isHandheld = true,		isGunpowder = true,		projectileType = MMUNIT.Pellets,			maxQuantityFired = 1,	moveCostPerProj = 2.0 },	-- moveAfterAllFire = 0
	[MMUNIT.TurkishJanissary.id]	= { isHandheld = true,		isGunpowder = true,		projectileType = MMUNIT.Pellets,			maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0.5
	[MMUNIT.Cuirassier.id]			= { isHandheld = true,		isGunpowder = true,		projectileType = MMUNIT.Pellets,			maxQuantityFired = 2,	moveCostPerProj = 1.167 },	-- moveAfterAllFire = 0.666
	[MMUNIT.Arquebusier.id]			= { isHandheld = true,		isGunpowder = true,		projectileType = MMUNIT.Bullets,			maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0.5
	[MMUNIT.Musketeer.id]			= { isHandheld = true,		isGunpowder = true,		projectileType = MMUNIT.Bullets,			maxQuantityFired = 2,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 0

	[MMUNIT.Ribauldequin.id]		= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.Stones,				maxQuantityFired = 2,	moveCostPerProj = 0.5 },	-- moveAfterAllFire = 0
	-- Ribauldequin is a odd one because it's an artillery unit whose projectile is a land unit (all other artillery projectiles are air units) that can only ever move 1 tile, and doesn't ignore City Walls
	[MMUNIT.Potdefer.id]			= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.Garrot,				maxQuantityFired = 1,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 0
	[MMUNIT.Fowler.id]				= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.SmStoneBall,		maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0
	[MMUNIT.Bombard.id]				= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.MedStoneBall,		maxQuantityFired = 1,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 0
	[MMUNIT.Basilisk.id]			= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.LgStoneBall,		maxQuantityFired = 1,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 0
	[MMUNIT.Serpentine.id]			= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.SmIronBall,			maxQuantityFired = 1,	moveCostPerProj = 2.0 },	-- moveAfterAllFire = 0
	[MMUNIT.Falconet.id]			= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.SmIronBall,			maxQuantityFired = 1,	moveCostPerProj = 2.0 },	-- moveAfterAllFire = 1.0
	[MMUNIT.Demiculverin.id]		= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.MedIronBall,		maxQuantityFired = 1,	moveCostPerProj = 1.5 },	-- moveAfterAllFire = 0
	[MMUNIT.Saker.id]				= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.MedIronBall,		maxQuantityFired = 1,	moveCostPerProj = 1.834 },	-- moveAfterAllFire = 0.666
	[MMUNIT.Culverin.id]			= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.LgIronBall,			maxQuantityFired = 1,	moveCostPerProj = 1.0 },	-- moveAfterAllFire = 0
	[MMUNIT.FieldCulverin.id]		= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.LgIronBall,			maxQuantityFired = 1,	moveCostPerProj = 1.667 },	-- moveAfterAllFire = 0.333
	[MMUNIT.ArmedCarrack.id]		= { isHandheld = false,		isGunpowder = true,		projectileType = MMUNIT.MedIronBall,		maxQuantityFired = 1,	moveCostPerProj = 2.0 },	-- moveAfterAllFire = 5.0
}
local PROJECTILE_DATA_TABLE = {
	[MMUNIT.BroadheadArrows.id]		= { cost = 0,	pctChanceCityWallsOrCastleDestroyed =  0,		pctChanceImprovementDestroyedIfWallsAreNot =  0 },
	[MMUNIT.BodkinArrows.id]		= { cost = 1, 	pctChanceCityWallsOrCastleDestroyed =  0,		pctChanceImprovementDestroyedIfWallsAreNot =  0 },
	[MMUNIT.Bolts.id]				= { cost = 1, 	pctChanceCityWallsOrCastleDestroyed =  0,		pctChanceImprovementDestroyedIfWallsAreNot =  0 },
	[MMUNIT.Quarrels.id]			= { cost = 1, 	pctChanceCityWallsOrCastleDestroyed =  0,		pctChanceImprovementDestroyedIfWallsAreNot =  0 },

	[MMUNIT.ArtillArrow.id]			= { cost = 2, 	pctChanceCityWallsOrCastleDestroyed =  0.00,	pctChanceImprovementDestroyedIfWallsAreNot =  2.00 },	-- 98.0% unscathed
	[MMUNIT.Rock.id]				= { cost = 0,	pctChanceCityWallsOrCastleDestroyed =  6.25,	pctChanceImprovementDestroyedIfWallsAreNot =  2.22 },	-- 91.7% unscathed
	[MMUNIT.Boulder.id]				= { cost = 1, 	pctChanceCityWallsOrCastleDestroyed =  8.33,	pctChanceImprovementDestroyedIfWallsAreNot =  3.03 },	-- 88.9% unscathed

	[MMUNIT.Pebbles.id]				= { cost = 1, 	pctChanceCityWallsOrCastleDestroyed =  0,		pctChanceImprovementDestroyedIfWallsAreNot =  0 },
	[MMUNIT.Pellets.id]				= { cost = 1, 	pctChanceCityWallsOrCastleDestroyed =  0,		pctChanceImprovementDestroyedIfWallsAreNot =  0 },
	[MMUNIT.Bullets.id]				= { cost = 1, 	pctChanceCityWallsOrCastleDestroyed =  0,		pctChanceImprovementDestroyedIfWallsAreNot =  0 },

	[MMUNIT.Stones.id]				= { cost = 1,	pctChanceCityWallsOrCastleDestroyed =  0,		pctChanceImprovementDestroyedIfWallsAreNot =  0 },
	[MMUNIT.Garrot.id]				= { cost = 2, 	pctChanceCityWallsOrCastleDestroyed =  0.00,	pctChanceImprovementDestroyedIfWallsAreNot =  2.00 },	-- 98.0% unscathed
	[MMUNIT.SmStoneBall.id]			= { cost = 2, 	pctChanceCityWallsOrCastleDestroyed =  6.25,	pctChanceImprovementDestroyedIfWallsAreNot =  2.22 },	-- 91.7% unscathed
	[MMUNIT.MedStoneBall.id]		= { cost = 4, 	pctChanceCityWallsOrCastleDestroyed =  8.33,	pctChanceImprovementDestroyedIfWallsAreNot =  3.03 },	-- 88.9% unscathed
	[MMUNIT.LgStoneBall.id]			= { cost = 6, 	pctChanceCityWallsOrCastleDestroyed = 12.50,	pctChanceImprovementDestroyedIfWallsAreNot =  4.76 },	-- 83.3% unscathed
	[MMUNIT.SmIronBall.id]			= { cost = 1, 	pctChanceCityWallsOrCastleDestroyed =  8.33,	pctChanceImprovementDestroyedIfWallsAreNot =  3.03 },	-- 88.9% unscathed
	[MMUNIT.MedIronBall.id]			= { cost = 3, 	pctChanceCityWallsOrCastleDestroyed = 11.11,	pctChanceImprovementDestroyedIfWallsAreNot =  4.17 },	-- 85.2% unscathed
	[MMUNIT.LgIronBall.id]			= { cost = 5, 	pctChanceCityWallsOrCastleDestroyed = 16.67,	pctChanceImprovementDestroyedIfWallsAreNot =  6.66},	-- 77.8% unscathed
}

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
for key, data in pairs(RANGED_UNIT_DATA_TABLE) do
	if key == nil then
		log.error("ERROR! For RANGED_UNIT_DATA_TABLE, found a row where key (ranged unit type) is nil")
	end
	if data.projectileType == nil then
		log.error("ERROR! For RANGED_UNIT_DATA_TABLE row " .. key .. ", projectileType is nil")
	end
end
for key, data in pairs(PROJECTILE_DATA_TABLE) do
	if key == nil then
		log.error("ERROR! For PROJECTILE_DATA_TABLE, found a row where key (projectile unit type) is nil")
	end
end
log.update("Synchronized Medieval Millennium ranged units and projectiles")
local function confirmLoad ()
	log.trace()
	log.info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " loaded successfully")
	log.info("")
end

-- ===========================================================
-- ••••••••••••••• STRICTLY INTERNAL FUNCTIONS •••••••••••••••
-- ===========================================================
local function appendValidTargetsOnTile (projectileTribe, isHandheld, projectileType, consideringTile, consideringTileDistance, requireStationaryTarget, validTargets)
	log.trace()
	for potentialTarget in consideringTile.units do

		-- 1. Tribe check: target must belong to a tribe you can attack. This means:
			-- 1a. Target tribe must be different than projectile tribe, and:
		if potentialTarget.owner ~= projectileTribe and (
			-- 1b. Both target and projectile belong to non-barbarian tribes which are at war with each other; or
			(tribeutil.isBarbarian(projectileTribe) == false and tribeutil.isBarbarian(potentialTarget.owner) == false and tribeutil.haveWar(projectileTribe, potentialTarget.owner) == true) or
			-- 1c. Target belongs to barbarians, who are always at war with everyone, AND is on a land tile; or

			(tribeutil.isBarbarian(potentialTarget.owner) == true and tileutil.isLandTile(consideringTile) == true) or
			-- 1d. Projectile belongs to barbarians, who are always at war with everyone, AND target is on a land tile
			--	   (Barbarians do not seem willing to attack a target on a sea tile, even with a projectile capable of doing so -- that is, an air-based one)
			(tribeutil.isBarbarian(projectileTribe) == true and tileutil.isLandTile(consideringTile) == true)
		) then
			-- 2. Domain check: land targets must be on a land tile; naval targets can only be attacked if the projectile is air-based.
			if (potentialTarget.type.domain == domain.Land and tileutil.isLandTile(consideringTile) == true) or
			   (potentialTarget.type.domain == domain.Sea and projectileType.domain == domain.Air) then
				-- 3. Specialist check: target must not be a city specialist (note that only the human tribe has city specialists visible on the map as units).
				if isCitySpecialistUnitType(potentialTarget.type) == false then
					-- 4. Damageable check: target must be able to take damage, i.e., projectile must be handheld or the target must have > 1 HP

					if isHandheld == true or potentialTarget.hitpoints > 1 then
						-- 5. Mobility check: If target must be "stationary", only certain tile or unit attributes qualify:

						if requireStationaryTarget == false or
						   consideringTile.city ~= nil or
						   tileutil.getTerrainId(consideringTile) == MMTERRAIN.Monastery or
						   hasCastle(consideringTile) == true or
						   (RANGED_UNIT_DATA_TABLE[potentialTarget.type.id] ~= nil and RANGED_UNIT_DATA_TABLE[potentialTarget.type.id].isHandheld == false) or
						   potentialTarget.type == MMUNIT.SiegeTower or
						   potentialTarget.type.domain == domain.Sea
						then
							-- 6. Handheld vs. artillery check: handheld ranged units will not fire at artillery ranged units, for several reasons:
							--	  a. In real life, the small projectiles of the handheld unit are unlikely to cause serious damage
							--	  b. In the game, a successful projectile attack would kill (destroy) the target. But the ranged unit would prefer to capture an unprotected artillery unit instead.
							--	  c. By not firing, the handheld ranged unit has the option of making a direct attack, thereby capturing the unprotected artillery unit (if the attack is successful
							--		 and the artillery unit is not in a city)
							-- Note that an artillery ranged unit *will* fire at another artillery ranged unit, regardless of whether or not it is in a city, since none of those three points apply.
							if isHandheld == false or
							   RANGED_UNIT_DATA_TABLE[potentialTarget.type.id] == nil or
							   RANGED_UNIT_DATA_TABLE[potentialTarget.type.id].isHandheld == true then
								log.info("Detected " .. potentialTarget.owner.adjective .. " " .. potentialTarget.type.name .. " (ID " .. potentialTarget.id .. ") at " .. consideringTile.x .. "," .. consideringTile.y)
								table.insert(validTargets, {target = potentialTarget, distance = consideringTileDistance})
							end -- 6.
						end -- 5.
					end -- 4.
				end -- 3.
			end -- 2.
		end -- 1.

	end -- for potentialTarget in consideringTile.units
end

local function getRangedUnit (projectile)
	log.trace()
	local rangedUnit = nil
	if db.projectileSources[projectile.id] ~= nil then
		local rangedUnitId = db.projectileSources[projectile.id]["sourceUnitId"]
		local rangedUnitTypeId = db.projectileSources[projectile.id]["sourceUnitTypeId"]
		if rangedUnitId ~= nil then
			rangedUnit = civ.getUnit(rangedUnitId)
			if rangedUnit ~= nil then
				if rangedUnit.type.id ~= rangedUnitTypeId or rangedUnit.owner ~= projectile.owner then
					log.warning("WARNING: Found unit with ID " .. rangedUnit.id .. ", but it was a " .. rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " instead of a " .. projectile.owner.adjective .. " " .. civ.getUnitType(rangedUnitTypeId).name .. ".")
					rangedUnit = nil
				end
			end
		end
	end
	return rangedUnit
end

local function getValidProjectileTargets (rangedUnit, sourceTile, isHandheld, projectileType, projectileRange)
	log.trace()
	local tilesEncountered = { }
	local tileId = tileutil.getTileId(sourceTile)
	tilesEncountered[tileId] = 0
	local tilesNotYetConsidered = { }
	table.insert(tilesNotYetConsidered, { tile = sourceTile, path = { } })
	local validTargets = { }

	while #tilesNotYetConsidered > 0 do
		local consideringTile = tilesNotYetConsidered[1]["tile"]
		local consideringTilePath = {table.unpack(tilesNotYetConsidered[1]["path"])}
		local consideringTileDistance = #consideringTilePath
		table.insert(consideringTilePath, consideringTile)
		table.remove(tilesNotYetConsidered, 1)
		local requireStationaryTarget = false
		if rangedUnit.type.move > 0 and projectileRange > 1 and consideringTileDistance == projectileRange then
			requireStationaryTarget = true
		end
		appendValidTargetsOnTile(rangedUnit.owner, isHandheld, projectileType, consideringTile, consideringTileDistance, requireStationaryTarget, validTargets)
		if projectileRange > consideringTileDistance and
		   ( (rangedUnit.type.domain == domain.Land and tileutil.isLandTile(consideringTile) == true) or
			 (rangedUnit.type.domain == domain.Sea and tileutil.isWaterTile(consideringTile) == true) or

			 (rangedUnit.type.domain == domain.Land and tileutil.isWaterTile(consideringTile) == true and consideringTileDistance == 0)
		   ) then
			for _, adjTile in ipairs(tileutil.getAdjacentTiles(consideringTile, false)) do
				if civ.isTile(adjTile) and tileutil.getTerrainId(adjTile) ~= MMTERRAIN.Mountains then
					tileId = tileutil.getTileId(adjTile)
					if tilesEncountered[tileId] == nil or tilesEncountered[tileId] > (consideringTileDistance + 1) then
						tilesEncountered[tileId] = consideringTileDistance + 1
						table.insert(tilesNotYetConsidered, { tile = adjTile, path = consideringTilePath })
					end
				end
			end
		end
	end

	return validTargets
end

local function getProjectileCost (unittype, tribe)
	log.trace()
	local projectileCost = 0
	if tribe.id > 0 and PROJECTILE_DATA_TABLE[unittype.id] ~= nil then
		projectileCost = adjustForDifficulty(PROJECTILE_DATA_TABLE[unittype.id].cost, tribe, false)
	end
	return projectileCost
end

local function reduceProjectileOffense (projectile, projectileSourceData)
	log.trace()
	local projAttack = MM_BASE_UNIT_STATS[projectile.type.id].baseAttack
	local projFirepower = MM_BASE_UNIT_STATS[projectile.type.id].baseFirepower

	-- 'percentOfBase' reduction is due to the ranged unit having reduced HP or MP
	-- Handheld units use math.min() to apply smallest percent of base (that is, the greater reduction), instead of applying both reductions. This is because a unit
	--		that has taken damage may *also* suffer from reduced MP, which would compound the effect to a greater degree than desired.
	-- Artillery units are only subject to a reduction due to reduced MP, not due to reduced HP
	local percentOfBase = 100
	if RANGED_UNIT_DATA_TABLE[projectileSourceData.sourceUnitTypeId].isHandheld == true then
		percentOfBase = math.min(projectileSourceData.sourceMovementPercent, projectileSourceData.sourceDamagePercent)
	else
		percentOfBase = projectileSourceData.sourceMovementPercent
	end
	if percentOfBase < 100 then
		local desiredOffense = round((projAttack + projFirepower) * percentOfBase / 100)
		log.info("Attempting to reduce offense of " .. projectile.type.name .. " to " .. percentOfBase .. "% of base (from " .. (projAttack + projFirepower) .. " to " .. desiredOffense .. ")")
		while (projAttack + projFirepower) > desiredOffense do
			if projFirepower > 1 then
				projFirepower = projFirepower - 1
			elseif projAttack > 1 then
				projAttack = projAttack - 1
			else
				break	-- both Attack and Firepower have been reduced to 1; the unit's offense is as minimal as possible (while still being able to attack)
			end
		end
	end

	-- Save changes
	projectile.type.attack = MM_BASE_UNIT_STATS[projectile.type.id].baseAttack
	if projAttack ~= projectile.type.attack then
		log.action("Reduced " .. projectile.type.name .. " attack from " .. projectile.type.attack .. " to " .. projAttack)
		projectile.type.attack = projAttack
	end
	projectile.type.firepower = MM_BASE_UNIT_STATS[projectile.type.id].baseFirepower
	if projFirepower ~= projectile.type.firepower then
		log.action("Reduced " .. projectile.type.name .. " firepower from " .. projectile.type.firepower .. " to " .. projFirepower)
		projectile.type.firepower = projFirepower
	end
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
-- Deliberately returns nil if the unit is not in the ranged table at all, meaning that it cannot determine whether or not it is human
local function isHumanRangedUnitType (unittype)
	log.trace()
	local isHumanRanged = nil
	if RANGED_UNIT_DATA_TABLE[unittype.id] ~= nil then
		isHumanRanged = RANGED_UNIT_DATA_TABLE[unittype.id].isHandheld
	elseif PROJECTILE_DATA_TABLE[unittype.id] ~= nil then
		isHumanRanged = false
	end
	return isHumanRanged
end

-- This is also called internally by cityTakenByProjectile(), destroyAllProjectiles(), fireOrMove(), firingUnitBecomesVeteran(), and getDefenderHpThreshold(), and must be defined prior to them in this file:
local function isProjectileUnitType (unittype)
	log.trace()
	local isProjectile = false
	if PROJECTILE_DATA_TABLE[unittype.id] ~= nil then
		isProjectile = true
	end
	return isProjectile
end

-- Since all ranged units must be in the table, returns either true or false but never nil (see isHumanRangedUnitType for comparison)
local function isRangedUnitType (unittype)
	log.trace()
	local isRanged = false
	if RANGED_UNIT_DATA_TABLE[unittype.id] ~= nil then
		isRanged = true
	end
	return isRanged
end

-- This is also called internally by cityTakenByProjectile(), destroyAllProjectiles(), and fireOrMove(), and must be defined prior to them in this file:
local function resetAllUnitStats (calledBy, expectToFind)

	log.trace()
	for unittype in unitutil.iterateUnitTypes() do
		if calledBy ~= "events.onCanBuild" then
			if unittype.attack ~= MM_BASE_UNIT_STATS[unittype.id].baseAttack then
				log.action("Reset attack of " .. unittype.name .. " from " .. unittype.attack .. " to " .. MM_BASE_UNIT_STATS[unittype.id].baseAttack .. " (called by " .. calledBy .. ")")
				unittype.attack = MM_BASE_UNIT_STATS[unittype.id].baseAttack

			end
			if unittype.firepower ~= MM_BASE_UNIT_STATS[unittype.id].baseFirepower then
				log.action("Reset firepower of " .. unittype.name .. " from " .. unittype.firepower .. " to " .. MM_BASE_UNIT_STATS[unittype.id].baseFirepower .. " (called by " .. calledBy .. ")")
				unittype.firepower = MM_BASE_UNIT_STATS[unittype.id].baseFirepower

			end
		end
	end
end

-- Code here is quite similar to mmUnits.captureNavalUnit(), but the formulas are somewhat different
local function captureArtilleryUnit (winningUnit, losingUnit, attackerTile, battleTile)
	log.trace()
	local rangedDataEntry = RANGED_UNIT_DATA_TABLE[losingUnit.type.id]
	local captureOccurred = false
	if rangedDataEntry ~= nil and rangedDataEntry.isHandheld == false and
	   losingUnit.type.domain == domain.Land and
	   unitutil.wasAttacker(losingUnit) == false and
	   isHumanUnitType(winningUnit.type) == true and
	   tileutil.isLandTile(attackerTile) then
		log.info("Losing unit was defender (" .. losingUnit.type.name .. ") and winning unit was attacker (" .. winningUnit.type.name .. ")")
		if unitutil.tileContainsOtherUnit(battleTile, losingUnit) then
			log.info("Found additional defender(s) for " .. losingUnit.type.name .. ", no capture")
		elseif battleTile.city ~= nil and battleTile.city.owner ~= winningUnit.owner then
			log.info(losingUnit.type.name .. " was in another tribe's city, no capture")
		else
			-- defenderDamage is a global variable populated in onResolveCombat(), and we've verified that the losing unit was the defender
			local hpRemainingAfterCapture = round(losingUnit.type.hitpoints - defenderDamage -
				(losingUnit.type.hitpoints * (adjustForDifficulty(constant.mmRangedUnits.CAPTURED_ARTILLERY_ADDTL_DAMAGE_PCT, winningUnit.owner, false) / 100)))
			if hpRemainingAfterCapture >= 1 then
				local captureProceeds = false
				if winningUnit.owner.isHuman == false then
					captureProceeds = true
				else
					local randomNumber = math.random(100)
					log.info("Human player chance to capture artillery = " .. constant.mmRangedUnits.CAPTURED_ARTILLERY_HUMAN_PLAYER_PCT .. ", randomNumber = " .. randomNumber)
					if randomNumber <= constant.mmRangedUnits.CAPTURED_ARTILLERY_HUMAN_PLAYER_PCT then
						captureProceeds = true
					end
				end
				if captureProceeds == true then
					log.info("No remaining defenders found for " .. losingUnit.type.name .. ", initiating capture")

					local capturedUnit = unitutil.createByType(losingUnit.type, winningUnit.owner, winningUnit.location)
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
						capturedUnit.damage = capturedUnit.type.hitpoints - hpRemainingAfterCapture
						log.action("  Set HP of " .. capturedUnit.owner.adjective .. " " .. capturedUnit.type.name .. " to " .. capturedUnit.hitpoints)
						-- Note: If the captured unit can move, but not fire, the AI just attacks with it as if it weren't ranged
						-- Captured unit cannot move this turn:
						capturedUnit.moveSpent = capturedUnit.type.move
						-- Captured unit cannot fire this turn:
						db.rangedUnitsFired[capturedUnit.id] = rangedDataEntry.maxQuantityFired
						log.update("  Set " .. capturedUnit.owner.adjective .. " " .. capturedUnit.type.name .. " as having fired already this turn")
						if capturedUnit.owner.isHuman == true then
							uiutil.messageDialog("Military Commander", "Good news! Our troops at " .. capturedUnit.x .. "," .. capturedUnit.y .. " have captured a " .. losingUnit.owner.adjective .. " " .. capturedUnit.type.name .. "!")
						elseif losingUnit.owner.isHuman == true then
							uiutil.messageDialog("Military Commander", "Oh no! Enemy troops at " .. capturedUnit.x .. "," .. capturedUnit.y .. " have managed to capture our " .. capturedUnit.type.name .. "!")
						end
					end
				end
			else
				log.info("No remaining defenders found for " .. losingUnit.type.name .. ", only " .. (losingUnit.type.hitpoints - defenderDamage) .. " HP at start of battle, capture failed")
			end
		end
	end
	return captureOccurred
end

local function clearHistoryForAllUnits ()
	log.trace()
	db.rangedUnitsFired = { }
	log.update("Cleared db.rangedUnitsFired table")
	db.projectileSources = { }
	log.update("Cleared db.projectileSources table")
end

-- This is also called internally by cityTakenByProjectile() and fireOrMove() and must be defined prior to them in this file:
local function clearFireHistoryForUnit (unit)
	-- If a new unit has the same ID as one that has already fired this turn, then that unit must have been destroyed
	-- 		without that being caught and handled for at the time, and the ID is being re-used.
	-- Remove that entry from the table, so that the new unit hasn't fired.
	log.trace()
	if db.rangedUnitsFired[unit.id] ~= nil then
		log.update("Cleared db.rangedUnitsFired entry for unit ID " .. unit.id .. " (stored value was " .. tostring(db.rangedUnitsFired[unit.id]) .. ")")
		db.rangedUnitsFired[unit.id] = nil
	end
end

local function clearProjectileHistoryForUnit (unit)
	-- If a projectile is involved in a battle, then it does not exist after the battle has concluded
	-- Presumably it was always the attacker, but whether or not it was the winner or loser, it will be destroyed after attacking
	-- So we can safely remove the entry for it from the projectile history table
	log.trace()
	if db.projectileSources[unit.id] ~= nil then
		log.update("Cleared db.projectileSources entry for unit ID " .. unit.id)
		db.projectileSources[unit.id] = nil
	end
end

local function cityTakenByProjectile (city)

	log.trace()
	local conqueringUnit = nil
	for unit in city.location.units do
		conqueringUnit = unit
	end
	if conqueringUnit ~= nil and isProjectileUnitType(conqueringUnit.type) then
		local projectile = conqueringUnit
		log.info("Detected land projectile (" .. projectile.owner.adjective .. " " .. projectile.type.name .. ") which conquered a city (" .. city.name .. ")")
		local rangedUnit = getRangedUnit(projectile)
		if rangedUnit ~= nil then
			unitutil.teleportUnit(rangedUnit, city.location)
		end
		clearProjectileHistoryForUnit(projectile)
		unitutil.deleteUnit(projectile)
		resetAllUnitStats("mmRangedUnits.cityTakenByProjectile", true)
	end
end

local function destroyProjectile (unit)
	log.trace()
	if isProjectileUnitType(unit.type) then
		unitutil.deleteUnit(unit)
	end
end

local function destroyAllProjectiles ()
	log.trace()
	local projectileDeleted = false
	for unit in civ.iterateUnits() do
		if isProjectileUnitType(unit.type) then
			local projectile = unit
			local thisTribeProjSummary = db.projectileSummary[projectile.owner.id] or { }
			messageText = "WARNING: Destroyed abandoned projectile: " .. projectile.owner.adjective .. " " .. projectile.type.name ..
				" (ID " .. projectile.id .. ") at " .. projectile.x .. "," .. projectile.y
			-- If damage was applied to a gunpowder artillery unit when the projectile was fired, reverse this:
			local rangedUnit = getRangedUnit(projectile)
			if rangedUnit ~= nil then
				if RANGED_UNIT_DATA_TABLE[rangedUnit.type.id].isHandheld == false and RANGED_UNIT_DATA_TABLE[rangedUnit.type.id].isGunpowder == true then
					rangedUnit.damage = math.max(rangedUnit.damage - constant.mmRangedUnits.GUNPOWDER_ARTILLERY_FIRING_DAMAGE_HP, 0)
					log.action("Increased HP of " .. rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " (ID " .. rangedUnit.id .. ") from " .. (rangedUnit.hitpoints - constant.mmRangedUnits.GUNPOWDER_ARTILLERY_FIRING_DAMAGE_HP) .. " to " .. rangedUnit.hitpoints)
				end
			end
			-- At this point the projectile history is no longer needed:
			clearProjectileHistoryForUnit(unit)
			resetAllUnitStats("mmRangedUnits.destroyAllProjectiles", true)
			-- If a nation does not attack with a projectile, they will receive a small amount of gold in exchange.
			-- First, both AI and human nations are refunded the firing cost of that projectile:
			local projectileCost = getProjectileCost(unit.type, unit.owner)
			thisTribeProjSummary.numFired = (thisTribeProjSummary.numFired or 0) - 1
			thisTribeProjSummary.fireCost = (thisTribeProjSummary.fireCost or 0) - projectileCost
			-- Secondly, since the ranged unit that fired it was prevented from taking other action such as moving or attacking directly, AI nations will receive payment equal to
			--		an estimate of the value of the projectile, based on the damage it might have done, calculated by adding its attack value and its firepower value.
			--		The human player is not eligible for this type of compensation.
			local projectileRecoveryValue = 0
			if unit.owner.isHuman == false then
				projectileRecoveryValue = unit.type.attack + unit.type.firepower
			end
			thisTribeProjSummary.numRecovered = (thisTribeProjSummary.numRecovered or 0) + 1
			thisTribeProjSummary.recoveryValue = (thisTribeProjSummary.recoveryValue or 0) + projectileRecoveryValue
			db.projectileSummary[unit.owner.id] = thisTribeProjSummary
			if (projectileCost + projectileRecoveryValue) > 0 then
				tribeutil.changeMoney(unit.owner, projectileCost + projectileRecoveryValue)
			end
			unitutil.deleteUnit(unit)
			projectileDeleted = true

			log.action(messageText)
			if constant.events.ADMINISTRATOR_MODE == true then
				uiutil.messageDialog("Administrator Mode Message", messageText .. ".")
			end

		end
	end
end

-- This is also called internally by fireImmobileOrCityUnits() and must be defined prior to it in this file:
local function fireOrMove (unit, activateImmediately)
	log.trace()

	local thisTribeProjSummary = db.projectileSummary[unit.owner.id] or { }
	local eventDescription = "Detected activation of"
	if activateImmediately == false then
		eventDescription = "Processing static"
	end

	resetAllUnitStats("mmRangedUnits.fireOrMove", false)

	local inputUnitContinuesTurn = true

	for rangedUnitTypeId, rangedUnitData in pairs(RANGED_UNIT_DATA_TABLE) do
		if unit.type.id == rangedUnitTypeId then

			-- If this ranged unit has fired and its projectile is still active in the game and has movement points remaining
			--		activate the projectile instead. The ranged unit is not permitted to move, *even if it has movement points
			--		remaining*, until its projectile has ended its turn.
			local activateProjectileInstead = false
			if activateImmediately == true then
				for projectileId, data in pairs(db.projectileSources) do
					if data.sourceUnitId == unit.id and data.sourceUnitTypeId == unit.type.id then
						local projectile = civ.getUnit(projectileId)
						if projectile ~= nil then
							log.info("Found projectile fired by this ranged unit, still present in the game: " .. projectile.type.name .. " (dest " .. projectile.id .. ")")
							if unitutil.canMove(projectile) == true then
								activateProjectileInstead = true
								log.info("Ranged unit is not permitted to move while projectile has movement points remaining")
								unitutil.setToWaiting(unit)
								log.action("Manually activating " .. projectile.owner.adjective .. " " .. projectile.type.name .. " (ID " .. projectile.id .. ") at " .. projectile.x .. "," .. projectile.y)
								inputUnitContinuesTurn = false
								if projectile.owner.isHuman == true then
									civ.ui.centerView(projectile.location)
								end
								projectile:activate()
								onActivateUnitFunction(projectile, true)
							end
						end
					end
				end
			end

			if activateProjectileInstead == false then
				-- If unit is a ranged unit, determine if it should fire or be permitted to move:
				local unitMovesRemaining = unitutil.getMovesRemaining(unit)
				if unitutil.isFortifying(unit) == true then
					activateImmediately = false
				end
				local rangedUnit = unit
				local projectilesFired = db.rangedUnitsFired[rangedUnit.id] or 0
				log.info(eventDescription .. " ranged unit: " .. rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " (ID " .. rangedUnit.id .. ") at " .. rangedUnit.x .. "," .. rangedUnit.y)
				log.info("  with " .. string.format("%.4f", unitMovesRemaining) .. " MP remaining, has fired " .. tostring(projectilesFired) .. " of " .. rangedUnitData.maxQuantityFired .. " projectiles")
				if unitMovesRemaining >= 1 or unitMovesRemaining >= rangedUnitData.moveCostPerProj or unit.moveSpent == 0 then
					if projectilesFired == rangedUnitData.maxQuantityFired then
						log.info(rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " (ID " .. rangedUnit.id .. ") has already fired all possible projectiles this turn")
					else
						local projectileCost = getProjectileCost(rangedUnitData.projectileType, rangedUnit.owner)
						if rangedUnit.owner.money < projectileCost then
							log.info("Ranged unit could not afford to fire: projectile cost = " .. projectileCost .. ", treasury = " .. rangedUnit.owner.money)
							if rangedUnit.owner.isHuman then
								uiutil.messageDialog("Treasurer", "We have to do something immediately to raise funds, Your Majesty! Our military commanders are demanding funds to pay for ammunition, but there is nothing I can do. Our ranged units are currently unsupplied.", 400)
							end
						else
							local projectileRange = unitutil.getMovementPointsAsMoves(rangedUnitData.projectileType.move)
							-- Potentially reduce calculated projectile range:
							while projectileRange > 1 and rangedUnit.moveSpent > 0 and unitMovesRemaining < projectileRange do
								log.info("Projectile range reduced from " .. projectileRange .. " to " .. projectileRange - 1)
								projectileRange = projectileRange - 1
							end
							if rangedUnit.type.domain == domain.Land and tileutil.isWaterTile(rangedUnit.location) == true then
								-- Note: no check exists for this condition when analyzing targets for a projectile that has already been fired; this is only applicable when analyzing a ranged unit
								log.info(rangedUnit.type.name .. " is not permitted to fire from a sea tile, retains movement of " .. unitMovesRemaining)
							else
								local targets = getValidProjectileTargets(rangedUnit, rangedUnit.location, rangedUnitData.isHandheld, rangedUnitData.projectileType, projectileRange)
								if #targets > 0 then
									-- For artillery, ability to fire depends on percent of HP remaining
									local fireChance = 100
									if rangedUnitData.isHandheld == false then
										fireChance = (rangedUnit.hitpoints / rangedUnit.type.hitpoints) * 100
										if rangedUnitData.isGunpowder == true and rangedUnit.hitpoints <= constant.mmRangedUnits.GUNPOWDER_ARTILLERY_FIRING_DAMAGE_HP then
											-- Gunpowder artillery lose HP when firing, so they are not permitted to fire unless they have more HP remaining than they will lose
											fireChance = 0
										end
									end
									local randomNumber = math.random(100)
									log.info("Ranged unit fire chance = " .. fireChance .. ", randomNumber = " .. randomNumber)
									if randomNumber <= fireChance then

										-- "Fire!"
										log.action(rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " (ID " .. rangedUnit.id .. ") fires projectile")
										local projectile = unitutil.createByType(rangedUnitData.projectileType, rangedUnit.owner, rangedUnit.location, {homeCity = nil})
										if projectile ~= nil then
											thisTribeProjSummary.numFired = (thisTribeProjSummary.numFired or 0) + 1
											if projectileCost > 0 then
												thisTribeProjSummary.fireCost = (thisTribeProjSummary.fireCost or 0) + projectileCost
												tribeutil.changeMoney(projectile.owner, projectileCost * -1)
											end
											db.projectileSummary[unit.owner.id] = thisTribeProjSummary
											-- If the firing unit is a mobile type, but it was fortified, change its order to fortifYING instead of fortifIED

											if rangedUnit.type.move > 0 and rangedUnit.order & 0xFF == 0x02 then
												rangedUnit.order = 0x01
												log.action("Changed ranged unit order from Fortified to Fortifying")
											end
											-- Reduce the projectile's MP so that it does not exceed the farthest target actually found:
											-- Note that if we reduced projectileRange above, this affected the valid targets, so we don't need to reduce the projectile's MP
											--		based *directly* on projectileRange
											local maxTargetDistance = 0
											for _, target in ipairs(targets) do
												if target.distance > maxTargetDistance then
													maxTargetDistance = target.distance
												end
											end
											if unitutil.getMovesRemaining(projectile) > maxTargetDistance then
												projectile.moveSpent = projectile.moveSpent + unitutil.getMovesAsMovementPoints(unitutil.getMovesRemaining(projectile) - maxTargetDistance)
											end
											if projectile.moveSpent > 0 then
												log.action("Set projectile remaining movement to " .. unitutil.getMovesRemaining(projectile))
											end
											-- Veterancy matches that of the firing unit:
											projectile.veteran = rangedUnit.veteran
											-- If the firing unit has insufficient MP remaining, or has taken damage, the offensive strength of the projectile may be reduced to compensate.

											local movementPercentOfBase = 100
											if rangedUnit.type.move > 0 and rangedUnit.moveSpent > 0 and unitMovesRemaining < rangedUnitData.moveCostPerProj then
												movementPercentOfBase = (unitMovesRemaining / rangedUnitData.moveCostPerProj) * 100
											end
											local damagePercentOfBase = 100
											if rangedUnit.damage > 0 then
												damagePercentOfBase = (rangedUnit.hitpoints / rangedUnit.type.hitpoints) * 100
											end
											-- All deductions are documented within the db.projectileSources table, and will be applied when the projectile itself is the activated unit:
											db.projectileSources[projectile.id] = {
												sourceUnitId = rangedUnit.id,
												sourceUnitTypeId = rangedUnit.type.id,
												sourceMovesToRestore = math.min(unitutil.getMovesRemaining(rangedUnit), rangedUnitData.moveCostPerProj),
												sourceMovementPercent = movementPercentOfBase,
												sourceDamagePercent = damagePercentOfBase
											}
											-- Just in case the projectile has an entry as a ranged unit (should only be able to happen if a ranged unit was disbanded after firing):
											clearFireHistoryForUnit(projectile)
											-- Apply damage to the firing unit, if applicable:
											if rangedUnitData.isHandheld == false and rangedUnitData.isGunpowder == true then
												rangedUnit.damage = rangedUnit.damage + constant.mmRangedUnits.GUNPOWDER_ARTILLERY_FIRING_DAMAGE_HP
												log.action("Reduced HP of " .. rangedUnit.type.name .. " from " .. (rangedUnit.hitpoints + constant.mmRangedUnits.GUNPOWDER_ARTILLERY_FIRING_DAMAGE_HP) .. " to " .. rangedUnit.hitpoints)
											end
											-- Reduce remaining movement of firing unit as defined in the table:
											local previousMovesRemaining = unitutil.getMovesRemaining(rangedUnit)
											rangedUnit.moveSpent = math.min(rangedUnit.moveSpent + unitutil.getMovesAsMovementPoints(rangedUnitData.moveCostPerProj), rangedUnit.type.move)
											if previousMovesRemaining > unitutil.getMovesRemaining(rangedUnit) then
												log.action("Reduced remaining movement of " .. rangedUnit.type.name .. " from " .. previousMovesRemaining .. " to " .. unitutil.getMovesRemaining(rangedUnit))
											elseif previousMovesRemaining == unitutil.getMovesRemaining(rangedUnit) then
												log.info(rangedUnit.type.name .. " already has " .. previousMovesRemaining .. " MP remaining which is correct")
											else
												log.error("ERROR! " .. unitutil.getMovesRemaining(rangedUnit) .. " MP is greater than " .. previousMovesRemaining .. " MP which should be impossible.")
											end
											-- Document the ranged unit action in db:
											db.rangedUnitsFired[rangedUnit.id] = projectilesFired + 1
											-- Potentially activate the projectile (if the firing unit was itself previously active):
											if activateImmediately == true and unitutil.canMove(projectile) then
												log.info("Manually activating " .. projectile.owner.adjective .. " " .. projectile.type.name .. " (ID " .. projectile.id .. ") at " .. projectile.x .. "," .. projectile.y)
												inputUnitContinuesTurn = false
												if projectile.owner.isHuman == true then
													civ.ui.centerView(projectile.location)
												end
												projectile:activate()
												onActivateUnitFunction(projectile, true)
											end
										else
											log.error("ERROR! Ranged unit tried to fire, but projectile was nil!")
										end

									else	-- i.e., randomNumber > fireChance, ranged unit is not permitted to fire
										log.action(rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " (ID " .. rangedUnit.id .. ") not permitted to fire projectile due to damage")
										-- Ranged unit also cannot move this turn, must rest
										local movesRemaining = unitutil.getMovesRemaining(rangedUnit)
										if rangedUnit.type == MMUNIT.ArmedCarrack then
											rangedUnit.moveSpent = rangedUnit.moveSpent + (RANGED_UNIT_DATA_TABLE[MMUNIT.ArmedCarrack.id].moveCostPerProj * totpp.movementMultipliers.aggregate)
											-- Mark unit as having fired (even though it didn't/couldn't, so it doesn't try again upon reactivation:
											db.rangedUnitsFired[rangedUnit.id] = projectilesFired + 1
										else
											rangedUnit.moveSpent = rangedUnit.type.move
										end
										log.action("Reduced remaining movement of " .. rangedUnit.type.name .. " from " .. movesRemaining .. " to " .. unitutil.getMovesRemaining(rangedUnit))
										if rangedUnit.owner.isHuman == true then
											local cause = "because it was in need of urgent repairs"
											if rangedUnitData.isGunpowder == true then
												cause = "in order to prevent it from overheating"
											end
											uiutil.messageDialog("Military Commander", "Our " .. rangedUnit.type.name .. " at " .. rangedUnit.x .. "," .. rangedUnit.y .. " was unable to fire this turn " .. cause .. ". The condition of this artillery unit is currently " .. tostring(round((rangedUnit.hitpoints / rangedUnit.type.hitpoints) * 100)) .. "%.")
										end
									end
								else
									log.info("No enemies found within range " .. projectileRange .. ", " .. rangedUnit.type.name .. " retains " .. unitutil.getMovesRemaining(rangedUnit) .. " MP")
								end
							end
						end
					end
				else
					log.info("Unit has insufficient MP remaining to fire (" .. rangedUnitData.moveCostPerProj .. " MP required)")
				end
			end
		elseif unit.type == rangedUnitData.projectileType then
			-- If unit is a projectile unit, confirm that it still has a valid target within range
			-- If not, destroy it and return movement (if applicable) to the unit that fired it
			local unitMovesRemaining = unitutil.getMovesRemaining(unit)
			local projectile = unit
			local projectileSourceData = db.projectileSources[projectile.id] or { }
			local rangedUnit = getRangedUnit(projectile)
			log.info(eventDescription .. " projectile unit: " .. projectile.owner.adjective .. " " .. projectile.type.name .. " (ID " .. projectile.id .. ") at " .. projectile.x .. "," .. projectile.y)
			log.info("  with " .. unitutil.getMovesRemaining(projectile) .. " MP remaining")
			if unitMovesRemaining >= 1 or unit.moveSpent == 0 then
				if civ.isTile(projectile.location) == true and projectile.x < 65000 and projectile.y < 65000 then
					if rangedUnit ~= nil then
						local correctRangedUnitData = RANGED_UNIT_DATA_TABLE[rangedUnit.type.id]
						-- rangedUnitData
						local targets = getValidProjectileTargets(rangedUnit, projectile.location, correctRangedUnitData.isHandheld, correctRangedUnitData.projectileType, unitutil.getMovesRemaining(projectile))
						if #targets > 0 then

							reduceProjectileOffense(projectile, projectileSourceData)

							if projectile.owner.isHuman == true then
								-- For the human player, all projectiles should correctly be marked as missiles that fall to earth after one turn:
								if unitutil.hasFlagDestroyedAfterAttacking(projectile.type) == false then
									unitutil.addFlagDestroyedAfterAttacking(projectile.type)
									projectile.type.range = 1
									log.action("Set range of " .. projectile.type.name .. " (unit type " .. projectile.type.id .. ") to " .. projectile.type.range)
								end
							else

								if unitutil.hasFlagDestroyedAfterAttacking(projectile.type) == true then
									unitutil.removeFlagDestroyedAfterAttacking(projectile.type)
									projectile.type.range = 2
									log.action("Set range of " .. projectile.type.name .. " (unit type " .. projectile.type.id .. ") to " .. projectile.type.range)
								end

								if unitutil.getMovesRemaining(projectile) == 2 then
									local adjacentTilesToTargets = { }
									local hasTargetOneTileAway = false
									for _, potentialTarget in ipairs(targets) do
										if potentialTarget.distance == 1 then
											hasTargetOneTileAway = true
											break
										else
											for _, adjTile in ipairs(tileutil.getAdjacentTiles(potentialTarget.target.location, false)) do
												if civ.isTile(adjTile) then
													table.insert(adjacentTilesToTargets, adjTile)
												end
											end
										end
									end
									if hasTargetOneTileAway == false then
										local validFirstMoves = { }
										for _, adjTile in ipairs(tileutil.getAdjacentTiles(projectile.location, false)) do
											if civ.isTile(adjTile) then
												if unitutil.isValidUnitLocation(projectile.type, projectile.owner, adjTile) then
													local alsoAdjacentToTarget = false
													for _, adjacentTileToTarget in ipairs(adjacentTilesToTargets) do
														if adjTile == adjacentTileToTarget then
															alsoAdjacentToTarget = true
															break
														end
													end
													if alsoAdjacentToTarget == true then
														table.insert(validFirstMoves, adjTile)
													end
												end
											end
										end
										if #validFirstMoves > 0 then
											local firstMove = validFirstMoves[math.random(#validFirstMoves)]
											unitutil.teleportUnit(projectile, firstMove)
											projectile.moveSpent = projectile.moveSpent + unitutil.getMovesAsMovementPoints(1)
											log.action("  and incremented its movement spent by 1")
										end
									end
								end		-- if unitutil.getMovesRemaining(projectile) == 2
							end		-- i.e., if projectile.owner.isHuman == false

						else

							-- "Undo!"	(need to undo ranged unit firing, since projectile no longer has a valid target)
							local projectileMoveSpent = unitutil.getMovementPointsAsMoves(projectile.moveSpent)
							if unitutil.getMovesRemaining(projectile) >= 1 then
								projectileMoveSpent = 0
							end
							local movesToRestore = math.max(projectileSourceData.sourceMovesToRestore - projectileMoveSpent, 0)
							log.info("No valid target found for " .. projectile.owner.adjective .. " " .. projectile.type.name .. " at " .. projectile.x .. "," .. projectile.y)
							clearProjectileHistoryForUnit(projectile)
							thisTribeProjSummary.numFired = (thisTribeProjSummary.numFired or 0) - 1
							local projectileCost = getProjectileCost(projectile.type, projectile.owner)
							if projectileCost > 0 then
								thisTribeProjSummary.fireCost = (thisTribeProjSummary.fireCost or 0) - projectileCost
								tribeutil.changeMoney(projectile.owner, projectileCost)
							end
							db.projectileSummary[unit.owner.id] = thisTribeProjSummary

							-- Updates to firing unit:
							if correctRangedUnitData.isHandheld == false and correctRangedUnitData.isGunpowder == true then
								rangedUnit.damage = math.max(rangedUnit.damage - constant.mmRangedUnits.GUNPOWDER_ARTILLERY_FIRING_DAMAGE_HP, 0)
								log.action("Increased HP of " .. rangedUnit.type.name .. " from " .. (rangedUnit.hitpoints - constant.mmRangedUnits.GUNPOWDER_ARTILLERY_FIRING_DAMAGE_HP) .. " to " .. rangedUnit.hitpoints)
							end
							movesToRestore = math.min(movesToRestore, unitutil.getMovementPointsAsMoves(rangedUnit.type.move))
							rangedUnit.moveSpent = math.max(rangedUnit.moveSpent - unitutil.getMovesAsMovementPoints(movesToRestore), 0)
							log.action("Restored " .. movesToRestore .. " MP to " .. rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " (ID " .. rangedUnit.id .. ") at " .. rangedUnit.x .. "," .. rangedUnit.y)
							if rangedUnit.type.move > 0 and rangedUnit.order & 0xFF == 0x01 then
								rangedUnit.order = 0x02
								log.action("Changed ranged unit order from Fortifying back to Fortified")
							end
							local prevQuantityFired = db.rangedUnitsFired[rangedUnit.id]
							if prevQuantityFired == nil then
								log.error("ERROR! mmRangedUnit.fireOrMove found prevQuantityFired == nil for unit ID " .. tostring(rangedUnit.id))
								prevQuantityFired = 1
							end
							db.rangedUnitsFired[rangedUnit.id] = prevQuantityFired - 1

							inputUnitContinuesTurn = false
							if projectile.owner.isHuman == true then
								-- Deleting the projectile at this point, while it is the active unit, causes the interface to flip from 'Move pieces' mode to 'View pieces' mode
								-- Instead, we will set db variable, and the onActivateUnit() trigger will delete the unit the next time it runs
								table.insert(db.gameData.UNITS_TO_DELETE_IMMEDIATELY, projectile)
								-- Then we will set the projectile order to 'Sleep' which forces the game to select another unit (if one exists) to become the new active unit
								unitutil.sleepUnit(projectile)
								-- The combination of these two commands prevents the mode from flipping and deletes the unit at the earliest possible opportunity
								-- The only corner case is when the projectile was fired by an immobile ranged unit, and every other unit has already been issued orders for this turn
								-- Then there is no other unit that can be activated, so the projectile remains asleep and is not deleted
								-- To handle this, it will be deleted in destroyAllProjectiles() without generating any error
								-- This function will run before the next tribe takes their turn, so the single remaining projectile cannot cause any (serious) issues
							else
								-- Deleting the projectile at this point is fine if the owner is an AI tribe; an interface mode flip is of no concern
								-- In fact, using the same approach as for the human player doesn't work! The AI doesn't honor the "sleep" request and will continue using the unit.
								unitutil.deleteUnit(projectile)
							end
							-- Finally: since the projectile is going away, any changes made to its stats or those of potential targets can be reset:
							resetAllUnitStats("mmRangedUnits.fireOrMove", true)
						end
					else	-- i.e., rangedUnit == nil
						-- The following message should probably be "info" instead of "update", although we're going to be doing plenty of "updating" as a result...
						log.update("Could not find valid ranged unit with ID " .. tostring(rangedUnit.id) .. " which fired " .. projectile.owner.adjective .. " " .. projectile.type.name .. " (ID " .. projectile.id .. ") at " .. projectile.x .. "," .. projectile.y .. ".")
						-- This means that the ranged unit either attacked by itself, and lost, or was disbanded
						-- New code to prevent the ranged unit from moving while its projectile exists should eliminate or greatly reduce the frequency of the former
						-- But the latter cannot be entirely prevented. In some testing, the AI disbands the ranged unit when the city that supports it builds *another* unit
						--		and then can't generate enough Materials to support both.
						-- If we don't know the ranged unit that fired the projectile, we aren't able to search for valid targets, so we can't determine if the projectile
						-- 		should remain, or if we should Undo and restore movement to the firing unit. But we couldn't Undo anyway, if the firing unit doesn't exist.
						-- So: if the ranged unit is "gone" by the time the projectiles try to move, then we will treat this like we do an "abandoned" projectile,
						--		which means we get rid of it but credit its owner some gold as compensation:
						clearProjectileHistoryForUnit(projectile)
						local projectileCost = getProjectileCost(projectile.type, projectile.owner)
						thisTribeProjSummary.numFired = (thisTribeProjSummary.numFired or 0) - 1
						thisTribeProjSummary.fireCost = (thisTribeProjSummary.fireCost or 0) - projectileCost
						local projectileRecoveryValue = projectile.type.attack + projectile.type.firepower
						thisTribeProjSummary.numRecovered = (thisTribeProjSummary.numRecovered or 0) + 1
						thisTribeProjSummary.recoveryValue = (thisTribeProjSummary.recoveryValue or 0) + projectileRecoveryValue
						tribeutil.changeMoney(projectile.owner, projectileCost + projectileRecoveryValue)
						db.projectileSummary[unit.owner.id] = thisTribeProjSummary
						inputUnitContinuesTurn = false
						-- See notes above for similar issue
						if projectile.owner.isHuman == true then
							table.insert(db.gameData.UNITS_TO_DELETE_IMMEDIATELY, projectile)
							unitutil.sleepUnit(projectile)
						else
							unitutil.deleteUnit(projectile)
						end
						resetAllUnitStats("mmRangedUnits.fireOrMove", true)
					end
				else
					log.error("ERROR! Projectile unit found at " .. projectile.x .. "," .. projectile.y .. " which is not on a valid map tile!")
				end
			end

			-- While there is only one row in RANGED_UNIT_DATA_TABLE for each rangedType, there are MULTIPLE rows in the table that contain the same projectileType!
			-- But we only need to run this code once, so we will "break" out of this for loop if the "else" condition is met.
			-- Note that it doesn't matter if we find the row for the rangedType that actually fired this projectileType;
			--		we are finding the actual ranged unit for this projectile by looking in db
			break

		end
	end

	return inputUnitContinuesTurn

end

local function fireImmobileOrCityUnits (tribe)
	-- Immobile units are those that can never move, or those that will not activate on a given turn
	-- 		because they are either fortifying, fortified, or sleeping/sentried
	-- Units that are in a city are also processed, because even if they are NOT fortified or sentried there,
	--		these units can be manually activated from the city screen which does not fire onActivateUnit()
	log.trace()
	for unit in civ.iterateUnits() do
		if unit.owner == tribe and isRangedUnitType(unit.type) and
		   (unit.type.move == 0 or unitutil.isFortifying(unit) or unitutil.isFortified(unit) or unitutil.isSleeping(unit) or unit.location.city ~= nil) then
			local maxFiringEvents = RANGED_UNIT_DATA_TABLE[unit.type.id].maxQuantityFired or 1
			for i = 1, maxFiringEvents do
				fireOrMove(unit, false)
			end
		end
	end
end

local function firingUnitBecomesVeteran (winningUnit, attackingUnit)
	log.trace()
	if isProjectileUnitType(attackingUnit.type) and (attackingUnit == winningUnit or attackerInflictedMaxDamage == true) then
		local projectile = attackingUnit
		local rangedUnit = getRangedUnit(projectile)
		if rangedUnit ~= nil then
			if rangedUnit.veteran == false then
				local vetChance = constant.mmRangedUnits.FIRING_UNIT_VETERANCY_PCT
				if wonderutil.getOwner(MMWONDER.WhiteTowerFortress) == rangedUnit.owner and wonderutil.isEffective(MMWONDER.WhiteTowerFortress) then
					vetChance = constant.mmRangedUnits.FIRING_UNIT_WHITE_TOWER_VETERANCY_PCT
				end
				local randomNumber = math.random(100)
				log.info("Ranged unit veterancy chance = " .. vetChance .. ", randomNumber = " .. randomNumber)
				if randomNumber <= vetChance then
					rangedUnit.veteran = true
					log.action("Promoted " .. rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " to veteran status")
					if rangedUnit.owner.isHuman == true then
						-- Mimic the @PROMOTED dialog from game.txt:
						uiutil.messageDialog("Constable's Report", "For demonstrating exceptional accuracy in combat, our " .. rangedUnit.type.name .. " unit has been promoted to veteran status.", 360)
					end
				else
					log.info("Did not promote " .. rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " to veteran status; random " .. randomNumber .. " > " .. vetChance)
				end
			else
				log.info(rangedUnit.owner.adjective .. " " .. rangedUnit.type.name .. " is already veteran, no need to check for promotion")
			end
		else
			log.info("No projectile source data for winning unit (may have been a naval stack kill)")
		end
	else
		log.info("Winning unit was not a projectile")
	end
end

local function formatRangedUnitInfo (unit)
	log.trace()
	local dataTable = { }
	if unit ~= nil then
		if isRangedUnitType(unit.type) then
			dataTable[1] = "Ranged unit."
			local rangedDataEntry =  RANGED_UNIT_DATA_TABLE[unit.type.id]
			dataTable[2] = "Fires " .. rangedDataEntry.maxQuantityFired .. " " .. rangedDataEntry.projectileType.name .. " for " .. PROJECTILE_DATA_TABLE[rangedDataEntry.projectileType.id].cost .. " gold"
			dataTable[3] = "   when a target is within range."
		elseif isProjectileUnitType(unit.type) then
			dataTable[1] = "Projectile unit."
			dataTable[2] = "Fired by"
			local firedByTable = { }
			for rangedUnitTypeId, rangedUnitData in pairs(RANGED_UNIT_DATA_TABLE) do
				if rangedUnitData.projectileType == unit.type then
					table.insert(firedByTable, civ.getUnitType(rangedUnitTypeId).name)
				end
			end
			for key, value in ipairs(firedByTable) do
				dataTable[2] = dataTable[2] .. " " .. value
				if key < #firedByTable - 1 or (key == #firedByTable - 1 and #firedByTable > 2) then
					dataTable[2] = dataTable[2] .. ","
				end
				if key == #firedByTable - 1 then
					dataTable[2] = dataTable[2] .. " and"
				end
			end
			dataTable[3] = "   for " .. PROJECTILE_DATA_TABLE[unit.type.id].cost .. " gold."
		end
	end
	return dataTable
end

local function getDefenderHpThreshold (attackingUnit, defendingUnit)
	log.trace()
	local threshold = 0

	if isProjectileUnitType(attackingUnit.type) then
		local projectile = attackingUnit
		-- This starts by assuming that the ranged unit is artillery, as a default, and calculates the higher threshold
		--		for the defending unit.
		-- The threshold is always rounded normally if the defender is an AI unit (i.e., 2.5 rounds *up* to 3)
		--		but is rounded *down* if the defender is human (i.e., 2.5 rounds down to 2)
		--		This is done *in place of* any reference to adjustForDifficulty(), which is not used, as a way to
		--		mitigate natural human advantage in understanding appropriate usage of artillery at all difficulty levels.
		if defendingUnit.owner.isHuman == true then
			threshold = math.floor(defendingUnit.hitpoints * (constant.mmRangedUnits.ARTILLERY_DAMAGE_PCT_MAX / 100))
		else
			threshold = round(defendingUnit.hitpoints * (constant.mmRangedUnits.ARTILLERY_DAMAGE_PCT_MAX / 100))
		end
		-- If the ranged unit can be confirmed to be handheld, set the threshold back to the default of 0
		-- 		This means that if the ranged unit is ever missing, then the defender gets the benefit of the doubt
		local rangedUnit = getRangedUnit(projectile)
		if rangedUnit ~= nil and RANGED_UNIT_DATA_TABLE[rangedUnit.type.id].isHandheld == true then
			threshold = 0
		end
		-- There are two special cases: if the defending unit is not human, or is permanently immobile, the correct
		--		threshold is zero. Ships follow the higher threshold so they may not be sunk with a single shot.
		if defendingUnit.type.move == 0 or (defendingUnit.type.domain == domain.Land and isHumanUnitType(defendingUnit.type) == false) then
			threshold = 0
		end
	end
	return threshold
end

local function improvementDestroyedByAttack (attackingUnit, defendingUnit, winningUnit, battleTile)
	-- Note that destruction of specific city improvements when a city is *conquered* is controlled by binary flags in Rules.txt
	-- This determines whether city improvements are destroyed by bombardment, with special emphasis on walls
	-- This also applies similar logic to the destruction of a castle by bombardment
	-- See mmTerrain.tileImprovementsDestroyedByBattle() for additional checks related to destruction of castles
	--		when the final defender is killed (regardless of attacking unit)
	log.trace()
	local wallsOrCastleDestroyChance = 0
	local improvementDestroyChance = 0
	if isProjectileUnitType(attackingUnit.type) then
		wallsOrCastleDestroyChance = PROJECTILE_DATA_TABLE[attackingUnit.type.id].pctChanceCityWallsOrCastleDestroyed
		improvementDestroyChance = PROJECTILE_DATA_TABLE[attackingUnit.type.id].pctChanceImprovementDestroyedIfWallsAreNot
	end
	if attackingUnit ~= winningUnit and attackerInflictedMaxDamage == false then
		wallsOrCastleDestroyChance = wallsOrCastleDestroyChance * (constant.mmRangedUnits.LOSING_PROJECTILE_IMPACT_PCT / 100)
		improvementDestroyChance = improvementDestroyChance * (constant.mmRangedUnits.LOSING_PROJECTILE_IMPACT_PCT / 100)
	end
	if wallsOrCastleDestroyChance > 0 then
		if tileutil.hasCity(battleTile) and civ.hasImprovement(battleTile.city, MMIMP.CityWalls) then
			if civ.hasImprovement(battleTile.city, MMIMP.BastionFortress) then
				wallsOrCastleDestroyChance = 0
			end
			local randomNumber = math.random(10000)
			log.info("City Walls destruction chance = " .. wallsOrCastleDestroyChance .. ", randomNumber = " .. (randomNumber / 100))
			if randomNumber <= (wallsOrCastleDestroyChance * 100) then
				imputil.removeImprovement(battleTile.city, MMIMP.CityWalls)
				if attackingUnit.owner.isHuman == true or defendingUnit.owner.isHuman == true then
					uiutil.messageDialog("Military Commander", "The city walls of " .. battleTile.city.name .. " have been destroyed by the " .. attackingUnit.type.name .. " attack!")
				end
				improvementDestroyChance = 0
			end
		elseif tileutil.hasFortress(battleTile) then

			local randomNumber = math.random(10000)
			log.info("Castle destruction chance = " .. wallsOrCastleDestroyChance .. ", randomNumber = " .. (randomNumber / 100))
			if randomNumber <= (wallsOrCastleDestroyChance * 100) then
				tileutil.removeFortress(battleTile)
				log.action("Destroyed castle due to " .. attackingUnit.type.name .. " projectile attack at " .. battleTile.x .. "," .. battleTile.y)
				if attackingUnit.owner.isHuman == true or defendingUnit.owner.isHuman == true then
					uiutil.messageDialog("Military Commander", "The castle at " .. battleTile.x .. "," .. battleTile.y .. " has been destroyed by the " .. attackingUnit.type.name .. " attack!")
				end
				improvementDestroyChance = 0
			end
		else
			improvementDestroyChance = improvementDestroyChance + wallsOrCastleDestroyChance
		end
	end
	if improvementDestroyChance > 0 and tileutil.hasCity(battleTile) then
		local improvementList = { }

		if civ.hasImprovement(battleTile.city, MMIMP.RoyalPalace)			then table.insert(improvementList, MMIMP.RoyalPalace) end
		if civ.hasImprovement(battleTile.city, MMIMP.Barracks)				then table.insert(improvementList, MMIMP.Barracks) end
		if civ.hasImprovement(battleTile.city, MMIMP.GristMill)				then table.insert(improvementList, MMIMP.GristMill) end
		if civ.hasImprovement(battleTile.city, MMIMP.Basilica)				then table.insert(improvementList, MMIMP.Basilica) end
		if civ.hasImprovement(battleTile.city, MMIMP.Marketplace)			then table.insert(improvementList, MMIMP.Marketplace) end
		if civ.hasImprovement(battleTile.city, MMIMP.MagistratesOffice)		then table.insert(improvementList, MMIMP.MagistratesOffice) end
		if civ.hasImprovement(battleTile.city, MMIMP.TextileMill)			then table.insert(improvementList, MMIMP.TextileMill) end
		if civ.hasImprovement(battleTile.city, MMIMP.RomanesqueCathedral)	then table.insert(improvementList, MMIMP.RomanesqueCathedral) end
		if civ.hasImprovement(battleTile.city, MMIMP.CathedralSchool)		then table.insert(improvementList, MMIMP.CathedralSchool) end
		if civ.hasImprovement(battleTile.city, MMIMP.GothicCathedral)		then table.insert(improvementList, MMIMP.GothicCathedral) end
		if civ.hasImprovement(battleTile.city, MMIMP.Foundry)				then table.insert(improvementList, MMIMP.Foundry) end
		if civ.hasImprovement(battleTile.city, MMIMP.Hospital)				then table.insert(improvementList, MMIMP.Hospital) end
		if civ.hasImprovement(battleTile.city, MMIMP.WindMill)				then table.insert(improvementList, MMIMP.WindMill) end
		if civ.hasImprovement(battleTile.city, MMIMP.WaterMill)				then table.insert(improvementList, MMIMP.WaterMill) end
		if civ.hasImprovement(battleTile.city, MMIMP.Bank)					then table.insert(improvementList, MMIMP.Bank) end
		if civ.hasImprovement(battleTile.city, MMIMP.University)			then table.insert(improvementList, MMIMP.University) end
		if civ.hasImprovement(battleTile.city, MMIMP.Guildhall)				then table.insert(improvementList, MMIMP.Guildhall) end
		if civ.hasImprovement(battleTile.city, MMIMP.HarborCrane)			then table.insert(improvementList, MMIMP.HarborCrane) end
		if civ.hasImprovement(battleTile.city, MMIMP.Shipyard)				then table.insert(improvementList, MMIMP.Shipyard) end

		if #improvementList > 0 then
			local randomNumber = math.random(10000)
			log.info("Improvement destruction chance = " .. improvementDestroyChance .. ", randomNumber = " .. (randomNumber / 100))
			if randomNumber <= (improvementDestroyChance * 100) then
				local randomImprovement = math.random(#improvementList)
				imputil.removeImprovement(battleTile.city, improvementList[randomImprovement])
				if attackingUnit.owner.isHuman == true or defendingUnit.owner.isHuman == true then
					uiutil.messageDialog("Military Commander", "The " .. improvementList[randomImprovement]["name"] .. " of " .. battleTile.city.name .. " has been destroyed by the " .. attackingUnit.type.name .. " attack!")
				end
			end
		end
	end
end

local function preventCityFromBuildingProjectile (city, unit)

	log.trace()
	if isProjectileUnitType(unit.type) then
		log.action(city.owner.adjective .. " city of " .. city.name .. " illegally produced a projectile unit: " .. unit.type.name)
		unitutil.deleteUnit(unit)
	end
end

local function provideProjectileSummary (tribe)
	log.trace()
	if db.projectileSummary[tribe.id] ~= nil and db.projectileSummary[tribe.id] ~= { } then
		local quantity = db.projectileSummary[tribe.id].numFired or 0
		local desc = "projectiles"
		if quantity == 1 then
			desc = "projectile"
		end
		local totalFireCost = db.projectileSummary[tribe.id].fireCost or 0
		local messageText = " fired " .. quantity .. " " .. desc .. " at a total cost of " .. tostring(totalFireCost) .. " gold"
		local messageText2 = ""
		log.info(tribe.name .. messageText)
		local totalRecoveryValue = 0
		if db.projectileSummary[tribe.id].numRecovered ~= nil and db.projectileSummary[tribe.id].numRecovered ~= 0 then
			local quantity2 = db.projectileSummary[tribe.id].numRecovered or 0
			local desc2 = "projectiles"
			if quantity2 == 1 then
				desc2 = "projectile"
			end
			totalRecoveryValue = db.projectileSummary[tribe.id].recoveryValue or 0
			messageText2 = " received " .. tostring(totalRecoveryValue) .. " gold in exchange for " .. quantity2 .. " unused " .. desc2
			log.info(tribe.name .. messageText2)
			if tribe.isHuman == false and constant.events.ADMINISTRATOR_MODE == true then
				uiutil.messageDialog("Administrator Mode Message", tribe.name .. messageText2 .. ".")
			end
		end
		if tribe.isHuman == true and (totalFireCost > 0 or totalRecoveryValue > 0) then
			messageText = "Our military forces " .. messageText .. "."
			if totalRecoveryValue > 0 then
				messageText = messageText .. "||However, we " .. messageText2 .. "."
			end
			uiutil.messageDialog("Constable's Report", messageText, 600)
		end
	end
	db.projectileSummary[tribe.id] = nil
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 24

return {
	confirmLoad = confirmLoad,

	isHumanRangedUnitType = isHumanRangedUnitType,
	isProjectileUnitType = isProjectileUnitType,
	isRangedUnitType = isRangedUnitType,
	resetAllUnitStats = resetAllUnitStats,
	captureArtilleryUnit = captureArtilleryUnit,
	clearHistoryForAllUnits = clearHistoryForAllUnits,
	clearFireHistoryForUnit = clearFireHistoryForUnit,
	clearProjectileHistoryForUnit = clearProjectileHistoryForUnit,
	cityTakenByProjectile = cityTakenByProjectile,
	destroyProjectile = destroyProjectile,
	destroyAllProjectiles = destroyAllProjectiles,
	fireOrMove = fireOrMove,
	fireImmobileOrCityUnits = fireImmobileOrCityUnits,
	firingUnitBecomesVeteran = firingUnitBecomesVeteran,
	formatRangedUnitInfo = formatRangedUnitInfo,
	getDefenderHpThreshold = getDefenderHpThreshold,
	improvementDestroyedByAttack = improvementDestroyedByAttack,
	preventCityFromBuildingProjectile = preventCityFromBuildingProjectile,
	provideProjectileSummary = provideProjectileSummary,
}
