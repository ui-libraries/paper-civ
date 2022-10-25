-- utilCivUI.lua
-- by Knighttime

-- Note: require globalFunctions.lua in the main events.lua file first, in order to require and use this file.
-- Note: require log.lua in the main events.lua file first, in order to require and use this file.

log.trace()

local UTIL_FILE_NAME = "utilCivUI"
local UTIL_FILE_VERSION = 1.00

local CHAR_PIXEL_WIDTH = {
	[32]  =  5, --  	space
	[33]  =  6,	-- !
	[34]  =  6,	-- "
	[35]  = 10,	-- #
	[36]  = 10,	-- $
	[37]  = 16,	-- %
	[38]  = 12,	-- &	needs to be escaped with a second & in order to print
	[39]  =  3,	-- '
	[40]  =  6,	-- (
	[41]  =  6,	-- )
	[42]  =  7,	-- *
	[43]  = 11,	-- +
	[44]  =  5,	-- ,
	[45]  =  6,	-- -
	[46]  =  5,	-- .
	[47]  =  5,	-- /
	[48]  = 10,	-- 0
	[49]  =  9,	-- 1
	[50]  = 10,	-- 2
	[51]  = 10,	-- 3
	[52]  = 10,	-- 4
	[53]  = 10,	-- 5
	[54]  = 10,	-- 6
	[55]  = 10,	-- 7
	[56]  = 10,	-- 8
	[57]  = 10,	-- 9
	[58]  =  5,	-- :
	[59]  =  5,	-- ;
	[60]  = 11,	-- <
	[61]  = 11,	-- =
	[62]  = 11,	-- >
	[63]  = 10,	-- ?
	[64]  = 18,	-- @
	[65]  = 11,	-- A
	[66]  = 12,	-- B
	[67]  = 13,	-- C
	[68]  = 13,	-- D
	[69]  = 12,	-- E
	[70]  = 11,	-- F
	[71]  = 14,	-- G
	[72]  = 13,	-- H
	[73]  =  4,	-- I
	[74]  =  9,	-- J
	[75]  = 12,	-- K
	[76]  = 10,	-- L
	[77]  = 15,	-- M
	[78]  = 13,	-- N
	[79]  = 14,	-- O
	[80]  = 12,	-- P
	[81]  = 14,	-- Q
	[82]  = 13,	-- R
	[83]  = 12,	-- S
	[84]  = 12,	-- T
	[85]  = 13,	-- U
	[86]  = 11,	-- V
	[87]  = 17,	-- W
	[88]  = 11,	-- X
	[89]  = 12,	-- Y
	[90]  = 11,	-- Z
	[91]  =  5,	-- [
	[92]  =  5,	-- \
	[93]  =  5,	-- ]
	[94]  =  7,	-- ^
	[95]  =  0,	-- _	underscore does not print!
	[96]  =  6,	-- `
	[97]  = 10,	-- a
	[98]  = 10,	-- b
	[99]  =  9,	-- c
	[100] = 10,	-- d
	[101] = 10,	-- e
	[102] =  5,	-- f
	[103] = 10,	-- g
	[104] = 10,	-- h
	[105] =  4,	-- i
	[106] =  4,	-- j
	[107] =  9,	-- k
	[108] =  4,	-- l
	[109] = 14,	-- m
	[110] = 10,	-- n
	[111] = 10,	-- o
	[112] = 10,	-- p
	[113] = 10,	-- q
	[114] =  6,	-- r
	[115] =  9,	-- s
	[116] =  5,	-- t
	[117] = 10,	-- u
	[118] =  9,	-- v
	[119] = 13,	-- w
	[120] =  8,	-- x
	[121] =  9,	-- y
	[122] =  8,	-- z
	[123] =  6,	-- {
	[124] =  6,	-- |
	[125] =  6,	-- }
	[126] = 11,	-- ~
--	[127] = ,	-- DEL
	[128] = 10,	-- €
--	[129] = ,	-- 
	[130] =  4,	-- ‚
	[131] = 10,	-- ƒ
	[132] =  7,	-- „
	[133] = 18,	-- …
	[134] = 10,	-- †
	[135] = 10,	-- ‡
	[136] =  6,	-- ˆ
	[137] = 17,	-- ‰
	[138] = 12,	-- Š
	[139] =  6,	-- ‹
	[140] = 18,	-- Œ
--	[141] = ,	-- 
	[142] = 11,	-- Ž
--	[143] = ,	-- 
--	[144] = ,	-- 
	[145] =  4,	-- ‘
	[146] =  4,	-- ’
	[147] =  7,	-- “
	[148] =  7,	-- ”
	[149] =  6,	-- •
	[150] = 10,	-- –
	[151] = 18,	-- —
	[152] =  5,	-- ˜
	[153] = 18,	-- ™
	[154] =  9,	-- š
	[155] =  6,	-- ›
	[156] = 17,	-- œ
--	[157] = ,	-- 
	[158] =  8,	-- ž
	[159] = 12,	-- Ÿ
	[160] =  5,	--  	non-breaking space
	[161] =  6,	-- ¡
	[162] = 10,	-- ¢
	[163] = 10,	-- £
	[164] = 10,	-- ¤
	[165] = 10,	-- ¥
	[166] =  6,	-- ¦
	[167] = 10,	-- §
	[168] =  6,	-- ¨
	[169] = 13,	-- ©
	[170] =  6,	-- ª
	[171] = 10,	-- «
	[172] = 11,	-- ¬
	[173] =  6,	-- ­
	[174] = 13,	-- ®
	[175] = 10,	-- ¯
	[176] =  7,	-- °
	[177] = 10,	-- ±
	[178] =  6,	-- ²
	[179] =  6,	-- ³
	[180] =  6,	-- ´
	[181] = 10,	-- µ
	[182] = 10,	-- ¶
	[183] =  6,	-- ·
	[184] =  6,	-- ¸
	[185] =  6,	-- ¹
	[186] =  7,	-- º
	[187] = 10,	-- »
	[188] = 15,	-- ¼
	[189] = 15,	-- ½
	[190] = 15,	-- ¾
	[191] = 11,	-- ¿
	[192] = 12,	-- À
	[193] = 12,	-- Á
	[194] = 12,	-- Â
	[195] = 12,	-- Ã
	[196] = 12,	-- Ä
	[197] = 12,	-- Å
	[198] = 18,	-- Æ
	[199] = 13,	-- Ç
	[200] = 12,	-- È
	[201] = 12,	-- É
	[202] = 12,	-- Ê
	[203] = 12,	-- Ë
	[204] =  5,	-- Ì
	[205] =  5,	-- Í
	[206] =  5,	-- Î
	[207] =  5,	-- Ï
	[208] = 13,	-- Ð
	[209] = 13,	-- Ñ
	[210] = 14,	-- Ò
	[211] = 14,	-- Ó
	[212] = 14,	-- Ô
	[213] = 14,	-- Õ
	[214] = 14,	-- Ö
	[215] = 11,	-- ×
	[216] = 14,	-- Ø
	[217] = 13,	-- Ù
	[218] = 13,	-- Ú
	[219] = 13,	-- Û
	[220] = 13,	-- Ü
	[221] = 12,	-- Ý
	[222] = 12,	-- Þ
	[223] = 11,	-- ß
	[224] =  6,	-- à
	[225] =  6,	-- á
	[226] =  6,	-- â
	[227] =  6,	-- ã
	[228] =  6,	-- ä
	[229] =  6,	-- å
	[230] = 16,	-- æ
	[231] =  9,	-- ç
	[232] = 10,	-- è
	[233] = 10,	-- é
	[234] = 10,	-- ê
	[235] = 10,	-- ë
	[236] =  5,	-- ì
	[237] =  5,	-- í
	[238] =  5,	-- î
	[239] =  5,	-- ï
	[240] = 10,	-- ð
	[241] = 10,	-- ñ
	[242] = 10,	-- ò
	[243] = 10,	-- ó
	[244] = 10,	-- ô
	[245] = 10,	-- õ
	[246] = 10,	-- ö
	[247] = 10,	-- ÷
	[248] = 10,	-- ø
	[249] = 10,	-- ù
	[250] = 10,	-- ú
	[251] = 10,	-- û
	[252] = 10,	-- ü
	[253] =  9,	-- ý
	[254] = 10,	-- þ
	[255] =  9,	-- ÿ
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
local function printRecursiveTable (tableString, tableReference, keysToExclude, indentLevel, luaCodeFormat) --> string
	log.trace()
	local keysAtThisLevel = {}
	local stringKeysAtThisLevel = {}
	for key, value in pairs(tableReference) do
		local keyShouldBeExcluded = false
		if keysToExclude ~= nil then
			for _, excludeKey in ipairs(keysToExclude) do
				if key == excludeKey then
					keyShouldBeExcluded = true
					if luaCodeFormat then
					--	do nothing
					-- else
					--	tableString = tableString .. string.rep(" ", indentLevel + 4) .. key .. ": [not displayed]\r\n"
					end
					break
				end
			end
		end
		if keyShouldBeExcluded == false then
			if type(key) == "number" then
				table.insert(keysAtThisLevel, key)
			else
				table.insert(stringKeysAtThisLevel, key)
			end
		end
	end
	table.sort(keysAtThisLevel)
	table.sort(stringKeysAtThisLevel)
	for _, stringKey in ipairs(stringKeysAtThisLevel) do
		table.insert(keysAtThisLevel, stringKey)
	end
	local isFirstKey = true
	for _, key in ipairs(keysAtThisLevel) do
		value = tableReference[key]
		if isFirstKey then
			isFirstKey = false
		else
			if luaCodeFormat then
				tableString = tableString .. ","
			end
			tableString = tableString .. "\r\n"
		end
		local stringKey = ""
		if luaCodeFormat then
			if type(key) == "number" then
				stringKey = "[" .. tostring(key) .. "]"
			else
				stringKey = "[\"" .. tostring(key) .. "\"]"
			end
		else
			stringKey = tostring(key)
		end
		if type(value) == "table" then
			tableString = tableString .. string.rep(" ", indentLevel + 4) .. stringKey
			if luaCodeFormat then
				tableString = tableString .. " = {"
			else
				tableString = tableString .. ":"
			end
			tableString = tableString .. "\r\n"
			tableString = printRecursiveTable(tableString, value, keysToExclude, indentLevel + 4, luaCodeFormat)
			if luaCodeFormat then
				tableString = tableString .. string.rep(" ", indentLevel + 4) .. "}"
			end
		else
			tableString = tableString .. string.rep(" ", indentLevel + 4) .. stringKey .. " = "
			if type(value) == "string" and luaCodeFormat then tableString = tableString .. "\"" end
			tableString = tableString .. tostring(value)
			if type(value) == "string" and luaCodeFormat then tableString = tableString .. "\"" end
		end
	end
	if isFirstKey == false and luaCodeFormat then
		-- That is, you found at least one key at this level
		tableString = tableString .. "\r\n"
	end
	return tableString
end

-- ==============================================================
-- ••••••••••••••• EXTERNALLY AVAILABLE FUNCTIONS •••••••••••••••
-- ==============================================================
local function addTextToDialog (dialog, text) --> void, but the dialog (first parameter) is passed by reference and altered
--
--	"|" is designated as a newline delimiter.
--		NOTE: This ALWAYS forces the following text (up to the next line or paragraph break) onto a single line!
--			  This seems to be inherent civ.ui.text behavior.
--	"||" is designated as a paragraph delimiter (i.e., a newline followed by another blank line)
--		NOTE: The new paragraph that follows this will wrap lines.
--	"^" forces the following text (up to the next line or paragraph break) onto a single line.
--		NOTE: This is rarely necessary; only needed at the beginning of a new message or paragraph, if you need the first
--			  line of that paragraph to be the longest in the message box.
--
	log.trace()
	local revisedText = string.gsub(string.gsub(text, "||", "\r\n^\r\n"), "|", "\r\n^")
	local pattern = string.format("([^%s]+)", "\r\n")
	local fields = {}
	string.gsub(revisedText, pattern, function(c)
		table.insert(fields, c)
	end)

--	civ.ui.text(table.unpack(fields))
	-- The above call to civ.ui.text() works;
	-- However, civ.ui.createDialog() supports several enhanced customization options, so it is being instead.
--	dialog:addText(table.unpack(fields))
	-- The above call results in only the first line being displayed!
	-- Instead, add each line to the dialog separately:
	for _, lineText in pairs(fields) do
		dialog:addText(lineText)
	end
end

local function convertTableToMessageText (columnTable, dataTable, borderWidth) --> string
	log.trace()
	local messageText = ""
	if borderWidth == nil or borderWidth < 1 then
		borderWidth = 1
	end
	local columnCharPixelWidth = { }
	for columnNumber, columnData in ipairs(columnTable) do
		columnCharPixelWidth[columnNumber] = 0
		for _, data in ipairs(dataTable) do
			local pixelWidth = 0
			for i = 1, #data[columnData.label] do
				charPixels = CHAR_PIXEL_WIDTH[string.byte(data[columnData.label], i)]
				if charPixels == nil then
					log.warning("WARNING: " .. UTIL_FILE_NAME .. ".lua found no pixel length for character " .. tostring(string.byte(data[columnData.label], i)))
					charPixels = 0
				end
				pixelWidth = pixelWidth + charPixels
			end
			if pixelWidth > columnCharPixelWidth[columnNumber] then
				columnCharPixelWidth[columnNumber] = pixelWidth
			end
		end
	end
	for _, data in ipairs(dataTable) do
		messageText = messageText .. "|"
		local pixelDifferenceThisLine = 0
		for columnNumber, columnData in ipairs(columnTable) do
			local pixelWidth = 0
			for i = 1, #data[columnData.label] do
				charPixels = CHAR_PIXEL_WIDTH[string.byte(data[columnData.label], i)]
				if charPixels == nil then
					charPixels = 0
				end
				pixelWidth = pixelWidth + charPixels
			end
			local pixelsNeeded = columnCharPixelWidth[columnNumber] - pixelWidth
			local spacesNeeded = round((pixelsNeeded + pixelDifferenceThisLine) / CHAR_PIXEL_WIDTH[32])
			pixelDifferenceThisLine = (pixelsNeeded + pixelDifferenceThisLine) - (spacesNeeded * CHAR_PIXEL_WIDTH[32])
			local columnBorderWidth = borderWidth
			if columnNumber == 1 then
				columnBorderWidth = 0
			end
			if columnData.align == "right" then
				messageText = messageText .. string.rep(" ", columnBorderWidth) .. string.rep(" ", spacesNeeded) .. data[columnData.label]
			elseif columnData.align == "center" then
				messageText = messageText .. string.rep(" ", columnBorderWidth) .. string.rep(" ", round(spacesNeeded / 2)) .. data[columnData.label] .. string.rep(" ", spacesNeeded - round(spacesNeeded / 2))
			else	-- default is left align
				messageText = messageText .. string.rep(" ", columnBorderWidth) .. data[columnData.label] .. string.rep(" ", spacesNeeded)
			end
		end
	end
	return messageText
end

-- See addTextToDialog() for notes about the format of 'messageText'
-- This is also called internally by message() and must be declared prior to it in this file:
local function messageDialog (messageTitle, messageText, messageWidth, messageHeight) --> void
	log.trace()
	local dialog = civ.ui.createDialog()
	dialog.title = messageTitle
	if messageWidth ~= nil and messageWidth > 0 then
		dialog.width = messageWidth
	else
		dialog.width = 480
	end
	if messageHeight ~= nil and messageHeight > 0 then
		dialog.height = messageHeight
	end
	addTextToDialog (dialog, messageText)
	log.action("Message dialog box displayed")
	dialog:show()
end

local function message (messageText) --> void
	log.trace()
	messageDialog("", messageText, 0, 0)
end

-- Credit to "menu" function in text.lua by Prof. Garfield
-- See addTextToDialog() for notes about the format of 'dialogText'
-- Calling program must ensure that 'maxOptionsPerPage' is compatible with the display lines utilized by dialogText, if that is provided
-- Calling program must also ensure that keys in the 'staticOptions' and 'pagedOptions' tables are unique (no collisions)
-- 		If pagedOptions is using object id's as keys, then using negative numbers as keys for staticOptions would be a best practice
-- The keys "-10000" and "10000" are not permitted in either table; these are reserved for the "Previous Page" and "Next Page" options
-- First return integer is the key that was selected, from either the staticOptions or pagedOptions table
-- Second return integer is the page number on which that selection was made
--		Useful if the dialog is being shown in a loop and you want to keep the user on (or return them to) the "current" page
local function optionDialog (dialogTitle, dialogText, dialogWidth, staticOptions, pagedOptions, maxOptionsPerPage, showPage) --> integer, integer
	log.trace()
	dialogTitle = dialogTitle or ""

	local dialog = civ.ui.createDialog()
	if dialogWidth ~= nil then
		dialog.width = dialogWidth
	end
	if dialogText ~= nil then
		addTextToDialog (dialog, dialogText)
	end
	if showPage == nil then
		showPage = 1
	end
	local prevPageId = -10000
	local nextPageId = 10000

	local numStaticOptions = 0
	local minStaticKey = 1
	local maxStaticKey = 1
	for key, _ in pairs(staticOptions) do
		numStaticOptions = numStaticOptions + 1
		if key < minStaticKey then minStaticKey = key end
		if key > maxStaticKey then maxStaticKey = key end
	end
	local numPagedOptions = 0
	local minPagedKey = 1
	local maxPagedKey = 1
	for key, _ in pairs(pagedOptions) do
		numPagedOptions = numPagedOptions + 1
		if key < minPagedKey then minPagedKey = key end
		if key > maxPagedKey then maxPagedKey = key end
	end

	if (numStaticOptions + numPagedOptions) <= maxOptionsPerPage then
		-- All dialog options can fit on one page
		dialog.title = dialogTitle
		for key = minStaticKey, maxStaticKey do
			if staticOptions[key] ~= nil then
				dialog:addOption(staticOptions[key], key)
			end
		end
		for key = minPagedKey, maxPagedKey do
			if pagedOptions[key] ~= nil then
				dialog:addOption(pagedOptions[key], key)
			end
		end
	else
		-- Dialog will not fit on one page
		-- Break the menu apart into pages:
		local page = { }
		local pageNumber = 1
		local lastPagedOptionKey = minPagedKey - 1
		repeat
			page[pageNumber] = { }
			for key = minStaticKey, maxStaticKey do
				if staticOptions[key] ~= nil then
					table.insert(page[pageNumber], {optionValue = staticOptions[key], optionId = key})
				end
			end
			if pageNumber > 1 then
				table.insert(page[pageNumber], {optionValue = "<–––[PREVIOUS PAGE]", optionId = prevPageId})
			end
			local startKey = lastPagedOptionKey + 1
			for key = startKey, maxPagedKey do
				if pagedOptions[key] ~= nil and #page[pageNumber] < (maxOptionsPerPage - 1) then		-- leaving 1 for the "Next Page" option which will appear on all but the last page
					table.insert(page[pageNumber], {optionValue = pagedOptions[key], optionId = key})
					lastPagedOptionKey = key
				end
			end
			if lastPagedOptionKey < maxPagedKey then
				table.insert(page[pageNumber], {optionValue = "[NEXT PAGE]–––>", optionId = nextPageId})
				pageNumber = pageNumber + 1
			end
		until
			lastPagedOptionKey == maxPagedKey
		log.info("Divided " .. numStaticOptions .. " static and " .. numPagedOptions .. " paged options into " .. #page .. " pages, at " .. maxOptionsPerPage .. " per page")

		-- Add the entries from the desired page to the dialog:
		dialog.title = dialogTitle .. ": page " .. showPage .. " of " .. #page
		for _, dataTable in ipairs(page[showPage]) do
			dialog:addOption(dataTable.optionValue, dataTable.optionId)
		end
	end

	log.action("Dialog box displayed")
	local result = dialog:show()
	if result == prevPageId then
		return optionDialog(dialogTitle, dialogText, dialogWidth, staticOptions, pagedOptions, maxOptionsPerPage, showPage - 1)
	elseif result == nextPageId then
		return optionDialog(dialogTitle, dialogText, dialogWidth, staticOptions, pagedOptions, maxOptionsPerPage, showPage + 1)
	else
		return result, showPage
	end
end

local function printTable (tableName, tableReference, keysToExclude, luaCodeFormat) --> void
	log.trace()
	if luaCodeFormat == nil then
		luaCodeFormat = false
	end
	print("----------------------------------------")
	local tableString = ""
	if luaCodeFormat then
		tableString = tableName .. " = {\r\n"
	else
		tableString = "Contents of '" .. tableName .. "' table:\r\n"
	end
	tableString = printRecursiveTable(tableString, tableReference, keysToExclude, 0, luaCodeFormat)
	if luaCodeFormat then
		tableString = tableString .. "}"
	end
--	print(tableString)

--	There seems to be timeout issues with printing long strings to the Lua console, in that they are (sometimes) truncated.
--	As a workaround, this will print strings in chunks of 10,000 characters at a time.
--	This inserts hard returns in undesirable places, but since the console is intended as an aid to programmers, they can probably figure it out...
	local chunk = 0
	repeat
		print(string.sub(tableString, (chunk * 10000) + 1, (chunk + 1) * 10000))
		chunk = chunk + 1
		if string.len(tableString) < (chunk * 10000) then
			break
		else
			print("...(continued)...")
		end
	until false
	print("----------------------------------------")
end

-- Credit to http://lua-users.org/wiki/SleepFunction
function sleep (seconds) --> void
	log.trace()
	local ntime = os.time() + seconds
	repeat
		-- nothing
	until os.time() > ntime
end

linesOfLuaCode = (linesOfLuaCode or 0) + debug.getinfo(1, "l").currentline + 12

return {
	confirmLoad = confirmLoad,

	addTextToDialog = addTextToDialog,
	convertTableToMessageText = convertTableToMessageText,
	messageDialog = messageDialog,
	message = message,
	optionDialog = optionDialog,
	printTable = printTable,
	sleep = sleep,
}
