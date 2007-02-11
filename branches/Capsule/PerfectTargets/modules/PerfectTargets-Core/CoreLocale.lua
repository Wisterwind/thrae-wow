--[[-------------------------------------------------------
-- PerfectTargetsLocale
---------------------------------------------------------]]
-- Any wrong translations, change them here.
-- This file must be saved as UTF-8 compatible.
--
-- To get your client's locale, type in:
--
-- /script DEFAULT_CHAT_FRAME:AddMessage( GetLocale() )
--
-- Do not repost without permission from the author. If you 
-- want to add a translation, contact the author.
--

local locale = GetLocale()

if locale == "zhTW" then -- Traditional Chinese
	PerfectTargetsLocale = {
		-- Reverse Translations: These are put in the hash themselves.
		-- Give them the same values as the default (enUS) translation.

		-- CC Debuffs
		["翼龍釘刺"] = true, -- Wyvern's Sting
		["恐嚇野獸"] = true, -- Scare Beast
		["變形術"] = true, -- Polymorph
		["變豬術"] = true, -- Polymorph: Pig
		["變龜術"] = true, -- Polymorph: Turtle
		["悶棍"] = true, -- Sap
		["誘惑"] = true, -- Seduction
		["休眠"] = true, -- Hibernate
		["束縛不死生物"] = true, -- Shackle Undead
		["冰凍陷阱效果"] = true, -- Freezing Trap Effect
		["放逐術"] = true, -- Banish

		-- Skill Debuffs
		["獵人印記"] = 2, -- Hunter's Mark

		-- Straight translations: Anything other then default should have 
		-- the actual translation of the hash key (IE, ["hash key"]) as the
		-- value assigned. The hash key must remain the same.

		-- Menus
		["Lock frame"] = "鎖定視窗",
		["Lock target frame's position."] = "鎖定目標視窗在目前位置.",

		["Tank Initials"] = "初始坦克",
		["Number of tank initials to append to the frames."] = "增加到這個視窗的坦克字首數量.",

		["Base frame update rate."] = "主視窗更新速率.",

		["Number of targets"] = "目標數目",
		["Maximum number of target frames shown."] = "顯示在目標視窗上的最大數目.",
	}
--[[
elseif 	locale == "zhCN" then -- Chinese
	PerfectTargetsLocale = {
		localization goes here
	}
--]]
--[[
elseif 	locale == "koKR" then -- Korean
	PerfectTargetsLocale = {
		localization goes here
	}
--]]
--[[
elseif 	locale == "deDE" then -- German
	PerfectTargetsLocale = {
		localization goes here
	}
--]]
--[[
elseif	locale == "frFR" then -- French
	PerfectTargetsLocale = {
		localization goes here
	}
--]]
--[[
elseif	locale == "esES" then -- Spanish
	PerfectTargetsLocale = {
		localization goes here
	}
--]]
--[[
elseif	locale == "enGB" then -- English (UK)
	PerfectTargetsLocale = {
		localization goes here
	}
--]]
else	-- default and enUS, copy this to get started with translation
	PerfectTargetsLocale = {
		-- Reverse Translations: These are put in the hash themselves.
		-- Give them the same values as the default (enUS) translation.

		-- CC Debuffs
		["Wyvern Sting"] = true, -- Wyvern's Sting
		["Scare Beast"] = true, -- Scare Beast
		["Polymorph"] = true, -- Polymorph
		["Polymorph: Pig"] = true, -- Polymorph: Pig
		["Polymorph: Turtle"] = true, -- Polymorph: Turtle
		["Sap"] = true, -- Sap
		["Seduction"] = true, -- Seduction
		["Hibernate"] = true, -- Hibernate
		["Shackle Undead"] = true, -- Shackle Undead
		["Freezing Trap Effect"] = true, -- Freezing Trap Effect
		["Banish"] = true, -- Banish

		-- Skill Debuffs
		["Hunter's Mark"] = 2, -- Hunter's Mark

		-- Straight translations: Anything other then default should have 
		-- the actual translation of the hash key (IE, ["hash key"]) as the
		-- value assigned. The hash key must remain the same.

		-- Menus
		["Lock frame"] = true,
		["Lock target frame's position."] = true,

		["Tank Initials"] = true,
		["Number of tank initials to append to the frames."] = true,

		["Update Rate"] = true,
		["Base frame update rate."] = true,

		["Number of targets"] = true,
		["Maximum number of target frames shown."] = true,
	}
end

