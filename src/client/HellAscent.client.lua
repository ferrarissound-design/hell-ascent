local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local event = ReplicatedStorage:WaitForChild("HellAscentRemotes"):WaitForChild("HellAscentEvent")

local oldGui = playerGui:FindFirstChild("HellAscentUI")
if oldGui then
	oldGui:Destroy()
end

local brokenSeals = {}
local guideMarkers = {}
local lastGuideUpdate = 0
local escapeShown = false
local endingFrame = nil
local respawnSafeUntil = 0
local gateMarker = nil
local toastSerial = 0
local activeToastTween = nil
local activeToastFade = nil
local hellWorld = nil
local currentEscalationStage = -1
local stageBannerSerial = 0
local wardenSeenThisRun = false
local lastWardenObservedReport = 0
local lastWardenObservedState = false
local finalRunActive = false
local tutorialShown = false
local tutorialRunToken = 0

local gui = Instance.new("ScreenGui")
gui.Name = "HellAscentUI"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.Parent = playerGui

local oldEscalationColor = Lighting:FindFirstChild("HellEscalationColor")
if oldEscalationColor then
	oldEscalationColor:Destroy()
end

local oldEscalationBloom = Lighting:FindFirstChild("HellEscalationBloom")
if oldEscalationBloom then
	oldEscalationBloom:Destroy()
end

local escalationColor = Instance.new("ColorCorrectionEffect")
escalationColor.Name = "HellEscalationColor"
escalationColor.Brightness = 0
escalationColor.Contrast = 0
escalationColor.Saturation = 0
escalationColor.TintColor = Color3.fromRGB(255, 255, 255)
escalationColor.Parent = Lighting

local escalationBloom = Instance.new("BloomEffect")
escalationBloom.Name = "HellEscalationBloom"
escalationBloom.Intensity = 0.05
escalationBloom.Size = 28
escalationBloom.Threshold = 1.4
escalationBloom.Parent = Lighting

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

local finalRunPanel = Instance.new("Frame")
finalRunPanel.AnchorPoint = Vector2.new(0.5, 0)
finalRunPanel.Position = UDim2.new(0.5, 0, 0, 103)
finalRunPanel.Size = UDim2.new(0.88, 0, 0, 58)
finalRunPanel.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
finalRunPanel.BackgroundTransparency = 0.12
finalRunPanel.BorderSizePixel = 0
finalRunPanel.Visible = false
finalRunPanel.ZIndex = 12
finalRunPanel.Parent = gui

local finalRunCorner = Instance.new("UICorner")
finalRunCorner.CornerRadius = UDim.new(0, 10)
finalRunCorner.Parent = finalRunPanel

local finalRunLabel = Instance.new("TextLabel")
finalRunLabel.Size = UDim2.fromScale(1, 1)
finalRunLabel.BackgroundTransparency = 1
finalRunLabel.Text = "FINAL RUN"
finalRunLabel.TextColor3 = Color3.fromRGB(255, 112, 62)
finalRunLabel.TextStrokeTransparency = 0.7
finalRunLabel.Font = Enum.Font.GothamBlack
finalRunLabel.TextSize = 15
finalRunLabel.TextWrapped = true
finalRunLabel.ZIndex = 13
finalRunLabel.Parent = finalRunPanel

local staminaPanel = Instance.new("Frame")
staminaPanel.AnchorPoint = Vector2.new(0.5, 1)
staminaPanel.Position = UDim2.new(0.5, 0, 1, -22)
staminaPanel.Size = UDim2.fromOffset(220, 28)
staminaPanel.BackgroundColor3 = Color3.fromRGB(13, 10, 11)
staminaPanel.BackgroundTransparency = 0.18
staminaPanel.BorderSizePixel = 0
staminaPanel.Visible = false
staminaPanel.ZIndex = 12
staminaPanel.Parent = gui

local staminaCorner = Instance.new("UICorner")
staminaCorner.CornerRadius = UDim.new(0, 8)
staminaCorner.Parent = staminaPanel

local staminaBarBack = Instance.new("Frame")
staminaBarBack.Position = UDim2.fromOffset(66, 8)
staminaBarBack.Size = UDim2.new(1, -76, 0, 12)
staminaBarBack.BackgroundColor3 = Color3.fromRGB(48, 37, 36)
staminaBarBack.BackgroundTransparency = 0.12
staminaBarBack.BorderSizePixel = 0
staminaBarBack.ZIndex = 13
staminaBarBack.Parent = staminaPanel

