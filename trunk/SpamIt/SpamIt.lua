--[[
-- Name: SpamIt!
-- Author: Thrae of Maelstrom (aka "Matthew Carras")
-- Release Date: 1-15-07
--
-- Supress UIErrorFrame spam.
--]]

local UIErrorsFrame_AddMessage_Orig, noSpam
local function SpamCatcher(this, text, r, g, b, a, holdTime, arg8, arg9)
	if noSpam and 
		 text ~= ERR_ABILITY_COOLDOWN and text ~= ERR_OUT_OF_ENERGY and
		 text ~= ERR_OUT_OF_RAGE then
		 	UIErrorsFrame_AddMessage_Orig(this, text, r, g, b, a, holdTime, arg8, arg9)
	end
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
