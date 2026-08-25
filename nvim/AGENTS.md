# nvim

Neovim config source.
Start: `init.lua` → `lua/plugins.lua` → `lua/customization/`.

## Tests

mini.test suite in `tests/`:
`NVIM_TEST_MINI_PATH=~/other/mini.nvim nvim --headless -u tests/minimal_init.lua -c 'lua MiniTest.run()' -c 'qa!'`
(mini.nvim checkout lives at `~/other/mini.nvim`)

## Code review session

`lua/customization/commands/review.lua` — `:ReviewComment` (range-aware),
`:ReviewList` (quickfix, jumps), `:ReviewReport` (markdown + clipboard),
`:ReviewClear`; maps `<leader>rc/rd/rl`. In-memory per session, extmark-anchored.