local staminaBarCorner = Instance.new("UICorner")
staminaBarCorner.CornerRadius = UDim.new(1, 0)
staminaBarCorner.Parent = staminaBarBack

local staminaFill = Instance.new("Frame")
staminaFill.Size = UDim2.fromScale(1, 1)
staminaFill.BackgroundColor3 = Color3.fromRGB(223, 128, 82)
staminaFill.BorderSizePixel = 0
staminaFill.ZIndex = 14
staminaFill.Parent = staminaBarBack

local staminaFillCorner = Instance.new("UICorner")
staminaFillCorner.CornerRadius = UDim.new(1, 0)
staminaFillCorner.Parent = staminaFill

local staminaText = Instance.new("TextLabel")
staminaText.Position = UDim2.fromOffset(8, 0)
staminaText.Size = UDim2.fromOffset(54, 28)
staminaText.BackgroundTransparency = 1
staminaText.Text = "STAMINA"
staminaText.TextColor3 = Color3.fromRGB(208, 184, 170)
staminaText.Font = Enum.Font.GothamBold
staminaText.TextSize = 10
staminaText.ZIndex = 14
staminaText.Parent = staminaPanel

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

local hellPressure = Instance.new("Frame")
hellPressure.Size = UDim2.fromScale(1, 1)
hellPressure.BackgroundColor3 = Color3.fromRGB(120, 16, 8)
hellPressure.BackgroundTransparency = 1
hellPressure.BorderSizePixel = 0
hellPressure.ZIndex = 5
hellPressure.Parent = gui

local wardenPressure = Instance.new("Frame")
wardenPressure.Size = UDim2.fromScale(1, 1)
wardenPressure.BackgroundColor3 = Color3.fromRGB(92, 7, 5)
wardenPressure.BackgroundTransparency = 1
wardenPressure.BorderSizePixel = 0
wardenPressure.ZIndex = 6
wardenPressure.Parent = gui

local stageBanner = Instance.new("TextLabel")
stageBanner.AnchorPoint = Vector2.new(0.5, 0.5)
stageBanner.Position = UDim2.new(0.5, 0, 0.39, 0)
stageBanner.Size = UDim2.new(0.82, 0, 0, 74)
stageBanner.BackgroundTransparency = 1
stageBanner.Text = ""
stageBanner.TextColor3 = Color3.fromRGB(240, 206, 190)
stageBanner.TextStrokeColor3 = Color3.fromRGB(40, 8, 6)
stageBanner.TextStrokeTransparency = 1
stageBanner.TextTransparency = 1
stageBanner.Font = Enum.Font.GothamBlack
stageBanner.TextScaled = true
stageBanner.ZIndex = 16
stageBanner.Parent = gui

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

local function setSprintRequested(active)
	event:FireServer("sprintState", active == true)
end

