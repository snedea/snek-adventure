-- GameInitializer.server.lua
-- Server startup script - initializes all services and wires them together

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("[GameInitializer] Starting Slither Simulator server...")

-- Load services
local CharacterManager = require(ServerScriptService.GameSystems.CharacterManager)
local ArenaBuilder = require(ServerScriptService.GameSystems.ArenaBuilder)
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
	ArenaBuilder:Initialize() -- Create arena
end)

if not arenaOk then
	warn("[GameInitializer] ArenaBuilder failed to initialize:", arenaErr)
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
