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
-- values (within the OnEvent function).
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

local ClassColours = {}
for k,v in pairs(RAID_CLASS_COLORS) do
    ClassColours[k] = strformat("%2x%2x%2x", v.r*255, v.g*255, v.b*255)
end

local _, db, PlayerRealm

-- _, TinyTip = GetAddOnInfo("TinyTip")
-- TinyTip = DongleStub("Dongle-1.0"):New(TinyTip)
if not _G.TinyTip then
    _G.TinyTip = { ["dongled"] = nil }
end
local TinyTip = _G.TinyTip

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
-- Formating and Skinning
-------------------------------------------------------------------------]]

-- for Tem
function TinyTip:SmoothBorder()
    if not db["NormalBorder"] and not self.onstandby then
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
        })

        GameTooltip:SetBackdropColor( 0, 0, 0, 0.8)
        GameTooltip:SetBackdropBorderColor( 0, 0, 0, 1)
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
        })

        GameTooltip:SetBackdropColor( 0, 0, 0, 1)
    end
end

-- Return color format in HEX from Blizzard percentage RGB
-- for the class.
function TinyTip:ColourPlayer(unit)
    local c
    _,c = UnitClass(unit)
    if c and ClassColours[c] then return ClassColours[c] end
    return "FFFFFF"
end

local lines
function TinyTip:TooltipFormat(unit)
    if not UnitExists(unit) then return end

    local numLines = GameTooltip:NumLines()
    local guildName = GetGuildInfo(unit)
    local line, levelLine, afterLevelLine
    for i = 1,numLines,1 do
        lines[i] = _G[ "GameTooltipTextLeft" .. i ]
        line = lines[i]
        if line:IsShown() then
            line = line:GetText()
            if line and line ~= guildName and strfind(line, L.Level, 1, true) then
                levelLine = true
                afterLevelLine = i + 1
            end
        end
    end
    GameTooltip:ClearLines()

    -- First Line
    local isPlayer = UnitIsPlayer(unit)
    local name, realm = UnitName(unit)
    local rankNumber
    _, rankNumber = GetPVPRankInfo(UnitPVPRank(unit), unit)
    if isPlayer and rankNumber > 0 then
        -- RankNumber UnitName PlayerRealm
        GameTooltip:AddLine( string.format(L.strformat_ranknumber .. " %s",
                             rankNumber,
                             (name or L.Unknown) .. ( (realm and
                             realm ~= PlayerRealm and (" (" .. realm .. ")") ) or "")))
    else -- UnitName PlayerRealm
        GameTooltip:AddLine( (name or L.Unknown) .. ( (realm and
                             realm ~= PlayerRealm and (" (" .. realm .. ")") ) or ""))
    end

    -- Reaction coloring
    local bdR,bdG,bdB = 0,0,0
    local isPlayerOrPet = UnitPlayerControlled(unit)
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
    local isDead
    if UnitHealth(unit) <= 0 and ( not isPlayer or UnitIsDeadOrGhost(unit)
                                    or UnitIsCorpse(unit) ) then
        bdR,bdG,bdB = 0.54, 0.54, 0.54
        GameTooltipTextLeft1:SetTextColor(0.54,0.54,0.54)
        deadOrTappedColour = "888888"
        isDead = true
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
                             (deadOrTappedColour or self:ColourPlayer(unit)) .. (UnitClass(unit) or "" ) .. "|r"
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
                                                 (UnitCreatureFamily(unit) or "") .. "|r"
             else
                 levelLineText = levelLineText .. " |cFF" .. (deadOrTappedColour or "DDEEAA") ..
                                                 (UnitCreatureType(unit) or "") .. "|r"
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

   -- if self.tmodules and self.isregistered["TinyTip_Format_BeforeShow"]  then self:ModuleMessage("TinyTip_Format_BeforeShow", unit, name, realm, guildName, isPlayer, isPlayerOrPet) end

    GameTooltip:Show() -- used to re-size gametooltip

   -- if self.tmodules and self.isregistered["TinyTip_Format_AfterShow"] then self:ModuleMessage("TinyTip_Format_AfterShow", unit, name, realm, guildName, isPlayer, isPlayerOrPet) end
end

