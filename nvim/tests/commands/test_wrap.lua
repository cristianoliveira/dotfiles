local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local T = new_set()

local function with_buffer(lines, callback)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buffer)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  callback(buffer)
  vim.api.nvim_buf_delete(buffer, { force = true })
end

T["CWrap"] = new_set()

T["CWrap"]["wraps current paragraph at supplied width without splitting words"] = function()
  with_buffer({
    "Keep whole words together while wrapping this commit-message paragraph.",
  }, function(buffer)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("CWrap 30")

    eq(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), {
      "Keep whole words together",
      "while wrapping this",
      "commit-message paragraph.",
    })
  end)
end

T["CWrap"]["rejects a non-positive width"] = function()
  local wrap = require("customization.commands.wrap")

  with_buffer({ "unchanged" }, function(buffer)
    local ok, message = pcall(wrap.current_paragraph, 0)

    eq(ok, false)
    assert(message:match("positive integer"))
    eq(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), { "unchanged" })
  end)
end

return T
