-- CameraController.lua
-- Zoom controls, FOV scaling by snake size, pinch/pan for mobile

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CameraController = {}
CameraController.ZoomLevel = 50 -- Current interpolated zoom
CameraController.TargetZoomLevel = 50 -- Desired zoom target
CameraController.MinZoom = 5
CameraController.MaxZoom = 150
CameraController.TargetPosition = Vector3.new(0, 0, 0)
CameraController._initialized = false

-- Initialize camera
function CameraController:Initialize()
	if self._initialized then
		return
	end
	self._initialized = true

	camera.CameraType = Enum.CameraType.Scriptable

	-- Desktop zoom (mouse wheel)
	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseWheel then
			-- "Glide" feel: Adjust target, let update loop interpolate
			-- Sensitivity: 10 studs per click
			self.TargetZoomLevel = math.clamp(self.TargetZoomLevel - input.Position.Z * 10, self.MinZoom, self.MaxZoom)
		end
	end)

	-- Toggle Zoom Key (Z)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- We ignore gameProcessed here to ensure it works even if some UI is consuming input (unless typing)
		if gameProcessed then 
			-- Check if it's a textbox, otherwise allow Z
			local focused = UserInputService:GetFocusedTextBox()
			if focused then return end
		end
		
		if input.KeyCode == Enum.KeyCode.Z then
			print("[CameraController] Z key pressed. Toggling zoom.")
			self:ToggleZoom()
		end
	end)

	-- Mobile pinch zoom
	if UserInputService.TouchEnabled then
		self:_setupMobilePinchZoom()
	end

	-- Update camera every frame
	RunService.RenderStepped:Connect(function(dt)
		self:_updateCamera(dt)
	end)

	print("[CameraController] Initialized")
end

-- Toggles between Min and Max zoom
function CameraController:ToggleZoom()
	-- If we are closer to min (POV), go to max. Otherwise go to min.
	local midPoint = (self.MinZoom + self.MaxZoom) / 2
	if self.TargetZoomLevel < midPoint then
		self.TargetZoomLevel = self.MaxZoom
	else
		self.TargetZoomLevel = self.MinZoom
	end
end

-- Updates camera position
function CameraController:_updateCamera(dt)
	-- Smoothly interpolate ZoomLevel towards TargetZoomLevel
	-- "Glide" effect: 5 * dt gives a nice slide.
	self.ZoomLevel = self.ZoomLevel + (self.TargetZoomLevel - self.ZoomLevel) * math.min(dt * 5, 1)

	-- Get local player's snake head from Snakes folder
	local snakesFolder = workspace:FindFirstChild("Snakes")
	if not snakesFolder then return end
	
	local snakeHead = snakesFolder:FindFirstChild(player.Name .. "_Head")
	if not snakeHead then return end
	
	self.TargetPosition = snakeHead.Position
	
	-- Get direction from SnakeController
	local SnakeController = require(script.Parent.SnakeController)
	local direction = SnakeController.CurrentDirection or Vector3.new(1, 0, 0)
	
	-- Calculate interpolation factor t (0 = MinZoom/POV, 1 = MaxZoom/TopDown)
	local t = math.clamp((self.ZoomLevel - self.MinZoom) / (self.MaxZoom - self.MinZoom), 0, 1)
	
	-- Calculate Pitch (Angle down)
	-- t=0 (POV): -10 degrees (looking forward/slightly down)
	-- t=1 (Top): -90 degrees (looking straight down)
	local pitch = -10 + (-80 * t)
	
	-- Calculate LookAhead (Where we look relative to head)
	-- t=0 (POV): Look 30 studs ahead
	-- t=1 (Top): Look at head
	local lookAhead = direction * (40 * (1 - t))
	local lookTarget = self.TargetPosition + lookAhead
	
	-- Calculate Camera Position
	-- We rotate a backward vector by the pitch and yaw
	local yawRotation = CFrame.lookAt(Vector3.zero, direction)
	local pitchRotation = CFrame.Angles(math.rad(pitch), 0, 0)
	
	-- Offset: When zoomed in (t=0), we want to be slightly above/behind head
	-- Head radius is ~3. We want to be maybe 4 studs up, 4 studs back?
	-- self.ZoomLevel handles the "back" distance mostly.
	
	local offsetVector = Vector3.new(0, 0, self.ZoomLevel)
	
	-- Combine rotations: Yaw -> Pitch -> Offset
	local finalOffset = yawRotation * pitchRotation * offsetVector
	
	-- Add a small vertical offset for POV so we aren't inside the floor
	if self.ZoomLevel < 10 then
		finalOffset = finalOffset + Vector3.new(0, 3, 0)
	end
	
	local cameraPos = self.TargetPosition + finalOffset
	
	-- Smoothly interpolate camera CFrame
	local targetCFrame = CFrame.new(cameraPos, lookTarget)
	camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.2) -- Smooth damping
	
	-- Adjust FOV based on zoom (wider FOV when zoomed out)
	local fov = math.clamp(50 + (self.ZoomLevel - 50) * 0.3, 60, 90)
	camera.FieldOfView = fov
end

-- Sets target position (called by SnakeRenderer)
function CameraController:SetTargetPosition(position)
	self.TargetPosition = position
end

-- Mobile pinch zoom setup
function CameraController:_setupMobilePinchZoom()
	local lastPinchDistance = nil

	UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
		if state == Enum.UserInputState.Begin then
			lastPinchDistance = (touchPositions[1] - touchPositions[2]).Magnitude
		elseif state == Enum.UserInputState.Change then
			local currentDistance = (touchPositions[1] - touchPositions[2]).Magnitude
			local delta = currentDistance - lastPinchDistance
			self.TargetZoomLevel = math.clamp(self.TargetZoomLevel - delta * 0.1, self.MinZoom, self.MaxZoom)
			lastPinchDistance = currentDistance
		end
	end)
end

return CameraController
