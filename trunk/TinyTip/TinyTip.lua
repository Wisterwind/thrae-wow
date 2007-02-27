--[[
-- Name: TinyTip
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date: 6-25-06
--
-- Based very losely off AF_Tooltip_Mini
-- Some code from PerfectTooltip by cladhaire
--
-- Thanks to #wowace and #wowi-lounge on Freenode as always for
-- optimization assistance.
--]]

local _G = getfenv(0)

--[[---------------------------------------------
-- Local References
----------------------------------------------]]
local strformat, strfind = string.format, string.find
local UIParent,GameTooltip = _G.UIParent,_G.GameTooltip

local L = _G.TinyTipLocale

--[[---------------------------------------------
-- Local Variables
----------------------------------------------]]

local LSpaceLevel = L.Level .. " "

local ClassColors = {}
for k,v in pairs(_G.RAID_CLASS_COLORS) do
	ClassColors[k] = strformat("%2x%2x%2x", v.r*255, v.g*255, v.b*255)
end

local tooltip
local RealmName
local tmp,tmp2,tmp3,i

--[[-------------------------------------------------------------------
-- Dongle it up
--]]

local _, AddonName = GetAddOnInfo("TinyTip")
TinyTip = DongleStub("Dongle-Beta0"):New(AddonName)

--------------------------------------------------------------------
-- Global Functions

-- Return ALL possible saved options.
function TinyTip_GetAllOptions()
	return { 	["_profile"]			= "boolean",
						["Fade"]					= "number",
						["MAnchor"]				= "string",
						["FAnchor"]				= "string",
						["MOffX"]					= "number",
						["MOffY"]					= "number",
						["FOffX"]					= "number",
						["FOffY"]					= "number",
						["Scale"]					= "number",
						["HideLevelText"]	= "boolean",
						["HideRace"]			= "boolean",
						["PvPRank"]				= "boolean",
						["PvPIcon"]				= "boolean",
						["BGColor"]				= "number",
						["Border"]				= "number",
						["HideInFrames"]	= "boolean",
						["HideGuild"]			= "boolean",
						["ReactionText"]	= "boolean",
						["Friends"]				= "number",
						["LevelGuess"]		= "boolean",
						["ToT"]						= "number",
						["ToP"]						= "number",
						["ToR"]						= "number",
						["ExtraTooltip"]	= "number",
						["ETAnchor"]			= "string",
						["ETOffX"]				= "number",
						["ETOffY"]				= "number",
						["FormatDisabled"] = "boolean",
						["Buffs"]					= "number",
						["Debuffs"]				= "number",
						["ManaBar"]				= "boolean",
						["Compact"]				= "boolean",
						["RTIcon"]				= "boolean",
						["AnchorAll"]			= "boolean",
						["PvPIconAnchor1"] 	= "string",
						["PvPIconAnchor2"] 	= "string",
						["PvPIconOffX"]			= "number",
						["PvPIconOffY"]			= "number",
						["RTIconAnchor1"] 	= "string",
						["RTIconAnchor2"] 	= "string",
						["RTIconOffX"]			= "number",
						["RTIconOffY"]			= "number",
						["BuffAnchor1"] 	= "string",
						["BuffAnchor2"] 	= "string",
						["BuffOffX"]			= "number",
						["BuffOffY"]			= "number",
						["DebuffAnchor1"] 	= "string",
						["DebuffAnchor2"] 	= "string",
						["DebuffOffX"]			= "number",
						["DebuffOffY"]			= "number",
						["PvPIconScale"]		= "number",
						["RTIconScale"]			= "number",
						["BuffScale"]				= "number",
						["KeyElite"]				= "boolean",
						["AlwaysAnchor"]		= "boolean",
						["SmoothBorder"]		= "boolean",
						["KeyServer"]				= "boolean"
					}
end

function TinyTip:LoDRun(addon,sfunc,...)
	if not self[ sfunc ] then
		local loaded, reason = LoadAddOn(addon)
		if loaded then
			self[ sfunc ](...)
		else
			self:Print( addon .. " Addon LoadOnDemand Error - " .. reason )
			return reason
		end
	else
		self[ sfunc ](...)
	end
end

function TinyTip:UpdateProfiles()
	if _G.TinyTipDB["_profile"] then
		if not _G.TinyTipCharDB then
			local k,v
			_G.TinyTipCharDB = {}
			for k,v in pairs(db) do
				_G.TinyTipCharDB[k] = v
			end
		end
		db = TinyTipCharDB
	else
		db = _G.TinyTipDB
	end
	if _G.TinyTipAnchor_SetLocals then 
		_G.TinyTipAnchor_SetLocals(db,EventFrame) 
	end
	if db["PvPIcon"] or db["Buffs"] or db["Debuffs"] then 
		_G.TinyTip_LoDRun( "TinyTipExtras", "TinyTipExtras_Init", db, EventFrame)
	end
end

