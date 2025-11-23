-- LeaderboardService.lua
-- Monthly + all-time stat tracking via OrderedDataStore

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LeaderboardService = {}
LeaderboardService._statsCache = {} -- [userId] = {kills, length, food}
LeaderboardService._lastFlush = 0

-- OrderedDataStores
local MonthlyKillsStore
local AllTimeKillsStore
local MonthlyLengthStore
local AllTimeLengthStore
local MonthlyFoodStore
local AllTimeFoodStore

-- Initialize OrderedDataStores
function LeaderboardService:Initialize()
	if not RunService:IsStudio() then
		MonthlyKillsStore = DataStoreService:GetOrderedDataStore("MonthlyKills_" .. self:_getCurrentMonth())
		AllTimeKillsStore = DataStoreService:GetOrderedDataStore("AllTimeKills")
		MonthlyLengthStore = DataStoreService:GetOrderedDataStore("MonthlyLength_" .. self:_getCurrentMonth())
		AllTimeLengthStore = DataStoreService:GetOrderedDataStore("AllTimeLength")
		MonthlyFoodStore = DataStoreService:GetOrderedDataStore("MonthlyFood_" .. self:_getCurrentMonth())
		AllTimeFoodStore = DataStoreService:GetOrderedDataStore("AllTimeFood")
	end

	-- Initialize cache for existing players
	for _, player in ipairs(Players:GetPlayers()) do
		self._statsCache[player.UserId] = {
			kills = 0,
			longestLength = 0,
			totalFood = 0,
			name = player.Name,
			isNPC = false,
		}
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		self._statsCache[player.UserId] = {
			kills = 0,
			longestLength = 0,
			totalFood = 0,
			name = player.Name,
			isNPC = false,
		}
	end)

	-- Flush stats on player leave
	Players.PlayerRemoving:Connect(function(player)
		self:FlushStats(player)
		self._statsCache[player.UserId] = nil
	end)

	-- Periodic flush every 60 seconds
	task.spawn(function()
		while true do
			task.wait(60)
			self:FlushAllStats()
		end
	end)

	print("[LeaderboardService] Initialized")
end

-- Gets current month key (YYYY-MM)
function LeaderboardService:_getCurrentMonth()
	local time = os.date("*t")
	return string.format("%04d-%02d", time.year, time.month)
end

-- Check if entity is an NPC
local function isNPC(entity)
	return type(entity) == "table" and entity.isNPC == true
end

-- Increments a stat in cache
function LeaderboardService:IncrementStat(player, statName, amount)
	amount = amount or 1
	local userId = player.UserId

	-- Initialize cache for NPCs on first use
	if isNPC(player) and not self._statsCache[userId] then
		self._statsCache[userId] = {
			kills = 0,
			longestLength = 0,
			totalFood = 0,
			name = player.Name, -- Store name for display
			isNPC = true,
		}
	end

	local cache = self._statsCache[userId]

	if cache then
		if statName == "kills" then
			cache.kills = cache.kills + amount
		elseif statName == "food" then
			cache.totalFood = cache.totalFood + amount
		end
	end
end

-- Sets stat in cache (for length, which can decrease)
function LeaderboardService:SetStat(player, statName, value)
	local userId = player.UserId

	-- Initialize cache for NPCs on first use
	if isNPC(player) and not self._statsCache[userId] then
		self._statsCache[userId] = {
			kills = 0,
			longestLength = 0,
			totalFood = 0,
			name = player.Name, -- Store name for display
			isNPC = true,
		}
	end

	local cache = self._statsCache[userId]

	if cache then
		if statName == "length" then
			cache.longestLength = math.max(cache.longestLength, value)
		end
	end
end

-- Flushes stats for a player to OrderedDataStores
function LeaderboardService:FlushStats(player)
	if RunService:IsStudio() then
		return -- Skip in Studio
	end

	-- Don't flush NPC stats to DataStore
	if isNPC(player) then
		return
	end

	local userId = player.UserId
	local cache = self._statsCache[userId]

	if not cache then
		return
	end

	-- Update OrderedDataStores with retry logic
	local function updateStore(store, value)
		if store and value > 0 then
			pcall(function()
				store:UpdateAsync(tostring(userId), function(oldValue)
					return math.max(oldValue or 0, value)
				end)
			end)
		end
	end

	-- Update all stores
	updateStore(MonthlyKillsStore, cache.kills)
	updateStore(AllTimeKillsStore, cache.kills)
	updateStore(MonthlyLengthStore, cache.longestLength)
	updateStore(AllTimeLengthStore, cache.longestLength)
	updateStore(MonthlyFoodStore, cache.totalFood)
	updateStore(AllTimeFoodStore, cache.totalFood)

	print(string.format("[LeaderboardService] Flushed stats for %s", player.Name))
end

-- Flushes stats for all players
function LeaderboardService:FlushAllStats()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:FlushStats(player)
		end)
	end
end

-- Gets top players for a stat
function LeaderboardService:GetTopPlayers(statName, scope, count)
	if RunService:IsStudio() then
		return {} -- Mock data in Studio
	end

	count = count or 10
	local store

	-- Select appropriate store
	if statName == "kills" then
		store = scope == "monthly" and MonthlyKillsStore or AllTimeKillsStore
	elseif statName == "length" then
		store = scope == "monthly" and MonthlyLengthStore or AllTimeLengthStore
	elseif statName == "food" then
		store = scope == "monthly" and MonthlyFoodStore or AllTimeFoodStore
	end

	if not store then
		return {}
	end

	-- Fetch top players
	local success, pages = pcall(function()
		return store:GetSortedAsync(false, count)
	end)

	if not success then
		warn("[LeaderboardService] Failed to fetch leaderboard:", pages)
		return {}
	end

	local topPlayers = {}
	local currentPage = pages:GetCurrentPage()

	for rank, entry in ipairs(currentPage) do
		table.insert(topPlayers, {
			rank = rank,
			userId = tonumber(entry.key),
			value = entry.value,
		})
	end

	return topPlayers
end

-- Gets session leaderboard from in-memory cache (includes NPCs)
function LeaderboardService:GetSessionLeaderboard(statName, count)
	count = count or 10

	-- Build list from cache
	local entries = {}
	for userId, cache in pairs(self._statsCache) do
		local value = 0

		if statName == "kills" then
			value = cache.kills
		elseif statName == "length" then
			value = cache.longestLength
		elseif statName == "food" then
			value = cache.totalFood
		end

		if value > 0 then
			table.insert(entries, {
				userId = userId,
				name = cache.name or "Unknown", -- NPCs have name stored, players need lookup
				isNPC = cache.isNPC or false,
				value = value,
			})
		end
	end

	-- Sort by value descending
	table.sort(entries, function(a, b)
		return a.value > b.value
	end)

	-- Limit to count
	local topPlayers = {}
	for i = 1, math.min(count, #entries) do
		local entry = entries[i]
		topPlayers[i] = {
			rank = i,
			userId = entry.userId,
			name = entry.name,
			isNPC = entry.isNPC,
			value = entry.value,
		}
	end

	return topPlayers
end

-- Resets monthly stats (call on month change)
function LeaderboardService:ResetMonthlyStats()
	warn("[LeaderboardService] Monthly reset should be handled by updating month key in Initialize()")
	-- The month key changes automatically, so old monthly stats are preserved
end

return LeaderboardService
