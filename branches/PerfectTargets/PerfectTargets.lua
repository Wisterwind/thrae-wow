-- Core File

local _G = getfenv(0)
local PerfectTargetsLocale = _G.PerfectTargetsLocale

local metro = DongleStub("MetrognomeNano-Beta0")

local maxbuffs, maxdebuffs = 32, 40
local framecount, delaycount, numtargets = 0
local targets, targetcounts, tanks, tankstrings 

local _

PerfectTargets = DongleStub("Dongle-Beta0"):New("PerfectTargets")

--[[-------------------------------------------------------
-- Local Functions
----------------------------------------------------------]]

local function ValidTargetHostile(unitId)
	if not unitId or not UnitExists(unitId) or not UnitIsVisible(unitId) 
	or not UnitExists(unitId.."target") or UnitIsCivilian(unitId.."target") 
	or UnitIsDead(unitId.."target") or UnitIsCorpse(unitId.."target")
	or not UnitCanAttack("player", unitId.."target")
	or not UnitIsVisible(unitId.."target") then return false end

	return true
end

local function ValidTargetHealer(unitId)
	if not unitId or not UnitExists(unitId) or not UnitIsVisible(unitId) 
	or not UnitExists(unitId.."target") or not UnitPlayerControlled(unitId.."target")
	or UnitIsDead(unitId.."target") or UnitIsCorpse(unitId.."target")
	or UnitCanAttack("player", unitId.."target")
	or not UnitIsVisible(unitId.."target") then return false end

	return true
end

local ValidTarget = ValidTargetHostile

local function UnitStatus(unit)
	local status
	for i=1,maxdebuffs do
		status = PerfectTargetsLocale[UnitDebuff(unit, i)]
		if status then
			return (status == 2 and status) or 1
		end
	end
end

local function CheckForDups(goodt,tuid)
	for j,t in pairs(targets) do
		if t ~= goodt then
			if not ValidTarget(t.unit) or UnitIsUnit(tuid,t.unit.."target") then
				return FixTargets(j)
			end
		end
	end
	return true
end

local function FixTargets(i,tuid)
	local substitute
	targets[i][ targets[i].unit ] = nil
	targets[i].unit = nil
	if tuid then 
		targets[i].unit = tuid
		substitute = true
	else
		for u,_ in pairs(targets[i]) do
			if u ~= "unit" and u ~= "num" then
				if ValidTarget(u) then
					targets[i].unit = u
					tuid = u.."target"
					substitute = true
					break
				else
					targets[i][u] = nil
				end
			end
		end
	end
	if not substitute then
		table.remove(targets, i)
		numtargets = numtargets - 1
		return false
	else
		CheckForDups(targets[i],tuid)
	end

	targets[i].num = targets[i].num - 1
	return true
end


--[[-------------------------------------------------------
-- Perfect Targets Target Frame
---------------------------------------------------------]]

local ptframe = {
	offset = -2,
	barheight = 7,

	colors = {
		tank = {0,0.7,0.7},
		green = {0,1,0},
		duptank = {1,0.7,1},
		yellow = {1,1,0},
		red = {1,0,0},
		dkred = {0.5,0,0},
		grey = {0.5,0.5,0.5},
		white = {1,1,1},
	},
}

