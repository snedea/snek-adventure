-- GameInitializer.server.lua
-- Server startup script - initializes all services and wires them together

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("[GameInitializer] Starting Snek Adventure server...")

-- Load services
-- Load services
local CharacterManager = require(ServerScriptService.GameSystems.CharacterManager)
local ArenaManager = require(ServerScriptService.GameSystems.ArenaManager)
local PlayerDataManager = require(ServerScriptService.GameSystems.PlayerDataManager)
local RankService = require(ServerScriptService.GameSystems.RankService)
local ShieldManager = require(ServerScriptService.GameSystems.ShieldManager)
local FoodSpawner = require(ServerScriptService.GameSystems.FoodSpawner)
local LeaderboardService = require(ServerScriptService.GameSystems.LeaderboardService)
local SnakeManager = require(ServerScriptService.GameSystems.SnakeManager)
local ReviveService = require(ServerScriptService.GameSystems.ReviveService)

-- Initialize services in dependency order
CharacterManager:Initialize() -- Disable default characters first
local arenaOk, arenaErr = pcall(function()
	ArenaManager:Initialize() -- Create arena via Manager
end)

if not arenaOk then
	warn("[GameInitializer] ArenaManager failed to initialize:", arenaErr)
end

PlayerDataManager:Initialize()
ShieldManager:Initialize()
LeaderboardService:Initialize()
FoodSpawner:Initialize()

-- Initialize SnakeManager with dependencies
SnakeManager:Initialize({
	PlayerDataManager = PlayerDataManager,
	FoodSpawner = FoodSpawner,
	ShieldManager = ShieldManager,
	RankService = RankService,
	LeaderboardService = LeaderboardService,
})

-- Setup RemoteEvents
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GameEvent")

-- Client → Server event handlers
remoteEvent.OnServerEvent:Connect(function(player, eventType, ...)
	if eventType == "SelectSnakeVariant" then
		local variantId = ...
		-- Set the player's selected variant
		SnakeManager:SetPlayerVariant(player, variantId)
		-- Create snake with selected variant and fixed spawn shield
		SnakeManager:CreateSnake(player, 10)

	elseif eventType == "MoveSnake" then
		local direction = ...
		SnakeManager:MoveSnake(player, direction)

	elseif eventType == "ActivateBoost" then
		SnakeManager:ActivateBoost(player)

	elseif eventType == "ActivateBrake" then
		SnakeManager:ActivateBrake(player)

	elseif eventType == "AcceptRevival" then
		ReviveService:AcceptRevival(player)

	elseif eventType == "DeclineRevival" then
		ReviveService:DeclineRevival(player)

	elseif eventType == "SetCustomization" then
		local customization = ...

		-- Validate customization
		local rank = PlayerDataManager:GetRank(player)
		local CustomizationData = require(ReplicatedStorage.Modules.CustomizationData)
		local validCustomization = CustomizationData.ValidateCustomization(customization, rank)

		PlayerDataManager:SetCustomization(player, validCustomization)

		-- Update snake appearance if alive
		local snake = SnakeManager:GetSnakeData(player)
		if snake then
			snake.head.Color = validCustomization.color
			for _, segment in ipairs(snake.bodySegments) do
				segment.Color = validCustomization.color
			end
		end

	elseif eventType == "RequestLeaderboard" then
		local statName, scope = ...
		local topPlayers = LeaderboardService:GetTopPlayers(statName, scope, 10)
		remoteEvent:FireClient(player, "LeaderboardData", topPlayers)

	elseif eventType == "ChangeMap" then
		local mapName = ...
		print("[GameInitializer] Map change requested by", player.Name, ":", mapName)
		ArenaManager:LoadMap(mapName)

	else
		warn("[GameInitializer] Unknown event type:", eventType)
	end
end)

-- Handle snake death → revival
SnakeManager.SnakeDied:Connect(function(player, killer)
	-- Notify client of death
	remoteEvent:FireClient(player, "SnakeDied", killer and killer.Name or "yourself")

	-- Offer revival if player has donuts
	task.wait(1) -- Brief delay
	ReviveService:OfferRevival(player, PlayerDataManager, SnakeManager, ShieldManager, RankService)
end)

-- Send initial data to players
Players.PlayerAdded:Connect(function(player)
	-- Chat commands for testing
	player.Chatted:Connect(function(message)
		print("[Chat] Player said:", message)
		local args = string.split(message, " ")
		if args[1] == "/map" and args[2] then
			-- Capitalize first letter for matching
			local mapName = args[2]:sub(1,1):upper() .. args[2]:sub(2):lower()
			print("[Chat] Switching map to:", mapName)
			ArenaManager:LoadMap(mapName)
		end
	end)

	task.wait(2) -- Wait for client to load

	local data = PlayerDataManager:GetData(player)
	if data then
		remoteEvent:FireClient(player, "InitialData", {
			gold = data.gold,
			rank = data.rank,
			donuts = data.reviveDonuts,
			customization = data.customization,
			stats = data.stats,
		})
	end
end)

print("[GameInitializer] Server initialized successfully!")
