--[[
	Game module template.
	1. Copy this file to games/<game-name>.lua
	2. Add it to games/registry.lua under the game's universe ID

	ctx fields:
	  Tab      the "Game" tab: ctx.Tab:AddLeftGroupbox(title) / AddRightGroupbox(title)
	  Library  Kompile UI
	  Window   the Kompile window
	  Options  every option by id, e.g. ctx.Options.TemplateToggle.Value
	  Track    ctx.Track(connection): disconnected automatically on unload
	  Notify   ctx.Notify(text, seconds?)

	Groupbox elements:
	  AddToggle(id, { Text, Default, Tooltip, Callback })  -> :AddKeybind(id, { Default, Mode })
	  AddSlider(id, { Text, Min, Max, Default, Rounding, Suffix, Callback })
	  AddDropdown(id, { Text, Values, Default, Searchable, Placeholder, Callback })
	  AddInput(id, { Text, Placeholder, Default, Numeric, Finished, Callback })
	  AddKeybind(id, { Text, Default, Mode = "Toggle" | "Hold" | "Press", Callback })
	  AddButton({ Text, Func, Tooltip })
	  AddLabel(text)  -> :SetText(text)
	  AddDivider()
]]

return function(ctx)
	local Main = ctx.Tab:AddLeftGroupbox("Main")

	Main:AddToggle("TemplateToggle", {
		Text = "Example toggle",
		Default = false,
		Callback = function(enabled)
			ctx.Notify("Example toggle: " .. tostring(enabled))
		end,
	})

	Main:AddSlider("TemplateSlider", {
		Text = "Example slider",
		Min = 0,
		Max = 100,
		Default = 50,
		Suffix = "%",
	})

	Main:AddButton({
		Text = "Example button",
		Func = function()
			ctx.Notify("Hello from the template module.")
		end,
	})
end
