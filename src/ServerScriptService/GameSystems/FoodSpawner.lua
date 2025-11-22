-- FoodSpawner.lua
-- Continuous food generation with Poisson disk sampling for even distribution

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FoodConfig = require(ReplicatedStorage.Modules.FoodConfig)
local SpatialGrid = require(ReplicatedStorage.Shared.SpatialGrid)

local FoodSpawner = {}
FoodSpawner._foodParts = {} -- [part] = {type, spawnTime, despawnTime}
FoodSpawner._spatialGrid = nil
FoodSpawner._foodParent = nil

-- Initialize food spawner
function FoodSpawner:Initialize()
	self._spatialGrid = SpatialGrid.new()
	self._foodParent = workspace:FindFirstChild("Food")

	if not self._foodParent then
		self._foodParent = Instance.new("Folder")
		self._foodParent.Name = "Food"
		self._foodParent.Parent = workspace
	end

	-- Initial spawn
	self:SpawnFood(FoodConfig.MAX_FOOD / 2)

	-- Continuous spawning
	task.spawn(function()
		while true do
			task.wait(FoodConfig.SPAWN_RATE)
			local currentCount = self:GetFoodCount()
			if currentCount < FoodConfig.MAX_FOOD then
				local spawnCount = math.min(FoodConfig.SPAWN_BATCH_SIZE, FoodConfig.MAX_FOOD - currentCount)
				self:SpawnFood(spawnCount)
			end
		end
	end)

	-- Despawn old food
	task.spawn(function()
		while true do
			task.wait(30) -- Check every 30 seconds
			self:_despawnOldFood()
		end
	end)

	print("[FoodSpawner] Initialized")
end

-- Spawns food with Poisson disk sampling
function FoodSpawner:SpawnFood(count)
	local SnakeConfig = require(ReplicatedStorage.Modules.SnakeConfig)
	local arenaMin = SnakeConfig.ARENA_MIN
	local arenaMax = SnakeConfig.ARENA_MAX

	local spawned = 0
	local maxAttempts = count * 10 -- Prevent infinite loops

	for attempt = 1, maxAttempts do
		if spawned >= count then
			break
		end

		-- Random position
		local x = math.random(arenaMin.X, arenaMax.X)
		local z = math.random(arenaMin.Z, arenaMax.Z)
		local position = Vector3.new(x, 2, z)

		-- Check minimum distance (Poisson disk)
		if self:_isValidSpawnPosition(position) then
			-- 5% chance for power-up
			if math.random() < 0.05 then
				local powerUpType, powerUpData = self:_getRandomPowerUp()
				self:_createFood(position, "POWERUP_" .. powerUpType, powerUpData)
			else
				local foodType, foodData = FoodConfig.GetRandomFoodType()
				self:_createFood(position, foodType, foodData)
			end
			spawned = spawned + 1
		end
	end

	if spawned > 0 then
		print(string.format("[FoodSpawner] Spawned %d food", spawned))
	end
end

-- Gets random power-up type
function FoodSpawner:_getRandomPowerUp()
	local totalWeight = 0
	for _, data in pairs(FoodConfig.POWERUPS) do
		totalWeight = totalWeight + data.weight
	end

	local random = math.random() * totalWeight
	local currentWeight = 0

	for typeName, data in pairs(FoodConfig.POWERUPS) do
		currentWeight = currentWeight + data.weight
		if random <= currentWeight then
			return typeName, data
		end
	end
	
	return "SPEED", FoodConfig.POWERUPS.SPEED
end

-- Checks if spawn position is valid (Poisson disk)
function FoodSpawner:_isValidSpawnPosition(position)
	local nearby = self._spatialGrid:GetNearby(position, FoodConfig.MIN_DISTANCE)
	return #nearby == 0
end

-- Creates a food part
function FoodSpawner:_createFood(position, foodType, foodData)
	local food = Instance.new("Part")
	food.Name = "Food_" .. foodType
	food.Size = Vector3.new(foodData.size, foodData.size, foodData.size)
	food.Shape = Enum.PartType.Ball
	food.Material = Enum.Material.Neon
	food.Color = foodData.color
	food.CanCollide = false
	food.Anchored = true
	food.Position = position
	food.TopSurface = Enum.SurfaceType.Smooth
	food.BottomSurface = Enum.SurfaceType.Smooth
	food.Parent = self._foodParent

	-- Store metadata
	self._foodParts[food] = {
		type = foodType,
		data = foodData,
		spawnTime = os.clock(),
		despawnTime = os.clock() + FoodConfig.DESPAWN_TIME,
	}

	-- Add to spatial grid
	self._spatialGrid:Insert(food, position)

	return food
end

-- Scatters food at position (on snake death)
function FoodSpawner:ScatterFood(position, count)
	local radius = FoodConfig.SCATTER_RADIUS

	for i = 1, count do
		-- Random position in circle
		local angle = math.random() * 2 * math.pi
		local distance = math.random() * radius
		local offset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
		local spawnPos = position + offset

		-- Clamp to arena bounds
		local SnakeConfig = require(ReplicatedStorage.Modules.SnakeConfig)
		spawnPos = Vector3.new(
			math.clamp(spawnPos.X, SnakeConfig.ARENA_MIN.X, SnakeConfig.ARENA_MAX.X),
			2,
			math.clamp(spawnPos.Z, SnakeConfig.ARENA_MIN.Z, SnakeConfig.ARENA_MAX.Z)
		)

		local foodType, foodData = FoodConfig.GetRandomFoodType()
		self:_createFood(spawnPos, foodType, foodData)
	end

	print(string.format("[FoodSpawner] Scattered %d food at %s", count, tostring(position)))
end

-- Collects food (called by SnakeManager)
function FoodSpawner:CollectFood(player, food)
	local foodData = self._foodParts[food]
	if not foodData then
		return false
	end

	-- Remove from tracking
	self._foodParts[food] = nil
	self._spatialGrid:Remove(food)
	food:Destroy()

	return true, foodData
end

-- Gets food in range (for magnet)
function FoodSpawner:GetFoodInRange(position, radius)
	return self._spatialGrid:GetNearby(position, radius)
end

-- Gets current food count
function FoodSpawner:GetFoodCount()
	local count = 0
	for _ in pairs(self._foodParts) do
		count = count + 1
	end
	return count
end

-- Despawns old food
function FoodSpawner:_despawnOldFood()
	local now = os.clock()
	local despawned = 0

	for food, data in pairs(self._foodParts) do
		if now >= data.despawnTime then
			self._spatialGrid:Remove(food)
			food:Destroy()
			self._foodParts[food] = nil
			despawned = despawned + 1
		end
	end

	if despawned > 0 then
		print(string.format("[FoodSpawner] Despawned %d old food", despawned))
	end
end

return FoodSpawner
