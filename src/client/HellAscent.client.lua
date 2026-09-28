local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local event = ReplicatedStorage:WaitForChild("HellAscentRemotes"):WaitForChild("HellAscentEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "HellAscentUI"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local header = Instance.new("Frame")
header.AnchorPoint = Vector2.new(0.5, 0)
header.Position = UDim2.new(0.5, 0, 0.035, 0)
header.Size = UDim2.new(0.88, 0, 0, 72)
header.BackgroundColor3 = Color3.fromRGB(13, 10, 11)
header.BackgroundTransparency = 0.22
header.BorderSizePixel = 0
header.Parent = gui

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -32, 0, 25)
title.BackgroundTransparency = 1
title.Text = Config.GameTitle .. "  /  " .. Config.LayerTitle
title.TextColor3 = Color3.fromRGB(220, 205, 196)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local objective = Instance.new("TextLabel")
objective.Position = UDim2.fromOffset(16, 35)
objective.Size = UDim2.new(1, -32, 0, 25)
objective.BackgroundTransparency = 1
objective.Text = "OBJECTIVE: " .. Config.Objective
objective.TextColor3 = Color3.fromRGB(194, 92, 66)
objective.Font = Enum.Font.GothamMedium
objective.TextSize = 15
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.Parent = header

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.new(0.5, 0, 0.76, 0)
toast.Size = UDim2.new(0.78, 0, 0, 62)
toast.BackgroundColor3 = Color3.fromRGB(12, 9, 10)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.TextStrokeTransparency = 1
toast.TextColor3 = Color3.fromRGB(224, 200, 183)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 19
toast.TextWrapped = true
toast.Parent = gui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toast

local intro = Instance.new("Frame")
intro.Size = UDim2.fromScale(1, 1)
intro.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
intro.BorderSizePixel = 0
intro.ZIndex = 20
intro.Parent = gui

local introTitle = Instance.new("TextLabel")
introTitle.AnchorPoint = Vector2.new(0.5, 0.5)
introTitle.Position = UDim2.new(0.5, 0, 0.47, 0)
introTitle.Size = UDim2.new(0.9, 0, 0, 90)
introTitle.BackgroundTransparency = 1
introTitle.Text = Config.GameTitle
introTitle.TextColor3 = Color3.fromRGB(220, 198, 186)
introTitle.Font = Enum.Font.GothamBlack
introTitle.TextScaled = true
introTitle.ZIndex = 21
introTitle.Parent = intro

local introSub = Instance.new("TextLabel")
introSub.AnchorPoint = Vector2.new(0.5, 0)
introSub.Position = UDim2.new(0.5, 0, 0.54, 0)
introSub.Size = UDim2.new(0.85, 0, 0, 52)
introSub.BackgroundTransparency = 1
introSub.Text = Config.LayerTitle .. "\nCLIMB. REMEMBER. ESCAPE."
introSub.TextColor3 = Color3.fromRGB(155, 83, 64)
introSub.Font = Enum.Font.GothamMedium
introSub.TextSize = 18
introSub.TextWrapped = true
introSub.ZIndex = 21
introSub.Parent = intro

local function showToast(text)
	toast.Text = text
	TweenService:Create(
		toast,
		TweenInfo.new(0.25),
		{BackgroundTransparency = 0.2, TextTransparency = 0, TextStrokeTransparency = 0.65}
	):Play()

	task.delay(2.2, function()
		TweenService:Create(
			toast,
			TweenInfo.new(0.45),
			{BackgroundTransparency = 1, TextTransparency = 1, TextStrokeTransparency = 1}
		):Play()
	end)
end

local function showEscape()
	local ending = Instance.new("Frame")
	ending.Size = UDim2.fromScale(1, 1)
	ending.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ending.BackgroundTransparency = 1
	ending.BorderSizePixel = 0
	ending.ZIndex = 30
	ending.Parent = gui

	local endingTitle = Instance.new("TextLabel")
	endingTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	endingTitle.Position = UDim2.new(0.5, 0, 0.45, 0)
	endingTitle.Size = UDim2.new(0.9, 0, 0, 90)
	endingTitle.BackgroundTransparency = 1
	endingTitle.Text = "LAYER ONE ESCAPED"
	endingTitle.TextColor3 = Color3.fromRGB(224, 204, 193)
	endingTitle.TextTransparency = 1
	endingTitle.Font = Enum.Font.GothamBlack
	endingTitle.TextScaled = true
	endingTitle.ZIndex = 31
	endingTitle.Parent = ending

	local endingSub = Instance.new("TextLabel")
	endingSub.AnchorPoint = Vector2.new(0.5, 0)
	endingSub.Position = UDim2.new(0.5, 0, 0.54, 0)
	endingSub.Size = UDim2.new(0.86, 0, 0, 80)
	endingSub.BackgroundTransparency = 1
	endingSub.Text = "THE BLACK GATE OPENS.\nLAYER TWO REMAINS SEALED."
	endingSub.TextColor3 = Color3.fromRGB(156, 75, 58)
	endingSub.TextTransparency = 1
	endingSub.Font = Enum.Font.GothamBold
	endingSub.TextSize = 20
	endingSub.TextWrapped = true
	endingSub.ZIndex = 31
	endingSub.Parent = ending

	TweenService:Create(ending, TweenInfo.new(1.15), {BackgroundTransparency = 0.08}):Play()
	TweenService:Create(endingTitle, TweenInfo.new(1.15), {TextTransparency = 0}):Play()
	TweenService:Create(endingSub, TweenInfo.new(1.15), {TextTransparency = 0}):Play()
end

event.OnClientEvent:Connect(function(kind, payload)
	if kind == "checkpoint" then
		showToast("SOUL ANCHOR: " .. string.upper(payload))
	elseif kind == "escaped" then
		showEscape()
	end
end)

task.delay(1.3, function()
	TweenService:Create(intro, TweenInfo.new(1.8), {BackgroundTransparency = 1}):Play()
	TweenService:Create(introTitle, TweenInfo.new(1.3), {TextTransparency = 1}):Play()
	TweenService:Create(introSub, TweenInfo.new(1.3), {TextTransparency = 1}):Play()

	task.delay(1.9, function()
		intro:Destroy()
	end)
end)
