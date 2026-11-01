local opts = {
	"michaelrommel/nvim-silicon",
	lazy = true,
	cmd = "Silicon",
	init = function ()
		local wk = require("which-key")
		wk.add({
			{ "<leader>ss", ":Silicon<CR>", desc = "Snapshot Code" },
		})
	end,
	config = function ()
	 require("silicon").setup({
	    font = "JetBrainsMono Nerd Font=34;Noto Color Emoji=34"
	  })
	end
}
return opts
