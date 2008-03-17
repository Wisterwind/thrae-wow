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
                ["FAnchor"] = nil,           -- "BOTTOMRIGHT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT", "CURSOR", "SMART"
                                             -- Used only in Frames. TinyTip default (when nil) is BOTTOMRIGHT.
                                             -- "SMART" anchor will attempt to position the tooltip as to not obscure frames.
                ["FCursorAnchor"] = nil,     -- Which side of the cursor to anchor for frame units.
                                             -- TinyTip's default (when nil) is "BOTTOM".
                ["MAnchor"] = nil,           -- Used only for Mouseover units. Options same as above, with the
                                             -- addition of "GAMEDEFAULT". TinyTip Default is CURSOR.
                ["MCursorAnchor"] = nil,     -- Which side of the cursor to anchor for mouseover (world).
                ["FOffX"] = nil,             -- X offset for Frame units (horizontal). By default (nil), this is not used.
                ["FOffY"] = nil,             -- Y offset for Frame units (vertical). By default (nil), this is not used.
                ["MOffX"] = nil,             -- Offset for Mouseover units (World Frame). By default (nil), this is not used.
                ["MOffY"] = nil,             -- "     "       "       "       "
                ["CFAnchor"] = nil,          -- "GAMEDEFAULT", "BOTTOMRIGHT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT", "CURSOR", "SMART"
                                             -- Anchor for frames when in combat. Overrides other settings.
                                             -- By default (nil), this is not used.
                ["CFOffX"] = nil,            -- Offset for frame units when in combat. Overrides other settings.
                                             -- By default (nil), this is not used.
                ["CFOffY"] = nil,            -- "     "       "       "       "
                ["MFAnchor"] = nil,          -- "GAMEDEFAULT", "BOTTOMRIGHT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT", "CURSOR"
                                             -- Anchor for mouseover units when in combat. Overrides other settings.
                                             -- By default (nil), this is not used.
                ["CMOffX"] = nil,            -- Offset for Mouseover units when in combat. Overrides other settings.
                                             -- By default (nil), this is not used.
                ["CMOffY"] = nil,            -- "     "       "       "       "
                ["EtcAnchor"] = nil,         -- "GAMEDEFAULT", "BOTTOMRIGHT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT", "CURSOR", "SMART"
                                             -- Used for all tooltips -except- GameTooltip. By default (nil), this is not used.
                                             -- Beware this feature, it can get messy.
                ["EtcOffX"] = nil,           -- Offset X for non-GameTooltip tooltips. Beware. Beeewaaarrre.
                ["EtcOffY"] = nil,           -- "           "           "           "           "
    }

    TinyTip_StandAloneDB =  (TinyTip_StandAloneDB and setmetatable(t, {__index=TinyTip_StandAloneDB})) or t
end