local Original_GameTooltip_OnTooltipSetUnit = nil
local function OnTooltipSetUnit(self,...)
    if Original_Gametooltip_OnTooltipSetUnit then
        Original_GameTooltip_SetUnit(self,...)
    end
    if not TinyTip.onstandby then
        local unit
        _, unit = self:GetUnit()
        if not db["FormatDisabled"] then TinyTip:TooltipFormat(unit) end
    end
end

--[[-------------------------------------------------------
-- Anchoring and Positioning
---------------------------------------------------------]]

local Original_GameTooltip_SetDefaultAnchor = nil
local function SetDefaultAnchor(tooltip,owner,...)
    if Original_GameTooltip_SetDefaultAnchor then
        Original_GameTooltip_SetDefaultAnchor(tooltip,owner,...)
    end
    if not TinyTip.onstandby and tooltip == GameTooltip then
        if owner ~= UIParent then
            if db["FAnchor"] or db["FOffX"] or db["FOffY"] then
                if db["FAnchor"] == "CURSOR" then
                        tooltip:SetOwner(owner, "ANCHOR_CURSOR")
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
        elseif db["MAnchor"] ~= "GAMEDEFAULT" or db["MOffX"] or db["MOffY"] then
            if not db["MAnchor"] then
                tooltip:SetOwner(owner, "ANCHOR_CURSOR")
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
-- Standby Modes
----------------------------------------------------------]]

-- Called when coming out of Standby, first initialization, or options change.
function TinyTip:ReInitialize()
       -- self:UnregisterAllEvents()
       if not lines then lines = {} end

        PlayerRealm = GetRealmName()
        self:SmoothBorder()

        if Original_GameTooltip_SetDefaultAnchor == nil then
            Original_GameTooltip_SetDefaultAnchor = _G.GameTooltip_SetDefaultAnchor
            if not Original_GameTooltip_SetDefaultAnchor then Original_GameTooltip_SetDefaultAnchor = false end
            _G.GameTooltip_SetDefaultAnchor = SetDefaultAnchor
        end
        if Original_GameTooltip_OnTooltipSetUnit == nil then
            Original_GameTooltip_OnTooltipSetUnit = GameTooltip:GetScript("OnTooltipSetUnit")
            if not Original_GameTooltip_OnTooltipSetUnit then Original_GameTooltip_OnTooltipSetUnit = false end
            GameTooltip:SetScript("OnTooltipSetUnit", OnTooltipSetUnit)
        end
end

function TinyTip:Standby()
    lines = nil
    self.onstandby = true
    --self:UnregisterAllEvents()
    self:SmoothBorder()
end

function TinyTip:Wakeup()
    self.onstandby = nil
    self:ReInitialize()
end

--[[-------------------------------------------------------
-- Initialization
----------------------------------------------------------]]

if not TinyTip.dongled then
    local function OnEvent(self, event)
        if event == "ADDON_LOADED" then
            if not db then
                db = {
                    --[[
                    ["FormatDisabled"] = true,   -- This will disable all formating, but not positioning.
                    ["BGColor"] = 1,             -- 1 will disable colouring the background. 3 will make it black,
                                                 -- except for Tapped/Dead. 2 will colour NPCs as well as PCs.
                    ["Border"] = 1,              -- 1 will disable colouring the border. 2 will make it always black.
                                                 -- 3 will make it a similiar colour to the background for NPCs.
                    ["FAnchor"] = nil,           -- "BOTTOMRIGHT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT", "CURSOR"
                                                 -- Used only in Frames. TinyTip default is BOTTOMRIGHT.
                    ["MAnchor"] = "GAMEDEFAULT", -- Used only for Mouseover units. Options same as above, with the
                                                 -- addition of "GAMEDEFAULT". TinyTip Default is CURSOR.
                    ["FOffX"] = nil,             -- X offset for Frame units (horizontal).
                    ["FOffY"] = nil,             -- Y offset for Frame units (vertical).
                    ["MOffX"] = nil,             -- Offset for Mouseover units (World Frame).
                    ["MOffY"] = nil              -- "     "       "       "       "
                    --]]
                }
            end
            if not TinyTip.loaded then
                TinyTip:ReInitialize()
                TinyTip.loaded = true
            end
        elseif event == "PLAYER_LOGIN" then
            if not TinyTip.loaded then
                TinyTip:ReInitialize()
                TinyTip.loaded = true
            end
        end
    end
    local EventFrame = CreateFrame("Frame", nil, UIParent)
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