local TooltipCompacted
function TinyTip:UnCompactGameTooltip()
	fClearPts(_G.GameTooltipStatusBar)
	fSetPt(_G.GameTooltipStatusBar, "TOPLEFT", GameTooltip, "BOTTOMLEFT", 2, -1)
	fSetPt(_G.GameTooltipStatusBar, "TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -2, -1)
	fClearPts(gtLine1)
	fSetPt(gtLine1, "TOPLEFT", 10, -10)
	tmp = gtLine1
	for i = 2, 8 do
		tmp2 = _G[ "GameTooltipTextLeft" .. i ]
		fClearPts( tmp2 )
		fSetPt( tmp2, "TOPLEFT", tmp, "BOTTOMLEFT", 0, -2) 
		tmp = tmp2
	end
	TooltipCompacted = nil
end

--------------------------------------------------------------------
-- Local Functions

--[[ Initialize the SavedVariables database.
	* If empty, copies the default table values to it.
	* If mismatched versions, prunes out invalid entries
	  and adds new ones.
	* Otherwise just sets the local db.
--]]

-- for Tem
function TinyTip:SmoothBorder(k)
	if k then db[k] = not db[k] end
	if db["SmoothBorder"] then
		GameTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = false,
			tileSize = 6,
			edgeSize = 18,
			insets = {
					left = 4,
					right = 4,
					top = 4,
					bottom = 4,
				}
			}	
		)
		fSetBDColor(GameTooltip, 0, 0, 0, 0.8)
		fSetBDBColor(GameTooltip, 0, 0, 0, 1)
	else
		GameTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = {
					left = 5,
					right = 5,
					top = 5,
					bottom = 5,
				}
			} 
		)
		fSetBDColor(GameTooltip, 0, 0, 0, 1)
	end
end

local function CompactTooltip(tooltip, unit)
	if not TooltipCompacted then
	local lineWidth, largestWidth, fsHHeight, fsHeight, count = 0,0,0,0
	tmp = _G[ fGetName(tooltip) .. "TextLeft1"]
	if tmp and fsIsShown(tmp) then
		count = 1
		_,fsHHeight = tmp:GetFont()
		fClearPts(tmp)
		fSetPt(tmp, "TOPLEFT", 1, 0)
		lineWidth = fsGetWidth(tmp)
		tmp2 = _G[ fGetName(tooltip) .. "TextRight1"]
		if tmp2 and fsIsShown(tmp2) then lineWidth = lineWidth + fsGetWidth(tmp2) + 40 end
		largestWidth = lineWidth
		fClearPts(_G.GameTooltipStatusBar)
		fSetPt(_G.GameTooltipStatusBar, "TOPLEFT", tmp, "BOTTOMLEFT", 0, 0)
		fSetPt(_G.GameTooltipStatusBar, "RIGHT", _G.GameTooltipStatusBar:GetParent(), "RIGHT", 0, 0)
		tmp = _G[ fGetName(tooltip) .. "TextLeft2"]
		if tmp then
			count = 2
			_,fsHeight = tmp:GetFont()
			fClearPts(tmp)
			if db["ManaBar"] and _G.TinyTipExtras_ManaBar:IsShown() then
				fSetPt(tmp, "TOPLEFT", _G.TinyTipExtras_ManaBar, "BOTTOMLEFT", 0, 0)
				count = count + 1
			else
				fSetPt(tmp, "TOPLEFT", _G.GameTooltipStatusBar, "BOTTOMLEFT", 0, 0)
			end
			lineWidth = fsGetWidth(tmp)
			tmp3 = tmp
			tmp2 = _G[ fGetName(tooltip) .. "TextRight2"]
			if tmp2 and fsIsShown(tmp2) then lineWidth = lineWidth + fsGetWidth(tmp2) + 40 end
			if lineWidth > largestWidth then largestWidth = lineWidth end
			tmp = tooltip:NumLines()
			for i = 3,tmp do
				tmp2 = _G[ fGetName(tooltip) .. "TextLeft" .. i ]
				if tmp2 and fsIsShown(tmp2) then 
					fClearPts(tmp2)
					fSetPt(tmp2, "TOPLEFT", tmp3, "BOTTOMLEFT", 0, 0) 
					lineWidth = fsGetWidth(tmp2)
					count = count + 1
				end
				tmp3 = tmp2
				tmp2 = _G[ fGetName(tooltip) .. "TextRight" .. i ]
				if tmp2 and fsIsShown(tmp2) then
					lineWidth = lineWidth + fsGetWidth(tmp2) + 40
				end
				if lineWidth > largestWidth then largestWidth = lineWidth end
			end
			tooltip:SetWidth( largestWidth + 5 )
			tooltip:SetHeight( fsHHeight + (fsHeight * (count) ) )
		end
	end
	TooltipCompacted = true
end
end

