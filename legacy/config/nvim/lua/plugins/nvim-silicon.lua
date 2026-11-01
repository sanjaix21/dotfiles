local opts = {
	"michaelrommel/nvim-silicon",
	lazy = true,
	cmd = "Silicon",
	init = function ()
		local wk = require("which-key")
		wk.register({
			["<leader>ss"] = {":Silicon<CR>", "Snapshot Code"}
		})
	end,
	config = function ()
	 require("silicon").setup({
	    font = "JetBrainsMono Nerd Font=34;Noto Color Emoji=34"
	  })
	end
}
return opts
