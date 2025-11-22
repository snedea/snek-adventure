-- SnakeManager.lua
-- Core snake lifecycle - creation, movement validation, collision detection, death handling

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnakeConfig = require(ReplicatedStorage.Modules.SnakeConfig)
local SnakeVariants = require(ReplicatedStorage.Modules.SnakeVariants)
local Maid = require(ReplicatedStorage.Shared.Maid)
local SpatialGrid = require(ReplicatedStorage.Shared.SpatialGrid)
local BodySegmentPool = require(ReplicatedStorage.Shared.BodySegmentPool)
local Signal = require(ReplicatedStorage.Shared.Signal)

local SnakeManager = {}
SnakeManager._snakes = {} -- [player] = snakeData
SnakeManager._playerVariants = {} -- [player] = variantId
SnakeManager._spatialGrid = nil
SnakeManager._bodySegmentPool = nil
SnakeManager._snakeParent = nil

-- Events
SnakeManager.SnakeDied = Signal.new()
SnakeManager.SnakeGrew = Signal.new()
SnakeManager.FoodCollected = Signal.new()

-- Dependencies (injected)
SnakeManager.PlayerDataManager = nil
SnakeManager.FoodSpawner = nil
SnakeManager.ShieldManager = nil
SnakeManager.RankService = nil
SnakeManager.LeaderboardService = nil

-- Initialize SnakeManager
function SnakeManager:Initialize(dependencies)
	self.PlayerDataManager = dependencies.PlayerDataManager
	self.FoodSpawner = dependencies.FoodSpawner
	self.ShieldManager = dependencies.ShieldManager
	self.RankService = dependencies.RankService
	self.LeaderboardService = dependencies.LeaderboardService

	self._spatialGrid = SpatialGrid.new()
	self._snakeParent = workspace:FindFirstChild("Snakes")

	if not self._snakeParent then
		self._snakeParent = Instance.new("Folder")
		self._snakeParent.Name = "Snakes"
		self._snakeParent.Parent = workspace
	end

	self._bodySegmentPool = BodySegmentPool.new(self._snakeParent)

	-- DON'T auto-create snakes - wait for variant selection from welcome screen

	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		self:KillSnake(player, nil, true) -- Silent cleanup
	end)

	-- Heartbeat loop for movement and collision
	RunService.Heartbeat:Connect(function(dt)
		self:_updateSnakes(dt)
	end)

	-- Network updates (20 Hz)
	task.spawn(function()
		while true do
			task.wait(SnakeConfig.UPDATE_RATE)
			self:_broadcastSnakeUpdates()
		end
	end)

	print("[SnakeManager] Initialized")
end

-- Sets the player's selected snake variant
function SnakeManager:SetPlayerVariant(player, variantId)
	self._playerVariants[player] = variantId
	print("[SnakeManager] Player", player.Name, "selected variant:", variantId)
end

-- Gets the player's selected variant (or default)
function SnakeManager:GetPlayerVariant(player)
	return self._playerVariants[player] or "classic"
end

