--[[-------------------------------------------------------------------------
  Copyright (c) 2006, Dongle Development Team
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of the Dongle Development Team nor the names of
        its contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------]]

local major = "Dongle-Beta0"
local minor = tonumber(string.match("$Revision: 249 $", "(%d+)") or 1)

assert(DongleStub, string.format("Dongle requires DongleStub.", major))
assert(DongleStub and DongleStub:GetVersion() == "DongleStub-Beta0",
	string.format("Dongle requires DongleStub-Beta0.  You are using an older version.", major))

if not DongleStub:IsNewerVersion(major, minor) then return end

local Dongle = {}
local methods = {
	"RegisterEvent", "UnregisterEvent", "UnregisterAllEvents",
	"RegisterMessage", "UnregisterMessage", "UnregisterAllMessages", "TriggerMessage",
	"EnableDebug", "IsDebugEnabled", "Print", "PrintF", "Debug", "DebugF",
	"InitializeDB",
	"InitializeSlashCommand",
	"NewModule", "HasModule", "IterateModules",
}

local registry = {}
local lookup = {}
local loadqueue = {}
local loadorder = {}
local events = {}
local databases = {}
local commands = {}
local messages = {}

local frame

--[[-------------------------------------------------------------------------
  Utility functions for Dongle use
---------------------------------------------------------------------------]]

local function assert(level,condition,message)
	if not condition then
		error(message,level)
	end
end

local function argcheck(value, num, ...)
	assert(1, type(num) == "number",
		"Bad argument #2 to 'argcheck' (number expected, got " .. type(level) .. ")")

	for i=1,select("#", ...) do
		if type(value) == select(i, ...) then return end
	end

	local types = strjoin(", ", ...)
	local name = string.match(debugstack(), "`argcheck'.-[`<](.-)['>]") or "Unknown"
	error(string.format("bad argument #%d to '%s' (%s expected, got %s)",
		num, name, types, type(value)), 3)
end

local function safecall(func,...)
	local success,err = pcall(func,...)
	if not success then
		geterrorhandler()(err)
	end
end

--[[-------------------------------------------------------------------------
  Dongle constructor, and DongleModule system
---------------------------------------------------------------------------]]

function Dongle:New(name, obj)
	argcheck(name, 2, "string")
	argcheck(obj, 3, "table", "nil")

	if not obj then
		obj = {}
	end

	if registry[name] then
		error("A Dongle with the name '"..name.."' is already registered.")
	end

	local reg = {["obj"] = obj, ["name"] = name}

	registry[name] = reg
	lookup[obj] = reg
	lookup[name] = reg

	for k,v in pairs(methods) do
		obj[v] = self[v]
	end

	-- Add this Dongle to the end of the queue
	table.insert(loadqueue, obj)
	return obj,name
end

function Dongle:NewModule(name, obj)
	local reg = lookup[self]
	assert(3, reg, "You must call 'NewModule' from a registered Dongle.")
	argcheck(name, 2, "string")
	argcheck(obj, 3, "table", "nil")

	obj,name = Dongle:New(name, obj)

	if not reg.modules then reg.modules = {} end
	reg.modules[obj] = obj
	reg.modules[name] = obj

	return obj,name
end

function Dongle:HasModule(module)
	local reg = lookup[self]
	assert(3, reg, "You must call 'HasModule' from a registered Dongle.")
	argcheck(module, 2, "string", "table")

	return reg.modules[module]
end

local function ModuleIterator(t, name)
	if not t then return end
	local obj
	repeat
		name,obj = next(t, name)
	until type(name) == "string" or not name

	return name,obj
end

function Dongle:IterateModules()
	local reg = lookup[self]
	assert(3, reg, "You must call 'IterateModules' from a registered Dongle.")

	return ModuleIterator, reg.modules
end

--[[-------------------------------------------------------------------------
  Event registration system
---------------------------------------------------------------------------]]

local function OnEvent(frame, event, ...)
	local eventTbl = events[event]
	if eventTbl then
		for obj,func in pairs(eventTbl) do
			if type(func) == "string" then
				if type(obj[func]) == "function" then
					safecall(obj[func], obj, event, ...)
				end
			else
				safecall(func, event, ...)
			end
		end
	end
end

