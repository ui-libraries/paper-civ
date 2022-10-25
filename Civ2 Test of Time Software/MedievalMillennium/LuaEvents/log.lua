-- log.lua
-- by Knighttime

local FILE_NAME = "log"
local FILE_VERSION = 1.00

local EnumLogLevel = {
	[0] = "Trace",		Trace = 0,		-- logs every function call and everything from higher levels (overwhelming amount of data)
	[1] = "Info",		Info = 1,		-- logs informational messages and everything from higher levels
	[2] = "Update",		Update = 2,		-- logs updates to internal memory tracking game status for event purposes, and everything from higher levels
	[3] = "Action",		Action = 3,		-- logs changes to actual in-game objects and everything from higher levels
	[4] = "Warning",	Warning = 4,	-- logs items of concern that may indicate an unforeseen path through events, and everything from the next higher level
	[5] = "Error",		Error = 5,		-- logs invalid function calls, missing data, etc.
	[6] = "None",		None = 6		-- no logging will occur. Not recommended as a logLevel, but may be useful as an alertLevel.
}
local showLevelPrefixes = false
local pathsToTrim = { }
local mostRecentPathInfo = { }
local pendingTriggerName = nil

-- ==============================================
-- ••••••••••••••• INITIALIZATION •••••••••••••••
-- ==============================================
-- Declared now for consistency, but defined later so it can use functions defined in this file:
local confirmLoad

-- ===========================================================
-- ••••••••••••••• STRICTLY INTERNAL FUNCTIONS •••••••••••••••
-- ===========================================================
local function getCurrentModule (sourcePath) --> String
	local currentModule = string.gsub(tostring(sourcePath), "@", "")
	for i = 1, #pathsToTrim do
		currentModule = string.gsub(tostring(currentModule), pathsToTrim[i], "")
	end
	currentModule = string.gsub(currentModule, ".lua", "")
	return currentModule
end

local function showPath () --> integer (quantity of valid heading levels found)
	local printedTriggerName = false
	if pendingTriggerName ~= nil then
		if showLevelPrefixes then
			pendingTriggerName = "[+] " .. pendingTriggerName
		end
		print(pendingTriggerName)
		printedTriggerName = true
		pendingTriggerName = nil
	end
	local currentPathInfo = { }
	local i = 1
	local pathFound = true
	while pathFound do
		local info = debug.getinfo(i, "Sn")
		if info == nil then
			pathFound = false
		else
			local currentModule = getCurrentModule(info.source)
			if currentModule == "=[C]" or (currentModule == "events" and info.name == nil) then
				pathFound = false
			elseif currentModule ~= "log" or
				   (currentModule == "log" and (info.name == "confirmLoad" or info.name == "setLogLevel" or info.name == "setAlertLevel" or info.name == "addPathToTrim")) then
				table.insert(currentPathInfo, 1, "@ " .. currentModule .. "." .. (info.name or "(root)"))
			end
		end
		i = i + 1
	end
	for i = 1, #currentPathInfo do
		if currentPathInfo[i] ~= mostRecentPathInfo[i] then
			local outputPath = string.rep(" ", i * 2) .. currentPathInfo[i]
			if showLevelPrefixes then
				outputPath = "[H] " .. outputPath
			end
			print(outputPath)
		end
	end
	mostRecentPathInfo = { }
	for k, v in ipairs(currentPathInfo) do
		mostRecentPathInfo[k] = v
	end
	return #mostRecentPathInfo
end

local function showMessage (messageLevel, messageString) --> void
	if messageLevel >= (logLevel or EnumLogLevel.Trace) then
		local headings = 1		-- used for Trace only
		if (logLevel or EnumLogLevel.Trace) > EnumLogLevel.Trace then
			headings = showPath()
		end
		if messageString ~= nil then
--			local consoleString = messageString
--			if messageLevel < EnumLogLevel.Update then
--				consoleString = string.rep(" ", (headings + 1) * 2) .. messageString
--			end
			local consoleString = ""
			if showLevelPrefixes then
				consoleString = "[" .. string.sub(EnumLogLevel[messageLevel], 1, 1) .. "] "
			end
			if messageLevel < EnumLogLevel.Update then
				consoleString = consoleString .. string.rep(" ", (headings + 1) * 2)
			end
			consoleString = consoleString .. messageString
			print(consoleString)
			if messageLevel >= (alertLevel or EnumLogLevel.Warning) then
