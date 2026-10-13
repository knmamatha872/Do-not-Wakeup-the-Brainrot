local Catalog = {}

Catalog.List = {
	{
		Id = "tralalero",
		Name = "Tralalero Tralala",
		Rarity = "Common",
		Income = 3,
		WakeSensitivity = 0.7,
		Color = Color3.fromRGB(70, 150, 255),
		Accent = Color3.fromRGB(20, 40, 80),
		Shape = "shark",
	},
	{
		Id = "tungtung",
		Name = "Tung Tung Tung Sahur",
		Rarity = "Common",
		Income = 4,
		WakeSensitivity = 0.85,
		Color = Color3.fromRGB(150, 95, 55),
		Accent = Color3.fromRGB(40, 25, 15),
		Shape = "bat",
	},
	{
		Id = "lirili",
		Name = "Lirili Larila",
		Rarity = "Rare",
		Income = 8,
		WakeSensitivity = 0.6,
		Color = Color3.fromRGB(240, 210, 90),
		Accent = Color3.fromRGB(90, 160, 70),
		Shape = "cactus",
	},
	{
		Id = "bombardiro",
		Name = "Bombardiro Crocodilo",
		Rarity = "Rare",
		Income = 10,
		WakeSensitivity = 0.9,
		Color = Color3.fromRGB(50, 120, 70),
		Accent = Color3.fromRGB(70, 70, 80),
		Shape = "plane",
	},
	{
		Id = "patapim",
		Name = "Brr Brr Patapim",
		Rarity = "Epic",
		Income = 18,
		WakeSensitivity = 0.55,
		Color = Color3.fromRGB(40, 130, 70),
		Accent = Color3.fromRGB(120, 80, 40),
		Shape = "tree",
	},
	{
		Id = "cappuccina",
		Name = "Ballerina Cappuccina",
		Rarity = "Epic",
		Income = 22,
		WakeSensitivity = 1.1,
		Color = Color3.fromRGB(255, 230, 245),
		Accent = Color3.fromRGB(120, 70, 50),
		Shape = "cup",
	},
	{
		Id = "assassino",
		Name = "Cappuccino Assassino",
		Rarity = "Legendary",
		Income = 40,
		WakeSensitivity = 1.25,
		Color = Color3.fromRGB(90, 55, 35),
		Accent = Color3.fromRGB(20, 20, 25),
		Shape = "cup",
	},
	{
		Id = "chimpanzini",
		Name = "Chimpanzini Bananini",
		Rarity = "Legendary",
		Income = 45,
		WakeSensitivity = 0.75,
		Color = Color3.fromRGB(255, 220, 70),
		Accent = Color3.fromRGB(90, 60, 40),
		Shape = "banana",
	},
	{
		Id = "tripi",
		Name = "Trippi Troppi",
		Rarity = "Mythic",
		Income = 80,
		WakeSensitivity = 0.5,
		Color = Color3.fromRGB(255, 90, 160),
		Accent = Color3.fromRGB(40, 220, 255),
		Shape = "shrimp",
	},
	{
		Id = "saturnita",
		Name = "La Vaca Saturno Saturnita",
		Rarity = "Mythic",
		Income = 95,
		WakeSensitivity = 0.95,
		Color = Color3.fromRGB(255, 170, 80),
		Accent = Color3.fromRGB(180, 80, 255),
		Shape = "cow",
	},
}

local byId = {}
for _, item in Catalog.List do
	byId[item.Id] = item
end

function Catalog.Get(id)
	return byId[id]
end

function Catalog.Roll(weights)
	local total = 0
	for _, item in Catalog.List do
		total += weights[item.Rarity] or 1
	end
	local pick = math.random() * total
	local acc = 0
	for _, item in Catalog.List do
		acc += weights[item.Rarity] or 1
		if pick <= acc then
			return item
		end
	end
	return Catalog.List[1]
end

return Catalog