local function sprintAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		setSprintRequested(true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		setSprintRequested(false)
	end

	return Enum.ContextActionResult.Sink
end

ContextActionService:UnbindAction("HellSprint")
ContextActionService:BindAction(
	"HellSprint",
	sprintAction,
	true,
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.RightShift,
	Enum.KeyCode.ButtonL3
)
ContextActionService:SetTitle("HellSprint", "走る")
ContextActionService:SetPosition("HellSprint", UDim2.new(1, -172, 1, -138))

local function setSprintControlVisible(visible)
	local button = ContextActionService:GetButton("HellSprint")
	if button then
		button.Visible = visible == true
	end
end

local function showToast(text)
	toastSerial += 1
	local serial = toastSerial

	if activeToastTween then
		activeToastTween:Cancel()
	end
	if activeToastFade then
		activeToastFade:Cancel()
	end

	toast.Text = text
	activeToastTween = TweenService:Create(
		toast,
		TweenInfo.new(0.18),
		{BackgroundTransparency = 0.18, TextTransparency = 0, TextStrokeTransparency = 0.65}
	)
	activeToastTween:Play()

	task.delay(2.0, function()
		if serial ~= toastSerial then
			return
		end

		activeToastFade = TweenService:Create(
			toast,
			TweenInfo.new(0.35),
			{BackgroundTransparency = 1, TextTransparency = 1, TextStrokeTransparency = 1}
		)
		activeToastFade:Play()
	end)
end

local function startFirstRunTutorial()
	if tutorialShown then
		return
	end
	tutorialShown = true
	local token = tutorialRunToken

	task.delay(1.8, function()
		if token == tutorialRunToken and not escapeShown and player:GetAttribute("RunExpired") ~= true then
			showToast("目的: 3つの封印を壊して BLACK GATEへ")
		end
	end)

	task.delay(4.2, function()
		if token == tutorialRunToken and not escapeShown and player:GetAttribute("RunExpired") ~= true then
			showToast("走る: Shift / 画面の「走る」 / L3")
		end
	end)

	task.delay(6.6, function()
		if token == tutorialRunToken and not escapeShown and player:GetAttribute("RunExpired") ~= true then
			showToast(string.format("死亡すると残り時間 -%d秒", Config.DeathPenaltySeconds))
		end
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

local function showEscalationBanner(text, isFinal)
	stageBannerSerial += 1
	local serial = stageBannerSerial

	stageBanner.Text = text
	stageBanner.TextColor3 = isFinal
		and Color3.fromRGB(255, 104, 62)
		or Color3.fromRGB(240, 206, 190)
	stageBanner.TextTransparency = 1
	stageBanner.TextStrokeTransparency = 1

	TweenService:Create(
		stageBanner,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0, TextStrokeTransparency = 0.5}
	):Play()

	task.delay(isFinal and 1.3 or 1.0, function()
		if serial ~= stageBannerSerial then
			return
		end

		TweenService:Create(
			stageBanner,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1, TextStrokeTransparency = 1}
		):Play()
	end)
end

local escalationProfiles = {
	[0] = {
		brightness = 0,
		contrast = 0,
		saturation = 0,
		tint = Color3.fromRGB(255, 255, 255),
		bloom = 0.05,
		fogStart = 90,
		fogEnd = 620,
		pressure = 1,
		emberBrightness = 2.6,
		emberRange = 38,
	},
	[1] = {
		brightness = -0.01,
		contrast = 0.05,
		saturation = -0.03,
		tint = Color3.fromRGB(255, 226, 216),
		bloom = 0.12,
		fogStart = 82,
		fogEnd = 570,
		pressure = 0.985,
		emberBrightness = 2.9,
		emberRange = 42,
	},
	[2] = {
		brightness = -0.015,
		contrast = 0.10,
		saturation = -0.06,
		tint = Color3.fromRGB(255, 196, 178),
		bloom = 0.22,
		fogStart = 72,
		fogEnd = 510,
		pressure = 0.972,
		emberBrightness = 3.4,
		emberRange = 47,
	},
	[3] = {
		brightness = 0.005,
		contrast = 0.16,
		saturation = -0.08,
		tint = Color3.fromRGB(255, 166, 145),
		bloom = 0.38,
		fogStart = 60,
		fogEnd = 445,
		pressure = 0.955,
		emberBrightness = 4.3,
		emberRange = 56,
	},
}

local function applyEscalationStage(stage, announce)
	stage = math.clamp(stage or 0, 0, 3)
	local previousStage = currentEscalationStage
	if stage == currentEscalationStage then
		if announce then
			if stage == 1 then
				showEscalationBanner("HELL STIRS", false)
			elseif stage == 2 then
				showEscalationBanner("THE VEIL THINS", false)
			elseif stage == 3 then
				showEscalationBanner("RUN", true)
			end
		end
		return
	end
	currentEscalationStage = stage

	local profile = escalationProfiles[stage]

	TweenService:Create(
		escalationColor,
		TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Brightness = profile.brightness,
			Contrast = profile.contrast,
			Saturation = profile.saturation,
			TintColor = profile.tint,
		}
	):Play()

	TweenService:Create(
		escalationBloom,
		TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Intensity = profile.bloom}
	):Play()

	TweenService:Create(
		Lighting,
		TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			FogStart = profile.fogStart,
			FogEnd = profile.fogEnd,
		}
	):Play()

	TweenService:Create(
		hellPressure,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = profile.pressure}
	):Play()

	if hellWorld then
		for _, descendant in ipairs(hellWorld:GetDescendants()) do
			if descendant:IsA("PointLight")
				and descendant.Parent
				and descendant.Parent.Name == "RouteEmber"
			then
				TweenService:Create(
					descendant,
					TweenInfo.new(0.8),
					{
						Brightness = profile.emberBrightness,
						Range = profile.emberRange,
					}
				):Play()
			end
		end
	end

	if announce and stage > previousStage then
		if stage == 1 then
			showEscalationBanner("HELL STIRS", false)
		elseif stage == 2 then
			showEscalationBanner("THE VEIL THINS", false)
		elseif stage == 3 then
			showEscalationBanner("RUN", true)
		end
	end
