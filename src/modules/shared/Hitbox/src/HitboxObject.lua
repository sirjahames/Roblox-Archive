--[[
    HitboxObject.lua
    Author: Conscience (@MixedConscience)
    -----------------
    Allows for raycast hitboxes to be created.
]]

--> ------------------------------
--> Services
--> ------------------------------

local RunService = game:GetService("RunService")

--> ------------------------------
--> Variables
--> ------------------------------

local Visualizer = Instance.new("Part")
Visualizer.Anchored = true
Visualizer.CanCollide = false
Visualizer.Material = Enum.Material.Neon

--> ------------------------------
--> Module
--> ------------------------------

local HitboxObject = {}
HitboxObject.__index = HitboxObject

--> ------------------------------
--> Types
--> ------------------------------

export type Array<V> = { V }
export type Map<K, V> = { [K]: V }

export type CastOptions = {
	Object: Instance,
	DebugMode: boolean?,
	Attachments: Array<Attachment>?,
}

--> ------------------------------
--> Constructor
--> ------------------------------

function HitboxObject.new(options: CastOptions)
	local self = setmetatable({}, HitboxObject)

	self.Object = options.Object
	self.InDebugMode = options.DebugMode or false
	self.AttachmentPoints = options.Attachments or {}
	self.RegisteredHitCallback = nil
	self.RunServiceEvent = nil
	self.ShouldCast = true

	return self
end

--> ------------------------------
--> Private Functions
--> ------------------------------

function HitboxObject:_CastRayWithPositions(from: Vector3, to: Vector3, raycastParams: RaycastParams)
	local Object = self.Object
	local CastedRay = workspace:Raycast(from, to, raycastParams)

	if self.InDebugMode then
		task.spawn(function()
			local CastVisualizationFolder = Instance.new("Folder")
			CastVisualizationFolder.Name = "__CastVisualization"
			CastVisualizationFolder.Parent = Object

			local VisualizationPart = Visualizer:Clone()
			VisualizationPart.CFrame = CFrame.lookAt(from, to) * CFrame.new(0.1, 0.1, -(to - from).Magnitude/2)
			VisualizationPart.Size = Vector3.new(0.05, 0.05, (from - to).Magnitude)
			VisualizationPart.Parent = CastVisualizationFolder

			task.delay(2, VisualizationPart.Destroy, VisualizationPart)
		end)
	end

	return CastedRay
end

--> ------------------------------
--> Public Functions
--> ------------------------------

function HitboxObject:RegisterHitCallback(callback: (RaycastResult) -> (boolean?))
	self.RegisteredHitCallback = callback
end

function HitboxObject:EnableCasting(ignoreDescendants: { Instance }?)
	ignoreDescendants = ignoreDescendants or {}
	table.insert(ignoreDescendants :: {}, self.Object)

	local IgnoreRaycastParams = RaycastParams.new()
	IgnoreRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	IgnoreRaycastParams.FilterDescendantsInstances = ignoreDescendants

	local PreviousAttachments = {}
	local RunServiceEvent = if RunService:IsClient() then RunService.RenderStepped else RunService.Heartbeat

	self.RunServiceEvent = RunServiceEvent:Connect(function(delta)
		if not self.ShouldCast then return end

		for _, attachment: Attachment in self.AttachmentPoints do
			local LastPosition = PreviousAttachments[attachment.Name]

			if LastPosition and (LastPosition ~= attachment.WorldPosition) then
				local CurrentPosition = attachment.WorldPosition
				local CastedRay: RaycastResult = self:_CastRayWithPositions(LastPosition, CurrentPosition, IgnoreRaycastParams)

				if CastedRay and self.RegisteredHitCallback then
					local SuspendCasting = self.RegisteredHitCallback(CastedRay)

					if SuspendCasting then
						self:DisableCasting()
						return
					end
				end
			end

			PreviousAttachments[attachment.Name] = attachment.WorldPosition
		end
	end)
end

function HitboxObject:DisableCasting()
	self.ShouldCast = false
	self.RunServiceEvent = if self.RunServiceEvent then self.RunServiceEvent:Disconnect() else nil

	--> NOTE:
	--> instances may have been created in the debug version of this object
	--> they will usually get removed after a certain time, so we dont worry about them
	return true
end

--> ------------------------------
--> Initializer/Destructor
--> ------------------------------

function HitboxObject:Initialize()
end

function HitboxObject:Destroy()
	self:DisableCasting()

	self.Object = nil
	self.AttachmentPoints = {}
	setmetatable(self, nil)
end

return HitboxObject