-- Sci-fi scenario events file

print "Lalande 21185 Science Fiction Game."

-- The `civ` library is written in C, and contains, generally, lower level functions to interact with the game.
-- It is always in scope.

-- The `civlua` library is written in Lua, and contains higher level functions built on the `civ` library.
local civlua = require "civlua"

-- The `functions` library contains general purpose functions.
local func = require "functions"

-- The `state` table represents the persistent state of the scenario, it is initialized here.
-- Keeping all state in a single table helps with serialization, see below.
-- The initial state can be empty for this scenario, since it's only used in calls to `justOnce`,
-- and all references to nonexistent keys evaluate to nil in lua.
local state = {}

-- Our local 'justOnce' function, so it uses our state.
local justOnce = function (key, f) civlua.justOnce(civlua.property(state, key), f) end

local negate = function (f) return function (x) return not f(x) end end

-- Alien tribes are the even numbered tribes in the Scifi game.
local isAlien = function (tribe)
  return tribe.id % 2 == 0
end

-- Human tribes are the tribes that are not aliens.
local isHuman = negate(isAlien)

-- Various texts used in the scenario
local introText = [[Years ago, a magnificent starship filled with valiant settlers set out to reach the star nearest their home world. En route, their sensing devices detected an enormous alien artifact, and they changed course to investigate. Unfortunately for the starship crew and passengers, they somehow activated the artifact's defensive systems.
^
Some sort of gateway opened up directly in front of the colony ship, and the next thing the survivors knew, they were entering the atmosphere of an unknown planet. The ship itself was almost completely destroyed, but due to the heroic efforts of the pilots and security officers, a few small groups managed to survive the fall.
^
Their best hope for the future is putting their training to good use--to tame and colonize this new world. If all goes well, then someday, somehow, they might be able to find a way to return home.]]

local transformText = function (unittype)
  return "Now that you have the requisite technology, the " .. unittype.name .. " can use the new Transform (\"o\") order to drastically change the terrain type in a square. These units also work twice as quickly as their predecessors in all ordinary tasks (road building, cultivation, etc)."
end

local shuttleText = "The newly built Shuttle unit is capable of rising to orbit on its own power. Use the Teleport order to move it into orbit around Funestis and to return it to the surface."

local shuttleDiscoveryText = "On a test flight of the new Shuttle, explorers in orbit around Funestis have stumbled onto an ancient artifact of immeasurable military importance. The radio reports describe a compact plasma containment unit. The original use of this device remains unknown, but it shows great promise as an ammunition chamber for plasma weapons of all types."

local hohmannText = "The newly built Hohmann unit can not only travel to and from orbit, but it can also reach the planet Naumachia on its own power. Use the Teleport order to get it there and back."

local hohmannDiscoveryText = "Carried there on the maiden voyage of the new Hohmann unit, planetary archaeologists digging into ancient ruins on the planet Naumachia have unearthed evidence of an unsuspected use for the crystal element Delierium 116. Significant portions of the text are intact, enough to re-create the long lost, alien technology."

local adamastorText = [[An ancient device of awe-inspiring power has been defeated.
^
Researchers studying recordings of the battle and the few
remains of the "guardian" weapon have found intriguing data
that hint at a previously unsuspected branch of physics.
^
Any civilization that attacks and destroys one of these
devices should be able to research into this new physics.]]

local urdarText = [[One of the ancient "creatures" that seemingly guard the planet
Nona from colonization attempts has been destroyed.
^
Whatever means the strange defender used to transport from place
to place left an unusual residual subatomic vibration signature.
Scientists are confident that research into this phenomenon will
lead to great leaps forward in the physical sciences.
^
Any civilization that attacks and destroys one of these creatures
should become able to research previously unknown topics.]]

local dondaschText = [[Forces have stopped a destructive, giant being of unknown design,
composition, and origin. Its destruction is not assured, however,
as it might have escaped by as yet unexplainable means.
^
Just before disappearing, the incredible device seemed to generate
and control a confined space-time incongruity in several dimensions.
Experts suggest that this might have been an attempt to escape,
perhaps a successful one. Nearby detectors gathered plenty of data,
and further study of the effect could have untold benefits.
^
Any civilization that attacks and destroys one of these beings should
gain access to new avenues of science.]]

local earthGateRaceText = [[^^The race to complete the Earthgate has begun!
^
The ability to create Penultimum, combined with Transfer Gate technology,
makes it possible to construct a wormhole with twin openings, connecting
Lalande 21185 (this planetary system) with the Solar system. Ships going
through would be instantly translated into Earth orbit!
^
All scientific efforts are being funneled into Earthgate research.
Whatever civilization completes this project will be the first to reach Earth,
and will be able to control access to the wormhole gate thereafter.]]

local earthGateBuiltText = [[^^The EarthGate has been opened!
^
A small group of ships has set on a diplomatic mission--to return to the home
world from which our human ancestors sprang and re-open relations with them.
^
Perhaps someday, with Earth technology added to ours, we will be able to send
emissaries to the home planet of our non-human ancestors, as well.]]