-- Return color format in HEX from Blizzard percentage RGB
-- for the class.
function TinyTip_ColorPlayer(unit)
	_,tmp=_G.UnitClass(unit)
	if tmp and ClassColors[tmp] then
		return ClassColors[tmp]
	else
		return "FFFFFF"
	end
end

local PvPLine, PvPBeforeLine
local function TooltipFormat(unit)
	if gtIsVisible(GameTooltip) and _G.UnitExists(unit) then
	local treac,cdeadortap,bdead,levelLine,name
	local bdR,bdG,bdB = 0,0,0

	if not db["FormatDisabled"] then
	tmp = gtNumLines(GameTooltip)
	for i = 1,tmp,1 do
		tmp2 = fsGetText(_G[ "GameTooltipTextLeft" .. i ])
		if tmp2 and strfind(tmp2, _G.TinyTipLocale_Level, 1, true) then
			levelLine = _G[ "GameTooltipTextLeft" .. i ]
			break
		end
	end

	-- Get Rank, then Set Name (rankName, rankNumber)
	tmp,tmp2 = _G.GetPVPRankInfo(_G.UnitPVPRank(unit), unit)
	name,tmp3 = _G.UnitName(unit)
	if db["PvPIcon"] and _G.TinyTipIcons_ResetPvPIcon then
		_G.TinyTipIcons_ResetPvPIcon(tmp2, _G.UnitIsPlayer(unit))
	end
	if _G.UnitIsPlayer(unit) and db["PvPRank"] ~= 1 and tmp2 > 0 then
			if db["PvPRank"] == 2 then
				fsSetText(gtLine1, "[" .. tmp .. "] " .. (name or TinyTipLocale_Unknown ) .. ( (tmp3 and tmp3 ~= RealmName and ( (db["KeyServer"] and "(*)") or (" (" .. tmp3 .. ")") ) ) or "") )
			elseif db["PvPRank"] == 3 then
				if ( GetLocale() ~= "koKR" ) then
					fsSetText(gtLine1, (name or TinyTipLocale_Unknown) .. ( (tmp3 and tmp3 ~= RealmName and ( (db["KeyServer"] and "(*)") or (" (" .. tmp3 .. ")") ) ) or "") .. " [R" .. tmp2 .. "]" )
				else
					fsSetText(gtLine1, (name or TinyTipLocale_Unknown) .. ( (tmp3 and tmp3 ~= RealmName and ( (db["KeyServer"] and "(*)") or (" (" .. tmp3 .. ")") ) ) or "") .. " [" .. tmp2 .. "계급]" )
				end
			else
				if ( GetLocale() ~= "koKR" ) then
					fsSetText(gtLine1, "[R" .. tmp2 .. "] " .. (name or TinyTipLocale_Unknown ) .. ( (tmp3 and tmp3 ~= RealmName and ( (db["KeyServer"] and "(*)") or (" (" .. tmp3 .. ")") ) ) or "") )
				else
					fsSetText(gtLine1, "[" .. tmp2 .. "계급] " .. (name or TinyTipLocale_Unknown ) .. ( (tmp3 and tmp3 ~= RealmName and ( (db["KeyServer"] and "(*)") or (" (" .. tmp3 .. ")") ) ) or "") )	
				end
			end
	else
			fsSetText(gtLine1, (name or TinyTipLocale_Unknown) .. ( (tmp3 and tmp3 ~= RealmName and ( (db["KeyServer"] and "(*)") or (" (" .. tmp3 .. ")") ) ) or "") )
	end

	-- Reaction coloring
	tmp,tmp2 = _G.UnitPlayerControlled(unit), _G.UnitReaction(unit, "player")
	if _G.UnitIsTapped(unit) and not _G.UnitIsTappedByPlayer(unit) then
		if not db["BGColor"] or db["BGColor"] == 2 then
			bdR,bdG,bdB = 0.54,0.54,0.54
		end
		fsSetTextColor(gtLine1, 0.54,0.54,0.54)
		cdeadortap = "888888"
	elseif ( tmp and _G.UnitCanAttack(unit, "player") ) or 
		   _G.UnitIsTappedByPlayer(unit) or 
		   ( not tmp and tmp2 and tmp2 > 0 and tmp2 <= 2 ) then -- hostile
			fsSetTextColor(gtLine1, _G.FACTION_BAR_COLORS[tmp2 or 2].r,
						_G.FACTION_BAR_COLORS[tmp2 or 2].g,
						_G.FACTION_BAR_COLORS[tmp2 or 2].b)
			if db["ReactionText"] and tmp2 and tmp2 > 0 then
				treac = _G["FACTION_STANDING_LABEL" .. tmp2]
			else
				treac = _G.FACTION_STANDING_LABEL2
			end
			
			if not db["BGColor"] or db["BGColor"] == 2 then
				if tmp or db["BGColor"] == 2 then 
					if tmp and not _G.UnitCanAttack("player", unit) then 
						bdR,bdG,bdB = 0.5,0.2,0.1
					else
						bdR,bdG,bdB = 0.5,0.0,0.0
					end
				end
			end
	elseif ( tmp and _G.UnitCanAttack("player",unit) ) or 
		   ( not tmp and tmp2 and tmp2 <= 4 ) then -- neutral
			fsSetTextColor(gtLine1, _G.FACTION_BAR_COLORS[4].r,
						_G.FACTION_BAR_COLORS[4].g,
						_G.FACTION_BAR_COLORS[4].b)
			if db["ReactionText"] then treac = _G.FACTION_STANDING_LABEL4 end
			if (tmp and not db["BGColor"]) or db["BGColor"] == 2 then
				tooltip:SetBackdropColor( 0.5, 0.5, 0.0)
			end
	else -- friendly
		treac = _G.FACTION_STANDING_LABEL5
		if (tmp and not db["BGColor"]) or db["BGColor"] == 2 then
			bdR,bdG,bdB = 0.0, 0.0, 0.5
		end
		if _G.UnitIsPVP(unit) then -- friendly, PvP-enabled
			fsSetTextColor(gtLine1,	_G.FACTION_BAR_COLORS[6].r,
																		_G.FACTION_BAR_COLORS[6].g,
																		_G.FACTION_BAR_COLORS[6].b)
		else
			fsSetTextColor(gtLine1,	(not tmp and _G.FACTION_BAR_COLORS[tmp2 or 5].r) or 0,
																		(not tmp and _G.FACTION_BAR_COLORS[tmp2 or 5].g) or 0.67,
																		(not tmp and _G.FACTION_BAR_COLORS[tmp2 or 5].b) or 1.0)
		end
	end

	-- remove PvP line, if it exists
	PvP_Line = nil
	if not db["ReactionText"] and _G.UnitIsPVP(unit) then
		tmp = gtNumLines(GameTooltip)
		for i=3,tmp,1 do
			tmp2 = _G["GameTooltipTextLeft" .. i]
			if tmp2 then
				tmp3 = fsGetText(tmp2)
				if tmp3 and strfind(tmp3, _G.PVP_ENABLED, 1, true) then
					PvPLine = tmp2
					PvPBeforeLine = _G["GameTooltipTextLeft" .. (i-1)]
					fsSetText(PvPLine, nil)
					fClearPts(PvPLine)
					fSetPt(PvPLine, "TOPLEFT", PvPBeforeLine or gtLine2, "BOTTOMLEFT", 0, 1) 
					fsHide(PvPLine)
					break
				end
			end
		end
	end

	-- We like to know who our friends are.
	if db["Friends"] ~= 2 and
	_G.UnitIsPlayer(unit) and treac == _G.FACTION_STANDING_LABEL5 then
		local num,name = _G.GetNumFriends(), _G.UnitName(unit)
		for i = 1,num,1 do
			tmp,tmp2 = _G.GetFriendInfo(i)
			if tmp and tmp2 ~= 0 and name and tmp == name then
				if db["Friends"] == 1 or db["BGColor"] == 1 or db["BGColor"] == 3 then
					fsSetTextColor(gtLine1, 0.58, 0.0, 0.83)
				else
					bdR,bdG,bdB = 0.29, 0.0, 0.42
				end
				break
			end
		end
	end
	
	-- Check for a dead unit, but try to leave out Hunter's Feign Death
	if _G.UnitHealth(unit) <= 0 and 
	( not _G.UnitIsPlayer(unit) or _G.UnitIsDeadOrGhost(unit) or _G.UnitIsCorpse(unit) ) then
		if not db["BGColor"] or db["BGColor"] == 2 then
			bdR,bdG,bdB = 0.54, 0.54, 0.54
		end
		fsSetTextColor(gtLine1, 0.54,0.54,0.54)
		cdeadortap = "888888"
		bdead = true
	end	
	
	-- set the color of line 2, if it's available
	if levelLine == gtLine3 then
		fsSetTextColor(gtLine2, fsGetTextColor(gtLine1) )
	end

	if levelLine then
	local clevel
	local ulevel = _G.UnitLevel(unit)
	tmp2 = ulevel - _G.UnitLevel("player") -- Level difficulty
	if tmp2 and _G.UnitFactionGroup(unit) ~= _G.UnitFactionGroup("player") then
		if tmp2 >= 5 or ulevel == -1 then clevel = "FF0000"
		elseif tmp2 >= 3 then clevel = "FF6600"
		elseif tmp2 >= -2 then clevel = "FFFF00"
		elseif -tmp2 <= _G.GetQuestGreenRange() then clevel = "00FF00"
		else clevel = "888888"
		end		
	end

		tmp = (not db["HideLevelText"] and SpaceLevel) or ""
		if ulevel and ulevel >= 1 then 
			fsSetText(levelLine, "|cFF" .. 
													 (cdeadortap or clevel or "FFCC00") ..
													 tmp .. 
													 ulevel .. 
													 "|r")
		elseif db["LevelGuess"] and ulevel and ulevel == -1 and ulevel < 60 then
			fsSetText(levelLine, "|cFF" .. 
													 (cdeadortap or clevel or "FFCC00") ..
													 tmp .. ">" ..
													  (_G.UnitLevel("player") + 10 ) .. 
													 "|r")
		else
			fsSetText(levelLine, "|cFF" .. 
													 (cdeadortap or clevel or "FFCC00") ..
													 tmp .. 
													 "??|r")
		end

		tmp2 = _G.UnitClassification(unit) -- Elite status
		if tmp2 and tmp2 ~= "normal" then
			if tmp2 == "elite" then
				fsSetText(levelLine, (fsGetText(levelLine) or "") .. 
														 ((db["KeyElite"] and "") or " ") ..
														 "|cFF" .. 
														 (cdeadortap or "FFCC00") .. 
														 ((db["KeyElite"] and "*") or _G.ELITE) ..
														 "|r" )
			elseif tmp2 == "worldboss" then
				fsSetText(levelLine, (fsGetText(levelLine) or "") .. 
														 ((db["KeyElite"] and "") or " ") ..
														 "|cFF" .. 
														 (cdeadortap or "FF0000") .. 
														 ((db["KeyElite"] and "**") or _G.BOSS) ..
														 "|r" )
			elseif tmp2 == "rare" then
				fsSetText(levelLine, (fsGetText(levelLine) or "") .. 
														 ((db["KeyElite"] and "") or " ") ..
														 "|cFF" .. 
														 (cdeadortap or "FF66FF") .. 
														 ((db["KeyElite"] and "!") or _G.ITEM_QUALITY3_DESC) ..
														 "|r" )
			elseif tmp2 == "rareelite" then
				fsSetText(levelLine, (fsGetText(levelLine) or "") .. 
														 ((db["KeyElite"] and "") or " ") ..
														 "|cFF" .. 
														 (cdeadortap or "FFAAFF") .. 
														 ((db["KeyElite"] and "!*") or _G.TinyTipLocale_RareElite) ..
														 "|r" )
			else
				fsSetText(levelLine, (fsGetText(levelLine) or "") .. 
														 " [|cFF" .. 
														 (cdeadortap or "FFFFFF") .. 
														 tmp2 ..
														 "|r]" )
			end
		end

		-- Class And Race
		if _G.UnitIsPlayer(unit) then
			tmp = _G.UnitRace(unit)
			fsSetText(levelLine, 	(fsGetText(levelLine) or "") .. 
														" |cFF" ..
														(cdeadortap or "DDEEAA") .. 
														(( not db["HideRace"] and tmp and (tmp .. " ") ) or "") ..
														"|r|cFF" ..
														(cdeadortap or TinyTip_ColorPlayer(unit)) .. 
														(_G.UnitClass(unit) or "" ) ..
														"|r")
		elseif not db["HideRace"] then
			if _G.UnitPlayerControlled(unit) then 
			fsSetText(levelLine, 	(fsGetText(levelLine) or "") .. 
														" |cFF" ..
														(cdeadortap or "DDEEAA") .. 
														(_G.UnitCreatureFamily(unit) or "") ..
														"|r")
			else
			fsSetText(levelLine, 	(fsGetText(levelLine) or "") .. 
														" |cFF" ..
														(cdeadortap or "DDEEAA") .. 
														(_G.UnitCreatureType(unit) or "") ..
														"|r")
			end
		end
	
	-- add corpse/tapped line
	if cdeadortap and levelLine then 
		fsSetText(levelLine,
						(fsGetText(levelLine) or "") .. 
						" |cFF888888(" ..
						( ( bdead and _G.CORPSE ) or TinyTipLocale_Tapped ) ..
						")|r")
	end

