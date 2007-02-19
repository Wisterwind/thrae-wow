
local _G = getfenv(0)
local L = _G.PerfectTargetsLocale
local PerfectTargets = _G.PerfectTargets
local InitializeOptions, RegisterSlashHandler, MsgReport, MsgError = ThraeOptions_GetTemplate()

function PerfectTargets:ToggleFrameLock()
	self.db.profile.locked = not self.db.profile.locked or nil
	MsgReport(self, L["locked_desc"], self.db.profile.locked, true)

	if not self.loaded then return end
	self.mainframe:EnableMouse(not self.db.profile.locked)
	self.headerback:EnableMouse(not self.db.profile.locked)
end

function PerfectTargets:ToggleEmergencyName()
	self.db.profile.emergencyname = not self.db.profile.emergencyname or nil
	MsgReport(self, L["emergencyname_desc"], self.db.profile.emergencyname, true)
end

function PerfectTargets:SetBaseRate(v)
	v = tonumber(v)
	if not v then MsgReport(self, L["baserate_desc"], self.db.profile.baserate)
	elseif v <= 0 then MsgError(self, L["baserate"])
	else
		self.db.profile.baserate = v
		MsgReport(self, L["baserate_desc"], self.db.profile.baserate, true)
		if not self.loaded or self.onstandby or self.asleep then return end
		metro:Unregister("PerfectTargetsMain")
		metro:Register(self, "PerfectTargetsMain", "UpdateFrames", self.db.profile.baserate)
	end
end

function PerfectTargets:SetMaxFrames(v)
	v = tonumber(v)
	if not v then MsgReport(self, L["maxframes_desc"], self.db.profile.maxframes)
	elseif v <= 0 then MsgError(self, L["maxframes"])
	else
		self.db.profile.maxframes = v
		MsgReport(self, L["maxframes_desc"], self.db.profile.maxframes, true)
	end
end

function PerfectTargets:InitializeOptions()
	InitializeOptions(self, "PerfectTargets", L["slash2"])

	RegisterSlashHandler(self, "ToggleFrameLock", L["locked"], L["locked_desc"], nil, L["slash2"])
	RegisterSlashHandler(self, "SetBaseRate", L["baserate"], L["baserate_desc"], " (d+)", L["slash2"], "number")
	RegisterSlashHandler(self, "SetMaxFrames", L["maxframes"], L["maxframes_desc"], " (d+)", L["slash2"], "number")
	RegisterSlashHandler(self, "ToggleEmergencyName", L["emergencyname"], L["emergencyname_desc"], nil, L["slash2"])
end

