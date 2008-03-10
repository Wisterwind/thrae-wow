--[[
-- Name: TinyTip
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date: 6-25-06
--
-- These functions allow you to change options via a
-- Dewdrop GUI. Loaded on demand by TinyTip.
--
-- This part does NOT need to be localized, look in
-- TinyTipChatLocale_xxXX.lua.
--]]

local _G = getfenv(0)
local dewdrop
local core = TinyTip
local L = _G.TinyTipOptionsLocale
local title = select(2, GetAddOnInfo("TinyTipOptions"))
local ddframe, db

TinyTipOptions = {}
local module = TinyTipOptions

local function ToggleDB(k)
    db[k] = nil or not db[k]
end

local function SetDB(k,v)
    db[k] = v
end

local function SetDBNum(k,v)
    db[k] = tonumber(v)
end

local function DDAddArrow(opt)
    dewdrop:AddLine( 'text', L["Opt_" .. opt],
        'hasArrow', true,
        'value', opt,
        'tooltipTitle', "TinyTip",
        'tooltipText', L["Desc_" .. opt]
    )
end

local function DDAddChecked(opt, func)
    dewdrop:AddLine( 'text', L["Opt_" .. opt],
        'checked', db[ opt ],
        'func', func or ToggleDB,
        'arg1', opt,
        'tooltipTitle', "TinyTip",
        'tooltipText', L["Desc_" .. opt]
    )
end

local function DDAddEditBoxNum(opt, func, arg2)
    dewdrop:AddLine( 'text', L["Opt_" .. opt],
        'hasArrow', true,
        'hasEditBox', true,
        'editBoxText', db[ opt ],
        'editBoxFunc', func or SetDBNum,
        'editBoxArg1', opt,
        'editBoxArg2', arg2,
        'tooltipTitle', "TinyTip",
        'tooltipText', L["Desc_" .. opt]
    )
end

local function DDAddRadioBoxes(opt, map, func, default)
    local k,v
    dewdrop:AddLine('text', default or L.GameDefault,
        'isRadio', true,
        'checked', not db[opt],
        'func', func or SetDB,
        'arg1', opt
    )
    for k,v in pairs(map) do
        dewdrop:AddLine('text', L[v] or v,
            'isRadio', true,
            'checked', db[opt] == k,
            'func', func or SetDB,
            'arg1', opt,
            'arg2', k
        )
    end
end

local function DDAddScale(opt, func, default)
    dewdrop:AddLine( 'text', L["Opt_" .. opt],
        'hasArrow', true,
        'hasSlider', true,
        'sliderMin', 0.01,
        'sliderMax', 2.0,
        'sliderIsPercent', true,
        'sliderValue', db[opt] or default or 1.0,
        'sliderFunc', func or SetDBNum,
        'sliderArg1', opt,
        'tooltipTitle', "TinyTip",
        'tooltipText', L["Desc_" .. opt]
    )
end