function ptframe:CreateAnchorFrame(mainframe)
	if not mainframe then return end

	local t = CreateFrame("Button", nil, mainframe)
	t:Hide()

	t.MyTarget = t:CreateFontString(nil, "ARTWORK")
	t.MyTarget:SetFontObject(GameFontHighlightSmall)
	t.MyTarget:SetText(">")
	t.MyTarget:SetPoint("BOTTOMLEFT", mainframe, "TOPLEFT")

	t.RaidIcon = t:CreateTexture(nil, "ARTWORK")
	t.RaidIcon:SetPoint("TOPLEFT", t.MyTarget, "TOPRIGHT")
	t.RaidIcon:SetPoint("BOTTOMLEFT", t.MyTarget, "BOTTOMRIGHT")
	t.RaidIcon:SetWidth(t.MyTarget:GetHeight())
	t.RaidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	SetRaidTargetIconTexture(t.RaidIcon, 1)

	t.Targetted = t:CreateFontString(nil, "ARTWORK")
	t.Targetted:SetFontObject(GameFontHighlightSmall)
	t.Targetted:SetText("40")
	t.Targetted:SetPoint("LEFT", t.RaidIcon, "RIGHT")

	t.PetTarget = t:CreateFontString(nil, "ARTWORK")
	t.PetTarget:SetFontObject(GameFontHighlightSmall)
	t.PetTarget:SetText("<")
	t.PetTarget:ClearAllPoints()
	t.PetTarget:SetPoint("LEFT", t.Targetted, "RIGHT")

	t.MobName = t:CreateFontString(nil, "ARTWORK")
	t.MobName:SetFontObject(GameFontHighlightSmall)
	t.MobName:SetText("*Unknown*")
	t.MobName:SetJustifyH("RIGHT")
	t.MobName:SetPoint("LEFT", t.PetTarget, "RIGHT", 2, 0)
	self.namewidth = t.MobName:GetStringWidth()
	self.defaultnamewidth = self.namewidth
	self.minwidth = t.minwidth

	t.Bar = CreateFrame("StatusBar", nil, t)
	t.Bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	t.Bar:SetMinMaxValues(0,100)
	t.Bar:ClearAllPoints()
	t.Bar:SetPoint("LEFT", t.MobName, "RIGHT", 5, 0)
	t.Bar:SetWidth(60)
	t.Bar:SetHeight(self.barheight)

	t.HPP = t:CreateFontString(nil, "ARTWORK")
	t.HPP:SetFontObject(GameFontHighlightSmall)
	t.HPP:SetText("100%")
	t.HPP:ClearAllPoints()
	t.HPP:SetPoint("LEFT", t.Bar, "RIGHT", 5, 0)

	t.Tanks = t:CreateFontString(nil, "ARTWORK")
	t.Tanks:SetFontObject(GameFontHighlightSmall)
	t.Tanks:SetText("X")
	t.Tanks:ClearAllPoints()
	t.Tanks:SetPoint("LEFT", t.HPP, "RIGHT", 5, 0)
	self.tankwidth = t.Tanks:GetStringWidth()
	self.defaulttankwidth = self.tankwidth

	t:SetPoint("TOPLEFT", t.MyTarget, "TOPLEFT")
	t:SetPoint("BOTTOMRIGHT", t.Tanks, "BOTTOMRIGHT")

	self.anchorframe = t
	return t
end