end

local function showEscape(payload)
	if escapeShown then
		return
	end
	escapeShown = true

	if endingFrame then
		endingFrame:Destroy()
		endingFrame = nil
	end

	local ending = Instance.new("Frame")
	ending.Name = "EscapeEnding"
	ending.Size = UDim2.fromScale(1, 1)
	ending.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ending.BackgroundTransparency = 1
	ending.BorderSizePixel = 0
	ending.ZIndex = 30
	ending.Parent = gui
	endingFrame = ending

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
	endingSub.Position = UDim2.new(0.5, 0, 0.53, 0)
	endingSub.Size = UDim2.new(0.86, 0, 0, 92)
	endingSub.BackgroundTransparency = 1

	local clearSeconds = payload and payload.clearSeconds or 0
	local bestSeconds = payload and payload.bestSeconds or clearSeconds
	local deaths = payload and payload.deaths or 0
	local escapes = payload and payload.escapes or 1
	local newBest = payload and payload.newBest == true
	local bestLine

	if newBest and escapes > 1 then
		bestLine = string.format("NEW BEST  %s   /   脱出 %d回", formatTime(bestSeconds), escapes)
	else
		bestLine = string.format("BEST  %s   /   脱出 %d回", formatTime(bestSeconds), escapes)
	end

	endingSub.Text = string.format(
		"クリア %s   /   死亡 %d回\n%s",
		formatTime(clearSeconds),
		deaths,
		bestLine
	)
	endingSub.TextColor3 = newBest and escapes > 1
		and Color3.fromRGB(232, 128, 82)
		or Color3.fromRGB(177, 88, 66)
	endingSub.TextTransparency = 1
	endingSub.Font = Enum.Font.GothamBold
	endingSub.TextSize = 18
	endingSub.TextWrapped = true
	endingSub.ZIndex = 31
	endingSub.Parent = ending

	local retry = Instance.new("TextButton")
	retry.AnchorPoint = Vector2.new(0.5, 0)
	retry.Position = UDim2.new(0.5, 0, 0.69, 0)
	retry.Size = UDim2.new(0, 220, 0, 48)
	retry.BackgroundColor3 = Color3.fromRGB(54, 32, 29)
	retry.BackgroundTransparency = 0.08
	retry.BorderSizePixel = 0
	retry.Text = "もう一度 / RETRY"
	retry.TextColor3 = Color3.fromRGB(235, 211, 197)
	retry.Font = Enum.Font.GothamBold
	retry.TextSize = 17
	retry.AutoButtonColor = true
	retry.ZIndex = 31
	retry.Parent = ending

	local retryCorner = Instance.new("UICorner")
	retryCorner.CornerRadius = UDim.new(0, 10)
	retryCorner.Parent = retry

	retry.Activated:Connect(function()
		retry.Active = false
		retry.AutoButtonColor = false
		retry.Text = "再挑戦を開始..."
		event:FireServer("restartRun")
	end)

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

hellWorld = workspace:WaitForChild("HellAscentWorld")
local gateHighlight = nil

local function applyGateVisualState(isOpen)
	local gate = hellWorld:FindFirstChild("BlackGate")
	if not gate then
		return
	end

	local veil = gate:FindFirstChild("ExitVeil")
	if veil and veil:IsA("BasePart") then
		veil.LocalTransparencyModifier = isOpen and 0.34 or 0
	end

	if isOpen then
		if not gateHighlight or not gateHighlight.Parent then
			gateHighlight = Instance.new("Highlight")
			gateHighlight.Name = "LocalGateOpenHighlight"
			gateHighlight.Adornee = gate
			gateHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			gateHighlight.FillTransparency = 1
			gateHighlight.OutlineTransparency = 0.18
			gateHighlight.OutlineColor = Color3.fromRGB(255, 92, 48)
			gateHighlight.Parent = gate
		end
		gateHighlight.Enabled = true
	elseif gateHighlight then
		gateHighlight.Enabled = false
	end
