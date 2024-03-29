--[[-------------------------------------------------------
-- TinyTip Localization : Traditional Chinese
-----------------------------------------------------------
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
-- Contributors: 舞葉@語風
--]]

if GetLocale() ~= "zhTW" then return end

TinyTipLocale = setmetatable({
        ["Targeting"] = "目標",
        ["<<YOU>>"] = "** 你 **",
        ["Targeted by"] = "被關注",
        ["Unknown"] = "未知",
        [" (F)"] = " (*)",
        [" (MT)"] = " (!)",
        [" (MA)"] = " <<",
}, {__index=TinyTipLocale})
