-- Original made by Tekkub. All rights reserved.
-- Edited by Thrae for PerfectAssist's purposes.

PerfectAssistTargetFrame = {
	offset = -2,
	barheight = 7,

	colors = {
		assist = {0,0.7,0.7},
		green = {0,1,0},
		dupassist = {1,0.7,1},
		yellow = {1,1,0},
		red = {1,0,0},
		dkred = {0.5,0,0},
		grey = {0.5,0.5,0.5},
		white = {1,1,1},
	},
}


function PerfectAssistTargetFrame:CreateAnchorFrame(mainframe)
	if not mainframe then return end

	local t = CreateFrame("Button", nil, mainframe, "SecureActionButtonTemplate")
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

	t.Assist = t:CreateFontString(nil, "ARTWORK")
	t.Assist:SetFontObject(GameFontHighlightSmall)
	t.Assist:SetText("X")
	t.Assist:ClearAllPoints()
	t.Assist:SetPoint("LEFT", t.HPP, "RIGHT", 5, 0)
	self.assistwidth = t.Assist:GetStringWidth()
	self.defaultassistwidth = self.assistwidth

	t:SetPoint("TOPLEFT", t.MyTarget, "TOPLEFT")
	t:SetPoint("BOTTOMRIGHT", t.Assist, "BOTTOMRIGHT")

	self.anchorframe = t
	return t
end


function PerfectAssistTargetFrame:CreateTargetFrame(mainframe, anchor)
	if not mainframe or not anchor then return end
	local t = CreateFrame("Button", nil, mainframe, "SecureActionButtonTemplate")
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

	t.Assist = t:CreateFontString(nil, "ARTWORK")
	t.Assist:SetFontObject(GameFontHighlightSmall)
	t.Assist:SetJustifyH("LEFT")
	t.Assist:ClearAllPoints()
	t.Assist:SetPoint("TOP", t.HPP, "TOP")
	t.Assist:SetPoint("LEFT", anchor.Assist, "LEFT", 0, self.offset)
	t.Assist:SetPoint("RIGHT", anchor.Assist, "RIGHT", 0, self.offset)
	t.Assist:Show()

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


function PerfectAssistTargetFrame:OnEnter()
	this.hover = true
end


function PerfectAssistTargetFrame:OnLeave()
	this.hover = nil
end


function PerfectAssistTargetFrame:UpdateTargetFrame(frame, atarget, assistId, targCount, hpp, resetwidth)
	if not frame then return end
	frame.unitIdId = atarget
	frame.assistId = assistId
	local mobname = frame.hover and assistId and UnitName(assistId) or atarget and UnitName(atarget) or "*Unknown*"
	local oldname = frame.MobNameText
	self:UpdateFrameText(frame, "MyTarget", atarget and UnitIsUnit("target", atarget) and ">" or "")
	self:UpdateFrameText(frame, "PetTarget", atarget and UnitIsUnit("pettarget", atarget) and "<" or "")
	self:UpdateFrameText(frame, "Targetted", targCount or "-")
	self:UpdateFrameText(frame, "MobName", mobname)
	self:UpdateFrameText(frame, "HPP", hpp and string.format("%d%%", hpp) or "")
	self:UpdateFrameText(frame, "Assist", assiststring or "")
	self:UpdateFrameIcon(frame, atarget and GetRaidTargetIndex(atarget) or 0)

	self:UpdateMobNameWidth(frame.MobName:GetStringWidth()*UIParent:GetScale(), resetwidth)
	self:UpdateAssistNameWidth(frame.Assist:GetStringWidth()*UIParent:GetScale(), resetwidth)

	if frame.hpp ~= (hpp or 0) then
		frame.hpp = hpp or 0
		frame.Bar:SetStatusBarColor(self:GetHPSeverity(nil, (hpp or 0)/100, 1))
		frame.Bar:SetValue(hpp or 0)
	end

	if frame.shown ~= (atarget ~= nil) then
		frame.shown = (atarget ~= nil)
		if frame.shown then frame:Show() else frame:Hide() end
	end
end


function PerfectAssistTargetFrame:UpdateFrameText(frame, elem, newtext)
	if not frame or not elem or not frame[elem] then return end
	if frame[elem.."Text"] == newtext then return end

	frame[elem.."Text"] = newtext
	frame[elem]:SetText(newtext)
end


function PerfectAssistTargetFrame:UpdateFrameIcon(frame, newidx)
	if not frame or not frame.RaidIcon then return end
	if frame.RaidIconIdx == newidx then return end

	frame.RaidIconIdx = newidx
	SetRaidTargetIconTexture(frame.RaidIcon, newidx)
end


function PerfectAssistTargetFrame:UpdateTargetFrameColors(frame, playercombat, isfriend, unitcombat, status)
	self:UpdateFrameTextColor(frame, "MyTarget", playercombat and self.colors.red or self.colors.white)
	self:UpdateFrameTextColor(frame, "MobName",
		(frame.hover and frame.assistId or frame.unitId and frame.assistId and frame.unitId == frame.assistId) and self.colors.assist
		or UnitIsFriend(frame.unitId, "player") and self.colors.green
		or status == 1 and self.colors.yellow
		or status == 2 and unitcombat and self.colors.red
		or status == 2 and self.colors.dkred
		or unitcombat and self.colors.white or self.colors.grey)
end


function PerfectAssistTargetFrame:UpdateFrameTextColor(frame, elem, color)
	if not frame or not elem or not frame[elem] or not color then return end
	if frame[elem.."Color"] == color then return end

	frame[elem.."Color"] = color
	frame[elem]:SetTextColor(color[1], color[2], color[3])
end


function PerfectAssistTargetFrame:UpdateMobNameWidth(newwidth, reset)
	if reset or newwidth > self.namewidth then
		local neww = math.max(reset and 0 or self.namewidth, newwidth, self.defaultnamewidth)
		self.anchorframe.MobName:SetWidth(neww)
		self.namewidth = neww
	end
end


function PerfectAssistTargetFrame:UpdateAssistNameWidth(newwidth, reset)
	if reset or newwidth > self.assistwidth then
		local neww = math.max(reset and 1 or self.assistwidth, newwidth, self.defaultassistwidth)
		self.anchorframe.Assist:SetWidth(neww)
		self.assistwidth = neww
	end
end


function PerfectAssistTargetFrame:GetHPSeverity(unit, percent, smooth)
	if (percent<=0) or (percent > 1.0) then return 0.35, 0.35, 0.35 end

	if smooth then
		if percent >= 0.5 then return (1.0-percent)*2, 1.0, 0.0
		else return 1.0, percent*2, 0.0 end
	else return 0, 1, 0 end
end



