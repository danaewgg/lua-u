local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local IS_SERVER = RunService:IsServer()
local IS_RUNNING = RunService:IsRunning()
local IS_EXPLOIT = typeof(identifyexecutor) == "function"

local Utilities = {
	["Log Signature"] = nil
}

function Utilities.changelogsignature(logSignature)
	Utilities["Log Signature"] = logSignature

	return true
end

function Utilities.getipinfo(ip)
	assert(not ip or IS_EXPLOIT, "Function must be executed from an exploit for custom IP lookups")
	assert(not IS_EXPLOIT or typeof(request) == "function", "Exploit does not support the following function: request()")

	local link = ip and `https://api.ipapi.is/?q={ip}` or "https://api.ipapi.is/"
	return IS_EXPLOIT and HttpService:JSONDecode(request({Url = link}).Body) or HttpService:JSONDecode(HttpService:GetAsync(link))
end

function Utilities.getiplocation(ip)
	assert(IS_SERVER or IS_EXPLOIT, "Function must be executed on the server")
	assert(not ip or IS_EXPLOIT, "Function must be executed from an exploit for custom IP lookups")

	local ip_info = Utilities.GetIpInfo(ip).location
    assert(ip_info, "Passed IP is invalid")

	return `{ip_info.city} ({ip_info.state}, {ip_info.country})`
end

function Utilities.log(functionToCall, ...)
	assert(typeof(functionToCall) == "function", "1st argument (functionToCall) must be a function")

    local messageTuple = ...
    if Utilities["Log Signature"] then
        -- In the future, I want to make this work without messing up 
        -- the functionality of being able to show tables on output in studio
        messageTuple = `{Utilities["Log Signature"]} | {...}`
    end

	functionToCall(messageTuple)

	return true
end

function Utilities.switchplayercharacter(player, newCharacter)
	assert(IS_SERVER or IS_EXPLOIT, "Function must be executed on the server")

	local OriginalCharacter = player.Character
	newCharacter:PivotTo(OriginalCharacter:GetPivot()) -- Move before changing player's .Character (there's a small bug otherwise)

	newCharacter.Name = player.Name
	player.Character = newCharacter -- Change before re-parenting for the CameraSubject to change
	newCharacter.Parent = workspace

	return newCharacter
end

function Utilities.enforcer6()
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

-- Make module functions case-insensitive
return setmetatable(Utilities, {
    __index = function(_, index)
        return rawget(Utilities, index:lower())
    end
})
