--[[
	Kompile UI baseplate example: a small working hub (movement, fly, lighting, a part builder) for any Baseplate.
	No-setup version (library included): dist/kompile-baseplate.lua
]]

--#library-start (tools/bundle.py swaps this block for the inlined library)
local Library = (function()
	local url = "https://raw.githubusercontent.com/snapsnarvmorvid/Kompile/main/src/ui/Library.lua"
	if url:find("YOUR_GITHUB_USERNAME", 1, true) then
		error("[Kompile] Set your GitHub username in examples/baseplate.lua, or run dist/kompile-baseplate.lua instead (no setup needed).", 0)
	end
	local chunk = loadstring(game:HttpGet(url))
	if not chunk then
		error("[Kompile] Couldn't load the UI library from " .. url .. ". Check that the repo is public and the file is uploaded.", 0)
	end
	return chunk()
end)()
--#library-end

local Env = (getgenv and getgenv()) or _G
if Env.KompileBaseplate and not Env.KompileBaseplate.Unloaded then
	Env.KompileBaseplate:Unload()
end
Env.KompileBaseplate = Library

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Options = Library.Options

Library:SetFolder("Kompile/baseplate")

local function character()
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return char, humanoid, root
end

local Window = Library:CreateWindow({
	Title = "Kompile",
	Subtitle = "Baseplate example",
	Footer = "Kompile UI v" .. Library.Version,
	ToggleKey = "RightControl",
})

local Tabs = {
	Player = Window:AddTab("Player"),
	World = Window:AddTab("World"),
	Builder = Window:AddTab("Builder"),
}

------------------------------------------------------------------------------------------------------------------------
-- Player
------------------------------------------------------------------------------------------------------------------------
local Movement = Tabs.Player:AddLeftGroupbox("Movement")
Movement:AddToggle("BpSpeedOn", { Text = "Custom Walk Speed", Default = false })
Movement:AddSlider("BpSpeed", { Text = "Walk Speed", Min = 16, Max = 200, Default = 50, Rounding = 0 })
Movement:AddToggle("BpJumpOn", { Text = "Custom Jump Power", Default = false })
Movement:AddSlider("BpJump", { Text = "Jump Power", Min = 50, Max = 300, Default = 100, Rounding = 0 })
Movement:AddDivider()
Movement:AddToggle("BpInfJump", { Text = "Infinite Jump", Default = false })
Movement:AddToggle("BpNoclip", { Text = "Noclip", Default = false }):AddKeybind("BpNoclipKey", { Default = "N" })

local FlyBox = Tabs.Player:AddRightGroupbox("Fly")
FlyBox:AddToggle("BpFly", { Text = "Fly", Default = false }):AddKeybind("BpFlyKey", { Default = "F" })
FlyBox:AddSlider("BpFlySpeed", { Text = "Fly Speed", Min = 10, Max = 300, Default = 80, Rounding = 0, Suffix = " st/s" })
FlyBox:AddLabel("WASD to move, Space up, Ctrl down.")

local Look = Tabs.Player:AddRightGroupbox("Character")
Look:AddToggle("BpHighlight", { Text = "Highlight Me", Default = false })
	:AddColorPicker("BpHighlightColor", { Default = Library.Theme.Accent, Title = "Highlight colour" })
Look:AddToggle("BpSpin", { Text = "Spin", Default = false })
Look:AddSlider("BpSpinSpeed", { Text = "Spin Speed", Min = 1, Max = 50, Default = 15, Rounding = 0 })
Look:AddButton({
	Text = "Reset Character",
	Func = function()
		local _, humanoid = character()
		if humanoid then
			humanoid.Health = 0
		end
	end,
})

-- walk speed / jump power, kept while the toggles are on (the default Humanoid resets them on respawn)
local defaultSpeed, defaultJump = 16, 50
RunService.Heartbeat:Connect(function()
	if Library.Unloaded then
		return
	end
	local _, humanoid = character()
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = Options.BpSpeedOn.Value and Options.BpSpeed.Value or defaultSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = Options.BpJumpOn.Value and Options.BpJump.Value or defaultJump
end)

