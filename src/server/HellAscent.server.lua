local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")

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
local runStates = {}
local wardenModel = nil
local wardenHome = Config.Warden.SpawnPosition
local wardenAttackTimes = {}
local setupPlayers = {}

local function serverNow()
	return workspace:GetServerTimeNow()
end

local function resetWardenHomeIfSafe(exceptPlayer)
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= exceptPlayer then
			local otherState = runStates[otherPlayer.UserId]
			if otherState
				and otherState.started
				and not otherState.expired
				and not otherState.escaped
				and otherState.sealCount > 0
			then
				return
			end
		end
	end

	if not wardenModel or not wardenModel.Parent or not wardenModel.PrimaryPart then
		return
	end

	wardenModel:PivotTo(CFrame.new(wardenHome))
	local root = wardenModel.PrimaryPart
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	local humanoid = wardenModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid:MoveTo(root.Position)
	end
end

local function beginRun(player)
	local state = {
		deadline = nil,
		started = false,
		seals = {},
		sealCount = 0,
		deaths = 0,
		checkpointIndex = 0,
		escaped = false,
		expired = false,
		wardenGraceUntil = math.huge,
	}

	runStates[player.UserId] = state
	checkpoints[player.UserId] = CFrame.new(Config.SpawnPosition)
	wardenAttackTimes[player.UserId] = nil

	player:SetAttribute("RunDeadline", nil)
	player:SetAttribute("SealsBroken", 0)
	player:SetAttribute("TotalSeals", #Config.Seals)
	player:SetAttribute("GateOpen", false)
	player:SetAttribute("RunExpired", false)
	player:SetAttribute("LayerOneEscaped", false)
	player:SetAttribute("DeathsThisRun", 0)

	resetWardenHomeIfSafe(player)

	event:FireClient(player, "runStart", {
		duration = Config.RunDurationSeconds,
	})
end

local function startRunClock(player)
	local state = runStates[player.UserId]
	if not state or state.started or state.expired or state.escaped then
		return
	end

	local now = serverNow()
	state.started = true
	state.deadline = now + Config.RunDurationSeconds
	state.wardenGraceUntil = now + Config.RespawnGraceSeconds

	player:SetAttribute("RunDeadline", state.deadline)
	event:FireClient(player, "runClockStarted", {
		deadline = state.deadline,
		duration = Config.RunDurationSeconds,
	})
end

local function breakSoulSeal(player, sealInfo)
	local state = runStates[player.UserId]
	if not state or state.expired or state.escaped then
		return
	end

	if state.seals[sealInfo.id] then
		event:FireClient(player, "sealAlreadyBroken", sealInfo.name)
		return
	end

	state.seals[sealInfo.id] = true
	state.sealCount += 1
	player:SetAttribute("SealsBroken", state.sealCount)

	event:FireClient(player, "sealBroken", {
		id = sealInfo.id,
		name = sealInfo.name,
		count = state.sealCount,
		total = #Config.Seals,
	})

	if state.sealCount == 1 then
		event:FireClient(player, "wardenAwakened")
	elseif state.sealCount == 2 then
		event:FireClient(player, "wardenHunting")
	elseif state.sealCount >= #Config.Seals then
		event:FireClient(player, "wardenUnbound")
	end

	if state.sealCount >= #Config.Seals then
		player:SetAttribute("GateOpen", true)
		event:FireClient(player, "gateOpen")
	end
end

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

local function makeCheckpoint(info, checkpointIndex)
	local marker = makePart(
		"Checkpoint_" .. info.name:gsub("%s+", "_"),
		Vector3.new(30, 1, 16),
		CFrame.new(info.position - Vector3.new(0, 3.5, 0)),
		Color3.fromRGB(115, 27, 20),
		Enum.Material.Neon
	)
	marker.Transparency = 0.38
	marker.CanCollide = false

	local beacon = makePart(
		"SoulAnchorBeacon_" .. info.name:gsub("%s+", "_"),
		Vector3.new(2.4, 11, 2.4),
		CFrame.new(info.position + Vector3.new(0, 4.5, 0)),
		Color3.fromRGB(184, 48, 26),
		Enum.Material.Neon
	)
	beacon.Transparency = 0.28
	beacon.CanCollide = false
	beacon.CanTouch = false

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 91, 52)
	light.Brightness = 2.1
	light.Range = 26
	light.Shadows = false
	light.Parent = beacon

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(170, 42)
	billboard.StudsOffset = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 180
	billboard.Parent = beacon

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(16, 11, 12)
	label.BorderSizePixel = 0
	label.Text = "SOUL ANCHOR"
	label.TextColor3 = Color3.fromRGB(235, 151, 112)
	label.TextStrokeTransparency = 0.65
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	marker.Touched:Connect(function(hit)
		local player, humanoid = playerFromHit(hit)
		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end

		local state = runStates[player.UserId]
		if not state or state.expired or state.escaped then
			return
		end

		if checkpointIndex <= (state.checkpointIndex or 0) then
			return
		end

		state.checkpointIndex = checkpointIndex
		checkpoints[player.UserId] = CFrame.new(info.position)

		humanoid.Health = humanoid.MaxHealth

		event:FireClient(player, "checkpoint", {
			name = info.name,
			index = checkpointIndex,
			total = #Config.Checkpoints,
		})
	end)
