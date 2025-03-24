--[[
    RagdollObject.lua
    Author: Conscience (@MixedConscience)
    -----------------
    Allows for R6 players to be ragdolled. 
    This functionality can be enabled and disabled quickly throughout gameplay.
]]

local RagdollObject = {}
RagdollObject.__index = RagdollObject

-----------------------------------
--> Constructor/Destructor
-----------------------------------

function RagdollObject.new(character: Model)
	local self = setmetatable({}, RagdollObject)

	self.Character = character
	self.Humanoid = character:WaitForChild("Humanoid")
	self.InRagdolledState = false

	return self
end

function RagdollObject:Initialize()
	local Character: Model = self.Character
	local Humanoid: Humanoid = self.Humanoid

	Humanoid.BreakJointsOnDeath = false
	Humanoid.RequiresNeck = false

	--> Folder to hold the colliders in the character
	--> These are removed when the character despawns or when the object is destroyed
	local LimbCollisionFolder = Instance.new("Folder")
	LimbCollisionFolder.Name = "__LimbCollision"
	LimbCollisionFolder.Parent = Character

	--> note:
	--> having colliders prevent the limbs from falling into the ground below the character
	--> if we simply enable the collision on the actual limbs, that may lead to stiff looking arms and legs
	--> therefore, having colliders will make it seem more realistic in a sense
	local SizeOfColliders = {
		["Head"]        = Vector3.new(0.8, 0.8, 0.8),
		["Left Arm"]    = Vector3.new(0.8, 1.7, 0.8),
		["Right Arm"]   = Vector3.new(0.8, 1.7, 0.8),
		["Left Leg"]    = Vector3.new(0.8, 1.2, 0.8),
		["Right Leg"]   = Vector3.new(0.8, 1.2, 0.8),
	}

	--> Initializing and setting the size of the colliders within the character
	for limbName, size in SizeOfColliders do		
		local Limb = Character:FindFirstChild(limbName)

		if not Limb then
			warn(`Character<{Character.Name}>: Cannot locate limb {limbName}`)
			continue
		end

		local ClonedLimb = Limb:Clone()
		local JoinWeld = Instance.new("Weld")

		JoinWeld.Name = limbName
		JoinWeld.Part0 = Limb
		JoinWeld.Part1 = ClonedLimb
		JoinWeld.Parent = ClonedLimb

		ClonedLimb.Size = size
		ClonedLimb.CanCollide = true
		ClonedLimb.Transparency = 1
		ClonedLimb.Parent = LimbCollisionFolder
	end

	--> note:
	--> we return self for functionality such as: `local obj = Ragdoll.new(char):Initialize()`
	return self
end

function RagdollObject:Destroy()
	if self.InRagdolledState then
		self:DisableRagdoll()
	end

	local Character: Model = self.Character
	local LimbCollisionFolder: Folder = Character:FindFirstChild("__LimbCollision") :: Folder

	if LimbCollisionFolder then
		LimbCollisionFolder:ClearAllChildren()
		LimbCollisionFolder:Destroy()  
	end

	self.Character = nil
	self.Humanoid = nil
	setmetatable(self, nil)
end

-----------------------------------
--> Public Member Functions
-----------------------------------

function RagdollObject:EnableRagdoll(): boolean
	if self.InRagdolledState then
		return false
	end

	self.InRagdolledState = true

	local Character: Model = self.Character
	local Humanoid: Humanoid = self.Humanoid

	--> note:
	--> This table is used to attain the correct positions for the attachments for the respective limbs
	--> If the limb attachments arent corrected, they can lead to unpleasing ragdoll effects
	local CorrectAttachmentPositions = {
		["Left Hip"] = {
			Att0Position = Vector3.new(-0.5, -1, 0),
			Att1Position = Vector3.new(0, 1, 0)
		},

		["Right Hip"] = {
			Att0Position = Vector3.new(0.5, -1, 0),
			Att1Position = Vector3.new(0, 1, 0)
		},
	}

	Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	Humanoid.PlatformStand = true

	for _, motor in Character:GetDescendants() do
		if motor:IsA("Motor6D") then
			local Part0 = motor.Part0
			local Part1 = motor.Part1

			--> Making new attachments for the ball socket connection
			--> We do this to allow the limb to move freely while attached to the character
			local Attachment0 = Instance.new("Attachment")
			Attachment0.Name = "__RagdollAttachment"
			Attachment0.Position = motor.C0.Position
			Attachment0.Parent = Part0

			local Attachment1 = Instance.new("Attachment")
			Attachment1.Name = "__RagdollAttachment"
			Attachment1.Position = motor.C1.Position
			Attachment1.Parent = Part1

			local BallSocket = Instance.new("BallSocketConstraint")
			BallSocket.Attachment0 = Attachment0
			BallSocket.Attachment1 = Attachment1

			local AttachmentPositions = CorrectAttachmentPositions[motor.Name]

			if AttachmentPositions then
				Attachment0.Position = AttachmentPositions.Att0Position
				Attachment1.Position = AttachmentPositions.Att1Position
			end

			BallSocket.Parent = Part0
			motor.Enabled = false
		end
	end

	return true
end

function RagdollObject:DisableRagdoll(): boolean
	if not self.InRagdolledState then
		return false
	end

	self.InRagdolledState = false

	local Character: Model = self.Character
	local Humanoid: Humanoid = self.Humanoid

	for _, instance in Character:GetDescendants() do
		if instance:IsA("BallSocketConstraint") then
			local Attachment0, Attachment1 = instance.Attachment0, instance.Attachment1
			if Attachment0 then Attachment0:Destroy() end
			if Attachment1 then Attachment1:Destroy() end

			instance:Destroy()
		elseif instance:IsA("Motor6D") then
			instance.Enabled = true
		end
	end

	Humanoid.PlatformStand = false
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

	return true
end

return RagdollObject