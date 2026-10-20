-- Optional-route content for Layer One: Soul Embers (time pickups) and Ember Vents (rhythm hazards).
-- HellAscent.server.lua owns run state; this module only borrows it through the ctx table.

local Players = game:GetService("Players")

local WorldExtras = {}

local EMBER_COLOR = Color3.fromRGB(150, 205, 255)
local EMBER_LIGHT_COLOR = Color3.fromRGB(110, 170, 255)
local VENT_IDLE_COLOR = Color3.fromRGB(70, 18, 12)
local VENT_WARN_COLOR = Color3.fromRGB(255, 120, 40)
local VENT_BLAST_COLOR = Color3.fromRGB(255, 70, 22)

local ctx = nil
local vents = {}

local function totalEmbers()
	return #ctx.Config.SoulEmbers.Positions
end

local function playSoundOn(part, soundId, volume)
	if not soundId or soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.8
	sound.RollOffMaxDistance = 140
	sound.Parent = part
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(8, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function WorldExtras.resetEmbers(player, state)
	state.embers = {}
	state.emberCount = 0
	player:SetAttribute("EmberCount", 0)
	player:SetAttribute("TotalEmbers", totalEmbers())
	player:SetAttribute("EmberMask", string.rep("0", totalEmbers()))
end

local function collectEmber(player, state, index)
	state.embers[index] = true
	state.emberCount += 1

	local bonus = state.difficulty.EmberBonusSeconds or 0
	if state.deadline then
		state.deadline += bonus
		player:SetAttribute("RunDeadline", state.deadline)
	end

	local mask = table.create(totalEmbers(), "0")
	for emberIndex in pairs(state.embers) do
		mask[emberIndex] = "1"
	end
	player:SetAttribute("EmberCount", state.emberCount)
	player:SetAttribute("EmberMask", table.concat(mask))

	ctx.event:FireClient(player, "emberCollected", {
		index = index,
		count = state.emberCount,
		total = totalEmbers(),
		bonus = bonus,
	})
end

local function makeEmber(folder, index, position)
	local ember = ctx.makePart(
		"SoulEmber_" .. index,
		Vector3.new(2.4, 2.4, 2.4),
		CFrame.new(position),
		EMBER_COLOR,
		Enum.Material.Neon,
		folder
	)
	ember.Shape = Enum.PartType.Ball
	ember.CanCollide = false
	ember.CanQuery = false
	ember.Transparency = 0.1

	local light = Instance.new("PointLight")
	light.Color = EMBER_LIGHT_COLOR
	light.Brightness = 2.4
	light.Range = 20
	light.Shadows = false
	light.Parent = ember

	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(EMBER_COLOR)
	sparks.LightEmission = 1
	sparks.Rate = 6
	sparks.Lifetime = NumberRange.new(1.2, 2.0)
	sparks.Speed = NumberRange.new(0.5, 1.5)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Parent = ember

	ember.Touched:Connect(function(hit)
		local player, humanoid = ctx.playerFromHit(hit)
		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end
		if player.Character ~= humanoid.Parent then
			return
		end

		local state = ctx.runStates[player.UserId]
		if not ctx.ensureRunStillActive(player, state) then
			return
		end
		if state.embers[index] then
			return
		end

		collectEmber(player, state, index)
	end)

	return ember
end

local function makeVent(folder, index, position)
	local config = ctx.Config.Vents
	local radius = config.Radius
	local model = Instance.new("Model")
	model.Name = "EmberVent_" .. index
	model.Parent = folder

	local glow = ctx.makePart(
		"VentGlow",
		Vector3.new(0.4, radius * 2, radius * 2),
		CFrame.new(position + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		VENT_IDLE_COLOR,
		Enum.Material.Neon,
		model
	)
	glow.Shape = Enum.PartType.Cylinder
	glow.Transparency = 0.82
	glow.CanCollide = false
	glow.CanTouch = false
	glow.CanQuery = false

	local column = ctx.makePart(
		"VentColumn",
		Vector3.new(24, radius * 1.5, radius * 1.5),
		CFrame.new(position + Vector3.new(0, 12, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		VENT_BLAST_COLOR,
		Enum.Material.Neon,
		model
	)
	column.Shape = Enum.PartType.Cylinder
	column.Transparency = 1
	column.CanCollide = false
	column.CanTouch = false
	column.CanQuery = false

	local light = Instance.new("PointLight")
	light.Color = VENT_WARN_COLOR
	light.Brightness = 0
	light.Range = 26
	light.Shadows = false
	light.Parent = glow

	local flames = Instance.new("ParticleEmitter")
	flames.Color = ColorSequence.new(VENT_WARN_COLOR, VENT_BLAST_COLOR)
	flames.LightEmission = 1
	flames.Rate = 90
	flames.Enabled = false
	flames.Lifetime = NumberRange.new(0.5, 0.9)
	flames.Speed = NumberRange.new(18, 30)
	flames.SpreadAngle = Vector2.new(12, 12)
	flames.EmissionDirection = Enum.NormalId.Right
	flames.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.4),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	flames.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	flames.Parent = glow

	-- Deterministic stagger so neighbouring vents never erupt together.
	local vent = {
		position = position,
		glow = glow,
		column = column,
		light = light,
		flames = flames,
		offset = (index * 1.7) % config.Period,
		state = "idle",
		hit = {},
	}
	vents[index] = vent
	return vent
end

local function setVentState(vent, newState)
	local audio = ctx.Config.Audio
	vent.state = newState

	if newState == "warn" then
		vent.glow.Color = VENT_WARN_COLOR
		vent.glow.Transparency = 0.35
		vent.light.Brightness = 2
		playSoundOn(vent.glow, audio.VentWarn, 0.6)
	elseif newState == "active" then
		vent.glow.Color = VENT_BLAST_COLOR
		vent.glow.Transparency = 0.1
		vent.column.Transparency = 0.25
		vent.light.Brightness = 6
		vent.flames.Enabled = true
		playSoundOn(vent.glow, audio.VentBlast, 1)
	else
		vent.hit = {}
		vent.glow.Color = VENT_IDLE_COLOR
		vent.glow.Transparency = 0.82
		vent.column.Transparency = 1
		vent.light.Brightness = 0
		vent.flames.Enabled = false
	end
end

local function blastNearbyPlayers(vent, now)
	local config = ctx.Config.Vents

	for _, player in ipairs(Players:GetPlayers()) do
		if not vent.hit[player] then
			local state = ctx.runStates[player.UserId]
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if state
				and root
				and humanoid
				and humanoid.Health > 0
				and state.started
				and not state.expired
				and not state.escaped
				and now >= (state.wardenGraceUntil or 0)
			then
				local dx = root.Position.X - vent.position.X
				local dz = root.Position.Z - vent.position.Z
				local dy = root.Position.Y - vent.position.Y
				if dx * dx + dz * dz <= config.Radius * config.Radius and dy > -3 and dy < 16 then
					vent.hit[player] = true
					root.AssemblyLinearVelocity = Vector3.new(0, 30, 0)
					humanoid:TakeDamage(config.Damage)
					ctx.event:FireClient(player, "ventStrike", {damage = config.Damage})
				end
			end
		end
	end
end

local function runVents()
	local config = ctx.Config.Vents
	local activeStart = config.Period - config.ActiveSeconds
	local warnStart = activeStart - config.WarnSeconds

	task.spawn(function()
		while true do
			task.wait(0.1)
			local now = ctx.serverNow()

			for _, vent in ipairs(vents) do
				local phase = (now + vent.offset) % config.Period
				local wanted = "idle"
				if phase >= activeStart then
					wanted = "active"
				elseif phase >= warnStart then
					wanted = "warn"
				end

				if wanted ~= vent.state then
					setVentState(vent, wanted)
				end

				if wanted == "warn" then
					-- Flicker faster as the blast approaches.
					local urgency = (phase - warnStart) / config.WarnSeconds
					local blink = math.floor(now * (4 + urgency * 8)) % 2 == 0
					vent.glow.Transparency = blink and 0.3 or 0.6
				elseif wanted == "active" then
					blastNearbyPlayers(vent, now)
				end
			end
		end
	end)
end

-- ctx: Config, world, event, runStates, serverNow, ensureRunStillActive, playerFromHit, makePart
function WorldExtras.build(context)
	ctx = context
	vents = {}

	local emberFolder = Instance.new("Folder")
	emberFolder.Name = "SoulEmbers"
	emberFolder.Parent = ctx.world
	for index, position in ipairs(ctx.Config.SoulEmbers.Positions) do
		makeEmber(emberFolder, index, position)
	end

	local ventFolder = Instance.new("Folder")
	ventFolder.Name = "EmberVents"
	ventFolder.Parent = ctx.world
	for index, position in ipairs(ctx.Config.Vents.Positions) do
		makeVent(ventFolder, index, position)
	end

	runVents()
	print(string.format(
		"[HELL ASCENT] Extras generated: %d soul embers, %d ember vents",
		#ctx.Config.SoulEmbers.Positions,
		#ctx.Config.Vents.Positions
	))
end

return WorldExtras
