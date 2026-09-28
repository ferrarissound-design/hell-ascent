local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
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
	-- Keep Layer One oppressive, but never so dark that the player loses the route.
	Lighting.Brightness = 2.4
	Lighting.ClockTime = 18.2
	Lighting.Ambient = Color3.fromRGB(92, 38, 34)
	Lighting.OutdoorAmbient = Color3.fromRGB(112, 48, 40)
	Lighting.FogColor = Color3.fromRGB(110, 37, 27)
	Lighting.FogStart = 90
	Lighting.FogEnd = 620
	Lighting.EnvironmentDiffuseScale = 0.7
	Lighting.EnvironmentSpecularScale = 0.25

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.28
	atmosphere.Offset = 0
	atmosphere.Color = Color3.fromRGB(156, 83, 62)
	atmosphere.Decay = Color3.fromRGB(70, 18, 12)
	atmosphere.Glare = 0.08
	atmosphere.Haze = 1.35

	local correction = Lighting:FindFirstChild("HellColor")
	if not correction then
		correction = Instance.new("ColorCorrectionEffect")
		correction.Name = "HellColor"
		correction.Parent = Lighting
	end
	correction.Brightness = 0.04
	correction.Contrast = 0.12
	correction.Saturation = -0.12
	correction.TintColor = Color3.fromRGB(255, 205, 185)
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

local TEMPLATE_FOLDER_NAME = "HellAscentAssets"

