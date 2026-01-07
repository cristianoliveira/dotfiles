return {
  "supermaven-inc/supermaven-nvim",
  -- See mappings/supermaven.lua
  config = function()
    require("supermaven-nvim").setup({
      disable_keymaps = true,
    })
  end
}