-- Creates a snake for player
function SnakeManager:CreateSnake(player, spawnShieldDuration)
	-- Cleanup existing snake
	if self._snakes[player] then
		self:KillSnake(player, nil, true)
	end

	-- Get player variant and customization
	local variantId = self:GetPlayerVariant(player)
	local variant = SnakeVariants.GetVariant(variantId)
	local customization = self.PlayerDataManager:GetCustomization(player)
	local rank = self.PlayerDataManager:GetRank(player)

	-- Random spawn position
	local spawnPos = self:_getRandomSpawnPosition()

	-- Create head with variant properties
	local head = Instance.new("Part")
	head.Name = player.Name .. "_Head"
	head.Size = variant.headSize or Vector3.new(SnakeConfig.HEAD_SIZE, SnakeConfig.HEAD_SIZE, SnakeConfig.HEAD_SIZE)
	head.Shape = (variant.headShape == "Block") and Enum.PartType.Block or Enum.PartType.Ball
	head.Material = variant.material or Enum.Material.SmoothPlastic
	head.Color = variant.color
	head.Transparency = variant.transparency or 0
	head.CanCollide = false
	head.Anchored = true
	head.Position = spawnPos
	head.TopSurface = Enum.SurfaceType.Smooth
	head.BottomSurface = Enum.SurfaceType.Smooth
	head.Parent = self._snakeParent
	
	-- Create Name Tag
	local nameTag = Instance.new("BillboardGui")
	nameTag.Name = "NameTag"
	nameTag.Size = UDim2.new(0, 200, 0, 50)
	nameTag.StudsOffset = Vector3.new(0, 3, 0)
	nameTag.AlwaysOnTop = true
	nameTag.Parent = head
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = nameTag

	-- Add Trail
	local att0 = Instance.new("Attachment")
	att0.Name = "TrailAtt0"
	att0.Position = Vector3.new(0, 0.5, 0)
	att0.Parent = head
	
	local att1 = Instance.new("Attachment")
	att1.Name = "TrailAtt1"
	att1.Position = Vector3.new(0, -0.5, 0)
	att1.Parent = head
	
	local trail = Instance.new("Trail")
	trail.Name = "SnakeTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(variant.color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.5
	trail.MinLength = 0.1
	trail.Parent = head

	-- Create body segments with variant properties
	local bodySegments = {}
	for i = 1, SnakeConfig.INITIAL_SEGMENTS do
		local segment = self._bodySegmentPool:Acquire()
		segment.Size = variant.bodySize or Vector3.new(SnakeConfig.SEGMENT_SIZE, SnakeConfig.SEGMENT_SIZE, SnakeConfig.SEGMENT_SIZE)
		segment.Shape = (variant.bodyShape == "Block") and Enum.PartType.Block or (variant.bodyShape == "Cylinder" and Enum.PartType.Cylinder or Enum.PartType.Ball)
		segment.Material = variant.material or Enum.Material.SmoothPlastic
		segment.Color = variant.color
		segment.Transparency = variant.transparency or 0
		segment.Position = spawnPos - Vector3.new(i * SnakeConfig.SEGMENT_SPACING, 0, 0)
		table.insert(bodySegments, segment)

		-- Add to spatial grid
		self._spatialGrid:Insert(segment, segment.Position)
	end

	-- Create maid for cleanup
	local maid = Maid.new()
	maid:GiveTask(head)

	-- Create snake data
	local snake = {
		player = player,
		head = head,
		bodySegments = bodySegments,
		variantId = variantId,
		maid = maid,
		speed = SnakeConfig.BASE_SPEED,
		direction = Vector3.new(1, 0, 0), -- Initial direction: right
		boostActive = false,
		brakeActive = false,
		boostCooldownRemaining = 0,
		brakeCooldownRemaining = 0,
		lastPosition = spawnPos,
		lastMoveTime = os.clock(),
		color = variant.color,
		mouth = customization.mouth,
		eyes = customization.eyes,
		currentGold = 0, -- Session gold (resets on death)
		
		-- Power-ups
		activePowerUps = {}, -- [type] = endTime
		magnetMultiplier = 1,
	}

	self._snakes[player] = snake

	-- Activate shield
	local shieldDuration = spawnShieldDuration or self.RankService:GetShieldDuration(rank)
	self.ShieldManager:ActivateShield(player, shieldDuration)

	print(string.format("[SnakeManager] Created snake for %s", player.Name))
end

-- Gets random spawn position
function SnakeManager:_getRandomSpawnPosition()
	local x = math.random(SnakeConfig.SPAWN_MIN.X, SnakeConfig.SPAWN_MAX.X)
	local z = math.random(SnakeConfig.SPAWN_MIN.Z, SnakeConfig.SPAWN_MAX.Z)
	return Vector3.new(x, 2, z)
end

