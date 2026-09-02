local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local review = require("customization.commands.review")

local T = new_set()

T["review"] = new_set()

local function with_buffer(lines, callback)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  callback(buffer)
  vim.api.nvim_buf_delete(buffer, { force = true })
end

T["review"]["add validates the comment"] = function()
  review.reset()

  local ok, message = pcall(review.add, "/p/a.lua", 0, 2, "text")
  eq(ok, false)
  assert(message:match("Invalid line range"))

  ok, message = pcall(review.add, "/p/a.lua", 2, 1, "text")
  eq(ok, false)
  assert(message:match("Invalid line range"))

  ok, message = pcall(review.add, "/p/a.lua", 1, 1, "  ")
  eq(ok, false)
  assert(message:match("must not be empty"))
end

T["review"]["add stores the comment and shows a preview extmark"] = function()
  review.reset()

  with_buffer({ "one", "two", "three" }, function(buffer)
    review.add("/p/a.lua", 2, 3, "watch out\nsecond line", { bufnr = buffer })

    eq(#review.all(), 1)
    local stored = review.all()[1]
    eq(stored.path, "/p/a.lua")
    eq(stored.start_line, 2)
    eq(stored.end_line, 3)
    eq(stored.text, "watch out\nsecond line")

    local marks = vim.api.nvim_buf_get_extmarks(buffer, review.namespace(), 0, -1, { details = true })
    eq(#marks, 1)
    eq(marks[1][2], 1) -- placed on start line, 0-based
    local virt_text = marks[1][4].virt_text[1]
    eq(virt_text[1], "  ● watch out")
  end)
end

T["review"]["remove deletes the comment and its extmark"] = function()
  review.reset()

  with_buffer({ "one", "two" }, function(buffer)
    review.add("/p/a.lua", 1, 1, "note", { bufnr = buffer })
    review.remove(1)

    eq(#review.all(), 0)
    eq(#vim.api.nvim_buf_get_extmarks(buffer, review.namespace(), 0, -1, {}), 0)
  end)
end

T["review"]["resolved follows the extmark when lines shift, falls back when buffer dies"] = function()
  review.reset()

  with_buffer({ "one", "two", "three" }, function(buffer)
    local comment = review.add("/p/a.lua", 2, 2, "note", { bufnr = buffer })

    vim.api.nvim_buf_set_lines(buffer, 0, 0, false, { "inserted" })
    local resolved = review.resolved(comment)
    eq(resolved.start_line, 3)
    eq(resolved.end_line, 3)

    eq(comment.start_line, 2) -- stored position untouched
  end)

  -- buffer deleted: extmark gone, falls back to stored position
  local comment = review.all()[1]
  local resolved = review.resolved(comment)
  eq(resolved.start_line, 2)
end

T["review"]["_save_input anchors the comment on the target buffer, not the input float"] = function()
  review.reset()

  local target = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(target, 0, -1, false, { "a", "b", "c", "d", "e" })

  local input = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(input, 0, -1, false, { "watch line 42" })

  local ok = review._save_input(input, "/p/a.lua", target, 4, 5)
  eq(ok, true)

  eq(#review.all(), 1)
  eq(review.all()[1].text, "watch line 42")
  -- extmark must live on the target buffer at the commented range
  local marks = vim.api.nvim_buf_get_extmarks(target, review.namespace(), 0, -1, {})
  eq(#marks, 1)
  eq(marks[1][2], 3) -- 0-based line 4
  -- and nothing leaked onto the input buffer
  eq(#vim.api.nvim_buf_get_extmarks(input, review.namespace(), 0, -1, {}), 0)

  vim.api.nvim_buf_delete(target, { force = true })
  vim.api.nvim_buf_delete(input, { force = true })
end

T["review"]["discarding empty input does not need confirmation"] = function()
  eq(review._should_discard("  \n", function()
    error("confirmation should not be requested")
  end), true)
end

T["review"]["discarding non-empty input requires confirmation"] = function()
  local keep_editing = review._should_discard("written comment", function(message, choices, default)
    eq(message, "Discard this review comment?")
    eq(choices, "&Discard\n&Keep editing")
    eq(default, 2)
    return 2
  end)
  eq(keep_editing, false)

  eq(review._should_discard("written comment", function()
    return 1
  end), true)
end

T["review"]["_save_input rejects empty input and reports failure"] = function()
  review.reset()

  local target = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(target, 0, -1, false, { "a" })
  local input = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(input, 0, -1, false, { "   " })

  eq(review._save_input(input, "/p/a.lua", target, 1, 1), false)
  eq(#review.all(), 0)

  vim.api.nvim_buf_delete(target, { force = true })
  vim.api.nvim_buf_delete(input, { force = true })
end

T["review"]["find_under locates the comment covering a line in the right file"] = function()
  review.reset()
  review.add("/p/a.lua", 5, 8, "range note", { bufnr = false })
  review.add("/p/b.lua", 5, 5, "other file", { bufnr = false })

  eq(review.find_under("/p/a.lua", 6), 1)
  eq(review.find_under("/p/a.lua", 9), nil)
  eq(review.find_under("/p/b.lua", 5), 2)
end

T["review"]["render_markdown groups by file, sorts by line, labels ranges"] = function()
  review.reset()
  review.add("/p/b.lua", 10, 10, "single line note", { bufnr = false })
  review.add("/p/a.lua", 42, 48, "first note\nfollow up thought", { bufnr = false })
  review.add("/p/a.lua", 7, 8, "earlier note", { bufnr = false })

  local markdown = review.render_markdown(review.all(), {
    title = "Code review — 2026-04-13",
    fetch_lines = function(path, start_line, end_line)
      if path == "/p/a.lua" and start_line == 42 then
        return { "if token.expired then", "  refresh(token)", "end" }
      end
      return nil
    end,
  })

  eq(markdown, table.concat({
    "# Code review — 2026-04-13",
    "",
    "## /p/a.lua",
    "",
    "**L7-8** earlier note",
    "",
    "**L42-48** first note",
    "> follow up thought",
    "",
    "    if token.expired then",
    "      refresh(token)",
    "    end",
    "",
    "## /p/b.lua",
    "",
    "**L10** single line note",
    "",
  }, "\n"))
end

T["review"]["to_qf_items maps comments to quickfix entries"] = function()
  review.reset()
  review.add("/p/a.lua", 42, 48, "first note\nsecond", { bufnr = false })
  review.add("/p/b.lua", 10, 10, "other", { bufnr = false })

  eq(review.to_qf_items(review.all()), {
    { filename = "/p/a.lua", lnum = 42, text = "first note" },
    { filename = "/p/b.lua", lnum = 10, text = "other" },
  })
end

return T
