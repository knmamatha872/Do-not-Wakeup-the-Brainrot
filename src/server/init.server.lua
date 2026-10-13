local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local MapBuilder = require(script.MapBuilder)
local BrainrotFactory = require(script.BrainrotFactory)

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function remoteEvent(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	return r
end

local Notify = remoteEvent("Notify")
local CarryChanged = remoteEvent("CarryChanged")
local WakePulse = remoteEvent("WakePulse")
local ShopSync = remoteEvent("ShopSync")
local RequestBuy = remoteEvent("RequestBuy")
local RequestDrop = remoteEvent("RequestDrop")

local worldFolder = Instance.new("Folder")
worldFolder.Name = "BrainrotWorld"
worldFolder.Parent = Workspace

local map = MapBuilder.Build(worldFolder)

local plotsByPlayer = {}
local freePlots = table.clone(map.Plots)
local sleepers = {}
local plotOccupants = {}
local playerState = {}
local luckyUntil = 0

local function getState(player)
	local state = playerState[player]
	if not state then
		state = {
			Cash = Config.StartCash,
			Carrying = nil,
			QuietUntil = 0,
			LockUntil = 0,
			PadlockUntil = 0,
		}
		playerState[player] = state
	end
	return state
end

local function notify(player, text)
	Notify:FireClient(player, text)
end

local function leaderstats(player)
	local folder = player:FindFirstChild("leaderstats")
	if folder then
		return folder
	end
	folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = folder
	local owned = Instance.new("IntValue")
	owned.Name = "Brainrots"
	owned.Parent = folder
	return folder
end

local function countOwned(player)
	local plot = plotsByPlayer[player]
	if not plot or not plotOccupants[plot.Index] then
		return 0
	end
	local n = 0
	for _ in plotOccupants[plot.Index] do
		n += 1
	end
	return n
end

local function refreshStats(player)
	if not player.Parent then
		return
	end
	local state = getState(player)
	local stats = leaderstats(player)
	stats.Cash.Value = math.floor(state.Cash)
	stats.Brainrots.Value = countOwned(player)
end

local function clearCarryVisual(player)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("CarriedBrainrot")
	if old then
		old:Destroy()
	end
end

local function attachCarry(player, defId)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	clearCarryVisual(player)
	local def = Catalog.Get(defId)
	local model = BrainrotFactory.CreateModel(def, false)
	model.Name = "CarriedBrainrot"
	model.Parent = character
	local primary = model.PrimaryPart
	primary.Anchored = false
	primary.CanCollide = false
	primary.Massless = true
	primary.CFrame = root.CFrame * CFrame.new(Config.CarryOffset)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = primary
	weld.Parent = primary
end

local function setCarry(player, defId)
	local state = getState(player)
	state.Carrying = defId
	if defId then
		attachCarry(player, defId)
	else
		clearCarryVisual(player)
	end
	CarryChanged:FireClient(player, defId)
end

local function stealHoldTime(owner)
	if owner and os.clock() < getState(owner).LockUntil then
		return Config.StealPromptTime * 2.5
	end
	return Config.StealPromptTime
end

local stealFromModel

local function hookSleeperPrompt(sleeper)
	sleeper.prompt.Triggered:Connect(function(player)
		if sleeper.raging or not sleeper.model.Parent then
			notify(player, "It is already awake. Run.")
			return
		end
		local state = getState(player)
		if state.Carrying then
			notify(player, "You already have a sleeping brainrot. Place it first.")
			return
		end
		local defId = sleeper.id
		setCarry(player, defId)
		sleeper.model:Destroy()
		for i, other in sleepers do
			if other == sleeper then
				table.remove(sleepers, i)
				break
			end
		end
		local def = Catalog.Get(defId)
		notify(player, `Shh... you lifted {def.Name}. Walk, don't sprint.`)
	end)
end

local function randomSleepPosition()
	for _ = 1, 12 do
		local a = math.random() * math.pi * 2
		local r = math.random() * (Config.SleepZoneRadius - 8)
		local pos = Vector3.new(math.cos(a) * r, 2.4, math.sin(a) * r)
		local clear = true
		for _, sleeper in sleepers do
			if sleeper.model.PrimaryPart and (sleeper.model.PrimaryPart.Position - pos).Magnitude < 6 then
				clear = false
				break
			end
		end
		if clear then
			return pos
		end
	end
	return Vector3.new(0, 2.4, 0)
end

local function spawnSleeperAt(def, position)
	local model = BrainrotFactory.CreateModel(def, true)
	model:SetAttribute("BrainrotId", def.Id)
	model:SetAttribute("Wake", 0)
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	model.Parent = map.Sleepers

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Gently pick up"
	prompt.ObjectText = def.Name
	prompt.HoldDuration = Config.PickupPromptTime
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	local sleeper = {
		id = def.Id,
		model = model,
		wake = 0,
		raging = false,
		prompt = prompt,
	}
	table.insert(sleepers, sleeper)
	hookSleeperPrompt(sleeper)
	return sleeper
end

local function spawnSleeper()
	if #sleepers >= Config.MaxWorldSleepers then
		return
	end
	local weights = table.clone(Config.RarityWeights)
	if os.clock() < luckyUntil then
		weights.Epic += 10
		weights.Legendary += 8
		weights.Mythic += 5
	end
	spawnSleeperAt(Catalog.Roll(weights), randomSleepPosition())
end

stealFromModel = function(thief, model)
	if not model or not model.Parent then
		return
	end
	local ownerId = model:GetAttribute("OwnerUserId")
	local slotIndex = model:GetAttribute("SlotIndex")
	local defId = model:GetAttribute("BrainrotId")
	if not ownerId or not defId then
		return
	end

	local owner
	for _, p in Players:GetPlayers() do
		if p.UserId == ownerId then
			owner = p
			break
		end
	end

	if owner and os.clock() < getState(owner).PadlockUntil then
		notify(thief, "Dream Padlock is active. You can't steal.")
		return
	end
	if getState(thief).Carrying then
		notify(thief, "Drop or place what you're carrying first.")
		return
	end

	local ownerPlot = owner and plotsByPlayer[owner]
	if ownerPlot and plotOccupants[ownerPlot.Index] then
		local entry = plotOccupants[ownerPlot.Index][slotIndex]
		if entry and entry.model == model then
			plotOccupants[ownerPlot.Index][slotIndex] = nil
		end
	end

	model:Destroy()
	setCarry(thief, defId)
	if owner then
		refreshStats(owner)
		notify(owner, `{thief.Name} stole your {Catalog.Get(defId).Name}!`)
	end
	refreshStats(thief)
	notify(thief, `You stole {Catalog.Get(defId).Name}... don't wake it.`)
end

local function placeOnPlot(player, slotIndex)
	local state = getState(player)
	local plot = plotsByPlayer[player]
	if not state.Carrying or not plot then
		return
	end
	plotOccupants[plot.Index] = plotOccupants[plot.Index] or {}
	if plotOccupants[plot.Index][slotIndex] then
		return
	end
	local def = Catalog.Get(state.Carrying)
	local slot = plot.Slots:FindFirstChild(`Slot_{slotIndex}`)
	if not slot then
		return
	end

	local model = BrainrotFactory.CreateModel(def, true)
	model:SetAttribute("BrainrotId", def.Id)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("SlotIndex", slotIndex)
	model:PivotTo(slot.CFrame * CFrame.new(0, 2.2, 0))
	model.Parent = plot.Folder

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal quietly"
	prompt.ObjectText = def.Name
	prompt.HoldDuration = stealHoldTime(player)
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(thief)
		stealFromModel(thief, model)
	end)

	plotOccupants[plot.Index][slotIndex] = { defId = def.Id, model = model }
	setCarry(player, nil)
	refreshStats(player)
	notify(player, `{def.Name} is napping on your base. +${def.Income}/s`)
