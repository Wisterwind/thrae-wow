--[[
-- Name: TinyTip
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date:
-- Release Version: 2.0
--
-- Thanks to #wowace, #dongle, and #wowi-lounge on Freenode as always for
-- optimization assistance. Thanks to AF_Tooltip_Mini for the idea that
-- became TinyTip.
--
-- Note: See bottom of code for instructions on manually changing database
-- values (within the Initialize function).
--]]

local _G = getfenv(0)

--[[---------------------------------------------
-- Local References
----------------------------------------------]]
local strformat, strfind = string.format, string.find
local UIParent, GameTooltip = _G.UIParent, _G.GameTooltip

local L = _G.TinyTipLocale

--[[---------------------------------------------
-- Local Variables
----------------------------------------------]]

local _, PlayerRealm, ClassColours

--[[
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
--]]

--[[----------------------------------------------------------------------
-- Module Support
------------------------------------------------------------------------]]

-- _, TinyTip = GetAddOnInfo("TinyTip")
-- TinyTip = DongleStub("Dongle-1.0"):New(TinyTip)
local module, EventFrame, db, ColourPlayer, Hook_OnTooltipSetUnit
if not modulecore then
    module = {}
else
    _, module = GetAddOnInfo("TinyTip")
    module = modulecore:NewModule(module)
    EventFrame = modulecore.OnUpdateFrame
    db = modulecore.db
    ColourPlayer = modulecore.ColourPlayer
    Hook_OnTooltipSetUnit = modulecore.Hook_OnTooltipSetUnit
end

--[[----------------------------------------------------------------------
-- Formating
-------------------------------------------------------------------------]]

-- Return color format in HEX from Blizzard percentage RGB
-- for the class.
if not modulecore then
    ColourPlayer = function(unit)
        local c
        _,c = UnitClass(unit)
        if c and ClassColours[c] then return ClassColours[c] end
        return "FFFFFF"
    end
end

