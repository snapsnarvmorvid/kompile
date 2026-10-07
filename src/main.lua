--[[
	Kompile — script hub
	UI: Kompile UI (src/ui/Library.lua)
]]

return function(Config)
	local Settings = {
		Version = "1.0.0",
		Discord = "discord.gg/your-invite",
		Folder = "Kompile",
	}

	local Repo = Config.Repo

	local Players = game:GetService("Players")
	local Lighting = game:GetService("Lighting")
	local TeleportService = game:GetService("TeleportService")
	local HttpService = game:GetService("HttpService")
	local MarketplaceService = game:GetService("MarketplaceService")
	local VirtualUser = game:GetService("VirtualUser")
	local Workspace = game:GetService("Workspace")

	local LocalPlayer = Players.LocalPlayer
	local Env = (getgenv and getgenv()) or _G

	local function fetch(url, name)
		local ok, result = pcall(function()
			local chunk, err = loadstring(game:HttpGet(url), "=" .. name)
			if not chunk then
				error(err, 0)
			end
			return chunk()
		end)
		if not ok then
			warn("[Kompile] Failed to load " .. name .. ": " .. tostring(result))
			return nil
		end
		return result
	end

	-- Repo file by path. The standalone build (dist/kompile.lua) passes every file in
	-- Config.Modules, so nothing is downloaded; otherwise it comes from GitHub.
	local function loadFile(path)
		local bundled = Config.Modules and Config.Modules[path]
		if bundled then
			local ok, result = pcall(bundled)
			if not ok then
				warn("[Kompile] Failed to load " .. path .. ": " .. tostring(result))
				return nil
			end
			return result
		end
		if not Repo then
			warn("[Kompile] " .. path .. " isn't bundled and no repo is set.")
			return nil
		end
		return fetch(Repo .. path, path)
	end

	-- Re-executing replaces the running instance instead of stacking a second window.
	if Env.Kompile and Env.Kompile.Library and not Env.Kompile.Library.Unloaded then
		pcall(function()
			Env.Kompile.Library:Unload()
		end)
	end

	local Library = loadFile("src/ui/Library.lua")
	if not Library then
		return
	end
	Env.Kompile = { Library = Library, Version = Settings.Version }

	local Options = Library.Options
	Library:SetFolder(Settings.Folder .. "/" .. tostring(game.GameId))

	local function notify(text, duration)
		Library:Notify("Kompile", text, duration)
	end

	local Connections = {}
	local function track(connection)
		table.insert(Connections, connection)
		return connection
	end

	local GameName = "Unknown game"
	pcall(function()
		GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
	end)
	local hasExecutor, executorName = pcall(identifyexecutor)
	local Executor = hasExecutor and executorName or "Unknown"

	local Window = Library:CreateWindow({
		Title = "Kompile",
		Subtitle = GameName,
		Footer = "Kompile v" .. Settings.Version,
		ToggleKey = "RightControl",
	})

	local Tabs = {
		Home = Window:AddTab("Home"),
		Game = Window:AddTab("Game"),
		Scripts = Window:AddTab("Scripts"),
		Utility = Window:AddTab("Utility"),
	}

	--// Home

	local Welcome = Tabs.Home:AddLeftGroupbox("Welcome")
	Welcome:AddLabel("Hey " .. LocalPlayer.DisplayName .. ", welcome to Kompile.")
	Welcome:AddDivider()
	Welcome:AddLabel("Game: " .. GameName)
	Welcome:AddLabel("Place ID: " .. tostring(game.PlaceId))
	Welcome:AddLabel("Executor: " .. tostring(Executor))

	local About = Tabs.Home:AddRightGroupbox("Kompile")
	About:AddLabel("Version " .. Settings.Version)
	About:AddLabel("Toggle the menu with Right Control. You can rebind it in Settings.")
	About:AddButton({
		Text = "Copy Discord invite",
		Func = function()
			if setclipboard then
				setclipboard(Settings.Discord)
				notify("Discord invite copied.")
			else
				notify(Settings.Discord, 8)
			end
		end,
	})

	--// Game: per-game module, looked up by universe id

	local GameModules = loadFile("games/registry.lua") or {}
	local modulePath = GameModules[game.GameId]

	if modulePath then
		local module = loadFile(modulePath)
		local ok, err = pcall(module, {
			Library = Library,
			Window = Window,
			Tab = Tabs.Game,
			Options = Options,
			Track = track,
			Notify = notify,
		})
		if not ok then
			warn("[Kompile] " .. modulePath .. " errored: " .. tostring(err))
			notify("The module for this game failed to load. Check the console.", 6)
		end
	else
		local Unsupported = Tabs.Game:AddLeftGroupbox("No module yet")
		Unsupported:AddLabel("Kompile has no tools for " .. GameName .. " yet. Universal tools are in the Utility tab.")
	end

	--// Scripts

	local ScriptList = loadFile("scripts/registry.lua") or {}
	local ScriptBox = Tabs.Scripts:AddLeftGroupbox("Script library")

	if #ScriptList == 0 then
		ScriptBox:AddLabel("No scripts registered yet. Add them in scripts/registry.lua.")
	else
		local names, byName = {}, {}
		for _, entry in ipairs(ScriptList) do
			table.insert(names, entry.Name)
			byName[entry.Name] = entry
		end

		local Description = ScriptBox:AddLabel(ScriptList[1].Description or "")

		ScriptBox:AddDropdown("ScriptPicker", {
			Text = "Script",
			Values = names,
			Default = 1,
			Searchable = true,
			Save = false,
			Callback = function(name)
				local entry = byName[name]
				Description:SetText(entry and entry.Description or "")
			end,
		})

		ScriptBox:AddButton({
			Text = "Execute",
			Func = function()
				local entry = byName[Options.ScriptPicker.Value]
				if not entry then
					return
				end
				notify("Running " .. entry.Name .. "…")
				task.spawn(fetch, entry.Url, entry.Name)
			end,
		})
	end

	--// Utility

	local Camera = Tabs.Utility:AddLeftGroupbox("Camera")
	local DefaultFov = Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView or 70

	Camera:AddSlider("FieldOfView", {
		Text = "Field of view",
		Default = math.floor(DefaultFov + 0.5),
		Min = 30,
		Max = 120,
		Rounding = 0,
		Suffix = "°",
		Callback = function(value)
			if Workspace.CurrentCamera then
				Workspace.CurrentCamera.FieldOfView = value
			end
		end,
	})

	local Bright = {
		Brightness = 2,
		ClockTime = 14,
		FogEnd = 100000,
		GlobalShadows = false,
		Ambient = Color3.fromRGB(178, 178, 178),
		OutdoorAmbient = Color3.fromRGB(178, 178, 178),
	}
	local savedLighting, brightConnection

	local function applyBright()
		for property, value in pairs(Bright) do
			if Lighting[property] ~= value then
				Lighting[property] = value
			end
		end
	end

	local function setFullbright(enabled)
		if enabled then
			if not savedLighting then
				savedLighting = {}
				for property in pairs(Bright) do
					savedLighting[property] = Lighting[property]
				end
			end
			applyBright()
			brightConnection = brightConnection or Lighting.Changed:Connect(applyBright)
		else
			if brightConnection then
				brightConnection:Disconnect()
				brightConnection = nil
			end
			if savedLighting then
				for property, value in pairs(savedLighting) do
					Lighting[property] = value
				end
				savedLighting = nil
			end
		end
	end

	Camera:AddToggle("Fullbright", {
		Text = "Fullbright",
		Default = false,
		Callback = setFullbright,
	}):AddKeybind("FullbrightKey", { Default = "None" })

	local Session = Tabs.Utility:AddRightGroupbox("Session")
	local afkConnection

	Session:AddToggle("AntiAfk", {
		Text = "Anti-AFK",
		Tooltip = "Stops Roblox from kicking you after 20 idle minutes.",
		Default = false,
		Callback = function(enabled)
			if enabled and not afkConnection then
				afkConnection = LocalPlayer.Idled:Connect(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end)
			elseif not enabled and afkConnection then
				afkConnection:Disconnect()
				afkConnection = nil
			end
		end,
	})

	Session:AddDivider()

	Session:AddButton({
		Text = "Rejoin",
		Func = function()
			if #Players:GetPlayers() <= 1 then
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			else
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end
		end,
	})

	Session:AddButton({
		Text = "Server hop",
		Func = function()
			local ok, result = pcall(function()
				local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(game.PlaceId)
				return HttpService:JSONDecode(game:HttpGet(url))
			end)
			if not ok or type(result) ~= "table" or type(result.data) ~= "table" then
				notify("Couldn't fetch the server list.")
				return
			end

			local candidates = {}
			for _, server in ipairs(result.data) do
				if server.id ~= game.JobId and (server.playing or 0) < (server.maxPlayers or 0) then
					table.insert(candidates, server.id)
				end
			end
			if #candidates == 0 then
				notify("No other open servers found.")
				return
			end

			notify("Hopping servers…")
			TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[math.random(#candidates)], LocalPlayer)
		end,
	})

	Session:AddButton({
		Text = "Copy server ID",
		Func = function()
			if setclipboard then
				setclipboard(game.JobId)
				notify("Server ID copied.")
			else
				notify(game.JobId, 8)
			end
		end,
	})

	--// Settings: menu keybind, accent, UI scale, configs

	Library:BuildSettingsTab(Window)

	Library:OnUnload(function()
		for _, connection in ipairs(Connections) do
			connection:Disconnect()
		end
		if afkConnection then
			afkConnection:Disconnect()
			afkConnection = nil
		end
		setFullbright(false)
		if Workspace.CurrentCamera then
			Workspace.CurrentCamera.FieldOfView = DefaultFov
		end
		if Env.Kompile and Env.Kompile.Library == Library then
			Env.Kompile = nil
		end
	end)

	Library:LoadAutoload()
	notify("Loaded for " .. GameName .. ".")
end
