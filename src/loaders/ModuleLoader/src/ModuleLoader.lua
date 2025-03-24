--[[
    ModuleLoader.lua
    Author: Conscience (@MixedConscience)
    -----------------
    Allows for modules to be loaded and executed (in an unknown order). 
]]

--> ------------------------------
--> Services
--> ------------------------------

local RunService = game:GetService("RunService")

--> ------------------------------
--> Module
--> ------------------------------

local ModuleLoader = {}

--> ------------------------------
--> Private
--> ------------------------------

local Private = {}
Private.Runtime = if RunService:IsClient() then "Client" else "Server"
Private.Modules = {}

--> ------------------------------
--> Public Functions
--> ------------------------------

function ModuleLoader.PrepareModules(modules: { Instance })
	for _, moduleScript in modules do
		if moduleScript:IsA("ModuleScript") then
			local Success, Exception = pcall(require, moduleScript)

			if not Success then
				error(`[ModuleLoader<{Private.Runtime}>}]: Exception while requiring '{moduleScript.Name}':\n{Exception}`)
			end

			local Module = Exception
			Private.Modules[moduleScript.Name] = Module
		end
	end
end

function ModuleLoader.Initialize()
	for _, module in Private.Modules do
		if module.Initialize then
			module.Initialize()
		end
	end
end

function ModuleLoader.Begin()
	for _, module in Private.Modules do
		if module.Begin then
			module.Begin()
		end
	end
end

return ModuleLoader