function module.CreateDDMenu(level,value)
    db = core:GetDB()
    if not db then return end

    if level == 1 then
        dewdrop:AddLine( 'text', title,
            'isTitle', true
        )

        DDAddArrow("Main_Anchor")
        DDAddArrow("Main_Text")
        DDAddArrow("Main_Appearance")
        DDAddArrow("Main_Targets")
        dewdrop:AddLine()
        dewdrop:AddLine('text', L.Opt_Profiles,
        'checked', core:GetCurrentProfile() ~= "global",
        'func', core.ToggleSetProfile,
        'arg1', core,
        'tooltipTitle', "TinyTip",
        'tooltipText', L.Desc_Profiles
        )

        dewdrop:AddLine()

        dewdrop:AddLine('text', L.Opt_Main_Default,
            'textR', 1, 'textG', 0.4, 'textB', 0.4,
            'func', core.ResetDatabase,
            'arg1', core,
            'tooltipTitle', "TinyTip",
            'tooltipText', L.Desc_Main_Default
        )

    elseif level == 2 then
        if value == "Main_Anchor" then

            DDAddArrow("MAnchor")
            DDAddEditBoxNum("MOffX")
            DDAddEditBoxNum("MOffY")

            dewdrop:AddLine()

            DDAddArrow("FAnchor")
            DDAddEditBoxNum("FOffX")
            DDAddEditBoxNum("FOffY")

        elseif value == "Main_Text" then

            DDAddArrow("PvPRankText")

            dewdrop:AddLine()

            DDAddChecked("HideRace")
            DDAddChecked("HideNPCType")
            DDAddChecked("KeyElite")
            DDAddChecked("ReactionText")
            DDAddChecked("LevelGuess")
            DDAddChecked("KeyServer")

        elseif value == "Main_Appearance" then

            DDAddScale("Scale")
            DDAddArrow("BGColor")
            DDAddArrow("Border")
            DDAddArrow("ColourFriends")

            dewdrop:AddLine()

            DDAddChecked("HideInFrames")
            DDAddChecked("HideInCombat")

        elseif value == "Main_Targets" then

            DDAddArrow("TargetsTooltipUnit")
            DDAddArrow("TargetsParty")
            DDAddArrow("TargetsRaid")
        end
    elseif level == 3 then
        local k,v
        if value == "MAnchor" then
            dewdrop:AddLine('text', L.GameDefault,
                'isRadio', true,
                'checked', db["MAnchor"] == "GAMEDEFAULT",
                'func', SetDB,
                'arg1', "MAnchor",
                'arg2', "GAMEDEFAULT"
            )

            dewdrop:AddLine('text', L.CURSOR,
                'isRadio', true,
                'checked', not db["MAnchor"],
                'func', SetDB,
                'arg1', "MAnchor"
            )

            for k,v in pairs(L.Map_Anchor) do
                dewdrop:AddLine('text', L[v] or v,
                    'isRadio', true,
                    'checked', db["MAnchor"] == k,
                    'func', SetDB,
                    'arg1', "MAnchor",
                    'arg2', k
                )
            end
        elseif value == "FAnchor" then
            dewdrop:AddLine('text', L.GameDefault,
                'isRadio', true,
                'checked', not db["FAnchor"],
                'func', SetDB,
                'arg1', "FAnchor"
            )

            dewdrop:AddLine('text', L.SMART,
                'isRadio', true,
                'checked', db["FAnchor"] == "SMART",
                'func', SetDB,
                'arg1', "FAnchor",
                'arg2', "SMART"
            )

            dewdrop:AddLine('text', L.CURSOR,
                'isRadio', true,
                'checked', db["FAnchor"] == "CURSOR",
                'func', SetDB,
                'arg1', "FAnchor",
                'arg2', "CURSOR"
            )

            for k,v in pairs(L.Map_Anchor) do
                dewdrop:AddLine('text', L[v] or v,
                    'isRadio', true,
                    'checked', db["FAnchor"] == k,
                    'func', SetDB,
                    'arg1', "FAnchor",
                    'arg2', k
                )
            end
        elseif value == "PvPRankText" then
            DDAddRadioBoxes(value,
                L.Map_PvPRankText,
                nil,
                L.TinyTipDefault
            )
        elseif value == "BGColor" then
            DDAddRadioBoxes(value,
                L.Map_BGColor,
                nil,
                L.TinyTipDefault
            )
        elseif value == "Border" then
            DDAddRadioBoxes(value,
                L.Map_Border,
                nil,
                L.TinyTipDefault
            )
        elseif value == "ColourFriends" then
            DDAddRadioBoxes(value,
                L.Map_ColourFriends,
                nil,
                L.TinyTipDefault
            )
        elseif value == "TargetsTooltipUnit" then
            DDAddRadioBoxes(value,
                L.Map_TargetsTooltipUnit,
                nil,
                L.TinyTipDefault
            )
        elseif value == "TargetsParty" then
            DDAddRadioBoxes(value,
                L.Map_TargetsParty,
                nil,
                L.TinyTipDefault
            )
        elseif value == "TargetsRaid" then
            DDAddRadioBoxes(value,
                L.Map_TargetsRaid,
                nil,
                L.TinyTipDefault
            )
        end
    end
end

function module:Show()
    if not dewdrop then
        dewdrop = _G.AceLibrary:GetInstance("Dewdrop-2.0")
    end

    -- open up options window
    if not ddframe then
        ddframe = CreateFrame("Frame", nil, UIParent)
        ddframe:SetWidth(2)
        ddframe:SetHeight(2)
        ddframe:SetPoint("BOTTOMLEFT", GetCursorPosition())
        ddframe:SetClampedToScreen(true)
        dewdrop:Register(ddframe, 'dontHook', true, 'children', self.CreateDDMenu )
    end
    local x,y = GetCursorPosition()
    ddframe:SetPoint("BOTTOMLEFT", x / UIParent:GetScale(), y / UIParent:GetScale())
    dewdrop:Open(ddframe)
end