function ptframe:CreateTargetFrame(i, mainframe, anchor)
	if not i or not mainframe or not anchor then return end
	local t = CreateFrame("Button", nil, mainframe)
	t:Hide()

	t.Targetted = t:CreateFontString(nil, "ARTWORK")
	t.Targetted:SetFontObject(GameFontHighlightSmall)
	t.Targetted:SetText("40")
	t.Targetted:SetTextColor(1,1,1)
	t.Targetted:SetJustifyH("CENTER")
	t.Targetted:SetPoint("TOPLEFT", anchor.Targetted, "BOTTOMLEFT", 0, self.offset)
	t.Targetted:SetPoint("TOPRIGHT", anchor.Targetted, "BOTTOMRIGHT", 0, self.offset)
	t.Targetted:Show()

	t.RaidIcon = t:CreateTexture(nil, "ARTWORK")
	t.RaidIcon:SetPoint("TOPLEFT", anchor.RaidIcon, "BOTTOMLEFT")
	t.RaidIcon:SetPoint("BOTTOMRIGHT", t.Targetted, "BOTTOMLEFT")
	t.RaidIcon:SetWidth(t.RaidIcon:GetHeight())
	t.RaidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	SetRaidTargetIconTexture(t.RaidIcon, 0)
	t.RaidIcon:Show()

	t.MyTarget = t:CreateFontString(nil, "ARTWORK")
	t.MyTarget:SetFontObject(GameFontHighlightSmall)
	t.MyTarget:SetText(">")
	t.MyTarget:SetJustifyH("RIGHT")
	t.MyTarget:SetPoint("RIGHT", t.RaidIcon, "LEFT")
	t.MyTarget:Show()

	t.PetTarget = t:CreateFontString(nil, "ARTWORK")
	t.PetTarget:SetFontObject(GameFontHighlightSmall)
	t.PetTarget:SetText("<")
	t.PetTarget:SetJustifyH("LEFT")
	t.PetTarget:SetTextColor(1,0,0)
	t.PetTarget:SetPoint("LEFT", t.Targetted, "RIGHT")
	t.PetTarget:Show()

	t.MobName = t:CreateFontString(nil, "ARTWORK")
	t.MobName:SetFontObject(GameFontHighlightSmall)
	t.MobName:SetText("Unknown")
	t.MobName:SetJustifyH("RIGHT")
	t.MobName:SetPoint("TOPLEFT", anchor.MobName, "BOTTOMLEFT", 0, self.offset)
	t.MobName:SetPoint("TOPRIGHT", anchor.MobName, "BOTTOMRIGHT", 0, self.offset)
	t.MobName:Show()

	t.HPP = t:CreateFontString(nil, "ARTWORK")
	t.HPP:SetFontObject(GameFontHighlightSmall)
	t.HPP:SetJustifyH("RIGHT")
	t.HPP:ClearAllPoints()
	t.HPP:SetPoint("TOPLEFT", anchor.HPP, "BOTTOMLEFT", 0, self.offset)
	t.HPP:SetPoint("TOPRIGHT", anchor.HPP, "BOTTOMRIGHT", 0, self.offset)
	t.HPP:Show()

	t.Tanks = t:CreateFontString(nil, "ARTWORK")
	t.Tanks:SetFontObject(GameFontHighlightSmall)
	t.Tanks:SetJustifyH("LEFT")
	t.Tanks:ClearAllPoints()
	t.Tanks:SetPoint("TOP", t.HPP, "TOP")
	t.Tanks:SetPoint("LEFT", anchor.Tanks, "LEFT", 0, self.offset)
	t.Tanks:SetPoint("RIGHT", anchor.Tanks, "RIGHT", 0, self.offset)
	t.Tanks:Show()

	t.Bar = CreateFrame("StatusBar", nil, t)
	t.Bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	t.Bar:SetMinMaxValues(0,100)
	t.Bar:ClearAllPoints()
	t.Bar:SetPoint("LEFT", t.MobName, "RIGHT", 5, 0)
	t.Bar:SetPoint("RIGHT", t.HPP, "LEFT", -5, 0)
	t.Bar:SetHeight(self.barheight)
	t.Bar:Show()

	t:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
	t:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT")
	t:SetPoint("BOTTOM", t.MobName, "BOTTOM")

	t:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
		edgeFile = "", edgeSize = 0,
		insets = {left = 0, right = -2, top = 0, bottom = -2},
		})

	return t
end


function ptframe:OnEnter()
	this.hover = true
end


function ptframe:OnLeave()
	this.hover = nil
end


function ptframe:UpdateTargetFrame(frame, unit, tank, targCount, hpp, duptank, tankstring, resetwidth)
	if not frame then return end
	frame.unit = unit
	frame.tank = tank
	local mobname = frame.hover and tank and UnitName(tank) or unit and UnitName(unit) or "*Unknown*"
	local oldname = frame.MobNameText
	self:UpdateFrameText(frame, "MyTarget", unit and UnitIsUnit("target", unit) and ">" or "")
	self:UpdateFrameText(frame, "PetTarget", unit and UnitIsUnit("pettarget", unit) and not duptank and "<" or "")
	self:UpdateFrameText(frame, "Targetted", not duptank and targCount or "-")
	self:UpdateFrameText(frame, "MobName", mobname, isfocus)
	self:UpdateFrameText(frame, "HPP", hpp and string.format("%d%%", hpp) or "")
	self:UpdateFrameText(frame, "Tanks", tankstring or "")
	self:UpdateFrameIcon(frame, unit and GetRaidTargetIndex(unit) or 0)

	self:UpdateMobNameWidth(frame.MobName:GetStringWidth()*UIParent:GetScale(), resetwidth)
	self:UpdateTankNameWidth(frame.Tanks:GetStringWidth()*UIParent:GetScale(), resetwidth)

	if frame.hpp ~= (hpp or 0) then
		frame.hpp = hpp or 0
		frame.Bar:SetStatusBarColor(self:GetHPSeverity(nil, (hpp or 0)/100, 1))
		frame.Bar:SetValue(hpp or 0)
	end

	if frame.shown ~= (unit ~= nil) then
		frame.shown = (unit ~= nil)
		if frame.shown then frame:Show() else frame:Hide() end
	end
