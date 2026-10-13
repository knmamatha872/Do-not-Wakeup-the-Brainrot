local ShopCatalog = {}

ShopCatalog.Items = {
	{
		Id = "quiet_socks",
		Name = "Quiet Socks",
		Price = 120,
		Desc = "Sprinting makes 60% less noise.",
		Duration = 90,
	},
	{
		Id = "nightcap",
		Name = "Nightcap Lock",
		Price = 280,
		Desc = "Steals on your plot take much longer.",
		Duration = 50,
	},
	{
		Id = "padlock",
		Name = "Dream Padlock",
		Price = 450,
		Desc = "Nobody can steal from your base.",
		Duration = 40,
	},
	{
		Id = "lucky_pillow",
		Name = "Lucky Pillow",
		Price = 600,
		Desc = "Rarer sleepers spawn for a while.",
		Duration = 70,
	},
}

local byId = {}
for _, item in ShopCatalog.Items do
	byId[item.Id] = item
end

function ShopCatalog.Get(id)
	return byId[id]
end

return ShopCatalog
