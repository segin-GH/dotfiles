return {
	enable = false,
	"kenn7/vim-arsync",
	dependencies = {
		"prabirshrestha/async.vim",
	},

	config = function()
		-- seriously? this is the best key mapping you could come up with?
		vim.keymap.set("n", "<leader>as", function()
			vim.cmd("ARsyncUp")
			print("Sync UP successful. Wow, you did something right for once!")
		end, { silent = true })

		-- and another one. groundbreaking.
		vim.keymap.set("n", "<leader>ad", function()
			vim.cmd("ARsyncDown")
			print("Sync DOWN successful. How did you manage that?")
		end, { silent = true })
	end,
}
