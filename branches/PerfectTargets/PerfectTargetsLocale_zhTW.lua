--[[-------------------------------------------------------
-- PerfectTargetsLocale
--
-- Traditional Chinese
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

if GetLocale() ~= "zhTW" then return end

-- Instead of translating the values, these are translated hashes.
-- Give them the same values as the default translation.
PerfectTargetsLocale._hashed = setmetatable({

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
}, {__index=PerfectTargetsLocale._hashed}) 
