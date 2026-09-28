local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))

local world = workspace:FindFirstChild("HellAscentWorld")
if world then
	world:Destroy()
end

world = Instance.new("Folder")
world.Name = "HellAscentWorld"
world.Parent = workspace

local remotes = ReplicatedStorage:FindFirstChild("HellAscentRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "HellAscentRemotes"
	remotes.Parent = ReplicatedStorage
end

local event = remotes:FindFirstChild("HellAscentEvent")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "HellAscentEvent"
	event.Parent = remotes
end

local checkpoints = {}

local function setLighting()
	Lighting.Brightness = 1.2
	Lighting.ClockTime = 0.4
	Lighting.Ambient = Color3.fromRGB(38, 13, 13)
	Lighting.OutdoorAmbient = Color3.fromRGB(60, 20, 20)
	Lighting.FogColor = Color3.fromRGB(72, 18, 12)
	Lighting.FogStart = 35
	Lighting.FogEnd = 420
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.15

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.52
	atmosphere.Offset = -0.1
	atmosphere.Color = Color3.fromRGB(92, 44, 36)
	atmosphere.Decay = Color3.fromRGB(20, 5, 3)
	atmosphere.Glare = 0.05
	atmosphere.Haze = 2.4

	local correction = Lighting:FindFirstChild("HellColor")
	if not correction then
		correction = Instance.new("ColorCorrectionEffect")
		correction.Name = "HellColor"
		correction.Parent = Lighting
	end
	correction.Brightness = -0.08
	correction.Contrast = 0.22
	correction.Saturation = -0.28
	correction.TintColor = Color3.fromRGB(255, 188, 165)
end

local function makePart(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = true
	part.Color = color or Color3.fromRGB(45, 34, 31)
	part.Material = material or Enum.Material.Slate
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or world
	return part
end

local function makeRockPlatform(name, size, position)
	local part = makePart(
		name,
		size,
		CFrame.new(position),
		Color3.fromRGB(46, 38, 35),
		Enum.Material.Slate
	)
	return part
end

local function makeSpike(position, height, tilt)
	local spike = makePart(
		"HellSpike",
		Vector3.new(5, height, 5),
		CFrame.new(position) * CFrame.Angles(math.rad(tilt or 0), 0, math.rad(7)),
		Color3.fromRGB(27, 23, 24),
		Enum.Material.Basalt
	)
	spike.Shape = Enum.PartType.Block
	return spike
end

local function makeDeadTree(position, scale)
	local model = Instance.new("Model")
	model.Name = "DeadTree"
	model.Parent = world

	local trunk = makePart(
		"Trunk",
		Vector3.new(3 * scale, 20 * scale, 3 * scale),
		CFrame.new(position + Vector3.new(0, 10 * scale, 0)) * CFrame.Angles(0, 0, math.rad(6)),
		Color3.fromRGB(38, 28, 24),
		Enum.Material.Wood,
		model
	)

	local branchA = makePart(
		"Branch",
		Vector3.new(2 * scale, 12 * scale, 2 * scale),
		trunk.CFrame * CFrame.new(0, 5 * scale, 0) * CFrame.Angles(0, 0, math.rad(52)),
		Color3.fromRGB(38, 28, 24),
		Enum.Material.Wood,
		model
	)

	local branchB = makePart(
		"Branch",
		Vector3.new(2 * scale, 10 * scale, 2 * scale),
		trunk.CFrame * CFrame.new(0, 3 * scale, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-48)),
		Color3.fromRGB(38, 28, 24),
		Enum.Material.Wood,
		model
	)

	trunk.CanCollide = true
	branchA.CanCollide = false
	branchB.CanCollide = false
end

local function playerFromHit(hit)
	if not hit or not hit.Parent then
		return nil, nil
	end

	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid and character.Parent then
		character = character.Parent
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end
	if not humanoid then
		return nil, nil
	end

	return Players:GetPlayerFromCharacter(character), humanoid
end

local function makeCheckpoint(info)
	local marker = makePart(
		"Checkpoint_" .. info.name:gsub("%s+", "_"),
		Vector3.new(30, 1, 16),
		CFrame.new(info.position - Vector3.new(0, 3.5, 0)),
		Color3.fromRGB(115, 27, 20),
		Enum.Material.Neon
	)
	marker.Transparency = 0.38
	marker.CanCollide = false

	local cooldown = {}
	marker.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player or cooldown[player] then
			return
		end

		cooldown[player] = true
		checkpoints[player.UserId] = CFrame.new(info.position)
		event:FireClient(player, "checkpoint", info.name)

		task.delay(1.5, function()
			cooldown[player] = nil
		end)
	end)
end

