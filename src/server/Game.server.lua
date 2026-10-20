-- Game.server.lua (Script, ServerScriptService)
-- Prototype "Tower of Light" : monde, cristaux, lumière du joueur, mission.
-- Convention Lumen : attributs de joueur "Light" et "MaxLight".

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local CONFIG = {
	MAX_LIGHT = 100,
	DRAIN_PER_SEC = 2,        -- perte de lumière hors de la Tour
	RECHARGE_PER_SEC = 15,    -- gain dans la Tour
	DARK_DAMAGE_PER_SEC = 5,  -- dégâts quand la lumière est à 0
	TICK = 0.25,

	CRYSTALS_TO_WIN = 5,
	CRYSTAL_COUNT = 14,
	CRYSTAL_MIN_DIST = 65,
	CRYSTAL_MAX_DIST = 190,

	TREE_COUNT = 100,
	TREE_CLEARANCE = 12,      -- aucun arbre à moins de 12 studs d'un cristal
	WORLD_SIZE = 500,
	SAFE_ZONE_SIZE = 55,
	SEED = 2026,
}

------------------------------------------------------------------
-- AMBIANCE
------------------------------------------------------------------
local function setupAmbience()
	Lighting.ClockTime = 0
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(12, 15, 30)
	Lighting.OutdoorAmbient = Color3.fromRGB(5, 8, 18)

	for _, name in ipairs({ "TolAtmosphere", "TolBloom", "TolColor" }) do
		local old = Lighting:FindFirstChild(name)
		if old then old:Destroy() end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "TolAtmosphere"
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.18
	atmosphere.Color = Color3.fromRGB(45, 50, 75)
	atmosphere.Decay = Color3.fromRGB(16, 20, 35)
	atmosphere.Glare = 0.12
	atmosphere.Haze = 1.4
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "TolBloom"
	bloom.Intensity = 0.85
	bloom.Size = 32
	bloom.Threshold = 0.82
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "TolColor"
	color.Contrast = 0.12
	color.Saturation = -0.04
	color.Brightness = -0.025
	color.TintColor = Color3.fromRGB(255, 235, 210)
	color.Parent = Lighting
end

------------------------------------------------------------------
-- MONDE
------------------------------------------------------------------
local oldWorld = workspace:FindFirstChild("TowerOfLightWorld")
if oldWorld then oldWorld:Destroy() end

local world = Instance.new("Folder")
world.Name = "TowerOfLightWorld"
world.Parent = workspace

local function makePart(name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = world
	return part
end

setupAmbience()
workspace:SetAttribute("CrystalsToWin", CONFIG.CRYSTALS_TO_WIN) -- lu par le HUD

makePart("ForestGround", Vector3.new(CONFIG.WORLD_SIZE, 2, CONFIG.WORLD_SIZE),
	Vector3.new(0, -1, 0), Color3.fromRGB(18, 35, 23), Enum.Material.Grass)

makePart("Tower", Vector3.new(16, 32, 16), Vector3.new(0, 16, 0),
	Color3.fromRGB(65, 65, 80), Enum.Material.Slate)

local beacon = makePart("TowerBeacon", Vector3.new(8, 2, 8), Vector3.new(0, 33, 0),
	Color3.fromRGB(100, 220, 255), Enum.Material.Neon)
local beaconLight = Instance.new("PointLight")
beaconLight.Brightness = 3
beaconLight.Range = 70
beaconLight.Color = beacon.Color
beaconLight.Parent = beacon

-- Zone de sécurité (convention Lumen : Part "TowerSafeZone" dans Workspace)
local safeZone = Instance.new("Part")
safeZone.Name = "TowerSafeZone"
safeZone.Size = Vector3.new(CONFIG.SAFE_ZONE_SIZE, 30, CONFIG.SAFE_ZONE_SIZE)
safeZone.Position = Vector3.new(0, 15, 0)
safeZone.Transparency = 1
safeZone.Anchored = true
safeZone.CanCollide = false
safeZone.CanTouch = false
safeZone.CanQuery = false
safeZone.Parent = workspace

-- Point d'apparition DANS la zone de sécurité (sinon on apparaît dans la Tour)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "TowerSpawn"
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 0.5, 20)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Material = Enum.Material.Slate
spawn.Color = Color3.fromRGB(65, 65, 80)
spawn.Parent = world

local function isInSafeZone(position)
	local half = CONFIG.SAFE_ZONE_SIZE / 2
	return math.abs(position.X) <= half and math.abs(position.Z) <= half
end