end


function ptframe:UpdateFrameText(frame, elem, newtext)
	if not frame or not elem or not frame[elem] then return end
	if frame[elem.."Text"] == newtext then return end
	frame[elem.."Text"] = newtext
	frame[elem]:SetText(newtext)
end


function ptframe:UpdateFrameIcon(frame, newidx)
	if not frame or not frame.RaidIcon then return end
	if frame.RaidIconIdx == newidx then return end

	frame.RaidIconIdx = newidx
	SetRaidTargetIconTexture(frame.RaidIcon, newidx)
end


function ptframe:UpdateTargetFrameColors(frame, tot, playercombat, isfriend, unitcombat, status)
	self:UpdateFrameTextColor(frame, "MyTarget", playercombat and self.colors.red or self.colors.white)
	self:UpdateFrameTextColor(frame, "MobName",
		(frame.hover and frame.tank or frame.unit and frame.tank and frame.unit == frame.tank) and self.colors.tank
		or UnitIsFriend(frame.unit, "player") and self.colors.green
		or status == 1 and self.colors.yellow
		or frame.tank and unitcombat and not tot and not UnitIsDead(frame.unit) and not UnitIsCorpse(frame.unit) and self.colors.duptank
		or status == 2 and unitcombat and self.colors.red
		or status == 2 and self.colors.dkred
		or unitcombat and self.colors.white or self.colors.grey)
end


function ptframe:UpdateFrameTextColor(frame, elem, color)
	if not frame or not elem or not frame[elem] or not color then return end
	if frame[elem.."Color"] == color then return end

	frame[elem.."Color"] = color
	frame[elem]:SetTextColor(color[1], color[2], color[3])
end


function ptframe:UpdateMobNameWidth(newwidth, reset)
	if reset or newwidth > self.namewidth then
		local neww = math.max(reset and 0 or self.namewidth, newwidth, self.defaultnamewidth)
		self.anchorframe.MobName:SetWidth(neww)
		self.namewidth = neww
	end
end


function ptframe:UpdateTankNameWidth(newwidth, reset)
	if reset or newwidth > self.tankwidth then
		local neww = math.max(reset and 1 or self.tankwidth, newwidth, self.defaulttankwidth)
		self.anchorframe.Tanks:SetWidth(neww)
		self.tankwidth = neww
	end
end


function ptframe:GetHPSeverity(unit, percent, smooth)
	if (percent<=0) or (percent > 1.0) then return 0.35, 0.35, 0.35 end

	if smooth then
		if percent >= 0.5 then return (1.0-percent)*2, 1.0, 0.0
		else return 1.0, percent*2, 0.0 end
	else return 0, 1, 0 end
end


--[[-------------------------------------------------------
-- Frame Manipulation
----------------------------------------------------------]]

------------------------------------
--      Target Frame Methods      --
------------------------------------

function PerfectTargets:CreateTargetFrame(i)
	if not i or i > self.db.profile.maxframes then return end
	if framecount < i then framecount = i end
	self.frames[i] = ptframe:CreateTargetFrame(i, self.mainframe, (i > 1) and self.frames[i-1] or self.anchorframe)
	return self.frames[i]
end

