-- @ScriptType: Script
-- THIS WAS NOT MADE BY ME!!!!

--!strict
local BindAction = require("@self/MovementHandler")

local BindFolder = Instance.new("Folder")
BindFolder.Name = "BindFolder"
BindFolder.Parent = script

local stateStore = {}

for actionName, actionProperties in BindAction do
	local InputContext = Instance.new("InputContext")
	local InputAction = Instance.new("InputAction")

	InputContext.Name = actionName
	InputContext:SetAttribute("Hold", actionProperties.hold)
	
	for _, keycode in actionProperties.keycode do
		local InputBinding = Instance.new("InputBinding")
		InputBinding.KeyCode = keycode
		InputBinding.UIButton = actionProperties.UI_button
		InputBinding.Parent = InputAction
	end

	InputAction.Parent = InputContext
	InputContext.Parent = BindFolder
end

for _, InputContext in BindFolder:GetChildren() do
	local InputAction = InputContext:FindFirstChildOfClass("InputAction")
	if not InputAction then return end
	
	InputAction.StateChanged:Connect(function(state)
		local nameInputContext = InputContext.Name
		local bindFunction = BindAction[nameInputContext].action

		if InputContext:GetAttribute("Hold") then
			bindFunction(state)
		else
			if state then
				local newState = not stateStore[nameInputContext]
				stateStore[nameInputContext] = newState and true or nil
				bindFunction(newState)
			end
		end
	end)
end