UserInputService.JumpRequest:Connect(function()
	if Options.BpInfJump.Value then
		local _, humanoid = character()
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

RunService.Stepped:Connect(function()
	if not Options.BpNoclip.Value then
		return
	end
	local char = character()
	for _, part in ipairs(char and char:GetDescendants() or {}) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end)

-- fly: the root follows the camera with WASD, held in place with no input
local flyVelocity, flyGyro
local function stopFly()
	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end
	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end
	local _, humanoid = character()
	if humanoid then
		humanoid.PlatformStand = false
	end
end
Options.BpFly:OnChanged(function(on)
	if not on then
		stopFly()
	end
end)
RunService.RenderStepped:Connect(function()
	if not Options.BpFly.Value or Library.Unloaded then
		return
	end
	local _, humanoid, root = character()
	if not (humanoid and root) then
		return
	end
	if not (flyVelocity and flyVelocity.Parent == root) then
		stopFly()
		flyVelocity = Instance.new("BodyVelocity")
		flyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		flyVelocity.Velocity = Vector3.zero
		flyVelocity.Parent = root
		flyGyro = Instance.new("BodyGyro")
		flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
		flyGyro.P = 9e4
		flyGyro.Parent = root
	end
	humanoid.PlatformStand = true
	local camera = Workspace.CurrentCamera
	local move = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
	flyVelocity.Velocity = move.Magnitude > 0 and move.Unit * Options.BpFlySpeed.Value or Vector3.zero
	flyGyro.CFrame = camera.CFrame
end)

-- highlight + spin
local highlight
RunService.Heartbeat:Connect(function(dt)
	local char, _, root = character()
	if Options.BpHighlight.Value and char then
		if not (highlight and highlight.Parent == char) then
			if highlight then
				highlight:Destroy()
			end
			highlight = Instance.new("Highlight")
			highlight.FillTransparency = 0.6
			highlight.Parent = char
		end
		highlight.FillColor = Options.BpHighlightColor.Value
		highlight.OutlineColor = Options.BpHighlightColor.Value
	elseif highlight then
		highlight:Destroy()
		highlight = nil
	end
	if Options.BpSpin.Value and root and not Options.BpFly.Value then
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Options.BpSpinSpeed.Value * 20 * dt), 0)
	end
end)

------------------------------------------------------------------------------------------------------------------------
-- World
------------------------------------------------------------------------------------------------------------------------
local Light = Tabs.World:AddLeftGroupbox("Lighting")
local saved = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
}
Light:AddToggle("BpFullbright", { Text = "Fullbright", Default = false })
Light:AddToggle("BpTimeOn", { Text = "Custom Time", Default = false })
Light:AddSlider("BpTime", { Text = "Time of Day", Min = 0, Max = 24, Default = 14, Rounding = 1, Suffix = " h" })
Light:AddToggle("BpNoFog", { Text = "No Fog", Default = false })

local CameraBox = Tabs.World:AddRightGroupbox("Camera")
CameraBox:AddSlider("BpFov", { Text = "Field of View", Min = 50, Max = 120, Default = 70, Rounding = 0 })
CameraBox:AddDropdown("BpTint", {
	Text = "Colour Filter",
	Values = { "None", "Warm", "Cold", "Night", "Retro" },
	Default = "None",
})

local TINTS = {
	None = { tint = Color3.new(1, 1, 1), saturation = 0, contrast = 0 },
	Warm = { tint = Color3.fromRGB(255, 225, 190), saturation = 0.1, contrast = 0.05 },
	Cold = { tint = Color3.fromRGB(190, 220, 255), saturation = -0.1, contrast = 0.05 },
	Night = { tint = Color3.fromRGB(150, 160, 255), saturation = -0.3, contrast = 0.15 },
	Retro = { tint = Color3.fromRGB(255, 240, 200), saturation = -0.6, contrast = 0.2 },
}
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "KompileBaseplateTint"
tint.Parent = Lighting

RunService.RenderStepped:Connect(function()
	if Library.Unloaded then
		return
	end
	if Options.BpFullbright.Value then
		Lighting.Brightness = 2
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(180, 180, 180)
	else
		Lighting.Brightness = saved.Brightness
		Lighting.GlobalShadows = saved.GlobalShadows
		Lighting.Ambient = saved.Ambient
	end
	Lighting.ClockTime = Options.BpTimeOn.Value and Options.BpTime.Value or saved.ClockTime
	Lighting.FogEnd = Options.BpNoFog.Value and 1e6 or saved.FogEnd
	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = Options.BpFov.Value
	end
	local look = TINTS[Options.BpTint.Value] or TINTS.None
	tint.TintColor = look.tint
	tint.Saturation = look.saturation
	tint.Contrast = look.contrast
end)