function PerfectTargets:UpdateUnitFrame(funit, frame, i, resetwidth)
	local unit = funit and funit.. "target"

	if not unit then ptframe:UpdateTargetFrame(frame)
	else
		if not ValidTarget(funit) then 
			if not FixTargets(i) then -- visability prune
				ptframe:UpdateTargetFrame(frame, funit, funit)
				ptframe:UpdateTargetFrameColors(frame)
				funit = nil
				local numframes = math.min(numtargets, self.db.profile.maxframes)
				if numframes > framecount then framecount = numframes end
			else
				funit = targets[i].unit
				unit = funit.."target"
			end
		end
		if funit then
			local isfriend = UnitIsFriend(unit, "player")
			local hp, hpmax = UnitHealth(unit), UnitHealthMax(unit)
			local numtext = targetcounts[i] or 0

			ptframe:UpdateTargetFrame(
					frame, 
					unit, 
					tanks[funit] and funit, 
					targetcounts[i], 
					(hpmax ~= 0) and math.floor((hp / hpmax) * 100) or 0, 
					duptank, 
					tankstrings[i],
					resetwidth)

			ptframe:UpdateTargetFrameColors(
					frame, 
					not isfriend and UnitIsUnit(unit.."target", funit),
					UnitAffectingCombat("player"), 
					isfriend, 
					not isfriend and UnitAffectingCombat(unit),
					not isfriend and UnitStatus(unit))
			if UnitExists("focus") and UnitIsUnit(funit, "focus") --and 
			   --ValidTarget("player") and not UnitIsUnit(unit, "playertarget") 
			   then
			   	self.FocusLeft:Show()
				self.FocusRight:Show()
			end

		end
		frame:Show()
	end
end

function PerfectTargets:UpdateFrames()
	self.FocusLeft:Hide()
	self.FocusRight:Hide()
	for i=1,framecount do
		self:UpdateUnitFrame(targets[i] and targets[i].unit, self.frames[i], i, i==1)
	end
	local targs = math.min(numtargets, self.db.profile.maxframes)
	self.mainframe:SetHeight(targs > 0 and targs*14 or 14)
end


----------------------------------
--      Main Frame Methods      --
----------------------------------

function PerfectTargets:SavePosition()
	local s = self.mainframe:GetEffectiveScale()
	self.db.profile.PosX = self.mainframe:GetLeft() * s
	self.db.profile.PosY = self.mainframe:GetTop() * s
end


function PerfectTargets:RestorePosition()
	local x = self.db.profile.PosX
	local y = self.db.profile.PosY
	if not x or not y then return end

	local s = self.mainframe:GetEffectiveScale()
	x, y = x/s, y/s
	self.mainframe:ClearAllPoints()
	self.mainframe:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

function PerfectTargets:CreateMainFrame()
	self.mainframe = CreateFrame("Frame", "PerfectTargetsFrame", UIParent)

	self.mainframe:EnableMouse(true)
	self.mainframe:SetMovable(true)
	self.mainframe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -150)
	self.mainframe:SetWidth(200)
	self.mainframe:SetHeight(14)

	self.anchorframe = ptframe:CreateAnchorFrame(self.mainframe)
	self.frames = {}
	setmetatable(self.frames, {__index = function(t,k) return PerfectTargets:CreateTargetFrame(k) end})

	self.headertext = self.mainframe:CreateFontString(nil, "ARTWORK")
	self.headertext:SetFontObject(GameFontHighlightSmall)
	self.headertext:ClearAllPoints()
	self.headertext:SetPoint("BOTTOM", self.anchorframe, "BOTTOM")
	self.headertext:SetText("Perfect Targets")
	self.headertext:Show()

	self.headerback = CreateFrame("Button", nil, UIParent)
	self.headerback.master = self.mainframe
	self.headerback:RegisterForDrag("LeftButton")
	self.headerback:SetScript("OnDragStart", function()
		if PerfectTargets.db.profile.framelocked then return end
		this.master:StartMoving()
		this.master.isMoving = true
	end)

	self.headerback:SetScript("OnDragStop", function()
		this.master:StopMovingOrSizing()
		this.master.isMoving = nil
		PerfectTargets:SavePosition()
	end)

	self.headerback:SetPoint("TOPLEFT", self.anchorframe, "TOPLEFT")
	self.headerback:SetPoint("BOTTOMRIGHT", self.anchorframe, "BOTTOMRIGHT")
	self.headerback:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
		edgeFile = "", edgeSize = 0,
		insets = {left = 0, right = -2, top = -2, bottom = -2},
		})
	self.headerback:Show()

	self.FocusLeft = self.mainframe:CreateFontString(nil, "ARTWORK")
	self.FocusLeft:SetFontObject(GameFontHighlightSmall)
	self.FocusLeft:SetText("|!|")
	self.FocusLeft:SetPoint("TOPRIGHT", self.anchorframe, "BOTTOMLEFT", -1, 0)
	self.FocusLeft:Hide()

	self.FocusRight = self.mainframe:CreateFontString(nil, "ARTWORK")
	self.FocusRight:SetFontObject(GameFontHighlightSmall)
	self.FocusRight:SetText("|!|")
	self.FocusRight:SetPoint("TOPLEFT", self.anchorframe, "BOTTOMRIGHT", 1, 0)
	self.FocusRight:Hide()
