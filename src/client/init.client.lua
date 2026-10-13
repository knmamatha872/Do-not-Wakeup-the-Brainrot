local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Notify = remotes:WaitForChild("Notify")
local CarryChanged = remotes:WaitForChild("CarryChanged")
local WakePulse = remotes:WaitForChild("WakePulse")
local ShopSync = remotes:WaitForChild("ShopSync")
local RequestBuy = remotes:WaitForChild("RequestBuy")
local RequestDrop = remotes:WaitForChild("RequestDrop")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, pos, size, text, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Font = Enum.Font.GothamBold
	l.Text = text
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.5
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local title = makeLabel(gui, "Title", UDim2.new(0, 24, 0, 18), UDim2.new(0, 520, 0, 36), "DO NOT WAKEUP THE BRAINROT", Color3.fromRGB(255, 220, 150))
title.Font = Enum.Font.GothamBlack

local hint = makeLabel(gui, "Hint", UDim2.new(0, 24, 0, 52), UDim2.new(0, 560, 0, 22), "Walk the nursery. Sprint and jump wake them. Place sleepers on your base. Steal from others.", Color3.fromRGB(190, 200, 230))
hint.Font = Enum.Font.Gotham

local carryLabel = makeLabel(gui, "Carry", UDim2.new(0, 24, 1, -90), UDim2.new(0, 420, 0, 28), "Carrying: nothing", Color3.fromRGB(180, 255, 200))
local dropHint = makeLabel(gui, "DropHint", UDim2.new(0, 24, 1, -62), UDim2.new(0, 420, 0, 20), "G = put it down   |   walk onto your pillows to place", Color3.fromRGB(160, 170, 200))
dropHint.Font = Enum.Font.Gotham

local wakeBack = Instance.new("Frame")
wakeBack.Name = "WakeBack"
wakeBack.Position = UDim2.new(0.5, -160, 0, 20)
wakeBack.Size = UDim2.new(0, 320, 0, 18)
wakeBack.BackgroundColor3 = Color3.fromRGB(20, 16, 28)
wakeBack.BorderSizePixel = 0
wakeBack.Parent = gui
Instance.new("UICorner", wakeBack).CornerRadius = UDim.new(0, 8)

local wakeFill = Instance.new("Frame")
wakeFill.Name = "Fill"
wakeFill.Size = UDim2.new(0, 0, 1, 0)
wakeFill.BackgroundColor3 = Color3.fromRGB(120, 220, 160)
wakeFill.BorderSizePixel = 0
wakeFill.Parent = wakeBack
Instance.new("UICorner", wakeFill).CornerRadius = UDim.new(0, 8)

local wakeText = makeLabel(wakeBack, "WakeText", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), "QUIET", Color3.new(1, 1, 1))
wakeText.TextXAlignment = Enum.TextXAlignment.Center
wakeText.TextScaled = true

local toast = makeLabel(gui, "Toast", UDim2.new(0.5, -280, 0.72, 0), UDim2.new(0, 560, 0, 36), "", Color3.fromRGB(255, 240, 200))
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.TextTransparency = 1

local shopBtn = Instance.new("TextButton")
shopBtn.Name = "ShopBtn"
shopBtn.Position = UDim2.new(1, -168, 0, 18)
shopBtn.Size = UDim2.new(0, 148, 0, 40)
shopBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 110)
shopBtn.Font = Enum.Font.GothamBold
shopBtn.Text = "NIGHT MARKET"
shopBtn.TextColor3 = Color3.new(1, 1, 1)
shopBtn.TextScaled = true
shopBtn.Parent = gui
Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 8)

local shop = Instance.new("Frame")
shop.Name = "Shop"
shop.Visible = false
shop.Position = UDim2.new(1, -360, 0, 70)
shop.Size = UDim2.new(0, 336, 0, 360)
shop.BackgroundColor3 = Color3.fromRGB(16, 14, 28)
shop.Parent = gui
Instance.new("UICorner", shop).CornerRadius = UDim.new(0, 12)
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 12)
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = shop
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.Parent = shop

local shopTitle = Instance.new("TextLabel")
shopTitle.BackgroundTransparency = 1
shopTitle.Size = UDim2.new(1, 0, 0, 28)
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.Text = "Buy silence"
shopTitle.TextColor3 = Color3.fromRGB(255, 220, 160)
shopTitle.TextScaled = true
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Parent = shop

for _, item in ShopCatalog.Items do
	local row = Instance.new("TextButton")
	row.Name = item.Id
	row.Size = UDim2.new(1, 0, 0, 70)
	row.BackgroundColor3 = Color3.fromRGB(32, 28, 52)
	row.Font = Enum.Font.GothamBold
	row.Text = ""
	row.Parent = shop
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
	local n = Instance.new("TextLabel")
	n.BackgroundTransparency = 1
	n.Position = UDim2.new(0, 10, 0, 6)
	n.Size = UDim2.new(1, -20, 0, 22)
	n.Font = Enum.Font.GothamBold
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.TextColor3 = Color3.new(1, 1, 1)
	n.TextScaled = true
	n.Text = `{item.Name}  —  ${item.Price}`
	n.Parent = row
	local d = Instance.new("TextLabel")
	d.BackgroundTransparency = 1
	d.Position = UDim2.new(0, 10, 0, 30)
	d.Size = UDim2.new(1, -20, 0, 32)
	d.Font = Enum.Font.Gotham
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.TextColor3 = Color3.fromRGB(190, 195, 220)
	d.TextWrapped = true
	d.TextSize = 14
	d.Text = item.Desc
	d.Parent = row
	row.MouseButton1Click:Connect(function()
		RequestBuy:FireServer(item.Id)
	end)
end

shopBtn.MouseButton1Click:Connect(function()
	shop.Visible = not shop.Visible
end)

local toastToken = 0
Notify.OnClientEvent:Connect(function(text)
	toastToken += 1
	local my = toastToken
	toast.Text = text
	toast.TextTransparency = 0
	task.delay(2.6, function()
		if toastToken == my then
			TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		end
	end)
end)

CarryChanged.OnClientEvent:Connect(function(defId)
	if not defId then
		carryLabel.Text = "Carrying: nothing"
		return
	end
	local def = Catalog.Get(defId)
	carryLabel.Text = `Carrying: {def and def.Name or defId}  (walk to your pillows)`
end)

WakePulse.OnClientEvent:Connect(function(alpha)
	alpha = math.clamp(alpha, 0, 1)
	wakeFill.Size = UDim2.new(alpha, 0, 1, 0)
	if alpha < 0.4 then
		wakeFill.BackgroundColor3 = Color3.fromRGB(120, 220, 160)
		wakeText.Text = "QUIET"
	elseif alpha < 0.75 then
		wakeFill.BackgroundColor3 = Color3.fromRGB(255, 200, 70)
		wakeText.Text = "STIRRING..."
	else
		wakeFill.BackgroundColor3 = Color3.fromRGB(255, 70, 80)
		wakeText.Text = "DON'T WAKE THEM"
	end
end)

ShopSync.OnClientEvent:Connect(function()
	-- HUD toast already confirms the purchase.
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.G then
		RequestDrop:FireServer()
	elseif input.KeyCode == Enum.KeyCode.B then
		shop.Visible = not shop.Visible
	end
end)
