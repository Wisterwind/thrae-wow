
local _G = getfenv(0)
local L = _G.PerfectTargetsLocale
local PerfectTargets = _G.PerfectTargets

local lname

local function MsgReport(obj, value, changed)
	if not name then return end
	if value == nil then
		value = "|cFFFF3333" .. L["Off"] .. "|r"
	elseif value and type(value) == "boolean" then
		value = "|cFF33FF33" .. L["On"] .. "|r"
	end

	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99"..lname.."|r: [|cFF9999FF" .. obj ..  "|r] " .. (changed and L["is now"] or L["is currently"]) .. " [|cFFFFFF33" .. value .. "|r]")
end

local function MsgError(obj)
	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99"..lname.."|r: " .. L["invalid entry for"] .. " [|cFF4455FF" .. obj ..  "|r].")
end

local function SanatizeUsage(opt1, desc, type)
	if not opt1 or not desc then return end
	if type then
		return "|cFF9999FF" .. opt1 .. "|r <" .. type .. "> - " .. desc
	end

	return "|cFF9999FF" .. opt1 .. "|r - " .. desc
end

function PerfectTargets:ToggleFrameLock()
	self.db.profile.locked = not self.db.profile.locked or nil
	MsgReport(L["locked_desc"], self.db.profile.locked, true)

	if not self.loaded then return end
	self.mainframe:EnableMouse(not self.db.profile.locked)
	self.mainframe:SetMovable(not self.db.profile.locked)
end

function PerfectTargets:SetBaseRate(v)
	v = tonumber(v)
	if not v then MsgReport(L["baserate_desc"], self.db.profile.baserate)
	elseif v <= 0 then MsgError(L["baserate"])
	else
		self.db.profile.baserate = v
		MsgReport(L["baserate_desc"], self.db.profile.baserate, true)
		if not self.loaded or self.onstandby or self.asleep then return end
		metro:Unregister("PerfectTargetsMain")
		metro:Register(self, "PerfectTargetsMain", "UpdateFrames", self.db.profile.baserate)
	end
end

function PerfectTargets:SetMaxFrames(v)
	v = tonumber(v)
	if not v then MsgReport(L["maxframes_desc"], self.db.profile.maxframes)
	elseif v <= 0 then MsgError(L["maxframes"])
	else
		self.db.profile.maxframes = v
		MsgReport(L["maxframes_desc"], self.db.profile.maxframes, true)
	end
end

function PerfectTargets:ToggleStandby()
	if not self.loaded then return end
	if self.onstandby or self.asleep then
		self:Wakeup()
	else
		self:Standby()
	end

	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99"..lname.."|r: " .. (self.onstandby and L["standing by."] or L["awake and ready."]))
end

function PerfectTargets:ResetDB()
	self.db:ResetDB()
	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99"..lname.."|r: " .. L["Your saved options are now reset."])
end

function PerfectTargets:InitializeOptions()
	local name, title, notes = GetAddOnInfo("PerfectTargets")
	if not name or title or notes then return end
	lname = title

	self.cmds = self:InitializeSlashCommand(notes, string.upper(name), string.upper(L["_name"]), string.lower(L["_name"]), L["slash2"])

	self.cmds:RegisterSlashHandler( SanatizeUsage(L["reset"], L["reset_desc"]), L["reset"], "ResetDB")
	self.cmds:RegisterSlashHandler( SanatizeUsage(L["standby"], L["standby_desc"]), L["standby"], "ToggleStandby")
	self.cmds:RegisterSlashHandler( SanatizeUsage(L["locked"], L["locked_desc"]), L["locked"], "ToggleFrameLock")
	self.cmds:RegisterSlashHandler( SanatizeUsage(L["baserate"], L["baserate_desc"], L["number"]), L["baserate"] .. "%s?(%d*)$", "SetBaseRate")
	self.cmds:RegisterSlashHandler( SanatizeUsage(L["maxframes"], L["maxframes_desc"], L["number"]), L["maxframes"] .. "%s?(%d*)$", "SetMaxFrames")
end

