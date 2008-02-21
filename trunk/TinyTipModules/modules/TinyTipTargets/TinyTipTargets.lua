--[[
-- Name: TinyTipTargets
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date:
-- Release Version: 2.0
--
-- Thanks to #wowace, #dongle, and #wowi-lounge on Freenode as always for
-- optimization assistance. Thanks to AF_Tooltip_Mini for the idea that
-- became TinyTip.
--
-- Note: If running TinyTipTargets without TinyTipModules, see
-- StandAloneConfig.lua for manual configuration options.
--]]

local _G = getfenv(0)

--[[---------------------------------------------
-- Local References
----------------------------------------------]]
local strformat, strfind = string.format
local GameTooltip = _G.GameTooltip
local UnitIsUnit, UnitExists, UnitName, UnitInRaid, UnitInParty, GetNumPartyMembers, GetNumRaidMembers = UnitIsUnit, UnitExists, UnitName, UnitInRaid, UnitInParty, GetNumPartyMembers, GetNumRaidMembers

local L = _G.TinyTipLocale

--[[---------------------------------------------
-- Local Variables
----------------------------------------------]]

local _, ClassColours

--[[----------------------------------------------------------------------
-- Module Support
------------------------------------------------------------------------]]

local modulecore = TinyTipModules

local module, UpdateFrame, db, ColourPlayer, HookOnTooltipSetUnit

if not modulecore then
    module = {}
else
    _, module = GetAddOnInfo("TinyTipTargets")
    module = modulecore:NewModule(module or "TinyTipTargets")
    db = modulecore:GetDB()
    ColourPlayer = modulecore.ColourPlayer
    HookOnTooltipSetUnit = modulecore.HookOnTooltipSetUnit
end

--[[----------------------------------------------------------------------
-- Main Function
-------------------------------------------------------------------------]]

-- Return color format in HEX from Blizzard percentage RGB
-- for the class.
if not modulecore then
    ColourPlayer = function(unit)
        local _,c = UnitClass(unit)
        return ( c and UnitIsPlayer(unit) and ClassColours[c]) or "FFFFFF"
    end
end

function module.AddTargets(unit)
    local self = module
    if not UnitExists(unit) then return end

    -- Unit on the tooltip
    if db["TargetsTooltipUnit"] ~= "DISABLED" then
        local target = unit .. "target"
        if UnitExists(target) then
            if db["TargetsTooltipUnit"] == "APPEND" then
                GameTooltip:AppendText( strformat(" : |cFF%s%s|r",
                                        ColourPlayer(target),
                                        (UnitIsUnit(target, "player") and L["<< YOU >>"]) or UnitName(target) or L["UnknownEntity"]) )
            else
                GameTooltip:AddLine( strformat("%s: |cFF%s%s|r",
                                     L["Targeting"],
                                     ColourPlayer(target),
                                     (UnitIsUnit(target, "player") and L["<< YOU >>"]) or UnitName(target) or L["UnknownEntity"]) )
            end
        end
    end

    -- If party is targeting unit on the tooltip
    local num = GetNumPartyMembers() or 0
    if db["TargetsParty"] ~= "DISABLED" and num > 0 then
        local result, isfocus
        local showall = db["TargetsParty"] == "SHOWALL"
        for i = 1,num do
            local uid = "party" .. i
            local tuid = uid .. "target"
            if UnitExists(uid) and not UnitIsUnit(uid, "player") and
               UnitExists(tuid) and UnitIsUnit(unit, tuid) then
                if UnitIsUnit(uid, "focus") then isfocus = true end
                if showall then
                    result = (result or (L["Targeted by"] .. ":\n")) .. "|cFF" .. ColourPlayer(uid) ..
                             (UnitName(uid) or L["Unknown"]) .. "|r\n"
                else
                    result = (result or 0) + 1
                end
            end
        end
        if result then
            if showall then
                GameTooltip:AddLine(result)
            else
                GameTooltip:AddLine( L["Targeted by"] .. ": (" .. result .. ") " .. L["PARTY"] ..
                                     ( (isfocus and " (*)") or "")
                                   )
            end
        end
    end

    num = GetNumRaidMembers() or 0
    if db["TargetsRaid"] ~= "DISABLED" and num > 0 then
        local result, isfocus, isma, ismt, _
        for i = 1,num do
            local uid = "raid" .. i
            local tuid = uid .. "target"
            if UnitExists(uid) and not UnitIsUnit(uid, "player") and
               UnitExists(tuid) and UnitIsUnit(unit, tuid) then
                    result = (result or 0) + 1
                    _, _, _, _, _, _, _, _, _, role = GetRaidRosterInfo(i)
                    if role == "mainassist" then isma = true end
                    if role == "maintank" then ismt = true end
                    if UnitIsUnit(uid, "focus") then isfocus = true end
            end
        end
        if result then
            GameTooltip:AddLine( L["Targeted by"] .. ": (" .. result .. ") " .. L["RAID"] ..
                                 ( (isfocus and " (*)") or "") ..
                                 ( (ismt and " (!)") or "") ..
                                 ( (isma and " <<") or "")
            )
        end
    end
