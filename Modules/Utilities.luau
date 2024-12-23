local SIGNATURE = "Utilities"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local IS_SERVER = RunService:IsServer()
local IS_RUNNING = RunService:IsRunning()
local IS_EXPLOIT = typeof(identifyexecutor) == "function"

local Utilities = {}

function Utilities.GetIpInfo(ip)
	assert(not ip or IS_EXPLOIT, "Function must be executed from an exploit for custom IP lookups")

	local link = ip and `https://api.ipapi.is/?q={ip}` or "https://api.ipapi.is"
	return IS_EXPLOIT and HttpService:JSONDecode(request({Url = link}).Body) or HttpService:JSONDecode(HttpService:GetAsync(link))
end

function Utilities.GetIpLocation(ip)
	assert(IS_SERVER or IS_EXPLOIT, "Function must be executed from the server")
	assert(not ip or IS_EXPLOIT, "Function must be executed from an exploit for custom IP lookups") -- If IP is given, ensure it is executed from an exploit 

	local ip_info = Utilities.GetIpInfo(ip).location
	return `{ip_info.city} ({ip_info.state}, {ip_info.country})`
end

function Utilities.Log(functionToCall, ...)
	assert(typeof(functionToCall) == "function", "1st argument (functionToCall) must be a function")

	functionToCall(...)
end

function Utilities.SwitchPlayerCharacter(player, newCharacter)
	assert(IS_SERVER, "Function must be executed from the server")

	local OriginalCharacter = player.Character
	newCharacter:PivotTo(OriginalCharacter:GetPivot()) -- Move before changing Player.Character (there's a small bug otherwise)

	newCharacter.Name = player.Name
	player.Character = newCharacter -- Change before re-parenting for the CameraSubject to change
	newCharacter.Parent = workspace

	return newCharacter
end

function Utilities.EnforceR6()
	assert(IS_SERVER, "Function must be executed on the server")
	assert(IS_RUNNING, "Function must be executed while the server is running")

	local function OnCharacterAdded(character)
		if character:WaitForChild("Humanoid").RigType == Enum.HumanoidRigType.R6 then return end

		local R6Rig = Players:CreateHumanoidModelFromDescription(
			Players:GetHumanoidDescriptionFromUserId(Players[character.Name].UserId), Enum.HumanoidRigType.R6
		)
		Utilities.SwitchPlayerCharacter(Players[character.Name], R6Rig)
	end

	for _, Player in Players:GetPlayers() do
		task.defer(function()
			OnCharacterAdded(Player.Character or Player.CharacterAdded:Wait())
			Player.CharacterAdded:Connect(OnCharacterAdded)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(OnCharacterAdded)
	end)

	return true
end

return Utilities
