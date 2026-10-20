return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		-- main branch does not auto-install parsers; declare them here.
		-- asm covers *.s / *.S (GAS), see :h nvim-treesitter-commands
		require("nvim-treesitter").install({ "asm" })
	end,
}
