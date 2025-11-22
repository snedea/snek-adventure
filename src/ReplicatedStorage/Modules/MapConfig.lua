-- MapConfig.lua
-- Configuration for different arena types

local MapConfig = {
	Maps = {
		Classic = {
			Name = "Classic Arena",
			Description = "Standard open field.",
			ArenaSize = Vector3.new(1000, 0, 1000),
			WallColor = Color3.fromRGB(255, 50, 50),
			FloorColor = Color3.fromRGB(20, 20, 20),
			GridColor = Color3.fromRGB(40, 40, 40),
			Physics = {
				Friction = 1.0, -- Normal friction
				TurnSpeedMultiplier = 1.0
			}
		},
		Maze = {
			Name = "The Maze",
			Description = "Tight corridors and deadly walls.",
			ArenaSize = Vector3.new(800, 0, 800),
			WallColor = Color3.fromRGB(50, 255, 50),
			FloorColor = Color3.fromRGB(10, 10, 30),
			GridColor = Color3.fromRGB(30, 30, 60),
			Physics = {
				Friction = 1.0,
				TurnSpeedMultiplier = 1.2 -- Sharper turns needed
			}
		},
		Space = {
			Name = "Zero-G",
			Description = "Low friction, high drift.",
			ArenaSize = Vector3.new(1200, 0, 1200),
			WallColor = Color3.fromRGB(100, 200, 255),
			FloorColor = Color3.fromRGB(0, 0, 10),
			GridColor = Color3.fromRGB(50, 50, 100),
			Physics = {
				Friction = 0.1, -- Slippery!
				TurnSpeedMultiplier = 0.8
			}
		}
	},
	
	CurrentMap = "Classic" -- Default
}

return MapConfig
