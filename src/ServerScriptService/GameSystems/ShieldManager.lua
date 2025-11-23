-- ShieldManager.lua
-- Spawn protection timers, invulnerability logic, visual effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShieldManager = {}
ShieldManager._shields = {} -- [player] = {endTime, connection}

-- Check if entity is an NPC
local function isNPC(entity)
	return type(entity) == "table" and entity.isNPC == true
end

-- Activates shield for player
function ShieldManager:ActivateShield(player, duration)
	-- Remove existing shield if any
	self:DeactivateShield(player)

	local endTime = os.clock() + duration

	self._shields[player] = {
		endTime = endTime,
		duration = duration,
	}

	-- Notify client (only for real players, not NPCs)
	if not isNPC(player) then
		local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEvent")
		if remoteEvent then
			remoteEvent:FireClient(player, "ShieldActivated", duration)
		end
	end

	print(string.format("[ShieldManager] Shield activated for %s (%.1fs)", player.Name, duration))

	-- Auto-deactivate after duration
	task.delay(duration, function()
		if self._shields[player] and self._shields[player].endTime == endTime then
			self:DeactivateShield(player)
		end
	end)
end

-- Deactivates shield for player
function ShieldManager:DeactivateShield(player)
	if self._shields[player] then
		self._shields[player] = nil

		-- Notify client (only for real players, not NPCs)
		if not isNPC(player) then
			local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GameEvent")
			if remoteEvent then
				remoteEvent:FireClient(player, "ShieldDeactivated")
			end
		end

		print(string.format("[ShieldManager] Shield deactivated for %s", player.Name))
	end
end

-- Checks if player has active shield
function ShieldManager:IsShielded(player)
	local shield = self._shields[player]
	if shield then
		if os.clock() < shield.endTime then
			return true
		else
			-- Shield expired, clean up
			self:DeactivateShield(player)
			return false
		end
	end
	return false
end

-- Gets remaining shield time
function ShieldManager:GetRemainingTime(player)
	local shield = self._shields[player]
	if shield then
		local remaining = shield.endTime - os.clock()
		return math.max(0, remaining)
	end
	return 0
end

-- Cleanup on player leave
function ShieldManager:_handlePlayerRemoving(player)
	self._shields[player] = nil
end

-- Initialize
function ShieldManager:Initialize()
	Players.PlayerRemoving:Connect(function(player)
		self:_handlePlayerRemoving(player)
	end)

	print("[ShieldManager] Initialized")
end

return ShieldManager
