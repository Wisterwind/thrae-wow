--[[
-- Name: SpamIt!
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date: 1-15-07
--
-- Supress UIErrorFrame spam.
--]]

local UIErrorsFrame_AddMessage_Orig, noSpam
local function SpamCatcher(this, text, ...)
	if not noSpam or text == ERR_ABILITY_COOLDOWN or 
	text == ERR_OUT_OF_ENERGY or text == ERR_OUT_OF_RAGE or 
	text == ERR_SPELL_COOLDOWN or text == SPELL_FAILED_ITEM_NOT_READY or 
	text == SPELL_FAILED_TARGET_AURASTATE then return end
	
	UIErrorsFrame_AddMessage_Orig(this, text, ...)
end

-- remove the function declaration if you want it to work all the time.
function SpamIt_Start()
	if not UIErrorsFrame_AddMessage_Orig then
		UIErrorsFrame_AddMessage_Orig = UIErrorsFrame.AddMessage
		UIErrorsFrame.AddMessage = SpamCatcher
	end
	noSpam = true
end

function SpamIt_Stop()
	noSpam = nil
end
