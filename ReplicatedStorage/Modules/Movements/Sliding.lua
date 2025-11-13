-- @ScriptType: ModuleScript


local Sliding = {}


local run_service = game:GetService("RunService")
local debris = game:GetService("Debris")


local player = game.Players.LocalPlayer
local character = player.Character
local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")

local slide_anim = humanoid:LoadAnimation(game.ReplicatedStorage.Animations.Movements.Slide)


local is_sliding = false
local can_slide = true
local pos_check
local current_multiplier = 1


local slide_velocity
local align_gyro

local Settings = {

	cooldown = 0.1,
	base_speed = 35,
	hip_height = {
		normal = 0,
		slide = -2,
	},
	max_multiplier = 2,
	speed_change_rate = {
		forward = 1,
		upward = 2,
		downward = 1
	},
	push_velocity = {
		forward = 50,
		up = 50,
	},

}

local params = RaycastParams.new()
params.FilterDescendantsInstances = { character }
params.FilterType = Enum.RaycastFilterType.Exclude

function Sliding.StopSlide()

	is_sliding = false

	pos_check:Disconnect()

	slide_velocity:Destroy()
	align_gyro:Destroy()
	slide_anim:Stop(0.15)

	humanoid.HipHeight = Settings.hip_height.normal

	task.delay(Settings.cooldown,function()
		can_slide = true
	end)


end

function Sliding.Slide()
	
	--// Cast a ray down to check if player's grounded or no
	local ray_direction = -humanoid_root_part.CFrame.UpVector * 5
	local ground_ray = workspace:Raycast(humanoid_root_part.Position, ray_direction, params)

	if is_sliding or not can_slide or not ground_ray then return end

	is_sliding = true
	can_slide = false
	slide_anim:Play(0.15)

	humanoid.HipHeight = Settings.hip_height.slide

	slide_velocity = Instance.new("BodyVelocity", humanoid_root_part)
	slide_velocity.MaxForce = Vector3.new(40000,0,40000)
	slide_velocity.Velocity = humanoid_root_part.CFrame.LookVector * Settings.base_speed

	align_gyro = Instance.new("BodyGyro", humanoid_root_part)
	align_gyro.MaxTorque = Vector3.new(3e5,3e5,3e5)
	align_gyro.P = 10000

	local previous_y = 0
	current_multiplier = 1

	pos_check = run_service.Heartbeat:Connect(function(delta_time)

		local current_y = humanoid_root_part.Position.Y
		local vertical_change = (current_y - previous_y)
		previous_y = current_y

		local ray_direction = -humanoid_root_part.CFrame.UpVector * 10
		local ground_ray = workspace:Raycast(humanoid_root_part.Position, ray_direction, params)

		--// Align Character to the slope
		if ground_ray then

			local current_right_vector = humanoid_root_part.CFrame.RightVector
			local up_vector = ground_ray.Normal
			local new_facial_vector = current_right_vector:Cross(up_vector)
			align_gyro.CFrame = CFrame.fromMatrix(humanoid_root_part.Position, current_right_vector, up_vector, new_facial_vector)

		end

		slide_velocity.Velocity = humanoid_root_part.CFrame.LookVector * (Settings.base_speed * current_multiplier)

		if vertical_change < 0.1 and vertical_change > -0.1 then -- Slide Forward (decrease speed until 0)

			if current_multiplier > 1 then -- If too fast speed rate will multiply and speed will drop fastur!

				current_multiplier = math.clamp(current_multiplier - (Settings.speed_change_rate.forward * 2) * delta_time, 0, Settings.max_multiplier)

			end


			current_multiplier = math.clamp(current_multiplier - Settings.speed_change_rate.forward * delta_time, 0, Settings.max_multiplier)

		elseif vertical_change > 0 then -- Slide Up (decrease speed until 0)

			if current_multiplier > 1 then -- If too fast speed rate will multiply and speed will drop fastur!
				current_multiplier = math.clamp(current_multiplier - (Settings.speed_change_rate.upward * 2) * delta_time, 0, Settings.max_multiplier)
			end

			current_multiplier = math.clamp(current_multiplier - Settings.speed_change_rate.upward * delta_time, 0, Settings.max_multiplier)

		else -- Slide Down (Add up speed until max)

			current_multiplier = math.clamp(current_multiplier + Settings.speed_change_rate.downward * delta_time, 0, Settings.max_multiplier)

		end

		current_multiplier = math.clamp(current_multiplier, 0, Settings.max_multiplier)

		if current_multiplier < 0.1 or not ground_ray then

			Sliding.StopSlide()

		end

	end)
	
end

return Sliding