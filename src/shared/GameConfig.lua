local Config = {}

Config.GameTitle = "HELL ASCENT"
Config.LayerTitle = "LAYER ONE: ASHEN VERGE"
Config.Objective = "Break 3 Soul Seals, then reach the Black Gate."

Config.SpawnPosition = Vector3.new(0, 8, 170)
Config.ExitPosition = Vector3.new(0, 8, -350)

Config.RunDurationSeconds = 600
Config.DeathPenaltySeconds = 30

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
