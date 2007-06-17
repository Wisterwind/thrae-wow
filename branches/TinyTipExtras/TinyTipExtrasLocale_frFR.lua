--[[ TinyTip by Thrae
-- 
-- French Localization
-- Any wrong words, change them here.
-- 
-- TinyTipLocale should be defined in your FIRST included
-- localization file.
--
-- Note: Localized slash commands are in TinyTipChatLocale_frFR.
--
-- Contributors: Adirelle
--]]

if TinyTipExtrasLocale and TinyTipExtrasLocale == "frFR" then
	-- TinyTipTargets
	TinyTipTargetsLocale_Targeting		= "Cible"
	TinyTipTargetsLocale_YOU					= "<<VOUS>>"
	TinyTipTargetsLocale_TargetedBy		= "Cibl\195\169 par" -- babelfish

	TinyTipTargetsLocale_Unknown	= "Inconnu"

	-- TinyTipExtras core
	TinyTipExtrasLocale_Buffs = "Buffs"
	TinyTipExtrasLocale_DispellableDebuffs = "Dispellable"
	TinyTipExtrasLocale_DebuffMap = {
		["Magic"] = "|cFF5555FFMagie|r",
		["Poison"] = "|cFFFF5555Poison|r",
		["Curse"] = "|cFFFF22FFMal\194\169diction|r",
		["Disease"] = "|cFF555555Maladie|r" }

	TinyTipExtrasLocale = nil -- we no longer need this
end
