-- mmAliases.lua
-- by Knighttime

log.trace()

-- =============================================
-- ••••••••••••••• GLOBAL TABLES •••••••••••••••
-- =============================================
-- As global variables, these tables can be used seamlessly within all custom external modules.

MMGOVERNMENT = {
	[0] = "Interregnum",
	[1] = "Primitive Monarchy",
	[2] = "Enlightened Monarchy",
	[3] = "Feudal Monarchy",
	[4] = "Tribal Monarchy",
	[5] = "Constitutional Monarchy",
	[6] = "Merchant Republic",
	Interregnum = 0,
	PrimitiveMonarchy = 1,
	EnlightenedMonarchy = 2,
	FeudalMonarchy = 3,
	TribalMonarchy = 4,
	ConstitutionalMonarchy = 5,
	MerchantRepublic = 6
}
log.update("Defined Medieval Millennium governments")

MMTECHGROUP = {
	[0] = "Dark Ages",
	[1] = "Early Medieval",
	[2] = "High Medieval",
	[3] = "Late Medieval",
	[4] = "Carvel/Clinker Construction",
	[5] = "Feudalism",
	[6] = "Can't Be Researched",
	[7] = "Events Only",
	Dark = 0,
	Early = 1,
	High = 2,
	Late = 3,
	Ships = 4,
	Feudalism = 5,
	TradeOnly = 6,
	Never = 7
}
log.update("Defined Medieval Millennium tech groups")

MMTERRAIN = {
	[0]  = "Arable (poor)",
	[1]  = "Arable",
	[2]  = "Pasture",
	[3]  = "Arable (lush)",
	[4]  = "Mountain Pass",
	[5]  = "Mountains",
	[6]  = "Dense Forest",
	[7]  = "Pine Forest",
	[8]  = "Heathland",
	[9]  = "Marsh/Fen",
	[10] = "Sea",
	[11] = "Woodland",
	[12] = "Hills",
	[13] = "Terraced Hills",
	[14] = "Monastery",
	[15] = "Urban",
	ArablePoor = 0,
	Arable = 1,
	Pasture = 2,
	ArableLush = 3,
	MountainPass = 4,
	Mountains = 5,
	DenseForest = 6,
	PineForest = 7,
	Heathland = 8,
	MarshFen = 9,
	Sea = 10,
	Woodland = 11,
	Hills = 12,
	TerracedHills = 13,
	Monastery = 14,
	Urban = 15
}
log.update("Defined Medieval Millennium terrain types")

MMIMP = {
	-- 0 is not used (Nothing)
	RoyalPalace = civ.getImprovement(1),
	Barracks = civ.getImprovement(2),
	GristMill = civ.getImprovement(3),
	Basilica = civ.getImprovement(4),
	Marketplace = civ.getImprovement(5),
	Monastery = civ.getImprovement(6),
	MagistratesOffice = civ.getImprovement(7),
	CityWalls = civ.getImprovement(8),
	MarketTownCharter = civ.getImprovement(9),
	TextileMill = civ.getImprovement(10),
	RomanesqueCathedral = civ.getImprovement(11),
	CathedralSchool = civ.getImprovement(12),
	SewerConduits = civ.getImprovement(13),
	GothicCathedral = civ.getImprovement(14),
	WoodStoneCraftsmen = civ.getImprovement(15),
	Foundry = civ.getImprovement(16),
	-- 17 is not used (SDI Defense)
	Hospital = civ.getImprovement(18),
	WindMill = civ.getImprovement(19),
	WaterMill = civ.getImprovement(20),
	-- 21 is not used (Nuclear Plant)
	Bank = civ.getImprovement(22),
	FreeCityCharter = civ.getImprovement(23),
	EnclosedFields = civ.getImprovement(24),
	TradeFairCircuit = civ.getImprovement(25),
	University = civ.getImprovement(26),
	BastionFortress = civ.getImprovement(27),
	TradeFairCircuitActual = civ.getImprovement(28),
	Guildhall = civ.getImprovement(29),
	FishingFleet = civ.getImprovement(30),
	HarborCrane = civ.getImprovement(31),
	-- 32 is not used (Airport)
	ChivalricTournament = civ.getImprovement(33),
	Shipyard = civ.getImprovement(34),
	-- 35 is not used (Transporter)
	AtlanticFleetCrew = civ.getImprovement(36),
	AtlanticFleetSails = civ.getImprovement(37),
	AtlanticFleetShipCargo = civ.getImprovement(38),
	Scutage = civ.getImprovement(39),
}
log.update("Defined Medieval Millennium improvements")