------------------------------------------------------------------
-- CRISTAUX (positions calculées d'abord, pour garder les arbres à distance)
------------------------------------------------------------------
local random = Random.new(CONFIG.SEED)
local crystalPositions = {}

for i = 1, CONFIG.CRYSTAL_COUNT do
	local angle = (i / CONFIG.CRYSTAL_COUNT) * math.pi * 2
	local distance = random:NextNumber(CONFIG.CRYSTAL_MIN_DIST, CONFIG.CRYSTAL_MAX_DIST)
	table.insert(crystalPositions, Vector3.new(math.cos(angle) * distance, 3, math.sin(angle) * distance))
end

-- Arbres
local half = CONFIG.WORLD_SIZE / 2 - 30
for _ = 1, CONFIG.TREE_COUNT do
	local x = random:NextNumber(-half, half)
	local z = random:NextNumber(-half, half)
	local pos2D = Vector3.new(x, 0, z)

	local tooClose = Vector2.new(x, z).Magnitude <= 40 -- autour de la Tour
	if not tooClose then
		for _, c in ipairs(crystalPositions) do
			if (Vector3.new(c.X, 0, c.Z) - pos2D).Magnitude < CONFIG.TREE_CLEARANCE then
				tooClose = true
				break
			end
		end
	end

	if not tooClose then
		local height = random:NextNumber(12, 24)
		makePart("TreeTrunk", Vector3.new(3, height, 3), Vector3.new(x, height / 2, z),
			Color3.fromRGB(70, 45, 30), Enum.Material.Wood)
		local leaves = makePart("TreeLeaves", Vector3.new(12, 12, 12), Vector3.new(x, height + 3, z),
			Color3.fromRGB(15, 45, 25), Enum.Material.Grass)
		leaves.Shape = Enum.PartType.Ball
	end
end

local crystalFolder = Instance.new("Folder")
crystalFolder.Name = "Crystals"
crystalFolder.Parent = world

for _, position in ipairs(crystalPositions) do
	local crystal = Instance.new("Part")
	crystal.Name = "LightCrystal"
	crystal.Shape = Enum.PartType.Ball
	crystal.Size = Vector3.new(3, 3, 3)
	crystal.Position = position
	crystal.Anchored = true
	crystal.Material = Enum.Material.Neon
	crystal.Color = Color3.fromRGB(70, 220, 255)
	crystal.Parent = crystalFolder

	local glow = Instance.new("PointLight")
	glow.Color = crystal.Color
	glow.Brightness = 1.5
	glow.Range = 12
	glow.Parent = crystal

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Récupérer"
	prompt.ObjectText = "Cristal de lumière"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.Parent = crystal

	prompt.Triggered:Connect(function(player)
		if crystal:GetAttribute("Collected") then return end
		crystal:SetAttribute("Collected", true)

		local stats = player:FindFirstChild("leaderstats")
		local count = stats and stats:FindFirstChild("Cristaux")
		if count then
			count.Value += 1
		end
		crystal:Destroy()
	end)
end

------------------------------------------------------------------
-- JOUEURS
------------------------------------------------------------------
local function setupPlayer(player)
	if player:FindFirstChild("leaderstats") then return end

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local count = Instance.new("IntValue")
	count.Name = "Cristaux"
	count.Value = 0
	count.Parent = stats

	player:SetAttribute("MaxLight", CONFIG.MAX_LIGHT)
	player:SetAttribute("Light", CONFIG.MAX_LIGHT)
	player:SetAttribute("MissionDone", false)

	-- Lumière pleine à chaque réapparition
	player.CharacterAdded:Connect(function()
		player:SetAttribute("Light", player:GetAttribute("MaxLight"))
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

------------------------------------------------------------------
-- BOUCLE PRINCIPALE (lumière + mission)
------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(CONFIG.TICK)

		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local light = player:GetAttribute("Light")
			local maxLight = player:GetAttribute("MaxLight")

			if root and humanoid and humanoid.Health > 0 and light and maxLight then
				local inside = isInSafeZone(root.Position)

				if inside then
					light += CONFIG.RECHARGE_PER_SEC * CONFIG.TICK
				else
					light -= CONFIG.DRAIN_PER_SEC * CONFIG.TICK
				end
				light = math.clamp(light, 0, maxLight)
				player:SetAttribute("Light", light)

				if light <= 0 then
					humanoid:TakeDamage(CONFIG.DARK_DAMAGE_PER_SEC * CONFIG.TICK)
				end

				local stats = player:FindFirstChild("leaderstats")
				local count = stats and stats:FindFirstChild("Cristaux")
				if count and inside
					and count.Value >= CONFIG.CRYSTALS_TO_WIN
					and not player:GetAttribute("MissionDone") then

					player:SetAttribute("MissionDone", true)
					player:SetAttribute("Light", maxLight)
					print(player.Name .. " a terminé Tower of Light !")
				end
			end
		end
	end
end)

print("Tower of Light chargé !")