end

local function assignPlot(player)
	if plotsByPlayer[player] then
		return plotsByPlayer[player]
	end
	local plot = table.remove(freePlots, 1)
	if not plot then
		notify(player, "No empty bases left.")
		return nil
	end
	plotsByPlayer[player] = plot
	plotOccupants[plot.Index] = {}
	plot.OwnerText.Text = `{player.Name}'s nursery`
	plot.Spawn.Neutral = true
	player.RespawnLocation = plot.Spawn
	task.defer(function()
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character:PivotTo(plot.Spawn.CFrame + Vector3.new(0, 4, 0))
		end
	end)
	return plot
end

local function releasePlot(player)
	local plot = plotsByPlayer[player]
	if not plot then
		return
	end
	local occ = plotOccupants[plot.Index]
	if occ then
		for _, entry in occ do
			if entry.model then
				entry.model:Destroy()
			end
		end
	end
	plotOccupants[plot.Index] = nil
	plot.OwnerText.Text = "Empty Base"
	plot.Spawn.Neutral = false
	plotsByPlayer[player] = nil
	table.insert(freePlots, plot)
end

local function wakeSleeper(sleeper, culprit)
	if sleeper.raging then
		return
	end
	sleeper.raging = true
	if sleeper.prompt then
		sleeper.prompt:Destroy()
	end
	local def = Catalog.Get(sleeper.id)
	local primary = sleeper.model.PrimaryPart
	if primary then
		primary.Color = Color3.fromRGB(255, 60, 60)
		local label = primary:FindFirstChild("Label")
		local nameLabel = label and label:FindFirstChildWhichIsA("TextLabel")
		if nameLabel then
			nameLabel.Text = `{def.Name} WOKE UP`
			nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		end
	end
	if culprit then
		notify(culprit, `{def.Name} WOKE UP!`)
		WakePulse:FireClient(culprit, 1)
		local state = getState(culprit)
		if Config.DropOnWake and state.Carrying then
			setCarry(culprit, nil)
			notify(culprit, "You dropped your brainrot in the panic.")
		end
		state.Cash = math.max(0, state.Cash - Config.WakeFine)
		refreshStats(culprit)
	end

	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < Config.RageDuration and sleeper.model.Parent do
			if culprit and culprit.Character then
				local root = culprit.Character:FindFirstChild("HumanoidRootPart")
				local pp = sleeper.model.PrimaryPart
				if root and pp then
					local dir = root.Position - pp.Position
					if dir.Magnitude > 1 then
						pp.CFrame = CFrame.lookAt(pp.Position + dir.Unit * Config.RageSpeed * 0.08, root.Position)
					end
					if dir.Magnitude < 5 then
						local hum = culprit.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							hum:TakeDamage(6)
						end
					end
				end
			end
			task.wait(0.08)
		end
		if sleeper.model then
			sleeper.model:Destroy()
		end
		for i, other in sleepers do
			if other == sleeper then
				table.remove(sleepers, i)
				break
			end
		end
	end)