-- Text to show and tech to give when a giant is killed.
local giantKilled = {
  [59]={text=dondaschText, tech=99},
  [60]={text=urdarText, tech=98},
  [61]={text=adamastorText, tech=97},
}

-- Locations where to spawn giants.
local giantLocations = {
  [59]={{{8,24,3}, {16,39,3}, {32,59,3}, {64,24,3}, {128,39,3}, {24,59,3}, {40,24,3}, {72,39,3}, {56,59,3}, {80,24,3}},
	{{1,1,3}, {22,22,3}, {43,34,3}, {64,46,3}, {85,58,3}, {106,61,3}, {127,73,3}, {115,52,3}, {103,31,3}, {91,19,3}},
	{{14,24,3}, {34,24,3}, {54,24,3}, {74,24,3}, {37,39,3}, {67,39,3}, {97,39,3}, {135,59,3}, {85,59,3}, {35,59,3}}},
  [60]={{{40,12,3}, {40,27,3}, {40,32,3}, {40,43,3}, {50,17,3}, {50,33,3}, {50,65,3}, {74,2,3}, {74,56,3}, {74,111,3}},
	{{2,35,3}, {24,70,3}, {46,44,3}, {68,110,3}, {90,65,3}, {112,47,3}, {136,4,3}, {11,23,3}, {39,34,3}, {76,76,3}},
	{{77,14,3}, {54,37,3}, {32,34,3}, {6,45,3}, {143,101,3}, {121,87,3}, {98,65,3}, {84,34,3}, {42,12,3}, {17,12,3}}},
  [61]={{{74,60,3}, {53,42,3}, {42,24,3}, {11,16,3}, {5,5,3}, {16,74,3}, {24,53,3}, {42,42,3}, {60,11,3}, {35,28,3}},
	{{47,6,3}, {35,24,3}, {24,42,3}, {11,61,3}, {50,50,3}, {61,47,3}, {42,35,3}, {22,24,3}, {6,11,3}, {49,2,3}},
	{{8,6,3}, {25,51,3}, {18,31,3}, {45,71,3}, {1,1,3}, {100,100,3}, {75,18,3}, {20,88,3}, {45,75,3}, {143,28,3}}}
}

-- Enables building of transporters for the given unittype
local function buildTransport(unittype, mask)
  local unittype = civlua.findUnitType(unittype)
  unittype.buildTransport = unittype.buildTransport | mask
end

-- Give `tech` to all tribes satisfying `pred`
local function giveAll(pred, tech)
  for i = 1, 7 do
    local tribe = civ.getTribe(i)
    if pred(tribe) then
      civ.giveTech(tribe, tech)
    end
  end
end