end

local function makeSoulSeal(info)
	local model = Instance.new("Model")
	model.Name = "SoulSeal_" .. info.id
	model.Parent = world

	local pedestal = makePart(
		"Pedestal",
		Vector3.new(9, 2.5, 9),
		CFrame.new(info.position),
		Color3.fromRGB(34, 28, 30),
		Enum.Material.Basalt,
		model
	)

	local core = makePart(
		"SealCore",
		Vector3.new(4.8, 4.8, 4.8),
		CFrame.new(info.position + Vector3.new(0, 5, 0)),
		Color3.fromRGB(170, 42, 24),
		Enum.Material.Neon,
		model
	)
	core.Shape = Enum.PartType.Ball
	core.CanCollide = false
	core.CanTouch = false

	local ring = makePart(
		"SealRing",
		Vector3.new(1.2, 9, 9),
		CFrame.new(info.position + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(72, 57, 55),
		Enum.Material.Metal,
		model
	)
	ring.Shape = Enum.PartType.Cylinder
	ring.CanCollide = false
	ring.CanTouch = false

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 76, 35)
	light.Brightness = 3.2
	light.Range = 32
	light.Shadows = true
	light.Parent = core

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BreakSealPrompt"
	prompt.ActionText = "封印を壊す / BREAK"
	prompt.ObjectText = info.name
	prompt.HoldDuration = 0.85
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = core

	prompt.Triggered:Connect(function(player)
		breakSoulSeal(player, info)
	end)

	pedestal.CanCollide = true
end

local function weldToRoot(root, part)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