end

local function hookJumps(player)
	local function bind(character)
		local hum = character:WaitForChild("Humanoid", 8)
		if not hum then
			return
		end
		hum.StateChanged:Connect(function(_, new)
			if new ~= Enum.HumanoidStateType.Jumping then
				return
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then
				return
			end
			for _, sleeper in sleepers do
				if sleeper.raging or not sleeper.model.PrimaryPart then
					continue
				end
				local dist = (sleeper.model.PrimaryPart.Position - root.Position).Magnitude
				if dist < Config.WakeRadius then
					local def = Catalog.Get(sleeper.id)
					sleeper.wake += Config.JumpWake * (def.WakeSensitivity or 1)
				end
			end
		end)
	end
	if player.Character then
		bind(player.Character)
	end
	player.CharacterAdded:Connect(bind)
end

RequestDrop.OnServerEvent:Connect(function(player)
	local state = getState(player)
	if not state.Carrying then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local def = Catalog.Get(state.Carrying)
	setCarry(player, nil)
	local pos = root.Position + root.CFrame.LookVector * 6
	spawnSleeperAt(def, Vector3.new(pos.X, 2.4, pos.Z))
	notify(player, "You set it down. It's still asleep. For now.")
end)

RequestBuy.OnServerEvent:Connect(function(player, itemId)
	if typeof(itemId) ~= "string" then
		return
	end
	local item = ShopCatalog.Get(itemId)
	if not item then
		return
	end
	local state = getState(player)
	if state.Cash < item.Price then
		notify(player, "Not enough cash.")
		return
	end
	state.Cash -= item.Price
	local untilTime = os.clock() + item.Duration
	if item.Id == "quiet_socks" then
		state.QuietUntil = untilTime
	elseif item.Id == "nightcap" then
		state.LockUntil = untilTime
		local plot = plotsByPlayer[player]
		if plot and plotOccupants[plot.Index] then
			for _, entry in plotOccupants[plot.Index] do
				local prompt = entry.model.PrimaryPart and entry.model.PrimaryPart:FindFirstChild("StealPrompt")
				if prompt then
					prompt.HoldDuration = stealHoldTime(player)
				end
			end
		end
	elseif item.Id == "padlock" then
		state.PadlockUntil = untilTime
	elseif item.Id == "lucky_pillow" then
		luckyUntil = math.max(luckyUntil, untilTime)
	end
	refreshStats(player)
	notify(player, `Bought {item.Name}.`)
	ShopSync:FireClient(player, {
		QuietUntil = state.QuietUntil,
		LockUntil = state.LockUntil,
		PadlockUntil = state.PadlockUntil,
		LuckyUntil = luckyUntil,
	})
end)

