-- SnakeRenderer.lua
-- Body segment interpolation for other players' snakes (smooth 60 FPS rendering)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local SnakeConfig = require(ReplicatedStorage.Modules.SnakeConfig)
local SnakeVariants = require(ReplicatedStorage.Modules.SnakeVariants)
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GameEvent")

local SnakeRenderer = {}
SnakeRenderer.OtherSnakes = {} -- [userId] = {headPart, bodyParts, targetData, variantId}
SnakeRenderer._initialized = false
SnakeRenderer._connections = {}

-- Updates snake data from server
function SnakeRenderer:UpdateSnakes(snakeData)
	for userId, data in pairs(snakeData) do
		-- Skip local player (rendered separately)
		if tonumber(userId) ~= player.UserId then
			local variant = SnakeVariants.GetVariant(data.variantId)

			if not self.OtherSnakes[userId] or self.OtherSnakes[userId].variantId ~= variant.id then
				self:_removeSnakeVisuals(userId)
				self:_createSnakeVisuals(userId, data, variant)
			end

			-- Update target data for interpolation
			local snake = self.OtherSnakes[userId]
			if snake then
				snake.targetHeadPos = data.headPos
				snake.targetDirection = data.direction
				snake.targetLength = data.length
				snake.targetColor = variant.color
				snake.variant = variant
			end
		end
	end

	-- Remove snakes that no longer exist
	for userId, snake in pairs(self.OtherSnakes) do
		if not snakeData[userId] then
			self:_removeSnakeVisuals(userId)
		end
	end
end

-- Creates visual representation for other snake
function SnakeRenderer:_createSnakeVisuals(userId, data, variant)
	local snakesFolder = workspace:FindFirstChild("Snakes")
	if not snakesFolder then
		return
	end

	variant = variant or SnakeVariants.GetVariant(data.variantId)

	-- Create head
	local head = Instance.new("Part")
	head.Name = "OtherSnake_" .. userId .. "_Head"
	head.Size = variant.headSize or Vector3.new(SnakeConfig.HEAD_SIZE, SnakeConfig.HEAD_SIZE, SnakeConfig.HEAD_SIZE)
	head.Shape = (variant.headShape == "Block") and Enum.PartType.Block or Enum.PartType.Ball
	head.Material = variant.material or Enum.Material.SmoothPlastic
	head.Transparency = variant.transparency or 0
	head.Color = variant.color
	head.CanCollide = false
	head.Anchored = true
	head.Position = data.headPos
	head.Parent = snakesFolder

	-- Create body segments (client-side only, for smooth rendering)
	local bodyParts = {}
	for i = 1, data.length do
		local segment = Instance.new("Part")
		segment.Name = "OtherSnake_" .. userId .. "_Body_" .. i
		segment.Size = variant.bodySize or Vector3.new(SnakeConfig.SEGMENT_SIZE, SnakeConfig.SEGMENT_SIZE, SnakeConfig.SEGMENT_SIZE)
		if variant.bodyShape == "Block" then
			segment.Shape = Enum.PartType.Block
		elseif variant.bodyShape == "Cylinder" then
			segment.Shape = Enum.PartType.Cylinder
		else
			segment.Shape = Enum.PartType.Ball
		end
		segment.Material = variant.material or Enum.Material.SmoothPlastic
		segment.Transparency = variant.transparency or 0
		segment.Color = variant.color
		segment.CanCollide = false
		segment.Anchored = true
		segment.Position = data.headPos - Vector3.new(i * SnakeConfig.SEGMENT_SPACING, 0, 0)
		segment.Parent = snakesFolder

		table.insert(bodyParts, segment)
	end

	self.OtherSnakes[userId] = {
		headPart = head,
		bodyParts = bodyParts,
		targetHeadPos = data.headPos,
		currentHeadPos = data.headPos,
		targetDirection = data.direction,
		targetLength = data.length,
		targetColor = variant.color,
		variantId = variant.id,
		variant = variant,
	}