local lines
function module:TooltipFormat(unit, name, realm, isPlayer, isPlayerOrPet, isDead)
    if not UnitExists(unit) then return end

    local numLines = GameTooltip:NumLines()
    local guildName = GetGuildInfo(unit)
    local line, levelLine, afterLevelLine
    for i = 1,numLines,1 do
        line = _G[ "GameTooltipTextLeft" .. i ]
        if line:IsShown() then
            lines[i] = line:GetText()
            line = lines[i]
            if line and line ~= guildName and strfind(line, L.Level, 1, true) then
                levelLine = true
                afterLevelLine = i + 1
            end
        end
    end
    GameTooltip:ClearLines()

    -- First Line
    if not isPlayer then isPlayer = UnitIsPlayer(unit) end
    if not name or realm then name, realm = UnitName(unit) end
    local rankNumber
    _, rankNumber = GetPVPRankInfo(UnitPVPRank(unit), unit)
    if isPlayer and rankNumber > 0 then
        -- RankNumber UnitName PlayerRealm
        GameTooltip:AddLine( string.format(L.strformat_ranknumber .. " %s",
                             rankNumber,
                             (name or L.UnknownEntity) .. ( (realm and
                             realm ~= PlayerRealm and (" (" .. realm .. ")") ) or "")))
    else -- UnitName PlayerRealm
        GameTooltip:AddLine( (name or L.UnknownEntity) .. ( (realm and
                             realm ~= PlayerRealm and (" (" .. realm .. ")") ) or ""))
    end

    -- Reaction coloring
    local bdR,bdG,bdB = 0,0,0
    if not isPlayerOrPet then isPlayerOrPet = UnitPlayerControlled(unit) end
    local reactionNum = UnitReaction(unit, "player")
    local deadOrTappedColour, reactionText
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
        bdR,bdG,bdB = 0.54,0.54,0.54
        GameTooltipTextLeft1:SetTextColor(0.54,0.54,0.54)
        deadOrTappedColour = "888888"
    elseif ( isPlayerOrPet and UnitCanAttack(unit, "player") ) or UnitIsTappedByPlayer(unit) or
            ( not isPlayerOrPet and reactionNum ~= nil and reactionNum > 0 and reactionNum <= 2 ) then
        -- hostile
        GameTooltipTextLeft1:SetTextColor(  FACTION_BAR_COLORS[reactionNum or 2].r,
                                            FACTION_BAR_COLORS[reactionNum or 2].g,
                                            FACTION_BAR_COLORS[reactionNum or 2].b)
        reactionText = ( reactionNum ~= nil and reactionNum > 0 and db["ReactionText"] and
                        _G["FACTION_STANDING_LABEL" .. reactionNum] ) or FACTION_STANDING_LABEL2

        if isPlayerOrPet and not UnitCanAttack("player", unit) then
            bdR,bdG,bdB = 0.5,0.2,0.1
        else
            bdR,bdG,bdB = 0.5,0.0,0.0
        end
    elseif ( isPlayerOrPet and UnitCanAttack("player",unit) ) or
            ( not isPlayerOrPet and reactionNum and reactionNum <= 4 ) then
        -- neutral
        GameTooltipTextLeft1:SetTextColor(  FACTION_BAR_COLORS[4].r,
                                            FACTION_BAR_COLORS[4].g,
                                            FACTION_BAR_COLORS[4].b)

        if db["ReactionText"] then reactionText = FACTION_STANDING_LABEL4 end
        bdR,bdG,bdB = 0.5, 0.5, 0.0
    else -- friendly
        reactionText = FACTION_STANDING_LABEL5
        if isPlayerOrPet then
            bdR,bdG,bdB = 0.0, 0.0, 0.5
        else
            bdR,bdG,bdB = 0.0, 0.5, 0.0
        end
        if UnitIsPVP(unit) then -- friendly, PvP-enabled
            GameTooltipTextLeft1:SetTextColor(  FACTION_BAR_COLORS[6].r,
                                                FACTION_BAR_COLORS[6].g,
                                                FACTION_BAR_COLORS[6].b)
        else
            GameTooltipTextLeft1:SetTextColor(  (not isPlayerOrPet and FACTION_BAR_COLORS[reactionNum or 5].r) or 0,
                                                (not isPlayerOrPet and FACTION_BAR_COLORS[reactionNum or 5].g) or 0.67,
                                                (not isPlayerOrPet and FACTION_BAR_COLORS[reactionNum or 5].b) or 1.0)

        end
    end

    -- We like to know who our friends are.
    if isPlayer and reactionText == FACTION_STANDING_LABEL5 and realm == PlayerRealm and db["Friends"] ~= 2 then
        local numFriends = GetNumFriends()
        local friendName, friendLevel
        for i = 1,numFriends,1 do
            friendName,friendLevel = GetFriendInfo(i)
            if friendName and friendName ~= name and friendLevel ~= nil and friendLevel > 0 then
                if db["Friends"] == 1 or db["BGColor"] == 1 or db["BGColor"] == 3 then
                    GameTooltipTextLeft1:SetTextColor(0.58, 0.0, 0.83)
                else
                    bdR,bdG,bdB = 0.29, 0.0, 0.42
                end
                break
            end
        end
    end

    -- Set the color of the trade or guild line, if it's available. This
    -- line comes before the level line.
    if afterLevelLine and afterLevelLine > 3 then
        line = lines[2]

        if line then
            GameTooltip:AddLine( "<" .. line.. ">" )
            line = _G["GameTooltipTextLeft" .. GameTooltip:NumLines()]
            -- We like to know who our guild members are.
            if guildName and IsInGuild() and guildName == GetGuildInfo("player")
            and db["Friends"] ~= 2 then
            --[[
                if not db["Friends"] and not UnitIsUnit(unit, "player")
                and db["BGColor"] ~= 3 and db["BGColor"] ~= 1 then
                    bdR,bdG,bdB = 0.4, 0.1, 0.5
                    line:SetTextColor( GameTooltipTextLeft1:GetTextColor() )
                else
            --]]
                    line:SetTextColor( 0.58, 0.0, 0.83 )
            --    end
            else -- other guilds or NPC trade line
                line:SetTextColor( GameTooltipTextLeft1:GetTextColor() )
            end
        end
        for i = 3, afterLevelLine - 2, 1 do -- add misc. lines before level line
            GameTooltip:AddLine( lines[i], GameTooltipTextLeft1:GetTextColor() )
        end
    end

    -- Check for a dead unit, but try to leave out Hunter's Feign Death
    if not isDead then
        isDead = UnitHealth(unit) <= 0 and ( not isPlayer or UnitIsDeadOrGhost(unit) or UnitIsCorpse(unit) )
    end
    if isDead then
        bdR,bdG,bdB = 0.54, 0.54, 0.54
        GameTooltipTextLeft1:SetTextColor(0.54,0.54,0.54)
        deadOrTappedColour = "888888"
    end

    -- The Level Line
    if levelLine then
        local levelColour
        local level = UnitLevel(unit)
        local levelDiff = level - UnitLevel("player") -- Level difference
        if levelDiff and UnitFactionGroup(unit) ~= UnitFactionGroup("player") then
            if levelDiff >= 5 or level == -1 then levelColour = "FF0000"
            elseif levelDiff >= 3 then levelColour = "FF6600"
            elseif levelDiff >= -2 then levelColour = "FFFF00"
            elseif -levelDiff <= GetQuestGreenRange() then levelColour = "00FF00"
            else levelColour = "888888"
            end
        end

        local levelLineText
        if level and level >= 1 then
            levelLineText = "|cFF" .. (deadOrTappedColour or levelColour or "FFCC00") ..
                            level .. "|r"
        elseif db["LevelGuess"] and ulevel and ulevel == -1 and ulevel < 60 then
            levelLineText = "|cFF" .. (deadOrTappedColour or levelColour or "FFCC00") ..
                            ">" .. (UnitLevel("player") + 10 ) .. "|r"
        else
            levelLineText = "|cFF" .. (deadOrTappedColour or levelColour or "FFCC00") .. "??|r"
        end

        if isPlayer then
             local race = UnitRace(unit)
             levelLineText = levelLineText .. " |cFF" .. (deadOrTappedColour or "DDEEAA") ..
                             (race or "") .. " |r|cFF" ..
                             (deadOrTappedColour or ColourPlayer(unit)) .. (UnitClass(unit) or "" ) .. "|r"
        else -- pet or npc
            if not isPlayerOrPet then
                local npcType = UnitClassification(unit) -- Elite,etc. status
                if npcType and npcType ~= "normal" then
                    if npcType == "elite" then
                        levelLineText = levelLineText .. " |cFF" .. (deadOrTappedColour or "FFCC00") .. ELITE .. "|r"
                    elseif npcType == "worldboss" then
                        levelLineText = levelLineText .. " |cFF" .. (deadOrTappedColour or "FF0000") .. BOSS .. "|r"
                    elseif npcType == "rare" then
                        levelLineText = levelLineText .. " |cFF" .. (deadOrTappedColour or "FF66FF") ..
                                                         ITEM_QUALITY3_DESC .. "|r"
                    elseif npcType == "rareelite" then
                        levelLineText = levelLineText .. " |cFF" .. (deadOrTappedColour or "FFAAFF") ..
                                                            L["Rare Elite"] .. "|r"
                    else -- should never get here
                        levelLineText = levelLineText .. " [|cFF" ..
                                        (deadOrTappedColour or "FFFFFF") .. npcType .. "|r]"
                    end
                end
             end
             if isPlayerOrPet then
                 levelLineText = levelLineText .. " |cFF" .. (deadOrTappedColour or "DDEEAA") ..
                                                 (UnitCreatureFamily(unit) or L.Unknown) .. "|r"
             else
                 levelLineText = levelLineText .. " |cFF" .. (deadOrTappedColour or "DDEEAA") ..
                                                 (UnitCreatureType(unit) or L.Unknown) .. "|r"
             end
         end

        -- add corpse/tapped line
         if deadOrTappedColour then
             levelLineText = levelLineText .. " |cFF" .. deadOrTappedColour .. "(" ..
                             ( ( isDead and CORPSE ) or L.Tapped ) .. ")|r"
         end

         GameTooltip:AddLine( levelLineText )
    end -- the Level Line

    -- add missing lines
    if afterLevelLine then
        for i = afterLevelLine, numLines, 1 do
            line = lines[i]
            if not strfind(line, PVP_ENABLED, 1, true) then
                if deadOrTappedColor then
                    GameTooltip:AddLine( line, GameTooltipTextLeft1:GetTextColor() )
                else
                    GameTooltip:AddLine( line )
                end
            end
        end
    end

    if db["BGColor"] ~= 1 and (isPlayerOrPet or deadOrTappedColour or db["BGColor"] == 2) then
        if db["BGColor"] == 3 and not deadOrTappedColour then
            bdR,bdG,bdB = 0,0,0
        end
        GameTooltip:SetBackdropColor(bdR, bdG, bdB)
    end

    if db["Border"] ~= 1 then
        if db["Border"] == 2 and not deadOrTappedColour then
            GameTooltip:SetBackdropBorderColor(0,0,0,0) -- ghetto hide
        else
            GameTooltip:SetBackdropBorderColor(bdR * 1.5 , bdG * 1.5, bdB * 1.5, 1)
        end
    end