local function buildWorld()
	setLighting()

	local lava = makePart(
		"LakeOfAsh",
		Vector3.new(700, 5, 780),
		CFrame.new(0, -20, -70),
		Color3.fromRGB(130, 30, 8),
		Enum.Material.Neon
	)
	lava.Touched:Connect(function(hit)
		local _, humanoid = playerFromHit(hit)
		if humanoid then
			humanoid.Health = 0
		end
	end)

	makeRockPlatform("AshShore", Vector3.new(180, 8, 125), Vector3.new(0, 0, 150))
	makeRockPlatform("BoneField", Vector3.new(190, 8, 125), Vector3.new(0, 0, -48))
	makeRockPlatform("ExecutionCauseway", Vector3.new(48, 8, 145), Vector3.new(0, 0, -180))
	makeRockPlatform("GatePlaza", Vector3.new(180, 8, 115), Vector3.new(0, 0, -305))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SoulSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(Config.SpawnPosition - Vector3.new(0, 3.5, 0))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Material = Enum.Material.Basalt
	spawn.Color = Color3.fromRGB(66, 49, 46)
	spawn.Parent = world

	local bridgeFolder = Instance.new("Folder")
	bridgeFolder.Name = "AshBridge"
	bridgeFolder.Parent = world

	for i = 1, 7 do
		local xOffset = (i % 2 == 0) and 7 or -7
		local z = 88 - ((i - 1) * 15)
		local slab = makePart(
			"BrokenSlab_" .. i,
			Vector3.new(26, 3, 12),
			CFrame.new(xOffset, 0.5 + ((i % 3) * 0.6), z) * CFrame.Angles(
				math.rad((i % 2 == 0) and 2 or -2),
				math.rad((i - 4) * 2),
				math.rad((i % 2 == 0) and 2 or -2)
			),
			Color3.fromRGB(52, 42, 38),
			Enum.Material.Slate,
			bridgeFolder
		)
		slab.CanCollide = true
	end

	for x = -70, 70, 35 do
		if math.abs(x) > 20 then
			makeSpike(Vector3.new(x, 10, 135 + math.random(-28, 28)), math.random(22, 42), math.random(-12, 12))
			makeSpike(Vector3.new(x, 8, -45 + math.random(-40, 40)), math.random(18, 36), math.random(-12, 12))
		end
	end

	makeDeadTree(Vector3.new(-62, 4, 178), 1.2)
	makeDeadTree(Vector3.new(56, 4, 122), 0.95)
	makeDeadTree(Vector3.new(-72, 4, -28), 1.1)
	makeDeadTree(Vector3.new(68, 4, -74), 0.85)

	for i = 1, 8 do
		local side = (i % 2 == 0) and 1 or -1
		local skullMarker = makePart(
			"BoneMarker_" .. i,
			Vector3.new(3, 8 + (i % 3) * 3, 3),
			CFrame.new(side * (28 + (i % 3) * 12), 6, -15 - i * 10)
				* CFrame.Angles(math.rad(12), 0, math.rad(side * 10)),
			Color3.fromRGB(170, 154, 125),
			Enum.Material.Limestone
		)
		skullMarker.CanCollide = false
	end

	for _, checkpoint in ipairs(Config.Checkpoints) do
		makeCheckpoint(checkpoint)
	end

	local gate = Instance.new("Model")
	gate.Name = "BlackGate"
	gate.Parent = world

	local pillarColor = Color3.fromRGB(18, 16, 18)
	makePart(
		"LeftPillar",
		Vector3.new(18, 72, 22),
		CFrame.new(-34, 36, -350),
		pillarColor,
		Enum.Material.Basalt,
		gate
	)
	makePart(
		"RightPillar",
		Vector3.new(18, 72, 22),
		CFrame.new(34, 36, -350),
		pillarColor,
		Enum.Material.Basalt,
		gate
	)
	makePart(
		"GateCrown",
		Vector3.new(86, 18, 24),
		CFrame.new(0, 67, -350),
		pillarColor,
		Enum.Material.Basalt,
		gate
	)

	local veil = makePart(
		"ExitVeil",
		Vector3.new(48, 56, 3),
		CFrame.new(0, 29, -350),
		Color3.fromRGB(160, 34, 18),
		Enum.Material.Neon,
		gate
	)
	veil.Transparency = 0.58
	veil.CanCollide = false

	for _, x in ipairs({-24, 24}) do
		local brazier = makePart(
			"GateFlame",
			Vector3.new(4, 4, 4),
			CFrame.new(x, 9, -337),
			Color3.fromRGB(255, 87, 20),
			Enum.Material.Neon,
			gate
		)
		brazier.CanCollide = false

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 86, 32)
		light.Brightness = 3
		light.Range = 28
		light.Shadows = true
		light.Parent = brazier
	end

	local exitCooldown = {}
	veil.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player or exitCooldown[player] then
			return
		end

		exitCooldown[player] = true
		player:SetAttribute("LayerOneEscaped", true)
		event:FireClient(player, "escaped", Config.LayerTitle)

		task.delay(3, function()
			exitCooldown[player] = nil
		end)
	end)

	local signAnchor = makePart(
		"GateLabelAnchor",
		Vector3.new(1, 1, 1),
		CFrame.new(0, 78, -350),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic,
		gate
	)
	signAnchor.Transparency = 1
	signAnchor.CanCollide = false

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(420, 90)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 500
	billboard.Parent = signAnchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "THE BLACK GATE"
	label.TextColor3 = Color3.fromRGB(190, 163, 146)
	label.TextStrokeTransparency = 0.45
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
end

local function moveCharacterToCheckpoint(player, character)
	local target = checkpoints[player.UserId] or CFrame.new(Config.SpawnPosition)
	local root = character:WaitForChild("HumanoidRootPart", 8)
	if root then
		task.wait(0.15)
		character:PivotTo(target + Vector3.new(0, 3, 0))
	end
end

buildWorld()

Players.PlayerAdded:Connect(function(player)
	checkpoints[player.UserId] = CFrame.new(Config.SpawnPosition)

	player.CharacterAdded:Connect(function(character)
		moveCharacterToCheckpoint(player, character)
	end)

	if player.Character then
		task.spawn(moveCharacterToCheckpoint, player, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	checkpoints[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	checkpoints[player.UserId] = CFrame.new(Config.SpawnPosition)

	player.CharacterAdded:Connect(function(character)
		moveCharacterToCheckpoint(player, character)
	end)

	if player.Character then
		task.spawn(moveCharacterToCheckpoint, player, player.Character)
	end
end