end
end

	if db["ExtraTooltip"] and _G.TinyTipExtras_CopyGameTooltip then
		_G.TinyTipExtras_CopyGameTooltip()
	end

	if not bdead then
	-- Add Reaction Text
	if db["ReactionText"] and treac then
		gtAddLine( tooltip, treac, fsGetTextColor(gtLine1) )
	end

	-- Add Guild info, if enabled
	tmp2 = _G.GetGuildInfo(unit)
	if not db["HideGuild"] and tmp2 then
		tmp = "<" .. tmp2 .. ">"
		if _G.IsInGuild() and tmp2 == _G.GetGuildInfo("player") and db["Friends"] ~= 2 then
			if not db["Friends"] and not _G.UnitIsUnit(unit, "player") and db["BGColor"] ~= 3 and db["BGColor"] ~= 1 then
				bdR,bdG,bdB = 0.4, 0.1, 0.5
				gtAddLine( tooltip, tmp, fsGetTextColor(gtLine1) )
			else
				gtAddLine( tooltip, tmp, 0.58, 0.0, 0.83)
			end
		else
			gtAddLine( tooltip, tmp, fsGetTextColor(gtLine1) )
		end
	end

	if db["RTIcon"] and _G.TinyTipIcons_ResetRTIcon then _G.TinyTipIcons_ResetRTIcon(unit, _G.GetNumRaidMembers()) end
	if db["ToT"] and _G.TinyTipTargets_Mouse then _G.TinyTipTargets_Mouse(unit, db["ToT"]) end
	if db["ToR"] or db["ToP"] then
		tmp,tmp2 = _G.GetNumRaidMembers(), _G.GetNumPartyMembers()
		if db["ToR"] and _G.TinyTipTargets_Raid and tmp and tmp > 0 then _G.TinyTipTargets_Raid(unit, tmp, db["ToR"])
		elseif db["ToP"] and _G.TinyTipTargets_Party and tmp2 and tmp2 > 0 then 
			_G.TinyTipTargets_Party(unit, tmp2, db["ToP"]) 
		end
	end

	if db["Buffs"] and _G.TinyTipIcons_ShowBuffs then _G.TinyTipIcons_ShowBuffs(unit) end
	if db["Debuffs"] and _G.TinyTipIcons_ShowDebuffs then _G.TinyTipIcons_ShowDebuffs(unit) end
