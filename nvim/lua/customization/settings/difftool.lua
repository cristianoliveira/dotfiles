-- To understand the options
-- :help diffopt
vim.opt.diffopt = {
  "internal", -- diff algorithm
  "filler", -- fill empty lines
  "closeoff", -- close off common lines
  "iwhite", -- ignore white space
  "vertical", -- side by side
  "algorithm:histogram", -- better algorithm faster than internal
}
