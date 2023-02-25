vim.o.ttyfast = true
vim.o.lazyredraw = true

-- Performance fix for Typescript
-- https://jameschambers.co.uk/vim-typescript-slow
-- Avoid using old regex implementation for code highlight which is slooow
vim.o.re = 0
