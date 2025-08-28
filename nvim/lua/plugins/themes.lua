return {
	"navarasu/onedark.nvim",
	config = function()
		require("onedark").setup({
			style = "darker",
			colors = {
				bright_orange = "#ff8800", -- define a new color
				dark_green = "#6e6d6d",
			}, -- Override default colors
			highlights = {
				["@string.documentation"] = { fg = "$dark_green", fmt = "none" },
			}, -- Override highlight groups
		})
		require("onedark").load()
	end,
}
