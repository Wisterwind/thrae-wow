--[[-------------------------------------------------------
-- PerfectTargetsLocale
--
-- Default (enUS)
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


-- Straight translations: Anything other then default should have 
-- the actual translation of the hash key (IE, ["hash key"]) as the
-- value assigned. The hash key must remain the same.
PerfectTargetsLocale = {
	----------------------------
	-- Slash Commands
	
	-- shortcut
	["slash2"] = "ptarg",

	-- options
	["locked"] = "lock",
	["locked_desc"] = "Toggle locking the frame",
	["baserate"] = "baserate",
	["baserate_desc"] = "Visual update rate when targets do not change",
	["maxframes"] = "maxframes",
	["maxframes_desc"] = "Maximum number of target frames shown",
	["emergencyname"] = "emergencyname",
	["emergencyname_desc"] = "Toggle showing the dying friend's name instead of !",
}

-- Instead of translating the values, these are translated hashes.
-- Give them the same values as the default translation.
PerfectTargetsLocale._hashed = {
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
}