function Dongle:RegisterEvent(event, func)
	local reg = lookup[self]
	assert(3, reg, "You must call 'RegisterEvent' from a registered Dongle.")
	argcheck(event, 2, "string")
	argcheck(func, 3, "string", "function", "nil")

	-- Name the method the same as the event if necessary
	if not func then func = event end

	if not events[event] then
		events[event] = {}
		frame:RegisterEvent(event)
	end
	events[event][self] = func
end

function Dongle:UnregisterEvent(event)
	local reg = lookup[self]
	assert(3, reg, "You must call 'UnregisterEvent' from a registered Dongle.")
	argcheck(event, 2, "string")

	local tbl = events[event]
	if tbl then
		tbl[self] = nil
		if not next(tbl) then
			events[event] = nil
			frame:UnregisterEvent(event)
		end
	end
end

function Dongle:UnregisterAllEvents()
	assert(3, lookup[self], "You must call 'UnregisterAllEvents' from a registered Dongle.")

	for event,tbl in pairs(events) do
		tbl[self] = nil
		if not next(tbl) then
			events[event] = nil
			frame:UnregisterEvent(event)
		end
	end
end

--[[-------------------------------------------------------------------------
  Inter-Addon Messaging System
---------------------------------------------------------------------------]]

function Dongle:RegisterMessage(msg, func)
	local reg = lookup[self]
	assert(3, reg, "You must call 'RegisterMessage' from a registered Dongle.")
	argcheck(msg, 2, "string")
	argcheck(func, 3, "string", "function", "nil")

	-- Name the method the same as the message if necessary
	if not func then func = msg end

	if not messages[msg] then
		messages[msg] = {}
	end
	messages[msg][self] = func
end

function Dongle:UnregisterMessage(msg)
	local reg = lookup[self]
	assert(3, reg, "You must call 'UnregisterMessage' from a registered Dongle.")
	argcheck(msg, 2, "string")

	local tbl = messages[msg]
	if tbl then
		tbl[self] = nil
		if not next(tbl) then
			messages[msg] = nil
		end
	end
end

function Dongle:UnregisterAllMessages()
	assert(3, lookup[self], "You must call 'UnregisterAllMessages' from a registered Dongle.")

	for msg,tbl in pairs(messages) do
		tbl[self] = nil
		if not next(tbl) then
			messages[msg] = nil
		end
	end
end

function Dongle:TriggerMessage(msg, ...)
	argcheck(msg, 2, "string")
	local msgTbl = messages[msg]
	if not msgTbl then return end

	for obj,func in pairs(msgTbl) do
		if type(func) == "string" then
			if type(obj[func]) == "function" then
				safecall(obj[func], obj, msg, ...)
			end
		else
			safecall(func, msg, ...)
		end
	end
end

--[[-------------------------------------------------------------------------
  Debug and Print utility functions
---------------------------------------------------------------------------]]

function Dongle:EnableDebug(level, frame)
	local reg = lookup[self]
	assert(3, reg, "You must call 'EnableDebug' from a registered Dongle.")
	argcheck(level, 2, "number", "nil")
	argcheck(frame, 3, "table", "nil")

	assert(3, type(frame) == "nil" or type(frame.AddMessage) == "function", "The frame you specify must have an \"AddMessage\" method")
	reg.debugFrame = frame or ChatFrame1
	reg.debugLevel = level
end

function Dongle:IsDebugEnabled()
	local reg = lookup[self]
	assert(3, reg, "You must call 'EnableDebug' from a registered Dongle.")

	return reg.debugLevel, reg.debugFrame
end

local function argsToStrings(a1, ...)
	if select("#", ...) > 0 then
		return tostring(a1), argsToStrings(...)
	else
		return tostring(a1)
	end
end

local function printHelp(obj, method, frame, msg, ...)
	local reg = lookup[obj]
	assert(4, reg, "You must call '"..method.."' from a registered Dongle.")

	local name = reg.name
	msg = "|cFF33FF99"..name.."|r: "..tostring(msg)
	if select("#", ...) > 0 then
		msg = string.join(", ", msg, argsToStrings(...))
	end

	frame:AddMessage(msg)
end

local function printFHelp(obj, method, frame, msg, ...)
	local reg = lookup[obj]
	assert(4, reg, "You must call '"..method.."' from a registered Dongle.")

	local name = reg.name
	local success,txt = pcall(string.format, "|cFF33FF99%s|r: "..msg, name, ...)
	if success then
		frame:AddMessage(txt)
	else
		error(string.gsub(txt, "'%?'", string.format("'%s'", method)), 3)
	end
