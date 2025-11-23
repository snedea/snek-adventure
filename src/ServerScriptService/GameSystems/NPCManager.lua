-- NPCManager.lua
-- Manages AI-controlled snakes (NPCs) arena-wide

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SnakeVariants = require(ReplicatedStorage.Modules.SnakeVariants)

local NPCManager = {}
local _initialized = false
local _dependencies = {}

-- NPC tracking (arena-wide, not per-player)
local _npcEntities = {} -- {npcId = {id, name, isNPC, lastMoveTime, currentDirection, changeDirectionTime}}
local _npcCount = 0 -- Current number of active NPCs
local _targetNpcCount = 0 -- Desired number of NPCs
local _npcEnabled = false -- Whether NPCs are enabled
local _nextNpcId = 1 -- Global counter for unique IDs

-- First-wins lock for NPC settings
local _npcSettingsLocked = false -- Whether settings are locked
local _npcSettingsOwner = nil -- Player who set the settings (first-wins)

-- Random name pool for NPCs
local NPC_NAMES = {
	"Slithery Pete", "Danger Noodle", "Snake Plissken", "Hiss Master",
	"Viper Queen", "Sneky Snek", "Long Boi", "Danger Zone",
	"Sir Slither", "Wiggle Worm", "Scale Squad", "Hiss Hiss",
	"Python Pete", "Cobra Commander", "Nope Rope", "Spaghetti Monster",
	"Boop Snoot", "Sneky McSnekface", "The Constrictor", "Venom"
}

function NPCManager:Initialize(dependencies)
	if _initialized then
		warn("[NPCManager] Already initialized")
		return
	end

	_dependencies = dependencies
	_initialized = true

	-- Release lock if owner leaves so someone else can set NPCs
	Players.PlayerRemoving:Connect(function(player)
		if _npcSettingsOwner == player then
			_npcSettingsLocked = false
			_npcSettingsOwner = nil
			print("[NPCManager] NPC settings lock released (owner left)")
		end
	end)

	-- Start NPC AI loop
	self:_StartAILoop()

	print("[NPCManager] Initialized")
end

-- Set NPC settings (arena-wide, first-wins lock)
function NPCManager:SetNPCSettings(player, enabled, count)
	-- Server-side validation
	enabled = enabled == true
	count = math.clamp(tonumber(count) or 0, 0, 20)

	-- First-wins lock: if locked and caller is not owner, reject silently
	if _npcSettingsLocked and _npcSettingsOwner ~= player then
		print(string.format("[NPCManager] %s tried to change NPC settings but %s owns them (first-wins)",
			player.Name, _npcSettingsOwner and _npcSettingsOwner.Name or "unknown"))
		return
	end

	-- If not locked, this player becomes the owner
	if not _npcSettingsLocked then
		_npcSettingsLocked = true
		_npcSettingsOwner = player
		print(string.format("[NPCManager] %s now owns NPC settings (first-wins)", player.Name))
	end

	_npcEnabled = enabled
	_targetNpcCount = enabled and count or 0

	print(string.format("[NPCManager] NPC settings updated by %s: enabled = %s, count = %d",
		player.Name, tostring(enabled), count))

	-- Adjust NPCs to match target
	self:_AdjustNPCCount()
end