-- Moves snake (called via RemoteEvent)
function SnakeManager:MoveSnake(player, direction)
	local snake = self._snakes[player]
	if not snake then
		return
	end

	-- Validate direction (must be unit vector)
	if direction.Magnitude > 1.1 or direction.Magnitude < 0.9 then
		warn(string.format("[SnakeManager] Invalid direction from %s: %s", player.Name, tostring(direction)))
		return
	end

	-- Normalize and store direction
	snake.direction = direction.Unit
end

-- Activates boost
function SnakeManager:ActivateBoost(player)
	local snake = self._snakes[player]
	if not snake then
		return
	end

	if snake.boostCooldownRemaining > 0 then
		return -- Still on cooldown
	end

	snake.boostActive = true
	snake.brakeActive = false -- Can't boost and brake simultaneously
	snake.speed = SnakeConfig.BASE_SPEED * SnakeConfig.BOOST_MULTIPLIER

	local rank = self.PlayerDataManager:GetRank(player)
	local cooldown = self.RankService:GetBoostCooldown(rank)
	snake.boostCooldownRemaining = cooldown

	print(string.format("[SnakeManager] %s activated boost", player.Name))
end

-- Activates brake
function SnakeManager:ActivateBrake(player)
	local snake = self._snakes[player]
	if not snake then
		return
	end

	if snake.brakeCooldownRemaining > 0 then
		return -- Still on cooldown
	end

	snake.brakeActive = true
	snake.boostActive = false -- Can't boost and brake simultaneously
	snake.speed = SnakeConfig.BASE_SPEED * SnakeConfig.BRAKE_MULTIPLIER

	local rank = self.PlayerDataManager:GetRank(player)
	local cooldown = self.RankService:GetBrakeCooldown(rank)
	snake.brakeCooldownRemaining = cooldown

	print(string.format("[SnakeManager] %s activated brake", player.Name))
end

-- Activates power-up
function SnakeManager:ActivatePowerUp(player, powerUpType, data)
	local snake = self._snakes[player]
	if not snake then return end
	
	local duration = data.duration or 10
	snake.activePowerUps[powerUpType] = os.clock() + duration
	
	if powerUpType == "SPEED" then
		snake.speed = SnakeConfig.BASE_SPEED * 1.5
	elseif powerUpType == "MAGNET" then
		snake.magnetMultiplier = data.rangeMultiplier or 2
	elseif powerUpType == "SHIELD" then
		self.ShieldManager:ActivateShield(player, duration)
	end
	
	-- Notify client
	local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEvent")
	if remoteEvent then
		remoteEvent:FireClient(player, "PowerUpActivated", powerUpType, duration)
	end
	
	print(string.format("[SnakeManager] %s collected %s", player.Name, powerUpType))
end

