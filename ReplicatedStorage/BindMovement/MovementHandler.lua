-- @ScriptType: ModuleScript
--!strict
type ActionProperty = {
	[string]: { 
		hold: boolean, 
		keycode: {Enum.KeyCode}, 
		UI_button: GuiButton?,
		action: (state: boolean) -> boolean
	}
}

---------------------------- SERVICES ----------------------------

local replicated_storage = game:GetService("ReplicatedStorage")
local user_input_service = game:GetService("UserInputService")

-------------------------- PLAYER STUFF --------------------------

local player = game.Players.LocalPlayer

repeat task.wait() until player.Character

local character = player.Character
local humanoid_root_part = character:WaitForChild("HumanoidRootPart")
local humanoid : Humanoid = character:WaitForChild("Humanoid") 

---------------------------- RAYCAST -----------------------------

local default_params = RaycastParams.new()
default_params.FilterType = Enum.RaycastFilterType.Exclude
default_params.FilterDescendantsInstances = { character }

---------------------------- BOOLEANS ----------------------------

local on_ledge = replicated_storage.Booleans.IsLedgeGrabbing
local in_air = false
local vault = false
local is_sprinting = false
local is_sliding = false

---------------------------- MODULES -----------------------------

local modules = replicated_storage.Modules.Movements
local sprinting = require(modules.Sprinting)
local vaulting = require(modules.Vaulting)
local ledge_grab = require(modules.LedgeGrabbing)
local sliding = require(modules.Sliding)

---------------------------- UTILITES ----------------------------

local vault_object = nil

local function airCheck()

	local hrp_ray = Ray.new(humanoid_root_part.Position,
		humanoid_root_part.CFrame.UpVector * (-3.50))

	local hrp_raycast = workspace:Raycast(hrp_ray.Origin, hrp_ray.Direction, default_params)

	if hrp_raycast then

		in_air = false
	
	else
		
		in_air = true
	
	end

end

----------------------------- RUN SERVICE ----------------------------

game:GetService("RunService").RenderStepped:Connect(function(dt)
	
	--------------------------- VAULT CHECK --------------------------
	
	airCheck()
	
	local temp_vault_object = vaulting.DetectVault()
	
	if temp_vault_object and in_air == false and is_sprinting == true then
		
		if temp_vault_object.Instance.Size.Y > 4 then return end
		
		vault_object = temp_vault_object.Instance
		
		vault = true
		humanoid.JumpPower = 0
		
	else 
		
		vault = false
		humanoid.JumpPower = 50
		
	end
	
	
end)

local Actions: ActionProperty = {
	
	LedgeGrab = {
		hold = false,
		keycode = {Enum.KeyCode.Space},
		UI_button = nil,
		action = function(state)
			
			ledge_grab.DetectLedge()
			
			return state;
			
		end,
	},
	
	Slide = {
		hold = true,
		keycode = {Enum.KeyCode.C},
		UI_button = nil,
		action = function(state)
			
			is_sliding = true
			
			sliding.Slide()
			
			return state;
			
		end,
	},
	
	EndSlide = {
		hold = true,
		keycode = {Enum.KeyCode.Space},
		UI_button = nil,
		action = function(state)

			if is_sliding == false then return state end
			
			is_sliding = false
			 
			sliding.StopSlide()
			
			return state;
			
		end,
	},
		
	Vault = {
		hold = false,
		keycode = {Enum.KeyCode.Space},
		UI_button = nil,
		action = function(state)
			
			if on_ledge == true then return state; end
			
			if vault then
				
				vaulting.Vault(vault_object)
				
			end
			
			return state;
			
		end,
	},
	
	Sprint = {
		hold = true,
		keycode = {Enum.KeyCode.LeftShift},
		UI_button = nil,
		action = function(state)
			
			if state == true and on_ledge.Value == true then
				
				is_sprinting = true
				sprinting.StartSprint(humanoid)
			
			else
				
				is_sprinting = false
				sprinting.EndSprint(humanoid)
				
			end
			
			return state;
			
		end,
	},
	
	
}

return Actions