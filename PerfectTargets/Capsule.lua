local _G = getfenv(0)
local dongle = DongleStub("Dongle-Beta0")
Capsule = dongle:New("Capsule")

local enable,disable

function Capsule:New(moduleName, ...)
	if not self:HasModule(moduleName) then
		local module = self:NewModule(moduleName) 
		module.loadcondition = loadcondition
		self:RegisterTrigger(module)
		return module
	end
end

function Capsule:Get(moduleName)
	local module = self:HasModule(moduleName)
	if module then module.obtained = true end
	return module
end

function Capsule:Load(moduleName)
	local module = self:HasModule(moduleName)
	if not module or module.obtained then return end
	local _, name, enabled, loadable, reason
	name, _, _, enabled, loadable, reason = GetAddOnInfo(moduleName)
	if not name or not enabled then self:UnregisterCondition(module) end
	if not loadable or IsAddOnLoaded(moduleName) then return end
	for dep in GetAddOnDependencies(moduleName) do
		if self:HasModule(dep) then
			self:ModuleEnable(dep)
		end
	end

	local loaded, reason = LoadAddOn(moduleName)
end

function Capsule:ModuleEnable(module)
	if not module then return end
	self:Load(module)
	if module.obtained then 
		self:UnregisterTrigger(module) 
		module.disabled = nil
	end
end

function Capsule:ModuleDisable(module)
	if not module or not module.obtained then return end
	module:Disable()
	module.disabled = true
	self:RegisterTrigger(module)
end

function Capsule:RegisterTrigger(module, loadcondition)
	if not module then return end
	if 

