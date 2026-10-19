#PROJET : Lumen, l'Éveil des Lueurs (Roblox) - FICHIER UNIQUE
ROBLOX-LUMIERE-
[TowerOfLight_COMPLET(1).md](https://github.com/user-attachments/files/33685463/TowerOfLight_COMPLET.1.md)
# PROJET : Lumen, l'Éveil des Lueurs (Roblox) - FICHIER UNIQUE

Ce fichier contient TOUT le projet : le résumé, l'état d'avancement et le code
complet de chaque script (avec son emplacement). À donner tel quel à une IA
pour qu'elle continue le travail.

## Concept
Le soleil s'est éteint. Les joueurs sont des "Allumeurs" qui explorent un monde
sombre pour récolter de la lumière, élever des compagnons (les "Lueurs") et
rallumer la Tour centrale. La LUMIÈRE est à la fois la vision, l'arme, la
monnaie et le but collectif.

## Conventions techniques
- Luau, Roblox Studio, synchronisation possible avec Rojo.
- Attributs de joueur : "Light", "MaxLight", "MissionDone" (à venir : "Level", "XP", "Coins", "Class").
- Zone de sécurité : Part "TowerSafeZone" dans Workspace.
- Une table CONFIG en haut de chaque script. Un script = une responsabilité.
- Logique côté serveur (Script), affichage côté client (LocalScript), RemoteEvent dans ReplicatedStorage.
- Ne jamais faire confiance au client (dégâts, lumière, pièces, XP).
- Code commenté en français.

## Vision du jeu (à développer dans l'ordre)
- Direction artistique : stylisé et féerique, contraste obscurité / lumière chaude,
  Bloom, Atmosphere, UI cohérente (module Theme).
- Introduction : parents enlevés par les Ombres, le joueur est recueilli par les
  Moines de Lumière (cinématique skippable, jouée une seule fois).
- Monastère (hub dans la zone de sécurité) : autel des classes, forgeron,
  boutique de skins (plus tard).
- Classes : Lumière Bleue (mage/contrôle), Blanche (soutien), Grise (polyvalent),
  Noire (assassin), Démon (classe spéciale à débloquer).
- Combat : pièces (équipement) + éclats (lumière/Tour) + XP et niveaux.
  Armes : épée, hache, katana, dague, lance, arc de lumière. Dégâts validés côté serveur.
- Donjons de lumière : tier = clamp(floor(distance_à_la_Tour / 200) + 1, 1, 6),
  3 salles + boss (2 à 3 phases, attaques annoncées), cristaux de recharge,
  coffre de récompenses.

## État d'avancement
FAIT : prototype Tower of Light (monde généré, Tour, zone de sécurité, point
d'apparition, lumière qui baisse hors de la Tour et se recharge dedans, 14
cristaux dont 5 à rapporter, lampe torche, HUD, ambiance Bloom/Atmosphere).

À FAIRE, dans cet ordre :
1. Module Theme (UI) + ambiance finale
2. Données joueur : DataStore + attributs Level, XP, Coins, Class
3. Ombres (ennemis) : IA simple, vie, dégâts, récompenses (pièces + XP)
4. Combat et armes (épée d'abord)
5. Niveaux et XP, interface de progression
6. Monastère, PNJ moines, forgeron
7. Classes
8. Cinématique d'introduction
9. Barre de lumière collective de la Tour
10. Donjons puis boss
11. Lueurs, skins, classe Démon, événements

## Installation (Rojo)
1. Installer Rojo. 2. `rojo serve` dans le dossier. 3. Connecter Studio via le plugin Rojo. 4. Play (F5).
Sans Rojo : créer les scripts à la main dans Studio avec les emplacements ci-dessous.

---

## FICHIER : default.project.json (racine du projet)
```json
{
  "name": "TowerOfLight",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage"
    },
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "Game": {
        "$path": "src/server/Game.server.lua"
      }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "HUD": {
          "$path": "src/client/HUD.client.lua"
        }
      }
    }
  }
}
```

## FICHIER : src/server/Game.server.lua  (Script dans ServerScriptService)
```lua
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
	atmosphere.Density = 0.4
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(20, 25, 50)
	atmosphere.Decay = Color3.fromRGB(10, 12, 30)
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "TolBloom"
	bloom.Intensity = 0.7
	bloom.Size = 28
	bloom.Threshold = 0.9
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "TolColor"
	color.Contrast = 0.1
	color.Saturation = 0.1
	color.TintColor = Color3.fromRGB(235, 240, 255)
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
```

## FICHIER : src/client/HUD.client.lua  (LocalScript dans StarterPlayer > StarterPlayerScripts)
```lua
-- HUD.client.lua (LocalScript, StarterPlayerScripts)
-- Affiche la lumière, les cristaux, et gère la lampe torche (visuel local).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
	Normal = Color3.fromRGB(65, 220, 255),
	Low = Color3.fromRGB(255, 65, 75),
	Text = Color3.fromRGB(235, 245, 255),
	Good = Color3.fromRGB(100, 255, 140),
	Warn = Color3.fromRGB(255, 100, 100),
}
local LOW_LIGHT_RATIO = 0.25

local gui = Instance.new("ScreenGui")
gui.Name = "TowerOfLightHUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(280, 125)
panel.Position = UDim2.fromOffset(20, 20)
panel.BackgroundColor3 = Color3.fromRGB(12, 17, 32)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local function makeLabel(text, y, height, size)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, height)
	label.Position = UDim2.fromOffset(10, y)
	label.BackgroundTransparency = 1
	label.TextColor3 = COLORS.Text
	label.Font = Enum.Font.GothamBold
	label.TextSize = size or 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = panel
	return label
end

makeLabel("TOWER OF LIGHT", 6, 24, 18)
local energyLabel = makeLabel("Lumière : 100%", 34, 22)
local crystalLabel = makeLabel("Cristaux : 0 / 5", 58, 22)
local statusLabel = makeLabel("Explore la forêt", 82, 22, 12)

local barBack = Instance.new("Frame")
barBack.Size = UDim2.new(1, -20, 0, 8)
barBack.Position = UDim2.fromOffset(10, 110)
barBack.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
barBack.BorderSizePixel = 0
barBack.Parent = panel
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 4)

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(1, 1)
bar.BackgroundColor3 = COLORS.Normal
bar.BorderSizePixel = 0
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

-- Lampe torche (visuelle, locale)
local function setupFlashlight(character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then return end

	local old = root:FindFirstChild("FlashlightAttachment")
	if old then old:Destroy() end

	local attachment = Instance.new("Attachment")
	attachment.Name = "FlashlightAttachment"
	attachment.Parent = root

	local light = Instance.new("SpotLight")
	light.Name = "PlayerFlashlight"
	light.Brightness = 3
	light.Range = 40
	light.Angle = 65
	light.Face = Enum.NormalId.Front
	light.Color = Color3.fromRGB(190, 225, 255)
	light.Parent = attachment
end

if player.Character then
	setupFlashlight(player.Character)
end
player.CharacterAdded:Connect(setupFlashlight)

-- Données
local stats = player:WaitForChild("leaderstats")
local crystals = stats:WaitForChild("Cristaux")

local function updateHUD()
	local maxLight = player:GetAttribute("MaxLight") or 100
	local value = math.clamp(player:GetAttribute("Light") or 0, 0, maxLight)
	local ratio = value / maxLight
	local goal = workspace:GetAttribute("CrystalsToWin") or 5
	local done = player:GetAttribute("MissionDone")

	energyLabel.Text = "Lumière : " .. math.floor(ratio * 100) .. "%"
	crystalLabel.Text = "Cristaux : " .. crystals.Value .. " / " .. goal
	TweenService:Create(bar, TweenInfo.new(0.2), { Size = UDim2.fromScale(ratio, 1) }):Play()
	bar.BackgroundColor3 = (ratio <= LOW_LIGHT_RATIO) and COLORS.Low or COLORS.Normal

	if done then
		statusLabel.Text = "MISSION TERMINÉE !"
		statusLabel.TextColor3 = COLORS.Good
	elseif ratio <= LOW_LIGHT_RATIO then
		statusLabel.Text = "Attention : lumière faible !"
		statusLabel.TextColor3 = COLORS.Warn
	elseif ratio >= 0.99 then
		statusLabel.Text = "Tu es en sécurité"
		statusLabel.TextColor3 = COLORS.Good
	else
		statusLabel.Text = "Trouve " .. goal .. " cristaux et reviens"
		statusLabel.TextColor3 = COLORS.Text
	end
end

player:GetAttributeChangedSignal("Light"):Connect(updateHUD)
player:GetAttributeChangedSignal("MaxLight"):Connect(updateHUD)
player:GetAttributeChangedSignal("MissionDone"):Connect(updateHUD)
workspace:GetAttributeChangedSignal("CrystalsToWin"):Connect(updateHUD)
crystals.Changed:Connect(updateHUD)

updateHUD()
```
