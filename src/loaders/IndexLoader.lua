local Main = {}
Main.ModuleCache = {}
Main.AllModulesLoaded = false

type ModuleOptions = {
	Debug: boolean?
}

function Main.init(options: ModuleOptions?)
	local RunService = game:GetService("RunService")
	local Modules = script:GetDescendants()
	local Count = os.clock()
	
	if (RunService:IsServer()) then
		local SSS = game:GetService("ServerScriptService")
		
		for _, instance in ipairs(SSS:GetDescendants()) do
			if (instance:IsA("ModuleScript")) then
				local Response = Main.SafeRequire(instance)

				if (Response) then
					Main.ModuleCache[instance.Name] = Response
				end
			end
		end
	end

	Main.AllModulesLoaded = false

	for _, instance in ipairs(Modules) do
		if (instance:IsA("ModuleScript")) then
			local Response = Main.SafeRequire(instance)

			if (Response) then
				Main.ModuleCache[instance.Name] = Response
			end
		end
	end

	Main.AllModulesLoaded = true

	local End = os.clock() - Count

	if (options) then
		if (options.Debug) then
			local Type = if (RunService:IsClient()) then "Client" elseif (RunService:IsServer()) then "Server" else "~Unknown"
			warn(string.format("ModuleMain: Require time for %s-side is approx. %d seconds.", Type, End))
		end
	end
end

function Main.SafeRequire(Module: ModuleScript)
	local success, required = pcall(function()
		return require(Module)
	end)

	if (not success) then
		warn(string.format("ModuleMain: Require Failure\nModule: %s\nMessage: %s", Module.Name, required))
		return nil
	end

	return required
end

function Main.DepthRequire(Name: string)
	local Modules = script:GetDescendants()

	for _, instance in ipairs(Modules) do
		if (instance:IsA("ModuleScript")) then
			if (instance.Name == Name) then
				return instance, Main.SafeRequire(instance)
			end
		end
	end

	return false, nil
end

function Main.Fetch(...)
	local ModuleNames = {...}
	local Modules = {}

	if (not Main.AllModulesLoaded) then
		repeat
			task.wait()
		until Main.AllModulesLoaded
	end

	for _, Name in ipairs(ModuleNames) do
		local Module = Main.ModuleCache[Name]

		if (Module) then
			table.insert(Modules, Module)
			continue
		end

		local Found, Item = Main.DepthRequire(Name)

		if (Found) then
			table.insert(Modules, Item)
			continue
		end

		warn(string.format("ModuleMain: Could not fetch module '%s'.", Name))
	end

	return table.unpack(Modules)
end

return Main