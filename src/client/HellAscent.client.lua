local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local event = ReplicatedStorage:WaitForChild("HellAscentRemotes"):WaitForChild("HellAscentEvent")

local brokenSeals = {}
local guideMarkers = {}
local lastGuideUpdate = 0
local escapeShown = false

local gui = Instance.new("ScreenGui")
gui.Name = "HellAscentUI"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local header = Instance.new("Frame")
header.AnchorPoint = Vector2.new(0.5, 0)
header.Position = UDim2.new(0.5, 0, 0, 10)
header.Size = UDim2.new(0.92, 0, 0, 86)
header.BackgroundColor3 = Color3.fromRGB(13, 10, 11)
header.BackgroundTransparency = 0.24
header.BorderSizePixel = 0
header.Parent = gui

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(14, 5)
title.Size = UDim2.new(1, -28, 0, 18)
title.BackgroundTransparency = 1
title.Text = "HELL ASCENT  /  ASHEN VERGE"
title.TextColor3 = Color3.fromRGB(195, 181, 173)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local sealsLabel = Instance.new("TextLabel")
sealsLabel.Position = UDim2.fromOffset(14, 25)
sealsLabel.Size = UDim2.new(0.54, -14, 0, 24)
sealsLabel.BackgroundTransparency = 1
sealsLabel.Text = "魂の封印  0 / " .. tostring(#Config.Seals)
sealsLabel.TextColor3 = Color3.fromRGB(222, 174, 145)
sealsLabel.Font = Enum.Font.GothamBold
sealsLabel.TextSize = 15
sealsLabel.TextXAlignment = Enum.TextXAlignment.Left
sealsLabel.Parent = header

local timerLabel = Instance.new("TextLabel")
timerLabel.AnchorPoint = Vector2.new(1, 0)
timerLabel.Position = UDim2.new(1, -14, 0, 25)
timerLabel.Size = UDim2.new(0.44, 0, 0, 24)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "残り  10:00"
timerLabel.TextColor3 = Color3.fromRGB(222, 174, 145)
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.TextSize = 15
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.Parent = header

local navLabel = Instance.new("TextLabel")
navLabel.Position = UDim2.fromOffset(14, 52)
navLabel.Size = UDim2.new(1, -28, 0, 25)
navLabel.BackgroundTransparency = 1
navLabel.Text = "次の封印を探す"
navLabel.TextColor3 = Color3.fromRGB(232, 118, 81)
navLabel.Font = Enum.Font.GothamBold
navLabel.TextSize = 15
navLabel.TextXAlignment = Enum.TextXAlignment.Left
navLabel.TextTruncate = Enum.TextTruncate.AtEnd
navLabel.Parent = header

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.new(0.5, 0, 0.74, 0)
toast.Size = UDim2.new(0.82, 0, 0, 58)
toast.BackgroundColor3 = Color3.fromRGB(12, 9, 10)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.TextStrokeTransparency = 1
toast.TextColor3 = Color3.fromRGB(238, 214, 198)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 17
toast.TextWrapped = true
toast.ZIndex = 15
toast.Parent = gui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toast

local damageFlash = Instance.new("Frame")
damageFlash.Size = UDim2.fromScale(1, 1)
damageFlash.BackgroundColor3 = Color3.fromRGB(170, 22, 12)
damageFlash.BackgroundTransparency = 1
damageFlash.BorderSizePixel = 0
damageFlash.ZIndex = 14
damageFlash.Parent = gui

local intro = Instance.new("Frame")
intro.Size = UDim2.fromScale(1, 1)
intro.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
intro.BackgroundTransparency = 0.18
intro.BorderSizePixel = 0
intro.ZIndex = 20
intro.Parent = gui

local introTitle = Instance.new("TextLabel")
introTitle.AnchorPoint = Vector2.new(0.5, 0.5)
introTitle.Position = UDim2.new(0.5, 0, 0.44, 0)
introTitle.Size = UDim2.new(0.86, 0, 0, 72)
introTitle.BackgroundTransparency = 1
introTitle.Text = Config.GameTitle
introTitle.TextColor3 = Color3.fromRGB(224, 202, 190)
introTitle.Font = Enum.Font.GothamBlack
introTitle.TextScaled = true
introTitle.ZIndex = 21
introTitle.Parent = intro

local introSub = Instance.new("TextLabel")
introSub.AnchorPoint = Vector2.new(0.5, 0)
introSub.Position = UDim2.new(0.5, 0, 0.52, 0)
introSub.Size = UDim2.new(0.84, 0, 0, 72)
introSub.BackgroundTransparency = 1
introSub.Text = "3つの封印を壊せ\n黒い門へ逃げろ"
introSub.TextColor3 = Color3.fromRGB(205, 98, 70)
introSub.Font = Enum.Font.GothamBold
introSub.TextSize = 19
introSub.TextWrapped = true
introSub.ZIndex = 21
introSub.Parent = intro

local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local minutes = math.floor(seconds / 60)
	local remainder = seconds % 60
	return string.format("%02d:%02d", minutes, remainder)
end

local function showToast(text)
	toast.Text = text
	TweenService:Create(
		toast,
		TweenInfo.new(0.18),
		{BackgroundTransparency = 0.18, TextTransparency = 0, TextStrokeTransparency = 0.65}
	):Play()

	task.delay(2.0, function()
		TweenService:Create(
			toast,
			TweenInfo.new(0.35),
			{BackgroundTransparency = 1, TextTransparency = 1, TextStrokeTransparency = 1}
		):Play()
	end)
end

local function flashDamage()
	damageFlash.BackgroundTransparency = 0.78
	TweenService:Create(
		damageFlash,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1}
	):Play()
