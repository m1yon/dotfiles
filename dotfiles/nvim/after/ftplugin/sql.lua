vim.keymap.set("n", "<leader>ls", "<cmd>DbtGotoDef<cr>", { buffer = true, desc = "DBT go to definition" })

vim.b.miniclue_config = {
	clues = {
		{ mode = "n", keys = "<Leader>d", desc = "+DBT" },
	},
}
