--[[ TinyTip by Thrae
-- 
-- Traditional Chinese Localization
-- Any wrong words, change them here.
-- 
-- TinyTipLocale should be defined in your FIRST localization
-- code.
--
-- Contributors: 舞葉@語風
--]]
TinyTipExtrasLocale = GetLocale()

if TinyTipExtrasLocale and TinyTipExtrasLocale == "zhTW" then
	-- TinyTipTargets
	TinyTipTargetsLocale_Targeting		= "目標"
	TinyTipTargetsLocale_YOU			= "** 你 **"
	TinyTipTargetsLocale_TargetedBy	= "被關注"

	TinyTipTargetsLocale_Unknown	= "未知"

	-- TinyTipExtras core
	TinyTipExtrasLocale_Buffs = "增益"
	TinyTipExtrasLocale_DispellableDebuffs = "可驅散"
	TinyTipExtrasLocale_DebuffMap = {
		["Magic"] = "|cFF5555FF魔法|r",
		["Poison"] = "|cFFFF5555中毒|r",
		["Curse"] = "|cFFFF22FF詛咒|r",
		["Disease"] = "|cFF555555疾病|r" }

	TinyTipExtrasLocale = nil -- we no longer need this
end
