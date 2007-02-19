-- My Options Template for Dongle usage

if ThraeOptions_GetTemplate then return end

--[[------------------------------------
-- Start Localizations
--------------------------------------]]

-- default
local L = {
	-- default options
	["reset"] = "reset",
	["reset_desc"] = "Reset all options",
	["standby"] = "standby",
	["standby_desc"] = "Toggle standby mode",

	-- report
	["On"] = "On",
	["Off"] = "Off",
	["standing by."] = "standing by.",
	["awake and ready."] = "awake and ready.",
	["Your saved options are now reset."] = "Your saved options are now reset.",

	-- helpers
	["is now"] = "is now",
	["is currently"] = "is currently",
	["invalid entry for"] = "invalid entry for",
	["number"] = "number",
}

--[[------------------------------------
-- End Localizations
--------------------------------------]]

--[[------------------------------------
-- Start Local Functions
--------------------------------------]]

local function Standby(obj)
	if not obj.loaded then return end
	if obj.onstandby or obj.asleep then
		obj:Wakeup()
	else
		obj:Standby()
	end

	obj:Print(obj.onstandby and L["standing by."] or L["awake and ready."])
end

local function ResetDB(obj)
	obj.db:ResetDB()
	obj:Print(L["Your saved options are now reset."])
end

local function MsgReport(obj, item, value, changed)
	if value == nil then
		value = "|cFFFF3333" .. L["Off"] .. "|r"
	elseif value and type(value) == "boolean" then
		value = "|cFF33FF33" .. L["On"] .. "|r"
	end

	obj:Print("[|cFF9999FF" .. item ..  "|r] " .. (changed and L["is now"] or L["is currently"]) .. " [|cFFFFFF33" .. value .. "|r]")
end

local function MsgError(obj, item)
	obj:Print(L["invalid entry for"] .. " [|cFF4455FF" .. item ..  "|r].")
end

local function RegisterSlashHandler(obj, handler, opt, desc, pattern, slash, type)
	obj.cmds:RegisterSlashHandler("/" .. slash .. "|cFF9999FF " .. opt .. 
					((L[type] and "|r <" .. L[type] .. "> - ") or "|r - ") .. desc,
					pattern and (opt .. pattern) or opt,
					handler)
end

local function InitializeOptions(obj, name, slash, ...)
	local _,title,desc = GetAddOnInfo(name)
	obj.cmds = obj:InitializeSlashCommand(desc, string.upper(name), string.upper(title), string.lower(title), slash, ...)

	RegisterSlashHandler(obj, function() Standby(obj) end, L["standby"], L["standby_desc"], nil, slash)
	RegisterSlashHandler(obj, function() ResetDB(obj) end, L["reset"], L["reset_desc"], nil, slash)
end

--[[------------------------------------
-- End Local Functions
--------------------------------------]]

-- get instance
function ThraeOptions_GetTemplate()
	return InitializeOptions, RegisterSlashHandler, MsgReport, MsgError
end

