local Config = {}

Config.GameTitle = "HELL ASCENT"
Config.LayerTitle = "LAYER ONE: ASHEN VERGE"
Config.Objective = "Break 3 Soul Seals, then reach the Black Gate."
Config.Version = "1.0.0"

Config.SpawnPosition = Vector3.new(0, 8, 170)
Config.ExitPosition = Vector3.new(0, 8, -350)

Config.RespawnGraceSeconds = 6

-- NIGHTMARE unlocks after the first escape (persisted when DataStore is available).
Config.DefaultDifficulty = "NORMAL"
Config.Difficulties = {
	NORMAL = {
		id = "NORMAL",
		label = "NORMAL",
		DurationSeconds = 600,
		DeathPenaltySeconds = 20,
		WardenSpeedScale = 1,
		WardenDamageScale = 1,
		AnchorHealFraction = 1,
		EmberBonusSeconds = 8,
	},
	NIGHTMARE = {
		id = "NIGHTMARE",
		label = "NIGHTMARE",
		DurationSeconds = 480,
		DeathPenaltySeconds = 30,
		WardenSpeedScale = 1.12,
		WardenDamageScale = 1.32,
		AnchorHealFraction = 0.5,
		EmberBonusSeconds = 6,
		requiresUnlock = true,
	},
}

-- Legacy aliases for NORMAL (docs and older code refer to these names).
Config.RunDurationSeconds = Config.Difficulties.NORMAL.DurationSeconds
Config.DeathPenaltySeconds = Config.Difficulties.NORMAL.DeathPenaltySeconds

-- Grade = first rank whose limits are met. Ratio = effective clear time / run duration.
-- Effective time = elapsed + death penalties - ember bonuses (the same number the HUD timer shows).
-- Rough estimate for NORMAL (600s): S <= 1:48, A <= 3:00, B <= 5:00. Tune after real playtests.
Config.Ranks = {
	{id = "S", MaxRatio = 0.18, MaxDeaths = 0},
	{id = "A", MaxRatio = 0.30, MaxDeaths = 1},
	{id = "B", MaxRatio = 0.50, MaxDeaths = 99},
	{id = "C", MaxRatio = 1.00, MaxDeaths = 99},
}
Config.GateRepelPosition = Vector3.new(0, 8, -322)

Config.AshRift = {
	Position = Vector3.new(62, 8, -88),
	Destination = Vector3.new(0, 8, -180),
	HealthCost = 25,
	MinimumSeals = 2,
	ArrivalGraceSeconds = 1.25,
}

Config.Sprint = {
	NormalWalkSpeed = 16,
	SprintWalkSpeed = 22,
	MaxStamina = 100,
	DrainPerSecond = 27,
	RegenPerSecond = 19,
	RegenDelaySeconds = 1.05,
	MinimumStartStamina = 12,
	UpdateInterval = 0.10,
}

Config.FinalRun = {
	MinimumStartStamina = 72,
}

Config.Safety = {
	VoidY = -45,
	CheckInterval = 0.5,
	VoidRescueGraceSeconds = 2,
}

Config.Warden = {
	SpawnPosition = Vector3.new(0, 8, -286),
	Damage = 34,
	AttackRange = 4.6,
	AttackCooldown = 1.6,
	RepathSeconds = 0.75,
	StageOneWatchDistance = 105,
	StageOneCreepSpeed = 5.2,
	StageTwoObservedSpeed = 7.2,
	ObservationFreshnessSeconds = 0.75,
	FearAwarenessRange = 150,
	FearCriticalRange = 28,
	Stages = {
		[0] = {WalkSpeed = 0, DetectionRange = 0},
		[1] = {WalkSpeed = 7, DetectionRange = 300},
		[2] = {WalkSpeed = 10, DetectionRange = 320},
		[3] = {WalkSpeed = 18, DetectionRange = 650},
	},
}

Config.Seals = {
	{
		id = "CINDERS",
		name = "SEAL OF CINDERS",
		lore = "灰の底で、誰かが自分の名を呼んでいた。",
		position = Vector3.new(-58, 5, 126),
	},
	{
		id = "BONE",
		name = "SEAL OF BONE",
		lore = "骨は覚えている。ここから出た者は、まだ一人もいない。",
		position = Vector3.new(66, 5, -50),
	},
	{
		id = "CHAINS",
		name = "SEAL OF CHAINS",
		lore = "鎖の先にあったのは、門番の足首だった。",
		position = Vector3.new(-17, 5, -205),
	},
}

Config.Checkpoints = {
	{
		name = "ASH BRIDGE",
		position = Vector3.new(0, 8, 18),
	},
	{
		name = "BONE FIELD",
		position = Vector3.new(0, 8, -105),
	},
	{
		name = "EXECUTION CAUSEWAY",
		position = Vector3.new(0, 8, -242),
	},
}

-- Optional detours: touching an ember restores run time (risk vs. reward).
Config.SoulEmbers = {
	Positions = {
		Vector3.new(-82, 7, 198),
		Vector3.new(82, 7, 96),
		Vector3.new(7, 6, 43),
		Vector3.new(-86, 7, 6),
		Vector3.new(88, 7, -104),
		Vector3.new(-88, 7, -100),
		Vector3.new(-20, 7, -150),
		Vector3.new(20, 7, -208),
		Vector3.new(-84, 7, -262),
		Vector3.new(84, 7, -352),
	},
}

-- Ember Vents erupt on a fixed rhythm: idle -> warning glow -> blast.
Config.Vents = {
	Period = 6.0,
	WarnSeconds = 1.4,
	ActiveSeconds = 0.9,
	Radius = 7.5,
	Damage = 28,
	Positions = {
		Vector3.new(-34, 4, -10),
		Vector3.new(32, 4, -26),
		Vector3.new(-30, 4, -68),
		Vector3.new(30, 4, -84),
		Vector3.new(-9, 4, -135),
		Vector3.new(9, 4, -160),
		Vector3.new(-9, 4, -185),
		Vector3.new(9, 4, -210),
		Vector3.new(-34, 4, -278),
		Vector3.new(34, 4, -300),
	},
}

-- Sound asset ids. Empty string = silent (the game runs fine without audio).
-- Use audio you own or that Roblox allows for your experience, e.g. "rbxassetid://123456789".
Config.Audio = {
	Ambience = "",
	Heartbeat = "",
	SealBreak = "",
	EmberPickup = "",
	Checkpoint = "",
	WardenStrike = "",
	WardenAwake = "",
	VentWarn = "",
	VentBlast = "",
	AshRift = "",
	GateOpen = "",
	DeathToll = "",
	Escape = "",
}

return Config
