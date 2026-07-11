vim.cmd([[let &rtp .= ',' .. getcwd()]])
vim.cmd("set rtp+=" .. vim.env.NVIM_TEST_MINI_PATH)

require("mini.test").setup()
require("customization.commands.wrap")