local function makeWardenBodyPart(model, root, name, size, offset, color, material, transparency, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = root.CFrame * offset
	part.Color = color or Color3.fromRGB(20, 18, 20)
	part.Material = material or Enum.Material.Slate
	part.Transparency = transparency or 0
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = model
	weldToRoot(root, part)
	return part
end

local function createWarden()
	if wardenModel and wardenModel.Parent then
		wardenModel:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "TheWarden"
	model.Parent = world

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.5, 3.4, 2.0)
	root.CFrame = CFrame.new(Config.Warden.SpawnPosition)
	root.Transparency = 1
	root.Anchored = false
	root.CanCollide = true
	root.CanTouch = false
	root.Massless = false
	root.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayName = "THE WARDEN"
	humanoid.MaxHealth = 100000
	humanoid.Health = 100000
	humanoid.RequiresNeck = false
	humanoid.AutoRotate = true
	humanoid.HipHeight = 2.8
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 42
	humanoid.Parent = model

	local black = Color3.fromRGB(18, 17, 19)
	local charcoal = Color3.fromRGB(30, 27, 29)
	local metal = Color3.fromRGB(48, 42, 43)
	local ember = Color3.fromRGB(255, 49, 24)

	-- Lean, oversized executioner silhouette.
	makeWardenBodyPart(model, root, "Torso", Vector3.new(4.4, 5.8, 2.3), CFrame.new(0, 3.2, 0), charcoal, Enum.Material.Slate)
	makeWardenBodyPart(model, root, "ChestPlate", Vector3.new(3.5, 3.0, 0.55), CFrame.new(0, 3.8, -1.25), black, Enum.Material.Metal)
	makeWardenBodyPart(model, root, "Head", Vector3.new(2.7, 3.5, 2.5), CFrame.new(0, 7.8, 0), black, Enum.Material.Basalt)
	makeWardenBodyPart(model, root, "HoodCrown", Vector3.new(1.3, 1.8, 1.3), CFrame.new(0, 10.0, 0) * CFrame.Angles(0, 0, math.rad(45)), black, Enum.Material.Basalt)

	makeWardenBodyPart(model, root, "LeftShoulder", Vector3.new(3.8, 1.25, 3.0), CFrame.new(-3.2, 5.4, 0) * CFrame.Angles(0, 0, math.rad(-12)), black, Enum.Material.Basalt)
	makeWardenBodyPart(model, root, "RightShoulder", Vector3.new(3.8, 1.25, 3.0), CFrame.new(3.2, 5.4, 0) * CFrame.Angles(0, 0, math.rad(12)), black, Enum.Material.Basalt)

	makeWardenBodyPart(model, root, "LeftArm", Vector3.new(1.35, 7.2, 1.45), CFrame.new(-2.8, 0.9, 0) * CFrame.Angles(0, 0, math.rad(-5)), charcoal, Enum.Material.Slate)
	makeWardenBodyPart(model, root, "RightArm", Vector3.new(1.35, 7.2, 1.45), CFrame.new(2.8, 0.9, 0) * CFrame.Angles(0, 0, math.rad(5)), charcoal, Enum.Material.Slate)
	makeWardenBodyPart(model, root, "LeftHand", Vector3.new(1.5, 2.5, 1.3), CFrame.new(-3.0, -3.8, -0.1) * CFrame.Angles(math.rad(-8), 0, math.rad(-8)), black, Enum.Material.Basalt)
	makeWardenBodyPart(model, root, "RightHand", Vector3.new(1.5, 2.5, 1.3), CFrame.new(3.0, -3.8, -0.1) * CFrame.Angles(math.rad(-8), 0, math.rad(8)), black, Enum.Material.Basalt)

	makeWardenBodyPart(model, root, "LeftLeg", Vector3.new(1.65, 6.6, 1.8), CFrame.new(-1.2, -3.3, 0) * CFrame.Angles(0, 0, math.rad(2)), charcoal, Enum.Material.Slate)
	makeWardenBodyPart(model, root, "RightLeg", Vector3.new(1.65, 6.6, 1.8), CFrame.new(1.2, -3.3, 0) * CFrame.Angles(0, 0, math.rad(-2)), charcoal, Enum.Material.Slate)
	makeWardenBodyPart(model, root, "LeftBladeFoot", Vector3.new(1.7, 3.1, 2.0), CFrame.new(-1.2, -7.4, -0.35) * CFrame.Angles(math.rad(-18), 0, math.rad(3)), black, Enum.Material.Basalt)
	makeWardenBodyPart(model, root, "RightBladeFoot", Vector3.new(1.7, 3.1, 2.0), CFrame.new(1.2, -7.4, -0.35) * CFrame.Angles(math.rad(-18), 0, math.rad(-3)), black, Enum.Material.Basalt)

	for index = 1, 4 do
		local x = (index <= 2) and -1.35 or 1.35
		local y = 2.1 - ((index - 1) % 2) * 2.2
		makeWardenBodyPart(
			model,
			root,
			"CloakStrip_" .. index,
			Vector3.new(1.15, 6.4 + index * 0.45, 0.45),
			CFrame.new(x, y - 2.5, 1.15) * CFrame.Angles(math.rad(4), 0, math.rad((index % 2 == 0) and 5 or -5)),
			black,
			Enum.Material.Fabric,
			0.08
		)
	end

	local slit = makeWardenBodyPart(
		model,
		root,
		"FaceSlit",
		Vector3.new(0.28, 2.65, 0.22),
		CFrame.new(0, 7.85, -1.36),
		ember,
		Enum.Material.Neon
	)

	local eyeLight = Instance.new("PointLight")
	eyeLight.Color = ember
	eyeLight.Brightness = 2.6
	eyeLight.Range = 18
	eyeLight.Shadows = true
	eyeLight.Parent = slit

	for chainSide = -1, 1, 2 do
		for index = 1, 5 do
			makeWardenBodyPart(
				model,
				root,
				("Chain_%d_%d"):format(chainSide, index),
				Vector3.new(0.38, 0.38, 0.38),
				CFrame.new(chainSide * (2.4 + index * 0.12), 5.0 - index * 0.85, 1.3),
				metal,
				Enum.Material.Metal,
				0,
				Enum.PartType.Ball
			)
		end
	end

	model.PrimaryPart = root
	root:SetNetworkOwner(nil)
	wardenModel = model
	print("[HELL ASCENT] THE WARDEN spawned")
	return model
