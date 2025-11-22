-- FoodConfig.lua
-- Food spawning, rewards, and distribution settings

local FoodConfig = {
	-- Spawning
	MAX_FOOD = 500, -- Maximum food parts in arena
	SPAWN_RATE = 2.0, -- Seconds between spawn checks
	SPAWN_BATCH_SIZE = 10, -- Food spawned per batch
	MIN_DISTANCE = 15, -- Minimum studs between food (Poisson disk)

	-- Rewards (gold per food by rank)
	BASE_GOLD = 1,
	RANK_GOLD_MULTIPLIER = 0.1, -- Extra gold per rank

	-- Food Types (different values/sizes)
	TYPES = {
		SMALL = {
			size = 2,
			gold = 1,
			weight = 70, -- Spawn probability weight
			color = Color3.fromRGB(100, 200, 255),
		},
		MEDIUM = {
			size = 3,
			gold = 3,
			weight = 25,
			color = Color3.fromRGB(255, 200, 100),
		},
		LARGE = {
			size = 4,
			gold = 5,
			weight = 5,
			color = Color3.fromRGB(255, 100, 200),
		},
	},
	
	-- Power-ups
	POWERUPS = {
		SPEED = {
			size = 5,
			color = Color3.fromRGB(50, 255, 50), -- Green
			duration = 10,
			weight = 2,
		},
		MAGNET = {
			size = 5,
			color = Color3.fromRGB(50, 50, 255), -- Blue
			duration = 15,
			rangeMultiplier = 3,
			weight = 2,
		},
		SHIELD = {
			size = 5,
			color = Color3.fromRGB(255, 255, 50), -- Yellow
			duration = 5,
			weight = 1,
		},
	},

	-- Scatter (on snake death)
	SCATTER_PERCENTAGE = 0.5, -- Percentage of snake value scattered
	SCATTER_RADIUS = 30, -- Studs from death position

	-- Despawn
	DESPAWN_TIME = 300, -- Seconds before auto-despawn (5 minutes)
}

-- Gets weighted random food type
function FoodConfig.GetRandomFoodType()
	local totalWeight = 0
	for _, foodType in pairs(FoodConfig.TYPES) do
		totalWeight = totalWeight + foodType.weight
	end

	local random = math.random() * totalWeight
	local currentWeight = 0

	for typeName, foodType in pairs(FoodConfig.TYPES) do
		currentWeight = currentWeight + foodType.weight
		if random <= currentWeight then
			return typeName, foodType
		end
	end

	return "SMALL", FoodConfig.TYPES.SMALL
end

-- Calculates gold reward for food collection
function FoodConfig.CalculateReward(foodType, playerRank)
	local baseGold = foodType.gold or FoodConfig.BASE_GOLD
	local rankBonus = math.floor(baseGold * (playerRank - 1) * FoodConfig.RANK_GOLD_MULTIPLIER)
	return baseGold + rankBonus
end

return FoodConfig
