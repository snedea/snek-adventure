-- SnakeVariants.lua
-- Different snake character types with unique visual styles

local SnakeVariants = {
	{
		id = "classic",
		name = "Classic Viper",
		description = "The original snake",
		color = Color3.fromRGB(255, 100, 100), -- Red
		headShape = "Ball",
		bodyShape = "Ball",
		headSize = Vector3.new(6, 6, 6),
		bodySize = Vector3.new(4, 4, 4),
		material = Enum.Material.Neon,
		unlocked = true, -- Always available
	},
	{
		id = "emerald",
		name = "Emerald Python",
		description = "Sleek and green",
		color = Color3.fromRGB(50, 255, 100), -- Bright green
		headShape = "Ball",
		bodyShape = "Ball",
		headSize = Vector3.new(6, 6, 6),
		bodySize = Vector3.new(4, 4, 4),
		material = Enum.Material.Neon,
		unlocked = true,
	},
	{
		id = "sapphire",
		name = "Sapphire Serpent",
		description = "Cool blue scales",
		color = Color3.fromRGB(100, 150, 255), -- Blue
		headShape = "Ball",
		bodyShape = "Ball",
		headSize = Vector3.new(6, 6, 6),
		bodySize = Vector3.new(4, 4, 4),
		material = Enum.Material.Neon,
		unlocked = true,
	},
	{
		id = "golden",
		name = "Golden Cobra",
		description = "Shimmering gold",
		color = Color3.fromRGB(255, 215, 0), -- Gold
		headShape = "Ball",
		bodyShape = "Cylinder",
		headSize = Vector3.new(6, 6, 6),
		bodySize = Vector3.new(4, 4, 4),
		material = Enum.Material.Neon,
		unlocked = true,
	},
	{
		id = "amethyst",
		name = "Amethyst Adder",
		description = "Purple mystic",
		color = Color3.fromRGB(200, 100, 255), -- Purple
		headShape = "Ball",
		bodyShape = "Ball",
		headSize = Vector3.new(6, 6, 6),
		bodySize = Vector3.new(4, 4, 4),
		material = Enum.Material.Neon,
		unlocked = true,
	},
	{
		id = "cube",
		name = "Cubic Constrictor",
		description = "Geometric and blocky",
		color = Color3.fromRGB(255, 255, 100), -- Yellow
		headShape = "Block",
		bodyShape = "Block",
		headSize = Vector3.new(5, 5, 5),
		bodySize = Vector3.new(3.5, 3.5, 3.5),
		material = Enum.Material.SmoothPlastic,
		unlocked = true,
	},
	{
		id = "diamond",
		name = "Diamond Diamondback",
		description = "Crystal clear beauty",
		color = Color3.fromRGB(200, 255, 255), -- Cyan
		headShape = "Ball",
		bodyShape = "Ball",
		headSize = Vector3.new(6, 6, 6),
		bodySize = Vector3.new(4, 4, 4),
		material = Enum.Material.Glass,
		transparency = 0.3,
		unlocked = true,
	},
	{
		id = "obsidian",
		name = "Obsidian Mamba",
		description = "Dark and sleek",
		color = Color3.fromRGB(50, 50, 50), -- Dark gray
		headShape = "Ball",
		bodyShape = "Ball",
		headSize = Vector3.new(6, 6, 6),
		bodySize = Vector3.new(4, 4, 4),
		material = Enum.Material.Neon,
		unlocked = true,
	},
	{
		id = "rainbow",
		name = "Rainbow Rattler",
		description = "Multicolored wonder",
		color = Color3.fromRGB(255, 100, 200), -- Pink (animated rainbow)
		headShape = "Ball",
		bodyShape = "Ball",
		headSize = Vector3.new(6, 6, 6),
		bodySize = Vector3.new(4, 4, 4),
		material = Enum.Material.Neon,
		rainbow = true, -- Special effect
		unlocked = true,
	},
	{
		id = "plasma",
		name = "Plasma Phantom",
		description = "Electric and deadly",
		color = Color3.fromRGB(100, 255, 255), -- Electric blue
		headShape = "Ball",
		bodyShape = "Cylinder",
		headSize = Vector3.new(6, 6, 6),
		bodySize = Vector3.new(4, 4, 4),
		material = Enum.Material.ForceField,
		unlocked = true,
	},
}

-- Get variant by ID
function SnakeVariants.GetVariant(id)
	for _, variant in ipairs(SnakeVariants) do
		if variant.id == id then
			return variant
		end
	end
	return SnakeVariants[1] -- Default to Classic Viper
end

-- Get all unlocked variants
function SnakeVariants.GetUnlockedVariants()
	local unlocked = {}
	for _, variant in ipairs(SnakeVariants) do
		if variant.unlocked then
			table.insert(unlocked, variant)
		end
	end
	return unlocked
end

return SnakeVariants
