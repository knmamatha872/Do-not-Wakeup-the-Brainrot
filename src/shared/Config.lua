local Config = {}

Config.MaxPlayers = 8
Config.PlotCount = 8
Config.PlotRadius = 90
Config.SleepZoneRadius = 42
Config.MaxWorldSleepers = 14
Config.SpawnInterval = 4
Config.IncomeInterval = 1
Config.CarryOffset = Vector3.new(0, 3.2, -1.6)
Config.StartCash = 25
Config.StealPromptTime = 1.8
Config.PickupPromptTime = 0.7
Config.MaxPlotSlots = 6
Config.WakeRadius = 14
Config.SprintWakePerSecond = 38
Config.WalkWakePerSecond = 4
Config.JumpWake = 22
Config.WakeDecayPerSecond = 12
Config.RageDuration = 6
Config.RageSpeed = 22
Config.DropOnWake = true
Config.WakeFine = 15

Config.RarityWeights = {
	Common = 48,
	Rare = 28,
	Epic = 14,
	Legendary = 8,
	Mythic = 2,
}

Config.RarityColors = {
	Common = Color3.fromRGB(180, 190, 210),
	Rare = Color3.fromRGB(80, 170, 255),
	Epic = Color3.fromRGB(190, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 50),
	Mythic = Color3.fromRGB(255, 70, 110),
}

return Config
