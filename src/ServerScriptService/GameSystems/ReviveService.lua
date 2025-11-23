-- ReviveService.lua
-- Donut consumption, revival prompt, respawn with shield

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReviveService = {}
ReviveService._activePrompts = {} -- [player] = {endTime}

local PROMPT_TIMEOUT = 10 -- Seconds to accept/decline

-- Check if entity is an NPC
local function isNPC(entity)
	return type(entity) == "table" and entity.isNPC == true
end

-- Offers revival to player
function ReviveService:OfferRevival(player, PlayerDataManager, SnakeManager, ShieldManager, RankService)
	-- NPCs auto-respawn via NPCManager, skip revival system
	if isNPC(player) then
		return false
	end
	-- Check if player has donuts
	local donuts = PlayerDataManager:GetDonuts(player)
	
	if donuts <= 0 then
		-- No donuts - auto respawn after delay
		local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEvent")
		if remoteEvent then
			remoteEvent:FireClient(player, "ShowRevivePrompt", 0)
		end
		
		task.wait(3)
		
		-- Auto-respawn
		SnakeManager:CreateSnake(player)
		local rank = PlayerDataManager:GetRank(player)
		local shieldDuration = RankService:GetShieldDuration(rank)
		ShieldManager:ActivateShield(player, shieldDuration)
		
		print(string.format("[ReviveService] %s auto-respawned (no donuts)", player.Name))
		return false
	end

	-- Send prompt to client
	local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEvent")
	if remoteEvent then
		remoteEvent:FireClient(player, "ShowRevivePrompt", donuts)
	end

	-- Store prompt with timeout
	self._activePrompts[player] = {
		endTime = os.clock() + PROMPT_TIMEOUT,
		PlayerDataManager = PlayerDataManager,
		SnakeManager = SnakeManager,
		ShieldManager = ShieldManager,
		RankService = RankService,
	}

	-- Auto-decline after timeout
	task.delay(PROMPT_TIMEOUT, function()
		if self._activePrompts[player] then
			self:DeclineRevival(player)
		end
	end)

	print(string.format("[ReviveService] Offered revival to %s", player.Name))
	return true
end

-- Accepts revival (called via RemoteEvent)
function ReviveService:AcceptRevival(player)
	local prompt = self._activePrompts[player]
	if not prompt then
		return false
	end

	-- Check timeout
	if os.clock() > prompt.endTime then
		self._activePrompts[player] = nil
		return false
	end

	local PlayerDataManager = prompt.PlayerDataManager
	local SnakeManager = prompt.SnakeManager
	local ShieldManager = prompt.ShieldManager
	local RankService = prompt.RankService

	-- Consume donut
	local success = PlayerDataManager:UseDonuts(player, 1)
	if not success then
		self._activePrompts[player] = nil
		return false
	end

	-- Respawn snake
	SnakeManager:CreateSnake(player)

	-- Activate shield
	local rank = PlayerDataManager:GetRank(player)
	local shieldDuration = RankService:GetShieldDuration(rank)
	ShieldManager:ActivateShield(player, shieldDuration)

	-- Cleanup prompt
	self._activePrompts[player] = nil

	print(string.format("[ReviveService] %s accepted revival", player.Name))
	return true
end

-- Declines revival
function ReviveService:DeclineRevival(player)
	if self._activePrompts[player] then
		local prompt = self._activePrompts[player]
		self._activePrompts[player] = nil

		-- Notify client
		local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEvent")
		if remoteEvent then
			remoteEvent:FireClient(player, "HideRevivePrompt")
		end

		-- Auto-respawn after declining
		task.wait(1)
		prompt.SnakeManager:CreateSnake(player)
		local rank = prompt.PlayerDataManager:GetRank(player)
		local shieldDuration = prompt.RankService:GetShieldDuration(rank)
		prompt.ShieldManager:ActivateShield(player, shieldDuration)

		print(string.format("[ReviveService] %s declined revival - auto-respawned", player.Name))
	end
end

return ReviveService