-- The `onTurn` function runs its argument every turn, with the turn number passed as `turn`.
civ.scen.onTurn(function (turn)
  -- Show the intro text on the first turn. I'm omitting `justOnce` since it won't be turn 1 more than once anyway.
  if turn == 1 then
    civ.ui.text(func.splitlines(introText))
  end

  -- `.researched` returns true when any tribe has researched the given tech.
  -- Used like this it's equivalent to a ReceivedTechnology event with receiver=Anybody.
  if civ.getTech(66).researched then
    -- `justOnce` will test `state.transportOrbit`, if that's `false` or `nil` it will run the function and set `state.transportOrbit` to `true`.
    -- When it's already `true` it does nothing.
    justOnce("transportOrbit", function ()
      -- In place of the `Transport` action you can assign `buildTransport`, `nativeTransport` and `useTransport` on a unit type.
      -- Here we use the `buildTransport` function above for convenience, and enable transport relationship 1 (1 << 1 == 2)
      buildTransport("Colonist", 2)
      buildTransport("Nidus", 2)
      civ.ui.text("Colonists and the Nidus can now build SSTO Pads, which allow space-worthy units to travel into orbit.")
    end)
  end

  if civ.getTech(13).researched then
    justOnce("transportNaumachia", function ()
      -- Using `buildTransport` with a mask to set multiple transport relationships at once.
      -- 0x824 enables relationships 2, 5 and 11 (it's equal to (1 << 2) + (1 << 5) + (1 << 11))
      buildTransport("Environeer", 0x824)
      buildTransport("Melior", 0x824)
      civ.ui.text("Environeers and the Melior can now build Planetary Bases.")
    end)
  end

  if civ.getTech(79).researched then
    justOnce("transportNona", function ()
      buildTransport("Environeer", 0x9249)
      buildTransport("Melior", 0x9249)
      civ.ui.text("Environeers and the Melior can now build Gravitic Grids.")
    end)
  end

  -- If the player has researched G.En.I.E.s (26), announce the Melior's transform abilities
  if civ.getPlayerTribe():hasTech(civ.getTech(26)) then
    justOnce("transformMelior", function ()
      civ.ui.text(transformText(civ.getUnitType(51)))
    end)
  end

  -- If the player has researched Basic Automation (41), announce the Environeer's transform abilities
  if civ.getPlayerTribe():hasTech(civ.getTech(41)) then
    justOnce("transformEnvironeer", function ()
      civ.ui.text(transformText(civ.getUnitType(1)))
    end)
  end

  local artGrav = civ.getTech(61)
  local uniTheory = civ.getTech(76)
  -- If any (human) tribe has researched Artificial Gravity (61), but no alien tribe has Unification Theory, give all aliens Unification Theory.
  if artGrav.researched and not uniTheory.researched then
    giveAll(isAlien, uniTheory)
  end
  -- If any (alien) tribe has researched Unification Theory (76), but no human tribe has Artificial Gravity, give all humans Artificial Gravity
  if uniTheory.researched and not artGrav.researched then
    giveAll(isHuman, artGrav)
  end

  -- When anyone gets Quantum Gravitics (79), create 9 HaGibborim units on Nona
  if civ.getTech(79).researched then
    justOnce("createdGiants", function ()
      for unittype, value in pairs(giantLocations) do
	for _, locations in pairs(value) do
	  -- Create Adamastor, Dondasch and Urdar units.
	  -- civlua.createUnit is a faithful recreation of the original CreateUnit action, though that doesn't mean it's the best way to go in lua.
	  -- For instance, since the Dondasch is domain 0, there's a good chance it won't be created given a static location list.
	  civlua.createUnit(civ.getUnitType(unittype), civ.getTribe(0), locations, {randomize=true, veteran=true})
	end
      end
    end)
  end

  -- Warn when both Penultimum (82) and Transfer Gate (94) are researched.
  if civ.getTech(82).researched and civ.getTech(94).researched then
    justOnce("earthGateRace", function ()
      civ.ui.text(func.splitlines(earthGateRaceText))
    end)
  end

  -- End game and play video when Earthgate (81) is discovered.
  if civ.getTech(81).researched then
    justOnce("earthGateBuilt", function ()
      civ.ui.text(func.splitlines(earthGateBuiltText))
      civ.playVideo("Scene11.avi")
      civ.endGame(true)
    end)
  end
end)

civ.scen.onUnitKilled(function (killed, killedBy)
  local id = killed.type.id
  -- If the killed unit is one of the giants
  if giantKilled[id] then
    justOnce("killed" .. killed.type.name, function ()
      civ.ui.text(func.splitlines(giantKilled[id].text))
    end)
    -- `giveTech` is the replacement for GiveTechnology. It takes a tribe and a tech as parameters.
    civ.giveTech(killedBy.owner, civ.getTech(giantKilled[id].tech))
    -- Create a replacement unit of the same type as `killed`.
    civlua.createUnit(killed.type, civ.getTribe(0), giantLocations[id][1], {randomize=true, veteran=true})
  end
end)

civ.scen.onCityProduction(function (city, prod)
  -- `prod` can either be a unit, improvement or wonder.
  -- Use the appropriate `civ.isX` function to test that it is what you expect.
  if civ.isUnit(prod) and prod.type.name == "Shuttle" then
    justOnce("firstShuttleBuilt", function ()
      civ.ui.text(shuttleText)
      civ.giveTech(city.owner, civ.getTech(95))
      civ.ui.text(shuttleDiscoveryText)
    end)
    -- `enableTechGroup` is the equivalent to EnableTechnology. It takes a tech group (0-7) and a tech code (0-2) (see @LEADERS2).
    -- Since EnableTechnology also enables the group of the given tech, I've changed the name to make this more explicit.
    city.owner:enableTechGroup(civ.getTech(95).group, 0)
  end

  -- These string comparisons are case-sensitive, prod.type.name won't match "Hohmann" for instance.
  -- Using prod.type.id might be better.
  if civ.isUnit(prod) and prod.type.name == "HohMann" then
    justOnce("firstHohmannBuilt", function ()
      civ.ui.text(hohmannText)
      civ.giveTech(city.owner, civ.getTech(96))
      civ.ui.text(hohmannDiscoveryText)
    end)
    city.owner:enableTechGroup(civ.getTech(96).group, 0)
  end
end)

-- `onNegotiation` runs not only when diplomatic negotiations occur between tribes, but also when opening the Foreign Minister dialog. Return `true` to allow the two tribes to negotiate, `false` to disallow.
civ.scen.onNegotiation(function (talker, listener)
  local xeno = civ.getTech(14)
  -- Allow negotiations if both tribes are alien or both are not, or whenever one of them has Xenolinguistics (14).
  return isAlien(talker) == isAlien(listener) or
    talker:hasTech(xeno) or listener:hasTech(xeno)
end)

-- `onLoad` is responsible for restoring scenario state from a string. `onSave` is responsible for returning the state as a string. The implementations given here should suffice as a basis for most scenarios.
civ.scen.onLoad(function (buffer) state = civlua.unserialize(buffer) end)
civ.scen.onSave(function () return civlua.serialize(state) end)