end

local function showEscape()
	if escapeShown then
		return
	end
	escapeShown = true

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
	endingTitle.Size = UDim2.new(0.9, 0, 0, 82)
	endingTitle.BackgroundTransparency = 1
	endingTitle.Text = "第1層 脱出"
	endingTitle.TextColor3 = Color3.fromRGB(230, 209, 197)
	endingTitle.TextTransparency = 1
	endingTitle.Font = Enum.Font.GothamBlack
	endingTitle.TextScaled = true
	endingTitle.ZIndex = 31
	endingTitle.Parent = ending

	local endingSub = Instance.new("TextLabel")
	endingSub.AnchorPoint = Vector2.new(0.5, 0)
	endingSub.Position = UDim2.new(0.5, 0, 0.54, 0)
	endingSub.Size = UDim2.new(0.86, 0, 0, 70)
	endingSub.BackgroundTransparency = 1
	endingSub.Text = "BLACK GATEを突破した\n次の層はまだ閉ざされている"
	endingSub.TextColor3 = Color3.fromRGB(177, 88, 66)
	endingSub.TextTransparency = 1
	endingSub.Font = Enum.Font.GothamBold
	endingSub.TextSize = 19
	endingSub.TextWrapped = true
	endingSub.ZIndex = 31
	endingSub.Parent = ending

	TweenService:Create(ending, TweenInfo.new(0.8), {BackgroundTransparency = 0.08}):Play()
	TweenService:Create(endingTitle, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
	TweenService:Create(endingSub, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
end

local guideFolder = workspace:FindFirstChild("HellAscentLocalGuides")
if guideFolder then
	guideFolder:Destroy()
end

guideFolder = Instance.new("Folder")
guideFolder.Name = "HellAscentLocalGuides"
guideFolder.Parent = workspace

for _, sealInfo in ipairs(Config.Seals) do
	local anchor = Instance.new("Part")
	anchor.Name = "Guide_" .. sealInfo.id
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = sealInfo.position + Vector3.new(0, 10, 0)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Parent = guideFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Marker"
	billboard.Adornee = anchor
	billboard.Size = UDim2.fromOffset(150, 42)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 260
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(17, 12, 13)
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.Text = "◆ 封印"
	label.TextColor3 = Color3.fromRGB(255, 132, 82)
	label.TextStrokeTransparency = 0.6
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	guideMarkers[sealInfo.id] = {
		anchor = anchor,
		billboard = billboard,
		label = label,
		info = sealInfo,
	}
end

local function refreshRunStatus()
	local broken = player:GetAttribute("SealsBroken") or 0
	local total = player:GetAttribute("TotalSeals") or #Config.Seals
	sealsLabel.Text = string.format("魂の封印  %d / %d", broken, total)

	if player:GetAttribute("GateOpen") then
		sealsLabel.TextColor3 = Color3.fromRGB(255, 111, 60)
	else
		sealsLabel.TextColor3 = Color3.fromRGB(222, 174, 145)
	end

	for id, marker in pairs(guideMarkers) do
		marker.billboard.Enabled = not player:GetAttribute("GateOpen") and not brokenSeals[id]
	end
end

local function directionArrow(fromPosition, targetPosition)
	local camera = workspace.CurrentCamera
	if not camera then
		return "•"
	end

	local delta = targetPosition - fromPosition
	local flat = Vector3.new(delta.X, 0, delta.Z)
	if flat.Magnitude < 1 then
		return "◆"
	end

	flat = flat.Unit
	local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)

	if look.Magnitude < 0.1 or right.Magnitude < 0.1 then
		return "•"
	end

	look = look.Unit
	right = right.Unit

	local forwardDot = flat:Dot(look)
	local rightDot = flat:Dot(right)

	if forwardDot > 0.62 then
		return "↑"
	elseif forwardDot < -0.62 then
		return "↓"
	elseif rightDot >= 0 then
		return "→"
	else
		return "←"
	end
end

local function getNavigationTarget(rootPosition)
	if player:GetAttribute("GateOpen") then
		return Config.ExitPosition, "BLACK GATE"
	end

	local bestInfo = nil
	local bestDistance = math.huge

	for _, sealInfo in ipairs(Config.Seals) do
		if not brokenSeals[sealInfo.id] then
			local distance = (sealInfo.position - rootPosition).Magnitude
			if distance < bestDistance then
				bestInfo = sealInfo
				bestDistance = distance
			end
		end
	end

	if bestInfo then
		return bestInfo.position, "次の封印"
	end

	return Config.ExitPosition, "BLACK GATE"
end

local function updateNavigation()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local targetPosition, targetName = getNavigationTarget(root.Position)
	local distance = (targetPosition - root.Position).Magnitude
	local arrow = directionArrow(root.Position, targetPosition)
	local text = string.format("%s  %s  %dm", targetName, arrow, math.floor(distance + 0.5))

	local world = workspace:FindFirstChild("HellAscentWorld")
	local warden = world and world:FindFirstChild("TheWarden")
	local wardenRoot = warden and warden:FindFirstChild("HumanoidRootPart")

	if wardenRoot and (player:GetAttribute("SealsBroken") or 0) > 0 then
		local wardenDistance = (wardenRoot.Position - root.Position).Magnitude
		if wardenDistance <= 65 then
			text = string.format("⚠ WARDEN %dm   |   %s %s %dm",
				math.floor(wardenDistance + 0.5),
				targetName,
				arrow,
				math.floor(distance + 0.5)
			)
		end
	end

	navLabel.Text = text

	for id, marker in pairs(guideMarkers) do
		if marker.billboard.Enabled then
			local markerDistance = (marker.info.position - root.Position).Magnitude
			marker.label.Text = string.format("◆ 封印  %dm", math.floor(markerDistance + 0.5))
		end
	end
end

event.OnClientEvent:Connect(function(kind, payload)
	if kind == "checkpoint" then
		showToast("復活地点: " .. string.upper(payload))
	elseif kind == "sealBroken" then
		if payload.id then
			brokenSeals[payload.id] = true
		end
		showToast(string.format("封印を破壊  %d / %d", payload.count, payload.total))
		refreshRunStatus()
	elseif kind == "sealAlreadyBroken" then
		showToast("この封印はすでに壊れている")
	elseif kind == "wardenAwakened" then
		showToast("門番が目を覚ました")
	elseif kind == "wardenHunting" then
		showToast("THE WARDEN が追ってくる")
	elseif kind == "wardenUnbound" then
		showToast("門番が解き放たれた。走れ")
	elseif kind == "wardenStrike" then
		flashDamage()
		showToast("WARDENの攻撃を受けた")
	elseif kind == "gateOpen" then
		showToast("BLACK GATEが開いた。門へ向かえ")
		refreshRunStatus()
	elseif kind == "gateLocked" then
		showToast(string.format("封印が足りない  %d / %d", payload.count, payload.total))
	elseif kind == "deathPenalty" then
		showToast(string.format("死亡: -%d秒  /  復活後%d秒は追跡されない", payload.seconds, Config.RespawnGraceSeconds))
	elseif kind == "expired" then
		showToast("魂が尽きた。最初から再挑戦")
	elseif kind == "runStart" then
		brokenSeals = {}
		escapeShown = false
		refreshRunStatus()
	elseif kind == "escaped" then
		showEscape()
	end
end)

for _, attributeName in ipairs({"SealsBroken", "TotalSeals", "GateOpen"}) do
	player:GetAttributeChangedSignal(attributeName):Connect(refreshRunStatus)
end

refreshRunStatus()

RunService.RenderStepped:Connect(function()
	local deadline = player:GetAttribute("RunDeadline")
	if deadline then
		local remaining = deadline - workspace:GetServerTimeNow()
		timerLabel.Text = "残り  " .. formatTime(remaining)

		if remaining <= 60 then
			timerLabel.TextColor3 = Color3.fromRGB(255, 73, 47)
		elseif remaining <= 180 then
			timerLabel.TextColor3 = Color3.fromRGB(235, 128, 72)
		else
			timerLabel.TextColor3 = Color3.fromRGB(222, 174, 145)
		end
	end

	local now = os.clock()
	if now - lastGuideUpdate >= 0.12 then
		lastGuideUpdate = now
		updateNavigation()
	end
end)

task.delay(1.35, function()
	TweenService:Create(intro, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(introTitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(introSub, TweenInfo.new(0.5), {TextTransparency = 1}):Play()

	task.delay(0.55, function()
		intro:Destroy()
	end)
end)