end

function Dongle:Print(msg, ...)
	argcheck(msg, 2, "number", "string", "boolean", "table", "function", "thread", "userdata")
	return printHelp(self, "Print", DEFAULT_CHAT_FRAME, msg, ...)
end

function Dongle:PrintF(msg, ...)
	argcheck(msg, 2, "number", "string", "boolean", "table", "function", "thread", "userdata")
	return printFHelp(self, "PrintF", DEFAULT_CHAT_FRAME, msg, ...)
end

function Dongle:Debug(level, ...)
	local reg = lookup[self]
	assert(3, reg, "You must call 'Debug' from a registered Dongle.")
	argcheck(level, 2, "number")

	if reg.debugLevel and level <= reg.debugLevel then
		printHelp(self, "Debug", reg.debugFrame, ...)
	end
end

function Dongle:DebugF(level, ...)
	local reg = lookup[self]
	assert(3, reg, "You must call 'DebugF' from a registered Dongle.")
	argcheck(level, 2, "number")

	if reg.debugLevel and level <= reg.debugLevel then
		printFHelp(self, "DebugF", reg.debugFrame, ...)
	end
end

--[[-------------------------------------------------------------------------
  Database System
---------------------------------------------------------------------------]]

local dbMethods = {
	"RegisterDefaults", "SetProfile", "GetProfiles", "DeleteProfile", "CopyProfile",
	"ResetProfile", "ResetDB",
}

local function initdb(parent, name, defaults, defaultProfile, olddb)
	local sv = getglobal(name)

	if not sv then
		sv = {}
		setglobal(name, sv)

		-- Lets do the initial setup

		sv.char = {}
		sv.faction = {}
		sv.realm = {}
		sv.class = {}
		sv.global = {}
		sv.profiles = {}
		sv.factionrealm = {}
	end

	-- Initialize the specific databases
	local char = string.format("%s of %s", UnitName("player"), GetRealmName())
	local realm = GetRealmName()
	local class = UnitClass("player")
	local race = select(2, UnitRace("player"))
	local faction = UnitFactionGroup("player")
	local factionrealm = string.format("%s - %s", faction, realm)

	-- Initialize the containers
	if not sv.char then sv.char = {} end
	if not sv.realm then sv.realm = {} end
	if not sv.class then sv.class = {} end
	if not sv.faction then sv.faction = {} end
	if not sv.global then sv.global = {} end
	if not sv.profiles then sv.profiles = {} end
	if not sv.factionrealm then sv.factionrealm = {} end
	if not sv.profileKeys then sv.profileKeys = {} end

	-- Initialize this characters profiles
	if not sv.char[char] then sv.char[char] = {} end
	if not sv.realm[realm] then sv.realm[realm] = {} end
	if not sv.class[class] then sv.class[class] = {} end
	if not sv.faction[faction] then sv.faction[faction] = {} end
	if not sv.factionrealm[factionrealm] then sv.faction[factionrealm] = {} end

	-- Try to get the profile selected from the char db
	local profileKey = sv.profileKeys[char] or defaultProfile or char
	sv.profileKeys[char] = profileKey

	local profileCreated
    if not sv.profiles[profileKey] then sv.profiles[profileKey] = {} profileCreated = true end

	if olddb then
		for k,v in pairs(olddb) do olddb[k] = nil end
	end

	local db = olddb or {}
	db.char = sv.char[char]
	db.realm = sv.realm[realm]
	db.class = sv.class[class]
	db.faction = sv.faction[faction]
	db.factionrealm = sv.factionrealm[factionrealm]
	db.profile = sv.profiles[profileKey]
	db.global = sv.global
	db.profiles = sv.profiles

	-- Copy methods locally
	for idx,method in pairs(dbMethods) do
		db[method] = Dongle[method]
	end

	-- Set some properties in the object we're returning
	db.sv = sv
	db.sv_name = name
	db.profileKey = profileKey
	db.parent = parent
	db.charKey = char
	db.realmKey = realm
	db.classKey = class
	db.factionKey = faction
	db.factionrealmKey = factionrealm

	databases[db] = true

	if defaults then
		db:RegisterDefaults(defaults)
	end

	return db,profileCreated
