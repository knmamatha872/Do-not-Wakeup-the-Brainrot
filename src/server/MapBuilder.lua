local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local MapBuilder = {}

local function basePart(name, size, cframe, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function MapBuilder.Build(folder)
	folder:ClearAllChildren()

	basePart(
		"Ground",
		Vector3.new(360, 2, 360),
		CFrame.new(0, -1, 0),
		Color3.fromRGB(18, 22, 38),
		Enum.Material.Grass,
		folder
	)

	local pillow = basePart(
		"SleepZone",
		Vector3.new(1, Config.SleepZoneRadius * 2, Config.SleepZoneRadius * 2),
		CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(48, 38, 78),
		Enum.Material.Fabric,
		folder
	)
	pillow.Shape = Enum.PartType.Cylinder

	basePart(
		"MoonGlow",
		Vector3.new(18, 1, 18),
		CFrame.new(0, 0.7, 0),
		Color3.fromRGB(90, 80, 160),
		Enum.Material.Neon,
		folder
	)

	local title = Instance.new("BillboardGui")
	title.Size = UDim2.fromOffset(420, 70)
	title.StudsOffset = Vector3.new(0, 18, 0)
	title.AlwaysOnTop = true
	title.Parent = pillow
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 230, 180)
	t.TextStrokeTransparency = 0.4
	t.Text = "DO NOT WAKEUP THE BRAINROT"
	t.Parent = title

	local shop = Instance.new("Model")
	shop.Name = "Shop"
	shop.Parent = folder
	local stall = basePart(
		"Stall",
		Vector3.new(16, 8, 10),
		CFrame.new(0, 4, -Config.PlotRadius - 18),
		Color3.fromRGB(40, 28, 22),
		Enum.Material.Wood,
		shop
	)
	shop.PrimaryPart = stall
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(220, 40)
	sign.StudsOffset = Vector3.new(0, 6, 0)
	sign.Parent = stall
	local s = Instance.new("TextLabel")
	s.BackgroundTransparency = 1
	s.Size = UDim2.fromScale(1, 1)
	s.Font = Enum.Font.GothamBold
	s.TextScaled = true
	s.TextColor3 = Color3.new(1, 1, 1)
	s.Text = "NIGHT MARKET"
	s.Parent = sign

	local plots = {}
	for i = 1, Config.PlotCount do
		local angle = (i / Config.PlotCount) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * Config.PlotRadius, 0, math.sin(angle) * Config.PlotRadius)
		local facing = CFrame.lookAt(pos, Vector3.new(0, 0, 0))
		local plot = Instance.new("Folder")
		plot.Name = `Plot_{i}`
		plot.Parent = folder

		basePart("Pad", Vector3.new(28, 1, 22), facing * CFrame.new(0, 0.5, 0), Color3.fromRGB(28, 34, 52), Enum.Material.Slate, plot)
		basePart("Rug", Vector3.new(20, 0.4, 14), facing * CFrame.new(0, 1.1, 2), Color3.fromRGB(70, 40, 90), Enum.Material.Fabric, plot)

		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(6, 1, 6)
		spawn.CFrame = facing * CFrame.new(0, 1.6, 8)
		spawn.Neutral = false
		spawn.Duration = 0
		spawn.BrickColor = BrickColor.new("Really black")
		spawn.Material = Enum.Material.Neon
		spawn.Transparency = 0.35
		spawn.Parent = plot

		local slots = Instance.new("Folder")
		slots.Name = "Slots"
		slots.Parent = plot
		for slot = 1, Config.MaxPlotSlots do
			local col = ((slot - 1) % 3) - 1
			local row = math.floor((slot - 1) / 3)
			local slotPart = basePart(
				`Slot_{slot}`,
				Vector3.new(4.5, 0.4, 4.5),
				facing * CFrame.new(col * 6, 1.3, -2 - row * 6),
				Color3.fromRGB(35, 30, 55),
				Enum.Material.Neon,
				slots
			)
			slotPart:SetAttribute("SlotIndex", slot)
		end

		local ownerGui = Instance.new("BillboardGui")
		ownerGui.Name = "OwnerBillboard"
		ownerGui.Size = UDim2.fromOffset(220, 36)
		ownerGui.StudsOffset = Vector3.new(0, 10, 0)
		ownerGui.AlwaysOnTop = true
		ownerGui.Parent = spawn
		local ownerText = Instance.new("TextLabel")
		ownerText.Name = "Text"
		ownerText.BackgroundTransparency = 1
		ownerText.Size = UDim2.fromScale(1, 1)
		ownerText.Font = Enum.Font.GothamBold
		ownerText.TextScaled = true
		ownerText.TextColor3 = Color3.fromRGB(200, 210, 255)
		ownerText.Text = "Empty Base"
		ownerText.Parent = ownerGui

		table.insert(plots, {
			Index = i,
			Folder = plot,
			CFrame = facing,
			Spawn = spawn,
			Slots = slots,
			OwnerText = ownerText,
		})
	end

	local sleepFolder = Instance.new("Folder")
	sleepFolder.Name = "Sleepers"
	sleepFolder.Parent = folder

	return {
		Plots = plots,
		Sleepers = sleepFolder,
		Shop = shop,
	}
end

return MapBuilder