end

local Hook_OnTooltipSetUnit, OnUpdateSet, IgnoreTooltipClearedHook, OnTooltipCleared
local Original_GameTooltip_OnTooltipCleared = nil
if not modulecore then
    local Original_GameTooltip_OnTooltipSetUnit = nil
    local IgnoreTooltipClearedHook
    local function OnTooltipSetUnit(self,...)
        IgnoreTooltipClearedHook = true
        if Original_GameTooltip_OnTooltipSetUnit then
            Original_GameTooltip_OnTooltipSetUnit(self,...)
        end
        if not db["FormatDisabled"] then
            local unit
            _, unit = self:GetUnit()
            module:TooltipFormat(unit)
            GameTooltip:Show()
            GameTooltipStatusBar:Show()
            EventFrame.unit = unit
        end
        IgnoreTooltipClearedHook = nil
    end

    Hook_OnTooltipSetUnit = function(ignorethisarg, tooltip)
        if Original_GameTooltip_OnTooltipSetUnit == nil then
            Original_GameTooltip_OnTooltipSetUnit  = tooltip:GetScript("OnTooltipSetUnit")
            if not Original_GameTooltip_OnTooltipSetUnit then Original_GameTooltip_OnTooltipSetUnit = false end
            tooltip:SetScript("OnTooltipSetUnit", OnTooltipSetUnit)
        end
    end
    OnTooltipCleared = function(self,...)
        if Original_GameTooltip_OnTooltipCleared then
            Original_GameTooltip_OnTooltipCleared(self,...)
        end
        if OnUpdateSet and not IgnoreTooltipClearedHook then
            EventFrame:SetScript("OnUpdate", nil)
            OnUpdateSet = nil
            EventFrame.unit = nil
        end
    end
    --[[
    local function OnHide(self,...)
        if Original_GameTooltip_OnHide then
            if OnUpdateSet then
                EventFrame:SetScript("OnUpdate", nil)
                OnUpdateSet = nil
                EventFrame.unit = nil
            end
        end
    end
    --]]