RunService.Heartbeat:Connect(function(dt)
	for _, sleeper in sleepers do
		if sleeper.raging or not sleeper.model.PrimaryPart then
			continue
		end
		local pos = sleeper.model.PrimaryPart.Position
		local def = Catalog.Get(sleeper.id)
		local add = 0
		local closestCulprit = nil
		local closestDist = math.huge
		for _, player in Players:GetPlayers() do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not hum or not root then
				continue
			end
			local dist = (root.Position - pos).Magnitude
			if dist > Config.WakeRadius then
				continue
			end
			local quiet = os.clock() < getState(player).QuietUntil
			local factor = if quiet then 0.4 else 1
			local speed = root.AssemblyLinearVelocity.Magnitude
			local wakeRate = if speed > 18 then Config.SprintWakePerSecond else Config.WalkWakePerSecond
			add += wakeRate * factor * (def.WakeSensitivity or 1) * dt * (1 - dist / Config.WakeRadius)
			if dist < closestDist then
				closestDist = dist
				closestCulprit = player
			end
		end
		sleeper.wake = math.clamp(sleeper.wake - Config.WakeDecayPerSecond * dt + add, 0, 100)
		sleeper.model:SetAttribute("Wake", sleeper.wake)
		if closestCulprit then
			WakePulse:FireClient(closestCulprit, sleeper.wake / 100)
		end
		if sleeper.wake >= 100 then
			wakeSleeper(sleeper, closestCulprit)
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	leaderstats(player)
	getState(player)
	assignPlot(player)
	refreshStats(player)
	hookJumps(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.4)
		local state = getState(player)
		if state.Carrying then
			attachCarry(player, state.Carrying)
		end
		local plot = plotsByPlayer[player]
		if plot then
			player.RespawnLocation = plot.Spawn
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	releasePlot(player)
	playerState[player] = nil
end)

for _, player in Players:GetPlayers() do
	leaderstats(player)
	assignPlot(player)
	refreshStats(player)
	hookJumps(player)
end

task.spawn(function()
	while true do
		spawnSleeper()
		task.wait(Config.SpawnInterval)
	end
end)

task.spawn(function()
	while true do
		task.wait(Config.IncomeInterval)
		for player, plot in plotsByPlayer do
			local occ = plotOccupants[plot.Index]
			if not occ then
				continue
			end
			local gain = 0
			for _, entry in occ do
				local def = Catalog.Get(entry.defId)
				if def then
					gain += def.Income
				end
			end
			if gain > 0 then
				getState(player).Cash += gain
				refreshStats(player)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		for player, plot in plotsByPlayer do
			local state = getState(player)
			if not state.Carrying then
				continue
			end
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end
			for _, slot in plot.Slots:GetChildren() do
				local index = slot:GetAttribute("SlotIndex")
				if plotOccupants[plot.Index] and plotOccupants[plot.Index][index] then
					continue
				end
				if (root.Position - slot.Position).Magnitude < 4.5 then
					placeOnPlot(player, index)
					break
				end
			end
		end
	end
end)

print("[Do not Wakeup the Brainrot] Server ready")
