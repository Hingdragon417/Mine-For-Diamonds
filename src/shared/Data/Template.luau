local HotbarConfig = require(script.Parent.Parent.Modules.HotbarConfig)

local function createEmptyHotbar()
	local hotbar = {}
	for i = 1, HotbarConfig.MAX_SLOTS do
		hotbar[i] = ""
	end
	return hotbar
end

return {
	hotbar = createEmptyHotbar(),
}  