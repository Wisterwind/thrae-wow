--[[
-- Name: PerfectAssist
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date: 1-27-07
--]]

local _G = getfenv(0)
local PerfectRaidTargetFrame = _G.PerfectAssistTargetFrame
local PerfectAssistLocale = _G.PerfectAssistLocale

local metro = DongleStub("MetrognomeNano-Beta0")
PerfectAssist = DongleStub("Dongle-Beta0"):New("PerfectAssist")
-- PerfectAssist.rev = tonumber(string.match("$Revision: $", "(%d+)") or 1)

local PerfectAssist = _G.PerfectAssist
local assistId, oldPTarg, raidNum, partyNum

-- This updates old versions of PerfectTargets on UNIT_TARGET as well as its periodic for assistId only.
if IsAddOnLoaded("PerfectTargets") then
	local meta = GetAddOnMetadata("PerfectTargets", "Version")
	if meta == "2.0" then
		oldPTarg = true
	end
end

--[[-------------------------------------------------------
-- Local Functions
----------------------------------------------------------]]

local function ValidTarget(unitId)
	if not unitId or not UnitExists(unitId) or not UnitIsVisible(unitId) 
	or not UnitExists(unitId.."target") or UnitIsCivilian(unitId.."target") 
	or UnitIsDead(unitId.."target") or UnitIsCorpse(unitId.."target")
	or not UnitCanAttack("player", unitId.."target")
	or not UnitIsVisible(unitId.."target") then return false end

	return true
end

local function UnitStatus(unit)
	local status
	for i=1,maxdebuffs do
		status = PerfectAssistLocale[UnitDebuff(unit, i)]
		if status then
			return (status == 2 and status) or true
		end
	end
end

local function SetAutoAssistId(uid, c, ac)
	if ac and ac == "ROGUE" then return ac end
	if not ac or c == "ROGUE" or c == "MAGE" or (c == "WARLOCK" and ac ~= "MAGE") or
	(c == "HUNTER" and not (ac == "MAGE" and ac == "WARLOCK") ) or
	(c == "WARRIOR" and not (ac == "MAGE" or ac == "WARLOCK" or ac == "HUNTER") ) or
	(c == "SHAMAN" and not (ac == "MAGE" or ac == "WARLOCK" or ac == "HUNTER" or ac == "WARRIOR") ) or
	(c == "PALADIN" and not (ac == "MAGE" or ac == "WARLOCK" or ac == "HUNTER" or 
				ac == "WARRIOR" or ac == "SHAMAN") ) or
	(c == "DRUID" and not (ac == "MAGE" or ac == "WARLOCK" or ac == "HUNTER" or 
				ac == "WARRIOR" or ac == "SHAMAN" or ac == "PALADIN" ) ) or
	(c == "PRIEST" and not (ac == "MAGE" or ac == "WARLOCK" or ac == "HUNTER" or 
					ac == "WARRIOR" or ac == "SHAMAN" or ac == "PALADIN" or ac == "DRUID" ) )  then
		--
		assistId = uid
		ac = c
		--
	end

	return ac
end

local function SetClick()
	if not UnitAffectingCombat("player") then
		if assistId then
			self.aframe:SetAttribute("unit", assistId)
			self.aframe:SetAttribute("type1", "assist")
			self.anchorframe:SetAttribute("unit", assistId)
			self.anchorframe:SetAttribute("type1", "assist")
		else
			self.aframe:SetAttribute("type1", ATTRIBUTE_NOOP)
			self.anchorframe:SetAttribute("type1", ATTRIBUTE_NOOP)
		end
	end
end

--[[-------------------------------------------------------
-- Frame Manipulation
----------------------------------------------------------]]

function PerfectAssist:SavePosition()
	local s = self.mainframe:GetEffectiveScale()
	self.db.profile.PosX = self.mainframe:GetLeft() * s
	self.db.profile.PosY = self.mainframe:GetTop() * s
end


