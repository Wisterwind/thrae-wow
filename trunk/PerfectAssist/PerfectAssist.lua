--[[
-- Name: PerfectAssist
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date: 1-27-07
--]]

local _G = getfenv(0)
local PerfectAssistTargetFrame = _G.PerfectAssistTargetFrame
local PerfectAssistLocale = _G.PerfectAssistLocale

local metro = DongleStub("MetrognomeNano-Beta0")
PerfectAssist = DongleStub("Dongle-Beta0"):New("PerfectAssist")
PerfectAssist.rev = tonumber(string.match("$Revision: $", "(%d+)") or 1)

local PerfectAssist = _G.PerfectAssist
local assistId, raidNum, partyNum, numtargets, assisting

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

local function UpdateAssisting(uid)
	if not UnitExists(uid) or UnitIsUnit(assistId, uid) then return end

	local tuid = uid.."target"
	if UnitExists(tuid) and UnitIsUnit(atarget, tuid) then
		if not assisting[uid] then 
			numtargets = numtargets + 1
		end
	elseif assisting[uid] then
		assisting[uid] = nil
		numtargets = numtargets - 1
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
		local isfriend = UnitIsFriend(atarget, "player")
		local hpmax = UnitHealthMax(atarget)

		PerfectAssistTargetFrame:UpdateTargetFrame(self.aframe, 
			atarget, 
			numtargets, 
			((hpmax ~= 0) and math.floor((UnitHealth(atarget) / hpmax) * 100)) or 0, 
			true)
		PerfectAssistTargetFrame:UpdateTargetFrameColors(self.aframe, 
			UnitAffectingCombat("player"), 
			isfriend, 
			not isfriend and UnitAffectingCombat(atarget), 
			not isfriend and UnitStatus(atarget))
	else
		PerfectAssistTargetFrame:UpdateTargetFrame(self.aframe)
	end
end

function PerfectAssist:SetClick()
	if not UnitAffectingCombat("player") then
		if assistId then
			self.aframe:SetAttribute("unit", assistId)
			self.aframe:SetAttribute("type1", "assist")
			self.anchorframe:SetAttribute("unit", assistId)
			self.anchorframe:SetAttribute("type1", "assist")

			self:UNIT_TARGET(nil, assistId) -- reset frame
		else
			self.aframe:SetAttribute("type1", ATTRIBUTE_NOOP)
			self.anchorframe:SetAttribute("type1", ATTRIBUTE_NOOP)
		end
	end
end

--[[-------------------------------------------------------
-- Events
----------------------------------------------------------]]

function PerfectAssist:UNIT_TARGET(event, unitId)
	if unitId == "target" or (unitId ~= "player" and UnitIsUnit(unitId, "player")) then return end

	if assistId then
		if UnitIsUnit(unitId, assistId) then
			local uid,tuid
			numtargets=0
			assisting={}
			if raidNum > 0 then
				for i = 1,raidNum do
					UpdateAssisting("raid"..i)
				end
			elseif partyNum > 0 then
				for i = 1,partyNum do
					UpdateAssisting("party"..i)
				end
			end
			self:UpdateAssistFrame()
		else
			UpdateAssisting(unitId)
		end
	end
end

function PerfectAssist:PARTY_MEMBERS_CHANGED(event)
	partyNum = GetNumPartyMembers()
	raidNum = GetNumRaidMembers() 
	if not UnitAffectingCombat("player") then
		CombatPartyChange = nil
		if raidNum == 0 and partyNum > 0 then
			if self.asleep then self:Wakeup() end
			local uid,c,ac
			assistId = nil
			for i = 1,partyNum do
				uid="party"..i
				if self.db.profile.savedAssist and 
				self.db.profile.savedAssist == UnitName(uid) then
					assistId = uid
					self:SetClick()
					return
				elseif self.db.profile.auto then
					_,c = UnitClass(uid)
					ac = SetAutoAssistId(uid, c, ac)
				end
			end
			self:SetClick()
		elseif raidNum == 0 and partyNum == 0 then
			assistId = nil
			self:Sleep()
		end
	else
		CombatPartyChange = true
	end
end

function PerfectAssist:RAID_ROSTER_UPDATE(event)
	partyNum = GetNumPartyMembers()
	raidNum = GetNumRaidMembers() 
	if not UnitAffectingCombat("player") then
		CombatRaidChange = nil
		if raidNum > 0 then
			if self.asleep then self:Wakeup() end
			local uid,name,c,ac
			assistId = nil
			for i = 1,raidNum do
				uid="raid"..i
				name,_,_,_,c = GetRaidRosterInfo(i)
				if self.db.profile.savedAssist and 
				self.db.profile.savedAssist == name then
					assistId = uid
					self:SetClick()
					return
				elseif self.db.profile.auto then
					ac = SetAutoAssistId(uid, c, ac)
				end
			end
			self:SetClick()
		elseif partyNum == 0 then
			assistId = nil
			self:Sleep()
		end
	else
		CombatRaidChange = true
	end
end

function PerfectAssist:PLAYER_REGEN_DISABLED(event)
	if CombatRaidChange then
		self:RAID_ROSTER_UPDATE()
	elseif CombatPartyChange then
		self:PARTY_MEMBERS_CHANGED()
	end
	if self.asleep then
		self.mainframe:Hide()
		self.headerback:Hide()
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	elseif assistId and self.aframe:GetAttribute("unit") ~= assistId then
		self:SetClick() 
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
end

function PerfectAssist:Sleep()
	--[[
	self:UnregisterEvent("UNIT_TARGET")
	metro:Stop("PerfectAssistMain")
	if not UnitAffectingCombat("player") then 
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self.mainframe:Hide()
		self.headerback:Hide()
	end

	self.asleep = true
	--]]
	assisting = nil
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
			rate=0.25
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
	self.headerback:RegisterForDrag("Shift-LeftButton")
	self.headerback:SetScript("OnDragStart", function()
		if PerfectAssist.db.profile.framelocked then return end
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
	metro:Register(self, "PerfectAssistMain", "UpdateAssistFrame", self.db.profile.rate)
	self:ReInitialize()
end