end

local function getWardenTarget()
	if not wardenModel or not wardenModel.PrimaryPart then
		return nil, 0
	end

	local origin = wardenModel.PrimaryPart.Position
	local bestPlayer = nil
	local bestStage = 0
	local bestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local state = runStates[player.UserId]
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if state
			and not state.expired
			and not state.escaped
			and state.sealCount > 0
			and serverNow() >= (state.wardenGraceUntil or 0)
			and root
			and humanoid
			and humanoid.Health > 0
		then
			local stage = math.clamp(state.sealCount, 1, 3)
			local stageConfig = Config.Warden.Stages[stage]
			local distance = (root.Position - origin).Magnitude
			if distance <= stageConfig.DetectionRange then
				if distance < bestDistance then
					bestPlayer = player
					bestStage = stage
					bestDistance = distance
				end
			end
		end
	end

	return bestPlayer, bestStage
end

local function moveWardenToward(targetPosition, stage)
	if not wardenModel then
		return
	end

	local root = wardenModel.PrimaryPart
	local humanoid = wardenModel:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	local stageConfig = Config.Warden.Stages[stage] or Config.Warden.Stages[0]
	humanoid.WalkSpeed = stageConfig.WalkSpeed

	local path = PathfindingService:CreatePath({
		AgentRadius = 2.0,
		AgentHeight = 10,
		AgentCanJump = true,
		WaypointSpacing = 5,
	})

	local success = pcall(function()
		path:ComputeAsync(root.Position, targetPosition)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		local waypoint = waypoints[math.min(2, #waypoints)]
		if waypoint then
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			humanoid:MoveTo(waypoint.Position)
			return
		end
	end

	humanoid:MoveTo(targetPosition)
end

local function runWardenAI()
	task.spawn(function()
		while true do
			task.wait(Config.Warden.RepathSeconds)

			if not wardenModel or not wardenModel.Parent then
				continue
			end

			local root = wardenModel.PrimaryPart
			local humanoid = wardenModel:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid then
				continue
			end

			local targetPlayer, stage = getWardenTarget()
			if not targetPlayer then
				humanoid.WalkSpeed = 7
				if (root.Position - wardenHome).Magnitude > 8 then
					moveWardenToward(wardenHome, 1)
				else
					humanoid:MoveTo(root.Position)
					humanoid.WalkSpeed = 0
				end
				continue
			end

			local character = targetPlayer.Character
			local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
			local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
				continue
			end

			moveWardenToward(targetRoot.Position, stage)

			local distance = (targetRoot.Position - root.Position).Magnitude
			if distance <= Config.Warden.AttackRange then
				local now = serverNow()
				local lastAttack = wardenAttackTimes[targetPlayer.UserId] or 0
				if now - lastAttack >= Config.Warden.AttackCooldown then
					wardenAttackTimes[targetPlayer.UserId] = now
					targetHumanoid:TakeDamage(Config.Warden.Damage)
					event:FireClient(targetPlayer, "wardenStrike")
				end
			end
		end
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

local function makeFallbackRockTemplate()
	local model = Instance.new("Model")
	model.Name = "GeneratedHellRock"

	local pieces = {
		{Vector3.new(3.8, 2.2, 3.1), Vector3.new(0, 0.7, 0), Vector3.new(8, 18, 3)},
		{Vector3.new(2.7, 1.8, 2.4), Vector3.new(1.6, 1.2, -0.7), Vector3.new(-12, 31, 8)},
		{Vector3.new(2.2, 1.4, 2.0), Vector3.new(-1.4, 1.0, 0.8), Vector3.new(16, -24, -7)},
	}

	for i, data in ipairs(pieces) do
		local part = Instance.new("Part")
		part.Name = "Rock_" .. i
		part.Size = data[1]
		part.CFrame = CFrame.new(data[2])
			* CFrame.Angles(math.rad(data[3].X), math.rad(data[3].Y), math.rad(data[3].Z))
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Slate
		part.Color = Color3.fromRGB(92, 78, 72)
		part.Parent = model
	end

	return model
end

local function makeFallbackChainTemplate()
	local model = Instance.new("Model")
	model.Name = "GeneratedHellChain"

	for i = 1, 9 do
		local bead = Instance.new("Part")
		bead.Name = "Link_" .. i
		bead.Shape = Enum.PartType.Ball
		bead.Size = Vector3.new(0.48, 0.48, 0.48)
		bead.CFrame = CFrame.new(
			((i % 2 == 0) and 0.16 or -0.16),
			(i - 1) * 0.72,
			0
		)
		bead.Anchored = true
		bead.CanCollide = false
		bead.Material = Enum.Material.Metal
		bead.Color = Color3.fromRGB(60, 52, 50)
		bead.Parent = model
	end

	return model
end

local function makeFallbackTombstoneTemplate()
	local model = Instance.new("Model")
	model.Name = "GeneratedHellTombstone"

	local slab = Instance.new("Part")
	slab.Name = "Stone"
	slab.Size = Vector3.new(3.6, 5.4, 1.2)
	slab.CFrame = CFrame.new(0, 2.7, 0)
	slab.Anchored = true
	slab.CanCollide = false
	slab.Material = Enum.Material.Slate
	slab.Color = Color3.fromRGB(86, 78, 74)
	slab.Parent = model

	local crown = Instance.new("Part")
	crown.Name = "Crown"
	crown.Shape = Enum.PartType.Cylinder
	crown.Size = Vector3.new(1.2, 3.6, 3.6)
	crown.CFrame = CFrame.new(0, 5.35, 0) * CFrame.Angles(0, 0, math.rad(90))
	crown.Anchored = true
	crown.CanCollide = false
	crown.Material = Enum.Material.Slate
	crown.Color = slab.Color
	crown.Parent = model

	return model
end

local function useTemplateOrFallback(templateName, fallbackFactory)
	local template = findLocalTemplate(templateName)
	if template then
		return template, true
	end

	local fallback = fallbackFactory()
	sanitizeLocalTemplate(fallback)
	print("[HELL ASCENT] Generated fallback decoration:", templateName)
	return fallback, false
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
	local skull, skullIsLocal = useTemplateOrFallback("HellSkull", makeFallbackRockTemplate)
	local chain, chainIsLocal = useTemplateOrFallback("HellChain", makeFallbackChainTemplate)
	local tombstone, tombstoneIsLocal = useTemplateOrFallback("HellTombstone", makeFallbackTombstoneTemplate)

	local localTemplateCount = 0
	if deadTree then localTemplateCount += 1 end
	if skullIsLocal then localTemplateCount += 1 end
	if chainIsLocal then localTemplateCount += 1 end
	if tombstoneIsLocal then localTemplateCount += 1 end

	local treePlacements = {
		{Vector3.new(-78, 4, 166), 18, -18},
		{Vector3.new(80, 4, 118), 17, 22},
		{Vector3.new(-82, 4, -46), 18, 12},
		{Vector3.new(82, 4, -92), 16, -28},
		{Vector3.new(-58, 4, -276), 15, 8},
		{Vector3.new(60, 4, -300), 16, -14},
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
		Vector3.new(-66, 4, -32),
		Vector3.new(-48, 4, -58),
		Vector3.new(-70, 4, -84),
		Vector3.new(66, 4, -34),
		Vector3.new(50, 4, -60),
		Vector3.new(72, 4, -86),
	}

	for index, position in ipairs(gravePlacements) do
		placeLocalClone(
			tombstone,
			"HellTombstone_" .. index,
			5.4,
			CFrame.new(position) * CFrame.Angles(0, math.rad((index * 31) % 70 - 35), 0),
			Color3.fromRGB(91, 83, 78),
			decoration,
			true
		)

		placeLocalClone(
			skull,
			"HellSkull_" .. index,
			2.2,
			CFrame.new(position + Vector3.new((index % 2 == 0) and 4 or -4, 0, 3))
				* CFrame.Angles(0, math.rad(index * 41), math.rad((index % 2 == 0) and 12 or -9)),
			Color3.fromRGB(183, 166, 134),
			decoration,
			true
		)
	end

	local chainPlacements = {
		CFrame.new(-27, 14, -166),
		CFrame.new(27, 16, -188),
		CFrame.new(-27, 15, -210),
		CFrame.new(27, 17, -232),
	}

	for index, cframe in ipairs(chainPlacements) do
		placeLocalClone(
			chain,
			"HellChain_" .. index,
			7.5,
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
		"[HELL ASCENT] Decoration pass finished:",
		localTemplateCount,
		"/ 4 local templates used; generated fallbacks filled the rest"
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
		local player, humanoid = playerFromHit(hit)
		if player and humanoid then
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

	makeDeadTree(Vector3.new(-68, 4, 178), 0.95)
	makeDeadTree(Vector3.new(70, 4, 126), 0.8)
	makeDeadTree(Vector3.new(-74, 4, -24), 0.9)
	makeDeadTree(Vector3.new(74, 4, -78), 0.72)
	makeDeadTree(Vector3.new(-42, 4, -268), 0.62)
	makeDeadTree(Vector3.new(45, 4, -286), 0.66)

	for i = 1, 8 do
		local side = (i % 2 == 0) and 1 or -1
		local skullMarker = makePart(
			"BoneMarker_" .. i,
			Vector3.new(1.6, 6 + (i % 3) * 2, 1.6),
			CFrame.new(side * (46 + (i % 3) * 10), 5, -15 - i * 10)
				* CFrame.Angles(math.rad(12), 0, math.rad(side * 10)),
			Color3.fromRGB(170, 154, 125),
			Enum.Material.Limestone
		)
		skullMarker.CanCollide = false
	end

	for checkpointIndex, checkpoint in ipairs(Config.Checkpoints) do
		makeCheckpoint(checkpoint, checkpointIndex)
	end

	for _, sealInfo in ipairs(Config.Seals) do
		makeSoulSeal(sealInfo)
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

	veil.CanCollide = false

	local exitCooldown = {}
	veil.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player or exitCooldown[player] then
			return
		end

		local state = runStates[player.UserId]
		if not state or state.expired or state.escaped then
			return
		end

		exitCooldown[player] = true

		if state.sealCount < #Config.Seals then
			event:FireClient(player, "gateLocked", {
				count = state.sealCount,
				total = #Config.Seals,
			})

			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if character and root then
				root.AssemblyLinearVelocity = Vector3.zero
				character:PivotTo(
					CFrame.lookAt(
						Config.GateRepelPosition,
						Vector3.new(0, Config.GateRepelPosition.Y, Config.ExitPosition.Z)
					)
				)
			end

			task.delay(1.2, function()
				exitCooldown[player] = nil
			end)
			return
		end

		state.escaped = true
		player:SetAttribute("LayerOneEscaped", true)
		event:FireClient(player, "escaped", {
			layer = Config.LayerTitle,
			remaining = state.deadline and math.max(0, math.ceil(state.deadline - serverNow())) or 0,
			deaths = state.deaths,
		})

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
	billboard.Size = UDim2.fromOffset(300, 64)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 360
	billboard.Parent = signAnchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BLACK GATE"
	label.TextColor3 = Color3.fromRGB(190, 163, 146)
	label.TextStrokeTransparency = 0.45
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard

	for _, z in ipairs({145, 62, -35, -142, -238, -322}) do
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

	createWarden()
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

local function bindCharacter(player, character)
	moveCharacterToCheckpoint(player, character)

	local humanoid = character:WaitForChild("Humanoid", 8)
	if not humanoid then
		return
	end

	startRunClock(player)

	local boundState = runStates[player.UserId]
	if boundState then
		boundState.wardenGraceUntil = serverNow() + Config.RespawnGraceSeconds
	end

	humanoid.Died:Connect(function()
		if runStates[player.UserId] ~= boundState then
			return
		end

		if not boundState or boundState.expired or boundState.escaped then
			return
		end

		boundState.deaths += 1
		if boundState.deadline then
			boundState.deadline -= Config.DeathPenaltySeconds
		end
		player:SetAttribute("DeathsThisRun", boundState.deaths)
		player:SetAttribute("RunDeadline", boundState.deadline)

		event:FireClient(player, "deathPenalty", {
			seconds = Config.DeathPenaltySeconds,
			deaths = boundState.deaths,
		})
	end)
end

local function setupPlayer(player)
	if setupPlayers[player] then
		return
	end
	setupPlayers[player] = true

	beginRun(player)

	player.CharacterAdded:Connect(function(character)
		bindCharacter(player, character)
	end)

	if player.Character then
		bindCharacter(player, player.Character)
	end
end

buildWorld()
runWardenAI()

event.OnServerEvent:Connect(function(player, kind)
	if kind ~= "restartRun" then
		return
	end

	local state = runStates[player.UserId]
	if not state or not state.escaped then
		return
	end

	beginRun(player)
	player:LoadCharacter()
end)

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	checkpoints[player.UserId] = nil
	runStates[player.UserId] = nil
	wardenAttackTimes[player.UserId] = nil
	setupPlayers[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

task.spawn(function()
	while true do
		task.wait(0.5)
		local now = serverNow()

		for _, player in ipairs(Players:GetPlayers()) do
			local state = runStates[player.UserId]
			if state
				and state.started
				and state.deadline
				and not state.expired
				and not state.escaped
				and now >= state.deadline
			then
				state.expired = true
				player:SetAttribute("RunExpired", true)
				event:FireClient(player, "expired")

				task.delay(3.5, function()
					if not player.Parent then
						return
					end

					beginRun(player)
					player:LoadCharacter()
				end)
			end
		end
	end
end)
