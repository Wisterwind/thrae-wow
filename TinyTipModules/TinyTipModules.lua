--[[
-- Name: TinyTipModules
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date:
-- Release Version: 2.0
--
-- This provides the modular core of TinyTip. If this
-- addon is enabled, it will make TinyTip a module.
--]]

local _G = getfenv(0)

--[[---------------------------------------------
-- Local References
----------------------------------------------]]
local UIParent, GameTooltip = _G.UIParent, _G.GameTooltip

local L = _G.TinyTipLocale
local classColours, hooks, origfuncs

--[[----------------------------------------------------------------------
-- Module Initialization
------------------------------------------------------------------------]]

local _, core = GetAddOnInfo("TinyTipModules")
core = DongleStub("Dongle-1.0"):New(core)
TinyTipModules = core

--[[----------------------------------------------------------------------
-- Local Functions
------------------------------------------------------------------------]]

local function handlerOnTooltipSetUnit(tooltip,origfunc,handlers,...)
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

    tooltip:Show()
end

local function handler(object,origfunc,handlers,...)
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
        table.insert(hooks[object][func], handler, (insert and 1) or nil)
    end

    if isscript then
        if origfuncs[object][func] == nil then
            if isscript then
                origfuncs[object][func] = object:GetScript(func) or false
                object:SetScript(func, function(...) mainhandler(object, origfuncs[object], hooks[object][func], ...) end)
            else
                origfuncs[object][func] = object[func] or false
                object[func] = function(...) mainhandler(object, origfuncs[object], hooks[object][func], ...) end
            end
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
    return ( c and classColours[c] ) or "FFFFFF"
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
    db = TinyTipModulesDB or TinyTip_StandAloneDB
end

-- Setting variables that only need to be set once goes here.
function core:Enable()
       self:ReInitialize()
end

-- Load all modules for "Always".
for i=1,GetNumAddons() do
    if GetAddOnMetadata(i, "X-TinyTipModule-Always") then
        local _, reason = LoadAddOn(i)
        if reason then
            local _, title = GetAddOnInfo(i)
            core:Print( title .. " LoadOnDemand Error - " .. reason )
        end
    end
end
