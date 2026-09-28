local Config = {}

Config.GameTitle = "HELL ASCENT"
Config.LayerTitle = "LAYER ONE: ASHEN VERGE"
Config.Objective = "Reach the Black Gate."

Config.SpawnPosition = Vector3.new(0, 8, 170)
Config.ExitPosition = Vector3.new(0, 8, -350)

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
