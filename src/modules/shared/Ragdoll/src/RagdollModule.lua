--[[
    RagdollObject.lua
    Author: Conscience (@MixedConscience)
    -----------------
    Allows for R6 players to be ragdolled. 
    This functionality can be enabled and disabled quickly throughout gameplay.
]]

--> ------------------------------
--> Module
--> ------------------------------

local RagdollModule = {}

RagdollModule.ColliderSizeMultiplier = 0.75
RagdollModule.LimbColliderSelection = { "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
RagdollModule.AttachmentOffsetPositions = {
	["Left Shoulder"] 	= { [1] = Vector3.new(0, 0.5, 0), 	[2] = Vector3.new(0, 0.5, 0) },
	["Right Shoulder"] 	= { [1] = Vector3.new(0, 0.5, 0), 	[2] = Vector3.new(0, 0.5, 0) },
	["Left Hip"] 		= { [1] = Vector3.new(0.5, 0, 0), 	[2] = Vector3.new(0.5, 0, 0) },
	["Right Hip"] 		= { [1] = Vector3.new(-0.5, 0, 0), 	[2] = Vector3.new(-0.5, 0, 0) }
}

--> ------------------------------
--> Private Functions
--> ------------------------------

local function CreateLimbColliders(character: Model)
	local ColliderFolder = character:FindFirstChild("__RagdollColliders")

	if not ColliderFolder then
		ColliderFolder = Instance.new("Folder")
		ColliderFolder.Name = "__RagdollColliders"
		ColliderFolder.Parent = character
	end

	for _, limb in character:GetChildren() do
		if limb:IsA("BasePart") and table.find(RagdollModule.LimbColliderSelection, limb.Name) then
			local Collider = Instance.new("Part")
			Collider.Name = `_{limb.Name} Collider`
			Collider.Size = limb.Size * RagdollModule.ColliderSizeMultiplier
			Collider.Massless = true
			Collider.Transparency = 1
			Collider.CanCollide = true

			local Weld = Instance.new("Weld")
			Weld.Part0 = limb
			Weld.Part1 = Collider
			Weld.Parent = limb

			Collider.Parent = ColliderFolder
		end
	end
end

local function DestroyLimbColliders(character: Model)
	local ColliderFolder = character:FindFirstChild("__RagdollColliders")

	if ColliderFolder then
		ColliderFolder:ClearAllChildren()
		ColliderFolder:Destroy()
	end
end

--> ------------------------------
--> Public Functions
--> ------------------------------

function RagdollModule.Ragdoll(character: Model)
	local Humanoid = character:WaitForChild("Humanoid") :: Humanoid

	CreateLimbColliders(character)

	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") then
			local BallSocket = Instance.new("BallSocketConstraint")
			local AttachmentOne = Instance.new("Attachment")
			local AttachmentTwo = Instance.new("Attachment")

			BallSocket.Name = `{motor.Name} BallSocket`
			AttachmentOne.Name = `{motor.Name} RagdollOne`
			AttachmentTwo.Name = `{motor.Name} RagdollTwo`

			BallSocket.Attachment0 = AttachmentOne
			BallSocket.Attachment1 = AttachmentTwo

			AttachmentOne.CFrame = motor.C0
			AttachmentTwo.CFrame = motor.C1

			local AttachmentOffsetPositions = RagdollModule.AttachmentOffsetPositions[motor.Name]

			if AttachmentOffsetPositions then
				AttachmentOne.Position += AttachmentOffsetPositions[1]
				AttachmentTwo.Position += AttachmentOffsetPositions[2]
			end

			--> Thank you CompletedLoop on the dev forum!
			--> They provided the configuration for the limits!
			--> "Perfect R6 Ragdolls - Easiest Ragdoll System for R6 Avatars" - Dev Forum
			--> -------------------------------------------------------------------------

			BallSocket.Radius = 0.15
			BallSocket.LimitsEnabled = true
			BallSocket.TwistLimitsEnabled = false
			BallSocket.MaxFrictionTorque = 0
			BallSocket.Restitution = 0
			BallSocket.UpperAngle = 90
			BallSocket.TwistLowerAngle = -45
			BallSocket.TwistUpperAngle = 45

			if motor.Name == "Neck" then
				BallSocket.TwistLimitsEnabled = true
				BallSocket.UpperAngle = 45
				BallSocket.TwistLowerAngle = -70
				BallSocket.TwistUpperAngle = 70
			end

			AttachmentOne.Parent = motor.Part0
			AttachmentTwo.Parent = motor.Part1
			BallSocket.Parent = motor.Parent

			motor.Enabled = false
		end
	end

	character:SetAttribute("RagdollEnabled", true)
	Humanoid.AutoRotate = false
	Humanoid.PlatformStand = true
end

function RagdollModule.Unragdoll(character: Model)
	local Humanoid = character:WaitForChild("Humanoid") :: Humanoid

	for _, instance in character:GetDescendants() do
		if instance:IsA("Motor6D") then
			instance.Enabled = true
		end

		if instance:IsA("BallSocketConstraint") then
			instance:Destroy() --> Ball Socket!
		end

		if instance:IsA("Attachment") then
			if string.find(instance.Name, "RagdollOne") or string.find(instance.Name, "RagdollTwo") then
				instance:Destroy() --> Attachments!
			end
		end
	end

	DestroyLimbColliders(character)	
	character:SetAttribute("RagdollEnabled", false)
	Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	Humanoid.PlatformStand = false
	Humanoid.AutoRotate = true
end

return RagdollModule