--
-- not yet integrated into template
--
--
local versionNumber = 1
local fileModified = false -- set this to true if you change this file for your scenario
-- if another file requires this file, it checks the version number to ensure that the
-- version is recent enough to have all the expected functionality
-- if you set fileModified to true, the error generated if this file is out of date will
-- warn you that you've modified this file
--
--
--
local gen = require("generalLibrary"):minVersion(1)
local param = require("parameters")
--
-- If you need to reset all the values for a season
-- (perhaps terrain was given a special bonus for some
-- reason), just run the function season.setSeason()
-- (After ensuring there is a line
-- local seasons=require("seasons")
-- in the file)

local seasons = {}


-- set everything that changes for "winter"
-- feel free to rename the seasons whatever you
-- want
local function setWinter()

end

-- set everything that changes for "summer"
local function setSummer()

end







function seasons.setSeason()
    -- by default, setSeason does nothing,
    -- since, by default, there are no special seasons
    
    -- use civ.getTurn() and whatever else to determine
    -- what season you wish to set
    -- if something then
    --      setSummer()
    --  else
    --      setWinter()

end

gen.versionFunctions(seasons,versionNumber,fileModified,"MechanicsFiles".."\\".."seasonSettings.lua")
return seasons
