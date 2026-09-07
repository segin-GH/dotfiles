return {
	"sindrets/diffview.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("diffview").setup({})

		vim.keymap.set("n", "<leader>dd", "<cmd>DiffviewOpen<cr>", { desc = "[D]iff: open diff view" })
		vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "[D]iff: close diff view" })
		vim.keymap.set("n", "<leader>dr", "<cmd>DiffviewRefresh<cr>", { desc = "[D]iff: refresh diff view" })
	end,
}
