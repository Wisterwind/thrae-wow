--[[
-- You need edit this file for configuration ONLY if
-- TinyTipOptions is NOT loaded. Otherwise, the options
-- in this file do nothing.
--]]

if not TinyTipDB or not TinyTipDB.configured then
    local t = {
                --[[
                -- To select the TinyTip default, set the value to nil.
                --]]
                --                              -- default, option1, option2, etc.
                ["TargetsTooltipUnit"] = nil,   -- nil, "DISABLED", "APPEND"
                                                -- The default (nil) is to add it as a new line. "APPEND" will
                                                -- add it to the name of the unit as Name : Target.
                ["TargetsParty"] = nil,         -- nil, "DISABLED", "SHOWALL"
                                                -- The default (nil) is the
                                                -- number of people in your party targeting the unit.
                                                -- "SHOWALL" will show all their names.
                ["TargetsRaid"] = nil,          -- nil, "DISABLED"
                                                -- The default (nil) is enabled.
    }

    TinyTip_StandAloneDB =  (TinyTip_StandAloneDB and setmetatable(t, {__index=TinyTip_StandAloneDB})) or t
    t = nil
end

