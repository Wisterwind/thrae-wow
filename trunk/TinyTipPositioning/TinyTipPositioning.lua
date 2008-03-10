--[[
-- Name: TinyTipPositioning
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date:
-- Release Version: 2.0
--
-- Thanks to #wowace, #dongle, and #wowi-lounge on Freenode as always for
-- optimization assistance. Thanks to AF_Tooltip_Mini for the idea that
-- became TinyTip.
--
-- Note: If running TinyTip without TinyTipOptions, see
-- StandAloneConfig.lua for manual configuration options.
--]]

local _G = getfenv(0)

--[[---------------------------------------------
-- Local References
----------------------------------------------]]
local UIParent, GameTooltip = _G.UIParent, _G.GameTooltip

local L = _G.TinyTipLocale

--[[----------------------------------------------------------------------
-- Module Support
------------------------------------------------------------------------]]

local modulecore, name = TinyTip, "TinyTipPositioning"

local module, UpdateFrame, db
if not modulecore then
    module = {}
    module.name, module.localizedname = name, name
else
    local localizedname, reason
    _, localizedname, _, _, _, reason = GetAddOnInfo(name)
    if (not reason or reason ~= "MISSING") and not IsAddOnLoaded(name) then return end -- skip internal loading if module is external
    module = modulecore:NewModule(name)
    module.name, module.localizedname = name, localizedname or name
    db = modulecore:GetDB()
end

--[[-------------------------------------------------------
-- Event Handling
---------------------------------------------------------]]

local OnUpdateSet
local function OnHide(self,...)
        if OnUpdateSet then self:SetScript("OnUpdate", nil) OnUpdateSet = nil end
end

--[[-------------------------------------------------------
-- Anchoring and Positioning
---------------------------------------------------------]]

-- Used to stick GameTooltip to the cursor with offsets.
local getcpos = _G.GetCursorPosition
local function OnUpdate(self, time)
            local x,y = getcpos()
            local uiscale,tscale = UIParent:GetScale(), GameTooltip:GetScale()
            GameTooltip:ClearAllPoints()
            GameTooltip:SetPoint(self.Anchor or "BOTTOM", UIParent, "BOTTOMLEFT",
                                (x + (self.OffX or 0)) / uiscale / tscale,
                                (y + (self.OffY or 0)) / uiscale / tscale)
end

-- Thanks to cladhaire for most of this one.
-- Used for FAnchor = "SMART"
local function SmartSetOwner(owner, setX, setY, tooltip)
    if not owner then owner = UIParent end
    if not tooltip then tooltip = this end
    if not setX then setX = 0 end
    if not setY then setY = 0 end

    local x,y = owner:GetCenter()
    local left, right = owner:GetLeft(), owner:GetRight()
    local top, bottom = owner:GetTop(), owner:GetBottom()
    local scrWidth, scrHeight = GetScreenWidth(), GetScreenHeight()
    local scale = owner:GetScale()

    -- sanity check
    if x == nil or y == nil or left == nil or right == nil or
       top == nil or bottom == nil or scale == nil or
       scrWidth == nil or scrHeight == nil or
       scrWidth < 0 or scrHeight < 0 then
            return
    end

    setX = setX * scale
    setY = setY * scale
    x = x * scale
    y = y * scale
    left = left * scale
    right = right * scale
    top = top * scale
    bottom = bottom * scale
    local width, anchorPoint = right - left

    if y <= (scrHeight / 2) then
        top = top + setY
        anchorPoint = "TOP"
        if top < 0 then
            setY = setY - top
        end
    else
        setY = -setY
        bottom = bottom + setY
        anchorPoint = "BOTTOM"
        if bottom > scrHeight then
            setY = setY + (scrHeight - bottom)
        end
    end

    if x <= (scrWidth / 2) then
        left = left + setX
        if anchorPoint == "BOTTOM" then
            anchorPoint = anchorPoint.."RIGHT"
            setX = setX - width
            if (left < 0) then
                setX = setX - left
            end
        else
            anchorPoint = anchorPoint.."LEFT"
            if left < 0 then
                setX = setX - left
            end
        end
    else
        setX = -setX
        right = right + setX
        if anchorPoint == "BOTTOM" then
            anchorPoint = anchorPoint.."LEFT"
            setX = setX + width
            if (right > scrWidth) then
                setX = setX - (right - scrWidth)
            end
        else
            anchorPoint = anchorPoint.."RIGHT"
            if (right > scrWidth) then
                setX = setX + (scrWidth - right)
            end
        end
    end

    scale = tooltip:GetScale()
    tooltip:ClearAllPoints()
    tooltip:SetOwner(owner, "ANCHOR_"..anchorPoint, setX / scale, setY / scale)
