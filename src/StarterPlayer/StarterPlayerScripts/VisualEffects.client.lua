-- VisualEffects.client.lua
-- Handles client-side visual effects (particles, sounds, etc.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GameEvent")

local VisualEffects = {}

-- Create particle templates
local function createEatParticle()
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "EatEffect"
	emitter.Texture = "rbxassetid://1266170131" -- Star texture
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(5, 10)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Rate = 0
	emitter.Enabled = false
	return emitter
end

local function createPowerUpParticle(color)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "PowerUpEffect"
	emitter.Texture = "rbxassetid://243098098" -- Ring texture
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 5),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Lifetime = NumberRange.new(1, 1.5)
	emitter.Speed = NumberRange.new(0)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(90)
	emitter.Rate = 0
	emitter.Enabled = false
	return emitter
end

-- Play eat effect
function VisualEffects:PlayEatEffect(position, amount)
	local part = Instance.new("Part")
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Position = position
	part.Parent = workspace
	
	local emitter = createEatParticle()
	emitter.Parent = part
	
	-- Burst
	emitter:Emit(math.min(20, amount * 2))
	
	-- Cleanup
	task.delay(2, function()
		part:Destroy()
	end)
end

-- Play power-up effect
function VisualEffects:PlayPowerUpEffect(position, type)
	local color = Color3.fromRGB(255, 255, 255)
	if type == "SPEED" then
		color = Color3.fromRGB(50, 255, 50)
	elseif type == "MAGNET" then
		color = Color3.fromRGB(50, 50, 255)
	elseif type == "SHIELD" then
		color = Color3.fromRGB(255, 255, 50)
	end
	
	local part = Instance.new("Part")
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Position = position
	part.Parent = workspace
	
	local emitter = createPowerUpParticle(color)
	emitter.Parent = part
	
	-- Burst
	emitter:Emit(1)
	
	-- Cleanup
	task.delay(2, function()
		part:Destroy()
	end)
end

-- Listen for events
remoteEvent.OnClientEvent:Connect(function(eventType, ...)
	if eventType == "FoodCollected" then
		local amount = ...
		-- We need position, but the event only sends amount. 
		-- For now, play on local snake head if it's us.
		-- Ideally, we'd send position from server.
		
		local character = workspace.Snakes:FindFirstChild(player.Name .. "_Head")
		if character then
			VisualEffects:PlayEatEffect(character.Position, amount)
		end
		
	elseif eventType == "PowerUpActivated" then
		local type, duration = ...
		local character = workspace.Snakes:FindFirstChild(player.Name .. "_Head")
		if character then
			VisualEffects:PlayPowerUpEffect(character.Position, type)
		end
	end
end)

print("[VisualEffects] Initialized")

return VisualEffects
