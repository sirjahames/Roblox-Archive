local Feather = require(...)

local part = Feather.create("Part", "object") {
	["Anchored"] = true,
	["Position"] = Vector3.yAxis * 50,
	["Color"] = Color3.new(1, 1, 1),
	
	["Touched"] = function(self, hit: BasePart)
		print(self.Name, " was hit by: ", hit.Name)
	end,
	
	["GetPropertyChanged.Color"] = function(color)
		print("Current color:", color)
	end,
	
	["GetAttributeChanged.Block"] = function(status)
		print("Current block status:", status)
	end,
}

part.Parent = workspace