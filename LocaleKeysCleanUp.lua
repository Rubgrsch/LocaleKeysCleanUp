-- LocaleKeysCleanUp.lua
-- Author: Rubgrsch
-- License: MIT

-- This code helps you find unused localeKeys in your WoW addon.

-- What may cause false positive
-- 1. keys in comments
-- 2. keys separated among lines
-- 3. keys doesn't match any patterns, e.g. L[ThisIsVariable]

-- Notes:
-- 1. Filenames in output only suggest one file that contains it. You need to search in files.
-- 2. The code is for Windows OS. You can find OS specific code with searching "io.popen".
-- 3. The code will not find redundant keys among locale files.


-- codePath is the dir (or file) of your addon. localePathT is an array of locale files or dirs.
-- exceptionPathT is an array of files or dirs that should't be processed (e.g. Libraries).
-- localePatternT is an array of regex patterns that match your locale keys.
-- You should use absolute path.
local codePath = [[path\to\elvui-master]]
local localePathT = {[[path\to\elvui-master\ElvUI_Config\locales]],[[path\to\elvui-master\ElvUI\locales]]}
local exceptionPathT = {[[path\to\elvui-master\ElvUI_Config\Libraries]],[[path\to\elvui-master\ElvUI\Libraries]]}
local localePatternT = {'L%[%".-%"%]', "L%[%'.-%'%]"}

-- Start of code --

local strfind, pairs, ipairs, strmatch, print = string.find, pairs, ipairs, string.match, print

localePathT = localePathT or {}

local codefilenameT = {} -- filenames of lua source files, [filename] = true
for filename in io.popen([[dir ]]..codePath..[[ /b /s /a-d]]):lines() do -- Change this if you're not on Windows
	if strfind(filename,"%.lua$") then codefilenameT[filename] = true end
end
local localefilenameT = {} -- filenames of locale files, [filename] = true
for _,path in ipairs(localePathT) do
	for filename in io.popen([[dir ]]..path..[[ /b /s /a-d]]):lines() do -- Change this if you're not on Windows
		if strfind(filename,"%.lua$") then localefilenameT[filename] = true end
	end
end

-- Remove exceptions
if exceptionPathT and type(exceptionPathT) == "table" then
	for _,exceptionName in ipairs(exceptionPathT) do
		for filename in pairs(codefilenameT) do
			if strfind(filename,exceptionName,1,true) then codefilenameT[filename] = nil end
		end
		for filename in pairs(localefilenameT) do
			if strfind(filename,exceptionName,1,true) then localefilenameT[filename] = nil end
		end
	end
end

-- Remove locale files in lua source file
for _,exceptionName in ipairs(localePathT) do
	for filename in pairs(codefilenameT) do
		if strfind(filename,exceptionName,1,true) then codefilenameT[filename] = nil end
	end
end

local function matchKey(fileNameTbl)
	local tbl = {}
	for filename in pairs(fileNameTbl) do
		local file = io.open(filename, "r")
		for line in file:lines() do
		-- Multi locales can exist in the same line, use a loop instead
			local left,right,flag = 1
			repeat
				flag = 0
				for _,pattern in ipairs(localePatternT) do
					local l,r = strfind(line,pattern,left)
					if l then
						left,right = l,r
						tbl[strmatch(line,pattern,left)] = filename
						left = right + 1
						flag = 1
						break
					end
				end
			until flag == 0
		end
		file:close()
	end
	return tbl
end

-- locale keys found in lua source files, [key] = filename
local codeKey = matchKey(codefilenameT)

-- locale keys found in locale files, [key] = filename
local localeKey = matchKey(localefilenameT)

-- Output
local count = 0
for key,filename in pairs(codeKey) do
	if not localeKey[key] then
		print("Unlocalized Key \t"..key.."\t in code file: "..filename)
		count = count + 1
	end
end
for key,filename in pairs(localeKey) do
	if not codeKey[key] then
		print("Unused Key \t"..key.."\t in locale file: "..filename)
		count = count + 1
	end
end
if count == 0 then
	print("No unused key found!")
else
	print("Found "..count.."!")
end