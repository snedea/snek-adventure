-- ClientInit.client.lua
-- Client initialization script for Snek Adventure

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Disable default Roblox UI elements
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Wait for player to select variant from welcome screen (or timeout after 5 seconds)
print("[ClientInit] Waiting for WelcomeScreen...")
local playerGui = player:WaitForChild("PlayerGui")
local welcomeScreen = playerGui:WaitForChild("WelcomeScreen", 5)

if welcomeScreen then
	print("[ClientInit] WelcomeScreen found, waiting for player selection...")
	-- Wait for welcome screen to be destroyed (player selected variant) with timeout
	local startTime = tick()
	while welcomeScreen.Parent and tick() - startTime < 120 do
		task.wait(0.1)
	end
	print("[ClientInit] Welcome screen closed, starting game initialization...")
else
	warn("[ClientInit] WelcomeScreen not found, continuing anyway...")
end

-- Wait for scripts to load
local playerScripts = player:WaitForChild("PlayerScripts")

-- Load controllers
local CameraController = require(playerScripts:WaitForChild("CameraController"))
local SnakeController = require(playerScripts:WaitForChild("SnakeController"))
local SnakeRenderer = require(playerScripts:WaitForChild("SnakeRenderer"))
local MobileControls = require(playerScripts:WaitForChild("MobileControls"))
local WelcomeScreenUI = require(ReplicatedStorage.Modules.WelcomeScreenUI)

-- Initialize in order
print("[Client] Initializing Snek Adventure client...")

CameraController:Initialize()
SnakeController:Initialize()
SnakeRenderer:Initialize()
MobileControls:Initialize(SnakeController)
WelcomeScreenUI.Show()

-- Set camera to arena center initially
CameraController:SetTargetPosition(Vector3.new(0, 0, 0))

print("[Client] Client initialized successfully!")
