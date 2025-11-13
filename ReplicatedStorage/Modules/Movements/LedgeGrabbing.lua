-- @ScriptType: ModuleScript
local user_input_service = game:GetService("UserInputService")
local context_action_service = game:GetService("ContextActionService")
local run_service = game:GetService("RunService")
local tween_service = game:GetService("TweenService")
local debris = game:GetService("Debris")
local gui_service = game:GetService("GuiService")


local player = game.Players.LocalPlayer
local character = player.Character
local camera = workspace.CurrentCamera
local humanoid = character:WaitForChild("Humanoid")
local humanoid_root_part = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")


local cameraShaker = require(game.ReplicatedStorage:WaitForChild("Modules").CameraShaker)


local function ShakeCamera(shakeCf)
	
	camera.CFrame = camera.CFrame * shakeCf
	
end

local render_priority = Enum.RenderPriority.Camera.Value + 1
local cam_shake = cameraShaker.new(render_priority, ShakeCamera)


local raycast_params = RaycastParams.new()
raycast_params.FilterDescendantsInstances = { character }
raycast_params.FilterType = Enum.RaycastFilterType.Exclude

local vault_move_number = 10
local can_ledge_climb = game.ReplicatedStorage.Booleans.IsLedgeGrabbing
local can_move = true
local vault_connection = nil
local ledge_part = nil


local loaded_anims = {
	climb = humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Animations.Movements.Climb),
	hang = humanoid.Animator:LoadAnimation(game.ReplicatedStorage.Animations.Movements.Hang)
}

local LedgeGrabbing = {}


local function PartCheck(ledge)
	
	local vaultPartCheck = workspace:Raycast(ledge.Position + Vector3.new(0, -1, 0) + ledge.LookVector * 1, ledge.UpVector * 3, raycast_params)
	
	if vaultPartCheck == nil then
		
		return true
		
	else
		
		return false
		
	end
	
end


local function LedgeMoveCheck(ray, anim)
	
	local local_pos = ray.Instance.CFrame:PointToObjectSpace(ray.Position)
	local local_ledge_pos = Vector3.new(local_pos.X, ray.Instance.Size.Y/2, local_pos.Z)
	local ledge_pos = ray.Instance.CFrame:PointToWorldSpace(local_ledge_pos)
	local ledge_offset = CFrame.lookAt(ledge_pos, ledge_pos - ray.Normal)

	if PartCheck(ledge_offset) then
		
		local magnitude = (ledge_pos - head.Position).Magnitude
		
		if magnitude < 3 then
			
			local info = TweenInfo.new(.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)
			local goal = {CFrame = ledge_offset + Vector3.new(0, -2, 0) + ledge_offset.LookVector * -1}
			local tween = tween_service:Create(ledge_part, info, goal)
			tween:Play()
			can_move = false


			cam_shake:Start()
			local dashShake = cam_shake:ShakeOnce(.2, 13, 0, .5)
			dashShake:StartFadeOut(.5)


			task.delay(.35, function()
				can_move = true
			end)
			
		end
	end
	
end


local function LedgeMove(direction, anim)
	
	local move_ray = workspace:Raycast(head.CFrame.Position, head.CFrame.RightVector * direction + head.CFrame.LookVector * 8, raycast_params)
	
	if move_ray then
		
		if move_ray.Instance then
			LedgeMoveCheck(move_ray, anim)
		end
		
	else
		
		local turn_ray = workspace:Raycast(head.CFrame.Position + Vector3.new(0, -1, 0) + head.CFrame.RightVector * direction, head.CFrame.RightVector * -direction + head.CFrame.LookVector * 2, raycast_params)
		
		if turn_ray then
			
			if turn_ray.Instance then
				
				LedgeMoveCheck(turn_ray, anim)
				
			end
			
		end
		
	end
	
end

humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
	
	if (humanoid.MoveDirection:Dot(camera.CFrame.RightVector) > .7) and can_ledge_climb.Value == false and can_move then
		
		LedgeMove(vault_move_number, "Right")
		
	end

	if (humanoid.MoveDirection:Dot(-camera.CFrame.RightVector) > .7) and can_ledge_climb.Value == false and can_move then
		
		LedgeMove(-vault_move_number, "Left")
		
	end
end)


function LedgeGrabbing.DetectLedge()
	
	if can_ledge_climb.Value == true and (humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping) then
		
		local vaultCheck = workspace:Raycast(humanoid_root_part.CFrame.Position, humanoid_root_part.CFrame.LookVector * 5, raycast_params)
		
		if vaultCheck then
			
			if vaultCheck.Instance then			
				local local_pos = vaultCheck.Instance.CFrame:PointToObjectSpace(vaultCheck.Position)
				local local_ledge_pos = Vector3.new(local_pos.X, vaultCheck.Instance.Size.Y/2, local_pos.Z)
				local ledge_pos = vaultCheck.Instance.CFrame:PointToWorldSpace(local_ledge_pos)
				local ledge_offset = CFrame.lookAt(ledge_pos, ledge_pos - vaultCheck.Normal)

				local magnitude = (ledge_pos - head.Position).Magnitude
				
				if magnitude < 4 then
					
					if PartCheck(ledge_offset) then
						
						can_ledge_climb.Value = false

						cam_shake:Start()
						local dash_shake = cam_shake:ShakeOnce(.36, 12, 0, .5)
						dash_shake:StartFadeOut(.5)


						ledge_part = Instance.new("Part")
						ledge_part.Parent = workspace
						ledge_part.Anchored = true
						ledge_part.Size = Vector3.one
						ledge_part.CFrame = ledge_offset + Vector3.new(0, -2, 0) + ledge_offset.LookVector * -1
						ledge_part.CanQuery = false
						ledge_part.CanCollide = false
						ledge_part.CanTouch = false
						ledge_part.Transparency = 1

						loaded_anims.hang:Play()
						
						vault_connection = run_service.RenderStepped:Connect(function(dt)
							
							humanoid_root_part.Anchored = true
							humanoid.AutoRotate = false 
							humanoid_root_part.CFrame = humanoid_root_part.CFrame:Lerp(CFrame.lookAt(ledge_part.Position, (ledge_part.CFrame * CFrame.new(0, 0, -1)).Position), .25)
							humanoid:ChangeState(Enum.HumanoidStateType.Seated)
							
						end)
						
					end
					
				end
				
			end
			
		end
		
	elseif can_ledge_climb.Value == false then
		
		can_ledge_climb.Value = true
		humanoid.AutoRotate = true
		humanoid_root_part.Anchored = false
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

		loaded_anims.hang:Stop()
		loaded_anims.climb:Play()

		if vault_connection then
			vault_connection:Disconnect()
		end

		if ledge_part then
			
			ledge_part:Destroy()
			
		end
	end
	
end

return LedgeGrabbing
