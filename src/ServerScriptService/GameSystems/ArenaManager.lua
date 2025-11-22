-- ArenaManager.lua
-- Manages map loading and arena state

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MapConfig = require(ReplicatedStorage.Modules.MapConfig)
local ArenaBuilder = require(ServerScriptService.GameSystems.ArenaBuilder)

local ArenaManager = {}
ArenaManager.CurrentMap = "Classic"

function ArenaManager:Initialize()
	print("[ArenaManager] Initializing...")
	
	-- Load default map
	self:LoadMap(self.CurrentMap)
	
	print("[ArenaManager] Initialized")
end

function ArenaManager:LoadMap(mapName)
	local config = MapConfig.Maps[mapName]
	if not config then
		warn("[ArenaManager] Map not found: " .. tostring(mapName))
		return
	end
	
	self.CurrentMap = mapName
	MapConfig.CurrentMap = mapName -- Update shared state (if needed)
	
	print("[ArenaManager] Loading map: " .. config.Name)
	
	-- Build the arena
	ArenaBuilder:Initialize(config)
	
	-- TODO: Handle player respawning or teleporting if needed
end

function ArenaManager:GetCurrentMapConfig()
	return MapConfig.Maps[self.CurrentMap]
end

return ArenaManager