end

local OriginalGameTooltipSetDefaultAnchor = nil
local function SetDefaultAnchor(tooltip,owner,...)
    if OriginalGameTooltipSetDefaultAnchor then
        if module.onstandby then
            return OriginalGameTooltipSetDefaultAnchor(tooltip,owner,...)
        else
            OriginalGameTooltipSetDefaultAnchor(tooltip,owner,...)
        end
    elseif module.onstandby then
        return
    end

    if tooltip == GameTooltip then
        if OnUpdateSet then UpdateFrame:SetScript("OnUpdate", nil) end
        if owner ~= UIParent then
            if db["FAnchor"] or db["FOffX"] ~= nil or db["FOffY"] ~= nil then
                if db["FAnchor"] == "CURSOR" then
                    if (db["FOffX"] ~= nil and db["FOffX"] > 0) or (db["FOffY"] ~= nil and db["FOffY"] > 0) or
                    db["FCursorAnchor"] then
                        UpdateFrame.OffX,UpdateFrame.OffY,UpdateFrame.Anchor = db["FOffX"], db["FOffY"], db["FCursorAnchor"]
                        UpdateFrame:SetScript("OnUpdate", OnUpdate)
                        OnUpdateSet = true
                    else
                        tooltip:SetOwner(owner, "ANCHOR_CURSOR")
                    end
                elseif db["FAnchor"] == "SMART" then
                    SmartSetOwner(owner, db["FOffX"], db["FOffY"], tooltip)
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
                    UpdateFrame.OffX,UpdateFrame.OffY,UpdateFrame.Anchor = db["MOffX"], db["MOffY"], db["MCursorAnchor"]
                    UpdateFrame:SetScript("OnUpdate", OnUpdate)
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


function module:ReInitialize(_db)
    db = _db or db
end

function module:Standby()
end
--]]

-- For initializing the database and hooking functions.
function module:Initialize()
    db = ( modulecore and modulecore:GetDB() ) or TinyTip_StandAloneDB or {}

    if OriginalGameTooltipSetDefaultAnchor == nil then
        OriginalGameTooltipSetDefaultAnchor = _G.GameTooltip_SetDefaultAnchor or false
        _G.GameTooltip_SetDefaultAnchor = SetDefaultAnchor
    end
end

-- Setting variables that only need to be set once goes here.
function module:Enable()
    self:ReInitialize()
end

-- TinyTipModuleCore NOT loaded
local EventFrame
if not modulecore then
    local function OnEvent(self, event, arg1)
        if event == "ADDON_LOADED" and arg1 == module.name then
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
    EventFrame = CreateFrame("Frame", nil, GameTooltip)
    EventFrame:RegisterEvent("ADDON_LOADED")
    EventFrame:RegisterEvent("PLAYER_LOGIN")
    EventFrame:SetScript("OnEvent", OnEvent)
    UpdateFrame = EventFrame

else
    UpdateFrame = CreateFrame("Frame", nil, GameTooltip)
end

-- Update frame used for GameTooltip-related update and handler scripts
UpdateFrame:SetScript("OnHide", OnHide)
UpdateFrame:Show()