end

function Dongle:InitializeDB(name, defaults, defaultProfile)
	local reg = lookup[self]
	assert(3, reg, "You must call 'InitializeDB' from a registered Dongle.")
	argcheck(name, 2, "string")
	argcheck(defaults, 3, "table", "nil")
	argcheck(defaultProfile, 4, "string", "nil")

	local db,profileCreated = initdb(self, name, defaults, defaultProfile)

	if profileCreated then
		Dongle:TriggerMessage("DONGLE_PROFILE_CREATED", db, self, db.sv_name, db.profileKey)
	end
	return db
end

local function copyDefaults(dest, src, force)
	for k,v in pairs(src) do
		if type(v) == "table" then
			if not dest[k] then dest[k] = {} end
			copyDefaults(dest[k], v, force)
		else
			if (dest[k] == nil) or force then
				dest[k] = v
			end
		end
	end
end

-- This function operates on a Dongle DB object
function Dongle.RegisterDefaults(db, defaults)
	assert(3, databases[db], "You must call 'RegisterDefaults' from a Dongle database object.")
	argcheck(defaults, 2, "table")

	if defaults.char then copyDefaults(db.char, defaults.char) end
	if defaults.realm then copyDefaults(db.realm, defaults.realm) end
	if defaults.class then copyDefaults(db.class, defaults.class) end
	if defaults.faction then copyDefaults(db.faction, defaults.faction) end
	if defaults.factionrealm then copyDefaults(db.factionrealm, defaults.factionrealm) end
	if defaults.global then copyDefaults(db.global, defaults.global) end
	if defaults.profile then copyDefaults(db.profile, defaults.profile) end

	db.defaults = defaults
end

local function removeDefaults(db, defaults)
	if not db then return end
	for k,v in pairs(defaults) do
		if type(v) == "table" and db[k] then
			removeDefaults(db[k], v)
			if not next(db[k]) then
				db[k] = nil
			end
		else
			if db[k] == defaults[k] then
				db[k] = nil
			end
		end
	end
end

function Dongle:ClearDBDefaults()
	for db in pairs(databases) do
		local defaults = db.defaults
		local sv = db.sv

		if db and defaults then
			if defaults.char then removeDefaults(db.char, defaults.char) end
			if defaults.realm then removeDefaults(db.realm, defaults.realm) end
			if defaults.class then removeDefaults(db.class, defaults.class) end
			if defaults.faction then removeDefaults(db.faction, defaults.faction) end
			if defaults.factionrealm then removeDefaults(db.faction, defaults.factionrealm) end
			if defaults.global then removeDefaults(db.global, defaults.global) end
			if defaults.profile then
				for k,v in pairs(sv.profiles) do
					removeDefaults(sv.profiles[k], defaults.profile)
				end
			end

			-- Remove any blank "profiles"
			if not next(db.char) then sv.char[db.charKey] = nil end
			if not next(db.realm) then sv.realm[db.realmKey] = nil end
			if not next(db.class) then sv.class[db.classKey] = nil end
			if not next(db.faction) then sv.faction[db.factionKey] = nil end
			if not next(db.factionrealm) then sv.faction[db.factionrealmKey] = nil end
			if not next(db.global) then sv.global = nil end
		end
	end
end

function Dongle.SetProfile(db, name)
	assert(3, databases[db], "You must call 'SetProfile' from a Dongle database object.")
	argcheck(name, 2, "string")

	local sv = db.sv
	local old = sv.profiles[db.profileKey]
	local new = sv.profiles[name]
	local profileCreated

	if not new then
		sv.profiles[name] = {}
		new = sv.profiles[name]
		profileCreated = true
	end

	if db.defaults and db.defaults.profile then
		-- Remove the defaults from the old profile
		removeDefaults(old, db.defaults.profile)

		-- Inject the defaults into the new profile
		copyDefaults(new, db.defaults.profile)
	end

	db.profile = new

	-- Save this new profile name
	sv.profileKeys[db.charKey] = name
    db.profileKey = name

	if profileCreated then
		Dongle:TriggerMessage("DONGLE_PROFILE_CREATED", db, db.parent, db.sv_name, db.profileKey)
	end

	Dongle:TriggerMessage("DONGLE_PROFILE_CHANGED", db, db.parent, db.sv_name, db.profileKey)