MMWONDER = {
	DomesdayBook = civ.getWonder(0),
	GloriousGothicCathedral = civ.getWonder(1),
	HanseaticLeagueCapital = civ.getWonder(2),
	CommemorativeTapestry = civ.getWonder(3),
	PilgrimmageRoute = civ.getWonder(4),
	PalatineChapel = civ.getWonder(5),
	OffasDyke = civ.getWonder(6),
	WhiteTowerFortress = civ.getWonder(7),
	NavalIndustrialArsenal = civ.getWonder(8),
	TravelsofMarcoPolo = civ.getWonder(9),
	IconicRomanesqueCathedral = civ.getWonder(10),
	SchoolofMedicine = civ.getWonder(11),
	MountofStMichael = civ.getWonder(12),
	DecoratedOctagonalBasilica = civ.getWonder(13),
	BrunelleschisDome = civ.getWonder(14),
	OpulentRomanesqueCathedral = civ.getWonder(15),
	MagnificentCluniacAbbey = civ.getWonder(16),
	MediciBank = civ.getWonder(17),
	OrnateGospelBook = civ.getWonder(18),
	GreatCharter = civ.getWonder(19),
	HolyRomanEmperor = civ.getWonder(20),
	KingsHolyLandCrusade = civ.getWonder(21),
	CistercianOrder = civ.getWonder(22),
	PalaceofthePopes = civ.getWonder(23),
	LeaningTower = civ.getWonder(24),
	SeaRoutetoIndia = civ.getWonder(25),
	IconicUniversity = civ.getWonder(26),
	MajesticGothicCathedral = civ.getWonder(27),
}
log.update("Defined Medieval Millennium wonders")

