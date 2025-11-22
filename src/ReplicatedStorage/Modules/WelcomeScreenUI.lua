-- WelcomeScreenUI.lua
-- Shared UI creator for the welcome/variant selection screen

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local SnakeVariants = require(ReplicatedStorage.Modules.SnakeVariants)
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GameEvent")

local WelcomeScreenUI = {}
local _created = false

local function ensurePlayerGui()
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then
		pg = Instance.new("PlayerGui")
		pg.ResetOnSpawn = false
		pg.Parent = player
	end
	return pg
end

function WelcomeScreenUI.Show()
	if _created then
		return
	end
	_created = true

	local playerGui = ensurePlayerGui()

	-- Avoid duplicate screen
	if playerGui:FindFirstChild("WelcomeScreen") then
		return
	end

	local selectedVariantId = "classic"

	local function createWelcomeScreen()
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "WelcomeScreen"
		screenGui.ResetOnSpawn = false
		screenGui.DisplayOrder = 100
		screenGui.Parent = playerGui

		local background = Instance.new("Frame")
		background.Name = "Background"
		background.Size = UDim2.new(1, 0, 1, 0)
		background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		background.BackgroundTransparency = 0.1
		background.BorderSizePixel = 0
		background.Parent = screenGui

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(0, 600, 0, 80)
		title.Position = UDim2.new(0.5, -300, 0.05, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.Text = "SLITHER SIMULATOR"
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextSize = 48
		title.TextStrokeTransparency = 0.5
		title.Parent = screenGui

		local subtitle = Instance.new("TextLabel")
		subtitle.Name = "Subtitle"
		subtitle.Size = UDim2.new(0, 600, 0, 40)
		subtitle.Position = UDim2.new(0.5, -300, 0.12, 0)
		subtitle.BackgroundTransparency = 1
		subtitle.Font = Enum.Font.Gotham
		subtitle.Text = "Choose Your Snake"
		subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
		subtitle.TextSize = 24
		subtitle.Parent = screenGui
	
		-- Map Selection Section
		local mapTitle = Instance.new("TextLabel")
		mapTitle.Name = "MapTitle"
		mapTitle.Size = UDim2.new(0, 600, 0, 25)
		mapTitle.Position = UDim2.new(0.5, -300, 0.62, 0)
		mapTitle.BackgroundTransparency = 1
		mapTitle.Font = Enum.Font.GothamBold
		mapTitle.Text = "Choose Your Arena"
		mapTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
		mapTitle.TextSize = 18
		mapTitle.Parent = screenGui
	
		local selectedMapName = "Classic"
		local MapConfig = require(ReplicatedStorage.Modules.MapConfig)
		local mapButtons = {}
	
		local mapContainer = Instance.new("Frame")
		mapContainer.Name = "MapContainer"
		mapContainer.Size = UDim2.new(0, 600, 0, 50)
		mapContainer.Position = UDim2.new(0.5, -300, 0.66, 0)
		mapContainer.BackgroundTransparency = 1
		mapContainer.Parent = screenGui
	
		local mapLayout = Instance.new("UIListLayout")
		mapLayout.FillDirection = Enum.FillDirection.Horizontal
		mapLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		mapLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		mapLayout.Padding = UDim.new(0, 15)
		mapLayout.Parent = mapContainer
	
		for mapName, mapData in pairs(MapConfig.Maps) do
			local mapButton = Instance.new("TextButton")
			mapButton.Name = mapName .. "Button"
			mapButton.Size = UDim2.new(0, 180, 0, 50)
			mapButton.BackgroundColor3 = (mapName == selectedMapName) and Color3.fromRGB(80, 80, 100) or Color3.fromRGB(50, 50, 60)
			mapButton.BorderSizePixel = 0
			mapButton.Font = Enum.Font.GothamBold
			mapButton.Text = mapData.Name
			mapButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			mapButton.TextSize = 16
			mapButton.Parent = mapContainer
		
			local mapCorner = Instance.new("UICorner")
			mapCorner.CornerRadius = UDim.new(0, 8)
			mapCorner.Parent = mapButton
		
			mapButtons[mapName] = mapButton
		
			mapButton.MouseButton1Click:Connect(function()
				selectedMapName = mapName
				-- Update all button colors
				for name, btn in pairs(mapButtons) do
					btn.BackgroundColor3 = (name == selectedMapName) and Color3.fromRGB(80, 80, 100) or Color3.fromRGB(50, 50, 60)
				end
			end)
		end

		local gridContainer = Instance.new("Frame")
		gridContainer.Name = "GridContainer"
		gridContainer.Size = UDim2.new(0, 900, 0, 320)
		gridContainer.Position = UDim2.new(0.5, -450, 0.2, 0)
		gridContainer.BackgroundTransparency = 1
		gridContainer.Parent = screenGui

		local gridLayout = Instance.new("UIGridLayout")
		gridLayout.CellSize = UDim2.new(0, 140, 0, 150)
		gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
		gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		gridLayout.Parent = gridContainer

		local unlocked = SnakeVariants.GetUnlockedVariants()
		for _, variant in ipairs(unlocked) do
			local card = Instance.new("Frame")
			card.Name = "Card_" .. variant.id
			card.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			card.BorderSizePixel = 0
			card.Parent = gridContainer

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = card

			local previewContainer = Instance.new("Frame")
			previewContainer.Name = "PreviewContainer"
			previewContainer.Size = UDim2.new(1, -20, 0.5, -10)
			previewContainer.Position = UDim2.new(0, 10, 0, 10)
			previewContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			previewContainer.BorderSizePixel = 0
			previewContainer.Parent = card

			local previewCorner = Instance.new("UICorner")
			previewCorner.CornerRadius = UDim.new(0, 6)
			previewCorner.Parent = previewContainer

			local headPreview = Instance.new("Frame")
			headPreview.Name = "HeadPreview"
			headPreview.Size = UDim2.new(0, 40, 0, 40)
			headPreview.Position = UDim2.new(0.5, -20, 0.5, -20)
			headPreview.BackgroundColor3 = variant.color
			headPreview.BorderSizePixel = 0
			headPreview.Parent = previewContainer

			if variant.headShape == "Ball" then
				local headCorner = Instance.new("UICorner")
				headCorner.CornerRadius = UDim.new(1, 0)
				headCorner.Parent = headPreview
			end

			for i = 1, 3 do
				local segment = Instance.new("Frame")
				segment.Name = "Segment" .. i
				segment.Size = UDim2.new(0, 30, 0, 30)
				segment.Position = UDim2.new(0.5, -15 - (i * 25), 0.5, -15)
				segment.BackgroundColor3 = variant.color
				segment.BorderSizePixel = 0
				segment.Parent = previewContainer

				if variant.bodyShape == "Ball" then
					local segmentCorner = Instance.new("UICorner")
					segmentCorner.CornerRadius = UDim.new(1, 0)
					segmentCorner.Parent = segment
				end
			end

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "NameLabel"
			nameLabel.Size = UDim2.new(1, -20, 0, 30)
			nameLabel.Position = UDim2.new(0, 10, 0.55, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Text = variant.name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 14
			nameLabel.TextScaled = true
			nameLabel.TextWrapped = true
			nameLabel.Parent = card

			local descLabel = Instance.new("TextLabel")
			descLabel.Name = "DescLabel"
			descLabel.Size = UDim2.new(1, -20, 0, 25)
			descLabel.Position = UDim2.new(0, 10, 0.7, 0)
			descLabel.BackgroundTransparency = 1
			descLabel.Font = Enum.Font.Gotham
			descLabel.Text = variant.description
			descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
			descLabel.TextSize = 11
			descLabel.TextWrapped = true
			descLabel.Parent = card

			local selectedIndicator = Instance.new("Frame")
			selectedIndicator.Name = "SelectedIndicator"
			selectedIndicator.Size = UDim2.new(1, 4, 1, 4)
			selectedIndicator.Position = UDim2.new(0, -2, 0, -2)
			selectedIndicator.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
			selectedIndicator.BorderSizePixel = 0
			selectedIndicator.Visible = (variant.id == selectedVariantId)
			selectedIndicator.ZIndex = 0
			selectedIndicator.Parent = card

			local selectedCorner = Instance.new("UICorner")
			selectedCorner.CornerRadius = UDim.new(0, 10)
			selectedCorner.Parent = selectedIndicator

			local button = Instance.new("TextButton")
			button.Name = "SelectButton"
			button.Size = UDim2.new(1, 0, 1, 0)
			button.BackgroundTransparency = 1
			button.Text = ""
			button.Parent = card

			button.MouseButton1Click:Connect(function()
				selectedVariantId = variant.id
				for _, otherCard in ipairs(gridContainer:GetChildren()) do
					if otherCard:IsA("Frame") and otherCard.Name:match("Card_") then
						local indicator = otherCard:FindFirstChild("SelectedIndicator")
						if indicator then
							indicator.Visible = (otherCard.Name == "Card_" .. variant.id)
						end
					end
				end
			end)
		end

		local playButton = Instance.new("TextButton")
		playButton.Name = "PlayButton"
		playButton.Size = UDim2.new(0, 300, 0, 55)
		playButton.Position = UDim2.new(0.5, -150, 0.75, 0)
		playButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		playButton.BorderSizePixel = 0
		playButton.Font = Enum.Font.GothamBold
		playButton.Text = "PLAY"
		playButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		playButton.TextSize = 32
		playButton.Parent = screenGui

		local playCorner = Instance.new("UICorner")
		playCorner.CornerRadius = UDim.new(0, 12)
		playCorner.Parent = playButton

		playButton.MouseButton1Click:Connect(function()
			remoteEvent:FireServer("SelectSnakeVariant", selectedVariantId)
			remoteEvent:FireServer("ChangeMap", selectedMapName)
			screenGui:Destroy()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
	end

	local ok, err = pcall(createWelcomeScreen)
	if not ok then
		warn("[WelcomeScreen] Failed to create screen:", err)
		remoteEvent:FireServer("SelectSnakeVariant", selectedVariantId)
	end

	print("[WelcomeScreen] Initialized")
end

return WelcomeScreenUI