end

--[[-------------------------------------------------------
-- Anchoring and Positioning
---------------------------------------------------------]]

local SetDefaultAnchor

-- Used to stick GameTooltip to the cursor with offsets.
local getcpos = _G.GetCursorPosition
local function Anchor_OnUpdate(self, time)
        if self.unit then
            local unit
            _, unit = GameTooltip:GetUnit()
            if unit and not UnitExists(unit) then GameTooltip:Hide() end
        end
        local x,y = getcpos()
        local uiscale,tscale = UIParent:GetScale(), GameTooltip:GetScale()
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint(self.Anchor or "BOTTOM", UIParent, "BOTTOMLEFT",
                             (x + (self.OffX or 0)) / uiscale / tscale,
                             (y + (self.OffY or 0)) / uiscale / tscale)
end

local Original_GameTooltip_SetDefaultAnchor = nil
SetDefaultAnchor = function(tooltip,owner,...)
    if Original_GameTooltip_SetDefaultAnchor then
        Original_GameTooltip_SetDefaultAnchor(tooltip,owner,...)
    end
    if not module.onstandby and tooltip == GameTooltip then
        if OnUpdateSet then EventFrame:SetScript("OnUpdate", nil) end
        if owner ~= UIParent then
            if db["FAnchor"] or db["FOffX"] ~= nil or db["FOffY"] ~= nil then
                if db["FAnchor"] == "CURSOR" then
                    if (db["FOffX"] ~= nil and db["FOffX"] > 0) or (db["FOffY"] ~= nil and db["FOffY"] > 0) or
                    db["FCursorAnchor"] then
                        EventFrame.OffX,EventFrame.OffY,EventFrame.Anchor = db["FOffX"], db["FOffY"], db["FCursorAnchor"]
                        EventFrame:SetScript("OnUpdate", Anchor_OnUpdate)
                        OnUpdateSet = true
                    else
                        tooltip:SetOwner(owner, "ANCHOR_CURSOR")
                    end
                else
                    tooltip:SetOwner(owner, "ANCHOR_NONE")
                    tooltip:ClearAllPoints()
                    tooltip:SetPoint(db["FAnchor"] or "BOTTOMRIGHT",
                                     UIParent,
                                     db["FAnchor"] or "BOTTOMRIGHT",
                                     (db["FOffX"] or 0) - ((not db["FAnchor"] and (CONTAINER_OFFSET_X - 13)) or 0),
                                     (db["FOffY"] or 0) + ((not db["FAnchor"] and CONTAINER_OFFSET_Y) or 0))
                end
            end
        elseif db["MAnchor"] ~= "GAMEDEFAULT" or db["MOffX"] ~= nil or db["MOffY"] ~= nil then
            if not db["MAnchor"] then
                if (db["MOffX"] ~= nil and db["MOffX"] > 0) or (db["MOffY"] ~= nil and db["MOffY"] > 0) or
                db["MCursorAnchor"] then
                    EventFrame.OffX,EventFrame.OffY,EventFrame.Anchor = db["MOffX"], db["MOffY"], db["MCursorAnchor"]
                    EventFrame:SetScript("OnUpdate", Anchor_OnUpdate)
                    OnUpdateSet = true
                else
                    tooltip:SetOwner(owner, "ANCHOR_CURSOR")
                end
            else
                tooltip:SetOwner(owner, "ANCHOR_NONE")
                tooltip:ClearAllPoints()
                tooltip:SetPoint((db["MAnchor"] ~= "GAMEDEFAULT" and db["MAnchor"]) or "BOTTOMRIGHT",
                                 UIParent,
                                 (db["MAnchor"] ~= "GAMEDEFAULT" and db["MAnchor"]) or "BOTTOMRIGHT",
                                 (db["MOffX"] or 0) - ((db["MAnchor"] == "GAMEDEFAULT"
                                  and (CONTAINER_OFFSET_X - 13)) or 0),
                                 (db["MOffY"] or 0) + ((db["MAnchor"] == "GAMEDEFAULT" and CONTAINER_OFFSET_Y) or 0))
            end
        end
    end