MMUNIT = {
	ArabCavalry = unitutil.findTypeByName("Arab Cavalry", true),
	ArabInfantry = unitutil.findTypeByName("Arab Infantry", true),
	Arbalestier = unitutil.findTypeByName("Arbalestier –×", true),
	ArbalestierAI = unitutil.findTypeByName("Arbalestier –×_", true),
	Archer = unitutil.findTypeByName("Archer –›", true),
	ArcherAI = unitutil.findTypeByName("Archer –›_", true),
	ArmedCarrack = unitutil.findTypeByName("Armed Carrack ó", true),
	Arquebusier = unitutil.findTypeByName("Arquebusier •", true),
	ArtillArrow = unitutil.findTypeByName("}—> Artill Arrow", true),
	Axeman = unitutil.findTypeByName("Axeman", true),
	AxemanII = unitutil.findTypeByName("Axeman II", true),
	Bakery = unitutil.findTypeByName("§ Bakery", true),
	Balinger = unitutil.findTypeByName("Balinger", true),
	Basilisk = unitutil.findTypeByName("Basilisk O", true),
	BerberCavalry = unitutil.findTypeByName("Berber Cavalry", true),
	BerberInfantry = unitutil.findTypeByName("Berber Infantry", true),
	BlackDeath = unitutil.findTypeByName("Black Death", true),
	BodkinArrows = unitutil.findTypeByName("–» Bodkin Arrows", true),
	Bolts = unitutil.findTypeByName("–+ Bolts", true),
	Bombard = unitutil.findTypeByName("Bombard 0", true),
	Boulder = unitutil.findTypeByName("Þ Boulder", true),
	Bowman = unitutil.findTypeByName("Bowman –»", true),
	BowmanAI = unitutil.findTypeByName("Bowman –»_", true),
	BroadheadArrows = unitutil.findTypeByName("–› Broadhead Arrows", true),
	Bullets = unitutil.findTypeByName("• Bullets", true),
	Caravel = unitutil.findTypeByName("Caravel", true),
	Carpenter = unitutil.findTypeByName("§ Carpenter", true),
	Carrack = unitutil.findTypeByName("Carrack", true),
	CarvelGalley = unitutil.findTypeByName("Carvel Galley", true),
	ClinkerGalley = unitutil.findTypeByName("Clinker Galley", true),
	Cog = unitutil.findTypeByName("Cog", true),
	CommercialTrader = unitutil.findTypeByName("Commercial Trader", true),
	Couillard = unitutil.findTypeByName("Couillard þ", true),
	Crossbowman = unitutil.findTypeByName("Crossbowman –+", true),
	CrossbowmanAI = unitutil.findTypeByName("Crossbowman –+_", true),
	Cuirassier = unitutil.findTypeByName("Cuirassier ²¨", true),
	Culverin = unitutil.findTypeByName("Culverin Ó", true),
	Demiculverin = unitutil.findTypeByName("Demi-culverin ó", true),
	Demilancer = unitutil.findTypeByName("Demi-lancer", true),
	DemilancerAI = unitutil.findTypeByName("Demi-lancer_", true),
	Dromon = unitutil.findTypeByName("Dromon", true),
	Envoy = unitutil.findTypeByName("Envoy", true),
	Falconet = unitutil.findTypeByName("Falconet °´", true),
	FieldCulverin = unitutil.findTypeByName("Field Culverin Ó", true),
	FishingFleet = unitutil.findTypeByName("§ Fishing Fleet", true),
	Forge = unitutil.findTypeByName("§ Forge", true),
	Fowler = unitutil.findTypeByName("Fowler o", true),
	Garrot = unitutil.findTypeByName("}—> Garrot", true),
	GreatGalley = unitutil.findTypeByName("Great Galley", true),
	Halberdier = unitutil.findTypeByName("Halberdier", true),
	HalberdierAI = unitutil.findTypeByName("Halberdier_", true),
	HandCannoneer = unitutil.findTypeByName("Hand Cannoneer ·", true),
	HandCulveriner = unitutil.findTypeByName("Hand Culveriner ¨", true),
	Horseman = unitutil.findTypeByName("Horseman", true),
	Hulk = unitutil.findTypeByName("Hulk", true),
	Inquisitor = unitutil.findTypeByName("Inquisitor", true),
	Knarr = unitutil.findTypeByName("Knarr", true),
	Knight = unitutil.findTypeByName("Knight", true),
	KnightII = unitutil.findTypeByName("Knight II", true),
	KnightIII = unitutil.findTypeByName("Knight III", true),
	Lancer = unitutil.findTypeByName("Lancer", true),
	LgIronBall = unitutil.findTypeByName("Ó Lg Iron Ball", true),
	LgStoneBall = unitutil.findTypeByName(" O Lg Stone Ball", true),
	Longbowman = unitutil.findTypeByName("Longbowman –»", true),
	LongbowmanAI = unitutil.findTypeByName("Longbowman –»_", true),
	Longship = unitutil.findTypeByName("Longship", true),
	ManatArms = unitutil.findTypeByName("Man-at-Arms", true),
	Mangonel = unitutil.findTypeByName("Mangonel þ", true),
	Mason = unitutil.findTypeByName("§ Mason", true),
	MedIronBall = unitutil.findTypeByName("ó Med Iron Ball", true),
	MedStoneBall = unitutil.findTypeByName(" 0 Med Stone Ball", true),
	Merchant = unitutil.findTypeByName("Merchant", true),
	Miller = unitutil.findTypeByName("§ Miller", true),
	MonasticKnight = unitutil.findTypeByName("Monastic Knight", true),
	MongolCavalry = unitutil.findTypeByName("Mongol Cavalry –»", true),
	Monks = unitutil.findTypeByName("§ Monks", true),
	MotteandBailey = unitutil.findTypeByName("Motte and Bailey", true),
	Musketeer = unitutil.findTypeByName("Musketeer ²•", true),
	Peasant = unitutil.findTypeByName("Peasant", true),
	PeasantMilitia = unitutil.findTypeByName("Peasant Militia", true),
	Pebbles = unitutil.findTypeByName("· Pebbles", true),
	Pellets = unitutil.findTypeByName("¨ Pellets", true),
	Pikeman = unitutil.findTypeByName("Pikeman", true),
	PikemanII = unitutil.findTypeByName("Pikeman II", true),
	Plague = unitutil.findTypeByName("Plague", true),
	Potdefer = unitutil.findTypeByName("Pot-de-fer }—>", true),
	Privateer = unitutil.findTypeByName("Privateer", true),
	Quarrels = unitutil.findTypeByName("–× Quarrels", true),
	Refugee = unitutil.findTypeByName("Refugee", true),
	Ribauldequin = unitutil.findTypeByName("Ribauldequin ²¤", true),
	Rock = unitutil.findTypeByName("þ Rock", true),
	Saker = unitutil.findTypeByName("Saker ó", true),
	Sawmill = unitutil.findTypeByName("§ Sawmill", true),
	Scout = unitutil.findTypeByName("Scout", true),
	SeaxSwordsman = unitutil.findTypeByName("Seax Swordsman", true),
	Serf = unitutil.findTypeByName("Serf", true),
	Serpentine = unitutil.findTypeByName("Serpentine °´", true),
	SiegeEngineer = unitutil.findTypeByName("Siege Engineer", true),
	SiegeTower = unitutil.findTypeByName("Siege Tower", true),
	SlenderGalley = unitutil.findTypeByName("Slender Galley", true),
	SmIronBall = unitutil.findTypeByName("°´ Sm Iron Ball", true),
	Smith = unitutil.findTypeByName("§ Smith", true),
	SmStoneBall = unitutil.findTypeByName(" o Sm Stone Ball", true),
	Spearman = unitutil.findTypeByName("Spearman", true),
	SpearmanII = unitutil.findTypeByName("Spearman II", true),
	Springald = unitutil.findTypeByName("Springald }—>", true),
	StoneCastle = unitutil.findTypeByName("Stone Castle", true),
	Stonecutter = unitutil.findTypeByName("§ Stonecutter", true),
	Stones = unitutil.findTypeByName("¤ Stones", true),
	SwissPikeman = unitutil.findTypeByName("Swiss Pikeman", true),
	Swordsman = unitutil.findTypeByName("Swordsman", true),
	SwordsmanII = unitutil.findTypeByName("Swordsman II", true),
	TorsionCatapult = unitutil.findTypeByName("Torsion Catapult þ", true),
	TradeGalley = unitutil.findTypeByName("Trade Galley", true),
	Trebuchet = unitutil.findTypeByName("Trebuchet Þ", true),
	TurkishJanissary = unitutil.findTypeByName("Turkish Janissary ¨", true),
	VikingBerserker = unitutil.findTypeByName("Viking Berserker", true),
	VikingLongship = unitutil.findTypeByName("Viking Longship", true),
	VikingRaider = unitutil.findTypeByName("Viking Raider", true),
	WarCog = unitutil.findTypeByName("War Cog", true),
	Warlord = unitutil.findTypeByName("Warlord", true),
	Yeoman = unitutil.findTypeByName("Yeoman", true),
}
MM_BASE_UNIT_STATS = { }
for unittype in unitutil.iterateUnitTypes() do
	MM_BASE_UNIT_STATS[unittype.id] = {
		baseAttack = unittype.attack,
		baseFirepower = unittype.firepower
	}
end
log.update("Synchronized Medieval Millennium units")

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
-- None

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 4

return {
	confirmLoad = confirmLoad,
}