------------------------------------------------------------------------------------------------------------------------
-- Builder: parts only you can see
------------------------------------------------------------------------------------------------------------------------
local Build = Tabs.Builder:AddLeftGroupbox("Spawn Parts")
Build:AddDropdown("BpShape", { Text = "Shape", Values = { "Block", "Ball", "Cylinder", "Wedge" }, Default = "Block" })
Build:AddSlider("BpSize", { Text = "Size", Min = 1, Max = 30, Default = 6, Rounding = 0, Suffix = " st" })
Build:AddLabel("Colour"):AddColorPicker("BpPartColor", { Default = Color3.fromRGB(62, 230, 208), Title = "Part colour" })
Build:AddToggle("BpNeon", { Text = "Neon", Default = false })
Build:AddToggle("BpAnchor", { Text = "Anchored", Default = true })

local spawned = {}
local folder = Instance.new("Folder")
folder.Name = "KompileBaseplateParts"
folder.Parent = Workspace
local countLabel

local function spawnPart()
	local _, _, root = character()
	if not root then
		return Library:Notify("Builder", "No character", 3)
	end
	local size = Options.BpSize.Value
	local shape = Options.BpShape.Value
	local part = shape == "Wedge" and Instance.new("WedgePart") or Instance.new("Part")
	if shape == "Ball" then
		part.Shape = Enum.PartType.Ball
	elseif shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
	end
	part.Size = Vector3.new(size, size, size)
	part.Color = Options.BpPartColor.Value
	part.Material = Options.BpNeon.Value and Enum.Material.Neon or Enum.Material.SmoothPlastic
	part.Anchored = Options.BpAnchor.Value
	part.CFrame = root.CFrame * CFrame.new(0, size / 2, -(size + 6))
	part.Parent = folder
	table.insert(spawned, part)
	countLabel:SetText("Spawned: " .. #spawned)
end

Build:AddButton({ Text = "Spawn Part", Func = spawnPart })
Build:AddToggle("BpRain", { Text = "Part Rain", Default = false })
countLabel = Build:AddLabel("Spawned: 0")
Build:AddButton({
	Text = "Clear Parts",
	Func = function()
		for _, part in ipairs(spawned) do
			part:Destroy()
		end
		table.clear(spawned)
		countLabel:SetText("Spawned: 0")
		Library:Notify("Builder", "Cleared", 3)
	end,
})

local Fun = Tabs.Builder:AddRightGroupbox("Fun")
Fun:AddToggle("BpRainbow", { Text = "Rainbow Parts", Default = false })
Fun:AddButton({
	Text = "Launch Me",
	Func = function()
		local _, _, root = character()
		if root then
			root.AssemblyLinearVelocity = Vector3.new(0, 180, 0)
		end
	end,
})
Fun:AddButton({
	Text = "Send Notification",
	Func = function()
		Library:Notify("Kompile", "This is a notification.", 4)
	end,
})

local rainAt = 0
RunService.Heartbeat:Connect(function()
	if Library.Unloaded then
		return
	end
	if Options.BpRain.Value and os.clock() - rainAt > 0.25 then
		rainAt = os.clock()
		local _, _, root = character()
		if root then
			local part = Instance.new("Part")
			local size = math.random(2, 5)
			part.Size = Vector3.new(size, size, size)
			part.Color = Color3.fromHSV(math.random(), 0.7, 1)
			part.CFrame = CFrame.new(root.Position + Vector3.new(math.random(-30, 30), 60, math.random(-30, 30)))
			part.Parent = folder
			game:GetService("Debris"):AddItem(part, 8)
		end
	end
	if Options.BpRainbow.Value then
		local hue = (os.clock() * 0.2) % 1
		for i, part in ipairs(spawned) do
			if part.Parent then
				part.Color = Color3.fromHSV((hue + i * 0.07) % 1, 0.75, 1)
			end
		end
	end
end)

------------------------------------------------------------------------------------------------------------------------
Library:BuildSettingsTab(Window)

Library:OnUnload(function()
	stopFly()
	if highlight then
		highlight:Destroy()
	end
	tint:Destroy()
	folder:Destroy()
	Lighting.Brightness = saved.Brightness
	Lighting.ClockTime = saved.ClockTime
	Lighting.FogEnd = saved.FogEnd
	Lighting.GlobalShadows = saved.GlobalShadows
	Lighting.Ambient = saved.Ambient
	local _, humanoid = character()
	if humanoid then
		humanoid.WalkSpeed = defaultSpeed
		humanoid.JumpPower = defaultJump
	end
end)

Library:Notify("Kompile", "Baseplate example loaded. Right Control toggles the menu.", 5)
