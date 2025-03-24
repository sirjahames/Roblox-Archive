--[[
    Client.lua
    Author: Conscience (@MixedConscience)
    -----------------
    Client-sided runtime for the Foundation framework.
]]

local Foundation = script.Parent
local Dependencies = Foundation.Dependencies
local Signal = require(Dependencies.Signal)

local Client = {}

local Private = {}
Private.Runtime = "Client"
Private.ModuleCreated = Signal.new()
Private.ModuleInitialized = Signal.new()
Private.Modules = {}

function Client.Create<T>(name: string, context: T)
	(context :: any).Name = name
	Private.ModuleCreated:Fire(context)
	return context
end

function Client.Initialize(modules: { Instance })
	local InitializationQueue = 0

	for _, moduleScript in modules do
		if moduleScript:IsA("ModuleScript") then
			local Success, Exception = pcall(require, moduleScript)

			if not Success then
				error(`[Foundation<{Private.Runtime}>}]: Exception while requiring '{moduleScript.Name}':\n{Exception}`)
			end

			local Module = Exception

			--

			if Private.Modules[moduleScript.Name] then
				error(`[Foundation<{Private.Runtime}>}]: Module with the name '{moduleScript.Name}' already found (duplicate)`)
			end

			if Module.Name ~= moduleScript.Name then
				error(`[Foundation<{Private.Runtime}>}]: Mismatched names for module '{moduleScript.Name}' ({moduleScript.Name} ~= {Module.Name})`)
			end

			--

			if Module.Initialize and typeof(Module.Initialize) == "function" then
				InitializationQueue += 1

				task.spawn(function()
					Module:Initialize()
					InitializationQueue -= 1
					Private.ModuleInitialized:Fire(Module)
				end)
			end

			Private.Modules[moduleScript.Name] = Module
		end
	end

	--

	while InitializationQueue > 0 do
		Private.ModuleInitialized:Wait()
	end
end

function Client.Serve()
	for _, module in Private.Modules do
		if module.Serve then
			task.spawn(module.Serve, module)
		end
	end
end

return Client