--				civ.ui.text(messageString)
				local dialog = civ.ui.createDialog()
				dialog.title = "events.lua"
				dialog:addText(messageString)
				dialog:show()
			end
		end
	end
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function showPathDebug () --> void
	local i = 1
	local pathFound = true
	while pathFound do
		local info = debug.getinfo(i, "Sn")
		if info == nil then
			pathFound = false
		else
			local currentModule = getCurrentModule(info.source)
			print("DEBUG: " .. currentModule .. "." .. (info.name or "(root)"))
		end
		i = i + 1
	end
end

-- This is called internally by trace() and must be declared prior to it in this file:
local function setPendingTriggerName (moduleName) --> void
	pendingTriggerName = "  + " .. moduleName
	mostRecentPathInfo = { }
end

-- NOTE: All functions should call log.trace() with no parameters, so that the name of the function appears on the console when the logging level is set to Trace.
--		The intended use of the moduleName parameter is to provide the logging system with the name of one of the fixed civ.scen.on___ triggers,
--		when calling this from the anonymous function used there.
local function trace (moduleName) --> void
	if moduleName == nil then
		local info = debug.getinfo(2, "Sn")
		moduleName = getCurrentModule(info.source)
		moduleName = "  @ " .. moduleName .. "." .. (info.name or "(root)")
	else
		setPendingTriggerName (moduleName)
		moduleName = "  + " .. moduleName
	end
	if (logLevel or EnumLogLevel.Trace) <= EnumLogLevel.Trace then
		if showLevelPrefixes then
			moduleName = "[T] " .. moduleName
		end
		print(moduleName)
	end
end

-- NOTE: Calling any of the following 5 functions with no parameter (or a nil parameter) will have the effect of printing the current path for the appropriate logLevel(s)
--		 Calling any of them with an empty string ("") will have the effect of printing the current path AND ALSO printing a blank line in the console, again for the appropriate logLevel(s)
local function info (messageString) --> void
	showMessage(EnumLogLevel.Info, messageString)
end

local function update (messageString) --> void
	showMessage(EnumLogLevel.Update, messageString)
end

local function action (messageString) --> void
	showMessage(EnumLogLevel.Action, messageString)
end

local function warning (messageString) --> void
	showMessage(EnumLogLevel.Warning, messageString)
end

local function error (messageString) --> void
	showMessage(EnumLogLevel.Error, messageString)
end

-- Declared earlier, defined now, so it can call functions defined previously in this file:
local function confirmLoad (requiredVersion) --> boolean
	trace()
	info(string.match(string.gsub(debug.getinfo(1, "S").source, "@", ""), ".*\\(.*)") .. " v" .. FILE_VERSION .. " loaded successfully")
	if requiredVersion ~= nil and requiredVersion > FILE_VERSION then
		error("Version " .. requiredVersion .. " of " .. FILE_NAME .. ".lua is required, but a lower version (" .. FILE_VERSION .. ") was found. Please download and install an updated version of this Lua utility file, and then restart the game. If you fail to do so, Lua events may crash or not work as intended.")
		return false
	end
	info("")
	return true
end

local function getLogLevel () --> integer
	trace()
	return logLevel
end

local function setLogLevel (level) --> void
	trace()
	logLevel = level
	action("Set log.logLevel = " .. EnumLogLevel[logLevel])
end
logLevel = EnumLogLevel.Trace
print("Set log.logLevel = " .. EnumLogLevel[logLevel])

local function getAlertLevel () --> integer
	trace()
	return alertLevel
end

local function setAlertLevel (level) --> void
	trace()
	alertLevel = level
	action("Set log.alertLevel = " .. EnumLogLevel[alertLevel])
end
alertLevel = EnumLogLevel.Warning
print("Set log.alertLevel = " .. EnumLogLevel[alertLevel])

local function addPathToTrim (path) --> void
--	trace()
	table.insert(pathsToTrim, path)
	action("Added " .. path .. " as a path to trim")
end
addPathToTrim(string.gsub(string.gsub(debug.getinfo(1, "S").source, "@", ""), "log.lua", ""))

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 20

return {
	EnumLogLevel = EnumLogLevel,

	confirmLoad = confirmLoad,

	showPathDebug = showPathDebug,
	setPendingTriggerName = setPendingTriggerName,
	trace = trace,
	info = info,
	update = update,
	action = action,
	warning = warning,
	error = error,
	getLogLevel = getLogLevel,
	setLogLevel = setLogLevel,
	getAlertLevel = getAlertLevel,
	setAlertLevel = setAlertLevel,
	addPathToTrim = addPathToTrim,
}
