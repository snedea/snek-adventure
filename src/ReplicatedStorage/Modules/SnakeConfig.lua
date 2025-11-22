-- SnakeConfig.lua
-- Physics constants for snake movement and behavior

local SnakeConfig = {
	-- Movement Physics
	BASE_SPEED = 16, -- Studs per second (base movement speed)
	BOOST_MULTIPLIER = 1.8, -- Speed multiplier when boosting
	BRAKE_MULTIPLIER = 0.5, -- Speed multiplier when braking
	ROTATION_SPEED = 5, -- Radians per second for turning

	-- Body Segments
	SEGMENT_SPACING = 2.5, -- Studs between segments (compact tail)
	INITIAL_SEGMENTS = 5, -- Starting body segment count
	MAX_SEGMENTS = 100, -- Maximum snake length
	SEGMENT_SIZE = 4, -- Studs diameter for body segments
	HEAD_SIZE = 6, -- Studs diameter for head

	-- Growth
	FOOD_GROWTH_SEGMENTS = 1, -- Segments gained per food
	KILL_GROWTH_SEGMENTS = 3, -- Segments gained per kill

	-- Collision
	COLLISION_RADIUS = 3, -- Studs for collision detection
	SELF_COLLISION_GRACE = 3, -- Number of body segments ignored for self-collision

	-- Network Updates
	UPDATE_RATE = 0.05, -- Seconds between server position broadcasts (20 Hz)
	CLIENT_INTERPOLATION_ALPHA = 0.3, -- Spring dampening factor

	-- Arena Bounds
	ARENA_MIN = Vector3.new(-500, 0, -500),
	ARENA_MAX = Vector3.new(500, 0, 500),
	SPAWN_MIN = Vector3.new(-400, 0, -400),
	SPAWN_MAX = Vector3.new(400, 0, 400),

	-- Security
	MAX_MOVEMENT_DELTA = 2.0, -- Maximum studs per frame (anti-teleport)
	POSITION_TOLERANCE = 1.5, -- Allowed client-server position difference
}

return SnakeConfig