end

--[[-------------------------------------------------------
-- Events
----------------------------------------------------------]]

-- Updates the known target list
-- Note that targets[i].unit may or may not be valid due to visability issues.
-- UNIT_TARGET is not fired when a unit goes out of range then changes targets.
function PerfectTargets:UNIT_TARGET(event,unit)
	if (unit ~= "player" and UnitIsUnit(unit,"player")) or unit == "target" or unit == "focus" then return end

	local tuid = unit.."target"
	if ValidTarget(unit) then
		local knowntarget
		for i,t in pairs(targets) do
			if ValidTarget(t.unit) then
				if UnitIsUnit(tuid, t.unit.."target") then
					if CheckForDups(t, t.unit.."target") then
						t[unit] = true
						t.num = t.num + 1
						knowntarget = true
						if UnitIsUnit(unit, "focus") and i ~= 1 then
							table.insert(targets, 1, table.remove(targets, i) )
						end
						break
					end
				end
			else -- primary targetId became invalid due to visability issues
				FixTargets(i)
			end
		end

		if not knowntarget then
			numtargets = numtargets + 1
			if UnitIsUnit(unit, "focus") then
				table.insert(targets, 1, { [unit] = true, ["unit"] = unit, ["num"] = 1 } )
			else
				table.insert(targets, { [unit] = true, ["unit"] = unit, ["num"] = 1 } )
			end
		end
	else -- unit now has a non-valid target
		for i,t in pairs(targets) do
			if t.unit == unit then
				FixTargets(i)
			elseif t[unit] then
				t[unit] = nil
				t.num = t.num - 1
			end
		end
	end

	local numframes = math.min(numtargets, self.db.profile.maxframes)
	if numframes > framecount then framecount = numframes end
	self:UpdateFrames()
end

function PerfectTargets:ResetFrames()
	delaycount, numtargets = 0, 0
	targets, targetcounts, tanks, tankstrings = {}, {}, {}, {}
	self:UpdateFrames()
end

--[[-------------------------------------------------------
-- Standby Modes
----------------------------------------------------------]]

-- Called when coming out of Standby or first initialization.
function PerfectTargets:ReInitialize()
	self:UnregisterAllEvents()

	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "ResetFrames")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "ResetFrames")

	metro:Start("PerfectTargetsMain")

	self:RestorePosition()
	self.mainframe:Show()
	self.headerback:Show()

	delaycount, numtargets = 0, 0
	targets, targetcounts, tanks, tankstrings = {}, {}, {}, {}
	self.asleep = nil
end

function PerfectTargets:Sleep()
	self:UnregisterAllEvents()
	metro:Stop("PerfectTargetsMain")
	self.mainframe:Hide()
	self.headerback:Hide()

	self.asleep = true
	delaycount, numtargets = nil,nil
	targets, targetcounts, tanks, tankstrings = nil,nil,nil,nil
end

function PerfectTargets:Wakeup()
	self:ReInitialize()
end

function PerfectTargets:Standby()
	self:Sleep()
end

--[[-------------------------------------------------------
-- Dongle Initialization
----------------------------------------------------------]]

function PerfectTargets:Initialize()
	self.defaults = {
		profile = {
			numinitials = 1,
			maxframes = 10,
			baserate = 0.25,
		},
	}

	self.db = self:InitializeDB("PerfectTargetsDB", self.defaults)
	metro:Register(self, "PerfectTargetsMain", "UpdateFrames", self.db.profile.rate)

	self:CreateMainFrame()

	self:ReInitialize()
end

--[[
function PerfectTargets:Enable()
end
--]]
