-- ArenaBuilder.lua
-- Procedurally generates the arena floor and boundaries

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnakeConfig = require(ReplicatedStorage.Modules.SnakeConfig)

local ArenaBuilder = {}

function ArenaBuilder:Initialize(mapConfig)
	local arenaFolder = workspace:FindFirstChild("Arena")
	if arenaFolder then
		arenaFolder:Destroy() -- Clear existing arena
	end
	
	arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "Arena"
	arenaFolder.Parent = workspace

	-- Create floor
	self:CreateFloor(arenaFolder, mapConfig)

	-- Create boundary walls
	self:CreateBoundaries(arenaFolder, mapConfig)

	-- Add lighting
	self:SetupLighting()

	print("[ArenaBuilder] Arena created successfully: " .. mapConfig.Name)
end

function ArenaBuilder:CreateFloor(parent, mapConfig)
	local size = mapConfig.ArenaSize
	local sizeX = size.X
	local sizeZ = size.Z
	
	-- Main floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(sizeX, 1, sizeZ)
	floor.Position = Vector3.new(0, -0.5, 0)
	floor.Anchored = true
	floor.Material = Enum.Material.Slate
	floor.Color = mapConfig.FloorColor or Color3.fromRGB(30, 30, 40)
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = parent

	-- Grid lines for visual reference
	local gridSpacing = 100
	local minX, maxX = -sizeX/2, sizeX/2
	local minZ, maxZ = -sizeZ/2, sizeZ/2
	
	for x = minX, maxX, gridSpacing do
		local line = Instance.new("Part")
		line.Name = "GridLine"
		line.Size = Vector3.new(2, 0.1, sizeZ)
		line.Position = Vector3.new(x, 0.1, 0)
		line.Anchored = true
		line.Material = Enum.Material.Neon
		line.Color = mapConfig.GridColor or Color3.fromRGB(50, 50, 70)
		line.CanCollide = false
		line.Transparency = 0.7
		line.Parent = parent
	end

	for z = minZ, maxZ, gridSpacing do
		local line = Instance.new("Part")
		line.Name = "GridLine"
		line.Size = Vector3.new(sizeX, 0.1, 2)
		line.Position = Vector3.new(0, 0.1, z)
		line.Anchored = true
		line.Material = Enum.Material.Neon
		line.Color = mapConfig.GridColor or Color3.fromRGB(50, 50, 70)
		line.CanCollide = false
		line.Transparency = 0.7
		line.Parent = parent
	end

	print("[ArenaBuilder] Floor created")
end

function ArenaBuilder:CreateBoundaries(parent, mapConfig)
	local size = mapConfig.ArenaSize
	local sizeX = size.X
	local sizeZ = size.Z
	
	local wallHeight = 20
	local wallThickness = 2

	-- North wall
	local northWall = Instance.new("Part")
	northWall.Name = "NorthWall"
	northWall.Size = Vector3.new(sizeX + wallThickness * 2, wallHeight, wallThickness)
	northWall.Position = Vector3.new(0, wallHeight / 2, sizeZ / 2 + wallThickness / 2)
	northWall.Anchored = true
	northWall.Material = Enum.Material.ForceField
	northWall.Color = mapConfig.WallColor or Color3.fromRGB(100, 100, 255)
	northWall.Transparency = 0.3
	northWall.CanCollide = true
	northWall.Parent = parent

	-- South wall
	local southWall = Instance.new("Part")
	southWall.Name = "SouthWall"
	southWall.Size = Vector3.new(sizeX + wallThickness * 2, wallHeight, wallThickness)
	southWall.Position = Vector3.new(0, wallHeight / 2, -sizeZ / 2 - wallThickness / 2)
	southWall.Anchored = true
	southWall.Material = Enum.Material.ForceField
	southWall.Color = mapConfig.WallColor or Color3.fromRGB(100, 100, 255)
	southWall.Transparency = 0.3
	southWall.CanCollide = true
	southWall.Parent = parent

	-- East wall
	local eastWall = Instance.new("Part")
	eastWall.Name = "EastWall"
	eastWall.Size = Vector3.new(wallThickness, wallHeight, sizeZ)
	eastWall.Position = Vector3.new(sizeX / 2 + wallThickness / 2, wallHeight / 2, 0)
	eastWall.Anchored = true
	eastWall.Material = Enum.Material.ForceField
	eastWall.Color = mapConfig.WallColor or Color3.fromRGB(100, 100, 255)
	eastWall.Transparency = 0.3
	eastWall.CanCollide = true
	eastWall.Parent = parent

	-- West wall
	local westWall = Instance.new("Part")
	westWall.Name = "WestWall"
	westWall.Size = Vector3.new(wallThickness, wallHeight, sizeZ)
	westWall.Position = Vector3.new(-sizeX / 2 - wallThickness / 2, wallHeight / 2, 0)
	westWall.Anchored = true
	westWall.Material = Enum.Material.ForceField
	westWall.Color = mapConfig.WallColor or Color3.fromRGB(100, 100, 255)
	westWall.Transparency = 0.3
	westWall.CanCollide = true
	westWall.Parent = parent

	print("[ArenaBuilder] Boundary walls created")
	
	-- Generate internal obstacles for Maze
	if mapConfig.Name == "The Maze" then
		self:GenerateMazeObstacles(parent, sizeX, sizeZ, wallHeight, wallThickness, mapConfig.WallColor)
	end
end

function ArenaBuilder:GenerateMazeObstacles(parent, sizeX, sizeZ, height, thickness, color)
	local seed = Random.new()
	local numWalls = 20
	
	for i = 1, numWalls do
		local isVertical = seed:NextInteger(0, 1) == 1
		local length = seed:NextNumber(50, 150)
		
		local wall = Instance.new("Part")
		wall.Name = "MazeWall"
		wall.Anchored = true
		wall.Material = Enum.Material.Neon
		wall.Color = color or Color3.fromRGB(50, 255, 50)
		wall.Transparency = 0.2
		wall.Parent = parent
		
		-- Random position within bounds (keeping away from center spawn)
		local x = seed:NextNumber(-sizeX/2 + 50, sizeX/2 - 50)
		local z = seed:NextNumber(-sizeZ/2 + 50, sizeZ/2 - 50)
		
		-- Keep clear of center
		if math.abs(x) < 50 and math.abs(z) < 50 then
			x = x + 100
		end
		
		if isVertical then
			wall.Size = Vector3.new(thickness, height, length)
			wall.Position = Vector3.new(x, height/2, z)
		else
			wall.Size = Vector3.new(length, height, thickness)
			wall.Position = Vector3.new(x, height/2, z)
		end
	end
	
	print("[ArenaBuilder] Maze obstacles generated")
end

function ArenaBuilder:SetupLighting()
	-- Set ambient lighting for better visibility
	local lighting = game:GetService("Lighting")

	local ok, err = pcall(function()
		lighting.Ambient = Color3.fromRGB(100, 100, 120)
		lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 120)
		lighting.Brightness = 2
		lighting.GlobalShadows = false

		-- Add a skybox for depth
		local sky = Instance.new("Sky")
		sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.jpg"
		sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.jpg"
		sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.jpg"
		sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.jpg"
		sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.jpg"
		sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.jpg"
		sky.Parent = lighting
	end)

	if not ok then
		warn("[ArenaBuilder] Lighting configuration skipped:", err)
	end

	print("[ArenaBuilder] Lighting configured")
end

return ArenaBuilder
