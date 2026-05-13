# nvim

Neovim configuration managed with [lazy.nvim](https://github.com/folke/lazy.nvim).

```
init.lua
  ├── lua/vim.lua          Core settings (tabs, search, undo, perf…)
  ├── lua/plugins.lua      Plugin definitions (lazy.nvim)
  └── lua/customization/
        ├── plugins/        Custom mini-plugins (grepapp, reminder, argpoon)
        ├── commands/       Custom commands (obsidian, git, visual-modes…)
        ├── autocmds.lua    Auto commands
        ├── functions/      Helpers (vimscript→lua, selection utils)
        ├── mappings/       Keymaps, one file per feature
        ├── settings/       Plugin-specific configs (lsp, treesitter, ale…)
        └── utils/          Shared utilities (aio, fn, runner, formatters)
```

## Plugins

| Category | Plugins |
|---|---|
| Git | vim-fugitive, vim-rhubarb, gitsigns.nvim |
| LSP & completion | nvim-lspconfig, mason.nvim, nvim-cmp, lazydev.nvim |
| Fuzzy finder | Telescope + FZF-native |
| AI | supermaven, dogmeat |
| Editing | vim-surround, vim-visual-multi, Comment.nvim, UltiSnips |
| Syntax | nvim-treesitter + textobjects |
| UI | solarized.nvim (dark neo), indent-blankline, vim-airline, which-key |
| Debug | nvim-dap (Go) |
| Search | csgithub.nvim, curl.nvim |
| Tooling | vim-sleuth, vim-projectionist |

## Key bindings

- **Leader:** `<Space>`
- `<leader>gp` / `<leader>gn` — Previous / next git hunk
- `<leader>ph` — Preview hunk
- `<leader>ghs` — Search on GitHub (by extension)
- `<leader>rhsf` — Search on GitHub (by filename)
- `<C-l>` — UltiSnips expand / jump forward

Full keymaps in `lua/customization/mappings/`.

## Snippets

Custom UltiSnips snippets live in `mysnippets/`. Mostly geared toward note-taking and daily workflows.

## Settings

- **Indent:** 2 spaces (tabstop/shiftwidth/softtabstop)
- **Line numbers:** relative + absolute on current line
- **Color column:** 80
- **Mouse:** enabled
- **Perf:** `re=0`, `synmaxcol=512`, lazyredraw, no swap/backup files
- **Undo:** persistent (`undofile`), 1000 levels

## Requirements

- Neovim ≥ 0.9
- Git (for lazy.nvim bootstrap)
- Tree-sitter CLI (lazy auto-builds grammars)
- Node / Go runtimes for LSP servers (via mason)
