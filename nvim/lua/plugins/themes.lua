-- Blend a colour toward its own luminance: takes the vividness down without
-- dimming the palette (used to "wash" the Tokyo Night accents).
local function wash(hex, amount)
	local r = tonumber(hex:sub(2, 3), 16)
	local g = tonumber(hex:sub(4, 5), 16)
	local b = tonumber(hex:sub(6, 7), 16)
	local gray = 0.2126 * r + 0.7152 * g + 0.0722 * b
	local function mix(c)
		return math.floor(c + (gray - c) * amount + 0.5)
	end
	return string.format("#%02x%02x%02x", mix(r), mix(g), mix(b))
end

return {
	"folke/tokyonight.nvim",
	priority = 1000, -- load before the other start plugins
	lazy = false,
	opts = {
		style = "night",
		-- Let kitty's background_opacity show the wallpaper through nvim too.
		transparent = true,
		styles = {
			comments = { italic = true },
			keywords = { italic = false },
		},
		-- Softer default text than Tokyo Night's #c0caf5, then wash every
		-- palette entry by 22% so the colours match the kitty theme.
		on_colors = function(colors)
			colors.fg = "#a9b1d6"
			for key, value in pairs(colors) do
				if type(value) == "string" and value:match("^#%x%x%x%x%x%x$") then
					colors[key] = wash(value, 0.22)
				end
			end
		end,
	},
	config = function(_, opts)
		require("tokyonight").setup(opts)
		vim.cmd.colorscheme("tokyonight-night")
	end,
}
