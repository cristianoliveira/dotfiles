return {
  "zbirenbaum/copilot.lua",

  cmd = "Copilot",
  event = "InsertEnter",

  config = function()
    require("copilot").setup({
      filetypes = {
        markdown = true,
        yaml = true,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<Tab>",
          next = "<C-h>",
        },
      },
    })
  end,
}
