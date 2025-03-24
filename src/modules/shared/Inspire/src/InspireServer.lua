local Inspire = {}

Inspire.Name = "Inspire"
Inspire.Runtime = "Server"
Inspire.Version = "0.0.0"
Inspire.PreloadedModules = {}
Inspire.InternalContexts = {}
Inspire.RequiredModules = {}

local InspireFolder = script.Parent
local Internal = InspireFolder.Internal
local InspireLogger = require(Internal.Logger).new(Inspire.Name)
local InspireSignal = require(Internal.Signal)

local UtilityModules = {}
local CustomModules = {}

function Inspire.CreateContext(name: string, config)
	local Context = config or {}
	Context._type = "Context"
	Context._base = "ContextObject"
	Context._dependencies = {} --> todo later or remove it overall
	
	Context.Name = name
	Context.Utility = UtilityModules
	Context.Custom = CustomModules
	
	Inspire.InternalContexts[name] = Context
	return Context
end

function Inspire.AppendModules(modules: { ModuleScript })
	for _, module in modules do
		if not module:IsA("ModuleScript") then
			continue
		end
		
		table.insert(Inspire.PreloadedModules, module)
	end
end

function Inspire.Initialize()
	InspireLogger:OutputMessage("Message", "hello world initialize!")
	
	local InitializeQueue = {}
	local InitializedSignal = InspireSignal.new()
	
	for _, module in Inspire.PreloadedModules do
		local Success, Response = pcall(require, module)
		
		if not Success then
			InspireLogger:OutputMessage("Exception", `Module {module.Name} had an exception while requiring:\n{Response}`)
			continue
		end
		
		if not Response.Name or (Response.Name ~= module.Name) then
			InspireLogger:OutputMessage("Exception", `Module {module.Name} must contain a .Name property with the same name as the ModuleScript!`)
			continue
		end
		
		if not (Response._type and Response._base) then
			InspireLogger:OutputMessage("Exception", `Module {module.Name} return object that was not created by Inspire. Please use Inspire.CreateContext(...)!`)
			continue
		end
		
		table.insert(Inspire.RequiredModules, Response)
	end
	
	for _, context in Inspire.InternalContexts do
		--> note:
		--> this is initialization of the module
		--> here, we append it to a queue stating its currently being initialized
		--> that allows for the stalling of the current thread until all modules have been initialized

		--> note:
		--> this is all asynchronous with initializing modules 
		if context.Initialize then
			table.insert(InitializeQueue, context.Name)

			task.spawn(function()
				context:Initialize()

				local IndexAtModuleName = table.find(InitializeQueue, context.Name)
				if IndexAtModuleName then table.remove(InitializeQueue, IndexAtModuleName) end

				InitializedSignal:Fire()
			end)
		end
	end
	
	while #InitializeQueue ~= 0 do
		InitializedSignal:Wait()
	end
	
	InspireLogger:OutputMessage("Message", "goodbye world initialize!")
end

function Inspire.Commence()
	InspireLogger:OutputMessage("Message", "hello world commence!")
	
	for _, context in Inspire.InternalContexts do
		--> note:
		--> this is simple commencement of the module, nothing special
		if context.Commence then
			context:Commence()
		end
	end
	
	InspireLogger:OutputMessage("Message", "goodbye world commence!")
end

return Inspire