end

--[[-------------------------------------------------------
-- Event Handlers
---------------------------------------------------------]]

if not modulecore then
    local OriginalOnTooltipSetUnit = nil
    local function OnTooltipSetUnit(self,...)
        if OriginalOnTooltipSetUnit then
            OriginalOnTooltipSetUnit(self,...)
        end
            local _, unit = self:GetUnit()
            module.AddTargets(unit)
            GameTooltip:Show()
    end
    HookOnTooltipSetUnit = function(tooltip)
        if OriginalOnTooltipSetUnit == nil then
            OriginalOnTooltipSetUnit  = tooltip:GetScript("OnTooltipSetUnit") or false
            tooltip:SetScript("OnTooltipSetUnit", AddTargets)
        end
    end
end

-- Refresh target list.
function module:UNIT_TARGET(unit)
    if not unit or not GameTooltip:IsVisible() or not UnitExists(unit) or not GameTooltip:GetUnit() then return end
    if (db["TargetsTooltipUnit"] ~= "DISABLED" and UnitIsUnit(unit, GameTooltip:GetUnit()) ) or
       (db["TargetsParty"] ~= "DISABLED" and UnitInParty(unit) ) or
       (db["TargetsRaid"] ~= "DISABLED" and UnitInRaid(unit) ) then
            GameTooltip:SetUnit( GameTooltip:GetUnit() ) -- force re-format
    end
end

--[[-------------------------------------------------------
-- Initialization States
----------------------------------------------------------]]
local EventFrame

function module:ReInitialize()
    if not modulecore and not ClassColours then
        ClassColours = {}
        for k,v in pairs(RAID_CLASS_COLORS) do
            ClassColours[k] = strformat("%2x%2x%2x", v.r*255, v.g*255, v.b*255)
        end
    end
end

function module:Standby()
    if not modulecore then ClassColours = nil end
end

-- For initializing the database and hooking functions.
function module:Initialize()
    db = db or TinyTipTargets_StandAloneDB or {}

    HookOnTooltipSetUnit(GameTooltip, self.AddTargets)
    if modulecore then
        self:RegisterEvent("UNIT_TARGET")
    else
       EventFrame:RegisterEvent("UNIT_TARGET")
    end
end

-- Setting variables that only need to be set once goes here.
function module:Enable()
       self:ReInitialize()
end

-- TinyTipModules NOT loaded
if not modulecore then
    local function OnEvent(self, event, arg1, ...)
        if event == "ADDON_LOADED" and arg1 == "TinyTipTargets" then
            module:Initialize()
            if not module.loaded then
                module:Enable()
            end
            self:UnregisterEvent("ADDON_LOADED")
        elseif event == "PLAYER_LOGIN" then
                module.loaded = true
                module:Enable()
        elseif event == "UNIT_TARGET" then
            module:UNIT_TARGET(arg1, ...)
        end
    end
    EventFrame = CreateFrame("Frame", nil, GameTooltip)
    EventFrame:RegisterEvent("ADDON_LOADED")
    EventFrame:RegisterEvent("PLAYER_LOGIN")
    EventFrame:SetScript("OnEvent", OnEvent)
end
