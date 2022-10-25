--[[
events.lua, by Knighttime and tootall_2012
	for Napoléon, a scenario by tootall_2012
]]

NAPOLEON_LUA_EVENTS_VERSION = "1.3"
MINIMUM_TOTPP_VERSION = "0.15.1"

print("=====================================================")
print("events.lua v" .. NAPOLEON_LUA_EVENTS_VERSION .. ", by Knighttime and tootall_2012")
print("    for Napoléon, a scenario by tootall_2012")
print("")
print("Requires TOTPP v" .. MINIMUM_TOTPP_VERSION .. " or higher, by TheNamelessOne")
print("=====================================================")
print("")

local eventsPath = string.gsub(debug.getinfo(1).source, "@", "")
local scenarioFolderPath = string.gsub(eventsPath, "events.lua", "?.lua")
if string.find(package.path, scenarioFolderPath, 1, true) == nil then
	package.path = package.path .. ";" .. scenarioFolderPath
end

local func = require("functions")
local civlua = require("civlua")

local help = require("helpkey")

-- •••••••••• civlua function wrappers: •••••••••••••••••••••••••••••••••••••••
--[[ These functions wrap calls to civlua in order to provide additional output
	 to the Lua console regarding success or failure. ]]

local function findCityByName (cityName)
	local city = civlua.findCity(cityName)
	if city ~= nil then
		print("    Found city \"" .. cityName .. "\" with ID " .. city.id)
	else
		print("ERROR: did not find city \"" .. cityName .. "\", returning nil")
	end
	return city
end

--[[ Custom version of civlua.findUnitType, which has an error in TOTPP 0.15.1.  This
	 is temporary and could be eliminated if a later TOTPP release resolves the issue.
	 "getCosmic()" should be replaced by "cosmic" as shown below: ]]
local function civluaFindUnitType(unitName)
	for i = 0, civ.cosmic.numberOfUnitTypes - 1 do
		local unittype = civ.getUnitType(i)
		if unittype.name == unitName then
			return unittype
		end
	end
end

local function findUnitTypeByName (unitName)
	local unittype = civluaFindUnitType(unitName)
	if unittype ~= nil then
--		print("    Found unittype \"" .. unitName .. "\" with ID " .. unittype.id)
	else
		print("ERROR: did not find unittype \"" .. unitName .. "\", returning nil")
	end
	return unittype
end

local function createUnitsByName (unitName, owner, locations, options)
	-- Note: first parameter is the unit type *name* as a string, not a unit type object
	local createdUnits = civlua.createUnit(findUnitTypeByName(unitName), owner, locations, options)
	if createdUnits == nil or #createdUnits == 0 then
		print("ERROR: Failed to create unit: " .. unitName .. ", " .. owner.name)
	else
		for _, unit in pairs(createdUnits) do
			print("Created " .. unit.type.name .. " (" .. unit.owner.adjective .. ") at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
		end
		if #createdUnits == 1 then
			return createdUnits[1]
		end
	end
end

-- •••••••••• Persistence: ••••••••••••••••••••••••••••••••••••••••••••••••••••
local state = {}
local JUSTONCE = function (key, f)
	civlua.justOnce(civlua.property(state, key), f)
end


-- •••••••••• Variables scoped to the entire events file: •••••••••••••••••••••
local newScenario = true

local monthName = { "January", "February", "March", "April", "May", "June",
					"July", "August", "September", "October", "November", "December" }

local Barbarians = civ.getTribe(0)
local Russia = civ.getTribe(1)
local Austria = civ.getTribe(2)
local Prussia = civ.getTribe(3)
local Spain = civ.getTribe(4)
local Ottoman = civ.getTribe(5)
local France = civ.getTribe(6)
local England = civ.getTribe(7)

-- Custom information in the following table can be either a single string (e.g. see [23]) or a table of multiple strings (e.g. see [10])
-- This table is provided to the helpkey module and will appear onscreen as notes for the corresponding unit type
local customUnitTypeTextTable = {
--[[Sapeurs]]				[1] = nil,
--[[Gendarmes]]				[2] = nil,
--[[Napoléon I]]			[10] = {"Provides a 40% or 50% Attack Bonus to infantry and land artillery units on the same tile.", "Press 'k' to activate an Administrative Bonus menu for this unit if located in Paris."},
--[[Garde Impériale]]		[11] = nil,
--[[Régiment de Ligne]]		[12] = nil,
--[[Infanterie Légère]]		[13] = nil,
--[[Carabiniers]]			[14] = nil,
--[[Cuirassiers]]			[15] = nil,
--[[Lanciers]]				[16] = nil,
--[[Grenadier à Cheval]]	[17] = nil,
--[[Art. à pied 8lb]]		[23] = "Press 'k' to fire 8 pdr Shells at a cost of 4 francs.",
--[[Art. à Cheval]]			[25] = "Press 'k' to fire 6 pdr Shells at a cost of 3 francs.",
--[[Mortier de 12po.]]		[26] = "Press 'k' to fire Mortar Shells at a cost of 9 francs if located on terrain with the Siege Work improvement.",
--[[Mortar Shells]]			[44] = "Can be fired by Mortier de 12po.",
--[[6 pdr Shells]]			[45] = "Can be fired by Art. à Cheval",
--[[8 pdr Shells]]			[46] = "Can be fired by Art. à pied 8lb",
--[[Hussars]]				[47] = nil,
--[[Train Militaire]]		[48] = nil,
--[[Plunder]]				[49] = nil,
--[[Soult]]					[72] = {"Provides a 20% Attack Bonus to infantry and land artillery units on the same tile.", "Press 'k' to activate an Administrative Bonus menu for this unit if located in either Strasbourg or Toulouse."},
--[[Davout]]				[73] = {"Provides a 20% Attack Bonus to infantry and land artillery units on the same tile.", "Press 'k' to activate an Administrative Bonus menu for this unit if located in either Strasbourg or Toulouse."},
--[[Lannes]]				[74] = {"Provides a 30% Attack Bonus to infantry and land artillery units on the same tile.", "Press 'k' to activate an Administrative Bonus menu for this unit if located in either Strasbourg or Toulouse."},
--[[Murat]]					[75] = {"Provides a 30% Attack Bonus to cavalry units on the same tile.", "Press 'k' to activate an Administrative Bonus menu for this unit if located in Hanover."},
--[[18 pdr Shells]]			[81] = "Can be fired by Frégate",
--[[Bombard Shells]]		[82] = "Can be fired by Bombarde",
--[[Bombarde]]				[83] = "Press 'k' to fire Bombard Shells at a cost of 9 francs if located on an ocean tile.",
--[[Villeneuve]]			[89] = {"Provides a 30% Attack Bonus to naval artillery units on the same tile.", "Press 'k' to fire 32 pdr Shells at a cost of 9 francs if located on an ocean tile."},
--[[Neapolitan Infantry]]	[90] = nil,
--[[Bavarian Infantry]]		[93] = nil,
--[[Bavarian Cavalry]]		[94] = nil,
--[[Danish Infantry]]		[95] = nil,
--[[Danish Cavalry]]		[96] = nil,
--[[Italian Infantry]]		[97] = nil,
--[[Italian Cavalry]]		[98] = nil,
--[[Rhine Infantry]]		[99] = nil,
--[[Polish Infantry]]		[100] = nil,
--[[Polish Lancers]]		[101] = nil,
--[[Dutch Infantry]]		[102] = nil,
--[[Dutch Cavalry]]			[103] = nil,
--[[Westphalian Infantry]]	[104] = nil,
--[[Westphalian Cavalry]]	[105] = nil,
--[[Würtemberg Infantry]]	[106] = nil,
--[[Swiss Infantry]]		[108] = nil,
--[[Frégate]]				[117] = "Press 'k' to fire 18 pdr Shells at a cost of 5 francs if located on an ocean tile.",
--[[Deux-ponts]]			[118] = "Press 'k' to fire 24 pdr Shells at a cost of 7 francs if located on an ocean tile.",
--[[Trois-ponts]]			[119] = "Press 'k' to fire 32 pdr Shells at a cost of 9 francs if located on an ocean tile.",
--[[24 pdr Shells]]			[120] = "Can be fired by Deux-ponts",
--[[Art. à pied 12lb]]		[122] = "Press 'k' to fire 12 pdr Shells at a cost of 6 francs.",
--[[12 pdr Shells]]			[123] = "Can be fired by Art. à pied 12lb",
--[[32 pdr Shells]]			[125] = "Can be fired by Trois-ponts and by Villeneuve",
}

-- France 
local Paris = findCityByName("Paris")
local Amsterdam = findCityByName("Amsterdam")
local Marseille = findCityByName("Marseille")
local Napoli = findCityByName("Napoli")
local Reims = findCityByName("Reims")
local Toulon = findCityByName("Toulon")
local frenchUnitTypesToBeDestroyed = {
	findUnitTypeByName("Sapeurs"),
	findUnitTypeByName("Gendarmes"),
	findUnitTypeByName("Napoléon I"),
	findUnitTypeByName("Garde Impériale"),
	findUnitTypeByName("Régiment de Ligne"),
	findUnitTypeByName("Infanterie Légère"),
	findUnitTypeByName("Carabiniers"),
	findUnitTypeByName("Cuirassiers"),
	findUnitTypeByName("Lanciers"),
	findUnitTypeByName("Grenadier à Cheval"),
	findUnitTypeByName("Art. à pied 8lb"),
	findUnitTypeByName("Art. à Cheval"),
	findUnitTypeByName("Mortier de 12po."),
	findUnitTypeByName("Hussars"),
	findUnitTypeByName("Train Militaire"),
	findUnitTypeByName("Plunder"),
	findUnitTypeByName("Soult"),
	findUnitTypeByName("Davout"),
	findUnitTypeByName("Lannes"),
	findUnitTypeByName("Murat"),
	findUnitTypeByName("Bombarde"),
	findUnitTypeByName("Villeneuve"),
	findUnitTypeByName("Neapolitan Infantry"),
	findUnitTypeByName("Bavarian Infantry"),
	findUnitTypeByName("Bavarian Cavalry"),
	findUnitTypeByName("Danish Infantry"),
	findUnitTypeByName("Danish Cavalry"),
	findUnitTypeByName("Italian Infantry"),
	findUnitTypeByName("Italian Cavalry"),
	findUnitTypeByName("Rhine Infantry"),
	findUnitTypeByName("Polish Infantry"),
	findUnitTypeByName("Polish Lancers"),
	findUnitTypeByName("Dutch Infantry"),
	findUnitTypeByName("Dutch Cavalry"),
	findUnitTypeByName("Westphalian Infantry"),
	findUnitTypeByName("Westphalian Cavalry"),
	findUnitTypeByName("Würtemberg Infantry"),
	findUnitTypeByName("Swiss Infantry"),
	findUnitTypeByName("Frégate"),
	findUnitTypeByName("Deux-ponts"),
	findUnitTypeByName("Trois-ponts"),
	findUnitTypeByName("Irish Rebel"),
	findUnitTypeByName("Art. à pied 12lb"),
	findUnitTypeByName("Poniatowski")
}
local costPerTrainMilitaire = 15
local incomePerIrishRebel = 10
local embargoCostPerShipFrance = 15
local embargoIncomePerShipEngland = 8
local garrisonCostEngland = 75
local contrabandCostPrussia = 25
local garrisonCostRussia = 50
local garrisonCostSpain = 35
local revenuePerWarehouse = 3

-- Austria:
local Agram = findCityByName("Agram")
local Munchen = findCityByName("München")
local Nurnberg = findCityByName("Nürnberg")
local Prag = findCityByName("Prag")
local Ratisbon = findCityByName("Ratisbon")
local Trieste = findCityByName("Trieste")
local Venezia = findCityByName("Venezia")
local Wien = findCityByName("Wien")
local austrianUnitTypesToBeDestroyed = {
	findUnitTypeByName("Charles"),
	findUnitTypeByName("Guerrilla"),
	findUnitTypeByName("A. Line Infantry"),
	findUnitTypeByName("A. Light Infantry"),
	findUnitTypeByName("A. Kürassier"),
	findUnitTypeByName("A. Uhlans"),
	findUnitTypeByName("A. Foot Artillery"),
	findUnitTypeByName("A. Horse Artillery")
}

-- England
local Southampton = findCityByName("Southampton")
local englishUnitTypesToBeDestroyed = {
	findUnitTypeByName("Wellington"),
	findUnitTypeByName("K.G.L."),
	findUnitTypeByName("B. Line Infantry"),
	findUnitTypeByName("B. Light Infantry"),
	findUnitTypeByName("Dragoon Guards"),
	findUnitTypeByName("Light Dragoon"),
	findUnitTypeByName("B. Foot Artillery"),
	findUnitTypeByName("B. Horse Artillery"),
	findUnitTypeByName("Uxbridge"),
	findUnitTypeByName("Moore"),
	findUnitTypeByName("Minor Fort"),
	findUnitTypeByName("Major Fort"),
	findUnitTypeByName("Nelson"),
	findUnitTypeByName("Coalition Shells"),
	findUnitTypeByName("Frigate"),
	findUnitTypeByName("Two Decker"),
	findUnitTypeByName("Three Decker")
}

local portugueseUnitTypesToBeDestroyed = {
	findUnitTypeByName("Portuguese Infantry"),
	findUnitTypeByName("Portuguese Cavalry")
}

local swedishUnitTypesToBeDestroyed = {
	findUnitTypeByName("Swedish Infantry"),
	findUnitTypeByName("Swedish Cavalry")
}

-- Prussia:
local Berlin = findCityByName("Berlin")
local Bremen = findCityByName("Bremen")
local Brunswick = findCityByName("Brunswick")
local Danzig = findCityByName("Danzig")
local Dresden = findCityByName("Dresden")
local Hanover = findCityByName("Hanover")
local Kassel = findCityByName("Kassel")
local Konigsberg = findCityByName("Königsberg")
local Kustrin = findCityByName("Küstrin")
local Leipzig = findCityByName("Leipzig")
local Lublin = findCityByName("Lublin")
local Magdeburg = findCityByName("Magdeburg")
local Munster = findCityByName("Münster")
local Posen = findCityByName("Posen")
local Thorn = findCityByName("Thorn")
local Warszawa = findCityByName("Warszawa")
local prussianUnitTypesToBeDestroyed = {
	findUnitTypeByName("Blücher"),
	findUnitTypeByName("P. Line Infantry"),
	findUnitTypeByName("P. Light Infantry"),
	findUnitTypeByName("P. Kürassier"),
	findUnitTypeByName("P. Uhlans"),
	findUnitTypeByName("P. Foot Artillery"),
	findUnitTypeByName("P. Horse Artillery")
}

-- Russia:
local Corfu = findCityByName("Corfu")
local Ekaterinoslav = findCityByName("Ekaterinoslav")
local Kyiv = findCityByName("Kyiv")
local Moskva = findCityByName("Moskva")
local NiznijNovgorod = findCityByName("Niznij Novgorod")
local Odesa = findCityByName("Odesa")
local Riga = findCityByName("Riga")
local SanktPeterburg = findCityByName("Sankt-Peterburg")
local Smolensk = findCityByName("Smolensk")
local Vjazma = findCityByName("Vjaz'ma")
local russianUnitTypesToBeDestroyed = {
	findUnitTypeByName("R. Line Infantry"),
	findUnitTypeByName("R. Light Infantry"),
	findUnitTypeByName("R. Cuirassiers"),
	findUnitTypeByName("Don Cossack"),
	findUnitTypeByName("R. Foot Artillery"),
	findUnitTypeByName("R. Horse Artillery"),
	-- findUnitTypeByName("Life Guards"),
	findUnitTypeByName("R. Opolchenye")
}
local russianLeaderTypesToBeDestroyed = {
	findUnitTypeByName("Kutusov"),
	findUnitTypeByName("Bagration"),
	findUnitTypeByName("Barclay de Tolly")
}

-- Spain:
local ACoruna = findCityByName("A Coruna")
local Barcelona = findCityByName("Barcelona")
local Bilbao = findCityByName("Bilbao")
local Cadiz = findCityByName("Cadiz")
local Cartagena = findCityByName("Cartagena")
local Gijon = findCityByName("Gijón")
local Madrid = findCityByName("Madrid")
local Malaga = findCityByName("Málaga")
local Sevilla = findCityByName("Sevilla")
local Valencia = findCityByName("Valencia")
local Valladolid = findCityByName("Valladolid")
local Zaragoza = findCityByName("Zaragoza")
local spanishUnitTypesToBeDestroyed = {
	findUnitTypeByName("Blake"),
	findUnitTypeByName("Cuesta"),
	findUnitTypeByName("S. Line Infantry"),
	findUnitTypeByName("S. Light Infantry"),
	findUnitTypeByName("Guerrilla"),
	findUnitTypeByName("S. Line Cavalry"),
	findUnitTypeByName("S. Foot Artillery"),
	findUnitTypeByName("Village")
}

-- Ottoman:
local Ankara = findCityByName("Ankara")
local Bucuresti = findCityByName("Bucuresti")
local Istanbul = findCityByName("Istanbul")
local ottomanUnitTypesToBeDestroyed = {
	findUnitTypeByName("O. Provincial"),
	findUnitTypeByName("O. Janissaries"),
	findUnitTypeByName("O. Nezam-I Cedid"),
	findUnitTypeByName("O. Mameluke"),
	findUnitTypeByName("O. Sipahi"),
	findUnitTypeByName("O. Artillery")
}

-- England:
local Birmingham = findCityByName("Birmingham")
local Bristol = findCityByName("Bristol")
local Liverpool = findCityByName("Liverpool")
local London = findCityByName("London")
-- English Portugal:
local Lagos = findCityByName("Lagos")
local Lisboa = findCityByName("Lisboa")
local Oporto = findCityByName("Oporto")

-- Cities on Map 1:
-- German Minors:
local Bavaria = findCityByName("Bavaria")
local Rhineland = findCityByName("Rhineland")
local Westphalia = findCityByName("Westphalia")
local Wurtemburg = findCityByName("Würtemberg")
local germanMinorUnitTypesToBeDestroyed = {
	findUnitTypeByName("Bavarian Infantry"),
	findUnitTypeByName("Bavarian Cavalry"),
	findUnitTypeByName("Rhine Infantry"),
	findUnitTypeByName("Westphalian Infantry"),
	findUnitTypeByName("Westphalian Cavalry"),
	findUnitTypeByName("Würtemberg Infantry")
}

-- Baltic Minors:
local Denmark = findCityByName("Denmark")
local Kobenhavn = findCityByName("Kobenhavn")
local danesMinorUnitTypesToBeDestroyed = {
	findUnitTypeByName("Danish Infantry"),
	findUnitTypeByName("Danish Cavalry")
}

local polishMinorUnitTypesToBeDestroyed = {
	findUnitTypeByName("Polish Infantry"),
	findUnitTypeByName("Polish Lancers")
}

-- Italian Minors:
local KofNaples = findCityByName("K. of Naples")
local naplesMinorUnitTypesToBeDestroyed = {
	findUnitTypeByName("Murat"),
	findUnitTypeByName("Neapolitan Infantry")
}
-- Western Minors:
local UnitedProvinces = findCityByName("United Province")
local dutchMinorUnitTypesToBeDestroyed = {
	findUnitTypeByName("Dutch Infantry"),
	findUnitTypeByName("Dutch Cavalry")
}

local projectilesToBeDestroyedEachTurn = {
	findUnitTypeByName("DO NOT USE"),
	findUnitTypeByName("6 pdr Shells"),
	findUnitTypeByName("8 pdr Shells"),
	findUnitTypeByName("12 pdr Shells"),
	findUnitTypeByName("Bombard Shells"),
	findUnitTypeByName("18 pdr Shells"),
	findUnitTypeByName("24 pdr Shells"),
	findUnitTypeByName("32 pdr Shells")
	-- Note: any accidentely built 'DO NOT USE' unit (formely known as the 'Constabulary') gets eliminated at the end of each turn
	-- Note: Unused Mortar Shells DO NOT get eliminated at the end of each turn
	-- Note: All projectiles are only eliminated at the end of each turn if owned by France
}

local baseUnitAttack = { }
for i = 0, civ.cosmic.numberOfUnitTypes - 1 do
	baseUnitAttack[i] = civ.getUnitType(i).attack
end


-- •••••••••• Scenario Text: ••••••••••••••••••••••••••••••••••••••••••••••••••
local scenText = { }

scenText.summerOneText =
[[IMPORTANT COMMUNIQUE: SUMMER FILE CHANGES (use bat file ONE)
^
Summer has returned and all belligerents are likely to renew
their land and naval operations with vigour.
^
Save the game, Exit ToT, and run the "Napoleon_ONE.bat" file.
Select option 2, "Summer" and reload the game.]]

scenText.summerTwoText =
[[IMPORTANT COMMUNIQUE: SUMMER FILE CHANGES (use bat file TWO)
^
Summer has returned and all belligerents are likely to renew
their land and naval operations with vigour.
^
Save the game, Exit ToT, and run the "Napoleon_TWO.bat" file.
Select option 1, "Summer" and reload the game.]]

scenText.winterOneText =
[[IMPORTANT COMMUNIQUE: WINTER FILE CHANGES (use bat file ONE)
^
Winter has arrived and for most areas on the European continent,
the inclement weather will hinder the movement of your land and
naval units.
^
In addition, any land or naval unit, save leaders and Train
Militaire, that doesn't begin the turn in a city/port during
the winter months will be subject to winter attrition.
^
This penalty does not apply to ground units located in
Temperate terrain tiles, except the Iberian Peninsula.
^
Save the game, Exit ToT, and run the "Napoleon_ONE.bat" file.
Select option 3, "Winter" and reload the game.]]

scenText.winterTwoText =
[[IMPORTANT COMMUNIQUE: WINTER FILE CHANGES (use bat file TWO)
^
Winter has arrived and for most areas on the European continent,
the inclement weather will hinder the movement of your land and
naval units.
^
In addition, any land or naval unit, save leaders and Train
Militaire, that doesn't begin the turn in a city/port during
the winter months will be subject to winter attrition.
^
This penalty does not apply to ground units located in
Temperate terrain tiles, except the Iberian Peninsula.
^
Save the game, Exit ToT, and run the "Napoleon_TWO.bat" file.
Select option 2, "Winter" and reload the game.]]

scenText.introText1 =
[[***************  France - August 15, 1805  ***************
^
Emperor Napoléon, England together with Austria and Russia have formed the Third Coalition, an alliance seeking to depose you and dismember the French Empire!
^
England, under King George III, remains your greatest foe and has vowed to pursue the war with you until your regime is overturned and it sees the legitimate Bourbon king restored. Your only recourse to overcome this adversary would be to subdue it but to do so would require you to invade that island nation and capture its major urban centers of London, Birmingham, Bristol and Liverpool.
^
You may also attempt to foment trouble in Ireland by raiding British garrisons located there. Each destroyed British ground unit will see the emergence of a local Irish resistance cell on that island...
]]

scenText.introText2_a =
[[Unfortunately, before you can make any invasion plans you would need to establish naval supremacy over the Royal Navy and to accomplish this feat, you would be required to eliminate 20 British naval units, without losing more than 9 of your own, prior to January 1808, otherwise British naval strength will simply become too great for you to overcome.
^
Gaining naval supremacy would give you access to the advance which would allow you to build naval Transport units. However, failure to accomplish this mission by the specified date will forever prevent you from accessing that technology, as your Continental obligations will come to occupy all your diplomatic and military resources.
^
Reseaching the 'New Naval Base' advance will not only create a Naval Base improvement in Toulon but provide you with the opportunity to activate two half-strength reserve naval squadrons in Marseille, though you might only want to consider this a priority if you are committed to establishing naval supremacy...
]]

scenText.introText2_b =
[[In parallel, as the primary backer of the present and possible future coalitions against your Empire, you will want to weaken England's economic position by imposing a Continental Blockade on its imports into Europe. To achieve this goal, you will need to control 11 of the 12 major European trade ports (easily identified on the map by the label "Port" next to the coastal cities in question).
^
Each trade "Port" serves as a supply base that allows the British to fund additional forces to any Coalition power when they are at war with you. Capturing the ports in question will prevent the British from doing so. 
^
In addition, controlling all the ports will severely curtail the lucrative trade that helps fill the coffers of the English treasury...
]]

scenText.introText2_c =
[[On the other hand, don't expect the Royal Navy to be passive while you scheme to overturn its dominance on the high seas, as it intends to pursue its own maritime strategy to strangle the French economy.
^
As such it has set up separate naval blockade zones around the ports of Amsterdam, Le Havre, Brest, La Rochelle / Bordeaux, Toulon / Marseille and Napoli in order to prevent foreign vessels from entering French waters to trade with your Empire. 
^
Thus, at the beginning of every month, 15 francs will be subtracted from the French treasury for EACH English vessel located in these sea zones. 
^
When at war with France, each Russian and Spanish vessel located in these waters will also participate in the British blockade effort and therefore be added to the overall economic penalty inflicted on your nation.
^
As you make your plans, beware, for maintaining a large navy can be an expensive endeavor as each vessel in your fleet requires a monthly maintenance fee which is subtracted from the national treasury...
]]

scenText.introText3 =
[[Austria, as a member of the anti-French coalition, has deployed large forces in Bavaria and northern Italy in the hopes of reversing the terms imposed on it by the treaties of Campo Formio and Lunéville. In response, you have swiftly deployed, under your command, the Grande Armée into eastern France and the Army of Italy under Maréchal Jean Lannes in the cities of Milano and Firenze.
^
Austria's resolve can be broken if you can strike at the enemy's heart by capturing Wien, Prag and Venezia. Should you accomplish your objective you can compel it to sign a peace treaty that will bring about the dissolution of the thousand-year-old Holy Roman Empire and allow you to establish the Confederation of the Rhine. The Confederation will serve as a military, economic and diplomatic buffer between your empires.
^
The initial members of the Confederation would consist of the minor German states of Bavaria (Ba), Rhineland (Rh) and Würtemberg (Wü). Each minor, under your protectorate, would provide yearly infantry and calvary regiments to bolster the overall armed forces under your command....]]

scenText.introText4 =
[[As a member of the Third Coalition and fierce defender of the God-given right of a legitimate monarch to rule, the Russian Empire of Tsar Alexander I is mobilizing forces to join its Austrian ally to reverse the abomination that your rule represents, but it will take some months before its troops reach the front.
^
As such, the quicker you strike at Austria and overrun its aforementioned cities the better.
^
A foray into southern Italy could allow you to nab the Kingdom of Naples (Na) which is currently an English protectorate and a possible source of enemy activity but also a potential minor ally of your own.
^
In addition, the capture of that kingdom would permit you to build a 'sea' route to the island of Corfu, whose port serves as an active base of operations for the Russian navy in the Mediterranean. 
^
The capture of Corfu would not only quash Russian naval actions in the area but allow you to establish a lucrative trading post with the Ottoman Sultanate... 
]]

scenText.introText5 =
[[Prussia is currently neutral and as long as peace exists between your two empires, your troops are forbidden from entering Prussian territory.
^
On the other hand, your agents report that the ruling elite of that nation is growing increasingly hostile to France's continuing encroachment into what it deems to be exclusively German affairs, and therefore is placing increasing pressure on its monarch, Frederick William III, to declare war on France. As a consequence you should be wary of any potential intervention on its part.
^
Should that kingdom begin hostilities against you, you will be presented with a golden opportunity to dismantle Prussia's political control over the German states of Saxony, Hanover and especially Westphalia (We), which could be swayed to become a member of the Rhine Confederation...
]]

scenText.introText6 =
[[Finally, the feeble King Ferdinand VII of Spain has allied his nation to your cause, but it remains a very tenuous alliance. The Catholic clergy, who controls the peasantry, is fiercely opposed to the ideals of the French Revolution, which threatens their position of power. For its part, the ruling class increasingly resents French pressure to curtail its trade with England, which serves as its main source of revenue.
^
As such, if you wish to solidify your alliance with the Spanish kingdom, you will need to complete certain objectives over the next couple of years; otherwise it will inexorably drift into the anti-French camp.
^
As part of the conditions, you must establish naval supremacy over the Royal Navy in order to secure the waters around Spain. You must prevent the British from capturing more than one Spanish city. And finally, you must seize control of all the cities of Portugual, which is England's staunchest minor ally on the continent, without deploying more than 60,000 troops in the Iberian Peninsula. All these conditions must be met prior to January 1808.
]]

scenText.introGameTip1 =
[[****************  GAME TIPS - French Artillery and Shells  ****************
^
The following French artillery units have the ability to generate
munition type units when they are active by pressing on the "k" key.
^
Artillery units:
^Art. à Cheval = costs 1 MP and 3 francs to generate one 6 pdr Shells
^Art. à pied 8lb = costs 1 MP and 4 francs to generate one 8 pdr Shells
^Art. à pied 12lb = costs 1 MP and 6 francs to generate one 12 pdr Shells
^Mortier de 12po. = costs all MP and 9 francs to generate one Mortar Shells
^
Note:
^As long as you have at least half a movement point remaining, and the
^necessary funds, you should be able to generate at least one munition.
^
All artillery munitions, save for Mortar Shells, that are unused at
the end of a turn are automatically eliminated.
^
In addition, Mortier de 12po. units may only generate Mortar Shells
if they are located on a tile that contains a Siege Works (aka Airbase),
which can only be built by French Sapeurs units.
]]

scenText.introGameTip2a =
[[*********************  GAME TIPS - French Leader Bonuses  *********************
^
The following French leaders provide a specific bonus to units that are attacking out of the same tile they are currently occupying:
^
^French Army Leaders:
Napoléon = 50% attack bonus to all infantry, shells and mortar units
^Davout = 20% attack bonus to all infantry and shells units
^Lannes = 30% attack bonus to all infantry and shells and mortar units
^Soult = 20% attack bonus to all infantry and shells units
^Murat = 30% attack bonus to all cavalry units
^
^Polish Army Leader:
^Poniatowski = 20% attack bonus to all infantry and shells units
^
^Naval Leader:
^Villeneuve = 20% attack bonus to all naval 18, 24 and 32 pdr Shells
^
^Note: Shells means 6, 8 and 12 pdr Shells (excluding naval 18, 24 and 32 pdr Shells )
^Note: Leader bonuses are not cumulative.
]]

scenText.introGameTip2b =
[[*************  GAME TIPS - French Leader Bonuses Application  *************
^
The eligible leaders bonuses apply under the following conditions:
^
^* If the unit starts and attacks from the same non-city tile as the leader,
^it will get the bonus provided it is eligible.
^
^* If the unit moves to a non-city tile that contains a leader, you must reselect
^the tile first before attacking for the eligible bonus to take effect.
^
^* If the unit starts in the same non-city tile as a leader but moves to
^a different tile without a leader it will still benefit from the leader
^bonus provided you don't reselect the tile before attacking.
^
^* If the unit starts or moves to a city tile that contains a leader, you
^must wait for the game to cycle to that unit for the bonus to take effect.
^
^NOTE:
^You can always verify if the leader bonus has been added to a unit by checking
^its stats in the Military Units section of the Civilopedia prior to attacking
^OR
^by pressing the TAB key of your keyboard which will bring up the HELP screen
^that provides all of a unit's statistics.
]]

scenText.introGameTip3 =
[[***********  GAME TIPS - French Hussars ***********
^
You begin the game with one French "Hussars" unit located in the city of Strasbourg.
^
Hussars play a vital reconnaissance role for your army as they possess the spy's "Investigate City" ability.
^
As the game progresses and you complete certain objectives you may receive extra such units.
]]

scenText.introGameTip4 =
[[**********  GAME TIPS - L'Élan Napoléonien  **********
^
France starts with the "L'Élan Napoléonien" wonder which gives the Veteran status to all newly produced ground units, or to those
that win a battle.
^
These benefits will only last as long as France doesn't lose more than 44 French regimental or naval units of all types 
(Gendarmes, infantry, artillery, cavalry, Imperial Guard or naval ships).
^
Should it lose 100 or more, then its Régiment de Ligne, Infanterie Légère and Carabiniers units will no longer benefit from 
the 'Ignore zones of control' attribute they begin the war with.
]]

scenText.introGameTip5_a =
[[*******************  GAME TIPS - French Vessels and Naval Shells  *******************
^
The following French naval units have the ability to generate munition
type units when they are active by pressing on the "k" key.
^
Naval units:
^Frégate = costs all of the ship's MP and 4 francs to generate one 18 pdr Shells
^Deux-ponts = costs all of the ship's MP and 5 francs to generate one 24 pdr Shells
^Trois-ponts = costs all of the ship's MP and 9 francs to generate one 32 pdr Shells
^Villeneuve = costs all of the ship's MP and 9 francs to generate one 32 pdr Shells
^Bombarde = costs 1/2 of the ship's MP and 9 francs to generate one Bombarde Shells
^
Note:
^As long as you have at least half a movement point remaining, and the necessary funds,
^you should be able to generate at least one munition.
^
All naval munitions that are unused at the end of a turn are automatically eliminated.
]]

scenText.introGameTip5_b =
[[*************  GAME TIPS - French Vessels Maintenance Costs  *************
^
^Navies have always been very expensive to maintain and operate and therefore 
^very few nations have historically been able to afford to deploy large fleets.
^
^To reflect this reality, each French vessel has an associated maintenance cost 
^which is subtracted from the French treasury at the beginning of each month:
^
Frégate = each unit costs 3 francs per turn to maintain
^Deux-ponts = each unit costs 6 francs per turn to maintain
^Trois-ponts = each unit costs 10 francs per turn to maintain
^Bombarde = each unit costs 8 francs per turn to maintain
^Transport = each unit costs 6 francs per turn to maintain
^
^Villeneuve = costs 12 francs per turn to maintain
^
There are no penalties, per se, applied to the French vessels for not having
the sufficient funds to pay for them, but it should be noted that these costs
are subtracted before those of the Train Militaire, which could increase the risk
of seeing some of these units being disbanded. 
^
Of course, there is always the additional risk of seeing your city improvements 
sold, as part of a fire sale, should the treasury ever fall below zero.
]]

scenText.introGameTip6 =
[[**************  GAME TIPS - Napoléon's Administrative Bonuses  **************
^
^In addition to his battlefield leadership qualities, the Emperor was also an
^excellent administrator, legislator and military organizer.
^
^As such, whenever Napoléon is in Paris you may opt, by pressing once on the "k" 
^key, to either:
^- Generate an extra 200 francs for the treasury and add 100 science beakers to  
^  the current research project, OR 
^- Recruit 2 new veteran Régiment de Ligne units at a cost of 600 francs 
^
Be aware that you may only benefit from this administrative bonus once per turn...
]]

scenText.introGameTip7 =
[[*********  GAME TIPS - Other French Leaders Administrative Bonuses  *********
^
^The following French leaders also possess administrative bonuses, which allows 
^them each to purchase one unit per turn by pressing on the 'k' key:
^
^Whenever Murat is located in Hanover he may purchase one of the following:   
^- Veteran Cuirassiers for 500 francs
^- Veteran Lanciers for 450 francs
^
^Whenever Davout, Lannes or Soult are located in Strasbourg or Toulouse they   
^may each purchase one of the following units:
^- Regular Régiment de Ligne for 200 francs 
^- Veteran Infanterie Légère for 260 francs 
]]

scenText.introGameTip8 =
[[*********  GAME TIPS - Trade Units and Revenue Improvements  *********
^
^There are no trade or settler (save French Sapeurs) type units in the game, 
^and as such trade and tile improvement activities are not possible (note 
^that "Sapeurs" are only permitted to build Siege Works (aka Airbase)).
^
On the other hand, certain cities already begin the scenario with established trade routes and pre-built farm tiles.
^
You can always increase your revenue base by building extra "Banks" and the "Great Market" improvement (after researching the Economics advance).
^
Finally, once you've discovered Intensive Farming, you can improve the yield of your farm tiles by building the "Grain Farm" improvement.
]]

scenText.introGameTip9 =
[[********  GAME TIPS - Coalition Core Cities  ********
^
Though you have the option to re-home any of your French units to any city on the European map, it's inadvisible to home them to core Austrian or Prussian cities. These cities are easily distinguishable by the '"c"' located to the right of their names.
^
This is because, after a surrender, these cities can be reassigned back to their original owner's control as part of a peace treaty they sign with France, and therefore you could lose control of any of your units which had been homed in them.
]]

scenText.introGameTip10 =
[[******************  GAME TIPS - Seasonal Attrition Penalties  ******************
^
^During winter months, all French ground units that are not located in a city/port 
^are subject to the effects of attrition, which translates into the loss of hit points. 
^French ground units also suffer attrition during summer months if located in the 
^Iberian Peninsula or within Russia proper.
^
During summer and winter months, all French naval units are subject to attrition rates of 0-10% and 10-20% respectively when not located in a city/port. This is to represents the general lack of sufficient naval maintenance facilities in France at the time.
^
The number of hit points lost can vary from one unit to another and from one month to the other. A unit can be eliminated if, at the moment that attrition takes effect, it has insufficient hit points remaining to cover the loss. Units lost through attrition are NOT regenerated.
^
Once you've discovered the Supply Logistics advance, you may build Train Militaire units which can help to heal your wounded ground units. Be forwarned that each unit costs 15 francs per turn to maintain and failure to have the sufficient funds could see some of them get disbanded.
^
Finally, given the rougher sea conditions in winter, your naval units cannot use the 18, 24 or 32 pdr Shells they generate to attack enemy ground units. They may still be used to attack other naval units at sea.
]]

scenText.introGameTip11 =
[[*******************  GAME TIPS - Message Boards  *******************
^
^You may, at any time, access the status of France's Foreign Relations 
^with the other powers by pressing on the 'F3' key.
^
You may, at any time, get a report of the leaders that have perished on the battlefield by pressing on the 'Backspace' key. 
^
You may, at any time, access the Empire Wide Status Report board by pressing on the '1' key. 
^
You may, at any time, access the current Allied Embargo of French Ports board by pressing on the '2' key. 
^
You may, at any time, access the French Minor Powers Activation Conditions board by pressing on the '3' key. 
^
You may, at any time, access the Coalition Wars Victory Conditions board by pressing on the '4' key. 
^
You may, at any time, access the General Game Tips 1 Information board by pressing on the '5' key. 
^
You may, at any time, access the General Game Tips 2 Information board by pressing on the '6' key. 
]]

scenText.introGameTip12 =
[[************  GAME TIPS - Automatic French Victory  ************
^
^If you capture 11 objective cities and manage to hold on to them till 
^the next turn you will have achieved an Automatic Decisive Victory.
^
These cities are easily identified on the map by the three red asterisks located next to their name and they include the following:
^
Cadiz, Danzig, Hanover, Istanbul, Leipzig, Lisboa, London, Madrid, Moskva, Paris, Sankt-Peterburg, Venezia and Warszawa.
^
As a consequence, the game will end and you will be proclaimed ruler of Europe!
]]

scenText.introGameTip13 =
[[*****************  GAME TIPS - Siege Warfare Technology  *****************
^
^You have discovered the Siege Warfare technology, which leads to both the
^Siege Engines and Siege Vessels advances. The Siege Warfare advance 
^allows you to build the Siege Workshop city improvement.
^
^The Siege Engines advances will allow you to build the Mortier de 12po  
^and Sapeurs units, whereas the Siege Vessels advance will permit the  
^construction of the Bombarde ships.
^
^You may only build the Mortier de 12po unit in French cities that contain both 
^a Cannon Foundry and Siege Workshop improvement. The Sapeur requires  
^a city that contains a Recruitment Center along with a Siege Workshop 
^improvement.
^
^You may only build the Bombarde vessel in French cities that contain both
^a Dockyard and Siege Workshop improvement.
]]

scenText.introGameTip14 =
[[***************  GAME TIPS - French Privateers  ***************
^
^The French ministry of the navy has granted letters of marque 
^to private naval captain(s) of France. This empowers the holder 
^to carry out all forms of hostile acts permissble at sea, including 
^attacking foreign vessels and taking them as prizes.
^
As such, at the beginning of every month, each French vessel located in the sea
zone 7, situated near the Egyptian ports of Al-Iskandariyah and Dumyat, will add
15 francs to the French treasury.
^ 
Though be wary as the English navy is known to send naval squadrons to patrol these 
waters.
]]

scenText.introGameTip15 =
[[**************  GAME TIPS - Special Map Transit Points  **************
^
^All French ground units* may use the following transit tiles:  
^ - Between tile 84,30 and 88,30 to access the island of Kobenhaven
^ - Between tiles 109,105 and 115,109 to access the island of Corfu**
^
^* Does not include Gendarmes
^** Provided you have built the 'sea' route on the 'European Powers' map.
]]

scenText.introGameTip16 =
[[***********  GAME TIPS - French Garrison Duties East ***********
^
^France will be required to keep garrison forces* under the following 
^conditions: 
^
^ - After defeating Prussia in war of 4th Coalition:
^   Maintain a garrison of 125,000 troops (25 ground units) within the 
^   Eastern Prussia Zone (delimited by the light brown *), as long as
^   France is at peace with Russia.
^   Each month that you fail to maintain the minimum garrison will cost
^   the French treasury 25 francs. 
^
^ - After subduing Russia in the invasion of Russia:
^   Maintain a garrison of 200,000 troops (40 ground units) within the 
^   borders of Russia.
^   Each month that you fail to maintain the minimum garrison will cost
^   the French treasury 50 francs.
^
^* Does not include leaders or naval units
]]

scenText.introGameTip17 =
[[*****************  GAME TIPS - Sea Route to Corfu  *****************
^
^The capture of the kingdom of Napoli will permit you to build a 'sea' 
^route on the 'European Powers' map between the cities of Taranto  
^and Corfu, the latter of which serves as a base of operations for the  
^Russian navy in the Mediterranean and which could become a     
^lucrative trading post with the Ottoman Sultanate for France.
^
^To build the route, you simply need to have one of you marshalls,
^Davout, Lannes or Soult, located in the city of Taranto and press
^on the 'u' key and a pop up window will appear giving you the option
^to establish the route for 100 francs. You can establish the route
^at any time and once created it will be permanent.
^
^This 'European Powers' map sea route will be accessible from tile
^109,105 located just south-east of Taranto.
]]

scenText.introGameTip18 =
[[***********  GAME TIPS - French Garrison Duties West  ***********
^
^France will be required to keep garrison forces* under the following 
^conditions: 
^
^ - After subduing England:
^   Maintain a garrison of 75,000 troops (15 ground units) within the 
^   British Isles.
^   Each month that you fail to maintain the minimum garrison will cost
^   the French treasury 75 francs. 
^
^ - After subduing Spain in the Peninsula war:
^   Maintain a garrison of 130,000 troops (30 ground units) within the 
^   Iberian Peninsula.
^   Each month that you fail to maintain the minimum garrison will cost
^   the French treasury 35 francs.
^
^* Does not include leaders or naval units
]]

scenText.introGameTip19 =
[[*****************  GAME TIPS - Barbary Pirates  *****************
^
^After England researches the ‘British Royal Marines’ advance it 
^will begin ‘funding’ Barbary Pirates out of the city of Algiers.
^
^These ‘pirates’ (aka Coalition Shells) will launch periodic coastal  
^raids along the French Mediterranean and Italian coasts. 
^
^Once begun, your only have 2 ways to bring an end to this activity. 
^Either subdue England or to launch a punitive raid against the pirate 
^city and destroy the minor fort installation protecting it. 
^
^Do not attempt to launch a punitive raid prior to the pirates being 
^activated otherwise you will forfeit the ability to cancel these raids.
]]

scenText.researchInfrastructure =
[[*********** France Researches Infrastructure Advance!  ***********
^
^Emperor Napoléon, your minister of War, Louis-Alexandre Berthier, has 
^been working on plans to improve the nation's infrastructure and as 
^such if you research the following technologies you will be rewarded 
^for your efforts.
^
^Extra Constabulary: will provide a new Constabulary improvement
^in the city of Reims, which will not only allow you to build extra
^Gendarmes but immediately add 2 new ones to your forces.		
^
^Extra Military Academy: will provide a new academy in the city of
^Marseille, which will not only allow you to train veteran units, 
^but immediately add one veteran Cuirassiers and one Lanciers to 
^your cavalry force.
^
^Extra Train Militaire: will see one extra Train Militaire unit generated
^at your option in one of the following cities: Bayonne, Milano, Leipzig 
^or Paris 
]]

scenText.researchNewNavalBase =
[[**************** France Researches New Naval Base!  ****************
^
^Emperor Napoléon, your minister of War, Louis-Alexandre Berthier, has 
^been working on plans to improve the nation's infrastructure and as 
^such if you research the New Naval Base technology you will be  
^rewarded for your efforts.
^
^New Naval Base: will provide a new Naval Base in the city of Toulon,
^which will allow you to build veteran naval units.
^
^In addition, for 350 extra francs you will be presented with a one time 
^opportunity to recruit two half strentgh reserve naval squadrons, one 
^Trois-ponts and one Deux-ponts in the city of Marseille.
^
^Failure to have the funds, at the time, will forfeit your ability to enlist 
^these naval squadrons.
]]

scenText.impHQDispatch_Hanover =
[[**********  Imperial Headquarters Dispatch  **********
^
Your Majesty, your forces have captured the important German objective city of Hanover, which also happens to be a fertile region for the breeding and raising of horses.
^
As such, as your leading expert in the matter, whenever Maréchal Murat is located in that city he will have the option to buy horses to equip your cavalry arm.
^
By pressing on the "k" key, he will be able to purchase on your behalf stallions to equip either a veteran regiment of Cuirassiers for 500 francs, or Lanciers for 450 francs.
^
NOTE: Should the Maréchal succumb on the battlefield you will have forfeited his ability to recruit horses.
]]

scenText.impHQDispatch_DefeatedAustria_3rdCoalition_p1 =
[[*****  Austria Defeated in War of Third Coalition  *****
^
Your Majesty, you have successfully defeated the Austrian army on the battlefield.
^
In order to avoid further bloodshed, Francis II of Austria agrees to sign the peace treaty of Pressburg with you and as such all hostilities between your two nations cease. 
^
As a consequence, all Austrian troops return to their barracks and the Emperor agrees to pay France a war indemnity of 800 francs.
^
Though unable to preserve his ally, Tsar Alexander I of Russia vows to continue the struggle against France...
]]

scenText.impHQDispatch_DefeatedAustria_3rdCoalition_p2 =
[[As part of the treaty, France agrees to return control of the following core cities to Austria: Agram, Budapest, Debrecen, Graz, Kosice, Krakow, Lemberg, Olmütz, Pécs, Prag, Temeschwar, Trieste and Wien.
^
Therefore France has one turn to evacuate its troops from these cities, otherwise they will be disbanded to conform to your treaty obligations (the cities are easily identified by the letter "c" or "!c" located to the right of their names).
^
In exchange, if your troops haven't already captured them, Austria cedes the Italian cities of Ancona and Verona to you.
^
France will post border guards along the Austrian, Italian and Bavarian frontiers to control the vital communication routes into these areas....
]]

scenText.impHQDispatch_DefeatedAustria_3rdCoalition_p3 =
[[Finally, Francis II agrees to relinquish the title of Emperor of the Holy Roman Empire, the institution of which is formally abolished and will henceforth only be known as Emperor Francis I of Austria.
^
In its stead and at your instructions, your Minister of Foreign Affairs Charles Maurice de Talleyrand, sets up the Confederation of the Rhine, which comprises the German minor states of Bavaria (Ba), Rhineland (Rh) and Würtemberg (Wü).
^
These three minor powers immediately agree to put their current contingents of infantry and cavalry regiments at your disposal.
]]

scenText.impHQDispatch_Prussia_Declare_War_4thCoalition =
[[*****  Prussia Declares war of Fourth Coalition  *****
^
Emperor Napoléon, gravely concerned by your encroachment in German affairs and because of pressure from within the Prussian court which sees France as an ever growing threat, Frederick Wilhelm III declares war on France. Tsar Alexander I of Russia pledges his support to the Prussian state.
^
To defeat Prussia and compel it to sign a peace treaty you will have to capture the cities of Berlin, Dresden, Königsberg, Lublin, Magdeburg, Münster, Thorn and Warszawa (all the cities with a light blue "x"). 
^
In addition, it is highly recommended you capture the cities of Küstrin and Posen to secure the strategic Küstrin - Posen - Thorn road network that would allow your forces to easily transit between the Rhine and the Polish-Russian borders.
^
Finally, the kingdom of Denmark (De) has advised your Foreign minister that the capture of Lübeck and Straslund would be seen as a favorable condition for it to join the pro-French camp.
]]

scenText.impHQDispatch_DefeatedPrussia_4thCoalition_p1 =
[[*****  Prussia Defeated in War of Fourth Coalition  *****
^
Emperor Napoléon, now that you have defeated your Prussian and Russian enemies on the battlefield you are able to compel them to sign the peace Treaty of Tilsit.
^
As such, you first meet on the river Niemen, under much pomp and ceremony, with your Russian counterpart Tsar Alexander I to discuss the terms.
^
The Tsar agrees to end all hostilities between your two nations and in exchange for this peace accord Russia will join the Continental Blockade and close their ports to British vessels and their trade, at great economic cost to both of them.
^
As a consequence, all Russian troops still located in Eastern Prussia or the confines of the Duchy of Warsaw will be withdrawn next month...
]]

scenText.impHQDispatch_DefeatedPrussia_4thCoalition_p2 =
[[Two days later, you meet Frederick Wilhelm III who agrees to return all his troops to their barracks and to pay France a war indemnity of 1000 francs.
^
France agrees to return control of the following core (c) cities to Prussia: Berlin, Breslau, Königsberg and Stettin.
^
Therefore France has one turn to evacuate its troops from these cities, otherwise they will be disbanded to conform to your treaty obligations.
^
Now that you have defeated your enemies of the Third and Fourth Coalition and signed peace treaties with them, you've established a certain degree of order in Europe...
]]

scenText.impHQDispatch_DefeatedPrussia_4thCoalition_p3 =
[[As a result, France will post border guards along the Austrian, Prussian and Russian fronts to ensure control of the vital communication routes within the Prussian state.
^
Furthermore, to enforce the peace and ensure that Prussia, and Russia, abide by the treaty obligations, which includes supporting the Continental Blockade, France will need to maintain a garrison force of 125,000 combat troops (25 units) in eastern Prussia and the Duchy of Poland.
^
Failure to preserve this minimum garrision force, will cost the French treasury 25 francs each month as Prussian traders seek to pass their goods as contraband to the far more lucrative British trade.
]]

 scenText.impHQDispatch_InvasionPortugal_p1 =
[[*******  Portugal in Defiance of French Edicts  *******
^
Portugal, which remains England's staunchest ally on the continent, has been serving as a base of operations for the British army in the Peninsula and thereby has been destabilizing your alliance with Spain, which is fragile to begin with.
^
In addition, the royal family under Queen Maria I and Prince Regent John, continues to defy your Continental Blockade edicts by trading with that island nation.
^
In order to resolve the issue, you've brought pressure to bear on the Spanish court to open its borders to a contingent of your troops...
]]

 scenText.impHQDispatch_InvasionPortugal_p2 =
[[Therefore, if you so choose, you can seize this opportunity to deal with the situation before it gets out of hand and transit your army through Spain to seize all the Portuguese cities.
^
By the terms of your agreement with King Ferdinand, whose court remains suspicious of your ultimate motives, you may not have a force greater than 60,000 men in Spain or Portugal combined (12 units (excludes leaders or Plunder unit in the count)).
^
You may decide to exceed this force limit but failure to comply with this Spanish demand will irrevocably compromise your alliance with that nation.
^
Furthermore, be aware that the Iberian Peninsula is a fairly poor region ill suited to supporting large scale armies and its inhabitants generally possess a hostile attitude towards France. This will render your forces more suceptible to attrition, as keeping them supplied will prove to be a challenge for your army's quartermasters.
]]

scenText.impHQDispatch_France_Invades_England =
[[************  France Invades England!  ************
^
Emperor Napoléon, you have launched your first invasion of the British Isles in the atttempt to subdue that nation. If you are able to capture its major urban centers of London, Birmingham, Bristol and Liverpool (easily identified by the pink "x" next to their names), you will compel the British government to permanently sue for peace.
^
Your agents confirm that the English have raised a sizable force in response with the goal of throwing your forces back into the sea. 
^
All British forces, normally slated for the Iberian Peninsula will be redirected to the defense of their homeland, as long as you have a force of 20,000 troops (4 units) or more in the island.
^
The Russian ambassador has transmitted, on behalf of the Tsar, a letter of protest for this latest French provocation and warned your minister that his government is reviewing all its possible options. You should heed this warning seriously!
]]

scenText.impHQDispatch_Defeated_England_p1 =
[[******  England Signs Peace Treaty of Amiens!  ******
^
Emperor Napoléon, you have successfully invaded and subdued England. In order to avoid further bloodshed, King George III agrees to sign the peace treaty of Amiens with you.
^
As a consequence, all hostilies between your two nations will cease for the remainder of the war and England agrees to pay you a war indenmity of 2000 francs.
^
Britain will withdraw all its forces from the Iberian peninsula and compel Portugal to open all its cities to your control and surrender its armed forces to you. The Portuguese are required to provide you with 2 infantry divisions to maintain law and order in Lisboa. Finally, any city it may control in Spain will be returned to Spanish control.
^
To ensure that England abides by the terms of the treaty you will need to maintain a garrison force of at least 75,000 troops (15 units) in that country. Failure to do so will cost the French treasury 75 francs each month you fail to have the minimum force in place.
]]

 scenText.impHQDispatch_Failed_Establish_Supremacy =
[[******  Royal Navy Maintains Naval Supremacy  ******
^
Emperor Napoléon, you have failed to meet your objective of establishing maritime supremacy over the Royal Navy by the prescibed date of January 1808.
^
As a consequence, you have forfeited the opportunity to gain the Naval Transport advance for the remainder of the war.
]]

 scenText.impHQDispatch_Spain_Leaves_Alliance_p1 =
[[************  Spain Joins Allied Coalition  ************
^
Emperor Napoléon, despite your best efforts, you have failed to secure your alliance with Spain.
^
Your brazen move to depose their beloved King Ferdinand VII, in favour of your brother Joseph, has pushed the peasantry, already spurred on by the Catholic clergy of that country to reject your attempts to import the ideals of the Revolution, to revolt against your forces.
^
The nobility, which resented your attempts to force them to abide by the Continental blockade, along with the Spanish military have joined them.
^
As such, you are no longer bound by your previous agreement to limit your intervention force to only 60,000 troops.
^
This promises to be a different kind of war, one that can only be resolved if you manage to capture the major Spanish centers of resistance to your rule...
]]

scenText.impHQDispatch_Ottoman_Russian_War =
[[****  Ottoman Sultanate Declares War on Russia  ****
^
Encouraged by the Austro-Russian defeat in the War of the Third Coalition, the Sultan of the Ottoman Empire, Sultan Selim III, has deposed the pro-Russian Constantine Ypsilanti as Hospodar of the Principality of Wallachia and Alexander Mourousis as Hospodar of Moldavia, both Ottoman vassal states.
^
In response Tsar Alexander I has ordered his generals to prepare an invasion of these two regions. The Sultan has promptly decided to block the Dardanelles to Russian ships and has declared war on Russia.
]]

scenText.impHQDispatch_LElan_Wonder_Nullified =
[[*******  L'Élan Napoléonien Wonder Cancelled  *******
^
Your Majesty, the many years of conflict since the French Revolution have begun to take their toll on the manpower reserves of France, and as such your armies are no longer able to recruit from the previous bounty of young and able bodied recruits.
^
As a consequence, your forces will no longer benefit from the advantages of L'Élan Napoléonien.
^
Furthermore, your chief of staff, General Louis-Alexandre Berthier, advises you that should the trend continue and your armed forces loses exceed 100 regimental or naval units, your infantry regiments will no longer benefit from the foraging and forced march abilities (aka Ignore zones of control ability).
]]

scenText.impHQDispatch_Ignore_ZOC_Nullified =
[[***  France's 18-25 Manpower Reserves Depleted  ***
^
Emperor Napoléon, the Coalition Wars continue to take their toll on France's reserves of young recruits and as such you are compelled to begin drafting men outside the 18-25 age class.
^
As a consequence, your forces will no longer possess the same foraging and forced march abilities held by the younger recruits.
^
Therefore, starting with the next bat file switch, your Régiment de Ligne, Infanterie Légère and Carabiniers will no longer benefit from the 'Ignore zones of control' attribute.
]]

 scenText.impHQDispatch_Austria_War_5th_Coalition =
[[**********  Austria Joins War of 5th Coalition  **********
^
Humiliated by its loss in the war of the Third Coalition, Austria declares war on France in a bid to reverse the effects of the Treaty of Pressburg.
^
In addition, the Austrian war declaration sparks a Tyrolean rebellion in an around Innsbruck, lead by an innkeeper and dover named Andreas Hofer. The rebellion is a consequence of the Bavarian government's taxation, trade and religious policies under Count Montgelas which have angered the Tyrolean population.
^
If you can capture the cities of Agram, Prag, Trieste, Wien and maintain control of Dresden, Lublin, Thorn and Warszawa, you can once again bring your foe to his knees and force him to capitulate...
]]

scenText.impHQDispatch_DefeatedAustria_5thCoalition_p1 =
[[******  Austria Defeated in War of Fifth Coalition  ******
^
Emperor Napoléon, once again, you have successfully defeated your Austrian adversary on the battlefield and Francis I of Austria agrees to sign the peace treaty of Schönbrunn with you.
^
As part of the treaty, France receives a war indenmity of 1200 francs and agrees to return control of the following cities to Austria should they be under French control:
^
Budapest, Debrecen, Graz, Kosice, Krakow, Lemberg, Olmütz, Pécs, Prag, Temeschwar and Wien, though France will retain control of Agram and Trieste this time around (the 2 cities with a "!c" next to their names).
^
Therefore France has one turn to evacuate its troops from these cities, otherwise they will be disbanded to conform to your treaty obligations.
]]

scenText.impHQDispatch_French_DOW_vs_Russia_p1 =
[[***********  France Declares War on Russia  ***********
^
Emperor Napoléon, you have ordered your minister of foreign affairs, Charles Maurice de Talleyrand, to advise the Russian ambassador that henceforth a state of war will exist between your two great nations.
^
As part of your peace treaties with Austria and Prussia, they are both compelled to provide a contingent of troops for your great invasion.
^
In addition, you have promoted General Jozef Poniatowski, who till now was the acting Polish minister of War, to lead your V Corps.

The General, who already has had an illustrious military career figthing for Poland's independence, deploys in Warzsawa...
]]

scenText.impHQDispatch_French_DOW_vs_Russia_p2 =
[[In order to finalize your invasion preparations, you may use General Poniatowski's ONETIME administrative bonus, by pressing on the "k" key, to select one of the previously described recruitment options.
^
To use the administrative bonus, the General must be located in Warzsawa. 
^
Remember, you may only press on the "k" once to activate the bonus, as this is a singular event you will not have a second opportunity to do so (see Major Game concept #17 of the ReadMe Guide for details)... 
]]

scenText.impHQDispatch_French_DOW_vs_Russia_p3 =
[[Your Majesty, have you amassed the necessary forces to overcome the autocratic regime of the Tsar and spread the ideals of the French Revolution to the oppressed masses of the Russian nation?
^
Will you defeat the Tsar's army and capture four of six of his major cities of Ekaterninoslav, Kyiv, Moskva, Riga, Sankt-Peterburg or Smolensk, while maintaining a force of over 325,000 men (65 units) in that country and thereby fulfill your destiny?
^
The troops of your Grande Armée await your command to proceed. Your empire and legacy rest in your hands!
]]

scenText.impHQDispatch_Austria_War_6th_Coalition =
[[*********  Austria Joins War of 6th Coalition  *********
^
Your Majesty, Austria has informed you through its foreign minister, Prince Klemens von Metternich, that since your have failed to meet 2 of the following conditions, subdue England or Russia or enter into a diplomatic marriage, that it is breaking off relations with you and that it has joined the ranks of the anti-French coalition and that henceforth a state of war exists between your two nations.
^
Expect no further peace treaty from it, other than one gained by the conquest of all its cities.
^
Furthermore, your chief of staff, Maréchal Berthier informs you that any Austrian troops that were in your service have deserted the ranks of your army.
]]

scenText.impHQDispatch_Prussia_War_6th_Coalition =
[[*********  Prussia Joins War of 6th Coalition  *********
^
Emperor Napoléon, having failed to subdue Russia in time in your bid for mastery of the continent, Prussia has sent a diplomatic letter though its minister of foreign affairs, Count Ferdinand von der Goltz, that it has joined the ranks of the anti-French coalition and therefore that, once again, a state of war exists between your two nations.
^
It has indicated that no request for peace terms will come from it, lest you recapture all its cities. It forces all your Garde Frontalier units to abandon their posts and make a hasty retreat lest they end up in Prussian prison camps.
^
Maréchal Berthier informs you that any Prussian troops that were still in your service have deserted.
]]

scenText.impHQDispatch_Spain_Subdued =
[[*********  Spanish Rebellion Crushed by France  *********
^
Emperor Napoléon, after a bitter and ruthless campaign on both sides, your army has finally defeated the counter-revolutionary forces of Spain and its representatives have agreed to a permanent peace accord on your terms.
^
As such, all hostilities between your two nations will cease immediately and all Spanish forces will return to their barracks and all guerilla bands will deactive.
^
In addition to your maintaining control of the major cities of the country, Spain agrees to join the Continental blockade against England.
^
On the other hand, the Peninsula remains a hotbed of anti-French resentment and thus you need to keep a garrison force of at least 150,00 troops (30 units) to maintain the peace, otherwise 35 francs will be deducted from the treasury each month you fail to have the minimum force in place.
]]

scenText.impHQDispatch_Ottoman_Subdued =
[[********  Ottoman Sultanate Defeated by France  ********
^
Emperor Napoléon, after a difficult campaign, your army has overcome the army of the Sultan and he has agreed to sign a permanent peace accord on your terms.
^
As such, all hostilities between your two nations will cease immediately.
^
This is a glorious day for you and your Empire!
]]

scenText.impHQDispatch_Confederation_Disbands =
[[*********  German Minor Allies Desert France  *********
^
Your Majesty, your failure to subdue the Russian Empire and your inability to hold on to key German and Polish cities has profoundly shaken the Confederation of the Rhine's members faith in your capacity to withstand the forces the Coalition has arrayed against you.
^
As a consequence the German Minors powers of Bavaria (Ba), Rhineland (Rh), Westphalia (We) and Würtemberg (Wü) have sent diplomatic envoys to minister Talleyrand advising France that they are witdrawing posthaste from the Confederation.
^
As such all their Infantry and Cavalry regiments are being recalled home and will cease to serve under your command.
]]

scenText.impHQDispatch_Naples_Deserts =
[[******  Murat's Kingdom of Naples Betrays France  ******
^
Your Majesty, Maréchal Joachim Murat, who you appointed as the king of Naples after your invasion of Spain has been in secret negotiations with the Coalition.
^
Opening communications with the Austrians and British, Murat has signed a treaty with the Austrians in which, in return for renouncing his claims to Sicily and providing military support to the Allies in the war against you, Austria agrees to guarantee his continued possession of Naples.
^
As such not only will Murat and the Neapolitan forces cease to be under your command but a sizeable Sicilian/Neapolitan contingent is raised to expel your forces from southern Italy.
]]

scenText.impHQDispatch_Russia_Subdued =
[[******  Russian Empire Defeated by Napoléon!  ******
^
Emperor Napoléon, after a long and bitter campaign the Grand Armée has finally swept aside the Russian army on the battlefield and captured all the major objective cities required to render further resistance by the Tsarist regime futile.
^
As a consequence, minister Talleyrand informs you that Tsar Alexander I has sent a delegation asking for peace terms. This is a glorious day for you and France!
^
Hence forth, a permanent state of peace will exist between your great nations and the Russian army will stand down and cease to recruit new regiments.
^
To ensure that Russia abides by the terms of the treaty you will need to maintain a garrison force of at least 200,00 troops (40 units) in that country. Failure to do so will cost the French treasury 50 francs each month you fail to have the minimum force in place.
^
Lastly, it agrees to rejoin the Continental Blockade against England!
]]

--- =============================== ---
--- Victory Conditons Text Section
--- =============================== ---

scenText.third_CoalitionWar_VC =
[[*****************  WAR OF 3RD COALITION CONDITIONS!  *****************
^
TRIGGER:
^France starts the scenario at war with Austria, England and Russia.
^
VICTORY CONDITIONS:
^France must capture the Austrian cities of Prag, Venezia and Wien.
^
CONSEQUENCES:
^Austria signs the peace Treaty of Pressburg and all its core (c) and (!c) cities 
^are returned to it one turn after its defeat. Any French troops located in these 
^cities at the start of that turn will be disbanded and thus it is best to evacuate
^your forces from said cities beforehand, otherwise they shall be lost.
^
All of Austria's armed forces are disbanded save the garrison troops in its cities.
^
England and Russia remain at war with France.
^
Austria may renew hostilities with France by launching the war of the 5th Coalition.
]]

scenText.fourth_CoalitionWar_VC =
[[*********************  WAR OF 4TH COALITION CONDITIONS!  *********************
^
TRIGGER:
^Prussia may declare war on France anytime starting in 1806. England and Russia are  
^still at war with your Empire from the war of the 3rd Coalition.
^
VICTORY CONDITIONS:
^France must capture the Prussian cities of Berlin, Dresden, Konigsberg, Magdeburg, 
^Münster, Thorn, Warszawa and the Russian city of Lublin (all of which are marked by 
^a blue X).
^
CONSEQUENCES:
^Prussia and Russia sign the peace Treaty of Tilsit whereby all of Prussia's core (c)  
^cities are returned to it one turn after its defeat. Any French troops located in these 
^cities at the start of that turn will be disbanded.
^
^All of Prussia's armed forces are disbanded save the garrison troops in its core cities.
^All of Russia's ground units located within the boundaries of the Duchy of Warsaw or  
^the Prussian state are disbanded. 
^
^Russia may potentially go to war with France either if the latter invades England or 
^during the Austrian war of the 5th Coalition.
^
Prussia may renew hostilities with France by joining the war of the 6th Coalition.
]]

scenText.fifth_CoalitionWar_VC =
[[********************  WAR OF 5TH COALITION CONDITIONS!  ********************
^
TRIGGER:
^Austria may declare war on France no sooner than a year or more after the Prussian
^defeat in the war of the 4th Coalition.
^
If Austria can capture any two of Dresden, Leipzig, Lublin, Ratisbon, Venezia or 
^Warszawa, Russia may intervene in the war on its behalf unless it already came
^to England's aid during a French invasion of that island nation.
^
VICTORY CONDITIONS:
^France must capture the Austrian cities of Agram, Prag, Trieste and Wien, all the 
^while maintaining control of the cities of Dresden, Lublin, Thorn and Warszawa. 
^ 
CONSEQUENCES:
^Austria signs the peace Treaty of Schönbrunn whereby all of Austria's core (c) cities 
^cities are returned to it one turn after its defeat. Its core (!c) cities of Agram and
^Trieste are not returned. Any French troops located in the (c) cities at the start of 
^that turn will be disbanded.
^
All of Austria's armed forces are disbanded save the garrison forces in its cities.
^
^If Russia intervened in this war, it too becomes a signatory of the treaty, whereby 
^all of its ground units located within the boundaries of the Duchy of Warsaw or the 
^Prussian state are disbanded. 
^
Austria may renew hostilities with France by joining the war of the 6th Coalition.
]]

scenText.maritimeSupremacy_VC =
[[*****************  MARITIME SUPREMACY CONDITIONS!  *****************
^
DESCRIPTION:
^Achieving maritime supremacy may provide France with an extra set of strategic 
^options towards winning the war.
^
VICTORY CONDITIONS:
^The French Navy must destroy 20 British naval vessels in combat without losing 
^more than 9 of its own prior to January 1808 to establish Maritime Supremacy.
^
^Any French naval losses incurred as a result of Russian actions, while these 2   
^nations are at war, also count against France's score.
^
^Any British naval losses incurred as a result of French ground or artillery attacks
^do not count against England's tally, i.e. only losses inflicted by French naval  
^18 pdr, 24 pdr or 32 pdr Shells are counted.
^
CONSEQUENCES:
^Should France establish naval supremacy over the Royal Navy it will be granted 
^the Naval Transport advance which will allow it to build the naval 'Transport'   
^units necessary for any planned invasion of England.
^
^Maritime supremacy is also one of the four prerequisites required for renewing 
^the Franco-Spanish alliance.
]]

scenText.invasionOfPortugal_VC =
[[*****************  INVASION OF PORTUGAL CONDITIONS!  *****************
^
TRIGGER:
^France may only invade Portugal once it is permitted to enter the Iberian Peninsula.
^
This may only occur under one of the following conditions:
^- Once France imposes the treaty of Tilsit on Prussia, or
^- If England captures any Spanish city
^
CONSEQUENCES:
^If one of the above conditions is met then the 'Border' units between the French and 
^Spanish borders are permanently removed. This will allow France to send troops into  
^the Iberian Peninsula.
^
^Prior to January 1808, France may safely deploy up to 12 ground combat units (leaders  
^aren't calculated) in the Peninsula and use them to attack the British controlled Portuguese 
^cities of Lagos, Lisboa and Oporto. The capture of said cities, prior to the aforementioned 
^date, is one the conditions for renewing the Franco-Spanish alliance. 
^
^If there are no rebels in Ireland between the time France may enter the Peninsula and
^January 1808, there is a chance that Portugal may receive a one time reinforcement bonus.
^
^France may, at anytime prior to this date, decide to exceed its unit limit but by doing
^so will automatically nullify any chance of renewing its Spanish alliance. 
]]

scenText.francoSpanish_Alliance_VC =
[[*************  FRANCO-SPANISH ALLIANCE RENEWAL CONDITIONS!  *************
^
DESCRIPTION:
^Renewing the Franco-Spanish alliance will help to solidify France's western front against 
^British meddling and significantly reduce the commitment in manpower and resources 
^that a campaign of conquest in the Peninsula would otherwise incur.
^
VICTORY CONDITIONS:
^To renew the alliance the following conditions must be met prior to January 1808:
^- Establish Maritime Supremacy over the Royal Navy
^- Capture the Portuguese cities of Lagos, Lisboa and Oporto
^- Prevent the British capture of more than 1 Spanish city
^- May not deploy more than 12 ground combat units in the Iberian Peninsula
^
CONSEQUENCES:
^- Renewing the alliance will firmly keep Spain in the pro-French camp for the remainder 
^  of the war.
^- Spain will cede the control of the objective cities of Cadiz and Madrid to France.
^- Spanish garrisons will remain in any city its still controls, but no other ground troops
^  will ever be generated by the Spanish military for the remainder of the war.
^- Spain may continue to produce naval vessels.
^- Any Spanish city captured by the British will remain under its control, until and unless 
^  France recaptures them.
]]

scenText.peninsulaWar_VC =
[[*********************  THE PENINSULA WAR CONDITIONS!  *********************
^
TRIGGER:
^Spain will go to war with France it the latter failed to renew the Franco-Spanish alliance 
^prior to January 1808.
^
VICTORY CONDITIONS:
^France must capture the Spanish cities of A Coruna, Barcelona, Bilbao, Cadiz, Cartagena, 
^Gijon, Madrid, Málaga, Sevilla, Valencia, Valladolid and Zaragoza (all of which are  
^marked with a green X) to subdue Spain.
^
CONSEQUENCES:
^Spain is considered to have been subdued and therefore will remain at peace with France
^for the remainder of the game.
^
All Spanish cities you conquered remain under your control.
^
All of Spain's armed forces, including guerrillas, are disbanded save the garrison troops 
^in its cities you may not have conquered.
^
Spain joins the Continental Blockade against England.
^
If England is still at war with France, you may expect continued British hostile activity 
^in the Peninsula.
]]

scenText.invasionOfEngland_VC =
[[************************** INVASION OF ENGLAND CONDITIONS!  **************************
^
TRIGGER:
^France may only conceivably invade England if it achieved Maritime Supremacy prior to January 
1808 and subsequently built naval 'Transport' units to carry its troops to that island nation.
^
France will only have been considered to 'successfully' invade England if it has landed and 
maintains 4 or more troops on the island. A successful invasion will redirect any English 
reinforcements normally slated for the Iberian Peninsula to the British isles.
^
If France invades England prior to the war of the 5th Coalition, Russia might feel compelled
to intervene and to declare war on the French. Be wary, for the longer you delay an invasion
the more forces England will have time to recruit for its defense.
^
VICTORY CONDITIONS:
^France must capture the English cities of Birmingham, Bristol, Liverpool and London (all of 
^which are marked with a pink X) to subdue England.
^
CONSEQUENCES:
^England is considered to have been subdued and therefore will remain at peace with France
^for the remainder of the game. All of England's armed forces, including those of its minor 
^allies Portugal and Sweden, are disbanded save the garrison troops in its cities you may not 
^have conquered.
^
Any Spanish city held by Britain will be transferred back to Spain.
^
Any Portuguese city held by Britain will be handed over to France.
]]

scenText.invasionOfRussia_VC =
[[*********************** INVASION OF RUSSIA CONDITIONS!  ***********************
^
TRIGGER:
^France may only invade Russia after it researched the 'Invasion of Russia' advance,  
^which is in itself only possible after it defeated Austria in the war of the 5th Coalition, 
^which eventually grants it the prerequiste 'Russian preparations' technology.
^
VICTORY CONDITIONS:
^France must capture 4 of the 6 Russian cities of Ekaterinoslav, Kyiv, Moskva, Riga, 
^Sankt-Peterburg, Smolensk (all of which are marked with a yellow X) AND have at least 
^325,000 troops (65 units) in the country, at the time, to subdue Russia.
^
CONSEQUENCES:
^Russia is considered to have been subdued and therefore will remain at peace with 
^France for the remainder of the game.
^
All Russian cities you conquered remain under your control.
^
The Russian armed forces are disbanded, though not its forts or villages. That nation may no longer build new units.
^
Russia joins the Continental Blockade against England.
]]

scenText.sixth_CoalitionWar_VC =
[[*****************  WAR OF 6TH COALITION CONDITIONS!  *****************
^
TRIGGER:
^Austria and Prussia may declare war on France if the latter hasn't managed to subdue 
^Russia by early 1813.
^
Austria may be prevented from intervening if prior to its declaration of war: 
^- France has managed to subdue England and married the Austrian princess Marie-Louise, or
^- France has managed to subdue Russia and married the Austrian princess Marie-Louise
^
VICTORY CONDITIONS:
^There are no specific victory conditions in the war of the 6th Coalition.
^
^Both Austria and Prussia will remain at war with France for the remainder of the war 
^as long has either has even one unconquered city.
]]

scenText.invasionOfSultanate_VC =
[[*********************** INVASION OF SULTANATE CONDITIONS!  ***********************
^
TRIGGER:
^France may only invade the Ottoman Empire after it researched the 'War with Sultanate'   
^advance, which is in itself only possible after it defeated Austria in the war of the  
^5th Coalition, which immediately grants it the prerequiste 'Ottoman preparations' 
^technology.
^
VICTORY CONDITIONS:
^France must capture the Ottoman cities of Ankara and Istanbul to subdue the Sultanate.
^
CONSEQUENCES:
^The Ottoman Empire is considered to have been subdued and therefore will remain at  
^peace with France for the remainder of the game.
^
All Ottoman cities you conquered remain under your control.
^
Ottoman armed forces are not disbanded but that nation may no longer build new ones.
]]

--- =============================== ---
--- Minor Power Activation Text Section
--- =============================== ---

scenText.generaltips_MP =
[[*********  GENERAL MINOR POWER TIPS!  *********
^
It is STRICTLY forbidden to re-home any of your French minor power units. They must always remain homed to their respective cities *.
^
As long as they are an active French minor power (MP), any unit eliminated in combat will be regenerated on a 'Training Base' tile on their corresponding MP replacement track located on the 'European Powers' map.
^
Once on the training track the unit(s) should be moved from one 'Training Base' tile to the next till you reach the 'Transit Point' tile from which you can teleport (key 'n') back to the 'European' map
^
Units lost due to the effects of attrition are not replaced and therefore are permanently removed from that MP's order of battle.
^
* : If you've accidently re-homed an MP unit, as soon as you reselect and move it, it will automatically be re-homed to its corresponding city.
]]

scenText.batavia_MP =
[[*****************  BATAVIAN REPUBLIC ALLY!  *****************
^
ALLIED:
^The Batavian Republic begins the war as a French allied minor 
power.
^
STARTING OOB:
^France starts with 3 Dutch Infantry
^
YEARLY (APRIL) REINFORCEMENTS:
^One new Dutch Infantry in: 1807, 1808, 1810
^One new Dutch Cavalry in: 1807
^
TERMS OF SURRENDER:
^The Batavian Republic will be compelled to surrender if both  
^the cities of Amsterdam and Bruxelles are controlled by troops   
^of the Coalition powers.
]]

scenText.warsaw_MP =
[[**************  DUCHY OF WARSAW ACTIVATION!  **************
^
RECRUITMENT:
^Is activated when France captures the city of Warszawa.
^
ON ACTIVATION:
^France receives 2 Polish Infantry and 2 Polish Lancers
^
YEARLY (APRIL) REINFORCEMENTS:
^One new Polish Infantry in: 1808, 1809, 1810, 1811, 1812
^One new Polish Lancers in: 1809
^
TERMS OF SURRENDER:
^The Duchy of Warsaw will be compelled to surrender if the city  
^of Warszawa is captured by any troops of the Coalition powers,
^though any of its units still on the European map will continue 
^to fight for France until eliminated.
^
Polish units are by default always homed to NONE.
]]

scenText.irish_MP =
[[*****************  IRISH REBELS ACTIVATION!  *****************
^
DESCRIPTION:
^The Irish Rebels are not a minor power in themselves, but rather 
^a type of guerrilla force. They have no movement points. 
^
ACTIVATION:
^France generates an Irish Rebel unit in a randomly selected tile in 
^Ireland every time it kills a British ground unit located on that 
^island (prior to receiving the naval Transport unit, that can only be 
^accomplished by shells fired from French vessels). 
^
^Each active Irish Rebel unit found in Ireland at the beginning of a  
^turn sees 10 francs added to the French treasury.
^
^Failure to have active rebel units in Ireland, increases the odds that 
^England may send more troops to fight in the Iberian Peninsula.
^
TERMS OF SURRENDER:
^If England is ever subdued by France, all Irish Rebel units will be 
^disbanded.
]]

scenText.bavaria_MP =
[[*****************  KINGDOM OF BAVARIA ACTIVATION!  *****************
^
RECRUITMENT:
^Is activated when France defeats Austria in the war of the 3rd Coalition.
^
ON ACTIVATION:
^France receives 2 Bavarian Infantry and 1 Bavarian Cavalry
^
YEARLY (APRIL) REINFORCEMENTS:
^One new Bavarian Infantry in: 1807, 1809, 1810, 1812
^One new Bavarian Cavalry in: 1808
^
TERMS OF SURRENDER:
^Starting in 1813, the minor powers of the Rhine Confederation * will be 
^compelled to surrender if both Prussia and Russia are currently at war 
^with France and the latter has lost control of any three of the following 
^cities:
^
Brunswick, Danzig, Dresden, Hanover, Leipzip or Warzsaw
^
*: Includes Bavaria (Ba), Rhineland (Rh), Westphalia (We) and Würtemberg (Wü)
]]

scenText.denmark_MP =
[[*****************  KINGDOM OF DENMARK ACTIVATION!  *****************
^
RECRUITMENT:
^Is officially activated if France captures the cities of Lübeck and Straslund 
during the Prussian war of the 4th Coalition or, prior to this, anytime England 
kills a Danish ground unit.
^
STARTING OOB:
^Even though not officially allied, France starts the war with 3 Danish Infantry
^
ON ACTIVATION:
^France receives 2 Danish Infantry, 1 Danish Cavalry, 1 Deux-ponts 
and 1 Frégate
^
YEARLY (APRIL) REINFORCEMENTS:
^NONE
^
TERMS OF SURRENDER:
^The kingdom of Denmark will be compelled to surrender if the city  
^of Kobenhavn is captured by any troops of the Coalition powers.
]]

scenText.italy_MP =
[[*****************  KINGDOM OF ITALY ALLY!  *****************
^
ALLIED:
^The kingdom of Italy begins the war as a French allied minor 
power.
^
STARTING OOB:
^France starts the war with 4 Italian Infantry and 1 Italian Cavalry
^
YEARLY (APRIL) REINFORCEMENTS:
^One new Italian Infantry in: 1806, 1808, 1809
^One new Italian Cavalry in: 1807, 1809
^
TERMS OF SURRENDER:
^The kingdom of Italy may never be compelled to surrender though 
^if its city of Milano is captured, Italian reinforcement will not be
^able to deploy to the European map until that city is liberated. 
^
Italian units are by default always homed to NONE. 
]]

scenText.naples_MP =
[[**************  KINGDOM OF NAPLES ACTIVATION!  **************
^
RECRUITMENT:
^Is activated if France captures the cities of Napoli and Taranto 
^
ON ACTIVATION:
^France receives 3 Neapolitan Infantry and a Customs Warehouse in
^Napoli.
^
YEARLY (APRIL) REINFORCEMENTS:
^One new Neapolitan Infantry in: 1807, 1808, 1810, 1811
^
TERMS OF SURRENDER:
^The kingdom of Naples will be compelled to surrender if the city  
^of Napoli is captured by any troops of the Coalition powers. 
]]

scenText.rhineland_MP =
[[*****************  RHINELAND ACTIVATION!  *****************
^
RECRUITMENT:
^Is activated when France defeats Austria in the war of the 3rd Coalition.
^
ON ACTIVATION:
^France receives 2 Rhine Infantry 
^
YEARLY (APRIL) REINFORCEMENTS:
^One new Rhine Infantry in: 1808, 1809, 1810, 1812
^
TERMS OF SURRENDER:
^Starting in 1813, the minor powers of the Rhine Confederation * will be 
^compelled to surrender if both Prussia and Russia are currently at war 
^with France and the latter has lost control of any three of the following 
^cities:
^
Brunswick, Danzig, Dresden, Hanover, Leipzip or Warzsaw
^
*: Includes Bavaria (Ba), Rhineland (Rh), Westphalia (We) and Würtemberg (Wü)
]]

scenText.westphalia_MP =
[[**************  KINGDOM OF WESTPHALIA ACTIVATION!  **************
^
RECRUITMENT:
^Is activated if France captures the city of Münster during the Prussian 
war of the 4th Coalition.
^
ON ACTIVATION:
^France receives 1 Westphalian Infantry 
^
YEARLY (APRIL) REINFORCEMENTS:
^One new Westphalian Infantry in: 1807, 1808
^One new Westphalian Cavalry in: 1809
^
TERMS OF SURRENDER:
^Starting in 1813, the minor powers of the Rhine Confederation * will be 
^compelled to surrender if both Prussia and Russia are currently at war 
^with France and the latter has lost control of any three of the following 
^cities:
^
Brunswick, Danzig, Dresden, Hanover, Leipzip or Warzsaw
^
*: Includes Bavaria (Ba), Rhineland (Rh), Westphalia (We) and Würtemberg (Wü)
]]

scenText.wurtemberg_MP =
[[*************  KINGDOM OF WÜRTEMBERG ACTIVATION!  *************
^
RECRUITMENT:
^Is activated when France defeats Austria in the war of the 3rd Coalition.
^
ON ACTIVATION:
^France receives 2 Würtemberg Infantry 
^
YEARLY (APRIL) REINFORCEMENTS:
^One new Würtemberg Infantry in: 1807, 1809, 1811
^
TERMS OF SURRENDER:
^Starting in 1813, the minor powers of the Rhine Confederation * will be 
^compelled to surrender if both Prussia and Russia are currently at war 
^with France and the latter has lost control of any three of the following 
^cities:
^
Brunswick, Danzig, Dresden, Hanover, Leipzip or Warzsaw
^
*: Includes Bavaria (Ba), Rhineland (Rh), Westphalia (We) and Würtemberg (Wü)
]]

scenText.swiss_MP =
[[*****************  SWISS CONFEDERATION ALLY!  *****************
^
ALLIED:
^The Swiss Confederation begins the war as a French allied minor 
power.
^
STARTING OOB:
^France starts the war with 2 Swiss Infantry
^
YEARLY (APRIL) REINFORCEMENTS:
^One new Swiss Infantry in: 1806, 1808, 1810
^
TERMS OF SURRENDER:
^The Swiss Confederation will be compelled to surrender if the city  
^of Genève is captured by any troops of the Coalition powers. 
]]

-- •••••••••• Functions: •••••••••••••••••••••••••••••••••••••••••••••••••••••••
local function changeMoney (tribe, amount)
	if amount > 0 then
		tribe.money = tribe.money + amount
		print("Added " .. amount .. " gold to " .. tribe.adjective .. " treasury")
	elseif tribe.money == 0 then
		print("ERROR: call to changeMoney with amount of 0")
	else
		local absAmount = math.abs(amount)
		if tribe.money < absAmount then
			print("Deducted " .. tribe.money .. " gold from " .. tribe.adjective .. "treasury; attempted to deduct " .. absAmount .. " but they only had " .. tribe.money)
			tribe.money = 0
		else
			tribe.money = tribe.money + amount	-- adding a negative number
			print("Deducted " .. absAmount .. " gold from " .. tribe.adjective .. " treasury")
		end
	end
end

-- This function is provided to the helpkey module and will appear onscreen as notes for the corresponding unit
local function customUnitTextFunction (unit)
	local leaderBonusText = ""
	if unit.type.attack > 0 then
		leaderBonusText = "No leader attack bonus active."
		if unit.type.attack ~= baseUnitAttack[unit.type.id] then
			leaderBonusText = "Leader attack bonus active! Attack value increased from base of " .. baseUnitAttack[unit.type.id] .. "."
		end
	end
	return leaderBonusText
end

local function enforcePeace (tribe1, tribe2, knownChange)
	local description = " peace between " .. tribe1.name .. " and " .. tribe2.name
	if knownChange == true then
		description = "Signed" .. description
		print(description)
	else
		local wasAlreadyAtPeace = false
		if tribe1.treaties[tribe2] & 0x0004 == 0x0004 and tribe2.treaties[tribe1] & 0x0004 == 0x0004 then
			wasAlreadyAtPeace = true
		end
		if wasAlreadyAtPeace == true then
			description = "    Confirmed" .. description
		else
			description = "REPAIRED" .. description
			print(description)
			civ.ui.text("DIPLOMACY UPDATE: A peace treaty between " .. tribe1.name .. " and " .. tribe2.name .. " has been restored by scenario events, effective immediately. " ..
				"If you recently received notification that these nations had declared war, please ignore that incorrect information.")
		end
	end
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] & ~0x2000		-- remove war (bitwise "and not")
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] & ~0x0010		-- remove vendetta (bitwise "and not")
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] | 0x0005		-- add contact and peace treaty (bitwise "or")
	tribe1.attitude[tribe2] = 0
	tribe1.reputation[tribe2] = 0
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] & ~0x2000		-- remove war (bitwise "and not")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] & ~0x0010		-- remove vendetta (bitwise "and not")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] | 0x0005		-- add contact and peace treaty (bitwise "or")
	tribe2.attitude[tribe1] = 0
	tribe2.reputation[tribe1] = 0
end

local function enforceAlliance (tribe1, tribe2, knownChange)
	local description = " alliance between " .. tribe1.name .. " and " .. tribe2.name
	if knownChange == true then
		description = "Activated" .. description
		print(description)
	else
		description = "    Set" .. description
	end
	enforcePeace(tribe1, tribe2, knownChange)
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] | 0x0008	-- add alliance (bitwise "or")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] | 0x0008	-- add alliance (bitwise "or")
end

local function enforceWar (tribe1, tribe2, knownChange)
	local description = " war between " .. tribe1.name .. " and " .. tribe2.name
	if knownChange == true then
		description = "Declared" .. description
		print(description)
	else
		local wasAlreadyAtWar = false
		if tribe1.treaties[tribe2] & 0x2000 == 0x2000 and tribe2.treaties[tribe1] & 0x2000 == 0x2000 then
			wasAlreadyAtWar = true
		end
		if wasAlreadyAtWar == true then
			description = "    Confirmed" .. description
		else
			description = "REPAIRED" .. description
			print(description)
			civ.ui.text("DIPLOMACY UPDATE: A state of war between " .. tribe1.name .. " and " .. tribe2.name .. " has been restored by scenario events, effective immediately. " ..
				"If you recently received notification that these nations had signed a peace treaty, please ignore that incorrect information.")
		end
	end
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] & ~0x0008		-- remove alliance (bitwise "and not")
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] & ~0x0004		-- remove peace treaty (bitwise "and not")
	tribe1.treaties[tribe2] = tribe1.treaties[tribe2] | 0x2001		-- add contact and war (bitwise "or")
	tribe1.attitude[tribe2] = 100
	tribe1.reputation[tribe2] = 100
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] & ~0x0008		-- remove alliance (bitwise "and not")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] & ~0x0004		-- remove peace treaty (bitwise "and not")
	tribe2.treaties[tribe1] = tribe2.treaties[tribe1] | 0x2001		-- add contact and war (bitwise "or")
	tribe2.attitude[tribe1] = 100
	tribe2.reputation[tribe1] = 100
end

local function findImprovement (impName)
	for i = 1, 39 do
		local imp = civ.getImprovement(i)
		if imp.name == impName then
			return imp
		end
	end
end

local function findImprovementByName (impName)
	local imp = findImprovement(impName)
	if imp ~= nil then
--		print("    Found improvement \"" .. impName .. "\" with ID " .. imp.id)
	else
		print("ERROR: did not find improvement \"" .. impName .. "\", returning nil")
	end
	return imp
end

local function findTech (techName)
	for i = 0, 99 do
		local tech = civ.getTech(i)
		if tech.name == techName then
			return tech
		end
	end
end

local function findTechByName (techName)
	local tech = findTech(techName)
	if tech ~= nil then
		print("    Found tech \"" .. techName .. "\" with ID " .. tech.id)
	else
		print("ERROR: did not find tech \"" .. techName .. "\", returning nil")
	end
	return tech
end

local function getMonthNumber (turn)
	local monthNumber = (turn + 7 ) % 12
	if monthNumber == 0 then
		monthNumber = 12
	end
	return monthNumber
end

local function getYear ()
	return math.floor(civ.getGameYear() / 12)
end

local function displayMonthYear ()
	return monthName[getMonthNumber(civ.getTurn())] .. " " .. getYear()
end

local function getRandomValidLocation (unitName, owner, potentialLocationList)
	-- Note: first parameter is the unit type *name* as a string, not a unit type object
	-- Adapted from civlua.createUnit():
	local function getFirstValidLocation (locations)
		for _, location in ipairs(locations) do
			local tile = civ.getTile(table.unpack(location))
			if civlua.isValidUnitLocation(findUnitTypeByName(unitName), owner, tile) then
				print("    Valid location found for unit creation event: " .. tile.x .. "," .. tile.y .. "," .. tile.z)
				return location
			end
		end
	end
	local shuffledLocationList = func.shuffle(potentialLocationList)
	local eventLocation = { }
	table.insert(eventLocation, getFirstValidLocation(shuffledLocationList))
	if #eventLocation == 0 then
		print("ERROR! Could not find a valid location for " .. owner.adjective .. " " .. unitName .. " from " .. tostring(#potentialLocationList) .. " potential tiles")
	end
	return eventLocation
end

local function grantTech (tribe, techName)
	local tech = findTechByName(techName)
	if tech ~= nil then
		civ.giveTech(tribe, tech)
		print("Gave \"" .. tech.name .. "\" tech (ID " .. tech.id .. ") to " .. tribe.name)
	end
end

local function revokeTech (tribe, techName)
	local tech = findTechByName(techName)
	if tech ~= nil then
		civ.takeTech(tribe, tech)
		print("Removed \"" .. tech.name .. "\" tech (ID " .. tech.id .. ") from " .. tribe.name)
	end
end

local function printGameStatus ()
	print("")
	print("--- State Table Contents:")
	local statekeys = {}
	for key, value in pairs(state) do
		table.insert(statekeys, key)
	end
	table.sort(statekeys)
	for _, key in ipairs(statekeys) do
		print("    " .. tostring(key) .. " = " .. tostring(state[key]))
	end
	print("")
end

local function round (decimal)
	-- Rounds a numeric value to the nearest integer and returns the integer
	return math.floor(decimal + 0.5)
end

local function tileCityCenterTerrain (tile)
	-- "City Center" terrains are (type 9) on map 0
	if tile.terrainType & 0x0F == 0x09 and tile.z == 0 then
		return true
	else
		return false
	end
end

local function tileOpenTerrain (tile)
	-- "Open" terrains are Grasslands (type 2), Forests (type 3), Hills (type 4), and Marshes (type 8)
	--		on map 0, which do not contain a city
	--[[ Per TNO: "make sure you use bitwise operators in tests and assignments
			(e.g. to test for the presence of a river, use tile.terrainType & 0x80,
			to add pollution to a tile, use tile.improvements = tile.improvements | 0x80)." ]]
	if (tile.terrainType & 0x0F == 0x02 or tile.terrainType & 0x0F == 0x03 or tile.terrainType & 0x0F == 0x04 or tile.terrainType & 0x0F == 0x08) and tile.z == 0 and tile.city == nil then
		return true
	else
		return false
	end
end

local function tileOceanTerrain (tile)
	-- "Ocean" terrains are (type 10) on map 0
	if tile.terrainType & 0x0F == 0x0A and tile.z == 0 then
		return true
	else
		return false
	end
end

local function tileOceanZone1 (tile)
	if tile.z ~= 0 and tile.terrainType & 0x0F ~= 0x0A then
		return false
	else
		if	(tile.x == 68 and tile.y == 40) or 
			(tile.x >= 67 and tile.y >= 41 and tile.x <= 69 and tile.y <= 41) or
			(tile.x >= 66 and tile.y >= 42 and tile.x <= 70 and tile.y <= 42) or
			(tile.x >= 65 and tile.y >= 43 and tile.x <= 71 and tile.y <= 43) or
			(tile.x >= 66 and tile.y >= 44 and tile.x <= 70 and tile.y <= 44) or
			(tile.x == 63 and tile.y == 45) or 
			(tile.x >= 64 and tile.y >= 46 and tile.x <= 68 and tile.y <= 46) then
			return true
		else
			return false
		end
	end
end

local function tileOceanZone2 (tile)
	if tile.z ~= 0 and tile.terrainType & 0x0F ~= 0x0A then
		return false
	else
		if	(tile.x >= 50 and tile.y >= 50 and tile.x <= 52 and tile.y <= 50) or
			(tile.x >= 49 and tile.y >= 51 and tile.x <= 53 and tile.y <= 51) or
			(tile.x >= 48 and tile.y >= 52 and tile.x <= 54 and tile.y <= 52) or
			(tile.x >= 47 and tile.y >= 53 and tile.x <= 55 and tile.y <= 53) or
			(tile.x >= 48 and tile.y >= 54 and tile.x <= 52 and tile.y <= 54) or
			(tile.x == 49 and tile.y == 55) or
			(tile.x >= 50 and tile.y >= 56 and tile.x <= 52 and tile.y <= 56) or
			(tile.x == 53 and tile.y == 57) then
			return true
		else
			return false
		end
	end
end

local function tileOceanZone3 (tile)
	if tile.z ~= 0 and tile.terrainType & 0x0F ~= 0x0A then
		return false
	else
		if	(tile.x == 36 and tile.y == 52) or 
			(tile.x >= 35 and tile.y >= 53 and tile.x <= 37 and tile.y <= 53) or
			(tile.x >= 34 and tile.y >= 54 and tile.x <= 38 and tile.y <= 54) or
			(tile.x >= 33 and tile.y >= 55 and tile.x <= 39 and tile.y <= 55) or
			(tile.x >= 32 and tile.y >= 56 and tile.x <= 40 and tile.y <= 56) or
			(tile.x >= 33 and tile.y >= 57 and tile.x <= 35 and tile.y <= 57) or
			(tile.x == 34 and tile.y == 58) then
			return true
		else
			return false
		end
	end
end

local function tileOceanZone4 (tile)
	if tile.z ~= 0 and tile.terrainType & 0x0F ~= 0x0A then
		return false
	else
		if	(tile.x == 42 and tile.y == 70) or 
			(tile.x >= 41 and tile.y >= 71 and tile.x <= 43 and tile.y <= 71) or
			(tile.x >= 40 and tile.y >= 72 and tile.x <= 42 and tile.y <= 72) or
			(tile.x == 41 and tile.y == 73) or 
			(tile.x == 42 and tile.y == 74) or 
			(tile.x == 42 and tile.y == 76) or 
			(tile.x >= 41 and tile.y >= 77 and tile.x <= 43 and tile.y <= 77) or
			(tile.x == 40 and tile.y == 78) or 
			(tile.x == 41 and tile.y == 79) then
			return true
		else
			return false
		end
	end
end

local function tileOceanZone5 (tile)
	if tile.z ~= 0 and tile.terrainType & 0x0F ~= 0x0A then
		return false
	else
		if	(tile.x == 63 and tile.y == 85) or 
			(tile.x == 63 and tile.y == 87) or 
			(tile.x >= 61 and tile.y >= 89 and tile.x <= 69 and tile.y <= 89) or 
			(tile.x >= 62 and tile.y >= 90 and tile.x <= 70 and tile.y <= 90) or
			(tile.x >= 63 and tile.y >= 91 and tile.x <= 69 and tile.y <= 91) or
			(tile.x >= 64 and tile.y >= 92 and tile.x <= 68 and tile.y <= 92) or
			(tile.x >= 65 and tile.y >= 93 and tile.x <= 67 and tile.y <= 93) or
			(tile.x == 66 and tile.y == 94) then
			return true
		else
			return false
		end
	end
end

local function tileOceanZone6 (tile)
	if tile.z ~= 0 and tile.terrainType & 0x0F ~= 0x0A then
		return false
	else
		if	(tile.x == 92 and tile.y == 102) or
			(tile.x >= 91 and tile.y >= 103 and tile.x <= 93 and tile.y <= 103) or 
			(tile.x >= 92 and tile.y >= 104 and tile.x <= 96 and tile.y <= 104) or
			(tile.x >= 93 and tile.y >= 105 and tile.x <= 97 and tile.y <= 105) or
			(tile.x >= 94 and tile.y >= 106 and tile.x <= 96 and tile.y <= 106) or
			(tile.x >= 95 and tile.y >= 107 and tile.x <= 97 and tile.y <= 107) or
			(tile.x == 96 and tile.y == 108) then
			return true
		else
			return false
		end
	end
end

local function tileOceanZone7 (tile)
	if tile.z ~= 0 and tile.terrainType & 0x0F ~= 0x0A then
		return false
	else
		if	(tile.x == 165 and tile.y == 139) or 
			(tile.x >= 164 and tile.y >= 140 and tile.x <= 166 and tile.y <= 140) or 
			(tile.x >= 163 and tile.y >= 141 and tile.x <= 167 and tile.y <= 141) or
			(tile.x >= 162 and tile.y >= 142 and tile.x <= 168 and tile.y <= 142) or
			(tile.x >= 161 and tile.y >= 143 and tile.x <= 169 and tile.y <= 143) or
			(tile.x == 160 and tile.y == 144) then
			return true
		else
			return false
		end
	end
end

local function tileWithinEngland (tile)
	if tile.z ~= 0 or tile.terrainType & 0x0F == 0x0A then
		return false
	else
		if (tile.x >= 42 and tile.y >=  8 and tile.x <= 54 and tile.y <= 28) or
		   (tile.x >= 41 and tile.y >= 29 and tile.x <= 59 and tile.y <= 43) or
		   (tile.x >= 36 and tile.y >= 44 and tile.x <= 56 and tile.y <= 50) then
			return true
		else
			return false
		end
	end
end

local function tileWithinIberia (tile)
	if tile.z ~= 0 or tile.terrainType & 0x0F == 0x0A then
		return false
	else
		if (				 tile.y >= 75 and tile.x <= 37 and tile.y <= 115) or
		   (tile.x >= 38 and tile.y >= 90 and tile.x <= 46 and tile.y <= 108) or
		   (tile.x >= 47 and tile.y >= 93 and tile.x <= 55 and tile.y <= 107) or
		   (tile.x == 38 and tile.y == 88) or
		   (tile.x == 39 and tile.y == 89) or
		   (tile.x == 40 and tile.y == 88) or
		   (tile.x == 41 and tile.y == 89) or
		   (tile.x == 48 and tile.y == 92) then
			return true
		else
			return false
		end
	end
end

local function tileWithinIreland (tile)
	if tile.z ~= 0 or tile.terrainType & 0x0F == 0x0A then
		return false
	else
		if (tile.x >= 28 and tile.y >= 22 and tile.x <= 40 and tile.y <= 32) or
		   (tile.x >= 25 and tile.y >= 33 and tile.x <= 37 and tile.y <= 39) then
			return true
		else
			return false
		end
	end
end

local function tileWithinPrussia (tile)
	if tile.z ~= 0 or tile.terrainType & 0x0F == 0x0A then
		return false
	else
		if (tile.x >= 105 and tile.y >= 35 and tile.x <= 111 and tile.y <= 57) or
		   (tile.x >= 111 and tile.y >= 35 and tile.x <= 119 and tile.y <= 55) or
		   (tile.x >= 119 and tile.y >= 45 and tile.x <= 123 and tile.y <= 55) or
		   (tile.x >= 123 and tile.y >= 49 and tile.x <= 127 and tile.y <= 55) then
			return true
		else
			return false
		end
	end
end

local function tileWithinRussia (tile)
	if tile.z ~= 0 or tile.terrainType & 0x0F == 0x0A then
		return false
	else
		if (tile.x >= 115 and tile.y <= 31) or
		   (tile.x >= 116 and tile.y <= 32) or
		   (tile.x >= 116 and tile.y <= 32) or
		   (tile.x >= 117 and tile.y <= 33) or
		   (tile.x >= 118 and tile.y <= 34) or
		   (tile.x == 120 and tile.y == 38) or
		   (tile.x >= 120 and tile.y <= 42) or
		   (tile.x >= 121 and tile.y <= 43) or
		   (tile.x >= 122 and tile.y <= 44) or
		   (tile.x >= 123 and tile.y <= 47) or
		   (tile.x >= 124 and tile.y <= 48) or
		   (tile.x >= 125 and tile.y <= 49) or
		   (tile.x >= 126 and tile.y <= 50) or
		   (tile.x >= 127 and tile.y <= 53) or
		   (tile.x >= 128 and tile.y <= 54) or
		   (tile.x >= 129 and tile.y <= 55) or
		   (tile.x >= 130 and tile.y <= 56) or
		   (tile.x >= 131 and tile.y <= 57) or
		   (tile.x >= 132 and tile.y <= 58) or
		   (tile.x >= 133 and tile.y <= 59) or
		   (tile.x >= 134 and tile.y <= 60) or
		   (tile.x >= 135 and tile.y <= 61) or
		   (tile.x >= 136 and tile.y <= 62) or
		   (tile.x >= 137 and tile.y <= 63) or
		   (tile.x >= 138 and tile.y <= 64) or
		   (tile.x >= 139 and tile.y <= 65) or
		   (tile.x >= 140 and tile.y <= 66) or
		   (tile.x >= 141 and tile.y <= 67) or
		   (tile.x >= 142 and tile.y <= 68) or
		   (tile.x >= 143 and tile.y <= 71) or
		   (tile.x >= 144 and tile.y <= 74) or
		   (tile.x >= 145 and tile.y <= 75) or
		   (tile.x == 146 and tile.y == 76) or
		   (tile.x >= 149 and tile.y <= 77) then
			return true
		else
			return false
		end
	end
end

local function cityTileWithinAustria (tile)
	if tile.z ~= 0 or tile.terrainType & 0x0F == 0x0A then
		return false
	else
		if (tile.x ==  96 and tile.y == 58) or
		   (tile.x ==  99 and tile.y == 73) or
		   (tile.x == 103 and tile.y == 67) or
		   (tile.x == 105 and tile.y == 61) or
		   (tile.x == 110 and tile.y == 76) or
		   (tile.x == 112 and tile.y == 70) or
		   (tile.x == 113 and tile.y == 57) or
		   (tile.x == 118 and tile.y == 70) or
		   (tile.x == 119 and tile.y == 65) or
		   (tile.x == 119 and tile.y == 79) or
		   (tile.x == 126 and tile.y == 58) then
			return true
		else
			return false
		end
	end
end

local function cityTileWithinPrussia (tile)
	if tile.z ~= 0 or tile.terrainType & 0x0F == 0x0A then
		return false
	else
		if (tile.x ==  94 and tile.y == 46) or
		   (tile.x ==  97 and tile.y == 41) or
		   (tile.x == 104 and tile.y == 52) or
		   (tile.x == 113 and tile.y == 35) then
			return true
		else
			return false
		end
	end
end

local function cityTileAgram (tile)
	if tile.x == 102 and tile.y == 78 and tile.z == 0 then
		return true
	else
		return false
	end
end

local function cityTileAlgier (tile)
	if tile.x == 51 and tile.y == 119 and tile.z == 0 then
		return true
	else
		return false
	end
end

local function cityTileCadiz (tile)
	if tile.x == 14 and tile.y == 112 and tile.z == 0 then
		return true
	else
		return false
	end
end

local function cityTileMadrid (tile)
	if tile.x == 28 and tile.y == 96 and tile.z == 0 then
		return true
	else
		return false
	end
end

local function cityTileMalaga (tile)
	if tile.x == 23 and tile.y == 113 and tile.z == 0 then
		return true
	else
		return false
	end
end

local function cityTileWarszawa (tile)
	if tile.x == 116 and tile.y == 46 and tile.z == 0 then
		return true
	else
		return false
	end
end

local frenchLeaders = { "Napoléon I", "Soult", "Davout", "Lannes", "Murat", "Garde Frontalier", "Poniatowski" }
for _, leaderUnit in pairs(frenchLeaders) do
	findUnitTypeByName(leaderUnit)
end
local function unitIsFrenchLeader (unit)
	if unit.type.name == frenchLeaders[1] or
	   unit.type.name == frenchLeaders[2] or
	   unit.type.name == frenchLeaders[3] or
	   unit.type.name == frenchLeaders[4] or
	   unit.type.name == frenchLeaders[5] or
	   unit.type.name == frenchLeaders[6] or
	   unit.type.name == frenchLeaders[7] then
		return true
	else
		return false
	end
end

local frenchCavalry = { "Cuirassiers", "Lanciers", "Grenadier à Cheval", "Bavarian Cavalry", "Danish Cavalry", "Italian Cavalry", "Polish Lancers", "Dutch Cavalry", "Westphalian Cavalry" }
for _, cavalryUnit in pairs(frenchCavalry) do
	findUnitTypeByName(cavalryUnit)
end
local function unitIsFrenchCavalry (unit)
	if 	unit.type.name == frenchCavalry[1] or
		unit.type.name == frenchCavalry[2] or
		unit.type.name == frenchCavalry[3] or
		unit.type.name == frenchCavalry[4] or
		unit.type.name == frenchCavalry[5] or
		unit.type.name == frenchCavalry[6] or
		unit.type.name == frenchCavalry[7] or
		unit.type.name == frenchCavalry[8] or
		unit.type.name == frenchCavalry[9] then
		return true
	else
		return false
	end
end

local frenchVesselShells = { "18 pdr Shells", "24 pdr Shells", "32 pdr Shells" }
for _, vesselShellUnit in pairs(frenchVesselShells) do
	findUnitTypeByName(vesselShellUnit)
end
local function unitIsFrenchVesselShell (unit)
	if unit.type.name == frenchVesselShells[1] or
	   unit.type.name == frenchVesselShells[2] or
	   unit.type.name == frenchVesselShells[3] then
		return true
	else
		return false
	end
end

local function getEmbargoShipDetails ()
	local embargoShips = { }
	if state.englandIsAtWarWithFrance == true then
		for unit in civ.iterateUnits() do
			if unit.type.domain == 2 and (unit.owner == England or (state.russiaIsAtWarWithFrance == true and unit.owner == Russia) or (state.spainIsAtWarWithFrance == true and unit.owner == Spain)) then
				if tileOceanZone1(unit.location) then
					embargoShips[1] = (embargoShips[1] or 0) + 1
				end
				if tileOceanZone2(unit.location) then
					embargoShips[2] = (embargoShips[2] or 0) + 1
				end
				if tileOceanZone3(unit.location) then
					embargoShips[3] = (embargoShips[3] or 0) + 1
				end
				if tileOceanZone4(unit.location) then
					embargoShips[4] = (embargoShips[4] or 0) + 1
				end
				if tileOceanZone5(unit.location) then
					embargoShips[5] = (embargoShips[5] or 0) + 1
				end
				if tileOceanZone6(unit.location) then
					embargoShips[6] = (embargoShips[6] or 0) + 1
				end
			end
		end
	end
	return embargoShips
end

local function getFrenchNavyInfo ()
	local costPerFrenchNavalUnit = {
		["Frégate"] = 3,
		["Deux-ponts"] = 6,
		["Trois-ponts"] = 10,
		["Bombarde"] = 8,
		["Transport"] = 6,
		["Villeneuve"] = 12,
	}
	local frenchNavyUnits = 0
	local frenchNavyTotalCost = 0
	for unit in civ.iterateUnits() do
		if unit.owner == France then
			local thisUnitCost = costPerFrenchNavalUnit[unit.type.name]
			if thisUnitCost ~= nil then
				frenchNavyUnits = frenchNavyUnits + 1
				frenchNavyTotalCost = frenchNavyTotalCost + thisUnitCost
			end
		end
	end
	return frenchNavyUnits, frenchNavyTotalCost
end

local function getFrenchTradingPost ()
	local frenchTradingPost = 0
	if Corfu.owner == France then
		frenchTradingPost = frenchTradingPost + 15
	end
	return frenchTradingPost
end


local function getFrenchTroopsInEngland ()
	local frenchTroopsInEngland = 0
	for unit in civ.iterateUnits() do
		if unit.owner == France and unit.type.domain == 0 and tileWithinEngland(unit.location) then
			frenchTroopsInEngland = frenchTroopsInEngland + 1
		end
	end
	return frenchTroopsInEngland
end

local function getFrenchTroopsInIberia ()
	local frenchTroopsInIberia = 0
	for unit in civ.iterateUnits() do
		if unit.owner == France and unit.type.domain == 0 and unit.type.name ~= "Plunder" and not(unitIsFrenchLeader(unit)) and tileWithinIberia(unit.location) then
			frenchTroopsInIberia = frenchTroopsInIberia + 1
		end
	end
	return frenchTroopsInIberia
end

local function getFrenchTroopsInPrussia ()
	local frenchTroopsInPrussia = 0
	for unit in civ.iterateUnits() do
		if unit.owner == France and unit.type.domain == 0 and unit.type.name ~= "Garde Frontalier" and not(unitIsFrenchLeader(unit)) and tileWithinPrussia(unit.location) then
			frenchTroopsInPrussia = frenchTroopsInPrussia + 1
		end
	end
	return frenchTroopsInPrussia
end

local function getFrenchTroopsInRussia ()
	local frenchTroopsInRussia = 0
	for unit in civ.iterateUnits() do
		if unit.owner == France and unit.type.domain == 0 and tileWithinRussia(unit.location) then
			frenchTroopsInRussia = frenchTroopsInRussia + 1
		end
	end
	return frenchTroopsInRussia
end

local function getIrishRebelsInIreland ()
	local irishRebelsInIreland = 0
	if state.englandIsAtWarWithFrance == true then
		for unit in civ.iterateUnits() do
			if unit.owner == France and unit.type.name == "Irish Rebel" and tileWithinIreland(unit.location) then
				irishRebelsInIreland = irishRebelsInIreland + 1
			end
		end
	end
	return irishRebelsInIreland
end


-- ==== 6. MINOR POWERS ====
-- ------ Western Minors ----
local function activateDenmark (reason)
	print("Activated Denmark (" .. reason .. ")")
	state.minorDenmark = true
	local denmarkSupplyTrainTile = civ.getTile(90,26,1)
	denmarkSupplyTrainTile.terrainType = 0
	createUnitsByName("Danish Infantry", France, {{90,30,1}, {85,23,0}}, {count = 2, randomize = true, homeCity = Denmark, veteran = false})
	createUnitsByName("Danish Cavalry", France, {{90,30,1}, {85,23,0}}, {randomize = true, homeCity = Denmark, veteran = false})
	createUnitsByName("Frégate", France, {{90,30,0}, {85,23,0}}, {randomize = true, homeCity = Denmark, veteran = false})
	createUnitsByName("Deux-ponts", France, {{90,30,0}, {85,23,0}}, {randomize = true, homeCity = Denmark, veteran = false})
	civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, having lifted the British/Swedish\n^encirclement around it, the Kingdom of Denmark (De)\n^has agreed to join your alliance and placed its\n^navy and army at your disposal."))
end

local function activateFrenchInvasionOfPortugal (reason)
	print("Activated French Invasion Of Portugal (" .. reason .. ")")
	-- ---- Invasion of Portugal ----
	state.frenchInvasionOfPortugal = true
	for unit in civ.iterateUnits() do
		if unit.owner == Spain and unit.type == findUnitTypeByName("Border") then
			print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
			civ.deleteUnit(unit)
		end
	end
	civ.ui.text(func.splitlines(scenText.impHQDispatch_InvasionPortugal_p1))
	civ.ui.text(func.splitlines(scenText.impHQDispatch_InvasionPortugal_p2))
end
-- =========================

local function updateSeason (initialLoad)
	local monthNumber = getMonthNumber(civ.getTurn())

	-- ==== 10. WINTER ====
	if monthNumber >= 11 or monthNumber <= 3 then
		-- Note: November through March are the winter months; set winter graphics at the *beginning* of those months
		state.winter = true
	else
		state.winter = false
	end

	if state.winter == true then
		civ.ui.loadTerrain(0, 'Terrain/wTerrain1.bmp', 'Terrain/wTerrain2.bmp')
		civ.playSound("Winter.wav")
		print("Loaded winter terrain")
		if monthNumber == 11 and initialLoad == false then
			if state.frenchForcedMarchAbility == true then
				civ.ui.text(func.splitlines(scenText.winterOneText))
			else
				civ.ui.text(func.splitlines(scenText.winterTwoText))
			end
		end
	else
		civ.ui.loadTerrain(0, 'Terrain/sTerrain1.bmp', 'Terrain/sTerrain2.bmp')
		print("Loaded normal (summer) terrain")
		civ.playSound("Spring.wav")
		if monthNumber == 4 and initialLoad == false then
			if state.frenchForcedMarchAbility == true then
				civ.ui.text(func.splitlines(scenText.summerOneText))
			else
				civ.ui.text(func.splitlines(scenText.summerTwoText))
			end
		end
	end
	-- ====================
end


-- •••••••••• Event Triggers: ••••••••••••••••••••••••••••••••••••••••••••••••••
-- Note: the civ.scen.onActivateUnit() trigger does not fire when a unit is activated by lua using unit:activate()
-- This is used for projectiles in this scenario.
-- Therefore, the code that belongs within that trigger is pulled out into this separate function,
-- so that it can be called directly by Lua when the activation is also being triggered by Lua.
onActivateUnitFunction = function (unit, source)

-- ==== 7. WAR STATES AND PEACE TREATIES ====
-- --	Confirm peace and war between AI tribes	--
	if unit.owner == Russia then
		enforcePeace(Russia, Austria, false)
		enforcePeace(Russia, Prussia, false)
		enforcePeace(Russia, Spain, false)
		if state.ottomanIsAtWarWithRussia == true then
			enforceWar(Russia, Ottoman, false)
		else
			enforcePeace(Russia, Ottoman, false)
		end
		enforcePeace(Russia, England, false)
	elseif unit.owner == Austria then
		enforcePeace(Austria, Russia, false)
		enforcePeace(Austria, Prussia, false)
		enforcePeace(Austria, Spain, false)
		enforcePeace(Austria, Ottoman, false)
		enforcePeace(Austria, England, false)
	elseif unit.owner == Prussia then
		enforcePeace(Prussia, Russia, false)
		enforcePeace(Prussia, Austria, false)
		enforcePeace(Prussia, Spain, false)
		enforcePeace(Prussia, Ottoman, false)
		enforcePeace(Prussia, England, false)
	elseif unit.owner == Spain then
		enforcePeace(Spain, Russia, false)
		enforcePeace(Spain, Austria, false)
		enforcePeace(Spain, Prussia, false)
		enforcePeace(Spain, Ottoman, false)
		if state.spainIsAtWarWithEngland == true then
			enforceWar(Spain, England, false)
		else
			enforcePeace(Spain, England, false)
		end
	elseif unit.owner == Ottoman then
		if state.ottomanIsAtWarWithRussia == true then
			enforceWar(Russia, Ottoman, false)
		else
			enforcePeace(Russia, Ottoman, false)
		end
		enforcePeace(Ottoman, Austria, false)
		enforcePeace(Ottoman, Prussia, false)
		enforcePeace(Ottoman, Spain, false)
		-- England may or may not go to war with Ottomans; allowing normal game logic to decide
	elseif unit.owner == England then
		enforcePeace(England, Russia, false)
		enforcePeace(England, Austria, false)
		enforcePeace(England, Prussia, false)
		if state.spainIsAtWarWithEngland == true then
			enforceWar(England, Spain, false)
		else
			enforcePeace(England, Spain, false)
		end
		-- England may or may not go to war with Ottomans; allowing normal game logic to decide

-- --	Confirm peace and war between France and AI tribes: new for v1.1	--
	elseif unit.owner == France then
		-- All code that manages *changes* in the relationship between France and each AI tribe is found in civ.scen.onTurn()
		-- This references some of the same state table variables to enforce and/or restore the relationships set there.
		if state.russiaIsAtWarWithFrance == true then
			-- Note: it is not necessary to check state.russiaIsAtWarWithFrance5thCoalition; this provides additional information about
			--		 whether a war between Russia is part of the 3rd or 5th coalition, but in either case, the code in civ.scen.onTurn()
			--		 sets state.russiaIsAtWarWithFrance to true.
			--		 This is different than the logic used for Austria or Prussia!
			enforceWar(France, Russia, false)
		else
			enforcePeace(France, Russia, false)
		end
		if state.austriaIsAtWarWithFrance1 == true or state.austriaIsAtWarWithFrance2 == true or state.austriaIsAtWarWithFrance3 == true then
			enforceWar(France, Austria, false)
		else
			enforcePeace(France, Austria, false)
		end
		if state.prussiaIsAtWarWithFrance1 == true or state.prussiaIsAtWarWithFrance2 == true then
			enforceWar(France, Prussia, false)
		else
		-- OLD (unneeded): if civ.getTurn() < state.prussiaFourthCoalitionWarTurn then
			enforcePeace(France, Prussia, false)
		end
		if state.spainIsAtWarWithFrance == true then
			enforceWar(France, Spain, false)
		else
			enforcePeace(France, Spain, false)
		end
		if state.ottomanIsAtWarWithFrance == true then
			enforceWar(France, Ottoman, false)
		elseif state.ottomanTreatyOfErdine == true then
			-- Note that unlike all other tribes, Ottomans have a separate treaty condition that must be met to enforce peace
			enforcePeace(France, Ottoman, false)
		end
		if state.englandIsAtWarWithFrance == true then
			enforceWar(France, England, false)
		else
			enforcePeace(France, England, false)
		end
	end
-- ==========================================

	-- Remove home city from Coalition or French leaders (for British see "Remove home city from British leaders" section):
	-- Remove home city from Portuguese Infantry and Cavalry as the AI appears to home them to Portuguese cities
	if unit.type.name == "Bagration" or
	   unit.type.name == "Barclay de Tolly" or
	   unit.type.name == "Kutusov" or
	   unit.type.name == "Blake" or
	   unit.type.name == "Cuesta" or
	   unit.type.name == "Charles" or
	   unit.type.name == "Schwarzenberg" or
	   unit.type.name == "Blücher" or
	   unit.type.name == "Yorck" or
	   unit.type.name == "Napoléon I" or
	   unit.type.name == "Davout" or
	   unit.type.name == "Lannes" or
	   unit.type.name == "Murat" or
	   unit.type.name == "Soult" or
	   unit.type.name == "Poniatwoski" or
	   unit.type.name == "Hussars" or
	   unit.type.name == "Italian Infantry" or
	   unit.type.name == "Italian Cavalry" or
	   unit.type.name == "Polish Infantry" or
	   unit.type.name == "Polish Lancers" or
	   unit.type.name == "B. Light Infantry" or
	   unit.type.name == "Light Dragoon" or
	   unit.type.name == "B. Horse Artillery" or
	   unit.type.name == "Portuguese Infantry" or
	   unit.type.name == "Portuguese Cavalry" or
	   -- unit.type.name == "Sicilian Infantry" or
	   unit.type.name == "Plunder" then
		if unit.homeCity ~= nil then
			print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
			unit.homeCity = nil
		end
	end

	-- In case players accidentally (or intentionally) re-homed French Minor Powers units, then rehome them to their associated city 
	if unit.type.name == "Bavarian Infantry" or unit.type.name == "Bavarian Cavalry" then
		if unit.homeCity ~= findCityByName("Bavaria") then
			print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
			unit.homeCity = findCityByName("Bavaria")
		end
	end	
	if unit.type.name == "Danish Infantry" or unit.type.name == "Danish Cavalry" then
		if unit.homeCity ~= findCityByName("Denmark") then
			print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
			unit.homeCity = findCityByName("Denmark")
		end
	end	
	if unit.type.name == "Dutch Infantry" or unit.type.name == "Dutch Cavalry" then
		if unit.homeCity ~= findCityByName("United Province") then
			print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
			unit.homeCity = findCityByName("United Province")
		end
	end
	if unit.type.name == "Neapolitan Infantry" then
		if unit.homeCity ~= findCityByName("K. of Naples") then
			print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
			unit.homeCity = findCityByName("K. of Naples")
		end
	end	
	if unit.type.name == "Rhine Infantry" then
		if unit.homeCity ~= findCityByName("Rhineland") then
			print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
			unit.homeCity = findCityByName("Rhineland")
		end
	end
	if unit.type.name == "Swiss Infantry" then
		if unit.homeCity ~= findCityByName("Switzerland") then
			print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
			unit.homeCity = findCityByName("Switzerland")
		end
	end
	if unit.type.name == "Westphalian Infantry" or unit.type.name == "Westphalian Cavalry" then
		if unit.homeCity ~= findCityByName("Westphalia") then
			print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
			unit.homeCity = findCityByName("Westphalia")
		end
	end		
	if unit.type.name == "Würtemberg Infantry" then
		if unit.homeCity ~= findCityByName("Würtemberg") then
			print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
			unit.homeCity = findCityByName("Würtemberg")
		end
	end	
	
-- ==== 4. LEADER ATTACK BONUSES ====
	-- First, reset attack values of all unit types, to revert any changes made to *previously* active unit:
	for i = 0, civ.cosmic.numberOfUnitTypes - 1 do
		civ.getUnitType(i).attack = baseUnitAttack[i]
	end
	-- Then calculate new attack bonus:
	local basetype = unit.type
	local oldAttackValue = basetype.attack
	local attackFactor = 0.0
	local position = unit.location
	if position.z == 0 then
		if unit.owner == France then
			print("    Testing for Leader attack bonuses for " .. basetype.name .. " (ID " .. unit.id .. ") at " .. position.x .. "," .. position.y .. "," .. position.z)
		end
		for stackMember in position.units do
			if stackMember.id ~= unit.id then
				if stackMember.type.name == "Napoléon I" and
				   ( (unit.type.domain == 0 and not(unitIsFrenchCavalry(unit))) or
					unit.type.name == "6 pdr Shells" or
					 unit.type.name == "8 pdr Shells" or
					 unit.type.name == "12 pdr Shells" or
					 unit.type.name == "Mortar Shells" ) then
					if state.napoleonMarriageMarieLouise == false then
						attackFactor = math.max(attackFactor, 0.5)
					else
						attackFactor = math.max(attackFactor, 0.4)
					end
				end
				if stackMember.type.name == "Soult" and
				   ( (unit.type.domain == 0 and not(unitIsFrenchCavalry(unit))) or
					 unit.type.name == "6 pdr Shells" or
					 unit.type.name == "8 pdr Shells" or
					 unit.type.name == "12 pdr Shells" ) then
					attackFactor = math.max(attackFactor, 0.2)
				end
				if stackMember.type.name == "Davout" and
				   ( (unit.type.domain == 0 and not(unitIsFrenchCavalry(unit))) or
					 unit.type.name == "6 pdr Shells" or
					 unit.type.name == "8 pdr Shells" or
					 unit.type.name == "12 pdr Shells") then
					attackFactor = math.max(attackFactor, 0.2)
				end
				if stackMember.type.name == "Lannes" and
				   ( (unit.type.domain == 0 and not(unitIsFrenchCavalry(unit))) or
					 unit.type.name == "6 pdr Shells" or
					 unit.type.name == "8 pdr Shells" or
					 unit.type.name == "12 pdr Shells" or
					 unit.type.name == "Mortar Shells") then
					attackFactor = math.max(attackFactor, 0.3)
				end
				if stackMember.type.name == "Poniatowski" and
				   ( (unit.type.domain == 0 and not(unitIsFrenchCavalry(unit))) or
					 unit.type.name == "6 pdr Shells" or
					 unit.type.name == "8 pdr Shells" or
					 unit.type.name == "12 pdr Shells" ) then
					attackFactor = math.max(attackFactor, 0.2)
				end
				if stackMember.type.name == "Murat" and unitIsFrenchCavalry(unit) then
					attackFactor = math.max(attackFactor, 0.3)
				end
				if stackMember.type.name == "Villeneuve" and unitIsFrenchVesselShell(unit) then
					attackFactor = math.max(attackFactor, 0.2)
				end
				if unit.owner == France then
					print("    Found stack member: " .. stackMember.id .. " (" .. stackMember.type.name .. "), attack factor now = " .. attackFactor)
				end
			end
		end
		attackFactor = attackFactor + 1
		local newAttackValue = round(baseUnitAttack[basetype.id] * attackFactor)
		if newAttackValue ~= oldAttackValue then
			basetype.attack = newAttackValue
			print("Changed attack of " .. unit.owner.adjective .. " " .. basetype.name ..
				" from " .. oldAttackValue .. " to " .. newAttackValue ..
				" (base = " .. baseUnitAttack[basetype.id] .. ", attackFactor = " .. attackFactor .. ")")
		end
	end
-- ==================================

end		-- end of onActivateUnitFunction()
civ.scen.onActivateUnit(onActivateUnitFunction)

-- civ.scen.onBribeUnit(function (unit, previousOwner) end)

civ.scen.onCanBuild(function (defaultBuildFunction, city, item)
	local permitted = defaultBuildFunction(city, item)

-- ==== 2. BUILD LIMITATIONS ====
	if permitted and city.owner == France and civ.isUnitType(item) then
		if item.name == "Sapeurs" and not(civ.hasImprovement(city, findImprovementByName("Recruitment Center")) and civ.hasImprovement(city, findImprovementByName("Siege Workshop"))) then
			permitted = false
		end
		if item.name == "Gendarmes" and not(civ.hasImprovement(city, findImprovementByName("Constabulary"))) then
			permitted = false
		end
		if item.name == "Régiment de Ligne" and not(civ.hasImprovement(city, findImprovementByName("Recruitment Center"))) then
			permitted = false
		end
		if item.name == "Infanterie Légère" and not(civ.hasImprovement(city, findImprovementByName("Recruitment Center"))) then
			permitted = false
		end
		if item.name == "Cuirassiers" and not(civ.hasImprovement(city, findImprovementByName("Stables"))) then
			permitted = false
		end
		if item.name == "Lanciers" and not(civ.hasImprovement(city, findImprovementByName("Stables"))) then
			permitted = false
		end
		if item.name == "Art. à pied 8lb" and not(civ.hasImprovement(city, findImprovementByName("Cannon Foundry"))) then
			permitted = false
		end
		if item.name == "Art. à pied 12lb" and not(civ.hasImprovement(city, findImprovementByName("Cannon Foundry"))) then
			permitted = false
		end
		if item.name == "Art. à Cheval" and not(civ.hasImprovement(city, findImprovementByName("Cannon Foundry")) and civ.hasImprovement(city, findImprovementByName("Stables"))) then
			permitted = false
		end
		if item.name == "Mortier de 12po." and not(civ.hasImprovement(city, findImprovementByName("Cannon Foundry")) and civ.hasImprovement(city, findImprovementByName("Siege Workshop"))) then
			permitted = false
		end
		if item.name == "Bombarde" and not(civ.hasImprovement(city, findImprovementByName("Dockyard")) and civ.hasImprovement(city, findImprovementByName("Siege Workshop"))) then
			permitted = false
		end
		if item.name == "Frégate" and not(civ.hasImprovement(city, findImprovementByName("Dockyard"))) then
			permitted = false
		end
		if item.name == "Deux-ponts" and not(civ.hasImprovement(city, findImprovementByName("Dockyard"))) then
			permitted = false
		end
		if item.name == "Trois-ponts" and not(civ.hasImprovement(city, findImprovementByName("Dockyard"))) then
			permitted = false
		end
		if item.name == "Transport" and not(civ.hasImprovement(city, findImprovementByName("Dockyard"))) then
			permitted = false
		end
		if item.name == "Train Militaire" and not(civ.hasImprovement(city, findImprovementByName("Recruitment Center")) and civ.hasImprovement(city, findImprovementByName("Stables"))) then
			permitted = false
		end
		if permitted == false and city.owner.isHuman then
			print("Blocked building " .. item.name .. " in " .. city.name)
		end
	end
-- ==============================

	return permitted
end)	-- end of civ.scen.onCanBuild()

-- civ.scen.onCentauriArrival(function (tribe) end)

-- civ.scen.onCityDestroyed(function (city) end)

-- civ.scen.onCityFounded(function (city) end)

civ.scen.onCityProduction(function (city, prod)
	if city.owner == Austria and civ.isUnit(prod) and state.austriaIsAtWarWithFrance1 == false and
	   state.austriaIsAtWarWithFrance2 == false and state.austriaIsAtWarWithFrance3 == false then
		for _, typeToBeDestroyed in pairs(austrianUnitTypesToBeDestroyed) do
			if prod.type == typeToBeDestroyed then
				print("Destroyed " .. prod.type.name .. " immediately after it was built in " .. city.name)
				civ.deleteUnit(prod)
			end
		end
	end
	if city.owner == England and civ.isUnit(prod) and state.englandIsAtWarWithFrance == false then
		for _, typeToBeDestroyed in pairs(englishUnitTypesToBeDestroyed) do
			if prod.type == typeToBeDestroyed then
				print("Destroyed " .. prod.type.name .. " immediately after it was built in " .. city.name)
				civ.deleteUnit(prod)
			end
		end
	end
	if city.owner == Ottoman and civ.isUnit(prod) and state.ottomanTreatyOfErdine == true then
		for _, typeToBeDestroyed in pairs(ottomanUnitTypesToBeDestroyed) do
			if prod.type == typeToBeDestroyed then
				print("Destroyed " .. prod.type.name .. " immediately after it was built in " .. city.name)
				civ.deleteUnit(prod)
			end
		end
	end
	if city.owner == Prussia and civ.isUnit(prod) and
	   state.prussiaIsAtWarWithFrance1 == false and state.prussiaIsAtWarWithFrance2 == false then
		for _, typeToBeDestroyed in pairs(prussianUnitTypesToBeDestroyed) do
			if prod.type == typeToBeDestroyed then
				print("Destroyed " .. prod.type.name .. " immediately after it was built in " .. city.name)
				civ.deleteUnit(prod)
			end
		end
	end
	if city.owner == Russia and civ.isUnit(prod) and state.russiaIsSubdued == true then
		for _, typeToBeDestroyed in pairs(russianUnitTypesToBeDestroyed) do
			if prod.type == typeToBeDestroyed then
				print("Destroyed " .. prod.type.name .. " immediately after it was built in " .. city.name)
				civ.deleteUnit(prod)
			end
		end
	end
	if city.owner == Spain and civ.isUnit(prod) and state.spainIsSubdued == true then
		for _, typeToBeDestroyed in pairs(spanishUnitTypesToBeDestroyed) do
			if prod.type == typeToBeDestroyed then
				print("Destroyed " .. prod.type.name .. " immediately after it was built in " .. city.name)
				civ.deleteUnit(prod)
			end
		end
	end
	-- Added for Austrian, English or Spanish controlled cities that may have been transferred to France as part of a treaty agreement as they were producing a unit of their nation
	if city.owner == France and civ.isUnit(prod) then
		for _, typeToBeDestroyed in pairs(austrianUnitTypesToBeDestroyed) do
			if prod.type == typeToBeDestroyed then
				print("Destroyed " .. prod.type.name .. " immediately after it was built in " .. city.name)
				civ.deleteUnit(prod)
			end
		end
		for _, typeToBeDestroyed in pairs(englishUnitTypesToBeDestroyed) do
			if prod.type == typeToBeDestroyed then
				print("Destroyed " .. prod.type.name .. " immediately after it was built in " .. city.name)
				civ.deleteUnit(prod)
			end
		end
		for _, typeToBeDestroyed in pairs(spanishUnitTypesToBeDestroyed) do
			if prod.type == typeToBeDestroyed then
				print("Destroyed " .. prod.type.name .. " immediately after it was built in " .. city.name)
				civ.deleteUnit(prod)
			end
		end
	end
end)	-- end of civ.scen.onCityProduction()

civ.scen.onCityTaken(function (city, defender)
	print("    onCityTaken(): " .. defender.adjective .. " city of " .. city.name .. " taken by " .. city.owner.name)

-- ==== 6. MINOR POWERS ====
-- ------ Baltic States ----
	if city.name == "Warszawa" and city.owner == France then
		JUSTONCE("x_Warszawa_Taken_By_France", function()
			print("Activated Duchy of Warsaw")
			state.minorDuchyOfWarsaw = true
			createUnitsByName("Polish Infantry", France, {{116,46,0}}, {count = 2, homeCity = nil, veteran = false})
			createUnitsByName("Polish Lancers", France, {{116,46,0}}, {count = 2, homeCity = nil, veteran = false})
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your troops have entered the city\n^of Warszawa, to the acclaim of the local population.\n^\r^You instruct Minister Talleyrand to establish the\n^Duchy of Warsaw, whose leaders immediately place\n^their active armed forces under your command."))
		end)
	end
	if city.name == "Warszawa" and defender == France then
		print("Deactivated Duchy of Warsaw")
		state.minorDuchyOfWarsaw = false
		civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, the capital of the Duchy of Warsaw has\n^fallen to the Coalition forces.\n^\r^As such, you will no longer be able to recruit new Polish\n^forces, and those currently in training will be disbanded,\n^though those active troops still under your command will\n^remain loyal to your cause.\n^\r^The Polish dream of an independent state dies here!"))
		local warszawaSupplyTrainTile = civ.getTile(116,48,1)
		warszawaSupplyTrainTile.terrainType = 10
		for unit in civ.iterateUnits() do
			if unit.owner == France and unit.z == 1 then
				for _, typeToBeDestroyed in pairs(polishMinorUnitTypesToBeDestroyed) do
					if unit.type == typeToBeDestroyed then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
			end
		end
	end
-- ------ Italian Minors ----
	if (city.name == "Napoli" or city.name == "Taranto") and city.owner == France then
		local otherCity = nil
		if city.name == "Napoli" then
			otherCity = findCityByName("Taranto")
		else
			otherCity = findCityByName("Napoli")
		end
		if otherCity.owner == France then
			JUSTONCE("x_Kingdom_Of_Naples_Activated", function()
				print("Activated Kingdom of Naples; deactivated Kingdom of Sicily")
				state.minorKingdomOfNaples = true
				--grantTech(France, "Corfu Preparations")
				--state.minorKingdomOfSicily = false
				createUnitsByName("Neapolitan Infantry", France, {{95,103,0}}, {count = 3, homeCity = KofNaples, veteran = false})
				createUnitsByName("Customs Warehouse", France, {{95,103,0}}, {homeCity = nil, veteran = false})
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, your troops have successfully overrun the\n^Kingdom of Naples and its king, Ferdinand IV, flees to Sicily.\n^In his stead, you install your brother Joseph as monarch.\n^\r^Pleased by your ouster of the British, the leaders of the\n^kingdom agree to join your growing empire and place their\n^contingent of troops at your disposal.\n^\r^You also decide to set up a Customs Warehouse in Napoli\n^to start collecting revenue from trade entering the\n^Italian Peninsula..."))
				civ.ui.text(func.splitlines("In addition, the capture of the kingdom will permit you to\n^build a 'sea' route, on the 'European Powers' map between the\n^cities of Taranto and Corfu, the latter of which serves as a base\n^of operations for the Russian navy in the Mediterranean and could\n^become a lucrative trading post with the Ottoman Sultanate for you.\n^\r^To build the route, you simply need to have one of you marshalls,\n^Davout, Lannes or Soult, located in the city of Taranto and press\n^on the 'u' key and a pop up window will appear giving you the option\n^to establish the route for 100 francs. You can establish the route\n^at any time and once created it will be permanent.\n^\r^This 'European Powers' map sea route will be accessible from tile\n^109,105 located just south-east of Taranto."))
			end)
		end
	end
	if city.name == "Napoli" and city.owner ~= France then
		JUSTONCE("x_Kingdom_Of_Naples_Deactivated", function()
			print("Deactivated Kingdom of Naples")
			state.minorKingdomOfNaples = false
			local naplesSupplyTrainTile = civ.getTile(95,101,1)
			naplesSupplyTrainTile.terrainType = 10
		end)
	end
	if city.name == "Genève" and city.owner ~= France then
		JUSTONCE("x_Switzerland_Deactivated", function()
			print("Deactivated Switzerland")
			state.minorSwitzerland = false
			local switzerlandSupplyTrainTile = civ.getTile(68,72,1)
			switzerlandSupplyTrainTile.terrainType = 10
		end)
	end
-- ------ Western Minors
	if (city.name == "Amsterdam" or city.name == "Bruxelles") and city.owner ~= France then
		local otherCity = nil
		if city.name == "Amsterdam" then
			otherCity = findCityByName("Bruxelles")
		else
			otherCity = findCityByName("Amsterdam")
		end
		if otherCity.owner ~= France then
			JUSTONCE("x_Holland_Deactivated", function()
				print("Deactivated Holland")
				state.minorHolland = false
				local hollandSupplyTrainTile = civ.getTile(64,50,1)
				hollandSupplyTrainTile.terrainType = 10
				for unit in civ.iterateUnits() do
					if unit.owner == France then
						for _, typeToBeDestroyed in pairs(dutchMinorUnitTypesToBeDestroyed) do
							if unit.type == typeToBeDestroyed then
								print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
								civ.deleteUnit(unit)
							end
						end
					end
				end
				civ.ui.text("Your Majesty, the Coalition have successfully overrun Holland and as such have compelled the Dutch troops to desert your cause!")
			end)
		end
	end
	if (city.name == "Lübeck" or city.name == "Straslund") and city.owner == France then
		local otherCity = nil
		if city.name == "Lübeck" then
			otherCity = findCityByName("Straslund")
		else
			otherCity = findCityByName("Lübeck")
		end
		if otherCity.owner == France then
			JUSTONCE("x_Denmark_Activated", function ()
				activateDenmark("France controls Lübeck and Straslund")
			end)
		end
	end
	if city.name == "Kobenhavn" and city.owner ~= France then
		JUSTONCE("x_Denmark_Deactivated", function()
			print("Deactivated Denmark")
			state.minorDenmark = false
			local denmarkSupplyTrainTile = civ.getTile(90,28,1)
			denmarkSupplyTrainTile.terrainType = 10
			for unit in civ.iterateUnits() do
				if unit.owner == France then
					for _, typeToBeDestroyed in pairs(danesMinorUnitTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
				end
			end
			civ.ui.text("Your Majesty, the Coalition have captured the Danish capital and as such have compelled the Danes to desert your cause!")
		end)
	end
-- ------ Spanish Partisans ----
	if state.spainIsAtWarWithFrance == true and city.owner == France then
		if city.name == "A Coruna" then -- size 4
			JUSTONCE("x_ACoruna_Taken_By_France", function()
				print("Activated Partisans near A Coruna")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{16,80,0},{17,79,0},{19,77,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Badajoz" then -- size 3
			JUSTONCE("x_Badajoz_Taken_By_France", function()
				print("Activated Partisans near Badajoz")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{12,100,0},{13,103,0}}, {randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Barcelona" then -- size 6
			JUSTONCE("x_Barcelona_Taken_By_France", function()
				print("Activated Partisans near Barcelona")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{48,96,0},{52,94,0},{50,94,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Bilboa" then-- size 5
			JUSTONCE("x_Bilboa_Taken_By_France", function()
				print("Activated Partisans near Bilboa")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{35,85,0},{36,86,0},{33,83,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Burgos" then-- size 3
			JUSTONCE("x_Burgos_Taken_By_France", function()
				print("Activated Partisans near Burgos")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{30,84,0},{30,86,0},{33,87,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Cadiz" then-- size 5
			JUSTONCE("x_Cadiz_Taken_By_France", function()
				print("Activated Partisans near Cadiz")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{15,111,0},{17,111,0},{18,110,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Cartagena" then-- size 4
			JUSTONCE("x_Cartagena_Taken_By_France", function()
				print("Activated Partisans near Cartagena")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{31,111,0},{35,111,0},{36,108,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Ciudad Rodrigo" then-- size 2
			JUSTONCE("x_Ciudad_Rodrigo_Taken_By_France", function()
				print("Activated Partisans near Ciudad Rodrigo")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{16,94,0},{19,93,0}}, {randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Córdoba" then-- size 3
			JUSTONCE("x_Córdoba_Taken_By_France", function()
				print("Activated Partisans near Córdoba")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{22,106,0},{23,105,0},{25,105,0}}, {randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Gijón" then-- size 4
			JUSTONCE("x_Gijón_Taken_By_France", function()
				print("Activated Partisans near Gijón")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{23,81,0},{27,81,0},{24,82,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Madrid" then-- size 8
			JUSTONCE("x_Madrid_Taken_By_France", function()
				print("Activated Partisans near Madrid")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{31,95,0},{28,92,0},{25,95,0},{30,94,0}}, {count = 4, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Málaga" then-- size 6
			JUSTONCE("x_Málaga_Taken_By_France", function()
				print("Activated Partisans near Málaga")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{23,111,0},{26,114,0},{21,111,0},{20,112,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Sevilla" then-- size 6
			JUSTONCE("x_Sevilla_Taken_By_France", function()
				print("Activated Partisans near Sevilla")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{15,105,0},{18,110,0},{18,106,0},{17,111,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Tortosa" then-- size 2
			JUSTONCE("x_Tortosa_Taken_By_France", function()
				print("Activated Partisans near Tortosa")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{41,97,0},{41,99,0}}, {randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Valencia" then-- size 5
			JUSTONCE("x_Valencia_Taken_By_France", function()
				print("Activated Partisans near Valencia")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{40,100,0},{38,102,0},{39,107,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Valladolid" then-- size 5
			JUSTONCE("x_Valladolid_Taken_By_France", function()
				print("Activated Partisans near Valladolid")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{26,86,0},{24,86,0},{24,92,0},{26,92,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		elseif city.name == "Zaragoza" then-- size 5
			JUSTONCE("x_Zaragoza_Taken_By_France", function()
				print("Activated Partisans near Zaragoza")
				civ.playSound("Gendarmes.wav")
				createUnitsByName("Guerrilla", Spain, {{38,94,0},{40,90,0},{39,95,0},{43,91,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		end
	end
-- =========================

-- ==== 7. WAR STATES AND PEACE TREATIES ====
-- Spain
	if city.owner == England and defender == Spain and civ.getTurn() <= 35 then		-- turn 30 is January 1808
		state.spanishCitiesTakenByEngland = state.spanishCitiesTakenByEngland + 1
		print(city.name .. " taken by England; total Spanish cities taken by England: " .. state.spanishCitiesTakenByEngland)
		if state.spanishCitiesTakenByEngland == 1 then
			JUSTONCE("x_French_InvasionOfPortugal_Activated", function ()
				activateFrenchInvasionOfPortugal("England captures first Spanish city")
			end)
		end
		if state.spanishCitiesTakenByEngland == 2 then
			print("Spanish alliance with France is shaken")
			state.spainAllianceWithFranceShaken = true
		end
	end
-- ==========================================

-- ==== 20. PLUNDER UNITS ====
	if city.owner == France then
		local plunderedCityList = {
			"Berlin", "Dresden", "Hamburg", "Hanover", "Königsberg", "Kyïv",
			"Lisboa", "London", "Madrid", "Moskva", "Napoli", "Prag",
			"Roma", "Sankt-Peterburg", "Smolensk", "Venezia", "Wien" }
		for _, plunderedCity in pairs(plunderedCityList) do
			if city.name == plunderedCity then
				JUSTONCE("x_" .. plunderedCity .. "_Plundered", function()
					print(plunderedCity .. " has been plundered by " .. city.owner.name .. "!")
					-- createUnitsByName("Plunder", city.owner, {{city.x, city.y, city.z}}, {homeCity = city, veteran = false})
					createUnitsByName("Plunder", city.owner, {{city.x, city.y, city.z}}, {homeCity = nil, veteran = false})
					civ.ui.text("Your Majesty, your troops have captured " .. plunderedCity .. ". You have ordered the Intendant General to plunder the city's treasury and bring back its booty to France where it can be used to build your biggest construction projects!")
				end)
			end
		end
	end
-- ===========================

-- ==== 23. RANDOM EVENTS ====

-- --- Game tip on DO NOT USE unit if Frankfurt, Stuttgart or Verona are captured
	if (city.name == "Frankfurt" or city.name == "Stuttgart" or city.name == "Verona") and city.owner == France then
		JUSTONCE("x_DO NOT USE_message", function()
			civ.ui.text(func.splitlines("***************** SPECIAL GAME TIP *****************\n^\r^In many instances, you may find that the default item in\n^the production queue of newly conquered cities to be the\n^DO NOT USE unit (a red circle with a stripe across it).\n^\r^As the name implies, these units are not to be used in\n^the game. At the end of each turn, the event file will\n^verify if any such unit exists, and if so delete them.\n^\r^As such, upon entering the city screen of a newly captured\n^city, you will want to go into its production queue and\n^change the item being built as soon as possible.\n^\r^For further explanations on why this was done, check\n^that unit's description in the Military Units section of\n^the Civilopedia."))
		end)
	end

-- ---- Paris captured by anti-French coalition ----
	if city.name == "Paris" and defender == France then
		JUSTONCE("x_Paris_Taken_Game_Ends", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, coalition forces have entered your capital. At the demand\n^of the occupiers, an emergency meeting between your ministers has taken place\n^and they have sent your minister of foreign affairs, Talleyrand, to recommend\n^you abdicate your throne.\n^\r^Under the circumstances, you have no other option but to comply.\n^\r^With no real heir to claim your throne, your generals have no other option but to\n^swear allegiance to the Bourbon king Louis XVIII, whom the Allies have reinstated\n^in your place.\n^\r^The Allies send you in exile to the island of Elba, off the Italian coast, where\n^you will live out the rest of your days.\n^\r^Your imperial ambitions and legacy end here."))
			civ.endGame(true)
		end)
	end

-- ---- France captures Roma ----
	if city.name == "Roma" and city.owner == France then
		JUSTONCE("x_Roma_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^In response to the Emperor's capture of the Eternal city and the\n^annexation by the Kingdom of Italy of many of the Papal territories,\n^Pope Pius VII has excommunicated you.\n^\r^As a consequence, you have ordered the seizure of Papal assets\n^and the capture and confinement of His Holiness, and as such\n^500 francs are added to your treasury.\n^\r^Given the dire relations between the French State and the Papacy,\n^the benefits of the Vatican wonder will not extend to the French Empire."))
			grantTech(France, "Papal confinement")
			changeMoney(France, 500)
		end)
	end
-- ---- Brunswick Taken By France ----
	if city.name == "Brunswick" and city.owner == France then
		JUSTONCE("x_Brunswick_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your troops have captured Brunswick,\n^the capital of the Principality of Brunswick-Wolfenbüttel,\n^and the principal recruiting center for the Prussian led\n^Brunswickian troops."))
		end)
	end
-- ---- Berlin Taken By France ----
	if city.name == "Berlin" and city.owner == France then
		JUSTONCE("x_Berlin_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your troops have entered the\n^Prussian capital of Berlin, as King Frederick III\n^and his entire retinue flee the city in haste to\n^Königsberg.\n^\r^The future of the Prussian state is in peril."))
		end)
	end

-- ---- Cadiz Taken By France ----
	if city.name == "Cadiz" and city.owner == France then
		JUSTONCE("x_Cadiz_Captured_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, after a very bitter and difficult siege\n^your forces have captured the vital objective city of\n^Cadiz.\n^\r^Your troops managed to capture the vital Dockyard\n^installations intact, which if you so desired could\n^serve as an additional ship building yard for your\n^navy.\n^\r^Finally, your forces were able to seize a squadron each\n^of Frigates and Two Decker vessels from the Spanish\n^navy which was using the city as a major naval port."))
			civ.addImprovement(Cadiz, findImprovementByName("Courthouse"))
			civ.addImprovement(Cadiz, findImprovementByName("Fishing Port"))
			createUnitsByName("Frégate", France, {{14,112,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("Deux-ponts", France, {{14,112,0}}, {homeCity = nil, veteran = false})
		end)
	end
-- ---- Danzig Taken By France ----
	if city.name == "Danzig" and city.owner == France then
		JUSTONCE("x_Danzig_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, General Lefebvre confirms that after\n^putting up a valiant defense, the Prussian commander\n^of Danzig, Marshall Kalkreuth, agreed to surrender\n^the city. The garrison was allowed to march out with\n^all the honours of war, with drums beating and\n^standards flying.\n^\r^You proceed to establish the Free City of Danzig, as\n^a semi-independent state under France's tutelage."))
		end)
	end
-- ---- Gibraltar Taken By France ----
	if city.name == "Gibraltar" and city.owner == France then
		JUSTONCE("x_Gibraltar_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your forces have successfully\n^taken the great British fortress of Gilbraltar along\n^with much of the provisions stockpiled in its\n^warehouses, which will increase your coffers by\n^500 francs.\n^\r^Captured from Spain in 1704 by an Anglo-Dutch\n^force, it will no longer serve as a thorn against your\n^armies operating in the Iberian Peninsula."))
			changeMoney(France, 500)
			end)
	end
-- ---- Hanover Taken By France ----
	if city.name == "Hanover" and city.owner == France then
		JUSTONCE("x_Hanover_Taken_By_France", function()
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Hanover))
		end)
	end
-- ---- Leipzig Taken By France ----
	if city.name == "Leipzig" and city.owner == France then
		JUSTONCE("x_Leipzig_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your troops have captured the\n^major objective city of Leipzig, a key town for the\n^control of the kingdom of Saxony and for establishing\n^your supremacy over the continent."))
		end)
	end
-- ---- Lisboa Taken By France ----
	if city.name == "Lisboa" and city.owner == France then
		JUSTONCE("x_Lisboa_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your troops have captured the\n^Portuguese capital of Lisboa, a major objective\n^city in your bid for establishing your rule over\n^the Continent.\n^\r^The quick actions of your commander have allowed\n^him to seize the Coastal Fortress installations of\n^the city before the enemy could destroy them.\n^\r^Unfortunately, the Braganza royal family was able\n^to flee to the Portuguese colony of Brazil just\n^days before your forces entered the city.\n^\r^Some of the Royal treasury that had been left in\n^haste on the docks was seized and will be used to\n^augment your coffers by 250 francs."))
			civ.addImprovement(Lisboa, findImprovementByName("Coastal Fortress"))
			changeMoney(France, 250)
		end)
	end
-- ---- Madgeburg Taken By France ----
	if city.name == "Magdeburg" and city.owner == France then
		JUSTONCE("x_Magdeburg_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your troops have captured the fortress city of\n^Magdeburg. It's Prussian commander, General Friedrich Graf Kleist\n^felt compelled to surrender his garrison when faced with the prospect\n^of a full-scale bombardment."))
		end)
	end
-- ---- Napoli Taken By France ----
	if city.name == "Napoli" and city.owner == France then
		JUSTONCE("x_Napoli_Taken_By_France", function()
			print("Added Fishing Port to Napoli when France captured it")
			civ.addImprovement(Napoli, findImprovementByName("Fishing Port"))
			civ.addImprovement(Napoli, findImprovementByName("Coastal Fortress"))
		end)
	end	
-- ---- Southampton Taken By France ----
	if city.name == "Southampton" and city.owner == France then
		JUSTONCE("x_Southampton_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your troops have captured Southampton\n^with its Coastal defenses intact. In addition, they have\n^seized the port's large supply warehouses which will help\n^to sustain your forces on the island.\n^\r^As such, the city should serve as an important base of\n^operations for your invasion of England."))
			civ.addImprovement(Southampton, findImprovementByName("Coastal Fortress"))
			createUnitsByName("Train Militaire", France, {{48,48,0}}, {homeCity = nil, veteran = false})
		end)
	end
-- ---- Trieste Taken By France ----
	if city.name == "Trieste" and city.owner == France then
		JUSTONCE("x_Trieste_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, your troops have captured the city of Trieste.\n^\r^You have decided to annex it to the Illyrian provinces, which\n^are predominatly populated by Croats and Slovenians, to\n^serve as a buffer with the Austrian Empire.\n^\r^As such, many local inhabitants join the local Gendarmes\n^forces to protect their new found autonomy!"))
			createUnitsByName("Gendarmes", France, {{94,80,0}}, {count = 2, homeCity = nil, veteran = true})
		end)
	end
-- ---- Zaragoza Taken By France ----
	if city.name == "Zaragoza" and city.owner == France then
		JUSTONCE("x_Zaragoza_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, after a long and brutal siege, your forces\n^have overcome the Spanish garrison of Zaragoza. It's\n^commander, General José de Palafox, had taken full\n^advantage of the city's architecture to reinforce its\n^defense.\n^\r^The almost entirely inflammable masonry homes and\n^apartment buildings that were laced together with\n^internal passageways, made each block of the city its own\n^barricaded fortress, with the numerous church buildings\n^standing as keeps and strong-points, from which grapeshot\n^and counter-battery fire could command the streets."))
		end)
	end

-- ---- Ancona, Prag or Wien Taken by France activates Russian Naval Squadron
	if (city.name == "Ancona" or city.name == "Prag" or city.name == "Wien") and city.owner == France then 
		JUSTONCE("x_Ancona_Prag_Wien_Taken_By_France", function()
			print("Activate Russian Mediterranenan Squadron")
			state.corfuIsRussian = true
			local eventLocation = getRandomValidLocation("Three Decker", Russia, {{92,104,0}, {89,113,0}, {100,112,0}, {109,109,0}})
			createUnitsByName("Three Decker", Russia, eventLocation, {homeCity = nil, veteran = true})
			createUnitsByName("Two Decker", Russia, eventLocation, {count = 2, homeCity = nil, veteran = true})
			createUnitsByName("Frigate", Russia, eventLocation, {homeCity = nil, veteran = false})
			civ.ui.text("A Russian naval squadron arrives off the Italian coast to support Allied operations in the region!")
		end)
	end

-- ---- Corfu Taken By France ----
	if city.name == "Corfu" and city.owner == France then
		JUSTONCE("x_Corfu_Taken_By_France", function()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, after a risky invasion, your forces have\n^overcome the Russian garrison on the island city\n^of Corfu.\n^\r^This action will deny the Tsar his only naval base in\n^the Mediterranean and henceforth restrict the Russian\n^navy, notwistanding some stragglers, to the Black Sea.\n^\r^In addition, this island base will provide you with a\n^small trading post with the Ottoman Empire. As long,\n^as your forces control this city, and you are not at\n^war with the Sultanate, 15 francs will be added to\n^the French treasury each month."))
			state.corfuIsRussian = false
		end)
	end

-- ---- Invasion of Russia - confirmations you've captured key city ----
	if state.russiaInvasion == true and city.owner == France then
		if city.name == "Ekaterinoslav" then
			JUSTONCE("x_Ekaterinoslav_Taken_By_France", function()
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, your troops have captured Ekaterinoslav,\n^one of the four objective cities required to force\n^Russia to surrender!"))
			end)
		elseif city.name == "Kyiv" then
			JUSTONCE("x_Kyiv_Taken_By_France", function()
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, your troops have captured Kyiv,\n^one of the four objective cities required to force\n^Russia to surrender!"))
				state.capturedKyiv = true -- Start to generate extra Russian reinforcements in Ekaterinoslav
			end)
		elseif city.name == "Moskva" then
			JUSTONCE("x_Moskva_Taken_By_France", function()
				print("Mosvka taken by France event takes place")
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your Grande Armée enters the city\n^of Moskva, only to find the population evacuated\n^and the Russian army retreated again.\n^\r^Though the city was the primary goal of the invasion,\n^you find it deserted by the czarist officials with\n^no great stores of food or supplies to reward the\n^French soldiers for their long march."))
				grantTech(France, "Captured Moskva") -- Makes Orthodox Church Wonder Obsolete for France
				state.capturedMoskva = true -- Start to generate extra Russian reinforcements in Tver'
			end)
		elseif city.name == "Riga" then
			JUSTONCE("x_Riga_Taken_By_France", function()
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, by seizing Riga you have captured\n^one of the four objective cities required to force\n^Russia to surrender!"))
			end)
		elseif city.name == "Sankt-Peterburg" then
			JUSTONCE("x_Sankt-Peterburg_Taken_By_France", function()
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your troops have captured\n^the capital of Russia, Sankt-Peterburg, a critical\n^objective in your bid to subdue that nation.\n^\r^Surely, the Tsar will begin to see reason and\n^consider your peace offerings!"))
			end)
		elseif city.name == "Smolensk" then
			JUSTONCE("x_Smolensk_Taken_By_France", function()
				print("Smolensk taken by France event takes place")
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, your troops have captured Smolensk, \n^a critical city in your bid to subdue Russia.\n^\r^What resistance will the Russians put up to stop\n^your progression towards Moskva?"))
				state.capturedSmolensk = true -- Generate Russian reaction force
			end)
		elseif city.name == "Vjaz'ma" then
			JUSTONCE("x_Vjazma_Taken_By_France", function()
				print("Vjazma taken by France event takes place")
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, your troops have captured Vjaz'ma\n^and are at the doorstep of Moskva!\n^\r^Unfortunately, the Russians show no sign to date\n^that they intend to capitulate!"))
				-- state.capturedVjazma = true -- Generate Russian reaction force
			end)
		end
	end

-- ---- Third and Fifth Coalition confirmations you've captured key city ----
	if city.owner == France then
		if state.austriaIsAtWarWithFrance1 == true then
			if city.name == "Prag" then
				JUSTONCE("x_Prag_Taken_By_France", function()
					civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, by seizing Prag you have captured one\n^of the three objective cities required to force Austria\n^to surrender, the others being Venezia and Wien!"))
				end)
			elseif city.name == "Venezia" then
				JUSTONCE("x_Venezia_Taken_By_France", function()
					civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, by seizing Venezia you have captured\n^one of the three objective cities required to force\n^Austria to surrender, the others being Prag and Wien!"))
				end)
			elseif city.name == "Wien" then
				JUSTONCE("x_Wien_Taken_By_France", function()
					civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, by seizing Wien you have captured\n^one of the three objective cities required to force\n^Austria to surrender, the others being Prag and Venezia!"))
				end)
			end
		elseif state.austriaIsAtWarWithFrance2 == true then
			if city.name == "Agram" then
				JUSTONCE("x_Agram_Taken_5th_By_France", function()
					civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, by seizing Agram you have captured\n^one of the four objective cities required to force\n^Austria to surrender in the war of the Fifth Coalition,\n^the others being Prag, Trieste and Wien!"))
				end)
			elseif city.name == "Prag" then
				JUSTONCE("x_Prag_Taken_5th_By_France", function()
					civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, by seizing Prag you have captured\n^one of the four objective cities required to force\n^Austria to surrender in the war of the Fifth Coalition,\n^the others being Agram, Trieste and Wien!"))
				end)
			elseif city.name == "Trieste" then
				JUSTONCE("x_Trieste_Taken_5th_By_France", function()
					civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, by seizing Trieste you have captured\n^one of the four objective cities required to force\n^Austria to surrender in the war of the Fifth Coalition,\n^the others being Agram, Prag and Wien!"))
				end)
			elseif city.name == "Wien" then
				JUSTONCE("x_Wien_Taken_5th_By_France", function()
					civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, by seizing Wien you have captured\n^one of the four objective cities required to force\n^Austria to surrender in the war of the Fifth Coalition,\n^the others being Agram, Prag and Trieste!"))
				end)
			end
		end
	end

-- ---- Third Coalition Austria reacts to captured objective cities ----
	if state.austriaIsAtWarWithFrance1 == true and ((city.name == "Prag" or city.name == "Venezia" or city.name == "Wien") and city.owner == France) then
		JUSTONCE("x_Austria_reacts_to_French_Advance", function()
			print("Austria reacts to French Advance Event takes place")
			createUnitsByName("A. Line Infantry", Austria, {{103,67,0}, {96,58,0}, {89,81,0}}, {count = 3, homeCity = nil, veteran = false})
			createUnitsByName("A. Light Infantry", Austria, {{103,67,0}, {96,58,0}, {89,81,0}}, {homeCity = nil, veteran = true})
			createUnitsByName("A. Kürassier", Austria, {{103,67,0}, {96,58,0}, {89,81,0}}, {homeCity = nil, veteran = true})
			createUnitsByName("A. Foot Artillery", Austria, {{103,67,0}, {96,58,0}, {89,81,0}}, {homeCity = nil, veteran = true})
			civ.ui.text("Desperate to halt the French advance, the Austrian Emperor Francis II releases his elite reserve in the hope of stemming the tide!")
		end)
	end
-- ---- British capture French ports event ----
	if state.englandIsAtWarWithFrance == true and city.owner == England and defender == France then
		if city.name == "Anvers" then
			JUSTONCE("x_Anvers_Taken_By_England", function()
				print("British Take Anvers Event takes place")
				createUnitsByName("Minor Fort", England, {{66,48,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("B. Line Infantry", England, {{66,48,0}}, {count = 4, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, {{66,48,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Foot Artillery", England, {{66,48,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Horse Artillery", England, {{66,48,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Dragoon Guards", England, {{66,48,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, {{66,48,0}}, {homeCity = nil, veteran = false})
				civ.ui.text("Your Majesty, the British have taken advantage of the fact that the port of Anvers was poorly defended and landed a very large force to occupy it!")
			end)
		elseif city.name == "Bayonne" then
			JUSTONCE("x_Bayonne_Taken_By_England", function()
				print("British Take Bayonne Event takes place")
				createUnitsByName("B. Line Infantry", England, {{40,84,0}}, {count = 2, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, {{40,84,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, {{40,84,0}}, {homeCity = nil, veteran = false})
				civ.ui.text("Your Majesty, the British have taken advantage of the fact that the port of Bayonne was poorly defended and landed a small force to occupy it!")
			end)
		elseif city.name == "Bordeaux" then
			JUSTONCE("x_Bordeaux_Taken_By_England", function()
				print("British Take Bordeaux Event takes place")
				createUnitsByName("Minor Fort", England, {{44,78,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Line Infantry", England, {{44,78,0}}, {count = 4, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, {{44,78,0}}, {count = 2, homeCity = nil, veteran = false})
				createUnitsByName("B. Foot Artillery", England, {{44,78,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Horse Artillery", England, {{44,78,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Dragoon Guards", England, {{44,78,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, {{44,78,0}}, {homeCity = nil, veteran = false})
				civ.ui.text("Your Majesty, the British have taken advantage of the fact that the port of Bordeaux was poorly defended and landed a very large force to occupy it!")
			end)
		elseif city.name == "Brest" then
			JUSTONCE("x_Brest_Taken_By_England", function()
				print("British Take Brest Event takes place")
				createUnitsByName("Minor Fort", England, {{36,56,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Line Infantry", England, {{36,56,0}}, {count = 3, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, {{36,56,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Foot Artillery", England, {{36,56,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, {{36,56,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Guerrilla", England, {{38,58,0}, {41,51,0}}, {count = 2, homeCity = nil, veteran = true})
				civ.ui.text("Your Majesty, the British have taken advantage of the fact that the port of Brest was poorly defended and landed a sizable force to occupy it! In addition, local french guerrilla units have risen in the hopes of freeing the Vendée region from your control")
			end)
		elseif city.name == "Bruxelles" then
			JUSTONCE("x_Bruxelles_Taken_By_England", function()
				print("British Take Bruxelles Event takes place")
				createUnitsByName("B. Line Infantry", England, {{64,52,0}}, {count = 3, homeCity = nil, veteran = true})
				createUnitsByName("B. Light Infantry", England, {{64,52,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("B. Foot Artillery", England, {{64,52,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("Light Dragoon", England, {{64,52,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("Dragoon Guards", England, {{64,52,0}}, {homeCity = nil, veteran = true})
				civ.ui.text("Your Majesty, the British have captured Bruxelles! A large contingent of local troops have joined them to fight for their independence from your rule!")
			end)
		elseif city.name == "Calais" then
			JUSTONCE("x_Calais_Taken_By_England", function()
				print("British Take Calais Event takes place")
				createUnitsByName("B. Line Infantry", England, {{58,50,0}}, {count = 2, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, {{58,50,0}}, {homeCity = nil, veteran = false})
				civ.ui.text("Your Majesty, the British have taken advantage of the fact that the port of Calais was poorly defended and landed a small force to occupy it!")
			end)
		elseif city.name == "Cherbourg" then
			JUSTONCE("x_Cherbourg_Taken_By_England", function()
				print("British Take Cherbourg Event takes place")
				createUnitsByName("B. Line Infantry", England, {{44,54,0}}, {count = 2, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, {{44,54,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, {{44,54,0}}, {homeCity = nil, veteran = false})
				civ.ui.text("Your Majesty, the British have taken advantage of the fact that the port of Cherbourg was poorly defended and landed a small force to occupy it!")
			end)
		elseif city.name == "La Rochelle" then
			JUSTONCE("x_La_Rochelle_Taken_By_England", function()
				print("British Take La Rochelle Event takes place")
				createUnitsByName("B. Line Infantry", England, {{44,72,0}}, {count = 3, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, {{44,72,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Foot Artillery", England, {{44,72,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, {{44,72,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Guerrilla", England, {{45,69,0}, {47,73,0}}, {count = 2, homeCity = nil, veteran = true})
				civ.ui.text("Your Majesty, the British have taken advantage of the fact that the port of La Rochelle was poorly defended and landed a sizable force to occupy it! In addition, local french guerrilla units have risen in the hopes of freeing the Vendée region from your control.")
			end)
		elseif city.name == "Le Havre" then
			JUSTONCE("x_Le_Havre_Taken_By_England", function()
				print("British Take Le Havre Event takes place")
				createUnitsByName("Minor Fort", England, {{51,55,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("B. Line Infantry", England, {{51,55,0}}, {count = 4, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, {{51,55,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Foot Artillery", England, {{51,55,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Horse Artillery", England, {{51,55,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Dragoon Guards", England, {{51,55,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, {{51,55,0}}, {homeCity = nil, veteran = false})
				civ.ui.text("Your Majesty, the British have taken advantage of the fact that the port of Le Havre was poorly defended and landed a large force to occupy it!")
			end)
		elseif city.name == "Nantes" then
			JUSTONCE("x_Nantes_Taken_By_England", function()
				print("British Take Nantes Event takes place")
				createUnitsByName("B. Line Infantry", England, {{43,65,0}}, {count = 4, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, {{43,65,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Foot Artillery", England, {{43,65,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("B. Horse Artillery", England, {{43,65,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Dragoon Guards", England, {{43,65,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, {{43,65,0}}, {homeCity = nil, veteran = false})
				createUnitsByName("Guerrilla", England, {{42,62,0}, {45,63,0}, {45,67,0}, {44,66,0}}, {count = 4, homeCity = nil, veteran = true})
				civ.ui.text("Your Majesty, the British have taken advantage of the fact that the port of Nantes was poorly defended and landed a large force to occupy it! In addition, it is supported by a major guerrilla uprising in the region, which seeks to avenge its defeat in the War in the Vendée.")
			end)
		end
	end

-- ---- British capture Spanish cities event ----
	if city.owner == England and state.englandIsAtWarWithFrance == true and state.frenchInvasionOfPortugal == true and civ.getTurn() >= 30 then
		if city.name == "Lisboa" then
			JUSTONCE("x_Lisboa_Taken_By_England", function()
				print("British Take Lisboa Event takes place")
				createUnitsByName("Major Fort", England, {{6,98,0}}, {homeCity = nil, veteran = true})
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, grim news, the British have recaptured\n^the Portuguese capital of Lisboa and are reported to\n^have contructed major defensive fortifications to\n^protect the city!"))
			end)
		elseif city.name == "Badajoz" then
			JUSTONCE("x_Badajoz_Taken_By_England", function()
				print("British Take Badajoz Event takes place")
				createUnitsByName("Minor Fort", England, {{15,101,0}}, {homeCity = nil, veteran = false})
				civ.ui.text("Your Majesty, the British have captured the Spanish city of Badajoz and reconnaissance reports indicate that they wasted no time in fortifying it!")
			end)
		elseif city.name == "Ciudad Rodrigo" then
			JUSTONCE("x_Ciudad_Rodrigo_Taken_By_England", function()
				print("British Take Ciudad Rodrigo Event takes place")
				createUnitsByName("Minor Fort", England, {{18,94,0}}, {homeCity = nil, veteran = false})
				civ.ui.text("Your Majesty, the British have captured the Spanish city of Ciudad Rodrigo and reconnaissance reports indicate that they wasted no time in fortifying it!")
			end)
		end
	end
-- ---- British Kingdom of Naples Invasion event ----
	if state.englandIsAtWarWithFrance == true and state.minorKingdomOfNaples == true and ((city.name == "Napoli" or city.name == "Taranto") and city.owner == England) then
		JUSTONCE("x_British_Naples_Invasion_Event", function()
			print("British Naples Invasion Event takes place")
			createUnitsByName("B. Line Infantry", England, {{95,103,0}}, {count = 3, homeCity = nil, veteran = false})
			createUnitsByName("B. Light Infantry", England, {{95,103,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("B. Foot Artillery", England, {{95,103,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("Dragoon Guards", England, {{95,103,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("Light Dragoon", England, {{95,103,0}}, {homeCity = nil, veteran = false})
			civ.ui.text("A British expeditionary force lands in southern Italy to regain control of the Kingdom of Naples!")
		end)
	end
-- ---- Austria recaptures German Minor cities event ----
	if city.owner == Austria and state.austriaIsAtWarWithFrance3 == true then
		if city.name == "Brunswick" then
			JUSTONCE("x_Brunswick_Taken_By_Austria", function()
				print("Austria Takes Brunswick Event takes place")
				createUnitsByName("Brunswick Infantry", Austria, {{86,48,0}}, {count = 3, homeCity = nil, veteran = true})
				createUnitsByName("Brunswick Cavalry", Austria, {{86,48,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Dresden" then
			JUSTONCE("x_Dresden_Taken_By_Austria", function()
				print("Austria Takes Dresden Event takes place")
				createUnitsByName("Saxon Infantry", Austria, {{94,52,0}}, {count = 4, homeCity = nil, veteran = true})
				createUnitsByName("Saxon Cavalry", Austria, {{94,52,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Leipzig" then
			JUSTONCE("x_Leipzig_Taken_By_Austria", function()
				print("Austria Takes Leipzig Event takes place")
				createUnitsByName("Saxon Infantry", Austria, {{91,51,0}}, {count = 3, homeCity = nil, veteran = true})
				createUnitsByName("Saxon Cavalry", Austria, {{91,51,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "München" then
			JUSTONCE("x_München_Taken_By_Austria", function()
				print("Austria Takes München Event takes place")
				createUnitsByName("A. Line Infantry", Austria, {{87,67,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("A. Light Infantry", Austria, {{87,67,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("A. Kürassier", Austria, {{87,67,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("A. Foot Artillery", Austria, {{87,67,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Nürnberg" then
			JUSTONCE("x_Nürnberg_Taken_By_Austria", function()
				print("Austria Takes Nürnberg Event takes place")
				createUnitsByName("A. Line Infantry", Austria, {{86,60,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("A. Light Infantry", Austria, {{86,60,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("A. Uhlans", Austria, {{86,60,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("A. Foot Artillery", Austria, {{86,60,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Ratisbon" then
			JUSTONCE("x_Ratisbon_Taken_By_Austria", function()
				print("Austria Takes Ratisbon Event takes place")
				createUnitsByName("A. Line Infantry", Austria, {{91,63,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("A. Uhlans", Austria, {{91,63,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Trieste" then
			JUSTONCE("x_Trieste_Taken_By_Austria", function()
				print("Austria Takes Trieste Event takes place")
				createUnitsByName("A. Line Infantry", Austria, {{94,80,0}}, {count = 3, homeCity = nil, veteran = true})
				createUnitsByName("A. Light Infantry", Austria, {{94,80,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("A. Uhlans", Austria, {{94,80,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("A. Foot Artillery", Austria, {{94,80,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("A. Horse Artillery", Austria, {{94,80,0}}, {homeCity = nil, veteran = true})
			end)
		end
	end
-- ---- Prussia recaptures German Minor cities event ----
	if city.owner == Prussia and state.prussiaIsAtWarWithFrance2 == true then
		if city.name == "Bremen" then
			JUSTONCE("x_Bremen_Taken_By_Prussia", function()
				print("Prussia Takes Bremen Event takes place")
				createUnitsByName("P. Line Infantry", Prussia, {{80,42,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("P. Light Infantry", Prussia, {{80,42,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Foot Artillery", Prussia, {{80,42,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Brunswick" then
			JUSTONCE("x_Brunswick_Taken_By_Prussia", function()
				print("Prussia Takes Brunswick Event takes place")
				createUnitsByName("Brunswick Infantry", Prussia, {{86,48,0}}, {count = 3, homeCity = nil, veteran = true})
				createUnitsByName("Brunswick Cavalry", Prussia, {{86,48,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Danzig" then
			JUSTONCE("x_Danzig_Taken_By_Prussia", function()
				print("Prussia Takes Danzig Event takes place")
				createUnitsByName("P. Line Infantry", Prussia, {{109,37,0}}, {count = 3, homeCity = nil, veteran = true})
				createUnitsByName("P. Light Infantry", Prussia, {{109,37,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Kürassier", Prussia, {{109,37,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Foot Artillery", Prussia, {{109,37,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Dresden" then
			JUSTONCE("x_Dresden_Taken_By_Prussia", function()
				print("Prussia Takes Dresden Event takes place")
				createUnitsByName("Saxon Infantry", Prussia, {{94,52,0}}, {count = 4, homeCity = nil, veteran = true})
				createUnitsByName("Saxon Cavalry", Prussia, {{94,52,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Hanover" then
			JUSTONCE("x_Hanover_Taken_By_Prussia", function()
				print("Prussia Takes Hanover Event takes place")
				createUnitsByName("P. Kürassier", Prussia, {{83,45,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("P. Uhlans", Prussia, {{83,45,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Horse Artillery", Prussia, {{83,45,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Kassel" then
			JUSTONCE("x_Kassel_Taken_By_Prussia", function()
				print("Prussia Takes Cassel Event takes place")
				createUnitsByName("P. Line Infantry", Prussia, {{81,49,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("P. Light Infantry", Prussia, {{81,49,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Foot Artillery", Prussia, {{81,49,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Küstrin" then
			JUSTONCE("x_Küstrin_Taken_By_Prussia", function()
				print("Prussia Takes Küstrin Event takes place")
				createUnitsByName("P. Line Infantry", Prussia, {{99,47,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("P. Light Infantry", Prussia, {{99,47,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Foot Artillery", Prussia, {{99,47,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Leipzig" then
			JUSTONCE("x_Leipzig_Taken_By_Prussia", function()
				print("Prussia Takes Leipzig Event takes place")
				createUnitsByName("Saxon Infantry", Prussia, {{91,51,0}}, {count = 3, homeCity = nil, veteran = true})
				createUnitsByName("Saxon Cavalry", Prussia, {{91,51,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Posen" then
			JUSTONCE("x_Posen_Taken_By_Prussia", function()
				print("Prussia Takes Posen Event takes place")
				createUnitsByName("P. Line Infantry", Prussia, {{104,46,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("P. Light Infantry", Prussia, {{104,46,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Kürassier", Prussia, {{104,46,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.name == "Thorn" then
			JUSTONCE("x_Thorn_Taken_By_Prussia", function()
				print("Prussia Takes Thorn Event takes place")
				createUnitsByName("P. Line Infantry", Prussia, {{109,43,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("P. Light Infantry", Prussia, {{109,43,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Uhlans", Prussia, {{109,43,0}}, {homeCity = nil, veteran = true})
			end)
		end
	end
-- ---- Prussia liberates Hanover Creates British Intervention ----
	if city.name == "Hanover" and city.owner == Prussia and state.prussiaIsAtWarWithFrance2 == true then
		JUSTONCE("x_Hanover_Taken_By_Coalition", function()
			print("Coalition Captures Hanover Event takes place")
			local eventLocation = getRandomValidLocation("B. Line Infantry", England,
				{{65,45,0}, {63,47,0}, {71,45,0}, {63,49,0}})
			createUnitsByName("B. Line Infantry", England, eventLocation, {count = 3, homeCity = nil, veteran = true})
			createUnitsByName("B. Light Infantry", England, eventLocation, {homeCity = nil, veteran = true})
			createUnitsByName("Light Dragoon", England, eventLocation, {homeCity = nil, veteran = true})
			createUnitsByName("Dragoon Guards", England, eventLocation, {homeCity = nil, veteran = true})
			createUnitsByName("B. Horse Artillery", England, eventLocation, {homeCity = nil, veteran = true})
			createUnitsByName("B. Foot Artillery", England, eventLocation, {homeCity = nil, veteran = true})
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, emboldened by the Coalition's recent\n^successes in Germany, England lands an expeditionary\n^force to liberate Holland from your control!"))
		end)
	end
-- ---- Russia recaptures Moskva event ----
	if city.owner == Russia and state.russiaInvasion == true then
		if city.name == "Moskva" then
			JUSTONCE("x_Moskva_Taken_By_Russia", function()
				print("Russia Takes Moskva Event takes place")
				createUnitsByName("R. Line Infantry", Russia, {{154,24,0}, {157,23,0}, {159,21,0}}, {count = 4, homeCity = nil, veteran = true})
				createUnitsByName("R. Light Infantry", Russia, {{154,24,0}, {157,23,0}, {159,21,0}}, {count = 4, homeCity = nil, veteran = true})
				-- createUnitsByName("Life Guards", Russia, {{154,24,0}, {157,23,0}, {159,21,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("R. Cuirassiers", Russia, {{154,24,0}, {157,23,0}, {159,21,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("R. Foot Artillery", Russia, {{154,24,0}, {157,23,0}, {159,21,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("R. Horse Artillery", Russia, {{154,24,0}, {157,23,0}, {159,21,0}}, {homeCity = nil, veteran = true})
			end)
		end
	end

-- --- Coalition powers capture Warszawa after French invasion of Russia
	if city.name == "Warszawa" and state.russiaInvasion == true and state.russiaIsSubdued == false then
		if city.owner == Russia then
			JUSTONCE("x_Warszawa_Taken_By_Russia", function()
			print("Russia Takes Warszawa Event takes place")
				createUnitsByName("R. Line Infantry", Russia, {{116,46,0}}, {count = 4, homeCity = nil, veteran = true})
				createUnitsByName("R. Light Infantry", Russia, {{116,46,0}}, {count = 4, homeCity = nil, veteran = true})
				-- createUnitsByName("Life Guards", Russia, {{116,46,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("R. Cuirassiers", Russia, {{116,46,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("R. Foot Artillery", Russia, {{116,46,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("R. Horse Artillery", Russia, {{116,46,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.owner == Austria then
			JUSTONCE("x_Warszawa_Taken_By_Austria", function()
			print("Austria Takes Warszawa Event takes place")
				createUnitsByName("A. Line Infantry", Austria, {{116,46,0}}, {count = 4, homeCity = nil, veteran = true})
				createUnitsByName("A. Light Infantry", Austria, {{116,46,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("A. Kürassier", Austria, {{116,46,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("A. Foot Artillery", Austria, {{116,46,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("A. Horse Artillery", Austria, {{116,46,0}}, {homeCity = nil, veteran = true})
			end)
		elseif city.owner == Prussia then
			JUSTONCE("x_Warszawa_Taken_By_Prussia", function()
			print("Prussia Takes Warszawa Event takes place")
				createUnitsByName("P. Line Infantry", Prussia, {{116,46,0}}, {count = 4, homeCity = nil, veteran = true})
				createUnitsByName("P. Light Infantry", Prussia, {{116,46,0}}, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("P. Kürassier", Prussia, {{116,46,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Uhlans", Prussia, {{116,46,0}}, {homeCity = nil, veteran = true})
				createUnitsByName("P. Horse Artillery", Prussia, {{116,46,0}}, {homeCity = nil, veteran = true})
			end)
		end
	end

-- ---- France captures London event ----
	if city.owner == France and state.englandIsAtWarWithFrance == true then
		if city.name == "London" then
			JUSTONCE("x_London_Taken_By_France", function()
				print("France Takes London Event takes place")
				civ.playSound("MilitaryFANFARE_1.wav")
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, your forces have struck a great blow to the British\n^by capturing their capital!\n^\r^Should you also capture Bristol, Birmingham and Liverpool you will,\n^force that nation to capitulate.\n^\r^Unfortunately, the benefits provided by the British Admiralty,\n^British Navy and British Trade wonders are not bestowed upon\n^your Empire (they become obsolete)!"))
				grantTech(France, "Captured London")
				grantTech(France, "Continental Blockade")
			end)
		end
	end

	-- ---- France captures Istanbul event ----
	if city.owner == France and state.ottomanIsAtWarWithFrance == true then
		if city.name == "Istanbul" then
			JUSTONCE("x_Istanbul_Taken_By_France", function()
				print("France Takes Istanbul Event takes place")
				civ.playSound("MilitaryFANFARE_1.wav")
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, your forces have struck a great blow to the Ottoman\n^Sultanate by capturing their great capital of Istanbul!\n^\r^To break the enemy's resolve and force the Sultan to accept peace,\n^you must also seize Ankara, if you haven't already done so.\n^\r^Unfortunately, the benefits provided by the Sultan Ahmed Mosque\n^will not extend to your Empire (it becomes obsolete under your rule)!"))
				grantTech(France, "Captured Istanbul")
			end)
		end
	end
	
-- ===========================

end)	-- end of civ.scen.onCityTaken()

-- civ.scen.onGameEnds(function (reason) end)

local printNextKeyCode = false
civ.scen.onKeyPress(function (keyCode)
	-- ------------------------------------------------------------------------------------------------------
	-- To find the code of any key, press the minus key on the numeric keypad, then the key you want to know
	if printNextKeyCode then
		print("    Detected key code: " .. tostring(keyCode))
	end
	if keyCode == 173 then	-- minus key on the numeric keypad
		printNextKeyCode = true
	else
		printNextKeyCode = false
	end
	-- ------------------------------------------------------------------------------------------------------

	if keyCode == 211 then	-- Tab
		help.helpKey(keyCode, keyCode, nil, customUnitTypeTextTable, customUnitTextFunction)
	end

	if keyCode == 178 then	-- F3 (178)
		local messageText = "Sire, we currently have the following relationships with foreign powers:\n^\r^"
		for i = 1, 7 do
			local tribe = civ.getTribe(i)
			if tribe ~= nil and tribe ~= France and tribe.active then
				messageText = messageText .. tribe.name .. " (" .. tribe.leader.name .. "): "
				if France.treaties[tribe] & 0x0004 == 0x0004 and tribe.treaties[France] & 0x0004 == 0x0004 then
					messageText = messageText .. "Peace Treaty"
					if France.treaties[tribe] & 0x0008 == 0x0008 and tribe.treaties[France] & 0x0008 == 0x0008 then
						messageText = messageText .. " plus Alliance"
					end
				elseif France.treaties[tribe] & 0x2000 == 0x2000 and tribe.treaties[France] & 0x2000 == 0x2000 then
					messageText = messageText .. "At War"
				else
					messageText = messageText .. "Contact"
				end
				messageText = messageText .. "\n^"
			end
		end
		civ.ui.text(func.splitlines(messageText))
	end

	-- Message Board that lists all leaders that were killed during scenario when press 'd' on keyboard
	if keyCode == 214 then	-- "Backspace" (214)
		local messageText = "Sire, the following leaders have perished on the battlefield:\n^\r^"
		if state.diedNone == true then
			messageText = messageText .. "No leader has died!\n^"
		end
		if state.diedCharles == true then
			messageText = messageText .. "Austria: Charles\n^"
		end
		if state.diedSchwarzenberg == true then
			messageText = messageText .. "Austria: Schwarzenberg\n^"
		end
		if state.diedMoore == true then
			messageText = messageText .. "England: Moore\n^"
		end
		if state.diedNelson == true then
			messageText = messageText .. "England: Nelson\n^"
		end
		if state.diedUxbridge == true then
			messageText = messageText .. "England: Uxbridge\n^"
		end
		if state.diedWellington == true then
			messageText = messageText .. "England: Wellington\n^"
		end
		if state.diedDavout == true then
			messageText = messageText .. "France: Davout\n^"
		end
		if state.diedLannes == true then
			messageText = messageText .. "France: Lannes\n^"
		end
		if state.diedMurat == true then
			messageText = messageText .. "France: Murat\n^"
		end
		if state.diedSoult == true then
			messageText = messageText .. "France: Soult\n^"
		end
		if state.diedVilleneuve == true then
			messageText = messageText .. "France: Villeneuve\n^"
		end
		if state.diedPoniatowski == true then
			messageText = messageText .. "Poland: Poniatowski\n^"
		end
		if state.diedBlucher == true then
			messageText = messageText .. "Prussia: Blücher\n^"
		end
		if state.diedYorck == true then
			messageText = messageText .. "Prussia: Yorck\n^"
		end
		if state.diedBagration == true then
			messageText = messageText .. "Russia: Bagration\n^"
		end
		if state.diedBarclaydeTolly == true then
			messageText = messageText .. "Russia: Barclay de Tolly\n^"
		end
		if state.diedKutusov == true then
			messageText = messageText .. "Russia: Kutusov\n^"
		end
		if state.diedBlake == true then
			messageText = messageText .. "Spain: Blake\n^"
		end
		if state.diedCuesta == true then
			messageText = messageText .. "Spain: Cuesta\n^"
		end
		civ.ui.text(func.splitlines(messageText))
	end

	-- Message Board that provide latest status reports for the Empire when press '1' on keyboard
	if keyCode == 49 then	-- '1' (49)
		local messageText = "******************************* " .. displayMonthYear() .. " *******************************\n^Sire, here are the latest status reports for the Empire:\n^\r^"
		if state.englandIsAtWarWithFrance == true then
			if state.january1808 == false then
				if state.frenchMaritimeSupremacy == false then
					messageText = messageText .. "Maritime Supremacy Losses Score:\n^England " .. state.englishNavalUnitsKilled .. " versus France " .. state.frenchNavalUnitsKilled .. "\n^\r^"	
				else
					messageText = messageText .. "Maritime Supremacy Losses Score:\n^England " .. state.englishNavalUnitsKilled .. " versus France " .. state.frenchNavalUnitsKilled .. "  - Maritime Supremacy Achieved!\n^\r^"
				end
			else
				if state.frenchMaritimeSupremacy == false then
					messageText = messageText .. "Naval Losses Score:\n^England " .. state.englishNavalUnitsKilled .. " versus France " .. state.frenchNavalUnitsKilled .. "\n^\r^"	
				else
					messageText = messageText .. "Naval Losses Score:\n^England " .. state.englishNavalUnitsKilled .. " versus France " .. state.frenchNavalUnitsKilled .. "  - Maritime Supremacy Achieved!\n^\r^"
				end
			end
		end
		
		if state.frenchUnitKilled < 44 then
			messageText = messageText .. "French units lost to date: " .. state.frenchUnitKilled .. " out of 44 to lose L'Élan Napoléonien\n^\r^"
		elseif state.frenchUnitKilled >= 44 and state.frenchUnitKilled < 100 then
			messageText = messageText .. "French units lost to date: " .. state.frenchUnitKilled .. " out of 100 to lose the 'Ignore ZOC'\n^\r^"
		elseif state.frenchUnitKilled >= 100 then
			messageText = messageText .. "Total French units lost to date: " .. state.frenchUnitKilled .. "   (use BAT file TWO to switch seasons)\n^\r^"
		end
		
		if state.frenchInvasionOfPortugal == true and state.spainIsSubdued == false then
			messageText = messageText .. "French troops in Iberian Peninsula: " .. getFrenchTroopsInIberia() .. "\n^"
		end
		if state.spainIsSubdued == true then
			messageText = messageText .. "French garrison troops in Spain: " .. getFrenchTroopsInIberia() .. " (30 required to maintain peace)\n^"
			if getFrenchTroopsInIberia() < 30 then
				messageText = messageText .. "; resistance activity costs " .. garrisonCostSpain .. " francs\n^"
			end			
		end
		
		-- if state.englandIsAtWarWithFrance == true and state.russiaIsAtWarWithFrance == false and state.russiaIsSubdued == false then
		if state.russiaIsAtWarWithFrance == false and state.russiaIsSubdued == false then
			messageText = messageText .. "French garrison troops in East Prussia: " .. getFrenchTroopsInPrussia() .. " (out of 25)\n^"
			if getFrenchTroopsInPrussia() < 25 then
				messageText = messageText .. "; contraband costs " .. contrabandCostPrussia .. " francs\n^"
			end
		end
		if state.englandExperiencesFrenchTransgression == true then
			messageText = messageText .. "French troops in England: " .. getFrenchTroopsInEngland() .. "\n^"
		end
		if state.englandIsSubdued == true then
			messageText = messageText .. "French garrison troops in England: " .. getFrenchTroopsInEngland() .. " (15 required to maintain peace)\n^"
			if getFrenchTroopsInEngland() < 15 then
				messageText = messageText .. "; resistance activity costs " .. garrisonCostEngland .. " francs\n^"
			end			
		end

		if state.russiaInvasion == true and state.russiaIsAtWarWithFrance == true then
			messageText = messageText .. "French troops in Russia: " .. getFrenchTroopsInRussia() .. " (65 required to subdue)\n^"
		end
		if state.russiaIsSubdued == true then
			messageText = messageText .. "French garrison troops in Russia: " .. getFrenchTroopsInRussia() .. " (40 required to maintain peace)\n^"
			if getFrenchTroopsInRussia() < 40 and state.spainIsSubdued == true then
				messageText = messageText .. "; resistance activity costs " .. garrisonCostRussia .. " francs\n^"
			end			
		end
		
		local irishRebelsInIreland = getIrishRebelsInIreland()
		if state.englandIsAtWarWithFrance == true and irishRebelsInIreland > 0 then
			messageText = messageText .. "\n^Irish Rebels in Ireland: " .. irishRebelsInIreland .. "; black market adds " .. tostring(irishRebelsInIreland * incomePerIrishRebel) .. " francs"
		end
		local totalTrainMilitaire = 0
		for unit in civ.iterateUnits() do
			if unit.owner == France then
				if unit.type.name == "Train Militaire" then
					totalTrainMilitaire = totalTrainMilitaire + 1
				end
			end
		end		
		if totalTrainMilitaire > 0 then
			messageText = messageText .. "\n^\r^Logistical Report: " .. totalTrainMilitaire .. " active TM(s) will cost " .. tostring(totalTrainMilitaire * costPerTrainMilitaire) .. " francs next month"
		end
		
		local frenchNavyUnits, frenchNavyTotalCost = getFrenchNavyInfo()
		messageText = messageText .. "\n^French Naval Report: " .. frenchNavyUnits .. " active naval unit(s) will cost " .. frenchNavyTotalCost .. " francs next month\n^"

		local totalWarehouses = 0
		for unit in civ.iterateUnits() do
			if unit.owner == France then
				if unit.type.name == "Customs Warehouse" then
					totalWarehouses = totalWarehouses + 1
				end
			end
		end		
		if totalWarehouses > 0 then
			messageText = messageText .. "\n^Customs Warehouses: " .. totalWarehouses .. " warehouses add " .. tostring(totalWarehouses * revenuePerWarehouse) .. " francs next month"
		end
		
		local frenchTradingPost = getFrenchTradingPost() 
		if state.ottomanIsAtWarWithFrance == false and Corfu.owner == France then
			messageText = messageText .. "\n^Corfu Trading Post: " .. frenchTradingPost .. " francs will be added next month\n^"
		end	
		
		local portsControlledByFrance = 0
		local totalPortsFound = 0
		for city in civ.iterateCities() do
		if city.name == "A Coruna" or city.name == "Cadiz" or city.name == "Cartagena" or city.name == "Danzig" or
			city.name == "Hamburg" or city.name == "Lisboa" or city.name == "Napoli" or city.name == "Narva" or
			city.name == "Riga" or city.name == "Splitz" or city.name == "Straslund" or city.name == "Venezia" then
			totalPortsFound = totalPortsFound + 1
				if city.owner == France then
					portsControlledByFrance = portsControlledByFrance + 1
				end
			end
		end
		if portsControlledByFrance > 0 then
			messageText = messageText .. "\n^Continental Ports: control " .. portsControlledByFrance .. " out of 11 ports for Continental Blockade"
		end
		civ.ui.text(func.splitlines(messageText))
	end

	-- Message Board that displays Allied Embargo activities when press '2' on keyboard
	if keyCode == 50 then	-- '2' (50)
		local messageText = "******************** " .. displayMonthYear() .. " ********************\n^Sire, here are the latest embargo figures:\n^\r^"
		if state.englandIsAtWarWithFrance == false then
			messageText = messageText .. "We are not currently at war with England,\n^and no embargo is currently active."
		else
			local embargoShipDetails = getEmbargoShipDetails()
			local embargoShipCount = 0
			for i = 1, 6 do
				if embargoShipDetails[i] ~= nil then
					embargoShipCount = embargoShipCount + embargoShipDetails[i]
				end
			end
			local embargoCostFrance = embargoShipCount * embargoCostPerShipFrance
			local opponentDesc = "British Navy"
			if state.russiaIsAtWarWithFrance == true then
				opponentDesc = "Allied Navies"
			end
			messageText = messageText .. opponentDesc .. " Embargo French Ports:\n^\r^In Zone 1: " .. tostring(embargoShipDetails[1] or 0) .. " Ship(s)\n^In Zone 2: " .. tostring(embargoShipDetails[2] or 0) .. " Ship(s)\n^In Zone 3: " .. tostring(embargoShipDetails[3] or 0) .. " Ship(s)\n^In Zone 4: " .. tostring(embargoShipDetails[4] or 0) .. " Ship(s)\n^In Zone 5: " .. tostring(embargoShipDetails[5] or 0) .. " Ship(s)\n^In Zone 6: " .. tostring(embargoShipDetails[6] or 0) .. " Ship(s)\n^\r^Total Funds We Expect To Be Lost: " .. embargoCostFrance.. "\n^\r^Total Funds Lost to Date: " .. tostring(state.totalEmbargoCost)
		end
		civ.ui.text(func.splitlines(messageText))
	end
	
	-- Message Board that displays different Minor Power activation conditions when press '3' on keyboard
	if keyCode == 51 then	-- '3' (51)
		local dialog = civ.ui.createDialog()
		dialog.title = "Minor Power Activation Conditions"
		dialog.width = 400
		dialog:addText("Please select the French Minor Power:")
		dialog:addOption("Exit",0)
		dialog:addOption("General Minor Power tips", 1)
		dialog:addOption("Batavian Republic (UP)", 2)
		dialog:addOption("Confederation of the Rhine (Rh)", 3)
		dialog:addOption("Duchy of Warsaw (Po)", 4)
		dialog:addOption("Irish Rebels", 5)
		dialog:addOption("Kingdom of Bavaria (Ba)", 6)
		dialog:addOption("Kingdom of Denmark (De)", 7)
		dialog:addOption("Kingdom of Italy (It)", 8)		
		dialog:addOption("Kingdom of Naples (Na)", 9)
		dialog:addOption("Kingdom of Westphalia (We)", 10)
		dialog:addOption("Kingdom of Würtemberg (Wu)", 11)
		dialog:addOption("Swiss Confederation (Sw)", 12)	
		local result = dialog:show()
		if result == 1 then
			civ.ui.text(func.splitlines(scenText.generaltips_MP))
		elseif result == 2 then
			civ.ui.text(func.splitlines(scenText.batavia_MP))
		elseif result == 3 then
			civ.ui.text(func.splitlines(scenText.rhineland_MP))
		elseif result == 4 then
			civ.ui.text(func.splitlines(scenText.warsaw_MP))
		elseif result == 5 then
			civ.ui.text(func.splitlines(scenText.irish_MP))
		elseif result == 6 then
			civ.ui.text(func.splitlines(scenText.bavaria_MP))			
		elseif result == 7 then
			civ.ui.text(func.splitlines(scenText.denmark_MP))	
		elseif result == 8 then
			civ.ui.text(func.splitlines(scenText.italy_MP))
		elseif result == 9 then
			civ.ui.text(func.splitlines(scenText.naples_MP))
		elseif result == 10 then
			civ.ui.text(func.splitlines(scenText.westphalia_MP))	
		elseif result == 11 then
			civ.ui.text(func.splitlines(scenText.wurtemberg_MP))	
		elseif result == 12 then
			civ.ui.text(func.splitlines(scenText.swiss_MP))
		end
	end
	
	-- Message Board that displays different Coalition wars victory conditions when press '4' on keyboard
	if keyCode == 52 then	-- '4' (52)
		local dialog = civ.ui.createDialog()
		dialog.title = "Coalition Wars Victory Conditions"
		dialog.width = 400
		dialog:addText("Please select the Coalition War Conditions:")
		dialog:addOption("Exit",0)
		dialog:addOption("War of the Third Coalition", 1)
		dialog:addOption("War of the Fourth Coalition", 2)
		dialog:addOption("War of the Fifth Coalition", 3)
		dialog:addOption("Achieving Maritime Supremacy (MS)", 4)
		dialog:addOption("Invasion of Portugal", 5)
		dialog:addOption("Franco-Spanish Alliance Renewal", 6)
		dialog:addOption("The Peninsula War", 7)
		dialog:addOption("Invasion of England", 8)
		dialog:addOption("Invasion of Russia", 9)
		dialog:addOption("War of the Sixth Coalition", 10)
		dialog:addOption("Invasion of the Sultanate", 11)
		local result = dialog:show()
		if result == 1 then
			civ.ui.text(func.splitlines(scenText.third_CoalitionWar_VC))
		elseif result == 2 then
			civ.ui.text(func.splitlines(scenText.fourth_CoalitionWar_VC))
		elseif result == 3 then
			civ.ui.text(func.splitlines(scenText.fifth_CoalitionWar_VC))
		elseif result == 4 then
			civ.ui.text(func.splitlines(scenText.maritimeSupremacy_VC))
		elseif result == 5 then
			civ.ui.text(func.splitlines(scenText.invasionOfPortugal_VC))
		elseif result == 6 then
		civ.ui.text(func.splitlines(scenText.francoSpanish_Alliance_VC))
		elseif result == 7 then
			civ.ui.text(func.splitlines(scenText.peninsulaWar_VC))
		elseif result == 8 then
			civ.ui.text(func.splitlines(scenText.invasionOfEngland_VC))
		elseif result == 9 then
			civ.ui.text(func.splitlines(scenText.invasionOfRussia_VC))
		elseif result == 10 then
			civ.ui.text(func.splitlines(scenText.sixth_CoalitionWar_VC))
		elseif result == 11 then
			civ.ui.text(func.splitlines(scenText.invasionOfSultanate_VC))		
		end
	end
	
	-- Message Board that displays different game tips when press '5' on keyboard
	if keyCode == 53 then	-- '5' (53)
		local dialog = civ.ui.createDialog()
		dialog.title = "Game Tips - One"
		dialog.width = 400
		dialog:addText("Please select the Game Tip Information:")
		dialog:addOption("Exit",0)
		dialog:addOption("French Artillery and Shells", 1)
		dialog:addOption("French Leader Bonuses", 2)
		dialog:addOption("French Leader Bonuses Application", 3)
		dialog:addOption("French Hussars", 4)
		dialog:addOption("L'Élan Napoléonien", 5)
		dialog:addOption("French Vessels and Naval Shells", 6)
		dialog:addOption("French Vessels Maintenance Costs", 7)
		dialog:addOption("French Privateers", 8)
		dialog:addOption("French Leaders Administrative Bonuses", 9)
		dialog:addOption("France Researches Infrastructure Advance", 10)		
		dialog:addOption("France Researches New Naval Base Advance", 11)	
		dialog:addOption("Automatic French Victory", 12)
		local result = dialog:show()
		if result == 1 then
			civ.ui.text(func.splitlines(scenText.introGameTip1))
		elseif result == 2 then
			civ.ui.text(func.splitlines(scenText.introGameTip2a))
		elseif result == 3 then
			civ.ui.text(func.splitlines(scenText.introGameTip2b))
		elseif result == 4 then
			civ.ui.text(func.splitlines(scenText.introGameTip3))
		elseif result == 5 then
			civ.ui.text(func.splitlines(scenText.introGameTip4))
		elseif result == 6 then
			civ.ui.text(func.splitlines(scenText.introGameTip5_a))
		elseif result == 7 then
			civ.ui.text(func.splitlines(scenText.introGameTip5_b))
		elseif result == 8 then
			civ.ui.text(func.splitlines(scenText.introGameTip14))
		elseif result == 9 then
			civ.ui.text(func.splitlines(scenText.introGameTip6))
			civ.ui.text(func.splitlines(scenText.introGameTip7))
		elseif result == 10 then
			civ.ui.text(func.splitlines(scenText.researchInfrastructure))
		elseif result == 11 then		
			civ.ui.text(func.splitlines(scenText.researchNewNavalBase))
		elseif result == 12 then
			civ.ui.text(func.splitlines(scenText.introGameTip12))	
		end
	end
	
	-- Message Board that displays different game tips when press '6' on keyboard
	if keyCode == 54 then	-- '6' (6)
		local dialog = civ.ui.createDialog()
		dialog.title = "Game Tips - Two"
		dialog.width = 400
		dialog:addText("Please select the Game Tip Information:")
		dialog:addOption("Exit",0)
		dialog:addOption("Barbary Pirates", 1)
		dialog:addOption("Coalition Core Cities", 2)
		dialog:addOption("French Garrison Duties East", 3)
		dialog:addOption("French Garrison Duties West", 4)
		dialog:addOption("Message Boards", 5)
		dialog:addOption("Seasonal Attrition Penalties", 6)
		dialog:addOption("Sea Route to Corfu", 7)
		dialog:addOption("Siege Warfare", 8)
		dialog:addOption("Special Map Transit Points", 9)
		local result = dialog:show()
		if result == 1 then
			civ.ui.text(func.splitlines(scenText.introGameTip19))
		elseif result == 2 then
			civ.ui.text(func.splitlines(scenText.introGameTip9))		
		elseif result == 3 then
					civ.ui.text(func.splitlines(scenText.introGameTip16))
		elseif result == 4 then
			civ.ui.text(func.splitlines(scenText.introGameTip18))
		elseif result == 5 then
			civ.ui.text(func.splitlines(scenText.introGameTip11))	
		elseif result == 6 then
			civ.ui.text(func.splitlines(scenText.introGameTip10))
		elseif result == 7 then
			civ.ui.text(func.splitlines(scenText.introGameTip17))
		elseif result == 8 then
			civ.ui.text(func.splitlines(scenText.introGameTip13))
		elseif result == 9 then
			civ.ui.text(func.splitlines(scenText.introGameTip15))	
		end
	end
	
	if keyCode == 75 then	-- lowercase "k" (75)
		local activeUnit = civ.getActiveUnit()
		if activeUnit ~= nil and activeUnit.owner == France then

			-- ==== 1. ARTILLERY UNITS ====
			local multiplier = civ.cosmic.roadMultiplier
			--[[
			print("    civ.cosmic.roadMultiplier: " .. civ.cosmic.roadMultiplier)
			if totpp.movementMultipliers then
				print("    totpp.movementMultipliers.road: " .. totpp.movementMultipliers.road)
				print("    totpp.movementMultipliers.railroad: " .. totpp.movementMultipliers.railroad)
				print("    totpp.movementMultipliers.aggregate: " .. totpp.movementMultipliers.aggregate)
			end
			]]
			--[[
			Formula for an artillery unit that should use all of its remaining movement points when a munition is fired:
				activeUnit.moveSpent = activeUnit.type.move

			Formula for an artillery unit to use fixed N movement points per munition fired:
				activeUnit.moveSpent = math.min(activeUnit.moveSpent + (N * multiplier), activeUnit.type.move)

			Formula for an artillery unit to be able to fire a max of 2 munitions per turn:
				activeUnit.moveSpent = math.min(activeUnit.moveSpent + (activeUnit.type.move / 2), activeUnit.type.move)
			Formula for an artillery unit to be able to fire a max of 3 munitions per turn:
				activeUnit.moveSpent = math.min(activeUnit.moveSpent + (math.ceil(activeUnit.type.move / (3 * multiplier)) * multiplier), activeUnit.type.move)
			]]

			if activeUnit.type.name == "Art. à Cheval" then
				if France.money >= 3 then
					local projectile = createUnitsByName("6 pdr Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
					activeUnit.moveSpent = math.min(activeUnit.moveSpent + (1 * multiplier), activeUnit.type.move)
					changeMoney(France, -3)
					projectile:activate()
					onActivateUnitFunction(projectile, true)
				else
					civ.ui.text("The minister of finance, Martin-Michel-Charles Gaudin, confirms the war effort has depleted the treasury and is unable to muster the measly 3 francs required to pay France's munitions manufacturers. Until the finances are redressed no more munitions will be forthcoming.")
				end
			end
			if activeUnit.type.name == "Art. à pied 8lb" then
				if France.money >= 4 then
					local projectile = createUnitsByName("8 pdr Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
					activeUnit.moveSpent = math.min(activeUnit.moveSpent + (1 * multiplier), activeUnit.type.move)
					changeMoney(France, -4)
					projectile:activate()
					onActivateUnitFunction(projectile, true)
				else
					civ.ui.text("The minister of finance, Martin-Michel-Charles Gaudin, confirms the war effort has depleted the treasury and is unable to muster the measly 4 francs required to pay France's munitions manufacturers. Until the finances are redressed no more munitions will be forthcoming.")
				end
			end
			if activeUnit.type.name == "Art. à pied 12lb" then
				if France.money >= 6 then
					local projectile = createUnitsByName("12 pdr Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
					activeUnit.moveSpent = math.min(activeUnit.moveSpent + (1 * multiplier), activeUnit.type.move)
					changeMoney(France, -6)
					projectile:activate()
					onActivateUnitFunction(projectile, true)
				else
					civ.ui.text("The minister of finance, Martin-Michel-Charles Gaudin, confirms the war effort has depleted the treasury and is unable to muster the measly 6 francs required to pay France's munitions manufacturers. Until the finances are redressed no more munitions will be forthcoming.")
				end
			end
			if activeUnit.type.name == "Mortier de 12po." then
				if France.money >= 9 then
					if activeUnit.location.improvements & 0x42 == 0x42 then		-- & 0x42 means "contains siege work (airfield)"
						local projectile = createUnitsByName("Mortar Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
						activeUnit.moveSpent = activeUnit.type.move
						changeMoney(France, -9)
						projectile:activate()
						onActivateUnitFunction(projectile, true)
					else
						civ.ui.text("Mortier de 12po. may only fire from terrain with the Siege Work improvement!")
					end
				else
					civ.ui.text("The minister of finance, Martin-Michel-Charles Gaudin, confirms the war effort has depleted the treasury and is unable to muster the measly 9 francs required to pay France's munitions manufacturers. Until the finances are redressed no more munitions will be forthcoming.")
				end
			end
			if activeUnit.type.name == "Frégate" then
				if France.money >= 4 then
					if activeUnit.location.terrainType & 0x0F == 0x0A then 	-- 0x0A equals Ocean tile
						local projectile = createUnitsByName("18 pdr Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
						activeUnit.moveSpent = activeUnit.type.move
						changeMoney(France, -4)
						projectile:activate()
						onActivateUnitFunction(projectile, true)
					else
						civ.ui.text("Naval units may only generate naval shells while at sea!")
					end
				else
					civ.ui.text("The minister of finance, Martin-Michel-Charles Gaudin, confirms the war effort has depleted the treasury and is unable to muster the measly 4 francs required to pay France's munitions manufacturers. Until the finances are redressed no more munitions will be forthcoming.")
				end
			end
			if activeUnit.type.name == "Deux-ponts" then
				if France.money >= 5 then
					if activeUnit.location.terrainType & 0x0F == 0x0A then 	-- & 0x0A equals Ocean tile
						--local projectile = createUnitsByName("18 pdr Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
						--activeUnit.moveSpent = math.min(activeUnit.moveSpent + (activeUnit.type.move / 2), activeUnit.type.move)
						local projectile = createUnitsByName("24 pdr Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
						activeUnit.moveSpent = activeUnit.type.move
						changeMoney(France, -5)
						projectile:activate()
						onActivateUnitFunction(projectile, true)
					else
						civ.ui.text("Naval units may only generate naval shells while at sea!")
					end
				else
					civ.ui.text("The minister of finance, Martin-Michel-Charles Gaudin, confirms the war effort has depleted the treasury and is unable to muster the measly 5 francs required to pay France's munitions manufacturers. Until the finances are redressed no more munitions will be forthcoming.")
				end
			end
			if activeUnit.type.name == "Trois-ponts" then
				if France.money >= 9 then
					if activeUnit.location.terrainType & 0x0F == 0x0A then 	-- & 0x0A equals Ocean tile
						local projectile = createUnitsByName("32 pdr Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
						activeUnit.moveSpent = activeUnit.type.move
						changeMoney(France, -9)
						projectile:activate()
						onActivateUnitFunction(projectile, true)
					else
						civ.ui.text("Naval units may only generate naval shells while at sea!")
					end
				else
					civ.ui.text("The minister of finance, Martin-Michel-Charles Gaudin, confirms the war effort has depleted the treasury and is unable to muster the measly 9 francs required to pay France's munitions manufacturers. Until the finances are redressed no more munitions will be forthcoming.")
				end
			end
			if activeUnit.type.name == "Bombarde" then
				if France.money >= 9 then
					if activeUnit.location.terrainType & 0x0F == 0x0A then 	-- & 0x0A equals Ocean tile
						local projectile = createUnitsByName("Bombard Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
						activeUnit.moveSpent = math.min(activeUnit.moveSpent + (activeUnit.type.move / 2), activeUnit.type.move)
						changeMoney(France, -9)
						projectile:activate()
						onActivateUnitFunction(projectile, true)
					else
						civ.ui.text("Naval units may only generate naval shells while at sea!")
					end
				else
					civ.ui.text("The minister of finance, Martin-Michel-Charles Gaudin, confirms the war effort has depleted the treasury and is unable to muster the measly 9 francs required to pay France's munitions manufacturers. Until the finances are redressed no more munitions will be forthcoming.")
				end
			end
			if activeUnit.type.name == "Villeneuve" then
				if France.money >= 9 then
					if activeUnit.location.terrainType & 0x0F == 0x0A then 	-- & 0x0A equals Ocean tile
						local projectile = createUnitsByName("32 pdr Shells", France, {{activeUnit.location.x, activeUnit.location.y, activeUnit.location.z}}, {homeCity = nil, veteran = false})
						activeUnit.moveSpent = activeUnit.type.move
						changeMoney(France, -9)
						projectile:activate()
						onActivateUnitFunction(projectile, true)
					else
						civ.ui.text("Naval units may only generate naval shells while at sea!")
					end
				else
					civ.ui.text("The minister of finance, Martin-Michel-Charles Gaudin, confirms the war effort has depleted the treasury and is unable to muster the measly 9 francs required to pay France's munitions manufacturers. Until the finances are redressed no more munitions will be forthcoming.")
				end
			end
			-- ============================

			-- ==== 5. LEADER ADMINISTRATIVE BONUSES ====
			-- Napoléon administrative bonus
			if activeUnit.type.name == "Napoléon I" then
				local ParisLocation = civ.getTile(58,60,0)
				if activeUnit.location == ParisLocation then
					local dialog = civ.ui.createDialog()
					dialog.title = "Select Administrative Bonus"
					dialog.width = 535
					dialog:addText("Please select the Napoléon administrative bonus you prefer:")
					dialog:addOption("Add to the Treasury and increase scientific research", 1)
					local unitCost = 600
					if France.money >= unitCost then
						dialog:addOption("Build two veteran Régiment de Ligne units at a cost of " .. unitCost .. " francs", 2)
					else
						civ.ui.text("If the treasury contains at least " .. unitCost .. " francs, Napoléon will have an additional administrative bonus option of building two Régiment de Ligne units.")
					end
					dialog:addOption("Exit (do not utilize the administrative bonus)", 0)
					local result = dialog:show()
					if result == 1 then
						local goldAmount = 200
						local scienceAmount = 100
						if state.napoleonMarriageMarieLouise == true then
							goldAmount = 150
							scienceAmount = 50
						end
						civ.ui.text(func.splitlines("Napoléon administrative bonus:\n^\r^" .. goldAmount .. " francs, " .. scienceAmount .. " research beakers"))
						changeMoney(France, goldAmount)
						France.researchProgress = France.researchProgress + scienceAmount
						local administrativeUnit = findUnitTypeByName("Napoléon I");
						activeUnit.moveSpent = administrativeUnit.move
					elseif result == 2 then
						local unitTypeName = "Régiment de Ligne"
						civ.ui.text(func.splitlines("Napoléon administrative bonus:\n^\r^2 veteran " .. unitTypeName .. " units are recruited at a cost of " .. unitCost .. " francs"))
						changeMoney(France, unitCost * -1)
						createUnitsByName("Régiment de Ligne", France, {{58,60,0}}, {count = 2, homeCity = Paris, veteran = true})
						local administrativeUnit = findUnitTypeByName("Napoléon I");
						activeUnit.moveSpent = administrativeUnit.move
					end
				else
					civ.ui.text("In order for Napoléon to provide an administrative bonus, he must be located in Paris!")
				end
			end
			-- Murat administrative bonus
			if activeUnit.type.name == "Murat" then
				local HanoverLocation = civ.getTile(83,45,0)
				if activeUnit.location == HanoverLocation then
					if France.money >= 450 then
						local dialog = civ.ui.createDialog()
						dialog.title = "Select Administrative Bonus"
						dialog.width = 535
						dialog:addText("Please select the Maréchal Murat administrative bonus you prefer:")
						dialog:addOption("Build a veteran Lanciers unit at a cost of 450 francs", 1)
						if France.money >= 500 then
							dialog:addOption("Build a veteran Cuirassiers unit at a cost of 500 francs", 2)
						end
						dialog:addOption("Exit (do not utilize the administrative bonus)", 0)
						local result = dialog:show()
						local unitTypeName = "Lanciers"
						local cost = 450
						if result == 2 then
							unitTypeName = "Cuirassiers"
							cost = 500
						end
						if result == 1 or result == 2 then
							civ.ui.text(func.splitlines("Murat administrative bonus:\n^\r^1 veteran " .. unitTypeName .. " unit is recruited at a cost of " .. cost .. " francs"))
							changeMoney(France, cost * -1)
							createUnitsByName(unitTypeName, France, {{83,45,0}}, {homeCity = findCityByName("Hanover"), veteran = true})
							local administrativeUnit = findUnitTypeByName("Murat");
							activeUnit.moveSpent = administrativeUnit.move
						end
					else
						civ.ui.text("In order for Murat to provide an administrative bonus, the treasury must contain at least 450 francs!")
					end
				else
					civ.ui.text("In order for Murat to provide an administrative bonus, he must be located in Hanover!")
				end
			end
			-- Soult administrative bonus
			if activeUnit.type.name == "Soult" then
				local StrasbourgLocation = civ.getTile(74,64,0)
				local ToulouseLocation = civ.getTile(50,84,0)
				if activeUnit.location == StrasbourgLocation or activeUnit.location == ToulouseLocation then
					if France.money >= 200 then
						local dialog = civ.ui.createDialog()
						dialog.title = "Select Administrative Bonus"
						dialog.width = 535
						dialog:addText("Please select the Maréchal Soult administrative bonus you prefer:")
						dialog:addOption("Build a regular Régiment de Ligne unit at a cost of 200 francs", 1)
						if France.money >= 260 then
							dialog:addOption("Build a veteran Infanterie Légère unit at a cost of 260 francs", 2)
						end
						dialog:addOption("Exit (do not utilize the administrative bonus)", 0)
						local result = dialog:show()
						local unitTypeName = "Régiment de Ligne"
						local cost = 200
						if result == 2 then
							unitTypeName = "Infanterie Légère"
							cost = 260
						end
						if result == 1 then
							civ.ui.text(func.splitlines("Soult administrative bonus:\n^\r^1 regular " .. unitTypeName .. " unit is recruited at a cost of " .. cost .. " francs"))
							changeMoney(France, cost * -1)
							if activeUnit.location == StrasbourgLocation then
								createUnitsByName(unitTypeName, France, {{74,64,0}}, {homeCity = findCityByName("Strasbourg"), veteran = false})
							else
								createUnitsByName(unitTypeName, France, {{50,84,0}}, {homeCity = findCityByName("Toulouse"), veteran = false})
							end
							local administrativeUnit = findUnitTypeByName("Soult");
							activeUnit.moveSpent = administrativeUnit.move
						elseif result == 2 then
							civ.ui.text(func.splitlines("Soult administrative bonus:\n^\r^1 veteran" .. unitTypeName .. " unit is recruited at a cost of " .. cost .. " francs"))
							changeMoney(France, cost * -1)
							if activeUnit.location == StrasbourgLocation then
								createUnitsByName(unitTypeName, France, {{74,64,0}}, {homeCity = findCityByName("Strasbourg"), veteran = true})
							else
								createUnitsByName(unitTypeName, France, {{50,84,0}}, {homeCity = findCityByName("Toulouse"), veteran = true})
							end
							local administrativeUnit = findUnitTypeByName("Soult");
							activeUnit.moveSpent = administrativeUnit.move
						end
					else
						civ.ui.text("In order for Soult to provide an administrative bonus, the treasury must contain at least 200 francs!")
					end
				else
					civ.ui.text("In order for Soult to provide an administrative bonus, he must be located in either Strasbourg or Toulouse!")
				end
			end
			-- Davout administrative bonus
			if activeUnit.type.name == "Davout" then
				local StrasbourgLocation = civ.getTile(74,64,0)
				local ToulouseLocation = civ.getTile(50,84,0)
				if activeUnit.location == StrasbourgLocation or activeUnit.location == ToulouseLocation then
					if France.money >= 200 then
						local dialog = civ.ui.createDialog()
						dialog.title = "Select Administrative Bonus"
						dialog.width = 535
						dialog:addText("Please select the Maréchal Davout administrative bonus you prefer:")
						dialog:addOption("Build a regular Régiment de Ligne unit at a cost of 200 francs", 1)
						if France.money >= 260 then
							dialog:addOption("Build a veteran Infanterie Légère unit at a cost of 260 francs", 2)
						end
						dialog:addOption("Exit (do not utilize the administrative bonus)", 0)
						local result = dialog:show()
						local unitTypeName = "Régiment de Ligne"
						local cost = 200
						if result == 2 then
							unitTypeName = "Infanterie Légère"
							cost = 260
						end
						if result == 1 then
							civ.ui.text(func.splitlines("Davout administrative bonus:\n^\r^1 regular " .. unitTypeName .. " unit is recruited at a cost of " .. cost .. " francs"))
							changeMoney(France, cost * -1)
							if activeUnit.location == StrasbourgLocation then
								createUnitsByName(unitTypeName, France, {{74,64,0}}, {homeCity = findCityByName("Strasbourg"), veteran = false})
							else
								createUnitsByName(unitTypeName, France, {{50,84,0}}, {homeCity = findCityByName("Toulouse"), veteran = false})
							end
							local administrativeUnit = findUnitTypeByName("Davout");
							activeUnit.moveSpent = administrativeUnit.move
						elseif result == 2 then
							civ.ui.text(func.splitlines("Davout administrative bonus:\n^\r^1 veteran " .. unitTypeName .. " unit is recruited at a cost of " .. cost .. " francs"))
							changeMoney(France, cost * -1)
							if activeUnit.location == StrasbourgLocation then
								createUnitsByName(unitTypeName, France, {{74,64,0}}, {homeCity = findCityByName("Strasbourg"), veteran = true})
							else
								createUnitsByName(unitTypeName, France, {{50,84,0}}, {homeCity = findCityByName("Toulouse"), veteran = true})
							end
							local administrativeUnit = findUnitTypeByName("Davout");
							activeUnit.moveSpent = administrativeUnit.move						
						end
					else
						civ.ui.text("In order for Davout to provide an administrative bonus, the treasury must contain at least 200 francs!")
					end
				else
					civ.ui.text("In order for Davout to provide an administrative bonus, he must be located in either Strasbourg or Toulouse!")
				end
			end
			-- Lannes administrative bonus
			if activeUnit.type.name == "Lannes" then
				local StrasbourgLocation = civ.getTile(74,64,0)
				local ToulouseLocation = civ.getTile(50,84,0)
				if activeUnit.location == StrasbourgLocation or activeUnit.location == ToulouseLocation then
					if France.money >= 200 then
						local dialog = civ.ui.createDialog()
						dialog.title = "Select Administrative Bonus"
						dialog.width = 535
						dialog:addText("Please select the Maréchal Lannes administrative bonus you prefer:")
						dialog:addOption("Build a regular Régiment de Ligne unit at a cost of 200 francs", 1)
						if France.money >= 260 then
							dialog:addOption("Build a veteran Infanterie Légère unit at a cost of 260 francs", 2)
						end
						dialog:addOption("Exit (do not utilize the administrative bonus)", 0)
						local result = dialog:show()
						local unitTypeName = "Régiment de Ligne"
						local cost = 200
						if result == 2 then
							unitTypeName = "Infanterie Légère"
							cost = 260
						end
						if result == 1 then
							civ.ui.text(func.splitlines("Lannes administrative bonus:\n^\r^1 regular " .. unitTypeName .. " unit is recruited at a cost of " .. cost .. " francs"))
							changeMoney(France, cost * -1)
							if activeUnit.location == StrasbourgLocation then
								createUnitsByName(unitTypeName, France, {{74,64,0}}, {homeCity = findCityByName("Strasbourg"), veteran = false})
							else
								createUnitsByName(unitTypeName, France, {{50,84,0}}, {homeCity = findCityByName("Toulouse"), veteran = false})
							end
							local administrativeUnit = findUnitTypeByName("Lannes");
							activeUnit.moveSpent = administrativeUnit.move
						elseif result == 2 then
							civ.ui.text(func.splitlines("Lannes administrative bonus:\n^\r^1 veteran " .. unitTypeName .. " unit is recruited at a cost of " .. cost .. " francs"))
							changeMoney(France, cost * -1)
							if activeUnit.location == StrasbourgLocation then
								createUnitsByName(unitTypeName, France, {{74,64,0}}, {homeCity = findCityByName("Strasbourg"), veteran = true})
							else
								createUnitsByName(unitTypeName, France, {{50,84,0}}, {homeCity = findCityByName("Toulouse"), veteran = true})
							end
							local administrativeUnit = findUnitTypeByName("Lannes");
							activeUnit.moveSpent = administrativeUnit.move						
						end
					else
						civ.ui.text("In order for Lannes to provide an administrative bonus, the treasury must contain at least 200 francs!")
					end
				else
					civ.ui.text("In order for Lannes to provide an administrative bonus, he must be located in either Strasbourg or Toulouse!")
				end
			end
			
			-- ==========================================
			-- Russian Invasion Preparations Option
			if activeUnit.type.name == "Poniatowski" then
				JUSTONCE("x_Russian_Preparations", function ()
					local WarzsawaLocation = civ.getTile(116,46,0)
					if activeUnit.location == WarzsawaLocation then
						if France.money >= 800 then
							local dialog = civ.ui.createDialog()
							dialog.title = "Select Russian Preparation Option"
							dialog.width = 550
							dialog:addText("Please select the Russian Invasion Preparation Option you prefer:")
							dialog:addOption("Option 1: recruit a Train Militaire, a Sapeurs and an Art. à pied 12lb for 800 francs", 1)
							if France.money >= 1000 then
								dialog:addOption("Option 2: recruit an extra 5 Régiment de Ligne for 1000 francs", 2)
							end
							if France.money >= 1800 then
								dialog:addOption("Option 3: get the units from both option 1 and 2 for 1800 francs", 3)
							end
							dialog:addOption("Exit (if you choose to exit you will forever forfeit your ability to raise the extra units)", 0)
							local result = dialog:show()
							local option = "Option 1"
							local cost = 800
							if result == 2 then
								option = "Option 2"
								cost = 1000
							end
							if result == 3 then
								option = "Option 3"
								cost = 1800
							end
							if result == 1 then
								civ.ui.text("You selected " .. option .. " for your Russian Invasion at a cost of " .. cost .. " francs")
								changeMoney(France, cost * -1)
								createUnitsByName("Train Militaire", France, {{116,46,0}}, {homeCity = nil, veteran = false})
								createUnitsByName("Sapeurs", France, {{116,46,0}}, {homeCity = nil, veteran = false})
								createUnitsByName("Art. à pied 12lb", France, {{116,46,0}}, {homeCity = nil, veteran = false})
							elseif result == 2 then
								civ.ui.text("You selected " .. option .. " for your Russian Invasion at a cost of " .. cost .. " francs")
								changeMoney(France, cost * -1)
								createUnitsByName("Régiment de Ligne", France, {{116,46,0}}, {count = 5, homeCity = nil, veteran = false})
								--local administrativeUnit = findUnitTypeByName("Poniatowski");
								-- activeUnit.moveSpent = administrativeUnit.move
							elseif result == 3 then 
								civ.ui.text("You selected " .. option .. " for your Russian Invasion at a cost of " .. cost .. " francs")
								changeMoney(France, cost * -1)
								createUnitsByName("Train Militaire", France, {{116,46,0}}, {homeCity = nil, veteran = false})
								createUnitsByName("Sapeurs", France, {{116,46,0}}, {homeCity = nil, veteran = false})
								createUnitsByName("Art. à pied 12lb", France, {{116,46,0}}, {homeCity = nil, veteran = false})
								createUnitsByName("Régiment de Ligne", France, {{116,46,0}}, {count = 5, homeCity = nil, veteran = false})
								-- local administrativeUnit = findUnitTypeByName("Poniatowski");
								-- activeUnit.moveSpent = administrativeUnit.move
							else
								civ.ui.text("By choosing to exit you have selected to forgo the possibilty to recruit new units!")
							end
						else
							civ.ui.text("In order for Poniatowski to initiate the Russian invasion preparations, the treasury must contain at least 800 francs!")
						end
					else
						civ.ui.text("In order for Poniatowski to initiate the Russian invasion preparations, he must be located in Warzsawa!")
					end
				end)
			end
			-- ==========================================
		end
	end
	
	-- ==========================================
	-- French leader(s) sea route bonus
	if keyCode == 85 then	-- 'u' (85)
		local activeUnit = civ.getActiveUnit()
		if activeUnit.type.name == "Davout" or activeUnit.type.name == "Lannes" or activeUnit.type.name == "Soult" then
			local TarantoLocation = civ.getTile(106,104,0)
			if activeUnit.location == TarantoLocation then
				local unitTypeName = "Davout"
				local unitTypeName = "Lannes"
				local unitTypeName = "Soult"
				if France.money >= 100 then
					local dialog = civ.ui.createDialog()
					dialog.title = "Select Administrative Bonus"
					dialog.width = 535
					dialog:addText("Please confirm if you wish to build a sea route to Corfu:")
					dialog:addOption("Build a sea route between Taranto and Corfu at a cost of 100 francs", 1)
					dialog:addOption("Exit (do not build the sea route)", 0)
					local result = dialog:show()
					local cost = 100
					if result == 1 then
						civ.ui.text("You selected to proceed with the sea route to Corfu at a cost of " .. cost .. " francs.")
						changeMoney(France, cost * -1)
						civ.getTile(111,109,1).terrainType = 5
						local administrativeUnit = findUnitTypeByName(unitTypeName);
						activeUnit.moveSpent = administrativeUnit.move
					end
				else
					civ.ui.text("The treasury must contain at least 100 francs in order to build the sea route!")
				end
			else
				civ.ui.text("The leader must be located in Taranto in order to build the sea route!")
			end
		end	
	end
	-- ==========================================
end)	-- end of civ.scen.onKeyPress()

civ.scen.onLoad (function (buffer)
	print("Processing \"onLoad()\" ...")
	state = civlua.unserialize(buffer)
	newScenario = false
	updateSeason(true)		-- needs to be checked on every game load, since changes are ephemeral
	printGameStatus()
end)

-- ==== STANDARD DIPOLOMACY NOT PERMITTED ====
--[[ If two tribes are at war, it seems that blocking negotiation between them ought to
	 prevent them from signing a Cease Fire or a Peace Treaty.
	 However, if two tribes are at peace, it's possible that even without negotiating,
	 they can still declare war and attack.
	 In testing, it seems like tribes sometimes AI tribes can both declare war on each
	 other and sign peace treaties with each other, *despite* all negotiation being
	 blocked! ]]
civ.scen.onNegotiation(function (talker, listener)
	return false
end)
-- ===========================================

-- civ.scen.onResolveCombat(function (defaultResolutionFunction, attacker, defender) end)

civ.scen.onSave (function ()
	return civlua.serialize(state)
end)

civ.scen.onScenarioLoaded(function ()
	print("Processing \"onScenarioLoaded()\" ...")

	if newScenario == true then
		print("    Detected \"Begin a Scenario\", initializing state variables")
		-- ==== 3. LEADERS ====
		-- French Leaders
		state.napoleonTimesKilled = 0
		-- ====================

		-- ==== 6. MINOR POWERS ====
		-- ------ Baltic States ----
		state.minorDuchyOfWarsaw = false
		-- ------ German Minors ----
		state.minorRhineConfederation = false
		-- ------ Italian Minors ----
		state.minorKingdomOfNaples = false
		state.minorKingdomOfSicily = true
		state.minorSwitzerland = true
		-- ------ Western Minors ----
		state.minorHolland = true
		state.minorDenmark = false
		-- =========================

		-- ==== 7. WAR STATES AND PEACE TREATIES ====
		-- Russia
		state.russiaIsAtWarWithFrance = true
		state.russiaIsAtWarWithFrance5thCoalition = false
		state.russiaIsAtWarWithFranceforEngland = false
		state.russiaEnglandTradeLoss = false
		state.russiaInvasion = false
		state.russiaTreatyOfSmolensk = false
		state.russiaIsSubdued = false
		state.capturedSmolensk = false
		state.corfuIsRussian = false
		-- state.capturedVjazma = false
		state.capturedMoskva = false
		state.capturedKyiv = false
		-- Austria
		state.austriaIsAtWarWithFrance1 = true
		state.austriaTreatyOfPressburg = false
		state.austriaFifthCoalitionMessageTurn = 0
		state.austriaFifthCoalitionWarTurn = 0
		state.austriaIsAtWarWithFrance2 = false
		state.austriaTreatyOfSchonbrunn = false
		state.austriaIsAtWarWithFrance3 = false
		-- Prussia
		state.prussiaFourthCoalitionWarTurn = 0
		state.prussiaIsAtWarWithFrance1 = false
		state.prussiaTreatyOfTilsit = false
		state.frenchInvasionOfPortugal = false
		state.prussiaIsAtWarWithFrance2 = false
		-- Spain
		state.spainIsAtWarWithEngland = true
		state.spanishCitiesTakenByEngland = 0
		state.spainAllianceWithFranceShaken = false
		state.spainExperiencesFrenchTransgression = false
		state.spainAllianceWithFranceRenewed = false
		state.spainIsAtWarWithFrance = false
		state.spainTreatyOfMadrid = false
		state.spainIsSubdued = false
		-- Ottoman
		state.ottomanIsAtWarWithFrance = false
		state.ottomanTreatyOfErdine = false
		state.ottomanIsAtWarWithRussia = false
		state.ottomanRussiaPeaceTurn = 0
		state.ottomanTreatyofBucuresti = false
		-- France
		state.frenchVictory = false
		-- England
		state.englandIsAtWarWithFrance = true
		state.englandTreatyOfAmiens = false
		state.englandExperiencesFrenchTransgression = false
		state.englandIsSubdued = false
		state.successfullyInvadedEngland = false 
		state.failedToInvadeEngland = false
		
		-- ==========================================

		-- ==== 3. LEADERS (Death Board) ====
		state.diedNone = true
		state.diedDavout = false
		state.diedLannes = false
		state.diedMurat = false
		state.diedSoult = false
		state.diedVilleneuve = false
		state.diedPoniatowski = false
		state.diedCharles = false
		state.diedSchwarzenberg = false
		state.diedMoore = false
		state.diedNelson = false
		state.diedUxbridge = false
		state.diedWellington = false
		state.diedBlucher = false
		state.diedYorck = false
		state.diedBagration = false
		state.diedBarclaydeTolly = false
		state.diedKutusov = false
		state.diedBlake = false
		state.diedCuesta = false
		-- ==========================================

		-- ==== 8. SPECIAL FRENCH UNITS RECRUITMENT ====
		state.coalitionLineInfantryUnitsKilled = 0
		-- =============================================

		-- ==== 10. WINTER ====
		state.winter = false
		state.frenchForcedMarchAbility = true
		-- ====================

		-- ==== 14. L'ELAN NAPOLEONIEN ====
		state.frenchUnitKilled = 0
		-- ================================

		-- ==== 15. MARITIME SUPREMACY ====
		state.englishNavalUnitsKilled = 0
		state.frenchNavalUnitsKilled = 0
		state.frenchMaritimeSupremacy = false
		state.january1808 = false
		-- ================================

		-- ==== 21. DIPLOMATIC MARRIAGE ====
		state.napoleonMarriageMarieLouise = false
		-- =================================

		-- === IRISH REBELLION ===
		state.rebellionInIreland = false
		-- =================================

		-- === ALLIED EMBARGO ===
		state.alliedEmbargo = false
		state.totalEmbargoCost = 0
		-- =================================

		-- === FRENCH PRIVATEER PLUNDER ===
		state.frenchPlunder = false
		state.frenchPrivateersInWaters = false
		-- =================================
		
		-- === BARBARY PIRATES ===		
		state.barbaryPiratesPunished = false
		-- =================================
		
		printGameStatus()
	else
		print("    Detected \"Load a Saved Game\", did not initialize state variables")
		print("")
	end

end)	-- end of civ.scen.onScenarioLoaded()

-- ==== SCHISMS NOT PERMITTED ====
civ.scen.onSchism(function (tribe)
	print("Blocked schism of " .. tribe.adjective .. " tribe!")
	return false
end)
-- ===============================

civ.scen.onTurn(function (turn)
	local monthNumber = getMonthNumber(turn)
	print("")
	print("==== Beginning of " .. monthName[monthNumber] .. " " .. getYear() .. " (turn " .. turn .. ") ====")
	printGameStatus()

	if turn == 1 then

-- ==== INTRODUCTORY TEXT ====
		civ.playSound("IntroductorySong.wav")
		civ.ui.text(func.splitlines(scenText.introText1))
		civ.ui.text(func.splitlines(scenText.introText2_a))
		civ.ui.text(func.splitlines(scenText.introText2_b))
		civ.ui.text(func.splitlines(scenText.introText2_c))
		civ.ui.text(func.splitlines(scenText.introText3))
		civ.ui.text(func.splitlines(scenText.introText4))
		civ.ui.text(func.splitlines(scenText.introText5))
		civ.ui.text(func.splitlines(scenText.introText6))
		civ.ui.text(func.splitlines(scenText.introGameTip1))
		civ.ui.text(func.splitlines(scenText.introGameTip2a))
		civ.ui.text(func.splitlines(scenText.introGameTip2b))
		civ.ui.text(func.splitlines(scenText.introGameTip3))
		civ.ui.text(func.splitlines(scenText.introGameTip11))
-- ===========================

-- ==== 7. WAR STATES AND PEACE TREATIES ====
		enforceAlliance(Austria, England, false)
-- ------- Russia -------
		enforceAlliance(Austria, Russia, false)
		enforceAlliance(England, Russia, false)
-- ------- Spain -------
		enforceAlliance(Spain, France, false)
-- ==========================================

-- ==== 23. RANDOM EVENTS ====
-- ---- Create Barbarian Forts ----
		local locationList = {{15,117,0}, {37,121,0}, {79,123,0}, {91,141,0}}
		-- Note: a unit will be created at *each* of the above locations, not just at the first available one
		for _, locationEntry in ipairs(locationList) do
			local eventLocation = { [1] = locationEntry }
			createUnitsByName("Minor Fort", Barbarians, eventLocation, {homeCity = nil, veteran = false})
		end
		-- Major fort for Barbary Pirate city of Algier
		local fort = createUnitsByName("Major Fort", Barbarians, {{51,119,0}}, {homeCity = nil, veteran = false})
		--fort.order = 2

-- ---- Create Random Austrian Landwehr units ----
		createUnitsByName("A. Landwehr", Austria, {{81,57,0}, {86,60,0}, {81,67,0}, {79,63,0}}, {randomize = true, homeCity = nil, veteran = false})
		createUnitsByName("A. Landwehr", Austria, {{87,67,0}, {86,72,0}, {84,80,0}}, {randomize = true, homeCity = nil, veteran = false})
		createUnitsByName("A. Landwehr", Austria, {{91,73,0}, {96,58,0}, {103,67,0}}, {randomize = true, homeCity = nil, veteran = true})

-- ---- Create Random Spanish Militia units ----
		createUnitsByName("S. Militia", Spain, {{18,94,0}, {15,101,0}}, {randomize = true, homeCity = nil, veteran = true})

		
-- --- Create Random Ottoman Minor Fort
		createUnitsByName("Minor Fort", Ottoman, {{128,92,0}, {140,96,0}, {166,100,0}}, {randomize = true, homeCity = nil, veteran = true})

-- --- Add science buildings to French cities
		-- civ.addImprovement(Bordeaux, findImprovementByName("Les Grandes Écoles"))
		-- civ.addImprovement(Toulouse, findImprovementByName("Les Grandes Écoles"))

-- --- Add or remove a city improvement
		-- civ.addImprovement(NiznijNovgorod, findImprovementByName("Military Academy"))
		-- civ.removeImprovement(city, findImprovementByName("Stables"))
		
		-- civ.addImprovement(Malaga, findImprovementByName("Coastal Fortress"))
-- ===========================

	elseif turn == 2 then

-- ==== INTRODUCTORY TEXT ====
		civ.ui.text(func.splitlines(scenText.introGameTip4))
		civ.ui.text(func.splitlines(scenText.introGameTip5_a))
		civ.ui.text(func.splitlines(scenText.introGameTip5_b))

-- --- Create British Two Decker in Glasgow
		createUnitsByName("Two Decker", England, {{46,22,0}}, {homeCity = nil, veteran = false})

-- ---- Austrian 2nd turn Reinforcement Event ----
		if state.austriaIsAtWarWithFrance1 == true then
			JUSTONCE("x_Austrian_Reinforcement_Event", function()
				print("Austrian Reinforcement Event takes place")
				local eventLocation = getRandomValidLocation("Charles", Austria, {{87,67,0}, {93,63,0}, {101,65,0}})
				createUnitsByName("Charles", Austria, eventLocation, {homeCity = nil, veteran = false})
				createUnitsByName("A. Line Infantry", Austria, eventLocation, {count = 2, homeCity = nil, veteran = false})
				createUnitsByName("A. Light Infantry", Austria, eventLocation, {homeCity = nil, veteran = false})
				createUnitsByName("A. Foot Artillery", Austria, eventLocation, {homeCity = nil, veteran = false})
				-- createUnitsByName("A. Kürassier", Austria, eventLocation, {homeCity = nil, veteran = false})
				createUnitsByName("A. Kürassier", Austria, {{87,67,0}, {93,63,0}, {86,60,0}}, {randomize = true, homeCity = nil, veteran = true})
				
				civ.ui.text("The Archduke Charles of Austria, younger brother of Emperor Francis II, arrives on the front with a fresh contingent of troops to assume command of all Austrian forces!")
			end)
		end
-- ===========================

	elseif turn == 3 then

-- ==== INTRODUCTORY TEXT ====
		civ.ui.text(func.splitlines(scenText.introGameTip6))
		civ.ui.text(func.splitlines(scenText.introGameTip7))
		civ.ui.text(func.splitlines(scenText.introGameTip8))
		civ.ui.text(func.splitlines(scenText.introGameTip9))
-- ===========================

-- ==== 23. RANDOM EVENTS ====
-- ---- Create British Naval Squadron ----
		if state.englandIsAtWarWithFrance == true then
			local eventLocation = getRandomValidLocation("Two Decker", England, {{3,91,0}, {22,72,0}, {5,85,0}, {10,78,0}})
			-- createUnitsByName("Three Decker", England, eventLocation, {homeCity = nil, veteran = true})
			createUnitsByName("Two Decker", England, eventLocation, {count = 3, homeCity = nil, veteran = true})
			createUnitsByName("Frigate", England, eventLocation, {homeCity = nil, veteran = false})
			civ.ui.text("A British naval squadron arrives off the coast of Spain!")
		end
-- ===========================

	elseif turn == 4 then

-- ==== INTRODUCTORY TEXT ====
		civ.ui.text(func.splitlines(scenText.introGameTip10))
		civ.ui.text(func.splitlines(scenText.introGameTip12))
-- ======================================

	end

--	-- Display French losses --
	if turn >=1 and (state.frenchUnitKilled > 0 and state.frenchUnitKilled < 90) then
		civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^French units lost to date: " .. state.frenchUnitKilled))
	end
	
--	-- Diplay Maritime Supremacy score --
	if turn <=30 and state.englandIsAtWarWithFrance == true and state.frenchMaritimeSupremacy == false and (state.englishNavalUnitsKilled > 0 or state.frenchNavalUnitsKilled > 0) and (state.frenchNavalUnitsKilled < 10) then
		civ.ui.text(func.splitlines(displayMonthYear() .. " - Maritime Supremacy Losses Score:\n^\r^England " .. state.englishNavalUnitsKilled .. " versus France " .. state.frenchNavalUnitsKilled .. ""))
	end
	if turn <=31 and state.englandIsAtWarWithFrance == true and state.frenchMaritimeSupremacy == false and state.frenchNavalUnitsKilled >= 10 then
		JUSTONCE("x_Maritime_Bid_Lost", function ()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, your navy has suffered too many losses to be able\n^to wrestle control of the seas from the Royal Navy and as such\n^your bid to gain Maritime Supremacy has failed!"))
		end)
	end

	if turn ==31 and state.englandIsAtWarWithFrance == true and state.frenchMaritimeSupremacy == false then
		civ.ui.text(func.splitlines(scenText.impHQDispatch_Failed_Establish_Supremacy))
	end

	if turn == 30 then
		state.january1808 = true
	end

	--	-- Display French Minor Power Yearly Spring Recruitment Message
	if turn == 9 or turn == 21 or turn == 33 or turn == 45 or turn == 57 or turn == 69 or turn == 81 then
		civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, it's the beginning of the summer campaign\n^season and as such your minor allies have provided a\n^new contingent of troops to join your armed forces."))
	end

	--	-- Display game tip if France discovers Siege Warfare advance
	if civ.hasTech(France, findTechByName("Siege Warfare")) then
		JUSTONCE("x_Siege_Warfare_Discovered", function ()
			civ.ui.text(func.splitlines(scenText.introGameTip13))
			civ.ui.text("In addition, if you so choose, the Siege Warfare advance will allow your civil engineers to build Coastal Fortress improvements, as many of your coastal cities defenses have fallen into disrepair since the Revolution!")
		end)
	end

	--	-- Display game tip if France discovers Infrastructure advance	
	if civ.hasTech(France, findTechByName("Infrastructure")) then
		JUSTONCE("x_Infrastructure_Discovered", function ()
			civ.ui.text(func.splitlines(scenText.researchInfrastructure))
		end)
	end

	--	-- Display message that Austria is becoming restless
	if turn == state.austriaFifthCoalitionMessageTurn then
		civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, minister Talleyrand informs you that he's\n^been receiving reports from his agents abroad that not\n^all is well with your relations with Austria.\n^\r^There appears to be a growing revanchism movement\n^amongst Francis' inner court who are bitterly resentful\n^of the terms of the treaty of Pressburg you imposed on\n^them.\n^\r^You would do well to keep a close eye on your borders\n^with that nation."))
	end

	for unit in civ.iterateUnits() do
		-- ==== 1. ARTILLERY UNITS (cleanup) ====
		if unit.owner == France then
			for _, typeToBeDestroyed in pairs(projectilesToBeDestroyedEachTurn) do
				if unit.type == typeToBeDestroyed then
					print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					civ.deleteUnit(unit)
				end
			end
		end
		-- ======================================
		-- ==== Remove home city from British leaders: ====
		if unit.type.name == "Uxbridge" or unit.type.name == "Moore" or unit.type.name == "Wellington" or unit.type.name == "Nelson" then
			if unit.homeCity ~= nil then
				print(unit.type.name .. " (" .. unit.owner.adjective .. ") home city changed from " .. unit.homeCity.name .. " to NONE")
				unit.homeCity = nil
			end
		end
		-- ================================================
	end

-- ==== 7. WAR STATES AND PEACE TREATIES ====

-- ------- England -------
	if state.englandIsAtWarWithFrance == true then
		-- Currently at war; test for peace condition:
		if Birmingham.owner == France and Bristol.owner == France and Liverpool.owner == France and London.owner == France then
			state.englandTreatyOfAmiens = true
			state.englandIsAtWarWithFrance = false
			state.spainIsAtWarWithEngland = false
			state.englandIsSubdued = true
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Defeated_England_p1))
			changeMoney(France, 2000)
			enforcePeace(England, France, true)
			enforcePeace(England, Spain, true)
			revokeTech(England, "English Military")
			grantTech(England, "Continental Blockade")
			for unit in civ.iterateUnits() do
				if unit.owner == England then
					if tileWithinIberia(unit.location) then
						for _, typeToBeDestroyed in pairs(englishUnitTypesToBeDestroyed) do
							if unit.type == typeToBeDestroyed then
								print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
								civ.deleteUnit(unit)
							end
						end
					end
					if 	unit.type == findUnitTypeByName("Royal Marines") or
						unit.type == findUnitTypeByName("Coalition Shells") or
						unit.type == findUnitTypeByName("Frigate") or
						unit.type == findUnitTypeByName("Two Decker") or
						unit.type == findUnitTypeByName("Three Decker") or
						unit.type == findUnitTypeByName("Transport") then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
					for _, typeToBeDestroyed in pairs(portugueseUnitTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
					for _, typeToBeDestroyed in pairs(swedishUnitTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
				end
			end
			for unit in civ.iterateUnits() do
				if unit.owner == France then
					if 	unit.type == findUnitTypeByName("Irish Rebel") then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
			end
			local portugueseCitiesToTransfer = {"Lagos", "Lisboa", "Oporto"}
			for _, cityName in pairs(portugueseCitiesToTransfer) do
				local city = findCityByName(cityName)
				if city.owner ~= France then
					city.owner = France
					print("Gave ownership of " .. cityName .. " to France")
				end
			end
			local spanishCitiesToTransfer = {
				"A Coruna", "Badajoz", "Barcelona", "Bilbao", "Burgos", "Cadiz",
				"Cartagena", "Ciudad Rodrigo", "Córdoba", "Gijón", "Madrid", "Málaga",
				"Sevilla", "Tortosa", "Valencia", "Valladolid", "Zaragoza"}
			for _, cityName in pairs(spanishCitiesToTransfer) do
				local city = findCityByName(cityName)
				if city.owner == England then
					city.owner = Spain
					print("Gave ownership of " .. cityName .. " to Spain")
				end
			end
			-- ==== 8. SPECIAL FRENCH UNITS RECRUITMENT ====
			createUnitsByName("Portuguese Infantry", France, {{6,98,0}}, {count = 2, homeCity = nil, veteran = false})
			createUnitsByName("Garde Impériale", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			civ.ui.text("In honor of your successful invasion of the British Isles, you authorize the creation of a new regiment of the Garde Impériale.")
			-- =============================================
		else
			enforceWar(England, France, false)
		end
	else
		-- Currently at peace; no war condition exists (peace means England is subdued for the duration of the scenario)
		enforcePeace(England, France, false)
	end

	-- ======================================================
	-- If France invades England:
	if state.englandIsAtWarWithFrance == true then
		local frenchTroopsInEngland = getFrenchTroopsInEngland()
		if state.englandExperiencesFrenchTransgression == false then
			if frenchTroopsInEngland >= 4 then
				state.englandExperiencesFrenchTransgression = true
				print("    French troops in England = " .. frenchTroopsInEngland .. ", set englandExperiencesFrenchTransgression to True")
			else
				print("    French troops in England = " .. frenchTroopsInEngland .. ", englandExperiencesFrenchTransgression remains False")
			end
		elseif state.englandExperiencesFrenchTransgression == true then
			if frenchTroopsInEngland == 0 then
				state.englandExperiencesFrenchTransgression = false
				print("    French troops in England = " .. frenchTroopsInEngland .. ", set englandExperiencesFrenchTransgression to False")
			else
				print("    French troops in England = " .. frenchTroopsInEngland .. ", englandExperiencesFrenchTransgression remains True")
			end
		end
		if state.englandExperiencesFrenchTransgression == true then
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^French troops in England: " .. frenchTroopsInEngland))
		end
	else
		state.englandExperiencesFrenchTransgression = false
	end

	-- ======================================================
	-- If Irish Rebels Exist in Ireland Then France Receives a Bonus to its Treasury For Each Rebel:
	if state.englandIsAtWarWithFrance == true then
		local irishRebelsInIreland = getIrishRebelsInIreland()
		local irishBlackMarket = irishRebelsInIreland * incomePerIrishRebel
		if state.rebellionInIreland == false then
			if irishRebelsInIreland >= 1 then
				state.rebellionInIreland = true
				print("    Irish Rebels in Ireland = " .. irishRebelsInIreland .. ", set state.rebellionInIreland to True")
			else
				print("    Irish Rebels in Ireland = " .. irishRebelsInIreland .. ", state.rebellionInIreland remains False")
			end
		elseif state.rebellionInIreland == true then
			if irishRebelsInIreland == 0 then
				state.rebellionInIreland = false
				print("    Irish Rebels in Ireland = " .. irishRebelsInIreland .. ", set state.rebellionInIreland to False")
			else
				print("    Irish Rebels in Ireland = " .. irishRebelsInIreland .. ", state.rebellionInIreland remains True")
			end
		end
		if state.rebellionInIreland == true then
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^Irish Rebels in Ireland: " .. irishRebelsInIreland .. "\n^\r^Black Market activities provide " .. irishBlackMarket .. " francs to the French economy."))
			changeMoney(France, irishBlackMarket)
		end
	else
		state.rebellionInIreland = false
	end

	-- ======================================================
	-- If British Embargo Of French Ports, Deduct Francs For Each Ship From French Treasury:
	local embargoShipDetails = getEmbargoShipDetails()
	local embargoShipCount = 0
	for i = 1, 6 do
		if embargoShipDetails[i] ~= nil then
			embargoShipCount = embargoShipCount + embargoShipDetails[i]
		end
	end
	local embargoCostFrance = embargoShipCount * embargoCostPerShipFrance
	local embargoIncomeEngland = embargoShipCount * embargoIncomePerShipEngland
	local opponentDesc = "British Navy"
	if state.russiaIsAtWarWithFrance == true then
		opponentDesc = "Allied Navies"
	end
	if state.alliedEmbargo == false then
		if embargoShipCount >= 1 then
			state.alliedEmbargo = true
			print("    " .. opponentDesc .. " = " .. embargoShipCount .. ", set state.alliedEmbargo to True")
		else
			print("    " .. opponentDesc .. " = " .. embargoShipCount .. ", state.alliedEmbargo remains False")
		end
	elseif state.alliedEmbargo == true then
		if embargoShipCount == 0 then
			state.alliedEmbargo = false
			print("    " .. opponentDesc .. " = " .. embargoShipCount .. ", set state.alliedEmbargo to False")
		else
			print("    " .. opponentDesc .. " = " .. embargoShipCount .. ", state.alliedEmbargo remains True")
		end
	end
	if 	state.alliedEmbargo == true then
		changeMoney(France, embargoCostFrance * -1)
		state.totalEmbargoCost = (state.totalEmbargoCost or 0) + embargoCostFrance
		changeMoney(England, embargoIncomeEngland)
		civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^" .. opponentDesc .. " Embargo French Ports:\n^\r^In Zone 1: " .. tostring(embargoShipDetails[1] or 0) .. " Ship(s)\n^In Zone 2: " .. tostring(embargoShipDetails[2] or 0) .. " Ship(s)\n^In Zone 3: " .. tostring(embargoShipDetails[3] or 0) .. " Ship(s)\n^In Zone 4: " .. tostring(embargoShipDetails[4] or 0) .. " Ship(s)\n^In Zone 5: " .. tostring(embargoShipDetails[5] or 0) .. " Ship(s)\n^In Zone 6: " .. tostring(embargoShipDetails[6] or 0) .. " Ship(s)\n^\r^Total Funds Lost: " .. embargoCostFrance.. "\n^Cargo Inbounded into British Treasury: " .. embargoIncomeEngland .. "\n^\r^Total Funds Lost to Date: " .. tostring(state.totalEmbargoCost)))
	end

	-- ======================================================
	-- FRENCH CUSTOMS WAREHOUSES
	-- Each French customs warehouse provide 3 francs per month to the French Treasury
	local totalWarehouses = 0
	for unit in civ.iterateUnits() do
		if unit.owner == France then
			if unit.type.name == "Customs Warehouse" then
				totalWarehouses = totalWarehouses + 1
				print("Received " .. revenuePerWarehouse .. " francs for Warehouses at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
			end
		end
	end	
	if totalWarehouses > 0 then
		-- civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^" .. totalWarehouses .." Customs Warehouses add " .. tostring(totalWarehouses * revenuePerWarehouse) .. " francs to the French Treasury"))
		changeMoney(France, totalWarehouses * revenuePerWarehouse)
	end
	
	-- ======================================================
	-- FRENCH GARRISON DUTIES
	-- If France fails to maintain a proper garrison in east Prussia after war of 4th Coalition and when at peace with Russia then subtract 25 francs from treasury
	if state.englandIsAtWarWithFrance == true and state.russiaIsAtWarWithFrance == false and state.russiaIsSubdued == false then
		if getFrenchTroopsInPrussia() < 25 then
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^French garrison troops in Prussia: " .. getFrenchTroopsInPrussia() .."\n^\r^The lack of garrison troops is costing the French Treasury " .. contrabandCostPrussia .. " this month."))
			changeMoney(France, contrabandCostPrussia * -1)
		end
	end	

	-- If France fails to maintain a proper garrison in England after it has been subdued subtract 75 francs from treasury
	if state.englandIsSubdued == true then
		if getFrenchTroopsInEngland() < 15 then
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^French garrison troops in England: " .. getFrenchTroopsInEngland() .."\n^\r^The lack of garrison troops is costing the French Treasury " .. garrisonCostEngland .. " this month."))
			changeMoney(France, garrisonCostEngland * -1)
		end
	end	
	
	-- If France fails to maintain a proper garrison in Russia after it has been subdued subtract 50 francs from treasury
	if state.spainIsSubdued == true then
		if getFrenchTroopsInRussia() < 40 then
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^French garrison troops in Russia: " .. getFrenchTroopsInRussia() .."\n^\r^The lack of garrison troops is costing the French Treasury " .. garrisonCostRussia .. " this month."))
			changeMoney(France, garrisonCostRussia * -1)
		end
	end	
	
	-- If France fails to maintain a proper garrison in Spain after it has been subdued subtract 35 francs from treasury
	if state.spainIsSubdued == true then
		if getFrenchTroopsInIberia() < 30 then
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^French garrison troops in Spain: " .. getFrenchTroopsInIberia() .."\n^\r^The lack of garrison troops is costing the French Treasury " .. garrisonCostSpain .. " this month."))
			changeMoney(France, garrisonCostSpain * -1)
		end
	end	
	
	-- ======================================================
	-- If French Navy Raids Egyptian Waters:
	if state.englandIsAtWarWithFrance == true then
		local frenchPrivateerShip = 0
		local privateerPlunder = 0
		for unit in civ.iterateUnits() do
			if unit.owner == France and unit.type.domain == 2 and tileOceanZone7(unit.location) then
				frenchPrivateerShip = frenchPrivateerShip + 1
				privateerPlunder = frenchPrivateerShip * 15
			end
		end
		if state.frenchPlunder == false then
			if frenchPrivateerShip >= 1 then
				state.frenchPlunder = true
				state.frenchPrivateersInWaters = true
				print("    French Privateer = " .. frenchPrivateerShip .. ", set frenchPlunder to True")
			else
				print("    French Privateer = " .. frenchPrivateerShip .. ", frenchPlunder remains False")
				state.frenchPrivateersInWaters = false
			end
		elseif state.frenchPlunder == true then
			if frenchPrivateerShip == 0 then
				state.frenchPlunder = false
				state.frenchPrivateersInWaters = false
				print("    French Privateer = " .. frenchPrivateerShip .. ", frenchPlunder remains False")
			else
				print("    French Privateer = " .. frenchPrivateerShip .. ", set frenchPlunder to True")
				state.frenchPrivateersInWaters = true
			end
		end
		if state.frenchPlunder == true then
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^" .. frenchPrivateerShip .." French Privateer(s) Raid British Trade in Egyptian Waters:\n^\r^" .. privateerPlunder .. " francs are added to the French Treasury"))
			changeMoney(France, privateerPlunder * 1)
		end
	else
		state.frenchPlunder = false
	end

	-- If French Privateers in Egyptian Waters then 1 in 4 chance a British Ship will Arrive
	if state.englandIsAtWarWithFrance == true then
		if state.frenchPrivateersInWaters == true then
			if math.random(4) <= 1 then
				createUnitsByName("Two Decker", England, {{170,140,0}, {172,136,0}, {173,143,0}}, {randomize = true, homeCity = nil, veteran = true})
				civ.ui.text("The British Admiralty sends a British Naval Squadron to clear Egyptian waters of French Privateers!")
			end
		end
	end

	-- If France establishes trading post with Ottoman Empire on the island of Corfu
	if state.ottomanIsAtWarWithFrance == false then
		local frenchTradingPost = getFrenchTradingPost ()
		if Corfu.owner == France then
			changeMoney(France, frenchTradingPost)
			JUSTONCE("x_France_Establishes_Trading_Post", function()
				civ.ui.text("As long as France controls Corfu it will receive 15 francs from its trading post with the Ottoman Sultanate!")
			end)
		end
	end
	
	-- ======================================================
	-- England 'Gifts' Arms to Spain if Britain Surrenders and Spain is Still At War with France
	if state.englandIsSubdued == true and state.spainIsAtWarWithFrance == true then
		JUSTONCE("x_England_Provides_Arms_To_Spain", function()
			civ.ui.text(func.splitlines("******************  Spain Seizes British Arms  ******************\n^\r^Your majesty, upon England's surrender to France and its\n^subsequent withdrawal from the Iberian Peninsula, your agents\n^confirm that Spain, most likely in connivance with the British,\n^has seized large stocks of English arms and is using them to\n^equip many new Spanish regiments in its ongoing struggle to\n^resist our legitimate claims on its lands and throne."))
			createUnitsByName("S. Line Infantry", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {count = 5, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("S. Light Infantry", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("S. Line Cavalry", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("S. Foot Artillery", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
		end)
	end

-- ------- Austria -------
	--- WAR OF THIRD COALITION
	if state.austriaIsAtWarWithFrance1 == true then
		-- Currently at war; test for peace condition:
		if Prag.owner == France and Wien.owner == France and Venezia.owner == France then
			state.austriaTreatyOfPressburg = true
			state.austriaIsAtWarWithFrance1 = false
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_DefeatedAustria_3rdCoalition_p1))
			civ.ui.text(func.splitlines(scenText.impHQDispatch_DefeatedAustria_3rdCoalition_p2))
			civ.ui.text(func.splitlines(scenText.impHQDispatch_DefeatedAustria_3rdCoalition_p3))
			changeMoney(France, 800)
			enforcePeace(Austria, France, true)
			revokeTech(Austria, "Austrian Military")
			for unit in civ.iterateUnits() do
				if unit.owner == Austria then
					for _, typeToBeDestroyed in pairs(austrianUnitTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
				end
			end
			state.Pressburg_Treaty_City_Return = turn + 1
			local austrianCitiesToTake = {"Ancona", "Verona"}
			for _, cityName in pairs(austrianCitiesToTake) do
				local city = findCityByName(cityName)
				if city.owner ~= France then
					city.owner = France
					print("Gave ownership of " .. cityName .. " to France")
				end
			end
			-- ==== 8. SPECIAL FRENCH UNITS RECRUITMENT ====
			createUnitsByName("Garde Impériale", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			civ.ui.text("In honor of your great victory over Austria in the war of the Third Coalition, you authorize the creation of a new regiment of the Garde Impériale.")
			-- =============================================
			state.minorRhineConfederation = true
			-- ==== 6. MINOR POWERS ====
			-- ------ German Minors ----
			createUnitsByName("Bavarian Infantry", France, {{87,67,1}}, {count = 2, homeCity = Bavaria, veteran = false})
			createUnitsByName("Bavarian Cavalry", France, {{87,67,1}}, {homeCity = Bavaria, veteran = false})
			createUnitsByName("Rhine Infantry", France, {{81,57,1}}, {count = 2, homeCity = Rhineland, veteran = false})
			createUnitsByName("Würtemberg Infantry", France, {{79,63,1}}, {count = 2, homeCity = Wurtemburg, veteran = false})
			-- =========================
		else
			enforceWar(Austria, France, false)
		end
	end
	if turn == state.Pressburg_Treaty_City_Return then
		local austrianCitiesToReturn = {"Agram", "Budapest", "Debrecen", "Graz", "Kosice", "Krakow",
			"Lemberg", "Olmütz", "Pécs", "Prag", "Temeschwar", "Trieste", "Wien"}
		for _, cityName in pairs(austrianCitiesToReturn) do
			local city = findCityByName(cityName)
			if city.owner ~= Austria then
				city.owner = Austria
				print("Gave ownership of " .. cityName .. " to Austria")
			end
		end
		for unit in civ.iterateUnits() do
			if unit.owner == France and unit.type.domain == 0 and (cityTileWithinAustria(unit.location) or cityTileAgram(unit.location))then
				for _, typeToBeDestroyed in pairs(frenchUnitTypesToBeDestroyed) do
					if unit.type == typeToBeDestroyed then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
			end
		end
		for unit in civ.iterateUnits() do
			if unit.owner == Russia and unit.type.domain == 0 and (cityTileWithinAustria(unit.location) or cityTileAgram(unit.location))then
				for _, typeToBeDestroyed in pairs(russianUnitTypesToBeDestroyed) do
					if unit.type == typeToBeDestroyed then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
			end
		end
		local locationList = {{96,58,0}, {99,73,0}, {102,78,0}, {103,67,0}, {105,61,0}}
		-- Note: a unit will be created at *each* of the above locations, not just at the first available one
		for _, locationEntry in ipairs(locationList) do
			local eventLocation = { [1] = locationEntry }
			createUnitsByName("A. Landwehr", Austria, eventLocation, {homeCity = nil, veteran = false})
		end
		createUnitsByName("Garde Frontalier", France, {{91,69,0}}, {homeCity = nil, veteran = false})
		createUnitsByName("Garde Frontalier", France, {{91,77,0}}, {homeCity = nil, veteran = false})
		state.Pressburg_Treaty_City_Return = 0
	end

	--- WAR OF FIFTH COALITION
	if state.austriaIsAtWarWithFrance1 == false and state.austriaTreatyOfPressburg == true and
	   state.austriaIsAtWarWithFrance2 == false and state.austriaTreatyOfSchonbrunn == false then
		-- Currently at peace; test for war condition:
		if state.prussiaTreatyOfTilsit == true and turn == state.austriaFifthCoalitionWarTurn then
			state.austriaIsAtWarWithFrance2 = true
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Austria_War_5th_Coalition))
			if state.russiaIsAtWarWithFranceforEngland == false then
				civ.ui.text("But be weary if Austria can seize two cities beyond its current borders as it may draw Russia into the conflict.")
			else
				civ.ui.text("With Russia already at war with you over England, you must defeat Austria and control all the aforementioned cities to force both Austria and Russia to sue for peace.")
			end
			enforceWar(Austria, France, true)
			grantTech(Austria, "Austrian Military")
			createUnitsByName("A. Line Infantry", Austria, {{102,78,0}, {103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {97,79,0}}, {count = 40, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Light Infantry", Austria, {{102,78,0}, {103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {97,79,0}}, {count = 10, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Kürassier", Austria, {{102,78,0}, {103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {97,79,0}}, {count = 4, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Uhlans", Austria, {{102,78,0}, {103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {97,79,0}}, {count = 6, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Charles", Austria, {{102,78,0}, {103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {97,79,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Foot Artillery", Austria, {{102,78,0}, {103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {97,79,0}}, {count = 8, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Horse Artillery", Austria, {{102,78,0}, {103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {97,79,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Guerrilla", Austria, {{86,76,0}, {84,68,0}, {86,70,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			-- ==== 6. MINOR POWERS ====
			-- ------ Sweden -----------
			if state.englandIsAtWarWithFrance == true then
				local eventLocation = getRandomValidLocation("Swedish Infantry", England, {{89,39,0}, {83,37,0}, {94,38,0}})
				createUnitsByName("Swedish Infantry", England, eventLocation, {count = 4, homeCity = nil, veteran = true})
				createUnitsByName("Swedish Cavalry", England, eventLocation, {homeCity = nil, veteran = true})
			end
			-- =========================
		else
			enforcePeace(Austria, France, false)
		end
	end

	-- NOTE: Only one of the two conditions below can be met, i.e. Russia CANNOT declare war in both the French invasion of England AND the Austrian War of 5th Coalition. It can only be one or the other OR neither. 
	-- NOTE: Irrespective of which war it gets involved in, it will sue for peace if Austria is defeated in war of 5th Coalition. It will no longer be possible for Russia to go to war for England after that.
	-- Possible Russian intervention if France has invaded England and the Austrian War of 5th Coalition hasn't begun (because of the Treaty of Tilsit condition it cannot go to war for England prior to the defeat of Prussia in war of 4th Coalition)
	if state.prussiaTreatyOfTilsit == true and state.austriaIsAtWarWithFrance2 == false and state.austriaTreatyOfSchonbrunn == false and state.englandExperiencesFrenchTransgression == true and state.englandIsSubdued == false then 
		if math.random(6) == 1 then		-- "1" is arbitrary, we want a 16.5% chance or 1 in 6
			JUSTONCE("x_conditions_Russian_DOW_5th", function ()
				state.russiaIsAtWarWithFrance = true
				state.russiaIsAtWarWithFranceforEngland = true -- NEW VARIABLE TO ADD
				state.russiaEnglandTradeLoss = false
				civ.playSound("MilitaryFANFARE_1.wav")
				civ.ui.text(func.splitlines("*********************  Russia Comes to Aid of England  *********************\n^\r^Your Majesty, your invasion of the British isles has drawn the ire of the\n^Russian Tsar, who sees your unfettered attempts at conquest of a fellow\n^monarch's domain as a continued threat to all European monarchies.\n^\r^As such, Tsar Alexander has seized this opportunity to renew hostilities with\n^you and thus ordered his military attaché in Paris to advise you that a state\n^of war exists between your two nations once more.\n^\r^The Tsar's ambassador in Austria has made him aware of that nation's deep\n^desire for revenge and hopes it will ultimately be drawn into a war of the\n^5th Coalition against you. Irrespective of the outcome in England, only by\n^defeating these two nations will you be able to re-establish peace."))
				enforceWar(Russia, France, true)
				createUnitsByName("R. Line Infantry", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 8, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Light Infantry", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 4, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Cuirassiers", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("Don Cossack", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Foot Artillery", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Horse Artillery", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {randomize = true, homeCity = nil, veteran = true})
			end)
		end
	-- Possible Russian intervention in War of 5th Coalition if Austria captures 2 of more cities outside of the Austrian Empire (and Russia hasn't declared war in French invasion of England)
	elseif	state.austriaIsAtWarWithFrance2 == true and state.austriaTreatyOfSchonbrunn == false and state.russiaIsAtWarWithFranceforEngland == false
	--	and state.englandExperiencesFrenchTransgression == false and state.englandIsSubdued == false 
	then
		local conditionsRussianDOW_5thCoalition = 0
		if Dresden.owner == Austria then
			conditionsRussianDOW_5thCoalition = conditionsRussianDOW_5thCoalition + 1
		end
		if Leipzig.owner == Austria then
			conditionsRussianDOW_5thCoalition = conditionsRussianDOW_5thCoalition + 1
		end
		if Lublin.owner == Austria then
			conditionsRussianDOW_5thCoalition = conditionsRussianDOW_5thCoalition + 1
		end
		if Ratisbon.owner == Austria then
			conditionsRussianDOW_5thCoalition = conditionsRussianDOW_5thCoalition + 1
		end
		if Venezia.owner == Austria then
			conditionsRussianDOW_5thCoalition = conditionsRussianDOW_5thCoalition + 1
		end
		if Warszawa.owner == Austria then
			conditionsRussianDOW_5thCoalition = conditionsRussianDOW_5thCoalition + 1
		end
		if conditionsRussianDOW_5thCoalition >= 2 then
			JUSTONCE("x_conditions_Russian_DOW_5th", function ()
				state.russiaIsAtWarWithFrance = true
				state.russiaIsAtWarWithFrance5thCoalition = true
				state.russiaEnglandTradeLoss = false
				civ.playSound("MilitaryFANFARE_1.wav")
				civ.ui.text(func.splitlines("*********************  Russia Joins War of 5th Coalition  *********************\n^\r^Your Majesty, you have failed to sufficiently protect your German and Polish\n^acquisitions from Austria's renewed aggression, which has left an impression\n^of great vulnerability amongst your adversaries and so-called friends.\n^\r^As such, Tsar Alexander has seized this opportunity to renew hostilities\n^with your Empire in the hopes of reversing the terms of the Treaty of Tilsit,\n^which was bitterly resented by the Russian court."))
				enforceWar(Russia, France, true)
				createUnitsByName("R. Line Infantry", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 8, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Light Infantry", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 4, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Cuirassiers", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("Don Cossack", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Foot Artillery", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Horse Artillery", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {randomize = true, homeCity = nil, veteran = true})
			end)
		end
	end

	-- Austrian surrender conditions in War of 5th Coalition (also see 'Russia sues for peace in the Austrian War of 5th Coalition' section)
	if state.austriaIsAtWarWithFrance2 == true then
		-- Currently at war; test for peace condition:
		if Agram.owner == France and Prag.owner == France and Trieste.owner == France and Wien.owner == France and Dresden.owner == France and Lublin.owner == France and Thorn.owner == France and Warszawa.owner == France then
			state.austriaTreatyOfSchonbrunn = true
			state.austriaIsAtWarWithFrance2 = false
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_DefeatedAustria_5thCoalition_p1))
			changeMoney(France, 1200)
			enforcePeace(Austria, France, true)
			revokeTech(Austria, "Austrian Military")
			grantTech(France, "Succession")
			grantTech(France, "Ottoman preparations")
			for unit in civ.iterateUnits() do
				if unit.owner == Austria then
					for _, typeToBeDestroyed in pairs(austrianUnitTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
				end
			end
			state.Schonbrunn_Treaty_City_Return = turn + 1
			-- ==== 8. SPECIAL FRENCH UNITS RECRUITMENT ====
			civ.ui.text("In honor of your great victory over Austria in the war of the Fifth Coalition, you authorize the creation of a new regiment of Hussars and the Garde Impériale along with the first regiment of Grenadier à Cheval.")
			createUnitsByName("Garde Impériale", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			createUnitsByName("Grenadier à Cheval", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			createUnitsByName("Hussars", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			-- =============================================
		else
			enforceWar(Austria, France, false)
		end
	end
	if turn == state.Schonbrunn_Treaty_City_Return then
		local austrianCitiesToReturn = {"Budapest", "Debrecen", "Graz", "Kosice", "Krakow",
			"Lemberg", "Olmütz", "Pécs", "Prag", "Temeschwar", "Wien"}
		for _, cityName in pairs(austrianCitiesToReturn) do
			local city = findCityByName(cityName)
			if city.owner ~= Austria then
				city.owner = Austria
				print("Gave ownership of " .. cityName .. " to Austria")
			end
		end
		for unit in civ.iterateUnits() do
			if unit.owner == Russia and unit.type.domain == 0 and tileWithinPrussia(unit.location) then
				for _, typeToBeDestroyed in pairs(russianUnitTypesToBeDestroyed) do
					if unit.type == typeToBeDestroyed then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
			elseif unit.owner == France and unit.type.domain == 0 and cityTileWithinAustria(unit.location) then
				for _, typeToBeDestroyed in pairs(frenchUnitTypesToBeDestroyed) do
					if unit.type == typeToBeDestroyed then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
			end
		end
		-- If Bagration or Kutusov are present on the map outside of Russia than return them to Moskva
		for unit in civ.iterateUnits() do
			if unit.owner == Russia and unit.type == findUnitTypeByName("Kutusov") then
				if tileWithinRussia(unit.location) == false then
					print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					civ.deleteUnit(unit)
					civ.ui.text("Prince Kutusov returns to Moskva for consultation!")
					createUnitsByName("Kutusov", Russia, {{159,21,0}}, {homeCity = nil, veteran = true})
				end
			elseif unit.owner == Russia and unit.type == findUnitTypeByName("Bagration") then
				if tileWithinRussia(unit.location) == false then
					print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					civ.deleteUnit(unit)
					civ.ui.text("General Bagration returns to Moskva for consultation!")
					createUnitsByName("Bagration", Russia, {{159,21,0}}, {homeCity = nil, veteran = true})
				end	
			end
		end
		
		local locationList = {{96,58,0}, {99,73,0}, {103,67,0}, {105,61,0}, {113,57,0}, {126,58,0}}
		-- Note: a unit will be created at *each* of the above locations, not just at the first available one
		for _, locationEntry in ipairs(locationList) do
			local eventLocation = { [1] = locationEntry }
			createUnitsByName("A. Landwehr", Austria, eventLocation, {homeCity = nil, veteran = false})
		end
		local fort = createUnitsByName("Major Fort", Austria, {{103,67,0}}, {homeCity = nil, veteran = true})
		fort.order = 2
		
		local locationList = {	{91,69,0}, {91,77,0}, {89,57,0}, {90,60,0}, {91,55,0}, {97,53,0},
								{100,52,0}, {109,55,0}, {113,53,0}, {116,54,0}, {120,48,0}, {118,42,0},
								{113,39,0}, {116,38,0}, {119,39,0}, {117,35,0}, {118,52,0}, {120,44,0},
								{124,50,0}, {120,54,0}, {123,55,0}, {126,54,0}	}
		-- Note: a unit will be created at *each* of the above locations, not just at the first available one, unless
		-- a unit of the appropriate type already exists at that location
		for _, locationEntry in ipairs(locationList) do
			local tile = civ.getTile(table.unpack(locationEntry))
			local tileContainsGardeFrontalier = false
			for unit in tile.units do
				if unit.type.name == "Garde Frontalier" then
					tileContainsGardeFrontalier = true
				end
			end
			if tileContainsGardeFrontalier == false then
				local eventLocation = { [1] = locationEntry }
				createUnitsByName("Garde Frontalier", France, eventLocation, {homeCity = nil, veteran = false})
			else
				print("    Did not create Garde Frontalier at " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because this unit already existed there")
			end
		end
		state.Schonbrunn_Treaty_City_Return = 0
	end

	--- WAR OF SIXTH COALITION
	if state.austriaIsAtWarWithFrance1 == false and state.austriaTreatyOfPressburg == true and
	   state.austriaIsAtWarWithFrance2 == false and state.austriaTreatyOfSchonbrunn == true and
	   state.austriaIsAtWarWithFrance3 == false then
		local conditionsForSixthCoalition = 0
		if state.englandIsSubdued == false then
			conditionsForSixthCoalition = conditionsForSixthCoalition + 1
		end
		if state.russiaIsSubdued == false then
			conditionsForSixthCoalition = conditionsForSixthCoalition + 1
		end
		--if state.spainIsSubdued == false then
		--	conditionsForSixthCoalition = conditionsForSixthCoalition + 1
		--end
		if state.napoleonMarriageMarieLouise == false then
			conditionsForSixthCoalition = conditionsForSixthCoalition + 1
		end
		print("    Conditions met for Sixth Coalition: " .. conditionsForSixthCoalition .. " (2 required out of 3 possible)")
		-- Currently at peace; test for war condition:
		if turn >= 93 and conditionsForSixthCoalition >= 2 and math.random(4) == 1 then
				-- April 1813; "1" is arbitrary, we want a 25% chance or 1 in 4
			state.austriaIsAtWarWithFrance3 = true
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Austria_War_6th_Coalition))
			enforceWar(Austria, France, true)
			grantTech(Austria, "Austrian Military")
			for unit in civ.iterateUnits() do
				if unit.owner == France then
					for _, typeToBeDestroyed in pairs(austrianUnitTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
				end
			end
			createUnitsByName("A. Line Infantry", Austria, {{103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {103,75,0}}, {count = 16, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Light Infantry", Austria, {{103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {103,75,0}}, {count = 6, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Charles", Austria, {{103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {103,75,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Schwarzenberg", Austria, {{103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {103,75,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Kürassier", Austria, {{103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {103,75,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Uhlans", Austria, {{103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {103,75,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Foot Artillery", Austria, {{103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {103,75,0}}, {count = 4, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("A. Horse Artillery", Austria, {{103,76,0}, {113,57,0}, {96,58,0}, {93,63,0}, {94,54,0}, {103,75,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
		else
			enforcePeace(Austria, France, false)
		end
	end
	if state.austriaIsAtWarWithFrance3 == true then
		-- Currently at war; no peace condition exists (only complete conquest can end the war)
		enforceWar(Austria, France, false)
	end

-- ------- Prussia -------
	--- WAR OF FOURTH COALITION
	if state.prussiaFourthCoalitionWarTurn == 0 then
		state.prussiaFourthCoalitionWarTurn = 9 + math.random(6)
	end
	if state.prussiaIsAtWarWithFrance1 == false and state.prussiaTreatyOfTilsit == false then
		-- Currently at peace; test for war condition:
		if turn == state.prussiaFourthCoalitionWarTurn then
			state.prussiaIsAtWarWithFrance1 = true
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Prussia_Declare_War_4thCoalition))
			enforceWar(Prussia, France, true)
			grantTech(Prussia, "Prussian Military")
			for unit in civ.iterateUnits() do
				if unit.owner == Prussia and unit.type == findUnitTypeByName("Border") then
					print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					civ.deleteUnit(unit)
				end
			end
			createUnitsByName("Brunswick Infantry", Prussia, {{86,48,0}}, {count = 3, homeCity = nil, veteran = false})
			createUnitsByName("Brunswick Cavalry", Prussia, {{86,48,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("Saxon Infantry", Prussia, {{94,52,0}}, {count = 4, homeCity = nil, veteran = false})
			createUnitsByName("Saxon Cavalry", Prussia, {{94,52,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("P. Line Infantry", Prussia, {{94,46,0}, {109,37,0}, {83,45,0}, {91,51,0}, {104,46,0}, {88,46,0}, {116,46,0}}, {count = 21, randomize = true, homeCity = nil, veteran = false})
			createUnitsByName("P. Light Infantry", Prussia, {{94,46,0}, {109,37,0}, {83,45,0}, {91,51,0}, {104,46,0}, {88,46,0}, {116,46,0}}, {count = 11, randomize = true, homeCity = nil, veteran = false})
			createUnitsByName("Blücher", Prussia, {{94,46,0}, {109,37,0}, {83,45,0}, {91,51,0}, {104,46,0}, {88,46,0}, {116,46,0}}, {randomize = true, homeCity = nil, veteran = false})
			createUnitsByName("P. Kürassier", Prussia, {{94,46,0}, {109,37,0}, {83,45,0}, {91,51,0}, {104,46,0}, {88,46,0}, {116,46,0}}, {count = 3, randomize = true, homeCity = nil, veteran = false})
			createUnitsByName("P. Uhlans", Prussia, {{94,46,0}, {109,37,0}, {83,45,0}, {91,51,0}, {104,46,0}, {88,46,0}, {116,46,0}}, {count = 3, randomize = true, homeCity = nil, veteran = false})
			createUnitsByName("P. Foot Artillery", Prussia, {{94,46,0}, {109,37,0}, {83,45,0}, {91,51,0}, {104,46,0}, {88,46,0}, {116,46,0}}, {count = 5, randomize = true, homeCity = nil, veteran = false})
			createUnitsByName("P. Horse Artillery", Prussia, {{94,46,0}, {109,37,0}, {83,45,0}, {91,51,0}, {104,46,0}, {88,46,0}, {116,46,0}}, {randomize = true, homeCity = nil, veteran = false})
			createUnitsByName("Bagration", Russia, {{136,6,0}}, {homeCity = nil, veteran = false})
			-- ==== 6. MINOR POWERS ====
			-- ------ Sweden -----------
			if state.englandIsAtWarWithFrance == true then
				local eventLocation = getRandomValidLocation("Swedish Infantry", England, {{91,37,0}, {86,38,0}})
				createUnitsByName("Swedish Infantry", England, eventLocation, {count = 3, homeCity = nil, veteran = false})
				createUnitsByName("Swedish Cavalry", England, eventLocation, {homeCity = nil, veteran = false})
			end
			-- =========================
			-- enforceAlliance(Prussia, Russia)		-- TODO: would this be correct and/or a good idea?
		else
			enforcePeace(Prussia, France, false)
		end
	end
	if state.prussiaIsAtWarWithFrance1 == true then
		-- Currently at war, test for peace condition:
		if Berlin.owner == France and Dresden.owner == France and Konigsberg.owner == France and Lublin.owner == France and Magdeburg.owner == France and Munster.owner == France and Thorn.owner == France and Warszawa.owner == France then
			state.prussiaTreatyOfTilsit = true
			state.prussiaIsAtWarWithFrance1 = false
			state.russiaEnglandTradeLoss = true
			state.austriaFifthCoalitionMessageTurn = turn + 12					-- 12 turns after current turn
			state.austriaFifthCoalitionWarTurn = turn + 15 + math.random(7)		-- 16 to 22 turns after current turn
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, you have successfully defeated your\n^Prussian and Russian adversaries on the battlefield.\n^\r^Frederick Wilhelm III and Tsar Alexander I agree to\n^meet to sign a peace treaty with you."))
			civ.ui.text(func.splitlines(scenText.impHQDispatch_DefeatedPrussia_4thCoalition_p1))
			civ.ui.text(func.splitlines(scenText.impHQDispatch_DefeatedPrussia_4thCoalition_p2))
			civ.ui.text(func.splitlines(scenText.impHQDispatch_DefeatedPrussia_4thCoalition_p3))
			changeMoney(France, 1000)
			enforcePeace(Prussia, France, true)
			revokeTech(Prussia, "Prussian Military")
			for unit in civ.iterateUnits() do
				if unit.owner == Prussia then
					for _, typeToBeDestroyed in pairs(prussianUnitTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
				end
			end
			state.Tilsit_Treaty_City_Return = turn + 1
			-- ==== 8. SPECIAL FRENCH UNITS RECRUITMENT ====
			civ.ui.text("In honor of your great victory over Prussia in the war of the Fourth Coalition, you authorize the creation of both a new Garde Impériale and a Hussars regiment.")
			createUnitsByName("Garde Impériale", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			createUnitsByName("Hussars", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			-- ==== 23. RANDOM EVENTS ====
			-- ---- Invasion of Portugal ----
			if state.prussiaTreatyOfTilsit == true then
				JUSTONCE("x_French_InvasionOfPortugal_Activated", function ()
					activateFrenchInvasionOfPortugal("France imposes Treaty of Tilsit")
				end)
			end
			-- ===========================
		else
			enforceWar(Prussia, France, false)
		end
	end
	if turn == state.Tilsit_Treaty_City_Return then
		local prussianCitiesToReturn = {"Berlin", "Breslau", "Königsberg", "Stettin"}
		for _, cityName in pairs(prussianCitiesToReturn) do
			local city = findCityByName(cityName)
			if city.owner ~= Prussia then
				city.owner = Prussia
				print("Gave ownership of " .. cityName .. " to Prussia")
			end
		end
		for unit in civ.iterateUnits() do
			if unit.owner == France and cityTileWithinPrussia(unit.location) then
				for _, typeToBeDestroyed in pairs(frenchUnitTypesToBeDestroyed) do
					if unit.type == typeToBeDestroyed then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
			end
		end
		-- Eliminate any Russian unit located in Eastern Prussia or Duchy of Warsaw
		for unit in civ.iterateUnits() do
			if unit.owner == Russia and unit.type.domain == 0 and tileWithinPrussia(unit.location) then
				for _, typeToBeDestroyed in pairs(russianUnitTypesToBeDestroyed) do
					if unit.type == typeToBeDestroyed then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
			end
		end
		-- If Bagration or Kutusov are present on the map outside of Russia than return them to Moskva
		for unit in civ.iterateUnits() do
			if unit.owner == Russia and unit.type == findUnitTypeByName("Kutusov") then
				if tileWithinRussia(unit.location) == false then
					print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					civ.deleteUnit(unit)
					civ.ui.text("Prince Kutusov returns to Moskva for consultation!")
					createUnitsByName("Kutusov", Russia, {{159,21,0}}, {homeCity = nil, veteran = true})
				end
			elseif unit.owner == Russia and unit.type == findUnitTypeByName("Bagration") then
				if tileWithinRussia(unit.location) == false then
					print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					civ.deleteUnit(unit)
					civ.ui.text("General Bagration returns to Moskva for consultation!")
					createUnitsByName("Bagration", Russia, {{159,21,0}}, {homeCity = nil, veteran = true})
				end	
			end
		end

		local fort = createUnitsByName("Major Fort", Prussia, {{94,46,0}}, {homeCity = nil, veteran = true})
		fort.order = 2
		local fort = createUnitsByName("Minor Fort", Prussia, {{97,41,0}}, {homeCity = nil, veteran = true})
		fort.order = 2
		local fort = createUnitsByName("Minor Fort", Prussia, {{104,52,0}}, {homeCity = nil, veteran = true})
		fort.order = 2
		local fort = createUnitsByName("Major Fort", Prussia, {{113,35,0}}, {homeCity = nil, veteran = true})
		fort.order = 2
		local locationList = {	{89,57,0}, {90,60,0}, {91,55,0}, {91,69,0}, {91,77,0}, {97,53,0}, {100,52,0}, {109,55,0},
								{113,53,0}, {116,54,0}, {120,48,0}, {118,42,0}, {113,39,0}, {116,38,0},
								{119,39,0}, {117,35,0}, {118,52,0}, {120,44,0}, {124,50,0}, {120,54,0}, {123,55,0},
								{126,54,0}	}
		-- Note: a unit will be created at *each* of the above locations, not just at the first available one, unless
		-- a unit of the appropriate type already exists at that location
		for _, locationEntry in ipairs(locationList) do
			local tile = civ.getTile(table.unpack(locationEntry))
			local tileContainsGardeFrontalier = false
			for unit in tile.units do
				if unit.type.name == "Garde Frontalier" then
					tileContainsGardeFrontalier = true
				end
			end
			if tileContainsGardeFrontalier == false then
				local eventLocation = { [1] = locationEntry }
				createUnitsByName("Garde Frontalier", France, eventLocation, {homeCity = nil, veteran = false})
			else
				print("    Did not create Garde Frontalier at " .. tile.x .. "," .. tile.y .. "," .. tile.z .. " because this unit already existed there")
			end
		end
		state.Tilsit_Treaty_City_Return = 0
	end

	--- WAR OF SIXTH COALITION
	if state.prussiaIsAtWarWithFrance1 == false and state.prussiaTreatyOfTilsit == true and
	   state.prussiaIsAtWarWithFrance2 == false then
		-- Currently at peace; test for war condition:
		if turn >= 91 and state.russiaIsSubdued == false and math.random(4) == 3 then	-- "3" is arbitrary, we want a 25% chance or 1 in 4
			state.prussiaIsAtWarWithFrance2 = true
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Prussia_War_6th_Coalition))
			enforceWar(Prussia, France, true)
			grantTech(Prussia, "Prussian Military")
			for unit in civ.iterateUnits() do
				if unit.owner == France then
					if unit.type == findUnitTypeByName("Garde Frontalier") then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					else
						for _, typeToBeDestroyed in pairs(prussianUnitTypesToBeDestroyed) do
							if unit.type == typeToBeDestroyed then
								print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
								civ.deleteUnit(unit)
							end
						end
					end
				end
			end
			createUnitsByName("P. Line Infantry", Prussia, {{94,46,0}, {104,52,0}, {113,35,0}, {97,41,0}}, {count = 16, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("P. Light Infantry", Prussia, {{94,46,0}, {104,52,0}, {113,35,0}, {97,41,0}}, {count = 8, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Blücher", Prussia, {{94,46,0}, {104,52,0}, {113,35,0}, {97,41,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Yorck", Prussia, {{97,41,0}, {113,35,0}, {104,52,0}, {94,46,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("P. Kürassier", Prussia, {{94,46,0}, {104,52,0}, {113,35,0}, {97,41,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("P. Uhlans", Prussia, {{94,46,0}, {104,52,0}, {113,35,0}, {97,41,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("P. Foot Artillery", Prussia, {{94,46,0}, {104,52,0}, {113,35,0}, {97,41,0}}, {count = 4, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("P. Horse Artillery", Prussia, {{94,46,0}, {104,52,0}, {113,35,0}, {97,41,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			-- ==== 6. MINOR POWERS ====
			-- ------ Sweden -----------
			if state.englandIsAtWarWithFrance == true then
				local eventLocation = getRandomValidLocation("Swedish Infantry", England, {{89,39,0}, {83,37,0}, {94,38,0}})
				createUnitsByName("Swedish Infantry", England, eventLocation, {count = 5, homeCity = nil, veteran = true})
				createUnitsByName("Swedish Cavalry", England, eventLocation, {count = 2, homeCity = nil, veteran = true})
			end
			-- =========================
		else
			enforcePeace(Prussia, France, false)
		end
	end
	if state.prussiaIsAtWarWithFrance2 == true then
		-- Currently at war; no peace condition exists (only complete conquest can end the war)
		enforceWar(Prussia, France, false)
	end

-- ------- Russia -------
	-- Initially, reinforce existing war or peace status. This may be reversed in events directly below.
	-- If not, this serves to confirm the states already in place.
	if state.russiaIsAtWarWithFrance == true then
		enforceWar(Russia, France, false)
	else
		enforcePeace(Russia, France, false)
	end
	if state.prussiaTreatyOfTilsit == true then
		JUSTONCE("x_Russia_Treaty_Of_Tilsit", function ()
			state.russiaIsAtWarWithFrance = false
			enforcePeace(Russia, France, true)
		end)
	end

	-- Russia sues for peace in the Austrian War of 5th Coalition (whether it went to war for England or not)
	if state.austriaIsAtWarWithFrance2 == false and state.austriaTreatyOfSchonbrunn == true and
	   (state.russiaIsAtWarWithFrance5thCoalition == true or state.russiaIsAtWarWithFranceforEngland == true) then
		JUSTONCE("x_conditions_Russian_Peace_5th", function ()
			state.russiaIsAtWarWithFrance = false
			state.russiaIsAtWarWithFrance5thCoalition = false
			state.russiaIsAtWarWithFranceforEngland = false
			state.russiaEnglandTradeLoss = true
			civ.ui.text(func.splitlines("Your Majesty, once again Russia has failed to protect its Coalition partners\n^in the War of the 5th Coalition and has no other option but to sue for peace\n^one more time.\n^\r^Nevertheless, you show yourself magnaminous in victory and simply ask the\n^Tsar to abide by the terms of the Treaty of Tilsit to which he agrees.\n^\r^As such, Russia will withdraw all of its troops still situated in eastern Prussia\n^or the Duchy of Warsaw by the end of next month."))
			enforcePeace(Russia, France, true)
		end)
	end
	
	-- ===================================================

	-- France will receive the 'Russian preparations' advance after it defeats Austria in the war of the 5th Coalition
	if state.austriaTreatyOfSchonbrunn == true then
		if math.random(10) == 9 then		-- "9" is arbitrary, we want a 10% chance or 1 in 10
			JUSTONCE("x_Received_Russian_Preparations", function ()
				grantTech(France, "Russian preparations")
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, you have ordered your minister of War,\n^Louis-Alexandre Berthier, to make the preliminary preparations\n^for a possible invasion of the Russian Empire.\n^\r^If you so desire, researching the \"Invasion of Russia\" will\n^remove the border tiles that have prevented your forces from\n^crossing over into Russia proper.\n^\r^Be forewarned, should you decide to pursue this route, that\n^you will have to deal with the harsh Russian summer and \n^winter conditions..."))
				civ.ui.text(func.splitlines("As part of the preparations, you've requested that the minister start\n^setting aside some extra funds, for when the time comes, you will be\n^presented with 3 options that could allow you to recruit additional\n^troops.\n^\r^For 800, 1000 or 1800 francs you will be able to have prepositioned\n^either 1) one Train Militaire, a Sapeurs and an Art. à pied 12lb or\n^2) 5 Régiment de Ligne or 3) all 8 units in Warzsawa, respectively.\n^\r^Finally, both Austria and Prussia will be required to provide a\n^contingent of 25,000 and 20,000 troops respectively, as part of\n^their treaty obligations..."))
				civ.ui.text(func.splitlines("As a consequence, the Tsar will surely direct his ministers\n^to recruit additional forces to repel your invasion and\n^therefore it is highly recommended you assemble a very large\n^army before venturing forth in this enterprise.\n^\r^Should your troops capture and hold 4 of the 6 cities of\n^Ekaterinoslav, Kyiv, Moskva, Riga, Sankt-Peterburg or\n^Smolensk AND have at least 325,000 troops in the country\n^(65 units) you will have subdued Russia and forced a\n^permanent peace treaty on it..."))
				civ.ui.text(func.splitlines("Should you succeed in subduing Russia prior to the spring of \n^1813, Austria (provided you have a diplomatic marriage) and\n^Prussia will also remain neutral for the remainder of the war.\n^\r^On the other hand, failure to subdue the Tsar's nation will not\n^only compel those other two nations to eventually renew hostilies\n^with you but ensure that Russia remains your enemy for the\n^remainder of the war."))
			end)
		end
	end

	-- Remove the 'Russian preparations' advance if France hasn't invaded Russia by January 1813
	if turn == 89 and civ.hasTech(France, findTechByName("Russian preparations")) then		-- turn 89 is January 1813
		revokeTech(France, "Russian preparations")
	end
	
	-- If France has received the 'Russian preparations' advance after defeating Austria in war of 5th Coalition AND researched the 'Invasion of Russia' it will be able to invade that country 
 	if state.x_Received_Russian_Preparations == true and civ.hasTech(France, findTechByName("Invasion of Russia")) then
		JUSTONCE("x_Researched_Invasion_Of_Russia", function ()
			state.russiaInvasion = true
			state.russiaIsAtWarWithFrance = true
			state.russiaEnglandTradeLoss = false
			state.ottomanRussiaPeaceTurn = turn + 2
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_French_DOW_vs_Russia_p1))
			civ.ui.text(func.splitlines(scenText.impHQDispatch_French_DOW_vs_Russia_p2))
			civ.ui.text(func.splitlines(scenText.impHQDispatch_French_DOW_vs_Russia_p3))
			enforceWar(Russia, France, true)
			for unit in civ.iterateUnits() do
				if unit.owner == Russia and unit.type == findUnitTypeByName("Border") then
					print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					civ.deleteUnit(unit)
				end
			end
			createUnitsByName("Barclay de Tolly", Russia, {{124,46,0},{127,35,0},{146,52,0}}, {randomize = true, homeCity = nil, veteran = false})
			civ.addImprovement(NiznijNovgorod, findImprovementByName("Military Academy"))
			createUnitsByName("Poniatowski", France, {{116,46,0}}, {homeCity = nil, veteran = true})
			createUnitsByName("A. Line Infantry", France, {{121,51,0}}, {count = 4, homeCity = nil, veteran = false})
			createUnitsByName("A. Uhlans", France, {{121,51,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("P. Line Infantry", France, {{109,37,0}}, {count = 3, homeCity = nil, veteran = false})
			createUnitsByName("P. Kürassier", France, {{109,37,0}}, {homeCity = nil, veteran = false})
		end)
	end

	-- If France invaded Russia then these are the conditions to subdue Russia, i.e. capture 4 objective cities and have over 65 units in country
	if state.russiaInvasion == true and state.russiaIsAtWarWithFrance == true then
		local conditionsSubdueRussia = 0
		if Ekaterinoslav.owner == France then
			conditionsSubdueRussia = conditionsSubdueRussia + 1
		end
		if Kyiv.owner == France then
			conditionsSubdueRussia = conditionsSubdueRussia + 1
		end
		if Moskva.owner == France then
			conditionsSubdueRussia = conditionsSubdueRussia + 1
		end
		if Riga.owner == France then
			conditionsSubdueRussia = conditionsSubdueRussia + 1
		end
		if SanktPeterburg.owner == France then
			conditionsSubdueRussia = conditionsSubdueRussia + 1
		end
		if Smolensk.owner == France then
			conditionsSubdueRussia = conditionsSubdueRussia + 1
		end
		print("    Conditions met to subdue Russia: " .. conditionsSubdueRussia .. " (4 required out of 6 possible)")
		if conditionsSubdueRussia >= 4 and getFrenchTroopsInRussia() >= 65 then
			state.russiaTreatyOfSmolensk = true
			state.russiaIsAtWarWithFrance = false
			state.russiaIsSubdued = true
			state.russiaEnglandTradeLoss = true
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Russia_Subdued))
			enforcePeace(Russia, France, true)
			revokeTech(Russia, "Russian Military")
			for unit in civ.iterateUnits() do
				if unit.owner == Russia then
					for _, typeToBeDestroyed in pairs(russianUnitTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
				end
			end
			for unit in civ.iterateUnits() do
				if unit.owner == Russia then
					for _, typeToBeDestroyed in pairs(russianLeaderTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
				end
			end			
			-- ==== 8. SPECIAL FRENCH UNITS RECRUITMENT ====
			createUnitsByName("Garde Impériale", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			civ.ui.text("In honor of your successful Russian invasion campaign, you authorize the creation of a new regiment of the Garde Impériale.")
			-- =============================================
		end
	end
	if turn >= 89 and state.russiaInvasion == false then		-- turn 89 is January 1813
		if math.random(5) == 2 then		-- "2" is arbitrary, we want a 20% chance or 1 in 5
			JUSTONCE("x_Russia_Initiates_War", function ()
				state.russiaIsAtWarWithFrance = true
				state.russiaEnglandTradeLoss = false
				civ.playSound("MilitaryFANFARE_1.wav")
				civ.ui.text("Emperor Napoléon, having grown weary of France's machinations on the continent which have become contrary to Russian interests, its ambassador to France has been directed by the Tsar to deliver a letter to your minister of foreign affairs, Talleyrand, confirming that a state of war between your two states now exists.")
				enforceWar(Russia, France, true)
				for unit in civ.iterateUnits() do
					if unit.owner == Russia and unit.type == findUnitTypeByName("Border") then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
				createUnitsByName("R. Line Infantry", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 16, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Light Infantry", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 8, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Cuirassiers", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 4, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("Don Cossack", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 5, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("Barclay de Tolly", Russia, {{124,46,0},{127,35,0},{146,52,0}}, {randomize = true, homeCity = nil, veteran = false})
				createUnitsByName("R. Foot Artillery", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 6, randomize = true, homeCity = nil, veteran = true})
				createUnitsByName("R. Horse Artillery", Russia, {{123,33,0}, {123,39,0}, {124,46,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			end)
		end
	end
	if state.russiaEnglandTradeLoss == true then
		print("Russian/English trade loss:")
		changeMoney(Russia, -25)
		changeMoney(England, -50)
	end

-- ------- Spain -------
	if turn <= 40 then			-- turn 40 is November 1808
		local frenchTroopsInIberia = getFrenchTroopsInIberia()
		if state.frenchInvasionOfPortugal == true and state.spainIsAtWarWithFrance == false and state.spainAllianceWithFranceRenewed == false then
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Status Report:\n^\r^French troops in Iberian Peninsula: " .. frenchTroopsInIberia))
		end
		print("    French troops in Iberia: " .. frenchTroopsInIberia .. " (limit is 12)")
		if frenchTroopsInIberia > 12 then
			state.spainExperiencesFrenchTransgression = true
		end
	end

	if turn == 30 and state.frenchMaritimeSupremacy == true and		-- turn 30 is January 1808
	   Lisboa.owner == France and Oporto.owner == France and Lagos.owner == France and
	   state.spainAllianceWithFranceShaken == false and state.spainExperiencesFrenchTransgression == false then
		state.spainAllianceWithFranceRenewed = true
	end
	
	-- Check to see if France failed to renew Franco-spanish alliance
	if turn >= 31 then			-- turn 31 is February 1808
		-- If succeeded, Spain permanently joins to French camp
		if state.spainAllianceWithFranceRenewed == true then
			JUSTONCE("x_Spain_Is_Subdued", function ()
				civ.playSound("MilitaryFANFARE_1.wav")
				state.spainIsSubdued = true
				civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, minister Talleyrand reports that your interventions\n^in Spain have been successful. King Ferdinand VII has agreed to step\n^down from the Spanish throne in favour of your brother Joseph who will\n^rule as sovereign directly from its capital of Madrid.\n^\r^As part of the agreement, the strategic naval base of Cadiz will also\n^be turned over to your control. In addition, regiments of Spanish Line\n^Infantry will be recruited in each of these 2 cities to maintain law and\n^order.\n^\r^As such, Spain will remain firmly in the French camp for the duration\n^of the war and France agrees to become its protector against any\n^British interventions in the Peninsula."))
				for unit in civ.iterateUnits() do
					if unit.owner == Spain and (cityTileCadiz(unit.location) or cityTileMadrid(unit.location))then
						for _, typeToBeDestroyed in pairs(spanishUnitTypesToBeDestroyed) do
							if unit.type == typeToBeDestroyed then
								print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
								civ.deleteUnit(unit)
							end
						end
						if 	unit.type == findUnitTypeByName("S. Militia") or unit.type == findUnitTypeByName("Major Fort") then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
					if 	unit.owner == Spain and unit.type == findUnitTypeByName("Village") then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
				Madrid.owner = France
				Cadiz.owner = France
				createUnitsByName("S. Line Infantry", France, {{28,96,0}}, {homeCity = Madrid, veteran = true})
				createUnitsByName("S. Line Infantry", France, {{14,112,0}}, {count = 2, homeCity = Cadiz, veteran = true})
			end)
		else
		-- If failed, set the turn on which Spain will join the anti-French camp		
			JUSTONCE("x_Spain_Alliance_Not_Renewed", function ()
				state.spainDeclaresWarTurn = turn + math.random(2, 4)
				civ.ui.text("Sire, in view of your failed attempt to renew the Franco-Spanish alliance, Spain and England agree to sign a ceasefire!")
				state.spainIsAtWarWithEngland = false
				enforcePeace(Spain, England, true)
			end)			
		end
	end

	-- Spain joins anti-French camp
	if turn == state.spainDeclaresWarTurn then
		JUSTONCE("x_Spain_Switches_Sides", function()
			state.spainIsAtWarWithEngland = false
			enforcePeace(Spain, England, true)
			civ.playSound("MilitaryFANFARE_1.wav")
			state.spainIsAtWarWithFrance = true
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Spain_Leaves_Alliance_p1))
			civ.ui.text("In addition, you could seize this opportunity to settle your differences with the Pope and take control of the Papal States by capturing Roma, whose assets could enrich French coffers!")
			enforceWar(Spain, France, true)
			grantTech(Spain, "Spanish Military")
			createUnitsByName("S. Line Infantry", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {count = 15, randomize = true, homeCity = nil, veteran = true})						
			createUnitsByName("S. Light Infantry", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {count = 7, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Blake", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {randomize = true, homeCity = nil, veteran = false})
			createUnitsByName("Cuesta", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {randomize = true, homeCity = nil, veteran = false})
			createUnitsByName("S. Line Cavalry", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("S. Foot Artillery", Spain, {{17,77,0}, {14,112,0}, {36,112,0}, {21,107,0}, {28,96,0}, {40,104,0}, {40,92,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
		end)
		state.spainDeclaresWarTurn = 0
	end
	
	
	if state.spainIsAtWarWithFrance == true then
		-- Currently at war, test for peace condition:
		if ACoruna.owner == France and Barcelona.owner == France and Bilbao.owner == France and Cadiz.owner == France and
		   Cartagena.owner == France and Gijon.owner == France and Madrid.owner == France and Malaga.owner == France and
		   Sevilla.owner == France and Valencia.owner == France and Valladolid.owner == France and Zaragoza.owner == France then
			state.spainTreatyOfMadrid = true
			state.spainIsAtWarWithFrance = false
			state.spainIsSubdued = true
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Spain_Subdued))
			enforcePeace(Spain, France, true)
			revokeTech(Spain, "Spanish Military")
			for unit in civ.iterateUnits() do
				if unit.owner == Spain then
					for _, typeToBeDestroyed in pairs(spanishUnitTypesToBeDestroyed) do
						if unit.type == typeToBeDestroyed then
							print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
							civ.deleteUnit(unit)
						end
					end
					if unit.type == findUnitTypeByName("Frigate") or unit.type == findUnitTypeByName("Two Decker") or unit.type == findUnitTypeByName("Three Decker") then
						print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
					end
				end
			end
		else
			enforceWar(Spain, France, false)
		end
	else
		enforcePeace(Spain, France, false)
	end
	if state.spainTreatyOfMadrid == true then
		print("Spanish participate in English blockade:")
		changeMoney(England, -75)
	end

-- ------- Ottoman Sultanate -------
	if state.austriaTreatyOfSchonbrunn == true and civ.hasTech(France, findTechByName("Ottoman preparations")) then
		JUSTONCE("x_Researched_Ottoman_Preparations", function ()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, you have ordered your minister of War,\n^Louis-Alexandre Berthier, to make the preliminary preparations\n^for a possible war with the Ottoman Empire.\n^\r^If you so desire, researching the \"War with Sultanate\" advance\n^will allow you to begin immediate hostilies with that Empire.\n^\r^If you decide to declare war, both the Border tiles and the two\n^Austrian villages situated south of Agram will be removed (if\n^you hadn't already eliminated them).\n^\r^Be forwarned, should you decide to pursue that route, that it\n^will not sue for peace unless you capture its great cities of\n^Istanbul and Ankara."))
		end)
	end
	if state.x_Researched_Ottoman_Preparations == true and civ.hasTech(France, findTechByName("War with Sultanate")) then
		JUSTONCE("x_Researched_War_With_Sultanate", function ()
			state.ottomanIsAtWarWithFrance = true
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, you have ordered your minister of\n^foreign affairs, Charles Maurice de Talleyrand, to\n^advise the ambassador of the Ottoman Sultanate that\n^henceforth a state of war exists between the two\n^great Empires.\n^\r^You have made a fateful decision, that can only be\n^remedied by the capture of Istanbul and Ankara."))
			enforceWar(Ottoman, France, true)
			for unit in civ.iterateUnits() do
				if unit.owner == Ottoman and unit.type == findUnitTypeByName("Border") then
					print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					civ.deleteUnit(unit)
				end
			end
			for unit in civ.iterateUnits() do
				if unit.owner == Austria and unit.type == findUnitTypeByName("Village") then
					print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					civ.deleteUnit(unit)
				end
			end
		end)
	end

	if state.ottomanIsAtWarWithFrance == true and state.ottomanIsAtWarWithRussia == true then
		if math.random(3) == 1 then		-- "1" is arbitrary, we want a 33% chance or 1 in 3
			JUSTONCE("x_Ottoman_War_With_France", function ()
				civ.ui.text("Imperial Dispatch - " .. displayMonthYear() .. ": In lieu of the war with France, the Sultan Selim III agrees to sign a peace treaty with Russia in exchange for the status quo and a monetary compensation!")
				state.ottomanIsAtWarWithRussia = false
				changeMoney(Ottoman, -250)
				enforcePeace(Ottoman, Russia, true)
			end)
		end
	end

	if state.ottomanIsAtWarWithFrance == true then
		-- Currently at war, test for peace condition:
		if Ankara.owner == France and Istanbul.owner == France then
			print("Ottomans sign Treaty of Erdine")
			state.ottomanTreatyOfErdine = true
			state.ottomanIsAtWarWithFrance = false
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Ottoman_Subdued))
			enforcePeace(Ottoman, France, true)
			revokeTech(Ottoman, "Ottoman Military")
			-- ==== 8. SPECIAL FRENCH UNITS RECRUITMENT ====
			createUnitsByName("Grenadier à Cheval", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			civ.ui.text("In honor of your great victory over the Ottoman Sultanate, you authorize the creation of a new regiment of Grenadier à Cheval.")
			-- =============================================
		else
			enforceWar(Ottoman, France, false)
		end
	else
		-- Note that we only want to enforcePeace *if* the treaty has been signed
		-- If it has not, we are in the initial game phase (pre-war) and will not enforce peace
		if state.ottomanTreatyOfErdine == true then
			enforcePeace(Ottoman, France, false)
		end
	end
	if state.austriaTreatyOfPressburg == true and state.ottomanIsAtWarWithRussia == false and state.ottomanTreatyofBucuresti == false then
		if math.random(10) == 9 then		-- "9" is arbitrary, we want a 10% chance or 1 in 10
			JUSTONCE("x_Ottoman_War_With_Russia", function ()
				state.ottomanIsAtWarWithRussia = true
				civ.ui.text(func.splitlines(scenText.impHQDispatch_Ottoman_Russian_War))
				enforceWar(Ottoman, Russia, true)
			end)
		end
	end
	if state.ottomanIsAtWarWithRussia == true then
		-- Currently at war, test for peace condition:
		if Bucuresti.owner == Russia or Odesa.owner == Ottoman or (state.ottomanRussiaPeaceTurn > 0 and turn >= state.ottomanRussiaPeaceTurn) then
			state.ottomanTreatyofBucuresti = true
			state.ottomanIsAtWarWithRussia = false
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^The bitter conflict between Russia and the Ottoman Sultanate\n^has come to an end, and the two powers have agreed to sign\n^a peace treaty ending hostilities between them."))
			enforcePeace(Ottoman, Russia, true)
		else
			enforceWar(Ottoman, Russia, false)
		end
	else
		-- Note that we only want to enforcePeace *if* the treaty has been signed
		-- If it has not, we are in the initial game phase (pre-war) and will not enforce peace
		if state.ottomanTreatyofBucuresti == true then
			enforcePeace(Ottoman, Russia, false)
		end
	end

-- --- French Automatic Victory
	if state.frenchVictory == false then
		local conditionsFrenchVictory = 0
		if Cadiz.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Danzig.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Hanover.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Istanbul.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Leipzig.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Lisboa.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if London.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Madrid.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Moskva.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Paris.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if SanktPeterburg.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Warszawa.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		if Venezia.owner == France then
			conditionsFrenchVictory = conditionsFrenchVictory + 1
		end
		print("    Conditions met for automatic French victory: " .. conditionsFrenchVictory .. " (11 required out of 13 possible)")
		if conditionsFrenchVictory >= 11 then
			civ.playSound("Marseillaise 1.wav")
			civ.ui.text(func.splitlines("************* FRANCE GAINS MASTERY OVER EUROPE *************\n^\r^Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, through your remarkable leadership, your forces\n^have captured the last bastion that stood in your way to ultimate\n^victory on the European continent.\n^\r^The remaining members of the Coalition that still opposed you, have\n^sent delegations to negotiate peace terms favorable to you and your\n^Empire.\n^\r^France has become the dominant power of its day and you have secured\n^the reign of the entire Bonaparte clan, probably for generations to come.\n^\r^You will go down in history as one of the greatest leaders of all time."))
			civ.endGame(true)
		end
	end
-- ==========================================

-- ==== 3. LEADERS (Turn-based Creation) ====
-- ---- French Leaders ----
	if turn == 6 then
		createUnitsByName("Murat", France, {{58,60,0}}, {homeCity = nil, veteran = true})
		civ.ui.text(func.splitlines("Emperor, Maréchal Joachim Murat, who is married to your sister\n^Hortense, arrives in Paris to join the ranks of your officer corps!\n^\r^Known for his bravery and fearlessness as a cavalry commander, you\n^will come to bestow upon him the title of First Horseman of Europe."))
	end
-- ---- Coalition Leaders: Austrian ----
	if turn == state.Charles_Return_On then
		createUnitsByName("Charles", Austria, {{103,67,0}, {112,70,0}, {118,70,0}}, {randomize = false, homeCity = nil, veteran = true})
		civ.ui.text("The Archduke Charles of Austria has returned to resume his command!")
		state.Charles_Return_On = 0
	end
	if turn == state.Schwarzenberg_Return_On then
		createUnitsByName("Schwarzenberg", Austria, {{103,67,0}, {112,70,0}, {118,70,0}}, {randomize = false, homeCity = nil, veteran = true})
		civ.ui.text("Generalfeldmarschall Karl Philipp, Prince of Schwarzenberg, has returned to resume his command!")
		state.Schwarzenberg_Return_On = 0
	end
-- ---- Coalition Leaders: English ----
--	-- General Wellington
	local wellingtonIberiaLocationList = {{6,98,0}, {12,88,0}, {8,106,0}, {8,94,0}, {13,85,0}, {10,90,0}}
	local wellingtonEnglandLocationList = {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}}
	if turn >= 33 and state.frenchInvasionOfPortugal == true and state.englandIsAtWarWithFrance == true then
		if math.random(6) <= 1 then		-- we want a 16.7% chance or 1 in 6
			local wellingtonLocationList = wellingtonIberiaLocationList
			local wellingtonLocationDesc = "arrives in the Iberian Peninsula"
			if state.englandExperiencesFrenchTransgression == true then
				wellingtonLocationList = wellingtonEnglandLocationList
				wellingtonLocationDesc = "mobilizes in England"
			end
			JUSTONCE("x_Wellington_Appears", function ()
				createUnitsByName("Wellington", England, wellingtonLocationList, {randomize = false, homeCity = nil, veteran = true})
				createUnitsByName("B. Line Infantry", England, wellingtonLocationList, {count = 3, randomize = false, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, wellingtonLocationList, {randomize = false, homeCity = nil, veteran = false})
				createUnitsByName("K.G.L.", England, wellingtonLocationList, {randomize = false, homeCity = nil, veteran = true})
				createUnitsByName("Dragoon Guards", England, wellingtonLocationList, {randomize = false, homeCity = nil, veteran = true})
				createUnitsByName("B. Foot Artillery", England, wellingtonLocationList, {randomize = false, homeCity = nil, veteran = true})
				civ.ui.text("A large contingent of troops under General Arthur Wellesley, the future Duke of Wellington, " .. wellingtonLocationDesc .. " to fight the French!")
			end)
		end
	end
	if turn == state.Wellington_Return_On and state.englandIsAtWarWithFrance == true then
		local wellingtonLocationList = wellingtonIberiaLocationList
		local wellingtonLocationDesc = " in the Peninsula"
		if state.englandExperiencesFrenchTransgression == true then
			wellingtonLocationList = wellingtonEnglandLocationList
			wellingtonLocationDesc = ""
		end
		createUnitsByName("Wellington", England, wellingtonLocationList, {randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("B. Line Infantry", England, wellingtonLocationList, {count = 2, randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("B. Light Infantry", England, wellingtonLocationList, {randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("Dragoon Guards", England, wellingtonLocationList, {randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("B. Foot Artillery", England, wellingtonLocationList, {randomize = false, homeCity = nil, veteran = true})
		civ.ui.text("The Duke of Wellington has resumed his command and arrives with a fresh contingent of British troops" .. wellingtonLocationDesc .. "!")
		state.Wellington_Return_On = 0
	end
	-- General Wellington Potential redeployment
	if state.englandIsAtWarWithFrance == true then
		local wellingtonUnit = nil
		local wellingtonLocation = nil
		for unit in civ.iterateUnits() do
			if unit.type.name == "Wellington" then
				wellingtonUnit = unit
				if tileWithinIberia(unit.location) then
					wellingtonLocation = "Iberia"
				elseif tileWithinEngland(unit.location) then
					wellingtonLocation = "England"
				end
				break
			end
		end
		if state.englandExperiencesFrenchTransgression == true and wellingtonLocation == "Iberia" then
			print("Redeployment of Wellington to England scheduled for " .. displayMonthYear())
			civ.deleteUnit(wellingtonUnit)
			state.Wellington_Redeploy_On = turn + 1
			state.Wellington_Redploy_Location = "England"
		elseif state.englandExperiencesFrenchTransgression == false and wellingtonLocation == "England" then
			print("Redeployment of Wellington to Iberia scheduled for " .. displayMonthYear())
			civ.deleteUnit(wellingtonUnit)
			state.Wellington_Redeploy_On = turn + 1
			state.Wellington_Redploy_Location = "Iberia"
		end
	end
	if turn == state.Wellington_Redeploy_On and state.englandIsAtWarWithFrance == true then
		local wellingtonLocationList = wellingtonIberiaLocationList
		if state.Wellington_Redploy_Location == "England" then
			wellingtonLocationList = wellingtonEnglandLocationList
		end
		createUnitsByName("Wellington", England, wellingtonLocationList, {randomize = true, homeCity = nil, veteran = true})
		civ.ui.text("The Duke of Wellington has redeployed to " .. state.Wellington_Redploy_Location .. " to battle the French there!")
		state.Wellington_Redeploy_On = 0
		state.Wellington_Redploy_Location = nil
	end

--	-- General Moore
	local mooreIberiaLocationList = {{8,106,0}, {6,98,0}, {6,104,0}, {10,90,0}, {13,85,0}}
	local mooreEnglandLocationList = {{46,44,0}, {49,39,0}, {46,34,0}, {53,45,0}}
	if turn >= 35 and state.frenchInvasionOfPortugal == true and state.englandIsAtWarWithFrance == true then
		if math.random(6) <= 1 then		-- we want a 16.7% chance or 1 in 6
			local mooreLocationList = mooreIberiaLocationList
			local mooreLocationDesc = "in Spain"
			if state.englandExperiencesFrenchTransgression == true then
				mooreLocationList = mooreEnglandLocationList
				mooreLocationDesc = "invasion"
			end
			JUSTONCE("x_Moore_Appears", function ()
				createUnitsByName("Moore", England, mooreLocationList, {randomize = false, homeCity = nil, veteran = true})
				createUnitsByName("B. Line Infantry", England, mooreLocationList, {count = 3, randomize = false, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, mooreLocationList, {randomize = false, homeCity = nil, veteran = false})
				createUnitsByName("B. Foot Artillery", England, mooreLocationList, {randomize = false, homeCity = nil, veteran = false})
				civ.ui.text("England sends Lieutenant-General Sir John Moore with a sizable contingent of troops to battle the French " .. mooreLocationDesc .. "!")
			end)
		end
	end
	if turn == state.Moore_Return_On and state.englandIsAtWarWithFrance == true then
		local mooreLocationList = mooreIberiaLocationList
		local mooreLocationDesc = "Iberian Peninsula"
		if state.englandExperiencesFrenchTransgression == true then
			mooreLocationList = mooreEnglandLocationList
			mooreLocationDesc = "front"
		end
		createUnitsByName("Moore", England, mooreLocationList, {randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("B. Line Infantry", England, mooreLocationList, {count = 2, randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("Dragoon Guards", England, mooreLocationList, {randomize = false, homeCity = nil, veteran = true})
		civ.ui.text("General Moore returns to the " .. mooreLocationDesc .. " to fight the French once again!")
		state.Moore_Return_On = 0
	end

--	-- General Uxbridge
	local uxbridgeIberiaLocationList = {{6,98,0}, {12,88,0}, {9,93,0}, {8,106,0}, {17,115,0}}
	local uxbridgeEnglandLocationList = {{46,34,0}, {49,39,0}, {46,44,0}, {53,45,0}}
	if turn >= 40 and state.frenchInvasionOfPortugal == true and state.englandIsAtWarWithFrance == true then
		if math.random(6) <= 1 then	-- we want a 16.7% chance or 1 in 6
			local uxbridgeLocationList = uxbridgeIberiaLocationList
			local uxbridgeLocationDesc = "is sent to Portugal"
			if state.englandExperiencesFrenchTransgression == true then
				uxbridgeLocationList = uxbridgeEnglandLocationList
				uxbridgeLocationDesc = "scrambles"
			end
			JUSTONCE("x_Uxbridge_Appears", function ()
				createUnitsByName("Uxbridge", England, uxbridgeLocationList, {randomize = false, homeCity = nil, veteran = false})
				createUnitsByName("B. Line Infantry", England, uxbridgeLocationList, {count = 2, randomize = false, homeCity = nil, veteran = false})
				civ.ui.text("A small British expeditionary force, under Field Marshal Henry William Paget, the future Earl of Uxbridge, " .. uxbridgeLocationDesc .. " to bolster British defenses!")
			end)
		end
	end
	uxbridgeIberiaLocationList = {{12,88,0}, {8,106,0}, {13,85,0}, {6,104,0}, {17,115,0}}
	if turn == state.Uxbridge_Return_On and state.englandIsAtWarWithFrance == true then
		local uxbridgeLocationList = uxbridgeIberiaLocationList
		local uxbridgeLocationDesc = "Spain"
		if state.englandExperiencesFrenchTransgression == true then
			uxbridgeLocationList = uxbridgeEnglandLocationList
			uxbridgeLocationDesc = "the English front"
		end
		createUnitsByName("Uxbridge", England, uxbridgeLocationList, {randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("B. Line Infantry", England, uxbridgeLocationList, {count = 2, randomize = false, homeCity = nil, veteran = true})
		civ.ui.text("General Uxbridge has returned to " .. uxbridgeLocationDesc .. " with a small British contingent!")
		state.Uxbridge_Return_On = 0
	end

-- ---- British Send Naval Squadron in Mediterranean ----
		if turn >= 9 and state.englandIsAtWarWithFrance == true then
			if math.random(100) <= 25 then	-- we want a 25% chance
				JUSTONCE("x_British_Mediterranean_Squadron", function ()
					print("British Mediterranean Squadron event takes place")
					local eventLocation = getRandomValidLocation("Three Decker", England, {{94,128,0}, {76,110,0}, {17,115,0}})
					createUnitsByName("Three Decker", England, eventLocation, {homeCity = nil, veteran = true})
					createUnitsByName("Two Decker", England, eventLocation, {count = 2, homeCity = nil, veteran = false})
					createUnitsByName("Frigate", England, eventLocation, {homeCity = nil, veteran = false})
					civ.ui.text("A British naval squadron arrives in the Mediterranean!")
				end)
			end
		end
-- ---- British Send 2nd Naval Squadron in Mediterranean ----
		if turn >= 93 and state.englandIsAtWarWithFrance == true then
			if math.random(100) <= 25 then	-- we want a 25% chance
				JUSTONCE("x_British_Mediterranean_Squadron", function ()
					print("British Mediterranean Squadron event takes place")
					local eventLocation = getRandomValidLocation("Three Decker", England,
						{{92,116,0}, {99,117,0}})
					createUnitsByName("Three Decker", England, eventLocation, {homeCity = nil, veteran = true})
					createUnitsByName("Two Decker", England, eventLocation, {count = 2, homeCity = nil, veteran = false})
					createUnitsByName("Frigate", England, eventLocation, {homeCity = nil, veteran = false})
					createUnitsByName("Transport", England, eventLocation, {homeCity = nil, veteran = false})
					createUnitsByName("Dragoon Guards", England, eventLocation, {randomize = false, homeCity = nil, veteran = true})
					createUnitsByName("Light Dragoon", England, eventLocation, {randomize = false, homeCity = nil, veteran = true})
					createUnitsByName("B. Foot Artillery", England, eventLocation, {randomize = false, homeCity = nil, veteran = true})
					civ.ui.text("A British naval squadron arrives in the Mediterranean!")
				end)
			end
		end

-- ---- British Build Naval Tranport Squadrons ----
		if state.englandIsAtWarWithFrance == true then
			if turn == 18 or turn == 33 or turn == 45 or turn == 69 or turn == 93 then
				print("British Naval Transport Squadron event takes place")
				createUnitsByName("Transport", England, {{52,28,0}, {53,45,0}}, {randomize = true, homeCity = nil, veteran = true})
				-- civ.ui.text("England builds a naval transport squadron!")
			end
		end

-- ---- British Send Reinforcements to Portugal (or England) ----
	if state.rebellionInIreland == false then
		if turn >= 30 and state.englandIsAtWarWithFrance == true and state.frenchInvasionOfPortugal == true then
			if math.random(18) <= 3 then -- we want an 16.5% chance or 3 in 18
				print("British Portuguese Reinforcements event takes place")
				local reinforcementIberiaLocationList = {{6,98,0}, {12,88,0}, {8,106,0}, {8,94,0}, {13,83,0}, {21,79,0}, {17,115,0}, {31,83,0}, {38,108,0}, {11,107,0}}
				local reinforcementEnglandLocationList = {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}}
				local eventLocationList = reinforcementIberiaLocationList
				local eventLocationDesc = "arrived in the Iberian Peninsula"
				if state.englandExperiencesFrenchTransgression == true then
					eventLocationList = reinforcementEnglandLocationList
					eventLocationDesc = "been recruited in England"
				end
				local eventLocation = getRandomValidLocation("B. Line Infantry", England, eventLocationList)
				createUnitsByName("B. Line Infantry", England, eventLocation, {count = 3, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, eventLocation, {count = 2, homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, eventLocation, {homeCity = nil, veteran = false})
				createUnitsByName("Dragoon Guards", England, eventLocation, {homeCity = nil, veteran = false})
				createUnitsByName("B. Foot Artillery", England, eventLocation, {homeCity = nil, veteran = false})
				createUnitsByName("B. Horse Artillery", England, eventLocation, {homeCity = nil, veteran = false})
				civ.ui.text(func.splitlines("As Ireland remains peaceful, new British\n^reinforcements have " .. eventLocationDesc .. "\n^to aid in the war against France!"))
			end
		end
	else
		if turn >= 30 and state.englandIsAtWarWithFrance == true and state.frenchInvasionOfPortugal == true then
			if math.random(24) <= 3 then -- we want an 12.5% chance or 3 in 24
				print("British Portuguese Reinforcements event takes place")
				local reinforcementIberiaLocationList = {{6,98,0}, {12,88,0}, {8,106,0}, {8,94,0}, {13,83,0}, {21,79,0}, {17,115,0}, {31,83,0}, {38,108,0}, {11,107,0}}
				local reinforcementEnglandLocationList = {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}}
				local eventLocationList = reinforcementIberiaLocationList
				local eventLocationDesc = "arrived in the Iberian Peninsula"
				if state.englandExperiencesFrenchTransgression == true then
					eventLocationList = reinforcementEnglandLocationList
					eventLocationDesc = "been recruited in England"
				end
				local eventLocation = getRandomValidLocation("B. Line Infantry", England, eventLocationList)
				createUnitsByName("B. Line Infantry", England, eventLocation, {count = 3, homeCity = nil, veteran = false})
				createUnitsByName("B. Light Infantry", England, eventLocation, {count = 2, homeCity = nil, veteran = false})
				createUnitsByName("Light Dragoon", England, eventLocation, {homeCity = nil, veteran = false})
				createUnitsByName("Dragoon Guards", England, eventLocation, {homeCity = nil, veteran = false})
				createUnitsByName("B. Foot Artillery", England, eventLocation, {homeCity = nil, veteran = false})
				createUnitsByName("B. Horse Artillery", England, eventLocation, {homeCity = nil, veteran = false})
				civ.ui.text("British reinforcements have " .. eventLocationDesc .. " to aid in the war against France!")
			end
		end
	end

-- ---- British Supplies Portugal JUSTONCE with Extra Troops if No Rebellion in Ireland ----
	if state.rebellionInIreland == false then
		if turn <= 30 and state.englandIsAtWarWithFrance == true and state.frenchInvasionOfPortugal == true then
			if math.random(3) <= 1 then	-- we want a 33% chance
				JUSTONCE("x_British_Baltic_Squadron", function ()
					createUnitsByName("Portuguese Infantry", England, {{12,88,0}, {6,98,0}, {8,106,0}}, {count = 2, randomize = true, homeCity = nil, veteran = false})
					createUnitsByName("Coalition Shells", England, {{12,88,0}, {6,98,0}, {8,106,0}}, {randomize = true, homeCity = nil, veteran = false})
					civ.ui.text("As there is no Irish rebel activity in Ireland during this month, England takes this onetime opportunity to send extra supplies to arm the Portuguese military against French invasion plans!")
				end)
			end
		end
	end

-- ---- British Send Naval Squadron and Military Expedition in Baltic ----
	if turn >= 36 and state.austriaIsAtWarWithFrance2 == true then
		if math.random(100) <= 25 then	-- we want a 25% chance
			JUSTONCE("x_British_Baltic_Squadron", function ()
				print("British Baltic Squadron event takes place")
				local eventLocation = getRandomValidLocation("Three Decker", England, {{90,20,0}, {98,30,0}})
				createUnitsByName("Three Decker", England, eventLocation, {homeCity = nil, veteran = true})
				createUnitsByName("Two Decker", England, eventLocation, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("Frigate", England, eventLocation, {homeCity = nil, veteran = true})
				createUnitsByName("Transport", England, eventLocation, {homeCity = nil, veteran = true})
				createUnitsByName("Royal Marines", England, eventLocation, {count = 2, homeCity = nil, veteran = true})
				createUnitsByName("Dragoon Guards", England, eventLocation, {homeCity = nil, veteran = true})
				createUnitsByName("B. Foot Artillery", England, eventLocation, {homeCity = nil, veteran = true})
				civ.ui.text("A British naval expeditionary force arrives in the Baltic!")
			end)
		end
	end

-- ---- Russian Naval Activity in Mediterranean from Corfu ----
	if turn >= 1 and state.russiaIsAtWarWithFrance == true and state.corfuIsRussian == true then
		if math.random(8) <= 1 then	-- we want a 12.5% chance
			print("Russian Frigate Squadron Event takes place")
			createUnitsByName("Frigate", Russia, {{81,97,0}, {92,106,0}, {96,114,0}, {72,92,0}}, {randomize = true, homeCity = nil, veteran = false})
		end
		if math.random(12) <= 1 then	-- we want a 8.5% chance
			print("Russian Two Decker Squadron Event takes place")
			createUnitsByName("Two Decker", Russia, {{92,106,0}, {81,97,0}, {72,92,0}, {96,114,0}}, {randomize = true, homeCity = nil, veteran = false})
		end
		if math.random(16) <= 1 then	-- we want a 6% chance
			print("Russian Three Decker Squadron Event takes place")
			createUnitsByName("Three Decker", Russia, {{96,114,0}, {72,92,0}, {81,97,0}, {92,106,0}}, {randomize = true, homeCity = nil, veteran = false})
		end
	end

-- ---- Coalition Leaders: Prussian ----
	if turn == state.Blucher_Return_On then
		createUnitsByName("Blücher", Prussia, {{94,46,0}, {97,41,0}, {104,52,0}, {113,35,0}}, {randomize = false, homeCity = nil, veteran = true})
		civ.ui.text("Generalfeldmarschall Blücher has returned to resume his command!")
		state.Blucher_Return_On = 0
	end
	if turn == state.Yorck_Return_On then
		createUnitsByName("Yorck", Prussia, {{97,41,0}, {113,35,0}, {104,52,0}, {94,46,0}}, {randomize = true, homeCity = nil, veteran = true})
		civ.ui.text("Generalfeldmarschall Yorck has returned to resume his command!")
		state.Yorck_Return_On = 0
	end
-- ---- Coalition Leaders: Russian ----
	if turn == state.BarclayDeTolly_Return_On then
		createUnitsByName("Barclay de Tolly", Russia, {{124,46,0}, {123,23,0}, {133,17,0}, {136,6,0}, {162,10,0}}, {randomize = false, homeCity = nil, veteran = true})
		civ.ui.text("Field Marshall Michael Barclay de Tolly has returned to resume his command!")
		state.BarclayDeTolly_Return_On = 0
	end
	if turn == state.Bagration_Return_On then
		createUnitsByName("Bagration", Russia, {{124,46,0}, {146,52,0}, {159,35,0}, {175,13,0}, {149,63,0}}, {randomize = false, homeCity = nil, veteran = true})
		civ.ui.text("General Pyotr Bagration has returned to resume his command!")
		state.Bagration_Return_On = 0
	end
	if turn == state.Kutusov_Return_On then
		createUnitsByName("Kutusov", Russia, {{124,46,0}, {134,36,0}, {146,30,0}, {159,21,0}, {136,6,0}}, {randomize = false, homeCity = nil, veteran = true})
		civ.ui.text("Prince Mikhail Kutusov has returned to resume his command!")
		state.Kutusov_Return_On = 0
	end
-- ---- Coalition Leaders: Spanish ----
	if turn == state.Blake_Return_On then
		createUnitsByName("Blake", Spain, {{14,112,0}, {17,77,0}, {36,112,0}, {28,96,0}, {23,113,0}}, {randomize = true, homeCity = nil, veteran = true})
		createUnitsByName("S. Light Infantry", Spain, {{14,112,0}, {17,77,0}, {36,112,0}, {28,96,0}, {23,113,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
		createUnitsByName("S. Foot Artillery", Spain, {{14,112,0}, {17,77,0}, {36,112,0}, {28,96,0}, {23,113,0}}, {randomize = true, homeCity = nil, veteran = true})
		civ.ui.text("General Joachim Blake has returned!")
		state.Blake_Return_On = 0
	end
	if turn == state.Cuesta_Return_On then
		createUnitsByName("Cuesta", Spain, {{14,112,0}, {17,77,0}, {36,112,0}, {28,96,0}, {23,113,0}}, {randomize = true, homeCity = nil, veteran = true})
		createUnitsByName("S. Light Infantry", Spain, {{14,112,0}, {17,77,0}, {36,112,0}, {28,96,0}, {23,113,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
		createUnitsByName("S. Line Cavalry", Spain, {{14,112,0}, {17,77,0}, {36,112,0}, {28,96,0}, {23,113,0}}, {randomize = true, homeCity = nil, veteran = true})
		civ.ui.text("General Cuesta has returned!")
		state.Cuesta_Return_On = 0
	end
-- ---- Allied Elite Unit replacements
	if turn == state.KGL_Return_On then
		createUnitsByName("K.G.L.", England, {{6,98,0}, {12,88,0}, {8,106,0}, {17,115,0}}, {randomize = true, homeCity = nil, veteran = true})
		civ.ui.text("The British raise a new regiment of the King's German Legion!")
		state.KGL_Return_On = 0
	end
	-- if turn == state.LifeGuards_Return_On then
		-- createUnitsByName("Life Guards", Russia, {{124,46,0}, {134,36,0}, {146,30,0}, {159,21,0}, {136,6,0}}, {randomize = false, homeCity = nil, veteran = true})
		-- civ.ui.text("The Russians raise a new elite Life Guards infantry regiment!")
		-- state.LifeGuards_Return_On = 0
	-- end

-- ==========================================

-- ==== 6. MINOR POWERS ====
-- ------ Baltic States ----
	if state.minorDuchyOfWarsaw == true and (turn == 33 or turn ==45 or turn == 57 or turn == 69 or turn == 81) then
		createUnitsByName("Polish Infantry", France, {{116,46,1}}, {homeCity = nil, veteran = false})
		if turn == 45 then
			createUnitsByName("Polish Lancers", France, {{116,46,1}}, {homeCity = nil, veteran = false})
		end
	end
	if state.englandIsAtWarWithFrance == true and state.prussiaIsAtWarWithFrance2 == true and turn >= 93 then
		-- turn 93 is April 1813
		if math.random(200) <= 33 then	-- we want a 16.5% chance or 33 in 200
			createUnitsByName("Swedish Infantry", England, {{89,39,0}, {83,37,0}, {94,38,0}}, {randomize = true, homeCity = nil, veteran = false})
		end
		if math.random(25) <= 2 then		-- we want an 8% chance or 2 in 25
			createUnitsByName("Swedish Cavalry", England, {{89,39,0}, {83,37,0}, {94,38,0}}, {randomize = true, homeCity = nil, veteran = false})
		end
	end
-- ------ German Minors: Rhine Confederation ----
	if state.minorRhineConfederation == true and Munster.owner == France then
		JUSTONCE("x_Westphalian_Infantry", function()
			createUnitsByName("Westphalian Infantry", France, {{76,46,1}}, {homeCity = Westphalia, veteran = false})
			civ.ui.text("Your Majesty, your troops have gained control of the minor German kingdom of Westphalia. As such, its rulers readily join your Confederation of the Rhine and pledge its troops to your command!")
		end)
	end
	if state.minorRhineConfederation == true then
		if turn == 20 then		-- turn 20 is March 1807
			local bavariaSupplyTrainTile = civ.getTile(85,65,1)
			bavariaSupplyTrainTile.terrainType = 0
			print("Set terrain type to 0 at 85,65,1 for Bavaria")
			local westphaliaSupplyTrainTile = civ.getTile(78,44,1)
			westphaliaSupplyTrainTile.terrainType = 0
			print("Set terrain type to 0 at 78,44,1 for Westphalia")
			local wurtemburgSupplyTrainTile = civ.getTile(81,61,1)
			wurtemburgSupplyTrainTile.terrainType = 0
			print("Set terrain type to 0 at 81,61,1 for Würtemberg")
		end
		if turn == 21 then		-- turn 21 is April 1807
			createUnitsByName("Bavarian Infantry", France, {{87,67,1}}, {homeCity = Bavaria, veteran = false})
			createUnitsByName("Westphalian Infantry", France, {{76,46,1}}, {homeCity = Westphalia, veteran = false})
			createUnitsByName("Würtemberg Infantry", France, {{79,63,1}}, {homeCity = Wurtemburg, veteran = false})
		end
		if turn == 33 then		-- turn 33 is April 1808
			createUnitsByName("Bavarian Cavalry", France, {{87,67,1}}, {homeCity = Bavaria, veteran = false})
			createUnitsByName("Rhine Infantry", France, {{81,57,1}}, {homeCity = Rhineland, veteran = false})
			createUnitsByName("Westphalian Infantry", France, {{76,46,1}}, {homeCity = Westphalia, veteran = false})
		end
		if turn == 44 then		-- turn 44 is March 1809
			local rhinelandSupplyTrainTile = civ.getTile(79,55,1)
			rhinelandSupplyTrainTile.terrainType = 0
			print("Set terrain type to 0 at 79,55,1 for Rhineland")
		end
		if turn == 45 then	-- turn 45 is April 1809
			createUnitsByName("Bavarian Infantry", France, {{87,67,1}}, {homeCity = Bavaria, veteran = false})
			createUnitsByName("Rhine Infantry", France, {{81,57,1}}, {homeCity = Rhineland, veteran = false})
			createUnitsByName("Westphalian Cavalry", France, {{76,46,1}}, {homeCity = Westphalia, veteran = false})
			createUnitsByName("Würtemberg Infantry", France, {{79,63,1}}, {homeCity = Wurtemburg, veteran = false})
		end
		if turn == 57 then		-- turn 57 is April 1810
			createUnitsByName("Bavarian Infantry", France, {{87,67,1}}, {homeCity = Bavaria, veteran = false})
			createUnitsByName("Rhine Infantry", France, {{81,57,1}}, {homeCity = Rhineland, veteran = false})
		end
		if turn == 69 then		-- turn 69 is April 1811
			createUnitsByName("Würtemberg Infantry", France, {{79,63,1}}, {homeCity = Wurtemburg, veteran = false})
		end
		if turn == 81 then		-- turn 81 is April 1812
			createUnitsByName("Bavarian Infantry", France, {{87,67,1}}, {homeCity = Bavaria, veteran = false})
			createUnitsByName("Rhine Infantry", France, {{81,57,1}}, {homeCity = Rhineland, veteran = false})
		end
		if state.prussiaIsAtWarWithFrance2 == true and state.russiaIsAtWarWithFrance == true then
			local conditionsConfederationToDisband = 0
			if Brunswick.owner ~= France then
				conditionsConfederationToDisband = conditionsConfederationToDisband + 1
			end
			if Danzig.owner ~= France then
				conditionsConfederationToDisband = conditionsConfederationToDisband + 1
			end
			if Dresden.owner ~= France then
				conditionsConfederationToDisband = conditionsConfederationToDisband + 1
			end
			if Hanover.owner ~= France then
				conditionsConfederationToDisband = conditionsConfederationToDisband + 1
			end
			if Leipzig.owner ~= France then
				conditionsConfederationToDisband = conditionsConfederationToDisband + 1
			end
			if Warszawa.owner ~= France then
				conditionsConfederationToDisband = conditionsConfederationToDisband + 1
			end
			if turn >= 89 and conditionsConfederationToDisband >= 3 then
				JUSTONCE("x_Rhine_Confederation_Deactivated", function()
					print("Deactivated Rhine Confederation")
					civ.ui.text(func.splitlines(scenText.impHQDispatch_Confederation_Disbands))
					for unit in civ.iterateUnits() do
						if unit.owner == France then
							for _, typeToBeDestroyed in pairs(germanMinorUnitTypesToBeDestroyed) do
								if unit.type == typeToBeDestroyed then
									print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
									civ.deleteUnit(unit)
								end
							end
						end
					end
					state.minorRhineConfederation = false
				end)
			-- ------ Italian Minors ----
				JUSTONCE("x_Kingdom_Of_Naples_Deactivated", function()
					print("Deactivated Kingdom of Naples")
					civ.ui.text(func.splitlines(scenText.impHQDispatch_Naples_Deserts))
					for unit in civ.iterateUnits() do
						if unit.owner == France then
							for _, typeToBeDestroyed in pairs(naplesMinorUnitTypesToBeDestroyed) do
								if unit.type == typeToBeDestroyed then
									print("Destroyed " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
									civ.deleteUnit(unit)
								end
							end
						end
					end
					state.minorKingdomOfNaples = false
					local naplesSupplyTrainTile = civ.getTile(95,101,1)
					naplesSupplyTrainTile.terrainType = 10
					createUnitsByName("Sicilian Infantry", England, {{97,103,0}, {96,102,0}, {94,102,0}}, {count = 5, homeCity = Bavaria, veteran = true})
					createUnitsByName("Dragoon Guards", England, {{97,103,0}, {96,102,0}, {94,102,0}}, {homeCity = Bavaria, veteran = true})
					createUnitsByName("B. Foot Artillery", England, {{97,103,0}, {96,102,0}, {94,102,0}}, {homeCity = Bavaria, veteran = true})
				end)
			-- --------------------------
			end
		end
	else
		if turn >= 42 then	-- turn 42 is January 1809
			JUSTONCE("x_German_Supply_Trains", function()
				local bavariaSupplyTrainTile = civ.getTile(87,65,1)
				bavariaSupplyTrainTile.terrainType = 10
				print("Set terrain type to 10 at 87,65,1 for Bavaria")
				local rhinelandSupplyTrainTile = civ.getTile(81,55,1)
				rhinelandSupplyTrainTile.terrainType = 10
				print("Set terrain type to 10 at 81,55,1 for Rhineland")
				local westphaliaSupplyTrainTile = civ.getTile(76,44,1)
				westphaliaSupplyTrainTile.terrainType = 10
				print("Set terrain type to 10 at 76,44,1 for Westphalia")
				local wurtemburgSupplyTrainTile = civ.getTile(79,61,1)
				wurtemburgSupplyTrainTile.terrainType = 10
				print("Set terrain type to 10 at 79,61,1 for Würtemberg")
			end)
		end
	end
-- ------ German Minors: Prussian Minors ----
	if state.prussiaIsAtWarWithFrance1 == true then
		if Brunswick.owner ~= France then
			if math.random(200) <= 33 then	-- we want a 16.5% chance or 33 in 200
				createUnitsByName("Brunswick Infantry", Prussia, {{86,48,0}, {94,46,0}}, {randomize = true, homeCity = nil, veteran = false})
			end
		end
		if Dresden.owner ~= France then
			if math.random(200) <= 33 then	-- we want a 16.5% chance or 33 in 200
				createUnitsByName("Saxon Infantry", Prussia, {{94,52,0}, {94,46,0}}, {randomize = true, homeCity = nil, veteran = false})
			end
		end
	end
-- ------ Italian Minors ----
	-- "minor Kingdom Of Italy" is always activated and therefore not defined as a state variable
	if turn == 9 or turn == 33 or turn == 45 then
		createUnitsByName("Italian Infantry", France, {{78,80,1}}, {homeCity = nil, veteran = false})
	end
	if turn == 21 or turn == 45 then
		createUnitsByName("Italian Cavalry", France, {{78,80,1}}, {homeCity = nil, veteran = false})
	end
	if state.minorKingdomOfNaples == true then
		if turn == 21 or turn == 33 or turn == 57 or turn == 69 then
			createUnitsByName("Neapolitan Infantry", France, {{95,103,1}}, {homeCity = KofNaples, veteran = false})
		end
		if turn == 32 then		-- turn 32 is March 1808
			local naplesSupplyTrainTile = civ.getTile(93,101,1)
			naplesSupplyTrainTile.terrainType = 0
			print("Set terrain type to 0 at 93,101,1 for Kingdom of Naples")
		end
	end
	if state.minorKingdomOfSicily == true then
		if math.random(200) <= 33 then	-- we want a 16.5% chance or 33 in 200
			createUnitsByName("Sicilian Infantry", England, {{95,103,0}, {106,104,0}, {99,117,0}, {92,116,0}, {76,110,0}}, {randomize = true, homeCity = nil, veteran = false})
		end
	end
	if state.minorSwitzerland == true then
		if turn == 8 then		-- turn 8 is March 1806
			local switzerlandSupplyTrainTile = civ.getTile(66,72,1)
			switzerlandSupplyTrainTile.terrainType = 0
			print("Set terrain type to 0 at 66,72,1 for Switzerland")
		end
		if turn == 9 or turn == 33 or turn == 57 then
			createUnitsByName("Swiss Infantry", France, {{68,74,1}}, {homeCity = findCityByName("Switzerland"), veteran = false})
		end
	end
-- ------ Western Minors ----
	if state.minorHolland == true then
		if turn == 21 or turn == 33 or turn == 57 then
			createUnitsByName("Dutch Infantry", France, {{64,52,1}}, {homeCity = findCityByName("United Province"), veteran = false})
		end
		if turn == 21 then
			createUnitsByName("Dutch Cavalry", France, {{64,52,1}}, {homeCity = findCityByName("United Province"), veteran = false})
		end
		if turn == 32 then		-- turn 32 is March 1808
			local hollandSupplyTrainTile = civ.getTile(66,50,1)
			hollandSupplyTrainTile.terrainType = 0
			print("Set terrain type to 0 at 66,50,1 for Holland")
		end
	end
	if state.englandIsAtWarWithFrance == true then
		if math.random(200) <= 33 then		-- we want a 16.5% chance or 33 in 200
			createUnitsByName("Portuguese Infantry", England, {{6,98,0}, {12,88,0}, {8,106,0}}, {randomize = true, homeCity = nil, veteran = false})
		end
		if math.random(25) <= 2 then		-- we want an 8% chance or 2 in 25
			createUnitsByName("Portuguese Cavalry", England, {{6,98,0}, {12,88,0}, {8,106,0}}, {randomize = true, homeCity = nil, veteran = false})
		end
	end
-- =========================

-- ==== 10. WINTER ====
	updateSeason(false)
-- ====================

-- ==== 10/11. SEASONAL ATTRITION ====
	for unit in civ.iterateUnits() do
		local season, hpMinPct, hpMaxPct = "Summer", 0, 0
		if unit.owner == France and not(unit.type.name == "Train Militaire") and not(unitIsFrenchLeader(unit)) then
			-- Calculate seasonal effects on French units:
			if unit.type.domain == 0 then
				-- Ground units:
				if monthNumber == 12 or monthNumber <= 4 then
					-- Winter damage:
					season = "Winter"
					if tileWithinRussia(unit.location) then 
						-- Russia:
						if tileOpenTerrain(unit.location) then
							hpMinPct, hpMaxPct = 20, 30				-- Winter damage, Russia, open terrain: 20-30% of HP per turn
						elseif tileCityCenterTerrain(unit.location) then
							season = "Winter (city)"
							hpMinPct, hpMaxPct = 20, 40				-- Winter damage, Russia, city: 20-40% of HP per turn
						end
																	-- Winter damage, Russia, other (temperate) terrain: NONE
					elseif tileWithinIberia(unit.location) then
						-- Iberia:
						if tileOpenTerrain(unit.location) then
							hpMinPct, hpMaxPct = 10, 20				-- Winter damage, Iberia, open terrain: 10-20% of HP per turn
						else
							hpMinPct, hpMaxPct = 0, 10				-- Winter damage, Iberia, other (temperate) terrain: 0-10% of HP per turn
						end
					else
						-- Remainder of Europe:
						if tileOpenTerrain(unit.location) then
							hpMinPct, hpMaxPct = 10, 20				-- Winter damage, remainder of Europe, open terrain: 10-20% of HP per turn
						end
																	-- Winter damage, remainder of Europe, other (temperate) terrain: NONE
					end
				else
					-- Summer damage:
					if tileWithinRussia(unit.location) then 
						-- Russia:
						if tileOpenTerrain(unit.location) then
							hpMinPct, hpMaxPct = 0, 20				-- Summer damage, Russia, open terrain: 0-20% of HP per turn
						end
																	-- Summer damage, Russia, other (temperate) terrain: NONE
					elseif tileWithinIberia(unit.location) and tileOpenTerrain(unit.location) == true then
						-- Iberia:
						hpMinPct, hpMaxPct = 0, 10					-- Summer damage, Iberia, all open terrain: 0-10% of HP per turn
					end
																	-- Summer damage, remainder of Europe, all terrain: NONE
				end
			elseif unit.type.domain == 2 and tileOceanTerrain(unit.location) then
				-- Naval units:
				if monthNumber == 12 or monthNumber <= 4 then
					season = "Winter"
					hpMinPct, hpMaxPct = 10, 20						-- Naval winter damage: 10-20% of HP per turn
				else
					hpMinPct, hpMaxPct = 0, 10						-- Naval summer damage: 0-10% of HP per turn
				end
			end

			-- Apply seasonal effects, if applicable: ----
			if hpMaxPct > 0 then
				-- Note: damage for a month is incurred at the *end* of that month, i.e., at the beginning of the following month.
				local damagePercent = math.random(hpMinPct, hpMaxPct)
				local damageAmount = round(unit.type.hitpoints * (damagePercent / 100))
				local oldHP = unit.hitpoints
				if damageAmount >= oldHP then
					print(season .. " damage: " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. " KILLED due to HP being reduced from " .. oldHP .. " HP to 0 HP!")
					civ.ui.text(func.splitlines("ATTRITION LOSS:\n^\r^A '".. unit.type.name .. "' at (" .. unit.x .. ", " .. unit.y .. ", " .. unit.z .. ") was KILLED due to HP being reduced from " .. oldHP .. " HP to 0 HP!"))
					civ.deleteUnit(unit)
				elseif damageAmount > 0 then
					local newHP = oldHP - damageAmount
					print(season .. " damage: " .. unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z .. " reduced from " .. oldHP .. "HP to " .. newHP .. "HP")
					unit.damage = unit.damage + damageAmount
				end
			end
		end
	end
-- =====================================

-- ==== 12. AUSTRIAN, BRITISH, OTTOMAN, RUSSIAN and SPANISH MOVETO COMMANDS ====
--	-- AUSTRIAN COMMANDS
	if state.austriaIsAtWarWithFrance2 == true or state.austriaIsAtWarWithFrance3 == true then
		for unit in civ.iterateUnits() do
			if unit.owner == Austria then
				-- "Move" commands within Austria
				-- From Wien to Ratisbon:
				if unit.x >= 101 and unit.y >= 65 and unit.x <= 105 and unit.y <= 69 and unit.z == 0 then
					unit.gotoTile = civ.getTile(91, 63, 0)
				end
				-- From Splitz to Agram:
				if unit.x >= 101 and unit.y >= 87 and unit.x <= 107 and unit.y <= 93 and unit.z == 0 then
					unit.gotoTile = civ.getTile(102, 78, 0)
				end
				-- From east of Trieste to Venezia:
				if unit.x >= 95 and unit.y >= 77 and unit.x <= 99 and unit.y <= 81 and unit.z == 0 then
					unit.gotoTile = civ.getTile(89, 81, 0)
				end
				-- From east of Ratisbon to München:
				if unit.x >= 91 and unit.y >= 61 and unit.x <= 95 and unit.y <= 65 and unit.z == 0 then
					unit.gotoTile = civ.getTile(87, 67, 0)
				end
				-- From south of Dresden to Leipzig:
				if unit.x >= 92 and unit.y >= 54 and unit.x <= 96 and unit.y <= 58 and unit.z == 0 then
					unit.gotoTile = civ.getTile(91, 51, 0)
				end
				-- From Krakow to Warszawa:
				if unit.x >= 111 and unit.y >= 55 and unit.x <= 115 and unit.y <= 59 and unit.z == 0 then
					unit.gotoTile = civ.getTile(116, 46, 0)
				end
			end
		end
	end
--	-- BRITISH COMMANDS
	-- GROUND COMMANDS
	if state.englandIsAtWarWithFrance == true and state.frenchInvasionOfPortugal== true then
		for unit in civ.iterateUnits() do
			if unit.owner == England then
				-- "Move" commands within Spain

				-- British Reinforcements movement toward Spanish coastal ports
				-- From e. of A Coruna to A Coruna:
				if unit.x >= 20 and unit.y >= 78 and unit.x <= 22 and unit.y <= 80 and unit.z == 0 then
					unit.gotoTile = civ.getTile(17, 77, 0)
				end
				-- From n. of Oporto to Oporto:
				if unit.x >= 12 and unit.y >= 82 and unit.x <= 14 and unit.y <= 86 and unit.z == 0 then
					unit.gotoTile = civ.getTile(12, 88, 0)
				end
				-- From n. of Lisboa to Lisboa:
				-- if unit.x >= 8 and unit.y >= 92 and unit.x <= 10 and unit.y <= 94 and unit.z == 0 then
				--	unit.gotoTile = civ.getTile(6, 98, 0)
				-- end
				-- From s. of Valencia to Valencia:
				if unit.x >= 37 and unit.y >= 107 and unit.x <= 39 and unit.y <= 109 and unit.z == 0 then
					unit.gotoTile = civ.getTile(40, 104, 0)
				end

				-- Movement towards France
				-- From Oporto to Ciudad Rodrigo:
				if unit.x >= 10 and unit.y >= 86 and unit.x <= 14 and unit.y <= 90 and unit.z == 0 then
					unit.gotoTile = civ.getTile(18, 94, 0)
				end
				-- From Ciudad Rodrigo to Valladolid:
				if unit.x >= 16 and unit.y >= 92 and unit.x <= 20 and unit.y <= 96 and unit.z == 0 then
					unit.gotoTile = civ.getTile(25, 89, 0)
				end
				-- From Valladolid to Burgos:
				if unit.x >= 23 and unit.y >= 87 and unit.x <= 27 and unit.y <= 91 and unit.z == 0 then
					unit.gotoTile = civ.getTile(31, 87, 0)
				end
				-- From Burgos to Bilboa:
				if unit.x >= 30 and unit.y >= 86 and unit.x <= 32 and unit.y <= 88 and unit.z == 0 then
					unit.gotoTile = civ.getTile(35, 83, 0)
				end
				-- From Lisboa to Badajoz:
				if unit.x >= 5 and unit.y >= 95 and unit.x <= 9 and unit.y <= 101 and unit.z == 0 then
					unit.gotoTile = civ.getTile(15, 101, 0)
				end
				-- From Badajoz to Madrid:
				if unit.x >= 14 and unit.y >= 98 and unit.x <= 18 and unit.y <= 102 and unit.z == 0 then
					unit.gotoTile = civ.getTile(28, 96, 0)
				end
				-- From Madrid to border:
				if unit.x >= 26 and unit.y >= 94 and unit.x <= 30 and unit.y <= 100 and unit.z == 0 then
					unit.gotoTile = civ.getTile(36, 90, 0)
				end
				-- From Bruxelles to Paris:
				if unit.x >= 61 and unit.y >= 51 and unit.x <= 65 and unit.y <= 55 and unit.z == 0 then
					unit.gotoTile = civ.getTile(58, 60, 0)
				end
			end
		end
	end
	-- NAVAL COMMANDS
	if state.englandIsAtWarWithFrance == true and state.frenchInvasionOfPortugal== true then
		for unit in civ.iterateUnits() do
			if unit.owner == England and unit.type.domain == 2 then
				-- #1 From Glasgow to sea tile south-east of Cork:
				if unit.x >= 42 and unit.y >= 20 and unit.x <= 46 and unit.y <= 24 and unit.z == 0 then
					unit.gotoTile = civ.getTile(34, 42, 0)
				end
				-- #2 From Liverpool to sea tile south of Cork:
				if unit.x >= 42 and unit.y >= 30 and unit.x <= 46 and unit.y <= 34 and unit.z == 0 then
					unit.gotoTile = civ.getTile(31, 49, 0)
				end
				-- #3 From Belfast to sea tile south of Cork:
				if unit.x >= 39 and unit.y >= 25 and unit.x <= 43 and unit.y <= 29 and unit.z == 0 then
					unit.gotoTile = civ.getTile(31, 49, 0)
				end
				-- #4 From Dublin to sea tile south-east of Plymouth:
				if unit.x >= 36 and unit.y >= 30 and unit.x <= 40 and unit.y <= 34 and unit.z == 0 then
					unit.gotoTile = civ.getTile(43, 51, 0)
				end
				-- #5 From Bristol to sea tile south-west of Brest:
				if unit.x >= 44 and unit.y >= 42 and unit.x <= 46 and unit.y <= 44 and unit.z == 0 then
					unit.gotoTile = civ.getTile(30, 60, 0)
				end
				-- #6 From London to sea tile south of Amsterdam:
				--if unit.x >= 52 and unit.y >= 44 and unit.x <= 54 and unit.y <= 46 and unit.z == 0 then
				--	unit.gotoTile = civ.getTile(68, 46, 0)
				--end
				-- #6 From London to sea tile north of Amsterdam:
				if unit.x >= 52 and unit.y >= 44 and unit.x <= 54 and unit.y <= 46 and unit.z == 0 then
					unit.gotoTile = civ.getTile(67, 35, 0)
				end
				-- #7 From west of Brest to sea tile north of Gijon:
				if unit.x >= 31 and unit.y >= 53 and unit.x <= 35 and unit.y <= 59 and unit.z == 0 then
					unit.gotoTile = civ.getTile(25, 77, 0)
				end
				-- From south-east of Cork to sea tile west of Nantes:
				if unit.x >= 32 and unit.y >= 40 and unit.x <= 36 and unit.y <= 44 and unit.z == 0 then
					unit.gotoTile = civ.getTile(40, 66, 0)
				end
				-- From sea tile south of Cork to sea tile north-west of A Coruna:
				if unit.x >= 29 and unit.y >= 47 and unit.x <= 33 and unit.y <= 51 and unit.z == 0 then
					unit.gotoTile = civ.getTile(16, 72, 0)
				end
				-- From sea tile south-east of Plymouth to sea tile north-west of Amsterdam:
				if unit.x >= 41 and unit.y >= 49 and unit.x <= 45 and unit.y <= 53 and unit.z == 0 then
					unit.gotoTile = civ.getTile(64, 40, 0)
				end
				-- From sea tile south-west of Brest to sea tile west of Bordeaux:
				if unit.x >= 28 and unit.y >= 58 and unit.x <= 32 and unit.y <= 62 and unit.z == 0 then
					unit.gotoTile = civ.getTile(41, 71, 0)
				end
				-- From sea tile west of Bordeaux to sea tile north-west of A Coruna:
				if unit.x >= 39 and unit.y >= 75 and unit.x <= 43 and unit.y <= 79 and unit.z == 0 then
					unit.gotoTile = civ.getTile(16, 72, 0)
				end
				-- From sea tile west of La Rochelle to to sea tile south of Cork:
				if unit.x >= 40 and unit.y >= 70 and unit.x <= 44 and unit.y <= 74 and unit.z == 0 then
					unit.gotoTile = civ.getTile(31, 49, 0)
				end
				-- Movements along Spanish coastline
				-- From sea tile north-west of A Coruna to sea tile north of Lisboa:
				if unit.x >= 12 and unit.y >= 70 and unit.x <= 18 and unit.y <= 76 and unit.z == 0 then
					unit.gotoTile = civ.getTile(5, 95, 0)
				end
				-- From sea tile north of Lisboa to Gibraltar:
				if unit.x >= 3 and unit.y >= 91 and unit.x <= 7 and unit.y <= 101 and unit.z == 0 then
					unit.gotoTile = civ.getTile(17, 115, 0)
				end
				-- From Gibraltar to sea tile south-west of Valencia:
				if unit.x >= 14 and unit.y >= 114 and unit.x <= 20 and unit.y <= 118 and unit.z == 0 then
					unit.gotoTile = civ.getTile(41, 107, 0)
				end
				-- From sea tile south-west of Valencia to sea tile south-east of Perpignan:
				if unit.x >= 39 and unit.y >= 103 and unit.x <= 43 and unit.y <= 111 and unit.z == 0 then
					unit.gotoTile = civ.getTile(57, 91, 0)
				end
				-- From sea tile south-east of Perpignan to sea tile south of Genova:
				if unit.x >= 55 and unit.y >= 89 and unit.x <= 59 and unit.y <= 93 and unit.z == 0 then
					unit.gotoTile = civ.getTile(77, 87, 0)
				end
				-- Egyptian Sea Commands
				-- From sea tile north-west of Al-Iskandariyah to sea tile east of Dumyat:
				if unit.x >= 169 and unit.y >= 135 and unit.x <= 173 and unit.y <= 143 and unit.z == 0 then
					unit.gotoTile = civ.getTile(161, 143, 0)
				end
			end
		end
	end
--	-- OTTOMAN COMMANDS
	if state.ottomanIsAtWarWithFrance == true or state.ottomanIsAtWarWithRussia== true then
		for unit in civ.iterateUnits() do
			if unit.owner == Spain then
				-- "Move" commands within Ottoman Sultanate
				-- From Adana to Ankara:
				if unit.x >= 175 and unit.y >= 107 and unit.x <= 181 and unit.y <= 113 and unit.z == 0 then
					unit.gotoTile = civ.getTile(166, 100, 0)
				end
				-- From Ankara to Istanbul:
				if unit.x >= 164 and unit.y >= 96 and unit.x <= 170 and unit.y <= 104 and unit.z == 0 then
					unit.gotoTile = civ.getTile(149, 97, 0)
				end
				-- From Izmir to Istanbul:
				if unit.x >= 144 and unit.y >= 108 and unit.x <= 148 and unit.y <= 112 and unit.z == 0 then
					unit.gotoTile = civ.getTile(149, 97, 0)
				end
				-- From Istanbul to north of Erdine:
				if unit.x >= 147 and unit.y >= 95 and unit.x <= 153 and unit.y <= 101 and unit.z == 0 then
					unit.gotoTile = civ.getTile(137, 91, 0)
				end
				-- From Al-Iskandariyah region to south-west of Yerushalayim
				if unit.x >= 160 and unit.y >= 142 and unit.x <= 164 and unit.y <= 148 and unit.z == 0 then
					unit.gotoTile = civ.getTile(177, 143, 0)
				end
				-- From Al-Qahirah region to south-west of Yerushalayim
				if unit.x >= 165 and unit.y >= 143 and unit.x <= 169 and unit.y <= 149 and unit.z == 0 then
					unit.gotoTile = civ.getTile(177, 143, 0)
				end
				-- From region to south-west of Yerushalayim to Bayrut
				if unit.x >= 175 and unit.y >= 143 and unit.x <= 179 and unit.y <= 145 and unit.z == 0 then
					unit.gotoTile = civ.getTile(182, 126, 0)
				end
				-- From Bayrut to Adana
				if unit.x >= 181 and unit.y >= 125 and unit.x <= 183 and unit.y <= 133 and unit.z == 0 then
					unit.gotoTile = civ.getTile(117, 111, 0)
				end
			end
		end
	end
--	-- RUSSIAN COMMANDS
	-- GROUND COMMANDS
	if state.russiaIsAtWarWithFrance == true then
		for unit in civ.iterateUnits() do
			if unit.owner == Russia then
				-- "Move" commands within Russia
				-- From eastern border to Tula:
				if unit.x >= 172 and unit.y >= 18 and unit.x <= 178 and unit.y <= 34 and unit.z == 0 then
					unit.gotoTile = civ.getTile(162, 28, 0)
				end
				-- From Niznij Novgorod to Moskva:
				if unit.x >= 173 and unit.y >= 11 and unit.x <= 177 and unit.y <= 15 and unit.z == 0 then
					unit.gotoTile = civ.getTile(159, 21, 0)
				end
				-- From Jaroslavl' to Moskva:
				if unit.x >= 160 and unit.y >= 8 and unit.x <= 164 and unit.y <= 12 and unit.z == 0 then
					unit.gotoTile = civ.getTile(159, 21, 0)
				end
				-- From Tver to Moskva:
				if unit.x >= 152 and unit.y >= 16 and unit.x <= 156 and unit.y <= 20 and unit.z == 0 then
					unit.gotoTile = civ.getTile(159, 21, 0)
				end
				-- From Moskva to Smolensk:
				if unit.x >= 157 and unit.y >= 19 and unit.x <= 161 and unit.y <= 23 and unit.z == 0 then
					unit.gotoTile = civ.getTile(146, 30, 0)
				end
				-- From Vjaz'ma to Smolensk:
				if unit.x >= 151 and unit.y >= 23 and unit.x <= 155 and unit.y <= 25 and unit.z == 0 then
					unit.gotoTile = civ.getTile(146, 30, 0)
				end
				-- From Smolensk to Minsk:
				if unit.x >= 144 and unit.y >= 28 and unit.x <= 148 and unit.y <= 32 and unit.z == 0 then
					unit.gotoTile = civ.getTile(134, 36, 0)
				end
				-- From Minsk to Brest-Litovsky:
				if unit.x >= 132 and unit.y >= 34 and unit.x <= 136 and unit.y <= 38 and unit.z == 0 then
					unit.gotoTile = civ.getTile(124, 46, 0)
				end
				-- From Narva to Riga:
				if unit.x >= 129 and unit.y >= 7 and unit.x <= 133 and unit.y <= 11 and unit.z == 0 then
					unit.gotoTile = civ.getTile(123, 23, 0)
				end
				-- From Pskov to Riga:
				if unit.x >= 131 and unit.y >= 15 and unit.x <= 135 and unit.y <= 19 and unit.z == 0 then
					unit.gotoTile = civ.getTile(123, 23, 0)
				end
				-- From Riga to Kovno:
				if unit.x >= 121 and unit.y >= 21 and unit.x <= 125 and unit.y <= 25 and unit.z == 0 then
					unit.gotoTile = civ.getTile(123, 33, 0)
				end
				-- From Kharkiv to Kyiv:
				if unit.x >= 161 and unit.y >= 47 and unit.x <= 165 and unit.y <= 51 and unit.z == 0 then
					unit.gotoTile = civ.getTile(146, 52, 0)
				end
				-- From Voronez to Orel:
				if unit.x >= 168 and unit.y >= 36 and unit.x <= 172 and unit.y <= 40 and unit.z == 0 then
					unit.gotoTile = civ.getTile(159, 35, 0)
				end
				-- From Orel to Vjaz'ma:
				if unit.x >= 158 and unit.y >= 34 and unit.x <= 160 and unit.y <= 36 and unit.z == 0 then
					unit.gotoTile = civ.getTile(153, 25, 0)
				end
				-- From Velikiye Luki to Vitsyebsk:
				if unit.x >= 138 and unit.y >= 22 and unit.x <= 140 and unit.y <= 24 and unit.z == 0 then
					unit.gotoTile = civ.getTile(141, 29, 0)
				end

				-- "Move" commands outside Russia
				-- From Kovno to Königsberg:
				if unit.x >= 121 and unit.y >= 31 and unit.x <= 125 and unit.y <= 35 and unit.z == 0 then
					unit.gotoTile = civ.getTile(113, 35, 0)
				end
				-- From Grodno to Warszawa:
				if unit.x >= 121 and unit.y >= 37 and unit.x <= 125 and unit.y <= 41 and unit.z == 0 then
					unit.gotoTile = civ.getTile(116, 46, 0)
				end
				-- From Warszawa to Posen:
				if unit.x >= 114 and unit.y >= 44 and unit.x <= 118 and unit.y <= 48 and unit.z == 0 then
					unit.gotoTile = civ.getTile(104, 46, 0)
				end
				-- From Brest-Litovsky to southwest of Lublin:
				if unit.x >= 122 and unit.y >= 44 and unit.x <= 126 and unit.y <= 48 and unit.z == 0 then
					unit.gotoTile = civ.getTile(119, 57, 0)
				end
				-- From southwest of Lublin to south of Krakow:
				if unit.x >= 117 and unit.y >= 55 and unit.x <= 121 and unit.y <= 59 and unit.z == 0 then
					unit.gotoTile = civ.getTile(111, 63, 0)
				end
			end
		end
	end
	-- NAVAL COMMANDS
	if state.russiaIsAtWarWithFrance == true then
		for unit in civ.iterateUnits() do
			if unit.owner == Russia and unit.type.domain == 2 then
				-- From Sankt-Peterburg to sea tile north of Riga:
				if unit.x >= 135 and unit.y >= 5 and unit.x <= 137 and unit.y <= 7 and unit.z == 0 then
					unit.gotoTile = civ.getTile(120, 18, 0)
				end
				-- From Riga to sea tile north-east of Danzig:
				if unit.x >= 122 and unit.y >= 22 and unit.x <= 124 and unit.y <= 24 and unit.z == 0 then
					unit.gotoTile = civ.getTile(110, 32, 0)
				end
			end
		end
	end
--	-- SPANISH COMMANDS
	if state.spainIsAtWarWithFrance == true and state.frenchInvasionOfPortugal== true then
		for unit in civ.iterateUnits() do
			if unit.owner == Spain then
				-- "Move" commands within Spain
				-- From Cadiz to Sevilla:
				if unit.x >= 13 and unit.y >= 111 and unit.x <= 15 and unit.y <= 113 and unit.z == 0 then
					unit.gotoTile = civ.getTile(16, 108, 0)
				end
				-- From Sevilla to Badajoz:
				if unit.x >= 15 and unit.y >= 107 and unit.x <= 17 and unit.y <= 109 and unit.z == 0 then
					unit.gotoTile = civ.getTile(15, 101, 0)
				end
			end
		end
	end
-- =====================================

-- ==== 16. BRITISH COALITION AID ====

	if state.englandIsAtWarWithFrance == true then
		-- Aid to Austria
		if (state.austriaIsAtWarWithFrance1 == true or state.austriaIsAtWarWithFrance2 == true or state.austriaIsAtWarWithFrance3 == true) and turn % 2 == 0 then
			if England.money >= 30 then
				createUnitsByName("A. Uhlans", Austria, {{89,81,0}, {104,90,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -30)
			else
				print("England failed to provide coalition aid to Austria because their treasury only contains " .. England.money .. " gold")
			end
		end
		-- Aid to Prussia
		if state.prussiaIsAtWarWithFrance1 == true and turn % 2 == 0 then
			if England.money >= 20 then
				createUnitsByName("P. Light Infantry", Prussia, {{84,40,0}, {109,37,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -20)
			else
				print("England failed to provide coalition aid to Prussia because their treasury only contains " .. England.money .. " gold")
			end
		end
		if state.prussiaIsAtWarWithFrance1 == true and turn % 3 == 0 then
			if England.money >= 30 then
				createUnitsByName("P. Uhlans", Prussia, {{84,40,0}, {109,37,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -30)
			else
				print("England failed to provide coalition aid to Prussia because their treasury only contains " .. England.money .. " gold")
			end
		end
		if state.prussiaIsAtWarWithFrance2 == true and turn % 2 == 0 then
			if England.money >= 20 then
				createUnitsByName("P. Light Infantry", Prussia, {{113,35,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -20)
			else
				print("England failed to provide coalition aid to Prussia because their treasury only contains " .. England.money .. " gold")
			end
		end
		if state.prussiaIsAtWarWithFrance2 == true and turn % 3 == 0 then
			if England.money >= 30 then
				createUnitsByName("P. Uhlans", Prussia, {{113,35,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -30)
			else
				print("England failed to provide coalition aid to Prussia because their treasury only contains " .. England.money .. " gold")
			end
		end
		-- Aid to Russia
		if state.russiaIsAtWarWithFrance == true and turn % 2 == 0 then
			if England.money >= 20 then
				createUnitsByName("R. Line Infantry", Russia, {{123,23,0}, {131,9,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -20)
			else
				print("England failed to provide coalition aid to Russia because their treasury only contains " .. England.money .. " gold")
			end
		end
		if state.russiaIsAtWarWithFrance == true and turn % 4 == 0 then
			if England.money >= 20 then
				createUnitsByName("R. Light Infantry", Russia, {{123,23,0}, {131,9,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -20)
			else
				print("England failed to provide coalition aid to Russia because their treasury only contains " .. England.money .. " gold")
			end
		end
		if state.russiaIsAtWarWithFrance == true and turn % 4 == 0 then
			if England.money >= 40 then
				createUnitsByName("R. Foot Artillery", Russia, {{123,23,0}, {131,9,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -40)
			else
				print("England failed to provide coalition aid to Russia because their treasury only contains " .. England.money .. " gold")
			end
		end
		if state.russiaIsAtWarWithFrance == true and turn % 4 == 0 then
			if England.money >= 30 then
				createUnitsByName("R. Horse Artillery", Russia, {{123,23,0}, {131,9,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -30)
			else
				print("England failed to provide coalition aid to Russia because their treasury only contains " .. England.money .. " gold")
			end
		end
		-- Aid to Spain
		if state.spainIsAtWarWithFrance == true and turn % 2 == 0 then
			if England.money >= 20 then
				createUnitsByName("S. Light Infantry", Spain, {{17,77,0}, {14,112,0}, {36,112,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -20)
			else
				print("England failed to provide coalition aid to Spain because their treasury only contains " .. England.money .. " gold")
			end
		end
		if state.spainIsAtWarWithFrance == true and turn % 2 == 0 then
			if England.money >= 30 then
				createUnitsByName("S. Line Cavalry", Spain, {{17,77,0}, {14,112,0}, {36,112,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -30)
			else
				print("England failed to provide coalition aid to Spain because their treasury only contains " .. England.money .. " gold")
			end
		end
		if state.spainIsAtWarWithFrance == true and turn % 3 == 0 then
			if England.money >= 40 then
				createUnitsByName("S. Foot Artillery", Spain, {{17,77,0}, {14,112,0}, {36,112,0}}, {randomize = true, homeCity = nil, veteran = true})
				changeMoney(England, -40)
			else
				print("England failed to provide coalition aid to Spain because their treasury only contains " .. England.money .. " gold")
			end
		end
	end

-- ---- British reinforcements arrive if hold Anvers ----
	if turn % 4 == 0 and state.englandIsAtWarWithFrance == true then
		local Anvers = civlua.findCity("Anvers")
		if Anvers.owner == England then
			print("British Anvers Reinforcements Event takes place")
			createUnitsByName("B. Line Infantry", England, {{66,48,0}}, {count = 2, homeCity = nil, veteran = true})
			createUnitsByName("B. Light Infantry", England, {{66,48,0}}, {homeCity = nil, veteran = true})
			createUnitsByName("B. Foot Artillery", England, {{66,48,0}}, {homeCity = nil, veteran = true})
			createUnitsByName("Dragoon Guards", England, {{66,48,0}}, {homeCity = nil, veteran = true})
			civ.ui.text("British reinforcements arrive in the port held city of Anvers!")
		end
	end
-- ===================================

-- ==== 17. CONTINENTAL BLOCKADE ====
	local portsControlledByFrance = 0
	local totalPortsFound = 0
	for city in civ.iterateCities() do
		if city.name == "A Coruna" or city.name == "Cadiz" or city.name == "Cartagena" or city.name == "Danzig" or
		   city.name == "Hamburg" or city.name == "Lisboa" or city.name == "Napoli" or city.name == "Narva" or
		   city.name == "Riga" or city.name == "Splitz" or city.name == "Straslund" or city.name == "Venezia" then
			totalPortsFound = totalPortsFound + 1
			if city.owner == France then
				portsControlledByFrance = portsControlledByFrance + 1
			end
		end
	end
	print("    Ports controlled by France: " .. portsControlledByFrance .. " (out of " .. totalPortsFound .. ")")
	if totalPortsFound ~= 12 then
		print("ERROR: did not find all 12 defined ports by name; one or more have been destroyed or renamed")
	end
	if portsControlledByFrance >= 11 then
		JUSTONCE("x_France_Controls_Eleven_Ports", function ()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your campaigns have successfully placed eleven\n^of the European Continental Ports under your control.\n^\r^As such, you are finally able to enforce your Continental Blockake\n^against the British Isles, which will severely hamper British Trade.\n^\r^Finally, access to these ports installations will provide the French\n^Navy with a small boost in its movement capabilities."))
			grantTech(England, "Continental Blockade")
			grantTech(France, "European Ports")
		end)
	end
	
-- ==================================

-- ==== 19. FRENCH NAVY & TRAIN MILITAIRE ====
	-- FRENCH NAVY
	local frenchNavyUnits, frenchNavyTotalCost = getFrenchNavyInfo()
	print("    Found " .. frenchNavyUnits .. " French naval units, requiring " .. frenchNavyTotalCost .. " francs to support")
	local frenchNavyExpensesPaid = 0
	if France.money >= frenchNavyTotalCost then
		frenchNavyExpensesPaid = frenchNavyTotalCost
		changeMoney(France, frenchNavyTotalCost * -1)
	else
		frenchNavyExpensesPaid = France.money
		changeMoney(France, France.money * -1)
	end
	if frenchNavyUnits > 0 then
		local messageText = displayMonthYear() .. " - French Naval Report:\n^\r^The Intendant General of the Navy advises you that\n^you currently have " .. frenchNavyUnits .. " operational naval unit(s).\n^\r^It costs the National Treasury " .. frenchNavyTotalCost .. " francs per turn to\n^provide the logistical support to maintain this fleet."
		if frenchNavyExpensesPaid < frenchNavyTotalCost then
			messageText = messageText .. "\n^\r^Unfortunately the Treasury did not have sufficient funds\n^to pay this entire amount! We spent the " .. frenchNavyExpensesPaid .. " available\n^francs to provide " .. round((frenchNavyExpensesPaid / frenchNavyTotalCost) * 100) .. "% of the support the navy requires."
		end
		civ.ui.text(func.splitlines(messageText))
	end

	-- TRAIN MILITAIRE
	local totalTrainMilitaire = 0
	local supportedTrainMilitaire = 0
	local disbandedTrainMilitaire = 0
	for unit in civ.iterateUnits() do
		if unit.owner == France then
			if unit.type.name == "Train Militaire" then
				totalTrainMilitaire = totalTrainMilitaire + 1
				if France.money >= costPerTrainMilitaire then
					print("Paid " .. costPerTrainMilitaire .. " francs for Train Militaire at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
					changeMoney(France, costPerTrainMilitaire * -1)
					supportedTrainMilitaire = supportedTrainMilitaire + 1
				else
					if math.random(4) == 1 then
						print("Disbanded unsupported Train Militaire at " .. unit.x .. "," .. unit.y .. "," .. unit.z)
						civ.deleteUnit(unit)
						disbandedTrainMilitaire = disbandedTrainMilitaire + 1
					end
				end
			else
				if unit.damage > 0 then
					local position = unit.location
					local foundTrainMilitaire = false
					for stackMember in position.units do
						if stackMember.id ~= unit.id then
							if stackMember.type.name == "Train Militaire" then
								foundTrainMilitaire = true
							end
						end
					end
					if foundTrainMilitaire then
						local formerHitPoints = unit.hitpoints
						local healAmount = math.random(0, 2)	-- Previous formula: round(unit.type.hitpoints * 0.25)
						if unit.damage > healAmount then
							unit.damage = unit.damage - healAmount
						else
							unit.damage = 0
						end
						print(unit.type.name .. " at " .. unit.x .. "," .. unit.y .. "," .. unit.z ..
							" healed due to Train Militaire; hit points changed from " .. formerHitPoints .. " to " .. unit.hitpoints .. ".")
					end
				end
			end
		end
	end
	
	if totalTrainMilitaire > 0 then
		if disbandedTrainMilitaire == 0 then
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Logistical Report:\n^\r^The Intendant General of the Army advises you that\n^you currently have " .. totalTrainMilitaire .. " Train Militaire unit(s) in the field.\n^\r^It costs the National Treasury " .. costPerTrainMilitaire .. " francs per turn to\n^provide the logistical support to maintain each\n^unit for a current total amount of " .. tostring(totalTrainMilitaire * costPerTrainMilitaire) .. " francs per turn."))
		else
			civ.ui.text(func.splitlines(displayMonthYear() .. " - Logistical Report:\n^\r^The Intendant General of the Army advises you that\n^you previously had " .. totalTrainMilitaire .. " Train Militaire unit(s) in the field.\n^\r^It costs the National Treasury " .. costPerTrainMilitaire .. " francs per turn to\n^provide the logistical support to maintain each\n^unit for a total amount of " .. tostring(totalTrainMilitaire * costPerTrainMilitaire) .. " francs per turn.\n^\r^Unfortunately, there were insufficient funds in the National\n^Treasury to cover this support cost, and it was necessary\n^to disband " .. disbandedTrainMilitaire .. " of these units! There are now " .. tostring(totalTrainMilitaire - disbandedTrainMilitaire) .. " Train\n^Militaire units remaining in the field."))
		end
	end
	
	-- ==============================================================================================================
	-- Check to see if Fire Sale sold special production buildings; if so rebuild it
	local messageText =  displayMonthYear() .. " - Special City Improvement(s) Fire Sale -\n^Emergency Refinancing by the minister of finance, Gaudin:\n^\r^"
	local rebuiltSomething = false
	for city in civ.iterateCities() do
		if city.owner == France then
			-- Rebuild sold Recruitment Center:
			if city.name == "Bordeaux" or city.name == "Le Havre" or city.name == "Lyon" or city.name == "Marseille" or city.name == "Nantes" or city.name == "Paris" or city.name == "Strasbourg" or city.name == "Toulon" or city.name == "Toulouse" then
				local impName, cost = "Recruitment Center", 80
				if civ.hasImprovement(city, findImprovementByName(impName)) == false then
					civ.addImprovement(city, findImprovementByName(impName))
					local message = "Rebuilt " .. impName .. " for " .. cost .. " francs in " .. city.name
					print(message)
					messageText = messageText .. message .. "\n^"
					changeMoney(France, cost * -1)
					rebuiltSomething = true
				end
			end
			-- Rebuild sold Cannon Foundry:
			if city.name == "Lyon" or city.name == "Paris" or city.name == "Toulouse"  then
				local impName, cost = "Cannon Foundry", 160
				if civ.hasImprovement(city, findImprovementByName(impName)) == false then
					civ.addImprovement(city, findImprovementByName(impName))
					local message = "Rebuilt " .. impName .. " for " .. cost .. " francs in " .. city.name
					print(message)
					messageText = messageText .. message .. "\n^"
					changeMoney(France, cost * -1)
					rebuiltSomething = true
				end
			end
			-- Rebuild sold Constabulary
			if city.name == "Metz" or city.name == "Perpignan" or city.name == "Rennes" then
				local impName, cost = "Constabulary", 30
				if civ.hasImprovement(city, findImprovementByName(impName)) == false then
					civ.addImprovement(city, findImprovementByName(impName))
					local message = "Rebuilt " .. impName .. " for " .. cost .. " francs in " .. city.name
					print(message)
					messageText = messageText .. message .. "\n^"
					changeMoney(France, cost * -1)
					rebuiltSomething = true
				end
			end
			-- Rebuild sold Dockyard
			if city.name == "Bordeaux" or city.name == "Toulon" then
				local impName, cost = "Dockyard", 80
				if civ.hasImprovement(city, findImprovementByName(impName)) == false then
					civ.addImprovement(city, findImprovementByName(impName))
					local message = "Rebuilt " .. impName .. " for " .. cost .. " francs in " .. city.name
					print(message)
					messageText = messageText .. message .. "\n^"
					changeMoney(France, cost * -1)
					rebuiltSomething = true
				end
			end
			-- Rebuild sold Stables
			if city.name == "Lyon" or city.name == "Marseille" or city.name == "Paris" then
				local impName, cost = "Stables", 100
				if civ.hasImprovement(city, findImprovementByName(impName)) == false then
					civ.addImprovement(city, findImprovementByName(impName))
					local message = "Rebuilt " .. impName .. " for " .. cost .. " francs in " .. city.name
					print(message)
					messageText = messageText .. message .. "\n^"
					changeMoney(France, cost * -1)
					rebuiltSomething = true
				end
			end
		end
	end
	if rebuiltSomething == true then
		civ.ui.text(func.splitlines(messageText))
	end
	
-- =============================

-- ==== France Researched the Infrastructure advance
	-- Once France researches Infrastructure advance it will be able to research the 'Extra' tech's which grant improvements and extra units
	-- Extra Military Academy advance      
	if civ.hasTech(France, findTechByName("Extra Military Academy")) then --and (city.name == "Marseille" and city.owner == France) then
		JUSTONCE("x_France_Receives_Military_Academy", function()		
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, the minister of War Berthier has recently commissioned\n^a new Military Academy in the city of Marseille.\n^\r^In honor of this new establishment, which will not only allow you\n^to train veteran ground units, the minister was also able to push\n^forward the graduation of two exceptionally gifted classes of young\n^cadet cavalrymen.\n^\r^As such, a new veteran regiment each of Cuirassiers and Lanciers\n^are raised in Marseille."))
			civ.addImprovement(Marseille, findImprovementByName("Military Academy"))
			createUnitsByName("Cuirassiers", France, {{64,88,0}}, {homeCity = Marseille, veteran = true})
			createUnitsByName("Lanciers", France, {{64,88,0}}, {homeCity = Marseille, veteran = true})
		end)
	end

	-- Extra Constabulary advance	
	if civ.hasTech(France, findTechByName("Extra Constabulary")) then --and (city.name == "Reims" and city.owner == France) then
		JUSTONCE("x_France_Receives_Constabulary", function()		
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, the minister of War Berthier has recently commissioned\n^a new Constabulary training facility in the city of Reims, which should\n^allow you to recruit new Gendarmes regiment\n^\r^In honor of this new establishment, the minister was also able to push\n^forward the graduation of two new Gendarmes regiments."))
			civ.addImprovement(Reims, findImprovementByName("Constabulary"))
			createUnitsByName("Gendarmes", France, {{63,59,0}}, {count = 2, homeCity = nil, veteran = false})
		end)
	end

	-- Extra Train Militaire advance	
	if civ.hasTech(France, findTechByName("Extra Train Militaire")) then
		JUSTONCE("x_France_Receives_Train_Militaire", function()		
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, in order to boost the logistical support of your\n^troops in the field, the minister of war Berthier has commissioned\n^a new Train Militaire regiment.\n^\r^The following dialog box will allow you to position it in one of the\n^following 4 cities: Bayonne, Milano, Leipzig or Paris."))
			local dialog = civ.ui.createDialog()
			dialog.title = "POSITION NEW TRAIN MILITAIRE REGIMENT!"
			dialog.width = 500
			dialog:addText("Please select the Train Militaire's starting position:")
			dialog:addOption("The Train Militaire is positioned in Bayonne!", 1)
			dialog:addOption("The Train Militaire is positioned in Milano!", 2)
			dialog:addOption("The Train Militaire is positioned in Leipzig!", 3)
			dialog:addOption("The Train Militaire is positioned in Paris!", 4)
			--dialog:addOption("Do not select option",0)
			local result = dialog:show()
			if result == 1 then
				civ.ui.text("You selected option 1 : the Train Militaire arrives in Bayonne!")
				createUnitsByName("Train Militaire", France, {{40,84,0}}, {homeCity = nil, veteran = false})
			elseif result == 2 then
				civ.ui.text("You selected option 2 :  the Train Militaire arrives in Milano!")
				createUnitsByName("Train Militaire", France, {{78,80,0}}, {homeCity = nil, veteran = false})
			elseif result == 3 then
				civ.ui.text("You selected option 3 :  the Train Militaire arrives in Leipzig!")
				createUnitsByName("Train Militaire", France, {{91,51,0}}, {homeCity = nil, veteran = false})
			else -- result == 4 then 
				civ.ui.text("You selected option 4 :  the Train Militaire arrives in Paris!")
				createUnitsByName("Train Militaire", France, {{58,60,0}}, {homeCity = nil, veteran = false})
			end
			
		end)
	end
	
-- ==== France Researched the New Naval Base advance
	if civ.hasTech(France, findTechByName("New Naval Base")) then
		JUSTONCE("x_France_Receives_Naval_Base", function()		
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your Majesty, the minister of War Berthier has recently commissioned\n^a new Naval Base in the city of Toulon. This new base will allow you\n^to train veteran naval units.\n^\r^In addition, the minister can with your approval re-activate two\n^reserve naval squadrons in Marseille, though to do so will cost\n^350 francs. Note that they won't start fully operational, as the captains\n^of each ship will need to refurbish the vessels and bring their\n^crew complements to full.\n^\r^The next dialog box will allow you to make that one time choice."))
			civ.addImprovement(Toulon, findImprovementByName("Naval Base"))
			if France.money >= 350 then
				local dialog = civ.ui.createDialog()
				dialog.title = "RECRUIT EXTRA NAVAL SQUADRONS!"
				dialog.width = 535
				dialog:addText("Please confirm if you wish to recruit the extra naval squadrons:")
				dialog:addOption("Recruit one Trois-ponts and one Deux-ponts at a cost of 350 francs", 1)
				dialog:addOption("Exit (the treasury does not have the sufficient funds)", 0)
				local result = dialog:show()
				if result == 1 then
					civ.ui.text("You selected to proceed with recruitment of the naval squadrons at a cost of 350 francs.")
					changeMoney(France, -350)
					local createdUnit = createUnitsByName("Trois-ponts", France, {{64,88,0}}, {homeCity = nil, veteran = false})
					createdUnit.damage = 48	-- 80% of the max HP of 60
					local createdUnit = createUnitsByName("Deux-ponts", France, {{64,88,0}}, {homeCity = nil, veteran = false})
					createdUnit.damage = 40	-- 80% of the max HP of 50
				end
			else
				civ.ui.text("Your treasury had less than 350 francs therefore you were unable to recruit the reserve ships!")
			end
		end)
	end

-- =============================

-- ==== 21. DIPLOMATIC MARRIAGE ====
	if civ.hasTech(France, findTechByName("Succession")) then
		JUSTONCE("x_Researched_Succession", function ()
			civ.ui.text("Despite your great love for the Empress Joséphine, your marriage has produced no heir. If you are to secure your succession and future legacy, you must make a fateful if difficult decision and seek a divorce from her...")
			civ.ui.text("This would allow you to propose a diplomatic marriage with Austria, and thereby, hopefully put an end to future wars between your two empires, especially if you were able to subdue either the British or Russian empires...")
			civ.ui.text("It is thought a new marriage might have a transformative effect on your lifestyle, make you more bourgeois and reduce the level of zeal and vigor in your leadership qualities. But isn't it a small price to pay for possible peace on the continent? The choice is yours to make!")
		end)
	end
	if civ.hasTech(France, findTechByName("Divorce Joséphine")) then
		JUSTONCE("x_Researched_Divorce_Josephine", function ()
			civ.ui.text("The first official step was taken in the throne room of the Tuileries. The Emperor spoke first, saying that he had found the courage to end his marriage in the conviction that it would serve the best interests of France, but he had nothing but gratitude for the devotion and tenderness of his beloved wife...")
			civ.ui.text("The Roman Catholic marriage was annulled on the grounds that the civil marriage had been conducted ‘badly and illegally’. Josephine would be treated well, receiving a substantial yearly allowance along with the Chateau of Malmaison outside Paris, where she would reside till her death in 1814. The Emperor is now free to propose a diplomatic marriage with Austria.")
			changeMoney(France, -200)
		end)
	end
	if civ.hasTech(France, findTechByName("Marriage Marie-Louise")) then
		state.napoleonMarriageMarieLouise = true
	end
-- =================================

-- ==== 22. ALLIED ELITE, GUERRILLA, LANDWEHR AND MILITIA UNITS RECRUITMENT ====
	-- Austria
	if state.austriaTreatyOfPressburg == true and turn % 2 == 0 then
		createUnitsByName("A. Landwehr", Austria,
			{{102,78,0}, {112,70,0}, {118,70,0}, {99,73,0}, {119,65,0}, {113,57,0}, {126,58,0}, {105,61,0}, {110,76,0}, {96,58,0}, {119,79,0}, {103,67,0}},
			{randomize = true, homeCity = nil, veteran = false})
	end
	if state.austriaIsAtWarWithFrance3 == true and turn % 3 == 0 then
		local eventLocation = getRandomValidLocation("A. Line Infantry", Austria, {{96,58,0}, {102,78,0}, {103,67,0}, {113,57,0}})
		print("Austrian 6th Coalition Reinforcements Event takes place")
		createUnitsByName("A. Line Infantry", Austria, eventLocation, {count = 3, homeCity = nil, veteran = true})
		createUnitsByName("A. Light Infantry", Austria, eventLocation, {homeCity = nil, veteran = true})
		createUnitsByName("A. Kürassier", Austria, eventLocation, {homeCity = nil, veteran = true})
		createUnitsByName("A. Uhlans", Austria, eventLocation, {homeCity = nil, veteran = true})
		createUnitsByName("A. Horse Artillery", Austria, eventLocation, {homeCity = nil, veteran = true})
		createUnitsByName("A. Foot Artillery", Austria, eventLocation, {homeCity = nil, veteran = true})
	end
	-- England
	if state.englandIsAtWarWithFrance == true and turn == 21 or turn == 33 then
		-- turn 21 is April 1807; turn 33 is April 1808
		createUnitsByName("K.G.L.", England, {{8,106,0}, {6,98,0}, {6,104,0}, {10,90,0}, {13,85,0}, {17,115,0}}, {randomize = true, homeCity = nil, veteran = true})
	end
	-- Ottoman
	if state.ottomanIsAtWarWithFrance == true or state.ottomanIsAtWarWithRussia == true then
		createUnitsByName("O. Provincial", Ottoman, {{177,111,0}, {166,100,0}, {133,115,0}, {137,83,0}, {145,111,0}, {128,92,0}}, {randomize = true, homeCity = nil, veteran = true})
	end
	if state.ottomanIsAtWarWithFrance == true and turn % 2 == 0 then
		createUnitsByName("O. Janissaries", Ottoman, {{117,83,0}, {128,92,0}, {140,96,0}, {149,97,0}, {166,100,0}, {145,111,0}}, {randomize = true, homeCity = nil, veteran = true})
	end
	if state.ottomanIsAtWarWithFrance == true and turn % 3 == 0 then
		createUnitsByName("O. Sipahi", Ottoman, {{117,83,0}, {128,92,0}, {140,96,0}, {149,97,0}, {166,100,0}, {145,111,0}}, {randomize = true, homeCity = nil, veteran = true})
	end
	-- Prussia
	if state.prussiaTreatyOfTilsit == true and turn % 3 == 0 then
		createUnitsByName("P. Landwehr", Prussia, {{94,46,0}, {104,52,0}, {113,35,0}, {97,41,0}}, {randomize = true, homeCity = nil, veteran = false})
	end
	if state.prussiaIsAtWarWithFrance2 == true and turn % 4 == 0 then
		local eventLocation = getRandomValidLocation("P. Line Infantry", Prussia, {{97,41,0}, {94,46,0}, {113,35,0}, {104,52,0}})
		print("Prussian 6th Coalition Reinforcements Event takes place")
		createUnitsByName("P. Line Infantry", Prussia, eventLocation, {count = 3, homeCity = nil, veteran = true})
		createUnitsByName("P. Light Infantry", Prussia, eventLocation, {homeCity = nil, veteran = true})
		createUnitsByName("P. Kürassier", Prussia, eventLocation, {homeCity = nil, veteran = true})
		createUnitsByName("P. Uhlans", Prussia, eventLocation, {homeCity = nil, veteran = true})
		createUnitsByName("P. Horse Artillery", Prussia, eventLocation, {homeCity = nil, veteran = true})
		createUnitsByName("P. Foot Artillery", Prussia, eventLocation, {homeCity = nil, veteran = true})
	end
	-- Russia
	if state.russiaInvasion == true and state.russiaIsSubdued == false and turn % 1 == 0 then
		createUnitsByName("Don Cossack", Russia, {{162,58,0}, {133,17,0}, {156,68,0}, {161,41,0}, {146,52,0}, {159,35,0}, {154,18,0}, {139,23,0}}, {randomize = true, homeCity = nil, veteran = true})
	end
	if state.russiaInvasion == true and state.russiaIsSubdued == false and turn % 1 == 0 then
		createUnitsByName("R. Opolchenye", Russia, {{162,58,0}, {163,49,0}, {146,52,0}, {134,36,0}, {123,23,0}, {146,30,0}, {159,21,0}, {136,6,0}, {170,38,0}}, {count = 3, randomize = true, homeCity = nil, veteran = false})
	end
	if state.russiaInvasion == true and state.russiaIsSubdued == false and turn % 2 == 0 then
		createUnitsByName("R. Cuirassiers", Russia, {{175,13,0}}, {homeCity = nil, veteran = true})
	end
	if state.russiaInvasion == true and state.russiaIsSubdued == false and turn % 2 == 0 then
		createUnitsByName("R. Foot Artillery", Russia, {{124,46,0}, {134,36,0}, {146,30,0}, {159,21,0}, {162,58,0}, {163,49,0}, {175,13,0}, {133,17,0}}, {randomize = true, homeCity = nil, veteran = true})
	end
	if state.russiaInvasion == true and state.russiaIsSubdued == false and turn % 3 == 0 then
		createUnitsByName("R. Horse Artillery", Russia, {{124,46,0}, {134,36,0}, {146,30,0}, {159,21,0}, {162,10,0}, {163,49,0}, {162,58,0}, {175,13,0}, {133,17,0}}, {randomize = true, homeCity = nil, veteran = true})
	end
	if state.capturedSmolensk == true and state.russiaIsSubdued == false and turn % 2 == 0 then
		JUSTONCE("x_Russian_Reaction_Force_Event", function()
			print("Russian Reaction Force Event takes place")
			local eventLocation = getRandomValidLocation("R. Line Infantry", Russia,
				{{157,23,0}, {159,35,0}, {159,21,0}, {139,23,0}})
			createUnitsByName("R. Line Infantry", Russia, eventLocation, {count = 6, homeCity = nil, veteran = true})
			createUnitsByName("R. Light Infantry", Russia, eventLocation, {count = 2, homeCity = nil, veteran = true})
			createUnitsByName("R. Cuirassiers", Russia, eventLocation, {count = 3, homeCity = nil, veteran = true})
			--createUnitsByName("Kutusov", Russia, {{159,21,0}, {161,19,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("R. Foot Artillery", Russia, eventLocation, {count = 2, homeCity = nil, veteran = true})
			createUnitsByName("R. Horse Artillery", Russia, eventLocation, {homeCity = nil, veteran = true})
		end)
	end
	if state.capturedMoskva == true and state.russiaIsSubdued == false and turn % 4 == 0 then
		createUnitsByName("R. Line Infantry", Russia, {{154,18,0}, {175,13,0}}, {count = 2, randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("R. Light Infantry", Russia, {{154,18,0}, {175,13,0}}, {randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("R. Cuirassiers", Russia, {{154,18,0}, {175,13,0}}, {randomize = false, homeCity = nil, veteran = true})
		createUnitsByName("R. Foot Artillery", Russia, {{154,18,0}, {175,13,0}}, {randomize = false, homeCity = nil, veteran = true})
	end
	if state.capturedKyiv == true and state.russiaIsSubdued == false and turn % 4 == 0 then
		createUnitsByName("R. Line Infantry", Russia, {{162,58,0}}, {count = 2, homeCity = nil, veteran = true})
		createUnitsByName("R. Light Infantry", Russia, {{162,58,0}}, {homeCity = nil, veteran = true})
		createUnitsByName("R. Cuirassiers", Russia, {{162,58,0}}, {homeCity = nil, veteran = true})
		createUnitsByName("R. Foot Artillery", Russia, {{162,58,0}}, {homeCity = nil, veteran = true})
	end
	-- Spain
	if state.spainIsSubdued == false and turn % 3 == 0 then
		createUnitsByName("S. Militia", Spain,
			{{17,77,0}, {50,96,0}, {35,83,0}, {14,112,0}, {36,112,0}, {25,79,0}, {28,96,0}, {23,113,0}, {16,108,0}, {40,104,0}, {25,89,0}, {40,92,0}},
			{randomize = true, homeCity = nil, veteran = false})
	end
	if state.spainIsAtWarWithFrance == true and state.spainIsSubdued == false and turn % 2 == 0 then
		createUnitsByName("Guerrilla", Spain,
			{{16,80,0}, {21,87,0}, {30,84,0}, {15,95,0}, {35,107,0}, {21,111,0}, {32,94,0}, {40,100,0}, {31,111,0}, {25,95,0}, {35,95,0}, {25,105,0}, {36,86,0}, {23,81,0}},
			{count = 2, randomize = true, homeCity = nil, veteran = true})
	end
	if state.spainIsAtWarWithFrance == true and state.spainIsSubdued == false and turn % 3 == 0 then
		createUnitsByName("S. Line Infantry", Spain,
			{{17,77,0}, {50,96,0}, {35,83,0}, {14,112,0}, {36,112,0}, {25,79,0}, {28,96,0}, {23,113,0}, {16,108,0}, {40,104,0}, {25,89,0}, {40,92,0}},
			{randomize = true, homeCity = nil, veteran = true})
	end
	if state.spainIsAtWarWithFrance == true and state.spainIsSubdued == false and turn % 3 == 0 then
		createUnitsByName("S. Line Cavalry", Spain, {{40,92,0}}, {homeCity = nil, veteran = true})
	end
-- ==============================================================================

-- ==== 23. RANDOM EVENTS ====
-- ---- British Wallcherin Event ----
	if state.englandIsAtWarWithFrance == true and state.austriaIsAtWarWithFrance2 == true then
		JUSTONCE("x_British_Wallcherin_Event", function()
			print("British Wallcherin Event takes place")
			local eventLocation = getRandomValidLocation("B. Line Infantry", England, {{65,45,0}, {75,41,0}, {82,34,0}, {89,39,0}, {39,57,0}})
			createUnitsByName("B. Line Infantry", England, eventLocation, {count = 6, homeCity = nil, veteran = false})
			createUnitsByName("B. Light Infantry", England, eventLocation, {count = 2, homeCity = nil, veteran = false})
			createUnitsByName("Dragoon Guards", England, eventLocation, {homeCity = nil, veteran = false})
			createUnitsByName("Light Dragoon", England, eventLocation, {homeCity = nil, veteran = false})
			createUnitsByName("B. Foot Artillery", England, eventLocation, {homeCity = nil, veteran = false})
			civ.ui.text("A British expedition has landed on the continent to support Austria in the War of the Fifth Coalition!")
		end)
	end
-- ---- Create Villeneuve and Nelson naval squadron ----
	if math.random(100) <= 33 then	-- we want a 33% chance
		JUSTONCE("x_Villeneuve_Squadron_Event", function()
			print("Villeneuve Squadron Event takes place")
			createUnitsByName("Villeneuve", France, {{1,123,0}, {1,119,0}, {1,115,0}}, {homeCity = nil, veteran = true})
			createUnitsByName("Deux-ponts", France, {{1,123,0}, {1,119,0}, {1,115,0}}, {count = 2, homeCity = nil, veteran = false})
			createUnitsByName("Frégate", France, {{1,123,0}, {1,119,0}, {1,115,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("Nelson", England, {{8,86,0}, {27,117,0}, {3,83,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Two Decker", England, {{8,86,0}, {10,82,0}, {5,79,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Two Decker", England, {{44,108,0}, {17,115,0}, {27,117,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Two Decker", England, {{57,97,0}, {45,103,0}, {44,108,0}}, {randomize = true, homeCity = nil, veteran = true})
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, Admiral Pierre-Charles Villeneuve's naval squadron\n^has returned from its Caribbean excursion south of Gibraltar and is\n^awaiting orders to rejoin the fleet to begin challenging Britain's\n^maritime supremacy!\n^\r^Your task force should sail with caution as British naval forces are\n^reported to be in the area.\n^\r^While these reinforcements are a welcome addition to your fleet, keep\n^in mind that their maintenance cost will be factored against the French\n^treasury starting next month."))

		end)
	end
-- ---- British/Russian Naples Expedition ----
	if state.englandIsAtWarWithFrance == true and math.random(100) <= 25 then	-- we want a 25% chance
		JUSTONCE("x_British_Russian_Naples_Event", function()
			print("British and Russian Naples Event takes place")
			createUnitsByName("B. Line Infantry", England, {{95,103,0}, {106,104,0}}, {count = 2, homeCity = nil, veteran = false})
			createUnitsByName("B. Light Infantry", England, {{95,103,0}, {106,104,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("Dragoon Guards", England, {{95,103,0}, {106,104,0}}, {homeCity = nil, veteran = false})
			createUnitsByName("R. Line Infantry", England, {{106,104,0}, {95,103,0}}, {count = 2, homeCity = nil, veteran = false})
			createUnitsByName("R. Light Infantry", England, {{106,104,0}, {95,103,0}}, {homeCity = nil, veteran = false})
			civ.ui.text("A British/Russian expeditionary force, under English command, has arrived in the Kingdom of Naples! You should make haste before it threatens your possessions in northern Italy.")
		end)
	end
	
-- ---- British have discovered the Royal Marines advance and Barbary Pirates Raid capability message ----	
	if civ.hasTech(England, findTechByName("British Royal Marines")) then	
		JUSTONCE("x_England_Researched_Royal_Marines", function ()
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your agents operating in England have discovered that\n^the British Admiralty are preparing two types of operations to be used\n^against your forces.\n^\r^The first, consists of training Royal Marines regiments for the purpose\n^of launching coastal raids along both the French Atlantic and Mediterraean\n^coasts, in the hopes of capturing ports through which regular troops can\n^invade your territory. As such, you may want to defend your coastal ports\n^accordingly.\n^\r^The second, is to fund the Barbary Pirates out of the city of Algiers to\n^launch periodic coastal raids along the French Mediterranean and Italian\n^coasts. Once begun, your only chance to bring an end to this activity would\n^be to launch a punitive raid against the pirate city and destroy the minor\n^fort installation protecting it."))
		end)
	end	
	
-- ---- British Royal Marines Raids ----
	if state.englandIsAtWarWithFrance == true and civ.hasTech(England, findTechByName("British Royal Marines")) and math.random(100) <= 20 then		-- we want a 20% chance
		print("British Royal Marines Raid Event takes place")
		local randomNumber = math.random(8)
		if randomNumber == 1 then
			createUnitsByName("Royal Marines", England, {{39,61,0}, {65,45,0}, {9,93,0}},							{randomize = true, homeCity = nil, veteran = true})
		elseif randomNumber == 2 then
			createUnitsByName("Royal Marines", England, {{54,54,0}, {43,69,0}, {32,82,0}, {100,106,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
		elseif randomNumber == 3 then
			createUnitsByName("Royal Marines", England, {{56,52,0}, {22,78,0}, {29,113,0}},				{count = 2, randomize = true, homeCity = nil, veteran = true})
		elseif randomNumber == 4 then
			createUnitsByName("Royal Marines", England, {{54,54,0}, {39,61,0}, {96,96,0}},				{count = 2, randomize = true, homeCity = nil, veteran = true})
		elseif randomNumber == 5 then
			createUnitsByName("Royal Marines", England, {{43,69,0}, {32,82,0}, {9,93,0}, {104,106,0}},	{count = 3, randomize = true, homeCity = nil, veteran = true})
		elseif randomNumber == 6 then
			createUnitsByName("Royal Marines", England, {{56,52,0}, {65,45,0}, {29,113,0}},							{randomize = true, homeCity = nil, veteran = true})
		elseif randomNumber == 7 then
			createUnitsByName("Royal Marines", England, {{39,61,0}, {22,78,0}, {9,93,0}},				{count = 2, randomize = true, homeCity = nil, veteran = true})
		elseif randomNumber == 8 then
			createUnitsByName("Royal Marines", England, {{92,100,0}, {98,104,0}, {104,106,0}, {115,109,0}, {115,111,0}}, {count = 4, randomize = true, homeCity = nil, veteran = true})
		end
		civ.ui.text("The English Royal Marines have launched a coastal raid!")
	end
	
-- ---- British 'Coalition Shells' Munitions ----
	if state.englandIsAtWarWithFrance == true and math.random(100) <= 20 then	-- we want a 20% chance
		print("British Naval Munitions Event takes place")
		createUnitsByName("Coalition Shells", England, {{53,45,0}, {48,48,0}, {46,44,0}, {40,48,0}, {46,34,0}}, {randomize = true, homeCity = nil, veteran = false})
		-- civ.ui.text("The Royal Navy receives a new shipment of naval shells in England!")
	end
	if state.englandIsAtWarWithFrance == true and math.random(100) <= 15 then	-- we want a 15% chance
		print("British Naval Munitions Event takes place")
		createUnitsByName("Coalition Shells", England, {{98,30,0}, {17,115,0}, {6,98,0}, {76,110,0}, {94,128,0}, {99,117,0}}, {randomize = true, homeCity = nil, veteran = false})
		-- civ.ui.text("The Royal Navy receives a new shipment of naval shells in one of its garrison cities!")
	end
-- ---- Barbary Pirates Sponsored By England Naval Munitions Mediterranean Raids----
	if state.englandIsAtWarWithFrance == true and civ.hasTech(England, findTechByName("British Royal Marines")) and state.barbaryPiratesPunished == false then 
		if math.random(16) <= 1 then	-- we want a 6% chance
			print("Barbary Pirates Italian Coast Raid Event takes place")
			createUnitsByName("Coalition Shells", Barbarians, {{117,107,0}, {106,102,0}, {93,91,0}, {95,101,0}, {115,105,0}}, {randomize = true, homeCity = nil, veteran = false})
			civ.ui.text(func.splitlines("Barbary Pirates financed by the British Admiralty\n^launch a lighting raid along the Italian coast!"))
		end
		if math.random(12) <= 1 then	-- we want an 8.5% chance
			print("Barbary Pirates French Mediterranean coast Coast Raid Event takes place")
			createUnitsByName("Coalition Shells", Barbarians, {{55,89,0}, {70,86,0}, {78,84,0}, {62,88,0}}, {randomize = true, homeCity = nil, veteran = false})
			civ.ui.text(func.splitlines("Barbary Pirates financed by the British Admiralty\n^launch a lighting raid along the French Mediterranenan\n^coast!"))
		end
	end

-- ---- British Reaction to French Naval Transport advance ----
	if civ.hasTech(France, findTechByName("Naval Transport")) then
		JUSTONCE("x_France_Received_Transport", function ()
			print("British Naval and Fortifications reinforcements in response to Naval Transport event takes place")
			createUnitsByName("Three Decker", England, {{40,48,0}, {48,48,0}, {53,45,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Two Decker", England, {{40,48,0}, {48,48,0}, {46,44,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Minor Fort", England, {{46,44,0}}, {homeCity = nil, veteran = true})
			local fort = createUnitsByName("Major Fort", England, {{53,45,0}}, {homeCity = nil, veteran = true})
			fort.order = 2
			local fort = createUnitsByName("Minor Fort", England, {{40,48,0}}, {homeCity = nil, veteran = true})
			fort.order = 2
			local fort = createUnitsByName("Minor Fort", England, {{48,48,0}}, {homeCity = nil, veteran = true})
			fort.order = 2
			local fort = createUnitsByName("Minor Fort", England, {{46,34,0}}, {homeCity = nil, veteran = true})
			fort.order = 2
			local fort = createUnitsByName("Minor Fort", England, {{49,39,0}}, {homeCity = nil, veteran = false})
			fort.order = 2
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Your majesty, your agents abroad report that the English government\n^is alarmed by recent French naval transport developments and as a\n^consequence has called up some naval reserves, bolstered its\n^defensive works in the British homeland and begun the regular\n^process of drafting new regiments!\n^\r^The Tsar's ambassador in Paris is also following these latest naval\n^developments closely and has advised your foreign minister, Talleyrand,\n^that his government would not look favorably upon a french invasion of\n^England."))
		end)
	end

-- ---- British Reaction to French Invasion of England ----
	if state.englandExperiencesFrenchTransgression == true then
		JUSTONCE("x_France_Invades_England", function ()
			print("British Reinforcements in response to French Invasion event takes place")
			createUnitsByName("B. Line Infantry", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {count = 8, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("B. Light Infantry", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Light Dragoon", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Dragoon Guards", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("B. Foot Artillery", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("B. Horse Artillery", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {count = 2, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Coalition Shells", England, {{53,45,0}, {48,48,0}, {46,44,0}, {40,48,0}, {46,34,0}}, {count = 5, randomize = true, homeCity = nil, veteran = false})
			civ.playSound("MilitaryFANFARE_1.wav")
			civ.ui.text(func.splitlines(scenText.impHQDispatch_France_Invades_England))
		end)
	end
	
-- ---- British Additional Reinforcements once France achieves maritime supremacy ----
	-- if  state.englandIsAtWarWithFrance == true and state.englandExperiencesFrenchTransgression == true then
	if  state.englandIsAtWarWithFrance == true and state.frenchMaritimeSupremacy == true then
		if math.random(7) <= 1 then	-- we want an 14.5% chance
			print("British Reinforcements in response to French Invasion event takes place")
			createUnitsByName("B. Line Infantry", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {count = 3, randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("B. Light Infantry", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Light Dragoon", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("Dragoon Guards", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("B. Foot Artillery", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {randomize = true, homeCity = nil, veteran = true})
			createUnitsByName("B. Horse Artillery", England, {{49,39,0}, {46,44,0}, {46,34,0}, {53,45,0}, {40,48,0}}, {randomize = true, homeCity = nil, veteran = true})
		end
	end

-- ===========================

end)	-- end of civ.scen.onTurn()

civ.scen.onUnitKilled(function (loser, winner)
	print("    onUnitKilled(): " .. loser.owner.adjective .. " " .. loser.type.name .. " killed by " .. winner.owner.adjective .. " " .. winner.type.name)

-- ==== 3. LEADERS (Handling defeat) ====
-- ---- French Leaders ----
	if loser.type.name == "Napoléon I" then
		if state.napoleonTimesKilled == 0 then
			createUnitsByName("Napoléon I", France, {{44,60,1}}, {homeCity = nil, veteran = true})
			civ.ui.text("Napoléon was slightly wounded on the battlefield and has returned to France on the advice of his doctors. Vive l'Empereur!")
			state.napoleonTimesKilled = 1
		else
			civ.playSound("FUNERAL.wav")
			civ.ui.text("Napoléon was killed when an enemy artillery shell expoded next to him! With no real heir to claim his throne, his generals have no other option but to swear allegiance to the Bourbon king Louis XVIII. The Emperor's legacy ends with him.")
			civ.endGame(true)
		end
	end
	--[[ Note: Napoleon (above) could potentially be rewritten to be more similar to Davout, Murat, Lannes, and Soult.
		 Napoleon doesn't really need a count if it never grows higher than 1, a boolean would suffice.]]

	 if loser.type.name == "Davout" then
		if math.random(3) == 1 or state.Davout_Returns == true then		-- "1" is arbitrary, we want a 33.3% chance or 1 in 3
			civ.playSound("FUNERAL.wav")
			civ.ui.text("Maréchal Davout perished on the battlefield for the glory of France and the Emperor!")
			state.diedDavout = true
			state.diedNone = false
		else
			createUnitsByName("Davout", France, {{44,60,1}}, {homeCity = nil, veteran = true})
			civ.ui.text("Maréchal Davout is wounded in battle and returns to France to recuperate!")
		end
	end
	if loser.type.name == "Lannes" then
		if math.random(3) == 3 or state.Lannes_Returns == true then		-- "3" is arbitrary, we want a 33.3% chance or 1 in 3
			civ.playSound("FUNERAL.wav")
			civ.ui.text("Maréchal Lannes, the only general allowed to address the Emperor with the informal \"Tu\", perishes on the battlefield for the glory of France! Napoleon once said of him: \"I found him a pygmy and left him a giant\".")
			state.diedLannes = true
			state.diedNone = false
		else
			createUnitsByName("Lannes", France, {{44,60,1}}, {homeCity = nil, veteran = true})
			civ.ui.text("Maréchal Lannes is wounded in battle and returns to France to recuperate!")
		end
	end
	if loser.type.name == "Murat" then
		if math.random(3) == 2 or state.Murat_Returns == true then		-- "2" is arbitrary, we want a 33.3% chance or 1 in 3
			civ.playSound("FUNERAL.wav")
			civ.ui.text("Maréchal Murat perished on the battlefield for the glory of France and the Emperor!")
			state.diedMurat = true
			state.diedNone = false
		else
			createUnitsByName("Murat", France, {{95,117,1}}, {homeCity = nil, veteran = true})
			civ.ui.text("Maréchal Murat is wounded in battle and returns to Napoli to recuperate!")
		end
	end
	if loser.type.name == "Soult" then
		if math.random(3) == 1 or state.Soult_Returns == true then		-- "1" is arbitrary, we want a 33.3% chance or 1 in 3
			civ.playSound("FUNERAL.wav")
			civ.ui.text("Maréchal Soult perished on the battlefield for the glory of France and the Emperor!")
			state.diedSoult = true
			state.diedNone = false
		else
			createUnitsByName("Soult", France, {{44,60,1}}, {homeCity = nil, veteran = true})
			civ.ui.text("Maréchal Soult is wounded in battle and returns to France to recuperate!")
		end
	end
	if loser.type.name == "Poniatowski" then
		if math.random(3) == 1 or state.Soult_Returns == true then		-- "1" is arbitrary, we want a 33.3% chance or 1 in 3
			civ.playSound("FUNERAL.wav")
			civ.ui.text("General Poniatowski perished on the battlefield for the glory of Poland!")
			state.diedPoniatowski = true
			state.diedNone = false
		else
			createUnitsByName("Soult", France, {{116,60,1}}, {homeCity = nil, veteran = true})
			civ.ui.text("General Poniatowski is wounded in battle and returns to Poland to recuperate!")
		end
	end
	if loser.type.name == "Villeneuve" then
		if math.random(2) == 1 or state.Villeneuve_Returns == true then		-- "1" is arbitrary, we want a 50.0% chance or 1 in 2
			civ.playSound("FUNERAL.wav")
			civ.ui.text("Admiral Villeneuve perished at sea for the glory of France and the Emperor!")
			state.diedVilleneuve = true
			state.diedNone = false
		else
			local createdUnit = createUnitsByName("Villeneuve", France, {{64,88,0}}, {homeCity = nil, veteran = true})
			createdUnit.damage = 50	-- 83% of the max HP of 60
			civ.ui.text("Admiral Villeneuve's flagship the Bucentaure is severely damaged in battle and as such he is compelled to limp back into port to have his vessel repaired!")
		end
	end
-- ---- Coalition Leaders: Austrian ----
	if loser.type.name == "Charles" and (state.austriaIsAtWarWithFrance1 == true or state.austriaIsAtWarWithFrance2 == true) then
		civ.ui.text("The Archduke Charles of Austria forces' are decimated when caught between two French Corps and he has no other option but to beat a hasty retreat with the remnants of his staff and troops. God willing, he shall return to fight another day!")
	elseif loser.type.name == "Charles" and state.austriaIsAtWarWithFrance3 == true then
		if math.random(20) <= 5 or state.Charles_Return_On == true then		-- we want a 25% chance, or 5 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("The Archduke Charles of Austria, the brother of Emperor Francis I, dies when leading a desperate counter-attack to dislodge the French from a strategic position. Napoléon permits the Austrians to recover the body to be returned for a state funeral!")
			state.diedCharles = true
			state.diedNone = false
		else
			state.Charles_Return_On = civ.getTurn() + math.random(6, 12)
			print("Return of Charles scheduled for turn " .. state.Charles_Return_On)
			civ.ui.text("The Archduke Charles of Austria main body is shattered by a French counterattack and as a result he must flee the battle in haste lest he fall in enemy hands. God willing, he shall return to fight another day!")
		end
	end
	if loser.type.name == "Schwarzenberg" and state.austriaIsAtWarWithFrance3 == true then
		if math.random(20) <= 5 or state.Schwarzenberg_Return_On == true then		-- we want a 25% chance, or 5 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("Generalfeldmarschall Schwarzenberg is killed when his horse is shot from under him and falls on the general. His staff grieves his loss!")
			state.diedSchwarzenberg = true
			state.diedNone = false
		else
			state.Schwarzenberg_Return_On = civ.getTurn() + math.random(6, 12)
			print("Return of Schwarzenberg scheduled for turn " .. state.Schwarzenberg_Return_On)
			civ.ui.text("Generalfeldmarschall Karl Philipp's, Prince of Schwarzenberg, division is defeated by a superior French force but he's able to lead a cavalry force which cuts its way through hostile lines. The general will live to fight another day!")
		end
	end
-- ---- Coalition Leaders: English ----
	if loser.type.name == "Nelson" then
		civ.playSound("FUNERAL.wav")
		civ.ui.text("After many years of faithful service, Admiral Nelson, hero of the battle of Battle of the Nile, perishes on the high seas in the defense of his nation!")
		state.diedNelson = true
		state.diedNone = false
	end
	if loser.type.name == "Moore" then
		if math.random(20) <= 6 or state.Moore_Return_On == true then		-- we want a 30% chance, or 6 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("General Moore died in combat in the service of his country!")
			state.diedMoore = true
			state.diedNone = false
		else
			state.Moore_Return_On = civ.getTurn() + math.random(6, 12)
			print("Return of Moore scheduled for turn " .. state.Moore_Return_On)
			civ.ui.text("General Moore is wounded by fragments of a shell that exploded nearby but the doctors are able to treat him quickly. He shall return to fight another day!")
		end
	end
	if loser.type.name == "Uxbridge" then
		if math.random(20) <= 5 or state.Uxbridge_Return_On == true then		-- we want a 25% chance, or 5 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("General Uxbridge is slain on the battlefield in honor of King and country!")
			state.diedUxbridge = true
			state.diedNone = false
		else
			state.Uxbridge_Return_On = civ.getTurn() + math.random(6, 9)
			print("Return of Uxbridge scheduled for turn " .. state.Uxbridge_Return_On)
			civ.ui.text("General Uxbridge is wounded in battle and is quickly carried off the battlefield by his staff. Doctors expect he will recover fully to fight another day!")
		end
	end
	if loser.type.name == "Wellington" then
		if math.random(20) <= 4 or state.Wellington_Return_On == true then		-- we want a 20% chance, or 4 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("General Wellington who was in an exposed position while giving orders to his subordinates is struck by the bullet of an enemy sharpshooter and dies instantly! The British nation mourns the loss of a great leader!")
			state.diedWellington = true
			state.diedNone = false
		else
			state.Wellington_Return_On = civ.getTurn() + math.random(9, 12)
			print("Return of Wellington scheduled for turn " .. state.Wellington_Return_On)
			civ.ui.text("General Wellington suffers a minor wound and his doctor, fearful for infections sends him to the back to recover. The General is expected to make a full recovery and return to his duties!")
		end
	end
-- ---- Coalition Leaders: Prussian ----
	if loser.type.name == "Blücher" and state.prussiaIsAtWarWithFrance1 == true then
		civ.ui.text("Generalfeldmarschall Gebhard Leberecht von Blücher, a fierce Prussian patriot, is compelled to abandon his position when his forces are shattered by a French attack. The general must flee the battlefield to fight another day!")
	elseif loser.type.name == "Blücher" and state.prussiaIsAtWarWithFrance2 == true then
		if math.random(20) <= 5 or state.Blucher_Return_On == true then		-- we want a 25% chance, or 5 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("Generalfeldmarschall Blücher and half is staff are killed when an enemy shell explodes next to them. Despite his advanced age, his energy and zeal in fighting the French will be difficult to replace!")
			state.diedBlucher = true
			state.diedNone = false
		else
			state.Blucher_Return_On = civ.getTurn() + math.random(6, 12)
			print("Return of Blücher scheduled for turn " .. state.Blucher_Return_On)
			civ.ui.text("Generalfeldmarschall von Blücher must order a hasty retreat when his forces are devastated by a French frontal attack. The general must flee the battlefield to fight another day!")
		end
	end
	if loser.type.name == "Yorck" and state.prussiaIsAtWarWithFrance2 == true then
		if math.random(20) <= 5 or state.Yorck_Return_On == true then		-- we want a 25% chance, or 5 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("Generalfeldmarschall Yorck, a die-hard opponent to French rule, dies instantly when shot through the heart by a stray bullet. His staff are devastated by the loss!")
			state.diedYorck = true
			state.diedNone = false
		else
			state.Yorck_Return_On = civ.getTurn() + math.random(6, 12)
			print("Return of Yorck scheduled for turn " .. state.Yorck_Return_On)
			civ.ui.text("Generalfeldmarschall Ludwig Yorck von Wartenburg's Armee Korps is severely beaten by the French. The general manages to escape but it will be sometime before his command can be rebuilt!")
		end
	end
-- ---- Coalition Leaders: Russian ----
	if loser.type.name == "Barclay de Tolly" then
		if math.random(20) <= 4 or state.BarclayDeTolly_Return_On == true then		-- we want a 20% chance, or 4 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("General Barclay is fatally run down by an enemy lancer while attempting to reach his command post!")
			state.diedBarclaydeTolly = true
			state.diedNone = false
		else
			state.BarclayDeTolly_Return_On = civ.getTurn() + math.random(6, 12)
			print("Return of Barclay de Tolly scheduled for turn " .. state.BarclayDeTolly_Return_On)
			civ.ui.text("Field Marshall Michael Barclay de Tolly's contingent of troops is defeated in battle. He manages to escape capture and returns to Russia for consultations with his superiors!")
		end
	end
	if loser.type.name == "Bagration" then
		if math.random(20) <= 4 or state.Bagration_Return_On == true then		-- we want a 20% chance, or 4 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("General Bagration dies when is horse falls on him after being shot by an enemy sniper. His staff is only able to recover his body after the battle!")
			state.diedBagration = true
			state.diedNone = false
		else
			state.Bagration_Return_On = civ.getTurn() + math.random(6, 12)
			print("Return of Bagration scheduled for turn " .. state.Bagration_Return_On)
			civ.ui.text("General Pyotr Bagration's troops are defeated in battle and the Prince is recalled to Russia to review his command!")
		end
	end
	if loser.type.name == "Kutusov" then
		if math.random(20) <= 5 or state.Kutusov_Return_On == true then		-- we want a 25% chance, or 5 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("General Kutusov, who was in his early sixties, succombs to a heart attack in the middle of the battle. His loss will be deeply felt amongst the Tsar's inner court!")
			state.diedKutusov = true
			state.diedNone = false
		else
			state.Kutusov_Return_On = civ.getTurn() + math.random(9, 12)
			print("Return of Kutusov scheduled for turn " .. state.Kutusov_Return_On)
			civ.ui.text("Prince Mikhail Kutusov has faithfully served three Russian Tsar's in his long and illustrious career but today was not his best performance. Though defeated by superior enemy forces he vows to return to avenge mother Russia!")
		end
	end
-- ---- Coalition Leaders: Spanish ----
	if loser.type.name == "Blake" then
		if math.random(20) <= 5 or state.Blake_Return_On == true then		-- we want a 25% chance, or 5 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("General Blake is caught in the cross fire of an artillery barrage and dies with half his staff!")
			state.diedBlake = true
			state.diedNone = false
		else
			state.Blake_Return_On = civ.getTurn() + math.random(6, 9)
			print("Return of Blake scheduled for turn " .. state.Blake_Return_On)
			civ.ui.text("General Joaquín Blake's spanish troops are defeated by a French column and the general and his staff are forced to flee the battlefield to fight another day!")
		end
	end
	if loser.type.name == "Cuesta" then
		if math.random(20) <= 5 or state.Cuesta_Return_On == true then		-- we want a 25% chance, or 5 in 20
			civ.playSound("FUNERAL.wav")
			civ.ui.text("General Cuesta is caught by an enemy patrol while trying to rejoin his command. He his fataly shot while trying to flee the enemy!")
			state.diedCuesta = true
			state.diedNone = false
		else
			state.Cuesta_Return_On = civ.getTurn() + math.random(6, 9)
			print("Return of Cuesta scheduled for turn " .. state.Cuesta_Return_On)
			civ.ui.text("General Gregorio García de la Cuesta is surprised by an advance force of French troops and forced to retreat in haste. The general vows to return and avenge his honor!")
		end
	end
-- ======================================

-- ==== 6. MINOR POWERS ====
-- ------ Baltic States ----
	if loser.type.name == "Polish Infantry" and state.minorDuchyOfWarsaw == true then
		createUnitsByName("Polish Infantry", France, {{116,66,1}}, {homeCity = nil, veteran = false})
	end
	if loser.type.name == "Polish Lancers" and state.minorDuchyOfWarsaw == true then
		createUnitsByName("Polish Lancers", France, {{116,72,1}}, {homeCity = nil, veteran = false})
	end
-- ------ German Minors ----
	if loser.type.name == "Bavarian Infantry" and state.minorRhineConfederation == true then
		createUnitsByName("Bavarian Infantry", France, {{87,87,1}}, {homeCity = Bavaria, veteran = false})
	end
	if loser.type.name == "Bavarian Cavalry" and state.minorRhineConfederation == true then
		createUnitsByName("Bavarian Cavalry", France, {{87,93,1}}, {homeCity = Bavaria, veteran = false})
	end
	if loser.type.name == "Rhine Infantry" and state.minorRhineConfederation == true then
		createUnitsByName("Rhine Infantry", France, {{101,57,1}}, {homeCity = Rhineland, veteran = false})
	end
	if loser.type.name == "Westphalian Infantry" and state.minorRhineConfederation == true then
		createUnitsByName("Westphalian Infantry", France, {{56,46,1}}, {homeCity = Westphalia, veteran = false})
	end
	if loser.type.name == "Westphalian Cavalry" and state.minorRhineConfederation == true then
		createUnitsByName("Westphalian Cavalry", France, {{56,40,1}}, {homeCity = Westphalia, veteran = false})
	end
	if loser.type.name == "Würtemberg Infantry" and state.minorRhineConfederation == true then
		createUnitsByName("Würtemberg Infantry", France, {{59,63,1}}, {homeCity = Wurtemburg, veteran = false})
	end
-- ------ Italian Minors ----
	-- "minorKingdomOfItaly" is always activated
	if loser.type.name == "Italian Infantry" then
		createUnitsByName("Italian Infantry", France, {{78,100,1}}, {homeCity = nil, veteran = false})
	end
	if loser.type.name == "Italian Cavalry" then
		createUnitsByName("Italian Cavalry", France, {{78,106,1}}, {homeCity = nil, veteran = false})
	end
	if loser.type.name == "Neapolitan Infantry" and state.minorKingdomOfNaples == true then
		createUnitsByName("Neapolitan Infantry", France, {{95,123,1}}, {homeCity = KofNaples, veteran = false})
	end
	if loser.type.name == "Swiss Infantry" and state.minorSwitzerland == true then
		createUnitsByName("Swiss Infantry", France, {{68,94,1}}, {homeCity = findCityByName("Switzerland"), veteran = false})
	end
-- ------ Western Minors ----
	if loser.type.name == "Dutch Infantry" and state.minorHolland == true then
		createUnitsByName("Dutch Infantry", France, {{44,52,1}}, {homeCity = findCityByName("United Province"), veteran = false})
	end
	if loser.type.name == "Dutch Cavalry" and state.minorHolland == true then
		createUnitsByName("Dutch Cavalry", France, {{38,52,1}}, {homeCity = findCityByName("United Province"), veteran = false})
	end
	if loser.type.name == "Danish Infantry" and winner.owner == England then
		JUSTONCE("x_Denmark_Activated", function ()
			activateDenmark("Danish Infantry killed by English unit")
		end)
	end
	if loser.type.name == "Danish Infantry" and state.minorDenmark == true then
		createUnitsByName("Danish Infantry", France, {{110,30,1}}, {homeCity = Denmark, veteran = false})
	end
	if loser.type.name == "Danish Cavalry" and state.minorDenmark == true then
		createUnitsByName("Danish Cavalry", France, {{116,30,1}}, {homeCity = Denmark, veteran = false})
	end
-- =========================

-- ==== 8. SPECIAL FRENCH UNITS RECRUITMENT ====
	if loser.type.name == "Garde Impériale" then
		createUnitsByName("Garde Impériale", France, {{38,60,1}}, {homeCity = nil, veteran = true})
		civ.ui.text(func.splitlines("Your Majesty, a regiment of your elite Garde Impériale have fallen on the battlefield.\n^\r^You have directed your Surintendant de l'Armée to raise\n^a new imperial regiment at the first opportunity."))
	end

	if (loser.type.name == "S. Line Infantry" or
	   loser.type.name == "B. Line Infantry" or
	   loser.type.name == "R. Line Infantry" or
	   loser.type.name == "A. Line Infantry" or
	   loser.type.name == "P. Line Infantry") and winner.owner == France then
		state.coalitionLineInfantryUnitsKilled = state.coalitionLineInfantryUnitsKilled + 1
		if state.coalitionLineInfantryUnitsKilled % 15 == 0 then
			createUnitsByName("Carabiniers", France, {{58,60,0}}, {homeCity = nil, veteran = true})
			civ.ui.text(func.splitlines("****************** Carabiniers Division Recruited ******************\n^\r^Emperor Napoléon, as some of your troops have distinguished\n^themselves on the battlefield you have decided to promote them.\n^\r^As such, you have directed your Surintendant de l'Armée to create\n^a new elite regiment of Carabiniers composed of these men."))
		end
	end
	if loser.type.name == "Grenadier à Cheval" then
		createUnitsByName("Grenadier à Cheval", France, {{32,60,1}}, {homeCity = nil, veteran = true})
		civ.ui.text(func.splitlines("Your Majesty, a regiment of your elite Grenadier à Cheval have fallen on the battlefield.\n^\r^You have directed your Surintendant de l'Armée to raise a new\n^imperial regiment at the first opportunity."))
	end
	if loser.type.name == "Hussars" then
		createUnitsByName("Hussars", France, {{44,60,1}}, {homeCity = nil, veteran = true})
		civ.ui.text(func.splitlines("Your Majesty, a regiment of your elite Hussars have fallen on the battlefield.\n^\r^You have directed your Surintendant de l'Armée to raise a new\n^regiment at the first opportunity."))
	end
-- =============================================

-- ==== 14. L'ELAN NAPOLEONIEN ====
	if 	loser.type.name == "Gendarmes" or
		loser.type.name == "Garde Impériale" or 
		loser.type.name == "Régiment de Ligne" or 
		loser.type.name == "Infanterie Légère" or 
		loser.type.name == "Carabiniers" or 
		loser.type.name == "Cuirassiers" or 
		loser.type.name == "Lanciers" or 
		loser.type.name == "Grenadier à Cheval" or 
		loser.type.name == "Art. à pied 8lb" or 
		loser.type.name == "Art. à Cheval" or
		loser.type.name == "Mortier de 12po." or
		loser.type.name == "Art. à pied 12lb" or 
		loser.type.name == "Hussars" or
		loser.type.name == "Bombarde" or
		loser.type.name == "Frégate" or
		loser.type.name == "Deux-ponts" or
		loser.type.name == "Trois-ponts" or
		loser.type.name == "Transport" then
		state.frenchUnitKilled = state.frenchUnitKilled + 1
		if state.frenchUnitKilled == 44 then
			JUSTONCE("x_French_Fatigue", function()
				civ.ui.text(func.splitlines(scenText.impHQDispatch_LElan_Wonder_Nullified))
				grantTech(France, "French Fatigue")
			end)
		elseif state.frenchUnitKilled == 100 then
			civ.ui.text(func.splitlines(scenText.impHQDispatch_Ignore_ZOC_Nullified))
			state.frenchForcedMarchAbility = false
		end
	end
-- ================================

-- ==== 15. MARITIME SUPREMACY ====
	if loser.owner == England and loser.type.domain == 2 and winner.owner == France then
		-- To prevent exploits, there are restrictions in place that limit which British ship losses are counted for this event:
		if winner.type.name == "18 pdr Shells" or winner.type.name == "24 pdr Shells" or winner.type.name == "32 pdr Shells" or winner.type.name == "Bombard Shells" or
		   (winner.type.domain == 2 and winner.location.city == nil) then
			state.englishNavalUnitsKilled = state.englishNavalUnitsKilled + 1
			print("Incremented state.englishNavalUnitsKilled to " .. state.englishNavalUnitsKilled)
			if state.englishNavalUnitsKilled == 20 and state.frenchNavalUnitsKilled < 10 and civ.getTurn() < 30 then	-- turn 30 is January 1808
				state.frenchMaritimeSupremacy = true
				grantTech(France, "Naval Transport")
				civ.playSound("RuleBritannia.wav")
				civ.ui.text("Imperial Dispatch - " .. displayMonthYear() .. ": Your Majesty, France has achieved maritime supremacy over the Royal Navy and receives the \"Naval Transport\" advance!")
			end
		else
			print("English ship destroyed in battle with France, but not applicable for maritime supremacy; did not increment state.englishNavalUnitsKilled")
		end
	end
	if loser.owner == France and loser.type.domain == 2 then
		state.frenchNavalUnitsKilled = state.frenchNavalUnitsKilled + 1
		print("Incremented state.frenchNavalUnitsKilled to " .. state.frenchNavalUnitsKilled)
	end
-- ================================

-- ==== 18. CAPTURING ENEMY UNITS ====
-- ---- Capturing French Vessels
	if loser.type.name == "Frégate" and winner.owner == England then
		local randomNumber = math.random(4)
		print(loser.type.name .. " defeated in battle, random number is " .. randomNumber .. " (vs. 1)")
		if randomNumber == 1 then
			-- "1" is arbitrary, we want a 25% chance or 1 in 4
			local createdUnit = createUnitsByName("Frigate", England, {{winner.x, winner.y, winner.z}}, {homeCity = nil, veteran = false})
			createdUnit.damage = 20	-- 40% of the max HP of 50
			civ.playSound("RuleBritannia.wav")
			civ.ui.text("Your Majesty, this is a shameful day as your admirals report that a squadron of French Frégate vessels was defeated on the high seas and captured by the British!")
		end
	end
	if loser.type.name == "Deux-ponts" and winner.owner == England then
		local randomNumber = math.random(4)
		print(loser.type.name .. " defeated in battle, random number is " .. randomNumber .. " (vs. 2)")
		if randomNumber == 2 then
			-- "2" is arbitrary, we want a 25% chance or 1 in 4
			local createdUnit = createUnitsByName("Two Decker", England, {{winner.x, winner.y, winner.z}}, {homeCity = nil, veteran = false})
			createdUnit.damage = 25	-- 50% of the max HP of 50
			civ.playSound("RuleBritannia.wav")
			civ.ui.text("Your Majesty, this is a shameful day as your admirals report that a squadron of French Deux-ponts vessels was defeated on the high seas and captured by the British!")
		end
	end
	if loser.type.name == "Trois-ponts" and winner.owner == England then
		local randomNumber = math.random(4)
		print(loser.type.name .. " defeated in battle, random number is " .. randomNumber .. " (vs. 3)")
		if randomNumber == 3 then
			-- "3" is arbitrary, we want a 25% chance or 1 in 4
			local createdUnit = createUnitsByName("Three Decker", England, {{winner.x, winner.y, winner.z}}, {homeCity = nil, veteran = false})
			createdUnit.damage = 30	-- 50% of the max HP of 60
			civ.playSound("RuleBritannia.wav")
			civ.ui.text("Your Majesty, this is a shameful day as your admirals report that a squadron of French Trois-ponts vessels was defeated on the high seas and captured by the British!")
		end
	end

-- -- Capturing French Artillery
	if loser.type.name == "Art. à Cheval" and (winner.owner == Austria or winner.owner == England or winner.owner == Prussia or winner.owner == Russia or winner.owner == Spain) then
		local randomNumber = math.random(2)
		print(loser.type.name .. " defeated in battle, random number is " .. randomNumber .. " (vs. 1)")
		if randomNumber == 1 then
			-- "1" is arbitrary, we want a 50% chance or 1 in 2
			local unitNameToCreate = {
				[1] = "R. Horse Artillery",	-- Russia
				[2] = "A. Horse Artillery",	-- Austria
				[3] = "P. Horse Artillery",	-- Prussia
				[4] = "S. Foot Artillery",	-- Spain
				[7] = "B. Horse Artillery"	-- England
			}
			createUnitsByName(unitNameToCreate[winner.owner.id], winner.owner, {{winner.x, winner.y, winner.z}}, {homeCity = nil, veteran = false})
			civ.ui.text("Your Majesty, a French battery of 6 pdr artillery was captured by " .. winner.owner.name .. "!")
		end
	end
	if loser.type.name == "Art. à pied 8lb" and (winner.owner == Austria or winner.owner == England or winner.owner == Prussia or winner.owner == Russia or winner.owner == Spain) then
		local randomNumber = math.random(2)
		print(loser.type.name .. " defeated in battle, random number is " .. randomNumber .. " (vs. 1)")
		if randomNumber == 1 then
			-- "1" is arbitrary, we want a 50% chance or 1 in 2
			local unitNameToCreate = {
				[1] = "R. Foot Artillery",	-- Russia
				[2] = "A. Foot Artillery",	-- Austria
				[3] = "P. Foot Artillery",	-- Prussia
				[4] = "S. Foot Artillery",	-- Spain
				[7] = "B. Foot Artillery"	-- England
			}
			createUnitsByName(unitNameToCreate[winner.owner.id], winner.owner, {{winner.x, winner.y, winner.z}}, {homeCity = nil, veteran = false})
			civ.ui.text("Your Majesty, a French battery of 8 pdr artillery was captured by " .. winner.owner.name .. "!")
		end
	end
	if loser.type.name == "Art. à pied 12lb" and (winner.owner == Austria or winner.owner == England or winner.owner == Prussia or winner.owner == Russia or winner.owner == Spain) then
		local randomNumber = math.random(2)
		print(loser.type.name .. " defeated in battle, random number is " .. randomNumber .. " (vs. 1)")
		if randomNumber == 1 then
			-- "1" is arbitrary, we want a 50% chance or 1 in 2
			local unitNameToCreate = {
				[1] = "R. Foot Artillery",	-- Russia
				[2] = "A. Foot Artillery",	-- Austria
				[3] = "P. Foot Artillery",	-- Prussia
				[4] = "S. Foot Artillery",	-- Spain
				[7] = "B. Foot Artillery"	-- England
			}
			createUnitsByName(unitNameToCreate[winner.owner.id], winner.owner, {{winner.x, winner.y, winner.z}}, {homeCity = nil, veteran = true})
			civ.ui.text("Your Majesty, a French battery of 12 pdr artillery was captured by " .. winner.owner.name .. "!")
		end
	end
-- ===================================

-- ==== 22. ALLIED ELITE, GUERRILLA, LANDWEHR AND MILITIA UNITS RECRUITMENT ====
	if loser.type.name == "K.G.L." and state.englandIsAtWarWithFrance == true then
		state.KGL_Return_On = civ.getTurn() + math.random(3, 9)
		print("Return of K.G.L. scheduled for turn " .. state.KGL_Return_On)
	end
	-- if loser.type.name == "Life Guards" and state.russiaIsSubdued == false then
		-- state.LifeGuards_Return_On = civ.getTurn() + math.random(3, 9)
		-- print("Return of Life Guards scheduled for turn " .. state.LifeGuards_Return_On)
	-- end

-- ==============================================================================

-- ==== CREATE IRISH REBELS
	if (loser.type.name == "K.G.L." or
		loser.type.name == "B. Line Infantry" or
		loser.type.name == "B. Light Infantry" or
		loser.type.name == "Dragoon Guards" or
		loser.type.name == "Light Dragoon" or
		loser.type.name == "B. Foot Artillery" or
		loser.type.name == "B. Horse Artillery") and
	   winner.owner == France and tileWithinIreland(loser.location) then
		createUnitsByName("Irish Rebel", France,{{38,24,0}, {26,36,0}, {34,32,0}, {31,31,0}, {32,28,0}, {34,26,0}, {37,27,0}}, {randomize = true, homeCity = nil, veteran = false})
		civ.ui.text(func.splitlines("************************ Irish Rebels Recruited ************************\n^\r^Emperor Napoléon, the French Navy has been successfully operating\n^off the coast of Ireland and engaging British units garrisonning the\n^island.\n^\r^As such, resistance cells have taken advantage of the situation to\n^raid or retrieve weapons from English depots left unattended during\n^the attacks and used them to form a local Irish resistance cell."))
	end
	
-- ==== French Punitive Raid against Barbary Pirates base of Algiers
	if state.englandIsAtWarWithFrance == true then --and civ.hasTech(England, findTechByName("British Royal Marines")) then
		if loser.type.name == "Major Fort" and cityTileAlgier(loser.location) and winner.owner == France then
			civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Emperor Napoléon, your forces have carried out a successful punitive raid\n^against the Barbary Pirates of Algiers.\n^\r^As such, the leader of the pirates, Hassan Bey agrees to cease all further\n^hostile acts against your Empire and to pay you a war indemnity of 250 francs.\n^\r^In return, you agree to withdraw your forces and allow the pirates to rebuild\n^their fortifications."))
			state.barbaryPiratesPunished = true
			local fort = createUnitsByName("Minor Fort", Barbarians, {{51,119,0}}, {homeCity = nil, veteran = true})
			--fort.order = 2
			changeMoney(France, 250)
		end
	end
	
-- ==== Killed British 'Tranport' units replaced
	if state.englandIsAtWarWithFrance == true and state.englandIsSubdued == false then 
		if loser.type.name == "Transport" and winner.owner == France then
			createUnitsByName("Transport", England,{{52,28,0}, {50,24,0}, {46,22,0}, {99,117,0}}, {randomize = true, homeCity = nil, veteran = false})
			print("Replaced lost British Transport Unit")
		end
	end
	
-- ==== British Raid against Malaga; Spaniards repair their fort
	-- if state.spainIsAtWarWithEngland == true then 
		-- if loser.type.name == "Minor Fort" and cityTileMalaga(loser.location) and winner.owner == England then
			-- civ.ui.text(func.splitlines("Imperial Dispatch - " .. displayMonthYear() .. ":\n^\r^Sire, despite having suffered some heavy damage to its installations during\n^a British raid, your agents in Spain report that the Spaniards were able to\n^quickly repair their fortifications in Malaga."))
			-- local fort = createUnitsByName("Minor Fort", Spain, {{23,113,0}}, {homeCity = nil, veteran = true})
			-- fort.order = 2
		-- end
	-- end

end)	-- end of civ.scen.onUnitKilled()

-- Initialize the random number generator each time this file is parsed:
local randomizer = (os.time() % 100)
randomizer = ((randomizer * randomizer * 111) + 111) % 10000
math.randomseed(randomizer)
for i = 1, randomizer do math.random() end
print("")
print("Initialized the random number generator using " .. randomizer)

print("")
print("=====================================================")
print("events.lua parsed successfully at " .. os.date("%c"))
print("    Lines found: " .. debug.getinfo(1).currentline + 2)
print("=====================================================")
print("")
