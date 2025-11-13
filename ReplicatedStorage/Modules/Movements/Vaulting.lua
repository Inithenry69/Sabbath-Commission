-- @ScriptType: ModuleScript
---------------------------- PLAYER VARIABLES ----------------------------

local player = game:GetService("Players").LocalPlayer

repeat task.wait() until player.Character 

local character = player.Character
local humanoid = character:WaitForChild("Humanoid")
local humanoid_root_part = character:WaitForChild("HumanoidRootPart")

local animator = humanoid:WaitForChild("Animator")

local new_params = RaycastParams.new()
new_params.FilterType = Enum.RaycastFilterType.Exclude
new_params.FilterDescendantsInstances = { character }

local loaded_anims = {
	climb = humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Animations.Movements.Climb),
	hang = humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Animations.Movements.Hang)
}

-- Constants
local detection_distance = 4

local Vaulting = {}

function Vaulting.DetectVault()
	
	local hrp_ray = Ray.new(humanoid_root_part.Position, humanoid_root_part.CFrame.LookVector * detection_distance)	
	local hrp_raycast = workspace:Raycast(hrp_ray.Origin, hrp_ray.Direction, new_params)
	
	if hrp_raycast then return hrp_raycast end
	
end

function Vaulting.Vault(object : Part)
	
	local linear_velocity = Instance.new("LinearVelocity", humanoid_root_part)
	linear_velocity.Attachment0 = humanoid_root_part.RootAttachment
	linear_velocity.VectorVelocity = Vector3.new(0, 0, 0)
	linear_velocity.Name = "Vault Velocity"
	linear_velocity.MaxForce = 50000		

	print(humanoid_root_part.CFrame.LookVector * 75)

	humanoid_root_part["Vault Velocity"].VectorVelocity = Vector3.new(humanoid_root_part.CFrame.LookVector.X * 50, 35, humanoid_root_part.CFrame.LookVector.Z * 50)
	object.CanCollide = false
	
	loaded_anims.climb:Play()
	
	humanoid.AutoRotate = true
	
	task.wait(0.1)
	
	object.CanCollide = true
	humanoid_root_part["Vault Velocity"]:Destroy()


end

return Vaulting
