-- SnakeController.lua
-- Input capture (mouse/touch), movement requests, local prediction

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SnakeConfig = require(ReplicatedStorage.Modules.SnakeConfig)
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GameEvent")

local SnakeController = {}
SnakeController.CurrentDirection = Vector3.new(1, 0, 0) -- Default: right
SnakeController.LastSentDirection = Vector3.new(1, 0, 0)
SnakeController.LastSendTime = 0
SnakeController.MobileControls = nil -- Set by MobileControls script
SnakeController._initialized = false

-- Threshold for sending updates (to reduce network traffic)
local UPDATE_THRESHOLD = 0.05 -- 20 Hz

-- Initializes controller
function SnakeController:Initialize()
	if self._initialized then
		return
	end
	self._initialized = true

	-- Desktop input (mouse)
	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement then
			self:_handleMouseInput(input)
		end
	end)

	-- Boost/Brake keys and gamepad buttons
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		-- Keyboard
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.W then
			-- Boost
			remoteEvent:FireServer("ActivateBoost")
		elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.S then
			-- Brake
			remoteEvent:FireServer("ActivateBrake")
		-- Gamepad buttons
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.ButtonR1 then
			-- Right trigger/bumper = Boost
			remoteEvent:FireServer("ActivateBoost")
		elseif input.KeyCode == Enum.KeyCode.ButtonL2 or input.KeyCode == Enum.KeyCode.ButtonL1 then
			-- Left trigger/bumper = Brake
			remoteEvent:FireServer("ActivateBrake")
		end
	end)

	-- Gamepad thumbstick input (processed every frame)
	-- Send direction updates at throttled rate
	RunService.Heartbeat:Connect(function()
		-- Check for gamepad input (more efficient method)
		if UserInputService.GamepadEnabled then
			local stickInput = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)

			-- Find left thumbstick input
			for _, inputObject in ipairs(stickInput) do
				if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 then
					local stickPos = inputObject.Position

					-- Apply deadzone (0.2) to prevent drift
					if stickPos.Magnitude > 0.2 then
						-- Convert stick position to world direction
						-- X = left/right, Y = up/down (inverted for proper direction)
						local direction = Vector3.new(stickPos.X, 0, -stickPos.Y)
						self.CurrentDirection = direction.Unit
					end
					break -- Found thumbstick, no need to continue loop
				end
			end
		end

		self:_sendDirectionUpdate()
	end)

	print("[SnakeController] Initialized (Gamepad support enabled)")
end

-- Handles mouse input
function SnakeController:_handleMouseInput(input)
	-- Get mouse position in world
	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	-- Project to Y=2 plane (snake height)
	local t = (2 - ray.Origin.Y) / ray.Direction.Y
	local worldPos = ray.Origin + ray.Direction * t

	-- Get snake position (use camera position as approximation)
	local snakePos = camera.CFrame.Position

	-- Calculate direction
	local direction = (worldPos - snakePos)
	direction = Vector3.new(direction.X, 0, direction.Z) -- Flatten to XZ plane

	if direction.Magnitude > 0.1 then
		self.CurrentDirection = direction.Unit
	end
end

-- Sets direction from mobile controls
function SnakeController:SetDirection(direction)
	if direction.Magnitude > 0.1 then
		self.CurrentDirection = direction.Unit
	end
end

-- Sends direction update to server (throttled)
function SnakeController:_sendDirectionUpdate()
	local now = os.clock()

	-- Check if direction changed significantly or enough time passed
	local directionChanged = (self.CurrentDirection - self.LastSentDirection).Magnitude > 0.1
	local timePassed = (now - self.LastSendTime) > UPDATE_THRESHOLD

	if directionChanged or timePassed then
		remoteEvent:FireServer("MoveSnake", self.CurrentDirection)
		self.LastSentDirection = self.CurrentDirection
		self.LastSendTime = now
	end
end

return SnakeController
