local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

task.spawn(function()
	while warden.Parent do
		task.wait(0.8)

		root = warden:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < -8 then
			warden:PivotTo(CFrame.new(Config.Warden.SpawnPosition))
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
end)

print("[HELL ASCENT] THE WARDEN visual polish applied")
