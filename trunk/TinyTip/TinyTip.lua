--[[
-- Name: TinyTip
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date:
-- Release Version: 2.0
--
-- This provides the modular core of TinyTip. It is
-- required for proper database functionality and
-- best optimization with a lot of modules.
--]]

local _G = getfenv(0)

--[[---------------------------------------------
-- Local References
----------------------------------------------]]
local strformat = string.format
local UIParent, GameTooltip = _G.UIParent, _G.GameTooltip
local UnitClass, UnitIsPlayer = UnitClass, UnitIsPlayer

local L = _G.TinyTipLocale
local classColours, hooks, origfuncs

--[[----------------------------------------------------------------------
-- Module Initialization
------------------------------------------------------------------------]]

local name, localizedname = GetAddOnInfo("TinyTip")
core = DongleStub("Dongle-1.0"):New(name)
core.name, core.localizedname = name, localizedname or name
_G.TinyTip = core

--[[----------------------------------------------------------------------
-- Local Functions
------------------------------------------------------------------------]]

local function handlerOnTooltipSetUnit(origfunc,handlers,self,...)
    if not handlers then
        if origfunc then
            return origfunc(self,...)
        end
    else
        origfunc(self,...)
    end

    local _, unit = self:GetUnit()
    for i = 1,#handlers do
        handlers[i](unit)
    end

    self:Show()
end

local function handler(origfunc,handlers,...)
    if not handlers then
        if origfunc then
            return origfunc(...)
        end
    else
        origfunc(...)
    end

    for i = 1,#handlers do
        handlers[i](...)
    end
end

local function isHooked(handlers, handler)
    if not handlers then return true end
    for _,v in ipairs(handlers) do
        if v == handler then
            return true
        end
    end
end

local function hook(object, func, mainhandler, handler, isscript, insert)
    if not origfuncs then origfuncs = {} end
    if not origfuncs[object] then origfuncs[object] = {} end
    if not hooks then hooks = {} end
    if not hooks[object] then hooks[object] = { [func] = {} } end

    if not isHooked(hooks[object][func], handler) then
        if insert then
            table.insert(hooks[object][func], 1, handler)
        else
            table.insert(hooks[object][func], handler)
        end
    end

    if origfuncs[object][func] == nil then
        if isscript then
            origfuncs[object][func] = object:GetScript(func) or false
            object:SetScript(func, function(...) mainhandler(origfuncs[object][func], hooks[object][func], ...) end)
        else
            origfuncs[object][func] = object[func] or false
            object[func] = function(...) mainhandler(origfuncs[object][func], hooks[object][func], ...) end
        end
    end
end

local function unhook(object, func, handler)
    if not hooks or not hooks[object] or not hooks[object][func] then return end
    local handlers = hooks[object][func]
    for i = 1, #handlers do
        if handlers[i] == handler then
            table.remove(handlers, i)
            return true
        end
    end
end

--[[----------------------------------------------------------------------
-- Public Functions
------------------------------------------------------------------------]]

function core.ColourPlayer(unit)
    local _,c = UnitClass(unit)
    return ( c and UnitIsPlayer(unit) and classColours[c] ) or "FFFFFF"
end

--[[----------------------------------------------------------------------
-- Shared Hooks
------------------------------------------------------------------------]]

function core.HookOnTooltipSetUnit(tooltip, handler, insert)
    hook(tooltip, "OnTooltipSetUnit", handlerOnTooltipSetUnit, handler, true, insert)
end

function core.UnhookOnTooltipSetUnit(tooltip, handler)
    unhook(tooltip, "OnTooltipSetUnit", handler)
end

--[[----------------------------------------------------------------------
-- Database Functions
------------------------------------------------------------------------]]

function core:GetDB()
    return db
end

--[[----------------------------------------------------------------------
-- Module State
-------------------------------------------------------------------------]]

function core:ReInitialize()
    if not classColours then
        classColours = {}
        self.ClassColours = classColours
        for k,v in pairs(RAID_CLASS_COLORS) do
            classColours[k] = strformat("%2x%2x%2x", v.r*255, v.g*255, v.b*255)
        end
    end
end

function core:Standby()
    classColours = nil
end

--[[
function core:Wakeup()
end
--]]

-- For initializing the database and hooking functions.
function core:Initialize()
    db = TinyTipDB or TinyTip_StandAloneDB or {}

    -- Load all modules for "Always".
    for i=1,GetNumAddOns() do
        if not IsAddOnLoaded(i) and GetAddOnMetadata(i, "X-TinyTip-Load-Always") then
            local _, reason = LoadAddOn(i)
            local _, title = GetAddOnInfo(i)
            if reason then
                self:Print( title .. " LoadOnDemand Error - " .. reason )
            else
                self:Print( "Loaded " .. title)
            end
        end
    end
end

-- Setting variables that only need to be set once goes here.
function core:Enable()
    -- Load all modules for "Always".
    for i=1,GetNumAddOns() do
        if not IsAddOnLoaded(i) and GetAddOnMetadata(i, "X-TinyTip-Load-Always") then
            local _, reason = LoadAddOn(i)
            local _, title = GetAddOnInfo(i)
            if reason then
                self:Print( title .. " LoadOnDemand Error - " .. reason )
            else
                self:Print( "Loaded " .. title)
            end
        end
    end

    self:ReInitialize()
end