end

-- Removes visual representation
function SnakeRenderer:_removeSnakeVisuals(userId)
	local snake = self.OtherSnakes[userId]
	if snake then
		snake.headPart:Destroy()
		for _, part in ipairs(snake.bodyParts) do
			part:Destroy()
		end
		self.OtherSnakes[userId] = nil
	end
end

-- Interpolates snake positions (60 FPS smooth)
function SnakeRenderer:_interpolateSnakes(dt)
	for userId, snake in pairs(self.OtherSnakes) do
		-- Interpolate head position
		local alpha = SnakeConfig.CLIENT_INTERPOLATION_ALPHA
		snake.currentHeadPos = snake.currentHeadPos:Lerp(snake.targetHeadPos, alpha)
		snake.headPart.Position = snake.currentHeadPos

		-- Update color if changed
		if snake.headPart.Color ~= snake.targetColor then
			snake.headPart.Color = snake.targetColor
			for _, part in ipairs(snake.bodyParts) do
				part.Color = snake.targetColor
			end
		end

		-- Adjust body segment count if length changed
		while #snake.bodyParts < snake.targetLength do
			local segment = Instance.new("Part")
			segment.Name = "OtherSnake_" .. userId .. "_Body_" .. #snake.bodyParts + 1
			segment.Size = snake.variant.bodySize or Vector3.new(SnakeConfig.SEGMENT_SIZE, SnakeConfig.SEGMENT_SIZE, SnakeConfig.SEGMENT_SIZE)
			if snake.variant.bodyShape == "Block" then
				segment.Shape = Enum.PartType.Block
			elseif snake.variant.bodyShape == "Cylinder" then
				segment.Shape = Enum.PartType.Cylinder
			else
				segment.Shape = Enum.PartType.Ball
			end
			segment.Material = snake.variant.material or Enum.Material.SmoothPlastic
			segment.Transparency = snake.variant.transparency or 0
			segment.Color = snake.targetColor
			segment.CanCollide = false
			segment.Anchored = true
			segment.Position = snake.currentHeadPos
			segment.Parent = workspace:FindFirstChild("Snakes")
			table.insert(snake.bodyParts, segment)
		end

		while #snake.bodyParts > snake.targetLength do
			local segment = table.remove(snake.bodyParts)
			segment:Destroy()
		end

		-- Interpolate body segments (follow head)
		local previousSegmentPos = snake.headPart.Position
		for i, segment in ipairs(snake.bodyParts) do
			local currentPos = segment.Position
			
			-- Calculate vector to the previous segment (or head)
			local vectorToPrev = previousSegmentPos - currentPos
			local distance = vectorToPrev.Magnitude
			
			-- If we are too far or too close, we want to be exactly SEGMENT_SPACING away
			-- But for smooth rendering, we Lerp towards that desired position
			
			if distance > 0.1 then
				local direction = vectorToPrev.Unit
				local desiredPos = previousSegmentPos - (direction * SnakeConfig.SEGMENT_SPACING)
				
				-- Smoothly move towards the desired position
				-- Using a higher alpha for the lead segments ensures they stick closer to the head
				local segmentAlpha = SnakeConfig.CLIENT_INTERPOLATION_ALPHA
				segment.Position = currentPos:Lerp(desiredPos, segmentAlpha)
			end
			
			-- Update previousSegmentPos for the next iteration
			previousSegmentPos = segment.Position
		end
	end
end

-- Initialize
function SnakeRenderer:Initialize()
	if self._initialized then
		return
	end
	self._initialized = true

	table.insert(self._connections, remoteEvent.OnClientEvent:Connect(function(eventType, data)
		if eventType == "UpdateSnakes" then
			self:UpdateSnakes(data)
		end
	end))

	table.insert(self._connections, RunService.RenderStepped:Connect(function(dt)
		self:_interpolateSnakes(dt)
	end))

	print("[SnakeRenderer] Initialized")
end

return SnakeRenderer