function PerfectAssist:RestorePosition()
	local x = self.db.profile.PosX
	local y = self.db.profile.PosY
	if not x or not y then return end

	local s = self.mainframe:GetEffectiveScale()
	x, y = x/s, y/s
	self.mainframe:ClearAllPoints()
	self.mainframe:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

function PerfectAssist:UpdateAssistFrame()
	if ValidTarget(assistId) then
		local atarget = assistId.."target"
		local numtargets = 0
		local uid, tuid
		if raidNum > 0 then
			for i = 1,raidNum do
				uid = "raid"..i
				tuid = "raid"..i.."target"
				if ValidTarget(uid) and UnitIsUnit(atarget, tuid) then
					numtargets = numtargets + 1
				end
				uid = "raidpet"..i
				tuid = "raidpet"..i.."target"
				if ValidTarget(uid) and UnitIsUnit(atarget, tuid) then
					numtargets = numtargets + 1
				end
			end
		elseif partyNum > 0 then
			for i = 1,partyNum do
				uid = "party"..i
				tuid = "party"..i.."target"
				if ValidTarget(uid) and UnitIsUnit(atarget, tuid) then
					numtargets = numtargets + 1
				end
				uid = "partypet"..i
				tuid = "partypet"..i.."target"
				if ValidTarget(uid) and UnitIsUnit(atarget, tuid) then
					numtargets = numtargets + 1
				end
			end
		end

		local isfriend = UnitIsFriend(atarget, "player")
		local ucombat = not isfriend and UnitAffectingCombat(atarget)
		local status = not isfriend and UnitStatus(atarget)
		local hp, hpmax = UnitHealth(atarget), UnitHealthMax(atarget)
		local hpp = ((hpmax ~= 0) and math.floor((hp / hpmax) * 100)) or 0

		PerfectAssistTargetFrame:UpdateTargetFrame(self.aframe, atarget, numtargets, hpp, true)
		PerfectAssistTargetFrame:UpdateTargetFrameColors(self.aframe, UnitAffectingCombat("player"), isfriend, ucombat, status)
		self.aframe:Show()
	elseif not assistId then
		PerfectAssistTargetFrame:UpdateTargetFrame(self.aframe)
	elseif not UnitExists(assistId.."target") then
		PerfectAssistTargetFrame:UpdateTargetFrame(self.aframe, assistId, assistId)
		PerfectAssistTargetFrame:UpdateTargetFrameColors(self.aframe)
		self.aframe:Show()
	end
end

--[[-------------------------------------------------------
-- Events
----------------------------------------------------------]]

function PerfectAssist:UNIT_TARGET(unitId)
	if unitId == assistId then
		if oldPTarg and PerfectTargets then PerfectTargets:PerfectTargets_UpdateAllTargets() end
		self:UpdateAssistFrame()
	end
end

function PerfectAssist:PARTY_MEMBERS_CHANGED()
	partyNum = GetNumPartyMembers()
	raidNum = GetNumRaidMembers() 
	if raidNum == 0 and partyNum > 0 then
		if self.asleep then self:Wakeup() end
		local uid,c,ac
		for i = 1,partyNum do
			uid="party"..i
			if self.db.profile.savedAssist and 
			self.db.profile.savedAssist == UnitName(uid) then
				assistId = uid
				SetClick()
				return
			elseif self.db.profile.auto then
				_,c = UnitClass(uid)
				ac = SetAutoAssistId(uid, c, ac)
			end
		end
		self.db.profile.savedAssist = UnitName(assistId)
		SetClick()
	elseif raidNum == 0 and partyNum == 0 then
		self:Sleep()
	end
end

