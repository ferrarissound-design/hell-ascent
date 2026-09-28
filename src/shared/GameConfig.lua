local Config = {}

Config.GameTitle = "HELL ASCENT"
Config.LayerTitle = "LAYER ONE: ASHEN VERGE"
Config.Objective = "Break 3 Soul Seals, then reach the Black Gate."

Config.SpawnPosition = Vector3.new(0, 8, 170)
Config.ExitPosition = Vector3.new(0, 8, -350)

Config.RunDurationSeconds = 600
Config.DeathPenaltySeconds = 20
Config.RespawnGraceSeconds = 6
Config.GateRepelPosition = Vector3.new(0, 8, -322)

Config.AshRift = {
	Position = Vector3.new(62, 8, -88),
	Destination = Vector3.new(0, 8, -214),
	HealthCost = 25,
	MinimumSeals = 1,
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
		[1] = {WalkSpeed = 7, DetectionRange = 180},
		[2] = {WalkSpeed = 10, DetectionRange = 320},
		[3] = {WalkSpeed = 14.2, DetectionRange = 650},
	},
}

Config.Seals = {
	{
		id = "CINDERS",
		name = "SEAL OF CINDERS",
		position = Vector3.new(-58, 5, 126),
	},
	{
		id = "BONE",
		name = "SEAL OF BONE",
		position = Vector3.new(66, 5, -50),
	},
	{
		id = "CHAINS",
		name = "SEAL OF CHAINS",
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

return Config
