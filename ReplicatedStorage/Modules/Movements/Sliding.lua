-- @ScriptType: ModuleScript


local Sliding = {}

--// Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

--// Players Stuff
local Plr = game.Players.LocalPlayer
local Char = Plr.Character
local RootPart = Char:FindFirstChild("HumanoidRootPart")
local Humanoid = Char:FindFirstChildOfClass("Humanoid")
local SlideAnim = Humanoid:LoadAnimation(game.ReplicatedStorage.Animations.Movements.Slide)

--// Varaibles
local isSliding = false
local CanSlide = true
local PosCheck
local CurrentMultiplier = 1

--// Objects
local SlideVelocity
local AlignGyro

local Settings = {

	Cooldown = 0.1,
	BaseSpeed = 35,
	HipHeight = {
		Normal = 0,
		Slide = -2,
	},
	MaxMultiplier = 2,
	SpeedChangeRate = {
		Forward = 1,
		Upward = 2,
		Downward = 1
	},
	PushOnCancel = false,
	PushVelocity = {
		Forward = 50,
		Up = 50,
	},

}

local Params = RaycastParams.new()
Params.FilterDescendantsInstances = {Char}
Params.FilterType = Enum.RaycastFilterType.Exclude

function Sliding.StopSlide()

	isSliding = false

	PosCheck:Disconnect()

	SlideVelocity:Destroy()
	AlignGyro:Destroy()
	SlideAnim:Stop(0.15)

	Humanoid.HipHeight = Settings.HipHeight.Normal

	task.delay(Settings.Cooldown,function()
		CanSlide = true
	end)


	local CancelMultiplier = CurrentMultiplier
	
	if Settings.PushOnCancel == true then

		local PushVelocity = Instance.new("BodyVelocity",RootPart)
		PushVelocity.MaxForce = Vector3.new(40000,40000,40000)
		PushVelocity.Velocity = (RootPart.CFrame.LookVector * (Settings.PushVelocity.Forward * CancelMultiplier)) + (RootPart.CFrame.UpVector * Settings.PushVelocity.Up)
		Debris:AddItem(PushVelocity,0.1)

	end
	
end

function Sliding.Slide()
	
	--// Cast a ray down to check if player's grounded or no
	local RayDirection = -RootPart.CFrame.UpVector * 5
	local GroundRay = workspace:Raycast(RootPart.Position, RayDirection, Params)

	if isSliding or not CanSlide or not GroundRay then return end

	isSliding = true
	CanSlide = false
	SlideAnim:Play(0.15)

	Humanoid.HipHeight = Settings.HipHeight.Slide

	SlideVelocity = Instance.new("BodyVelocity",RootPart)
	SlideVelocity.MaxForce = Vector3.new(40000,0,40000)
	SlideVelocity.Velocity = RootPart.CFrame.LookVector * Settings.BaseSpeed

	AlignGyro = Instance.new("BodyGyro",RootPart)
	AlignGyro.MaxTorque = Vector3.new(3e5,3e5,3e5)
	AlignGyro.P = 10000

	local PreviousY = 0
	CurrentMultiplier = 1

	PosCheck = RunService.Heartbeat:Connect(function(deltaTime)

		local CurrentY = RootPart.Position.Y
		local VerticalChange = (CurrentY - PreviousY)
		PreviousY = CurrentY

		local RayDirection = -RootPart.CFrame.UpVector * 10
		local GroundRay = workspace:Raycast(RootPart.Position, RayDirection, Params)

		--// Align Character to the slope
		if GroundRay then

			local CurrentRightVector = RootPart.CFrame.RightVector
			local UpVector = GroundRay.Normal
			local NewFacialVector = CurrentRightVector:Cross(UpVector)
			AlignGyro.CFrame = CFrame.fromMatrix(RootPart.Position, CurrentRightVector, UpVector, NewFacialVector)

		end

		SlideVelocity.Velocity = RootPart.CFrame.LookVector * (Settings.BaseSpeed * CurrentMultiplier)

		if VerticalChange < 0.1 and VerticalChange > -0.1 then -- Slide Forward (decrease speed until 0)

			if CurrentMultiplier > 1 then -- If too fast speed rate will multiply and speed will drop fastur!

				CurrentMultiplier = math.clamp(CurrentMultiplier - (Settings.SpeedChangeRate.Forward * 2) * deltaTime, 0, Settings.MaxMultiplier)

			end


			CurrentMultiplier = math.clamp(CurrentMultiplier - Settings.SpeedChangeRate.Forward * deltaTime, 0, Settings.MaxMultiplier)

		elseif VerticalChange > 0 then -- Slide Up (decrease speed until 0)

			if CurrentMultiplier > 1 then -- If too fast speed rate will multiply and speed will drop fastur!
				CurrentMultiplier = math.clamp(CurrentMultiplier - (Settings.SpeedChangeRate.Upward * 2) * deltaTime, 0, Settings.MaxMultiplier)
			end

			CurrentMultiplier = math.clamp(CurrentMultiplier - Settings.SpeedChangeRate.Upward * deltaTime, 0, Settings.MaxMultiplier)

		else -- Slide Down (Add up speed until max)

			CurrentMultiplier = math.clamp(CurrentMultiplier + Settings.SpeedChangeRate.Downward * deltaTime, 0, Settings.MaxMultiplier)

		end

		CurrentMultiplier = math.clamp(CurrentMultiplier,0,Settings.MaxMultiplier)

		if CurrentMultiplier < 0.1 or not GroundRay then

			Sliding.StopSlide()

		end

	end)
	
end

return Sliding