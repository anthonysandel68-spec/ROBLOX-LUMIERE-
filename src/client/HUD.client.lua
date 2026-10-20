-- HUD.client.lua (LocalScript, StarterPlayerScripts)
-- Affiche la lumière, les cristaux, et gère la lampe torche (visuel local).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
	Normal = Theme.Colors.Primary,
	Low = Theme.Colors.Danger,
	Text = Theme.Colors.Text,
	Good = Theme.Colors.Success,
	Warn = Theme.Colors.Warning,
}
local LOW_LIGHT_RATIO = 0.25

local gui = Instance.new("ScreenGui")
gui.Name = "TowerOfLightHUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(280, 125)
panel.Position = UDim2.fromOffset(20, 20)
panel.BackgroundColor3 = COLORS.Panel
panel.BackgroundTransparency = 0.12
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
barBack.BackgroundColor3 = COLORS.Track
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