end
	if (db["Buffs"] or db["Debuffs"]) and _G.TinyTipIcons_HideUnusedTextures then _G.TinyTipIcons_HideUnusedTextures() end
	
	if db["BGColor"] ~= 1 then
		if db["BGColor"] == 3 then
			fSetBDColor(GameTooltip, 0, 0, 0)
		else
			fSetBDColor(GameTooltip, bdR, bdG, bdB )
		end
	end
	if db["Border"] ~= 1 then
		if db["Border"] == 2 then
			fSetBDBColor(GameTooltip, 0,0,0,0)
		else
			local r,g,b = fGetBDColor(GameTooltip)
			r,g,b = r * 1.5, g * 1.5, b * 1.5
			fSetBDBColor(GameTooltip, r,g,b,1)
		end
	end
	

	this.skipOnShow = nil
	GameTooltip:Show() -- used to re-size gametooltip

	if db["ExtraTooltip"] and _G.TinyTipExtras_Tooltip then
		fSetBDColor(_G.TinyTipExtras_Tooltip, fGetBDColor(GameTooltip) )
		fSetBDBColor( _G.TinyTipExtras_Tooltip, fGetBDBColor(GameTooltip) )
		fSetBDColor(GameTooltip, 0,0,0)
		fSetBDBColor(GameTooltip, 0,0,0,0)
		_G.TinyTipExtras_Tooltip:Show()
	end
	if db["Compact"] then CompactTooltip(EventFrame.tooltip, unit) end