function PerfectAssist:RAID_ROSTER_UPDATE()
	partyNum = GetNumPartyMembers()
	raidNum = GetNumRaidMembers() 
	if raidNum > 0 then
		if self.asleep then self:Wakeup() end
		local uid,name,c,ac
		for i = 1,raidNum do
			uid="raid"..i
			name,_,_,_,c = GetRaidRosterInfo(i)
			if self.db.profile.savedAssist and 
			self.db.profile.savedAssist == name then
				assistId = uid
				SetClick()
				return
			elseif self.db.profile.auto then
				ac = SetAutoAssistId(uid, c, ac)
			end
		end
		self.db.profile.savedAssist = UnitName(assistId)
		SetClick()
	elseif partyNum == 0 then
		self:Sleep()
	end
end

function PerfectAssist:PLAYER_REGEN_DISABLED()
	if self.asleep then
		self.mainframe:Hide()
		self.headerback:Hide()
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	elseif assistId and self.aframe:GetAttribute("unit") ~= assistId then
		SetClick() 
	end
end

--[[-------------------------------------------------------
-- Standby Modes
----------------------------------------------------------]]

-- Called when coming out of Standby or first initialization.
function PerfectAssist:ReInitialize()
	self:UnregisterAllEvents()

	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")

	metro:Start("PerfectAssistMain")

	self.mainframe:Show()
	self.headerback:Show()

	partyNum = GetNumPartyMembers()
	raidNum = GetNumRaidMembers()

	self.asleep = nil
	--self:PARTY_MEMBERS_CHANGED()
end

function PerfectAssist:Sleep()
	self:UnregisterEvent("UNIT_TARGET")
	metro:Stop("PerfectAssistMain")
	if not UnitAffectingCombat("player") then 
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self.mainframe:Hide()
		self.headerback:Hide()
	end

	self.asleep = true
end

function PerfectAssist:Wakeup()
	self:ReInitialize()
end

function PerfectAssist:Standby()
	self:Sleep()
	self:UnregisterAllEvents()
end

--[[-------------------------------------------------------
-- Dongle Initialization
----------------------------------------------------------]]

function PerfectAssist:Initialize()
	self.defaults = {
		profile = {
			auto=true,
			rate=1
		},
	}
	
	self.mainframe = CreateFrame("Frame", "PerfectAssistFrame", UIParent)

	self.mainframe:EnableMouse(true)
	self.mainframe:SetMovable(true)
	self.mainframe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -150)
	self.mainframe:SetWidth(200)
	self.mainframe:SetHeight(14)

	self.anchorframe = PerfectAssistTargetFrame:CreateAnchorFrame(self.mainframe)

	self.headertext = self.mainframe:CreateFontString(nil, "ARTWORK")
	self.headertext:SetFontObject(GameFontHighlightSmall)
	self.headertext:ClearAllPoints()
	self.headertext:SetPoint("BOTTOM", self.anchorframe, "BOTTOM")
	self.headertext:SetText("Perfect Assist")
	self.headertext:Show()

	self.headerback = CreateFrame("Button", nil, UIParent)
	self.headerback.master = self.mainframe
	self.headerback:RegisterForDrag("LeftButton")
	self.headerback:SetScript("OnDragStart", function()
		if db and PerfectAssist.db.profile.framelocked then return end
		this.master:StartMoving()
		this.master.isMoving = true
	end)

	self.headerback:SetScript("OnDragStop", function()
		this.master:StopMovingOrSizing()
		this.master.isMoving = nil
		PerfectAssist:SavePosition()
	end)

	self.headerback:SetPoint("TOPLEFT", self.anchorframe, "TOPLEFT")
	self.headerback:SetPoint("BOTTOMRIGHT", self.anchorframe, "BOTTOMRIGHT")
	self.headerback:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
		edgeFile = "", edgeSize = 0,
		insets = {left = 0, right = -2, top = -2, bottom = -2},
		})
	self.headerback:Show()

	self.aframe = PerfectAssistTargetFrame:CreateTargetFrame(self.mainframe, self.anchorframe)
end


function PerfectAssist:Enable()
	self.db = self:InitializeDB("PerfectAssistDB", self.defaults, "all")
	metro:Register(self, "PerfectAssistMain", self.UpdateAssistFrame, self.db.profile.rate)
	self:ReInitialize()
end