-- Grows snake
function SnakeManager:GrowSnake(player, segmentCount)
	local snake = self._snakes[player]
	if not snake then
		return
	end

	for i = 1, segmentCount do
		if #snake.bodySegments >= SnakeConfig.MAX_SEGMENTS then
			break -- Max length reached
		end

		-- Acquire segment from pool
		local segment = self._bodySegmentPool:Acquire()
		segment.Color = snake.color

		-- Position at tail
		local lastSegment = snake.bodySegments[#snake.bodySegments]
		segment.Position = lastSegment.Position

		table.insert(snake.bodySegments, segment)
		self._spatialGrid:Insert(segment, segment.Position)
	end

	self.SnakeGrew:Fire(player, #snake.bodySegments)
	self.LeaderboardService:SetStat(player, "length", #snake.bodySegments)
end

-- Kills snake
function SnakeManager:KillSnake(player, killer, silent)
	local snake = self._snakes[player]
	if not snake then
		return
	end

	-- Scatter food
	local snakeValue = snake.currentGold or 0
	local foodCount = math.floor(snakeValue * 0.5) -- 50% of gold as food
	if foodCount > 0 then
		self.FoodSpawner:ScatterFood(snake.head.Position, foodCount)
	end

	-- Update stats
	if killer and killer ~= player then
		self.LeaderboardService:IncrementStat(killer, "kills", 1)
		self.PlayerDataManager:IncrementStat(killer, "totalKills", 1)
	end

	-- Cleanup
	self._snakes[player] = nil
	snake.maid:DoCleaning()

	-- Release body segments
	for _, segment in ipairs(snake.bodySegments) do
		self._spatialGrid:Remove(segment)
		self._bodySegmentPool:Release(segment)
	end

	-- Fire event
	if not silent then
		self.SnakeDied:Fire(player, killer)
		print(string.format("[SnakeManager] %s's snake died", player.Name))
	end
end

-- Updates snakes (movement, collisions, food collection)
function SnakeManager:_updateSnakes(dt)
	for player, snake in pairs(self._snakes) do
		-- Update cooldowns
		if snake.boostCooldownRemaining > 0 then
			snake.boostCooldownRemaining = math.max(0, snake.boostCooldownRemaining - dt)
		end
		if snake.brakeCooldownRemaining > 0 then
			snake.brakeCooldownRemaining = math.max(0, snake.brakeCooldownRemaining - dt)
		end

		-- Reset speed if not boosting/braking
		if snake.boostActive and snake.boostCooldownRemaining == 0 then
			snake.boostActive = false
			snake.speed = SnakeConfig.BASE_SPEED
		end
		if snake.brakeActive and snake.brakeCooldownRemaining == 0 then
			snake.brakeActive = false
			snake.speed = SnakeConfig.BASE_SPEED
		end
		
		-- Check power-ups
		local now = os.clock()
		for type, endTime in pairs(snake.activePowerUps) do
			if now >= endTime then
				snake.activePowerUps[type] = nil
				
				if type == "SPEED" then
					if not snake.boostActive and not snake.brakeActive then
						snake.speed = SnakeConfig.BASE_SPEED
					end
				elseif type == "MAGNET" then
					snake.magnetMultiplier = 1
				end
			end
		end

		-- Move head
		local movement = snake.direction * snake.speed * dt
		local newPosition = snake.head.Position + movement

		-- Clamp to arena bounds
		newPosition = Vector3.new(
			math.clamp(newPosition.X, SnakeConfig.ARENA_MIN.X, SnakeConfig.ARENA_MAX.X),
			2,
			math.clamp(newPosition.Z, SnakeConfig.ARENA_MIN.Z, SnakeConfig.ARENA_MAX.Z)
		)

		snake.head.Position = newPosition

		-- Update body segments (follow head)
		self:_updateBodySegments(snake, dt)

		-- Check collisions (if not shielded)
		if not self.ShieldManager:IsShielded(player) then
			self:_checkCollisions(player, snake)
		end

		-- Check food collection (with magnet)
		self:_checkFoodCollection(player, snake)
	end
end

-- Updates body segments to follow head
function SnakeManager:_updateBodySegments(snake, dt)
	local positions = {snake.head.Position}

	-- Calculate segment positions - each segment follows the one in front
	for i, segment in ipairs(snake.bodySegments) do
		local targetPos = positions[i]
		local currentPos = segment.Position

		-- Calculate direction and distance to target (previous segment)
		local direction = (targetPos - currentPos)
		local distance = direction.Magnitude

		local newPos
		-- Move segment toward target position, maintaining spacing
		if distance > SnakeConfig.SEGMENT_SPACING then
			-- Calculate how far to move (don't overshoot)
			local moveDistance = math.min(distance - SnakeConfig.SEGMENT_SPACING, snake.speed * dt)
			newPos = currentPos + direction.Unit * moveDistance
		else
			-- Already at correct spacing
			newPos = currentPos
		end

		segment.Position = newPos

		-- Update spatial grid
		self._spatialGrid:Insert(segment, newPos)

		table.insert(positions, newPos)
	end
end

-- Checks collisions
function SnakeManager:_checkCollisions(player, snake)
	local headPos = snake.head.Position

	-- Get nearby parts
	local nearby = self._spatialGrid:GetNearby(headPos, SnakeConfig.COLLISION_RADIUS * 2)

	for _, part in ipairs(nearby) do
		if part.Name == "BodySegment" then
			-- Check distance
			local distance = (part.Position - headPos).Magnitude
			if distance < SnakeConfig.COLLISION_RADIUS then
				-- Find owner
				local ownerPlayer = self:_findSegmentOwner(part)

				-- Self-collision grace period
				if ownerPlayer == player then
					local segmentIndex = table.find(snake.bodySegments, part)
					if segmentIndex and segmentIndex <= SnakeConfig.SELF_COLLISION_GRACE then
						continue -- Skip self-collision on first few segments
					end
				end

				-- Collision detected
				self:KillSnake(player, ownerPlayer)
				return
			end
		end
	end
end

-- Finds which player owns a segment
function SnakeManager:_findSegmentOwner(segment)
	for player, snake in pairs(self._snakes) do
		if table.find(snake.bodySegments, segment) then
			return player
		end
	end
	return nil
end

-- Checks food collection with magnet
function SnakeManager:_checkFoodCollection(player, snake)
	local rank = self.PlayerDataManager:GetRank(player)
	local magnetRange = self.RankService:GetMagnetRange(rank) * (snake.magnetMultiplier or 1)

	local nearbyFood = self.FoodSpawner:GetFoodInRange(snake.head.Position, magnetRange)

	for _, food in ipairs(nearbyFood) do
		local success, foodData = self.FoodSpawner:CollectFood(player, food)

		if success and foodData then
			-- Check if power-up
			if string.sub(foodData.type, 1, 8) == "POWERUP_" then
				local powerUpType = string.sub(foodData.type, 9)
				self:ActivatePowerUp(player, powerUpType, foodData.data)
				continue
			end
			
			-- Award gold
			local FoodConfig = require(ReplicatedStorage.Modules.FoodConfig)
			local goldReward = FoodConfig.CalculateReward(foodData.data, rank)

			self.PlayerDataManager:AddGold(player, goldReward)
			snake.currentGold = (snake.currentGold or 0) + goldReward

			-- Grow snake
			self:GrowSnake(player, SnakeConfig.FOOD_GROWTH_SEGMENTS)

			-- Update stats
			self.LeaderboardService:IncrementStat(player, "food", 1)
			self.PlayerDataManager:IncrementStat(player, "totalFood", 1)

			-- Check rank up
			local currentRank = rank
			local newRank = self.RankService:CheckRankUp(currentRank, self.PlayerDataManager:GetGold(player))
			if newRank > currentRank then
				self.PlayerDataManager:SetRank(player, newRank)

				-- Notify client
				local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEvent")
				if remoteEvent then
					remoteEvent:FireClient(player, "RankUp", newRank)
				end
			end

			-- Notify client
			local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEvent")
			if remoteEvent then
				remoteEvent:FireClient(player, "FoodCollected", goldReward)
			end

			self.FoodCollected:Fire(player, goldReward)
		end
	end
end

-- Broadcasts snake updates to clients
function SnakeManager:_broadcastSnakeUpdates()
	local updates = {}

	for player, snake in pairs(self._snakes) do
		local variant = SnakeVariants.GetVariant(snake.variantId)
		updates[player.UserId] = {
			headPos = snake.head.Position,
			direction = snake.direction,
			length = #snake.bodySegments,
			color = variant.color,
			variantId = snake.variantId,
			headShape = variant.headShape,
			bodyShape = variant.bodyShape,
			headSize = variant.headSize,
			bodySize = variant.bodySize,
			material = variant.material,
			transparency = variant.transparency,
		}
	end

	-- Broadcast to all players
	local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEvent")
	if remoteEvent then
		if not next(updates) then
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			remoteEvent:FireClient(player, "UpdateSnakes", updates)
		end
	end
end

-- Gets snake data
function SnakeManager:GetSnakeData(player)
	return self._snakes[player]
end

return SnakeManager