-- Get random NPC name
function NPCManager:_GetRandomName()
	local baseName = NPC_NAMES[math.random(1, #NPC_NAMES)]
	return baseName .. " [BOT]"
end

-- Get random variant
function NPCManager:_GetRandomVariant()
	local variants = SnakeVariants.GetUnlockedVariants()
	return variants[math.random(1, #variants)].id
end

-- Get random non-zero direction
function NPCManager:_GetRandomDirection()
	local x, z
	repeat
		x = math.random(-10, 10)
		z = math.random(-10, 10)
	until x ~= 0 or z ~= 0 -- Ensure at least one component is non-zero
	return Vector3.new(x, 0, z).Unit
end

-- Create NPC entity (lightweight data structure, not a Player instance)
function NPCManager:_CreateNPCEntity()
	local npcId = "NPC_" .. _nextNpcId
	_nextNpcId = _nextNpcId + 1

	local entity = {
		id = npcId,
		Name = self:_GetRandomName(),
		UserId = -_nextNpcId, -- Unique negative UserId for each NPC
		isNPC = true,
	}

	return entity
end

-- Spawn a single NPC
function NPCManager:SpawnSingleNPC()
	local entity = self:_CreateNPCEntity()

	-- Store NPC data
	_npcEntities[entity.id] = {
		entity = entity,
		lastMoveTime = tick(),
		currentDirection = self:_GetRandomDirection(),
		changeDirectionTime = tick() + math.random(2, 5),
	}

	-- Set variant and create snake using SnakeManager
	local variantId = self:_GetRandomVariant()
	_dependencies.SnakeManager:SetPlayerVariant(entity, variantId)
	_dependencies.SnakeManager:CreateSnake(entity, 3) -- 3 second shield for NPCs

	_npcCount = _npcCount + 1
	print("[NPCManager] Spawned NPC:", entity.Name, "ID:", entity.id)
end

-- Remove a specific NPC
function NPCManager:RemoveNPC(npcId)
	local npcData = _npcEntities[npcId]
	if not npcData then return end

	-- Kill the snake
	local snake = _dependencies.SnakeManager:GetSnakeData(npcData.entity)
	if snake then
		_dependencies.SnakeManager:KillSnake(npcData.entity, nil, true)
	end

	_npcEntities[npcId] = nil
	_npcCount = _npcCount - 1
	print("[NPCManager] Removed NPC:", npcId)
end

-- Adjust NPC count to match target
function NPCManager:_AdjustNPCCount()
	-- Remove excess NPCs
	while _npcCount > _targetNpcCount do
		-- Find and remove one NPC
		local npcId = next(_npcEntities)
		if npcId then
			self:RemoveNPC(npcId)
		else
			break
		end
	end

	-- Add missing NPCs
	while _npcCount < _targetNpcCount do
		self:SpawnSingleNPC()
	end
end

-- AI loop for NPCs
function NPCManager:_StartAILoop()
	task.spawn(function()
		while true do
			task.wait(0.1) -- Update NPCs 10 times per second

			for npcId, npcData in pairs(_npcEntities) do
				local entity = npcData.entity
				local snake = _dependencies.SnakeManager:GetSnakeData(entity)

				if snake then
					-- NPC is alive, update movement
					local now = tick()

					-- Change direction randomly every 2-5 seconds
					if now >= npcData.changeDirectionTime then
						npcData.currentDirection = self:_GetRandomDirection()
						npcData.changeDirectionTime = now + math.random(2, 5)
					end

					-- Move NPC
					if now - npcData.lastMoveTime >= 0.1 then
						_dependencies.SnakeManager:MoveSnake(entity, npcData.currentDirection)
						npcData.lastMoveTime = now
					end
				else
					-- NPC died, respawn asynchronously (don't block the loop)
					task.spawn(function()
						task.wait(3)
						-- Check if this NPC still exists and NPCs are still enabled
						if _npcEntities[npcId] and _npcEnabled then
							local variantId = self:_GetRandomVariant()
							_dependencies.SnakeManager:SetPlayerVariant(entity, variantId)
							_dependencies.SnakeManager:CreateSnake(entity, 3)
							-- Reset movement data
							npcData.currentDirection = self:_GetRandomDirection()
							npcData.changeDirectionTime = tick() + math.random(2, 5)
							npcData.lastMoveTime = tick()
							print("[NPCManager] Respawned NPC:", entity.Name)
						end
					end)
				end
			end
		end
	end)
end

-- Clear all NPCs (called on map change)
function NPCManager:ClearAllNPCs()
	print("[NPCManager] Clearing all NPCs...")

	-- Kill all NPC snakes
	for npcId, npcData in pairs(_npcEntities) do
		local snake = _dependencies.SnakeManager:GetSnakeData(npcData.entity)
		if snake then
			_dependencies.SnakeManager:KillSnake(npcData.entity, nil, true)
		end
	end

	-- Clear tracking
	_npcEntities = {}
	_npcCount = 0
	_targetNpcCount = 0
	_npcEnabled = false

	-- Reset first-wins lock (allows new player to set settings after map change)
	_npcSettingsLocked = false
	_npcSettingsOwner = nil

	print("[NPCManager] All NPCs cleared and settings lock reset")
end

-- Check if an entity is an NPC
function NPCManager:IsNPC(entity)
	if type(entity) == "table" and entity.isNPC then
		return true
	end
	return false
end

return NPCManager
