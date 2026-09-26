--[[
	Kompile loader
	loadstring(game:HttpGet("https://raw.githubusercontent.com/snapsnarvmorvid/Kompile/main/loader.lua"))()
]]

local Repo = "https://raw.githubusercontent.com/snapsnarvmorvid/Kompile/main/"

local ok, err = pcall(function()
	if Repo:find("YOUR_GITHUB_USERNAME", 1, true) then
		error("set your GitHub username in loader.lua first.", 0)
	end
	local main = loadstring(game:HttpGet(Repo .. "src/main.lua"), "=src/main")
	if not main then
		error("couldn't download src/main.lua. Check that the repo is public and the files are uploaded.", 0)
	end
	main()({ Repo = Repo })
end)

if not ok then
	warn("[Kompile] Failed to start: " .. tostring(err))
end
