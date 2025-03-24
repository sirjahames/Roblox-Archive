local Feather = {}

Feather.Name = "Feather"
Feather.Version = "0.0.0"

local FeatherFolder = script.Parent
local Internal = FeatherFolder.Internal
local FeatherLogger = require(Internal.Logger).new(Feather.Name)

function Feather.create(obj: string, name: string?)
	local Success, Object: Instance = pcall(Instance.new, obj)
	Object.Name = name or Object.Name
	
	if not Success then
		FeatherLogger:OutputMessage("Exception", `Cannot create unknown instance {name}!`)
	end
	
	return function(properties)
		for property, value in properties do
			--> sorting out custom keys (aka property; this may be special things)
			if typeof(property) == "table" then
				if property._type and property._base then
					continue
				end
			end
			
			--> sorting out custom values (aka value; this may be states or something else)
			if typeof(value) == "table" then
				if property._type and property._base then
					continue
				end
			end
			
			--> sorting out events
			if typeof(value) == "function" then
				if typeof(property) == "string" then
					local SplitProperty = string.split(property, ".")
					local EventBase = SplitProperty[1]
					local Reference = SplitProperty[2] --> i couldnt think of a name that has both property and attribute combined...
					
					if not Reference and (typeof(Object[property]) == "RBXScriptSignal") then
						(Object[property] :: RBXScriptSignal):Connect(function(...)
							value(Object, ...)
						end)

						continue
					else
						--> note:
						--> alright, heres a special functionality
						--> you can have GetPropertyChangedSignal with a property attached!
						--> isnt that fun! might not be but anyways, just do:
						--> ["GetPropertyChanged.{property}"] = function

						--> example:
						--> ["GetPropertyChanged.Color"] = function(currentColor) end

						--> note:
						--> the same can be applied for attributes :)

						if (EventBase == "") or (Reference == "") then
							FeatherLogger:OutputMessage("Exception", `Could not link ScriptSignal to event base or property. Format: ["EventBase.Property"]!`)
						end

						local EventScriptSignal = if EventBase == "GetPropertyChanged" then Object:GetPropertyChangedSignal(Reference) 
							elseif EventBase == "GetAttributeChanged" then Object:GetAttributeChangedSignal(Reference) else nil

						if not EventScriptSignal then
							FeatherLogger:OutputMessage("Exception", `Event base for ScriptSignal should be GetPropertyChanged or GetAttributeChanged; got {EventBase}!`)	
						end

						EventScriptSignal:Connect(function()
							local CurrentValue = if EventBase == "GetAttributeChanged" then Object:GetAttribute(Reference) else Object[Reference]
							value(CurrentValue)
						end)

						continue
					end
				end
			end

			if typeof(value) == "Instance" then
				value.Parent = Object
				continue
			end
			
			--> unsafe set of property
			local Success, _ = pcall(function()
				Object[property] = value
			end)
			
			if not Success then
				FeatherLogger:OutputMessage("Exception", `Cannot assign property {property} to object {obj}; may be caused by a type mismatch or invalid property!`)
			end
		end
		
		return Object
	end
end

return Feather