end

local function applySealVisualState(sealId, isBroken)
	local sealModel = hellWorld:FindFirstChild("SoulSeal_" .. sealId)
	if not sealModel then
		return
	end

	for _, descendant in ipairs(sealModel:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Enabled = not isBroken
		elseif descendant:IsA("PointLight") then
			descendant.Enabled = not isBroken
		elseif descendant:IsA("BasePart") then
			if isBroken then
				descendant.LocalTransparencyModifier = (descendant.Name == "Pedestal") and 0.18 or 0.68
			else
				descendant.LocalTransparencyModifier = 0
			end
		end
	end
end

local function resetSealVisuals()
	for _, sealInfo in ipairs(Config.Seals) do
		applySealVisualState(sealInfo.id, false)
	end
end

local function rebuildBrokenSealsFromAttributes()
	brokenSeals = {}

	for _, sealInfo in ipairs(Config.Seals) do
		local isBroken = player:GetAttribute("Seal_" .. sealInfo.id) == true
		if isBroken then
			brokenSeals[sealInfo.id] = true
		end
		applySealVisualState(sealInfo.id, isBroken)
	end
end

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

do
	local gateAnchor = Instance.new("Part")
	gateAnchor.Name = "Guide_BLACK_GATE"
	gateAnchor.Size = Vector3.new(0.2, 0.2, 0.2)
	gateAnchor.Position = Config.ExitPosition + Vector3.new(0, 15, 0)
	gateAnchor.Anchored = true
	gateAnchor.CanCollide = false
	gateAnchor.CanTouch = false
	gateAnchor.CanQuery = false
	gateAnchor.Transparency = 1
	gateAnchor.Parent = guideFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GateMarker"
	billboard.Adornee = gateAnchor
	billboard.Size = UDim2.fromOffset(180, 44)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 360
	billboard.Enabled = false
	billboard.Parent = gateAnchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(17, 12, 13)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Text = "◆ BLACK GATE"
	label.TextColor3 = Color3.fromRGB(255, 112, 62)
	label.TextStrokeTransparency = 0.55
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 15
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	gateMarker = {
		anchor = gateAnchor,
		billboard = billboard,
		label = label,
	}
end

rebuildBrokenSealsFromAttributes()

local function refreshRunStatus()
	local broken = player:GetAttribute("SealsBroken") or 0
	local total = player:GetAttribute("TotalSeals") or #Config.Seals
	sealsLabel.Text = string.format("魂の封印  %d / %d", broken, total)
	applyEscalationStage(broken, false)

	if player:GetAttribute("GateOpen") then
		sealsLabel.TextColor3 = Color3.fromRGB(255, 111, 60)
	else
		sealsLabel.TextColor3 = Color3.fromRGB(222, 174, 145)
	end

	for id, marker in pairs(guideMarkers) do
		marker.billboard.Enabled = not player:GetAttribute("GateOpen") and not brokenSeals[id]
	end

	local gateOpen = player:GetAttribute("GateOpen") == true
	local runFinished = player:GetAttribute("RunExpired") == true
		or player:GetAttribute("LayerOneEscaped") == true
	finalRunActive = gateOpen and not runFinished
	finalRunPanel.Visible = finalRunActive and not escapeShown
	if gateMarker then
		gateMarker.billboard.Enabled = gateOpen and not runFinished
	end
	applyGateVisualState(gateOpen and not runFinished)
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

local function getWardenParts()
	if not hellWorld then
		return nil, nil, nil
	end

	local warden = hellWorld:FindFirstChild("TheWarden")
	local root = warden and warden:FindFirstChild("HumanoidRootPart")
	local faceSlit = warden and warden:FindFirstChild("FaceSlit")
	return warden, root, faceSlit
end

local function reportWardenObserved(observed, now, broken)
	if broken < 1 or broken > 2 then
		if lastWardenObservedState then
			event:FireServer("wardenObserved", false)
		end
		lastWardenObservedState = false
		lastWardenObservedReport = now
		return
	end

	if observed ~= lastWardenObservedState or now - lastWardenObservedReport >= 0.3 then
		lastWardenObservedState = observed
		lastWardenObservedReport = now
		event:FireServer("wardenObserved", observed)
	end
end

local function updateWardenFear(now)
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local broken = player:GetAttribute("SealsBroken") or 0
	local warden, wardenRoot, faceSlit = getWardenParts()

	if not playerRoot or not camera or not wardenRoot or broken <= 0 then
		reportWardenObserved(false, now, broken)
		wardenPressure.BackgroundTransparency = 1
		if faceSlit then
			local faceLight = faceSlit:FindFirstChildOfClass("PointLight")
			if faceLight then
				faceLight.Brightness = 2.6
				faceLight.Range = 18
			end
		end
		return
	end

	local distance = (wardenRoot.Position - playerRoot.Position).Magnitude
	local awarenessRange = Config.Warden.FearAwarenessRange or 150
	local criticalRange = Config.Warden.FearCriticalRange or 28
	local observationRange = 0

	if broken >= 1 and broken <= 2 then
		observationRange = Config.Warden.Stages[broken].DetectionRange or awarenessRange
	end

	local targetPoint = wardenRoot.Position + Vector3.new(0, 4, 0)
	local screenPoint, onScreen = camera:WorldToViewportPoint(targetPoint)
	local visible = onScreen and screenPoint.Z > 0

	if visible and warden then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.IgnoreWater = true

		local origin = camera.CFrame.Position
		local direction = targetPoint - origin
		local result = workspace:Raycast(origin, direction, raycastParams)
		if result and not result.Instance:IsDescendantOf(warden) then
			visible = false
		end
	end

	reportWardenObserved(
		visible and observationRange > 0 and distance <= observationRange,
		now,
		broken
	)

	if distance >= awarenessRange then
		wardenPressure.BackgroundTransparency = 1
		if faceSlit then
			local faceLight = faceSlit:FindFirstChildOfClass("PointLight")
			if faceLight then
				faceLight.Brightness = 2.6
				faceLight.Range = 18
			end
		end
		return
	end

	local span = math.max(1, awarenessRange - criticalRange)
	local proximity = 1 - math.clamp((distance - criticalRange) / span, 0, 1)
	local visibilityFactor = visible and 1 or 0.5
	local strength = math.clamp(proximity * visibilityFactor, 0, 1)
	local pulse = 0.5 + 0.5 * math.sin(now * (2.4 + strength * 4.2))

	wardenPressure.BackgroundTransparency = math.clamp(
		1 - (0.035 + strength * 0.11 + pulse * strength * 0.035),
		0.82,
		1
	)

	if faceSlit then
		local faceLight = faceSlit:FindFirstChildOfClass("PointLight")
		if faceLight then
			faceLight.Brightness = 2.6 + (visible and strength * 5.2 or strength * 2.0)
			faceLight.Range = 18 + strength * 12
		end
	end

	if visible
		and not wardenSeenThisRun
		and distance <= math.min(awarenessRange, 130)
	then
		wardenSeenThisRun = true
		showToast("何かがこちらを見ている")
		task.delay(1.15, function()
			if wardenSeenThisRun and (player:GetAttribute("SealsBroken") or 0) == 1 then
				showToast("奴から目を離すな")
			end
		end)
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
	local text = string.format("%s  %s  %d", targetName, arrow, math.floor(distance + 0.5))

	local warden = hellWorld and hellWorld:FindFirstChild("TheWarden")
	local wardenRoot = warden and warden:FindFirstChild("HumanoidRootPart")

	if finalRunActive then
		local gateDistance = (Config.ExitPosition - root.Position).Magnitude
		local gateArrow = directionArrow(root.Position, Config.ExitPosition)
		local wardenText = "WARDEN 不明"

		if wardenRoot then
			local wardenDistance = (wardenRoot.Position - root.Position).Magnitude
			local wardenArrow = directionArrow(root.Position, wardenRoot.Position)
			wardenText = string.format(
				"WARDEN %s %d",
				wardenArrow,
				math.floor(wardenDistance + 0.5)
			)
		end

		finalRunLabel.Text = string.format(
			"FINAL RUN\nBLACK GATE %s %d   |   %s",
			gateArrow,
			math.floor(gateDistance + 0.5),
			wardenText
		)
		text = "走れ。視線はもう効かない"
		navLabel.TextColor3 = Color3.fromRGB(255, 112, 62)
	elseif wardenRoot and (player:GetAttribute("SealsBroken") or 0) > 0 then
		local wardenDistance = (wardenRoot.Position - root.Position).Magnitude
		local wardenArrow = directionArrow(root.Position, wardenRoot.Position)
		if wardenDistance <= 25 then
			text = string.format("⚠ WARDEN %s %d   |   %s %s %d",
				wardenArrow,
				math.floor(wardenDistance + 0.5),
				targetName,
				arrow,
				math.floor(distance + 0.5)
			)
			navLabel.TextColor3 = Color3.fromRGB(255, 74, 48)
		elseif wardenDistance <= 65 then
			text = string.format("⚠ WARDEN %s %d   |   %s %s %d",
				wardenArrow,
				math.floor(wardenDistance + 0.5),
				targetName,
				arrow,
				math.floor(distance + 0.5)
			)
			navLabel.TextColor3 = Color3.fromRGB(244, 136, 78)
		else
			navLabel.TextColor3 = Color3.fromRGB(232, 118, 81)
		end
	else
		navLabel.TextColor3 = Color3.fromRGB(232, 118, 81)
	end

	local safeRemaining = respawnSafeUntil - os.clock()
	if safeRemaining > 0 then
		text = string.format("復活保護 %d秒   |   %s", math.ceil(safeRemaining), text)
		navLabel.TextColor3 = Color3.fromRGB(196, 208, 220)
	end

	navLabel.Text = text

	for id, marker in pairs(guideMarkers) do
		if marker.billboard.Enabled then
			local markerDistance = (marker.info.position - root.Position).Magnitude
			marker.label.Text = string.format("◆ 封印  %d", math.floor(markerDistance + 0.5))
		end
	end
end

event.OnClientEvent:Connect(function(kind, payload)
	if kind == "checkpoint" then
		local checkpointName = payload.name or "SOUL ANCHOR"
		showToast(string.format(
			"復活地点を更新: %s  [%d/%d]  /  HP・スタミナ回復",
			string.upper(checkpointName),
			payload.index or 0,
			payload.total or #Config.Checkpoints
		))
	elseif kind == "sealBroken" then
		tutorialRunToken += 1
		if payload.id then
			brokenSeals[payload.id] = true
			applySealVisualState(payload.id, true)
		end
		applyEscalationStage(payload.count or 0, true)
		showToast(string.format("封印を破壊  %d / %d", payload.count, payload.total))
		refreshRunStatus()
	elseif kind == "sealAlreadyBroken" then
		showToast("この封印はすでに壊れている")
	elseif kind == "wardenAwakened" then
		showToast("門番が目を覚ました")
	elseif kind == "wardenHunting" then
		showToast("見ても止まらない。視線で鈍らせろ")
	elseif kind == "wardenUnbound" then
		showToast("視線はもう効かない。BLACK GATEへ走れ")
	elseif kind == "wardenStrike" then
		flashDamage()
		showToast("WARDENの攻撃を受けた")
	elseif kind == "sprintExhausted" then
		showToast("息が切れた。スタミナを回復しろ")
	elseif kind == "voidRescue" then
		setSprintRequested(false)
		showToast("地形外からSOUL ANCHORへ救済  /  HP・スタミナ回復")
	elseif kind == "ashRiftUsed" then
		flashDamage()
		showToast(string.format("ASH RIFT使用  /  HP -%d  /  前方へ転移", payload.cost or Config.AshRift.HealthCost))
	elseif kind == "ashRiftUnavailable" then
		if payload.reason == "used" then
			showToast("ASH RIFTは1周1回だけ使える")
		elseif payload.reason == "seals" then
			showToast(string.format("封印を%d個以上壊すと使える", payload.required or Config.AshRift.MinimumSeals))
		elseif payload.reason == "health" then
			showToast(string.format("HPが足りない  /  必要HP > %d", payload.cost or Config.AshRift.HealthCost))
		else
			showToast("ASH RIFTは今使えない")
		end
	elseif kind == "finalRun" then
		finalRunActive = true
		finalRunPanel.Visible = true
		showToast(string.format(
			"FINAL RUN  /  スタミナ %d  /  BLACK GATEへ",
			math.floor((payload and payload.stamina) or Config.FinalRun.MinimumStartStamina)
		))
	elseif kind == "gateOpen" then
		refreshRunStatus()
	elseif kind == "gateLocked" then
		showToast(string.format("封印が足りない  %d / %d", payload.count, payload.total))
	elseif kind == "deathPenalty" then
		showToast(string.format("死亡: -%d秒  /  スタミナ回復  /  %d秒安全", payload.seconds, Config.RespawnGraceSeconds))
	elseif kind == "expired" then
		setSprintRequested(false)
		setSprintControlVisible(false)
		finalRunActive = false
		finalRunPanel.Visible = false
		staminaPanel.Visible = false
		showToast("魂が尽きた。最初から再挑戦")
	elseif kind == "runStart" then
		setSprintRequested(false)
		setSprintControlVisible(true)
		tutorialRunToken += 1
		brokenSeals = {}
		escapeShown = false
		finalRunActive = false
		finalRunPanel.Visible = false
		respawnSafeUntil = 0
		currentEscalationStage = -1
		wardenSeenThisRun = false
		lastWardenObservedState = false
		lastWardenObservedReport = 0
		wardenPressure.BackgroundTransparency = 1
		applyEscalationStage(0, false)
		timerLabel.Text = "準備中"
		timerLabel.TextColor3 = Color3.fromRGB(196, 208, 220)
		if endingFrame then
			endingFrame:Destroy()
			endingFrame = nil
		end
		resetSealVisuals()
		applyGateVisualState(false)
		refreshRunStatus()
	elseif kind == "runClockStarted" then
		timerLabel.Text = "残り  " .. formatTime(payload.duration or Config.RunDurationSeconds)
		timerLabel.TextColor3 = Color3.fromRGB(222, 174, 145)

		startFirstRunTutorial()
	elseif kind == "escaped" then
		setSprintRequested(false)
		setSprintControlVisible(false)
		finalRunActive = false
		finalRunPanel.Visible = false
		staminaPanel.Visible = false
		showEscape(payload)
	end
end)

for _, attributeName in ipairs({
	"SealsBroken",
	"TotalSeals",
	"GateOpen",
	"RunExpired",
	"LayerOneEscaped",
}) do
	player:GetAttributeChangedSignal(attributeName):Connect(refreshRunStatus)
end

for _, sealInfo in ipairs(Config.Seals) do
	player:GetAttributeChangedSignal("Seal_" .. sealInfo.id):Connect(function()
		rebuildBrokenSealsFromAttributes()
		refreshRunStatus()
	end)
end

rebuildBrokenSealsFromAttributes()
refreshRunStatus()
setSprintControlVisible(
	player:GetAttribute("RunExpired") ~= true
		and player:GetAttribute("LayerOneEscaped") ~= true
)

if player:GetAttribute("RunDeadline") then
	task.defer(startFirstRunTutorial)
end

player.CharacterAdded:Connect(function()
	if (player:GetAttribute("DeathsThisRun") or 0) > 0 then
		respawnSafeUntil = os.clock() + Config.RespawnGraceSeconds
		task.delay(0.45, function()
			if respawnSafeUntil > os.clock() then
				showToast(string.format("復活保護: %d秒", Config.RespawnGraceSeconds))
			end
		end)
	end
end)

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	updateWardenFear(now)

	local stamina = player:GetAttribute("SprintStamina")
	if stamina == nil then
		stamina = Config.Sprint.MaxStamina
	end
	local sprintActive = player:GetAttribute("SprintActive") == true
	local staminaRatio = math.clamp(stamina / Config.Sprint.MaxStamina, 0, 1)
	staminaFill.Size = UDim2.fromScale(staminaRatio, 1)
	local runFinished = player:GetAttribute("RunExpired") == true
		or player:GetAttribute("LayerOneEscaped") == true
	staminaPanel.Visible = not runFinished
		and (sprintActive or stamina < Config.Sprint.MaxStamina)
	staminaText.Text = sprintActive and "SPRINT" or "STAMINA"

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
	else
		timerLabel.Text = "準備中"
		timerLabel.TextColor3 = Color3.fromRGB(196, 208, 220)
	end

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