end

--[[-------------------------------------------------------
-- Initialization States
----------------------------------------------------------]]

function module:ReInitialize()
    if not db["FormatDisabled"] then
        if not modulecore and not ClassColours then
            ClassColours = {}
            for k,v in pairs(RAID_CLASS_COLORS) do
                ClassColours[k] = strformat("%2x%2x%2x", v.r*255, v.g*255, v.b*255)
            end
        end
        if not lines then lines = {} end
    end
end

function module:Standby()
    lines,ClassColours = nil,nil
end

--[[
function module:Wakeup()
end
--]]

-- For initializing the database and hooking functions.
function module:Initialize()
    db = db or
        {
            -- The below options are commented out by default. To select the
            -- TinyTip default, set it to nil.
            --[[
                ["FormatDisabled"] = nil,    -- This will disable all formating is set to true.
                ["BGColor"] = nil,           -- 1 will disable colouring the background. 3 will make it black,
                                             -- except for Tapped/Dead. 2 will colour NPCs as well as PCs.
                ["Border"] = nil,            -- 1 will disable colouring the border. 2 will make it always black.
                                             -- 3 will make it a similiar colour to the background for NPCs.
                ["FAnchor"] = nil,           -- "BOTTOMRIGHT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT", "CURSOR"
                                             -- Used only in Frames. TinyTip default is BOTTOMRIGHT.
                ["FCursorAnchor"] = nil,     -- Which side of the cursor to anchor for frame units.
                                             -- TinyTip's default is BOTTOM.
                ["MAnchor"] = nil,           -- Used only for Mouseover units. Options same as above, with the
                                             -- addition of "GAMEDEFAULT". TinyTip Default is CURSOR.
                ["MCursorAnchor"] = nil,     -- Which side of the cursor to anchor for mouseover (world).
                                             -- TinyTip's default is BOTTOM.
                ["FOffX"] = nil,             -- X offset for Frame units (horizontal).
                ["FOffY"] = nil,             -- Y offset for Frame units (vertical).
                ["MOffX"] = nil,             -- Offset for Mouseover units (World Frame).
                ["MOffY"] = nil              -- "     "       "       "       "
            --]]
        }

    Hook_OnTooltipSetUnit(self, GameTooltip, TooltipFormat)

    if not modulecore and Original_GameTooltip_OnTooltipCleared == nil then
        Original_GameTooltip_OnTooltipCleared  = GameTooltip:GetScript("OnTooltipCleared")
        if not Original_GameTooltip_OnTooltipCleared then Original_GameTooltip_OnTooltipCleared = false end
        GameTooltip:SetScript("OnTooltipCleared", OnTooltipCleared)
    end

    if Original_GameTooltip_SetDefaultAnchor == nil then
        Original_GameTooltip_SetDefaultAnchor = _G.GameTooltip_SetDefaultAnchor
        if not Original_GameTooltip_SetDefaultAnchor then Original_GameTooltip_SetDefaultAnchor = false end
        _G.GameTooltip_SetDefaultAnchor = SetDefaultAnchor
    end
end

-- Setting variables that only need to be set once goes here.
function module:Enable()
       PlayerRealm = GetRealmName()
       self:ReInitialize()
end

-- TinyTipModuleCore NOT loaded
if not modulecore then
    local function OnEvent(self, event, arg1)
        if event == "ADDON_LOADED" and arg1 == "TinyTip" then
            module:Initialize()
            if not module.loaded then
                module:Enable()
            end
            self:UnregisterEvent("ADDON_LOADED")
        elseif event == "PLAYER_LOGIN" then
                module.loaded = true
                module:Enable()
        end
    end
    EventFrame = CreateFrame("Frame", nil, UIParent)
    EventFrame:RegisterEvent("ADDON_LOADED")
    EventFrame:RegisterEvent("PLAYER_LOGIN")
    EventFrame:SetScript("OnEvent", OnEvent)
end

--[[
function TinyTip:Initialize()
    if not _G.TinyTipDB then db = {} end
end

function TinyTip:Enable()
    self:ReInitialize()
    self.loaded = true
end
--]]