local function sanitizeLocalTemplate(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		elseif descendant:IsA("ProximityPrompt")
			or descendant:IsA("ClickDetector")
			or descendant:IsA("TouchTransmitter")
		then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CastShadow = true
		end
	end

	if root:IsA("BasePart") then
		root.Anchored = true
		root.CanCollide = false
		root.CanTouch = false
		root.CastShadow = true
	end
end

local function asModel(instance)
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		return instance
	end

	local model = Instance.new("Model")
	model.Name = instance.Name
	instance:Clone().Parent = model
	return model
end

local function findLocalTemplate(templateName)
	local roots = {
		ServerStorage:FindFirstChild(TEMPLATE_FOLDER_NAME),
		workspace:FindFirstChild(TEMPLATE_FOLDER_NAME),
		ServerStorage,
		workspace,
	}

	for _, root in ipairs(roots) do
		if root then
			local found = root:FindFirstChild(templateName)
			if found then
				local model = asModel(found)
				if model ~= found then
					model.Name = templateName
				end
				sanitizeLocalTemplate(model)
				print("[HELL ASCENT] Local template found:", templateName)
				return model
			end
		end
	end

	warn(
		"[HELL ASCENT] Missing local template:",
		templateName,
		"- add it to ServerStorage/" .. TEMPLATE_FOLDER_NAME
	)
	return nil
end

local function tintModel(model, color)
	if not color then
		return
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Color = color
		end
	end
end

local function placeLocalClone(template, name, targetHeight, cframe, color, parent, grounded)
	if not template then
		return nil
	end

	local clone = template:Clone()
	clone.Name = name
	clone.Parent = parent or world
	sanitizeLocalTemplate(clone)

	local _, initialSize = clone:GetBoundingBox()
	if initialSize.Y > 0.01 then
		local scaleFactor = targetHeight / initialSize.Y
		local scaled = pcall(function()
			clone:ScaleTo(clone:GetScale() * scaleFactor)
		end)

		if not scaled then
			warn("[HELL ASCENT] Could not scale local template:", name)
		end
	end

	tintModel(clone, color)
	clone:PivotTo(cframe)

	if grounded then
		local boxCFrame, boxSize = clone:GetBoundingBox()
		local bottomY = boxCFrame.Position.Y - (boxSize.Y * 0.5)
		local deltaY = cframe.Position.Y - bottomY
		clone:PivotTo(clone:GetPivot() + Vector3.new(0, deltaY, 0))
	end

	return clone
end

local function decorateWithLocalTemplates()
	local decoration = Instance.new("Folder")
	decoration.Name = "LocalAssetDecoration"
	decoration.Parent = world

	local deadTree = findLocalTemplate("HellTree")
	local skull = findLocalTemplate("HellSkull")
	local chain = findLocalTemplate("HellChain")
	local tombstone = findLocalTemplate("HellTombstone")

	local loadedCount = 0
	for _, template in ipairs({deadTree, skull, chain, tombstone}) do
		if template then
			loadedCount += 1
		end
	end

	local treePlacements = {
		{Vector3.new(-72, 4, 164), 24, -18},
		{Vector3.new(74, 4, 118), 21, 22},
		{Vector3.new(-78, 4, -48), 23, 12},
		{Vector3.new(72, 4, -92), 20, -28},
		{Vector3.new(-45, 4, -278), 19, 8},
		{Vector3.new(52, 4, -300), 22, -14},
	}

	for index, data in ipairs(treePlacements) do
		placeLocalClone(
			deadTree,
			"HellTree_" .. index,
			data[2],
			CFrame.new(data[1]) * CFrame.Angles(0, math.rad(data[3]), 0),
			Color3.fromRGB(58, 46, 42),
			decoration,
			true
		)
	end

	local gravePlacements = {
		Vector3.new(-52, 4, -38),
		Vector3.new(-35, 4, -58),
		Vector3.new(-58, 4, -78),
		Vector3.new(40, 4, -36),
		Vector3.new(58, 4, -60),
		Vector3.new(36, 4, -83),
	}

	for index, position in ipairs(gravePlacements) do
		placeLocalClone(
			tombstone,
			"HellTombstone_" .. index,
			9,
			CFrame.new(position) * CFrame.Angles(0, math.rad((index * 31) % 70 - 35), 0),
			Color3.fromRGB(91, 83, 78),
			decoration,
			true
		)

		placeLocalClone(
			skull,
			"HellSkull_" .. index,
			2.8,
			CFrame.new(position + Vector3.new((index % 2 == 0) and 4 or -4, 0, 3))
				* CFrame.Angles(0, math.rad(index * 41), math.rad((index % 2 == 0) and 12 or -9)),
			Color3.fromRGB(183, 166, 134),
			decoration,
			true
		)
	end

	local chainPlacements = {
		CFrame.new(-18, 24, -168) * CFrame.Angles(0, 0, math.rad(90)),
		CFrame.new(18, 28, -187) * CFrame.Angles(0, 0, math.rad(90)),
		CFrame.new(-18, 26, -208) * CFrame.Angles(0, 0, math.rad(90)),
		CFrame.new(18, 30, -229) * CFrame.Angles(0, 0, math.rad(90)),
	}

	for index, cframe in ipairs(chainPlacements) do
		placeLocalClone(
			chain,
			"HellChain_" .. index,
			24,
			cframe,
			Color3.fromRGB(70, 60, 56),
			decoration,
			false
		)
	end

	if deadTree and deadTree.Parent == nil then deadTree:Destroy() end
	if skull and skull.Parent == nil then skull:Destroy() end
	if chain and chain.Parent == nil then chain:Destroy() end
	if tombstone and tombstone.Parent == nil then tombstone:Destroy() end

	print(
		"[HELL ASCENT] Local asset decoration pass finished:",
		loadedCount,
		"/ 4 template types found"
	)
end

local function buildWorld()
	setLighting()

	local emberSun = makePart(
		"EmberSun",
		Vector3.new(34, 34, 34),
		CFrame.new(150, 165, -130),
		Color3.fromRGB(255, 84, 28),
		Enum.Material.Neon
	)
	emberSun.Shape = Enum.PartType.Ball
	emberSun.CanCollide = false

	local emberLight = Instance.new("PointLight")
	emberLight.Color = Color3.fromRGB(255, 103, 54)
	emberLight.Brightness = 5
	emberLight.Range = 260
	emberLight.Shadows = true
	emberLight.Parent = emberSun

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

	for _, z in ipairs({145, 50, -45, -145, -245, -325}) do
		local guide = makePart(
			"RouteEmber",
			Vector3.new(3, 3, 3),
			CFrame.new(0, 10, z),
			Color3.fromRGB(255, 72, 24),
			Enum.Material.Neon
		)
		guide.Shape = Enum.PartType.Ball
		guide.CanCollide = false

		local guideLight = Instance.new("PointLight")
		guideLight.Color = Color3.fromRGB(255, 94, 43)
		guideLight.Brightness = 2.6
		guideLight.Range = 38
		guideLight.Parent = guide
	end

	print("[HELL ASCENT] Layer One world generated successfully")
	task.spawn(decorateWithLocalTemplates)
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
