-- Theme.lua
-- Palette et styles partagés de Lumen : l'Éveil des Lueurs.
-- À utiliser dans l'interface client avec :
-- local Theme = require(ReplicatedStorage.Shared.Theme)

local Theme = {}

Theme.Colors = {
	-- Surfaces sombres pour garder un contraste lisible dans la nuit.
	Background = Color3.fromRGB(9, 13, 27),
	Panel = Color3.fromRGB(16, 23, 42),
	PanelRaised = Color3.fromRGB(25, 34, 57),
	Track = Color3.fromRGB(48, 58, 78),

	-- Lumières principales : cyan magique et or chaud de la Tour.
	Primary = Color3.fromRGB(100, 225, 255),
	PrimaryDark = Color3.fromRGB(42, 135, 177),
	Warm = Color3.fromRGB(255, 195, 112),
	WarmLight = Color3.fromRGB(255, 226, 169),

	-- États accessibles et faciles à distinguer.
	Text = Color3.fromRGB(240, 245, 255),
	MutedText = Color3.fromRGB(165, 180, 205),
	Success = Color3.fromRGB(116, 242, 169),
	Warning = Color3.fromRGB(255, 190, 95),
	Danger = Color3.fromRGB(255, 95, 112),
	Border = Color3.fromRGB(69, 92, 125),
}

Theme.Fonts = {
	Title = Enum.Font.GothamBlack,
	Heading = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
}

Theme.Sizes = {
	PanelCorner = UDim.new(0, 10),
	ButtonCorner = UDim.new(0, 8),
	BorderThickness = 1,
	PanelTransparency = 0.12,
}

function Theme.applyPanel(frame)
	frame.BackgroundColor3 = Theme.Colors.Panel
	frame.BackgroundTransparency = Theme.Sizes.PanelTransparency
	frame.BorderSizePixel = 0

	local corner = frame:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = frame
	end
	corner.CornerRadius = Theme.Sizes.PanelCorner

	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = frame
	end
	stroke.Color = Theme.Colors.Border
	stroke.Transparency = 0.35
	stroke.Thickness = Theme.Sizes.BorderThickness
end

function Theme.styleLabel(label, role)
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.Colors.Text
	label.Font = role == "Title" and Theme.Fonts.Title
		or role == "Heading" and Theme.Fonts.Heading
		or Theme.Fonts.Body
end

return Theme
