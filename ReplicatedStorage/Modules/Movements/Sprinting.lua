-- @ScriptType: ModuleScript
local Sprint = {}

local camera = workspace.CurrentCamera
local TS = game:GetService("TweenService")

local player = game.Players.LocalPlayer

repeat task.wait() until player.Character

local character = player.Character
local humanoid_root_part = character:WaitForChild("HumanoidRootPart")
local humanoid : Humanoid = character:WaitForChild("Humanoid") 

local animator : Animator = humanoid.Animator 

local loaded_animations = {
	["Run"] = animator:LoadAnimation(game.ReplicatedStorage.Animations.Movements.Run)
}

function Sprint.StartSprint(humanoid : Humanoid)
	
	TS:Create(camera, TweenInfo.new(0.75), {FieldOfView = 85}):Play()
	TS:Create(humanoid, TweenInfo.new(0.75), {WalkSpeed = 24}):Play()
	
	loaded_animations.Run:Play(0.55)
	
end

function Sprint.EndSprint(humanoid : Humanoid)
	
	TS:Create(camera, TweenInfo.new(0.75), {FieldOfView = 70}):Play()
	TS:Create(humanoid, TweenInfo.new(0.75), {WalkSpeed = 8}):Play()
	
	loaded_animations.Run:Stop(0.35)
	
end

return Sprint