end
end

-- arg1=this,arg2=unit
_G.TinyTip_Original_GameTooltip_SetUnit = nil
function TinyTip_SetUnit(this,unit,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
	this.skipOnShow = true
	if unit ~= "mouseover" and _G.TinyTip_Original_GameTooltip_SetUnit then
		_G.TinyTip_Original_GameTooltip_SetUnit(this,unit,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
	end
	GameTooltip.unit = unit
	if db["HideInFrames"] and unit ~= "mouseover" then
		fSetScript(EventFrame, "OnUpdate", nil)
		fSetAlpha(GameTooltip, 0.01)
		if GameTooltip.owner then
			fClearPts(GameTooltip)
			GameTooltip:SetOwner(GameTooltip.owner, "ANCHOR_NONE")
		end
	else
		if db["ManaBar"] and _G.TinyTipExtras_ManaBar then sbShow(_G.TinyTipExtras_ManaBar) end
		TooltipFormat(unit)
		GameTooltip.unit = unit
		if db["ExtraTooltip"] and _G.TinyTipAnchor_SetDefaultAnchor then
			_G.TinyTipAnchor_SetDefaultAnchor(_G.TinyTipExtras_Tooltip, GameTooltip.owner)
		end
	end
	this.skipOnShow = nil
end

_G.TinyTip_Original_GameTooltip_FadeOut = nil
function TinyTip_FadeOut(this,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
	if db["Fade"] == 2 or db["ExtraTooltip"] then
		GameTooltip:Hide()
	elseif _G.TinyTip_Original_GameTooltip_FadeOut then
		_G.TinyTip_Original_GameTooltip_FadeOut(this,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
	end
end

local Original_GameTooltip_OnTooltipCleared
function TinyTip_OnTooltipCleared(this,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
	if Original_GameTooltip_OnTooltipCleared then
		Original_GameTooltip_OnTooltipCleared(this,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
	end
	if (db["Compact"] or TooltipCompacted) and not db["ExtraTooltip"] then
		_G.TinyTip_UnCompactGameTooltip()
	elseif PvPLine then
		fClearPts(PvPLine)
		fSetPt(PvPLine, "TOPLEFT", PvPBeforeLine or gtLine2, "BOTTOMLEFT", 0, -2)
		PvPLine,PvPBeforeLine = nil, nil
	end
	GameTooltip.unit = nil
	fSetScript(EventFrame, "OnUpdate", nil)
	_G.GameTooltip_ClearMoney()
end

_G.TinyTip_Original_GameTooltip_OnShow = nil
function TinyTip_OnShow(this,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
	if _G.TinyTip_Original_GameTooltip_OnShow and (this and not this.skipOnShow) then
		_G.TinyTip_Original_GameTooltip_OnShow(this,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
	end
	if db["AlwaysAnchor"] and not GameTooltip.unit and not _G.UnitExists("mouseover") and not EventFrame:GetScript("OnUpdate") and _G.TinyTipAnchor_AlwaysAnchor then
		fSetScript(EventFrame, "OnUpdate", _G.TinyTipAnchor_AlwaysAnchor)
	end
	if GameTooltip.unit then
		_G.GameTooltip_ClearMoney()
	end
end

local function OnEvent()	
	if _G.event == "UPDATE_MOUSEOVER_UNIT" then
		if UnitExists("mouseover") then
			GameTooltip:SetUnit("mouseover")
		end
	elseif _G.event == "PLAYER_ENTERING_WORLD" and db then -- rescale
		_G.TinyTip_SetScale("Scale", db["Scale"] )
		if _G.TinyTipExtras_Init then _G.TinyTipExtras_Init(db) end
	elseif _G.event == "ADDON_LOADED" and _G.arg1 == "TinyTip" then
		InitDB()
		RealmName = _G.GetRealmName()
		if _G.TinyTipAnchor_SetLocals then 
			_G.TinyTipAnchor_SetLocals(db,EventFrame,acehook)
		end
		local ttextraserror = true
		if db["UseAceHook"] or db["PvPIcon"] or db["Buffs"] or db["Debuffs"] or db["ExtraTooltip"] or db["ManaBar"] or db["RTIcon"] then
			ttextraserror = _G.TinyTip_LoDRun( "TinyTipExtras", "TinyTipExtras_Init", db, EventFrame,acehook)
		elseif db["ToT"] or db["ToP"] or db["ToR"] then
			_G.TinyTip_LoDRun( "TinyTipExtras", "TinyTipTargetsExists")
		end
		if not acehook:IsHooked(GameTooltip, "FadeOut") and ( db["Fade"] == 2 or db["ExtraTooltip"] ) then
			acehook:SecureHook(GameTooltip, "FadeOut", _G.TinyTip_FadeOut)
			_G.TinyTip_Original_GameTooltip_FadeOut = acehook.hooks[GameTooltip]["FadeOut"]
		end
		if not acehook:IsHooked(GameTooltip, "OnShow") then
			acehook:HookScript(GameTooltip, "OnShow", _G.TinyTip_OnShow)
			_G.TinyTip_Original_GameTooltip_OnShow = acehook.hooks[GameTooltip]["OnShow"]
		end
		if not acehook:IsHooked(GameTooltip, "OnTooltipCleared") then -- most sure-fire way to hide something
			acehook:HookScript(GameTooltip, "OnTooltipCleared", _G.TinyTip_OnTooltipCleared)
			_G.TinyTip_Original_GameTooltip_OnTooltipCleared = acehook.hooks[GameTooltip]["OnTooltipCleared"]
		end

		_G.TinyTip_SetScale( "Scale", db["Scale"] )

		if db["Fade"] == 2 then
			EventFrame:SetScript("OnUpdate", _G.TinyTip_SlimOnUpdate)
		end

		TinyTip_SmoothBorder()

		EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		EventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		GameTooltip:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")	
	end
end

	elseif _G.event == "PLAYER_ENTERING_WORLD" and db then -- rescale
		_G.TinyTip_SetScale("Scale", db["Scale"] )
		if _G.TinyTipExtras_Init then _G.TinyTipExtras_Init(db) end
	elseif _G.event == "ADDON_LOADED" and _G.arg1 == "TinyTip" then
		InitDB()
		RealmName = _G.GetRealmName()
		if _G.TinyTipAnchor_SetLocals then 
			_G.TinyTipAnchor_SetLocals(db,EventFrame,acehook)
		end
		local ttextraserror = true
		if db["UseAceHook"] or db["PvPIcon"] or db["Buffs"] or db["Debuffs"] or db["ExtraTooltip"] or db["ManaBar"] or db["RTIcon"] then
			ttextraserror = _G.TinyTip_LoDRun( "TinyTipExtras", "TinyTipExtras_Init", db, EventFrame,acehook)
		elseif db["ToT"] or db["ToP"] or db["ToR"] then
			_G.TinyTip_LoDRun( "TinyTipExtras", "TinyTipTargetsExists")
		end
		if not acehook:IsHooked(GameTooltip, "FadeOut") and ( db["Fade"] == 2 or db["ExtraTooltip"] ) then
			acehook:SecureHook(GameTooltip, "FadeOut", _G.TinyTip_FadeOut)
			_G.TinyTip_Original_GameTooltip_FadeOut = acehook.hooks[GameTooltip]["FadeOut"]
		end
		if not acehook:IsHooked(GameTooltip, "OnShow") then
			acehook:HookScript(GameTooltip, "OnShow", _G.TinyTip_OnShow)
			_G.TinyTip_Original_GameTooltip_OnShow = acehook.hooks[GameTooltip]["OnShow"]
		end
		if not acehook:IsHooked(GameTooltip, "OnTooltipCleared") then -- most sure-fire way to hide something
			acehook:HookScript(GameTooltip, "OnTooltipCleared", _G.TinyTip_OnTooltipCleared)
			_G.TinyTip_Original_GameTooltip_OnTooltipCleared = acehook.hooks[GameTooltip]["OnTooltipCleared"]
		end

		_G.TinyTip_SetScale( "Scale", db["Scale"] )

		if db["Fade"] == 2 then
			EventFrame:SetScript("OnUpdate", _G.TinyTip_SlimOnUpdate)
		end

		TinyTip_SmoothBorder()

		EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		EventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		GameTooltip:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")	

-----------------------------------------------------------------------
-- WoW-Required Functions
--

_G.SlashCmdList["TINYTIP"] = function(msg)
	if db then
		_G.TinyTip_LoDRun( "TinyTipOptions", "TinyTipChat_SlashHandler", msg, db)
	end
end

-- hook these immediatly
if _G.TinyTipAnchor_Hook then TinyTipAnchor_Hook(acehook) end

if not acehook:IsHooked(GameTooltip, "SetUnit") then
	acehook:Hook(GameTooltip, "SetUnit", _G.TinyTip_SetUnit, true)
	_G.TinyTip_Original_GameTooltip_SetUnit = acehook.hooks[GameTooltip]["SetUnit"]
end

--[[-------------------------------------------------------
-- Standby Modes
----------------------------------------------------------]]

-- Called when coming out of Standby or first initialization.
function TinyTip:ReInitialize()
	db = self.db.profile
	
	self:UnregisterAllEvents()
	RealmName = GetRealmName()

	local ttextraserror = true
	
	if db["PvPIcon"] or db["Buffs"] or db["Debuffs"] or db["ExtraTooltip"] or db["ManaBar"] or db["RTIcon"] then
		ttextraserror = _G.TinyTip_LoDRun( "TinyTipExtras" )
	elseif db["ToT"] or db["ToP"] or db["ToR"] then
		_G.TinyTip_LoDRun( "TinyTipExtras", "TinyTipTargetsExists")
	end
	
	if not acehook:IsHooked(GameTooltip, "FadeOut") and ( db["Fade"] == 2 or db["ExtraTooltip"] ) then
			acehook:SecureHook(GameTooltip, "FadeOut", _G.TinyTip_FadeOut)
			_G.TinyTip_Original_GameTooltip_FadeOut = acehook.hooks[GameTooltip]["FadeOut"]
		end
		if not acehook:IsHooked(GameTooltip, "OnShow") then
			acehook:HookScript(GameTooltip, "OnShow", _G.TinyTip_OnShow)
			_G.TinyTip_Original_GameTooltip_OnShow = acehook.hooks[GameTooltip]["OnShow"]
		end
		if not acehook:IsHooked(GameTooltip, "OnTooltipCleared") then -- most sure-fire way to hide something
			acehook:HookScript(GameTooltip, "OnTooltipCleared", _G.TinyTip_OnTooltipCleared)
			_G.TinyTip_Original_GameTooltip_OnTooltipCleared = acehook.hooks[GameTooltip]["OnTooltipCleared"]
		end

		_G.TinyTip_SetScale( "Scale", db["Scale"] )

		if db["Fade"] == 2 then
			EventFrame:SetScript("OnUpdate", _G.TinyTip_SlimOnUpdate)
		end

		TinyTip_SmoothBorder()

		EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		EventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		GameTooltip:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")	

	
end

function TinyTip:Standby()
	self:UnregisterAllEvents()
	tooltip:Hide()

	self.onstandby = true
end

function PerfectTargets:Wakeup()
	self:ReInitialize()
	self.onstandby = nil
end

--[[-------------------------------------------------------
-- Dongle Initialization
----------------------------------------------------------]]

function TinyTip:Initialize()
	self.db = self:InitializeDB("TinyTipDB", {
		profile = {
			maxframes = 10,
			baserate = 0.25,
		},
	}, "global")

--	self:InitializeOptions()
end


function TinyTip:Enable()
	tooltip = CreateFrame("GameTooltip", "TinyTip_Tooltip", UIParent, "GameTooltipTemplate")
	self.tooltip = tooltip
	
	self:ReInitialize()

	self.loaded = true
end
