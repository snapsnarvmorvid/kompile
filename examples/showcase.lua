--[[
	Kompile UI showcase: every element in one window. It doesn't touch the game.
	No-setup version (library included): dist/kompile-showcase.lua
]]

--#library-start (tools/bundle.py swaps this block for the inlined library)
local Library = (function()
	local url = "https://raw.githubusercontent.com/snapsnarvmorvid/Kompile/main/src/ui/Library.lua"
	if url:find("YOUR_GITHUB_USERNAME", 1, true) then
		error("[Kompile] Set your GitHub username in examples/showcase.lua, or run dist/kompile-showcase.lua instead (no setup needed).", 0)
	end
	local chunk = loadstring(game:HttpGet(url))
	if not chunk then
		error("[Kompile] Couldn't load the UI library from " .. url .. ". Check that the repo is public and the file is uploaded.", 0)
	end
	return chunk()
end)()
--#library-end

local Env = (getgenv and getgenv()) or _G
if Env.KompileShowcase and not Env.KompileShowcase.Unloaded then
	Env.KompileShowcase:Unload()
end
Env.KompileShowcase = Library

local Options = Library.Options
Library:SetFolder("Kompile/showcase")

local Window = Library:CreateWindow({
	Title = "Kompile",
	Subtitle = "UI showcase",
	Footer = "Kompile UI v" .. Library.Version,
	ToggleKey = "RightShift",
})

local Tabs = {
	Controls = Window:AddTab("Controls"),
	Inputs = Window:AddTab("Inputs"),
}

--// Controls

local Toggles = Tabs.Controls:AddLeftGroupbox("Toggles")
Toggles:AddToggle("DemoEnabled", {
	Text = "Enabled",
	Default = true,
	Tooltip = "A plain toggle. Click the row or the switch.",
})
Toggles:AddToggle("DemoKeyed", { Text = "With keybind" }):AddKeybind("DemoKeyedKey", { Default = "F" })
Toggles:AddToggle("DemoHold", { Text = "Hold to activate" }):AddKeybind("DemoHoldKey", { Default = "LeftShift", Mode = "Hold" })

local Buttons = Tabs.Controls:AddLeftGroupbox("Buttons")
local clicks = 0
local ClickLabel = Buttons:AddLabel("Button clicked 0 times.")
Buttons:AddButton({
	Text = "Click me",
	Func = function()
		clicks = clicks + 1
		ClickLabel:SetText(("Button clicked %d time%s."):format(clicks, clicks == 1 and "" or "s"))
	end,
})
Buttons:AddButton({
	Text = "Send notification",
	Tooltip = "Notifications stack in the bottom-right corner.",
	Func = function()
		Library:Notify("Kompile", "This is a notification.", 4)
	end,
})
Buttons:AddButton({
	Text = "Long notification",
	Func = function()
		Library:Notify("Heads up", "Longer messages wrap onto multiple lines, and the card slides away when its time is up.", 8)
	end,
})

local Sliders = Tabs.Controls:AddRightGroupbox("Sliders")
Sliders:AddSlider("DemoVolume", { Text = "Volume", Min = 0, Max = 100, Default = 72, Suffix = "%" })
Sliders:AddSlider("DemoDelay", { Text = "Delay", Min = 0, Max = 2, Default = 0.25, Rounding = 2, Suffix = "s" })
Sliders:AddSlider("DemoCount", { Text = "Items", Min = 1, Max = 10, Default = 4 })

local Dropdowns = Tabs.Controls:AddRightGroupbox("Dropdowns")
Dropdowns:AddDropdown("DemoMode", { Text = "Mode", Values = { "Legit", "Balanced", "Rage" }, Default = 2 })
Dropdowns:AddDropdown("DemoFruit", {
	Text = "Searchable",
	Values = { "Apple", "Banana", "Cherry", "Dragonfruit", "Grape", "Kiwi", "Lemon", "Mango", "Orange", "Peach", "Pear", "Plum" },
	Searchable = true,
	Placeholder = "Pick a fruit",
})

--// Inputs

local Text = Tabs.Inputs:AddLeftGroupbox("Text input")
Text:AddInput("DemoName", { Text = "Name", Placeholder = "Type and press Enter", Finished = true })
Text:AddInput("DemoAmount", { Text = "Amount (numbers only)", Placeholder = "0", Numeric = true })

local Live = Tabs.Inputs:AddLeftGroupbox("Live values")
local LiveLabel = Live:AddLabel("")
local function refreshLive()
	LiveLabel:SetText(table.concat({
		"Enabled: " .. tostring(Options.DemoEnabled.Value),
		"Volume: " .. tostring(Options.DemoVolume.Value) .. "%",
		"Mode: " .. tostring(Options.DemoMode.Value),
		"Fruit: " .. tostring(Options.DemoFruit.Value or "none"),
		"Name: " .. (Options.DemoName.Value ~= "" and Options.DemoName.Value or "(empty)"),
	}, "\n"))
end
for _, id in ipairs({ "DemoEnabled", "DemoVolume", "DemoMode", "DemoFruit", "DemoName" }) do
	Options[id]:OnChanged(refreshLive)
end
refreshLive()

local Keys = Tabs.Inputs:AddRightGroupbox("Keybinds")
local KeyLabel = Keys:AddLabel("Press G, hold H, or tap J.")
Keys:AddKeybind("DemoToggleKey", {
	Text = "Toggle mode",
	Default = "G",
	Mode = "Toggle",
	Callback = function(state)
		KeyLabel:SetText("Toggle mode is now " .. (state and "on." or "off."))
	end,
})
Keys:AddKeybind("DemoHoldKey2", {
	Text = "Hold mode",
	Default = "H",
	Mode = "Hold",
	Callback = function(held)
		KeyLabel:SetText(held and "Holding H…" or "Released H.")
	end,
})
Keys:AddKeybind("DemoPressKey", {
	Text = "Press mode",
	Default = "J",
	Mode = "Press",
	Callback = function()
		Library:Notify("Kompile", "You pressed the Press-mode key.", 3)
	end,
})
Keys:AddLabel("Click a key box to rebind it. Esc clears it.")

--// Settings: menu keybind, accent color, UI scale, configs

Library:BuildSettingsTab(Window)

Library:Notify("Kompile", "Showcase loaded. Right Shift hides the menu.", 5)