end

function Dongle.GetProfiles(db, t)
	assert(3, databases[db], "You must call 'GetProfiles' from a Dongle database object.")
	argcheck(t, 2, "table", "nil")

	t = t or {}
	local i = 1
	for profileKey in pairs(db.profiles) do
		t[i] = profileKey
		i = i + 1
	end
	return t, i - 1
end

function Dongle.DeleteProfile(db, name)
	assert(3, databases[db], "You must call 'DeleteProfile' from a Dongle database object.")
	argcheck(name, 2, "string")

	if db.profileKey == name then
		error("You cannot delete your active profile.  Change profiles, then attempt to delete.", 2)
	end

	db.sv.profiles[name] = nil
	Dongle:TriggerMessage("DONGLE_PROFILE_DELETED", db, db.parent, db.sv_name, name)
end

function Dongle.CopyProfile(db, name)
	assert(3, databases[db], "You must call 'CopyProfile' from a Dongle database object.")
	argcheck(name, 2, "string")

	assert(3, db.profileKey ~= name, "Source/Destination profile cannot be the same profile")
	assert(3, type(db.sv.profiles[name]) == "table", "Profile \""..name.."\" doesn't exist.")

	local profile = db.profile
	local source = db.sv.profiles[name]

	copyDefaults(profile, source, true)
	Dongle:TriggerMessage("DONGLE_PROFILE_COPIED", db, db.parent, db.sv_name, name, db.profileKey)
end

function Dongle.ResetProfile(db)
	assert(3, databases[db], "You must call 'ResetProfile' from a Dongle database object.")

	local profile = db.profile

	for k,v in pairs(profile) do
		profile[k] = nil
	end
	if db.defaults and db.defaults.profile then
		copyDefaults(profile, db.defaults.profile)
	end
	Dongle:TriggerMessage("DONGLE_PROFILE_RESET", db, db.parent, db.sv_name, db.profileKey)
end


function Dongle.ResetDB(db, defaultProfile)
	assert(3, databases[db], "You must call 'ResetDB' from a Dongle database object.")
    argcheck(defaultProfile, 2, "nil", "string")

	local sv = db.sv
	for k,v in pairs(sv) do
		sv[k] = nil
	end

	local parent = db.parent

	initdb(parent, db.sv_name, db.defaults, defaultProfile, db)
	Dongle:TriggerMessage("DONGLE_DATABASE_RESET", db, parent, db.sv_name, db.profileKey)
	Dongle:TriggerMessage("DONGLE_PROFILE_CREATED", db, db.parent, db.sv_name, db.profileKey)
	Dongle:TriggerMessage("DONGLE_PROFILE_CHANGED", db, db.parent, db.sv_name, db.profileKey)
	return db
end

--[[-------------------------------------------------------------------------
  Slash Command System
---------------------------------------------------------------------------]]

local slashCmdMethods = {
	"RegisterSlashHandler",
	"PrintUsage",
}

local function OnSlashCommand(cmd, cmd_line)
	if cmd.patterns then
		local pattern
		for _,tbl in pairs(cmd.patterns) do
			pattern = tbl.pattern
			if string.match(cmd_line,pattern) then
				if type(tbl.handler) == "string" then
					cmd.parent[tbl.handler](cmd.parent, 
								string.match(cmd_line, pattern))
				else
					tbl.handler(string.match(cmd_line, pattern))
				end
				return
			end
		end
	end
	cmd:PrintUsage()
end

function Dongle:InitializeSlashCommand(desc, name, ...)
	local reg = lookup[self]
	assert(3, reg, "You must call 'InitializeSlashCommand' from a registered Dongle.")
	argcheck(desc, 2, "string")
	argcheck(name, 3, "string")
	argcheck(select(1, ...), 4, "string")
	for i = 2,select("#", ...) do
		argcheck(select(i, ...), i+2, "string")
	end

	local cmd = {}
	cmd.desc = desc
	cmd.name = name
	cmd.parent = self
	cmd.slashes = { ... }
	for idx,method in pairs(slashCmdMethods) do
		cmd[method] = Dongle[method]
	end

	local genv = getfenv(0)

	for i = 1,select("#", ...) do
		genv["SLASH_"..name..tostring(i)] = "/"..select(i, ...)
	end

	genv.SlashCmdList[name] = function(...) OnSlashCommand(cmd, ...) end

	commands[cmd] = true

	return cmd
