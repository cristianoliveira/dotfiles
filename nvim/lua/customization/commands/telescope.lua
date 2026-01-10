--- Custom Telescope commands

local telescope_builtin = require("telescope.builtin")

--- Telescope Git Diff <commit1> <commit2>
--- Select 2 commits to diff the files between
vim.api.nvim_create_user_command("TeGitDiff", function(opts)
  if #opts.args < 2 then
    telescope_builtin.git_files {
      git_command = { 'git', 'diff', '--name-only' },
    }
    return
  end

  local commit1 = opts.fargs[1]
  local commit2 = opts.fargs[2]

  telescope_builtin.git_files {
    git_command = { 'git', 'diff', '--name-only', commit1, commit2 },
  }

end, { nargs = "*", desc = "Telescope Git Diff <commit1> <commit2>" })
