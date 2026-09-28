local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))

local world = workspace:WaitForChild("HellAscentWorld")
local warden = world:WaitForChild("TheWarden", 15)

if not warden then
	warn("[HELL ASCENT] WardenPolish could not find TheWarden")
	return
end

local humanoid = warden:FindFirstChildOfClass("Humanoid")
local root = warden:FindFirstChild("HumanoidRootPart")

-- The concept art target is roughly 1.5-1.8x a Roblox avatar.
pcall(function()
	warden:ScaleTo(0.60)
end)

if humanoid then
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.HipHeight = 2.45
end

if root then
	root:SetNetworkOwner(nil)
end

local function anyActiveRun()
	for _, player in ipairs(Players:GetPlayers()) do
		if (player:GetAttribute("SealsBroken") or 0) > 0
			and not player:GetAttribute("LayerOneEscaped")
			and not player:GetAttribute("RunExpired")
		then
			return true
		end
	end
	return false
end

task.spawn(function()
	local lastPosition = root and root.Position or Config.Warden.SpawnPosition
	local stuckFor = 0

	while warden.Parent do
		task.wait(0.8)

		root = warden:FindFirstChild("HumanoidRootPart")
		humanoid = warden:FindFirstChildOfClass("Humanoid")

		if root then
			if root.Position.Y < -8 then
				warden:PivotTo(CFrame.new(Config.Warden.SpawnPosition))
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				stuckFor = 0
				lastPosition = Config.Warden.SpawnPosition
			else
				local moved = (root.Position - lastPosition).Magnitude
				local tryingToMove = humanoid and humanoid.MoveDirection.Magnitude > 0.05

				if anyActiveRun() and tryingToMove and moved < 1.0 then
					stuckFor += 0.8
				else
					stuckFor = 0
				end

				if stuckFor >= 8 then
					warden:PivotTo(CFrame.new(Config.Warden.SpawnPosition))
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					stuckFor = 0
				end

				lastPosition = root.Position
			end
		end
	end
end)

print("[HELL ASCENT] THE WARDEN visual polish applied")
