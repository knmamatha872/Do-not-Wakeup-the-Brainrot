local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local Config = require(ReplicatedStorage.Shared.Config)

local Factory = {}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = props.Anchored ~= false
	p.CanCollide = props.CanCollide == true
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.new(1, 1, 1)
	p.Size = props.Size or Vector3.new(1, 1, 1)
	p.CFrame = props.CFrame or CFrame.new()
	p.Name = props.Name or "Part"
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	if props.Parent then
		p.Parent = props.Parent
	end
	return p
end

function Factory.CreateModel(def, sleeper)
	def = def or Catalog.List[1]
	local model = Instance.new("Model")
	model.Name = def.Name

	local root = part({
		Name = "Root",
		Size = Vector3.new(2.4, 2.2, 2.6),
		Color = def.Color,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = model,
	})
	model.PrimaryPart = root

	part({
		Name = "Belly",
		Size = Vector3.new(2.8, 2.4, 2.2),
		Color = def.Color:Lerp(Color3.new(1, 1, 1), 0.15),
		CFrame = root.CFrame * CFrame.new(0, -0.2, 0.1),
		Parent = model,
	})
	part({
		Name = "Hat",
		Size = Vector3.new(2.2, 0.5, 2.2),
		Color = def.Accent,
		CFrame = root.CFrame * CFrame.new(0, 1.4, 0),
		Parent = model,
	})
	part({
		Name = "EyeL",
		Size = Vector3.new(0.45, 0.35, 0.3),
		Color = Color3.new(1, 1, 1),
		CFrame = root.CFrame * CFrame.new(-0.45, 0.45, -1.2),
		Parent = model,
	})
	part({
		Name = "EyeR",
		Size = Vector3.new(0.45, 0.35, 0.3),
		Color = Color3.new(1, 1, 1),
		CFrame = root.CFrame * CFrame.new(0.45, 0.45, -1.2),
		Parent = model,
	})

	if sleeper then
		local zzz = part({
			Name = "Zzz",
			Size = Vector3.new(0.7, 0.7, 0.7),
			Color = Color3.fromRGB(200, 220, 255),
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(1.4, 1.8, 0),
			Parent = model,
		})
		zzz.Shape = Enum.PartType.Ball
	end

	local rarity = Config.RarityColors[def.Rarity] or Color3.new(1, 1, 1)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(180, 48)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = root

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Text = def.Name
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Position = UDim2.new(0, 0, 0.6, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.4, 0)
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextScaled = true
	rarityLabel.TextColor3 = rarity
	rarityLabel.TextStrokeTransparency = 0.5
	rarityLabel.Text = `{def.Rarity}  +${def.Income}/s`
	rarityLabel.Parent = gui

	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = child
			weld.Parent = child
			child.Anchored = false
			child.CanCollide = false
		end
	end
	root.Anchored = true

	return model
end

return Factory