end

function Dongle.RegisterSlashHandler(cmd, desc, pattern, handler)
	assert(3, commands[cmd], "You must call 'RegisterSlashHandler' from a Dongle slash command object.")

	argcheck(desc, 2, "string")
	argcheck(pattern, 3, "string")
	argcheck(handler, 4, "function", "string")

	if not cmd.patterns then
		cmd.patterns = {}
	end
	table.insert(cmd.patterns, {
			["desc"] = desc,
			["handler"] = handler,
			["pattern"] = pattern,
		})
end

function Dongle.PrintUsage(cmd)
	assert(3, commands[cmd], "You must call 'PrintUsage' from a Dongle slash command object.")

	local usage = "|cFF33FF99"..cmd.name.."|r: "..cmd.desc.."\n".."/"..table.concat(cmd.slashes, ", /")..":\n"
	local slash = "/" .. cmd.slashes[1] .. " "

	if cmd.options then
		for _,tbl in cmd.patterns do
			usage = usage.." - "..slash..desc.."\n"
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage(usage)
end

--[[-------------------------------------------------------------------------
  Internal Event Handlers
---------------------------------------------------------------------------]]

local function PLAYER_LOGOUT(event)
	Dongle:ClearDBDefaults()
	for k,v in pairs(registry) do
		local obj = v.obj
		if type(obj["Disable"]) == "function" then
			safecall(obj["Disable"], obj)
		end
	end
end

local function PLAYER_LOGIN()
	Dongle.initialized = true
	for i,obj in ipairs(loadorder) do
		if type(obj.Enable) == "function" then
			safecall(obj.Enable, obj)
		end
	end
end

local function ADDON_LOADED(event, ...)
	for i=1, #loadqueue do
		local obj = loadqueue[i]
		table.insert(loadorder, obj)

		if type(obj.Initialize) == "function" then
			safecall(obj.Initialize, obj)
		end

		if Dongle.initialized and type(obj.Enable) == "function" then
			safecall(obj.Enable, obj)
		end
		loadqueue[i] = nil
	end
end

--[[-------------------------------------------------------------------------
  DongleStub required functions and registration
---------------------------------------------------------------------------]]

function Dongle:GetVersion() return major,minor end

local function Activate(self, old)
	if old then
		registry = old.registry or registry
		lookup = old.lookup or lookup
		loadqueue = old.loadqueue or loadqueue
		loadorder = old.loadorder or loadorder
		events = old.events or events
		databases = old.databases or databases
		commands = old.commands or commands
		messages = old.messages or messages
		frame = old.frame or CreateFrame("Frame")

		local reg = self.registry[major]
		reg.obj = self
	else
	  frame = CreateFrame("Frame")

		local reg = {obj = self, name = "Dongle"}
		registry[major] = reg
		lookup[self] = reg
		lookup[major] = reg
	end

	self.registry = registry
	self.lookup = lookup
	self.loadqueue = loadqueue
	self.loadorder = loadorder
	self.events = events
	self.databases = databases
	self.commands = commands
	self.messages = messages
	self.frame = frame

	local reg = self.registry[major]
	lookup[self] = reg
	lookup[major] = reg

	frame:SetScript("OnEvent", OnEvent)

	-- Register for events using Dongle itself
	self:RegisterEvent("ADDON_LOADED", ADDON_LOADED)
	self:RegisterEvent("PLAYER_LOGIN", PLAYER_LOGIN)
	self:RegisterEvent("PLAYER_LOGOUT", PLAYER_LOGOUT)

	-- Convert all the modules handles
	for name,obj in pairs(registry) do
		for k,v in ipairs(methods) do
			obj[k] = self[v]
		end
	end

	-- Convert all database methods
	for db in pairs(databases) do
		for idx,method in ipairs(dbMethods) do
			db[method] = self[method]
		end
	end

	-- Convert all slash command methods
	for cmd in pairs(commands) do
		for idx,method in ipairs(slashCmdMethods) do
			cmd[method] = self[method]
		end
	end
end

local function Deactivate(self, new)
	self:UnregisterAllEvents()
	lookup[self] = nil
end

Dongle = DongleStub:Register(Dongle, Activate, Deactivate)
