-- GitHub-like code review comments, in-memory per nvim session.
--
--   :ReviewComment (or '<,'>ReviewComment for a visual range)
--     open a floating input, write the comment, <CR> (normal mode) saves
--   :ReviewList     quickfix of every comment, <CR> jumps to the line
--   :ReviewReport   markdown report in a split, also yanked to the clipboard
--   :ReviewClear    drop the whole session
--
-- Mappings: <leader>rc (comment), <leader>rd (delete under cursor), <leader>rl (list)
--
-- Positions move with the code: each comment anchors to an extmark, so edits
-- above it shift the comment. The stored position is only the fallback once
-- the buffer is gone.
local M = {}

local comments = {}
local namespace = vim.api.nvim_create_namespace("customization.code-review")

local PREVIEW_MAX = 60

local function validate(path, start_line, end_line, text)
  if type(path) ~= "string" or path == "" then
    error("Comment needs a file path")
  end
  if type(start_line) ~= "number" or type(end_line) ~= "number" or start_line < 1 or end_line < start_line then
    error("Invalid line range")
  end
  if type(text) ~= "string" or text:match("^%s*$") then
    error("Comment text must not be empty")
  end
end

local function preview_line(text)
  local first = text:match("([^\n]+)") or text
  first = first:gsub("^%s+", "")
  if #first > PREVIEW_MAX then
    first = first:sub(1, PREVIEW_MAX) .. "…"
  end
  return "  ● " .. first
end

function M.namespace()
  return namespace
end

function M.reset()
  comments = {}
end

function M.all()
  return comments
end

function M.add(path, start_line, end_line, text, opts)
  opts = opts or {}
  validate(path, start_line, end_line, text)

  local bufnr = opts.bufnr
  local extmark_id = nil
  if bufnr ~= false then
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    extmark_id = vim.api.nvim_buf_set_extmark(bufnr, namespace, start_line - 1, 0, {
      virt_text = { { preview_line(text), "Comment" } },
      virt_text_pos = "eol",
      hl_mode = "combine",
    })
  end

  local comment = {
    path = path,
    start_line = start_line,
    end_line = end_line,
    text = text,
    bufnr = bufnr,
    extmark_id = extmark_id,
  }
  table.insert(comments, comment)
  return comment
end

function M.remove(index)
  local comment = comments[index]
  if not comment then
    error("No comment at index " .. index)
  end

  if comment.bufnr and vim.api.nvim_buf_is_valid(comment.bufnr) then
    vim.api.nvim_buf_del_extmark(comment.bufnr, namespace, comment.extmark_id)
  end
  table.remove(comments, index)
  return comment
end

-- Current position of a comment: the extmark when its buffer is still alive,
-- the stored position otherwise.
function M.resolved(comment)
  if comment.bufnr and vim.api.nvim_buf_is_valid(comment.bufnr) then
    local mark = vim.api.nvim_buf_get_extmark_by_id(comment.bufnr, namespace, comment.extmark_id, {})
    if mark[1] ~= nil then
      return { start_line = mark[1] + 1, end_line = mark[1] + 1 + (comment.end_line - comment.start_line) }
    end
  end
  return { start_line = comment.start_line, end_line = comment.end_line }
end

function M.find_under(path, line)
  for index = #comments, 1, -1 do
    local comment = comments[index]
    local position = M.resolved(comment)
    if comment.path == path and line >= position.start_line and line <= position.end_line then
      return index
    end
  end
  return nil
end

local function fetch_lines(path, start_line, end_line)
  local bufnr = vim.fn.bufnr("^" .. vim.pesc(path) .. "$")
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    return vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or #lines == 0 then
    return nil
  end
  local slice = {}
  for i = start_line, math.min(end_line, #lines) do
    table.insert(slice, lines[i])
  end
  return slice
end

local function label(start_line, end_line)
  if start_line == end_line then
    return "**L" .. start_line .. "**"
  end
  return "**L" .. start_line .. "-" .. end_line .. "**"
end

function M.render_markdown(list, opts)
  opts = opts or {}
  local title = opts.title or ("Code review — " .. os.date("%Y-%m-%d"))
  local fetch = opts.fetch_lines or fetch_lines

  local sorted = {}
  for _, comment in ipairs(list) do
    table.insert(sorted, { comment = comment, position = M.resolved(comment) })
  end
  table.sort(sorted, function(a, b)
    if a.comment.path ~= b.comment.path then
      return a.comment.path < b.comment.path
    end
    return a.position.start_line < b.position.start_line
  end)

  local output = { "# " .. title, "" }
  local current_path = nil
  for _, entry in ipairs(sorted) do
    local comment, position = entry.comment, entry.position
    if comment.path ~= current_path then
      current_path = comment.path
      table.insert(output, "## " .. comment.path)
      table.insert(output, "")
    end

    local body_lines = vim.split(comment.text, "\n", { plain = true })
    table.insert(output, label(position.start_line, position.end_line) .. " " .. body_lines[1])
    for i = 2, #body_lines do
      table.insert(output, "> " .. body_lines[i])
    end

    local snippet = fetch(comment.path, position.start_line, position.end_line)
    if snippet then
      table.insert(output, "")
      for _, line in ipairs(snippet) do
        table.insert(output, line == "" and "" or "    " .. line)
      end
    end
    table.insert(output, "")
  end

  return table.concat(output, "\n")
end

function M.to_qf_items(list)
  local items = {}
  for _, comment in ipairs(list) do
    local position = M.resolved(comment)
    table.insert(items, {
      filename = comment.path,
      lnum = position.start_line,
      text = comment.text:match("([^\n]+)"),
    })
  end
  return items
end

------------------------------------------------------------------------------
-- UI

local function close_float(win)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

function M._should_discard(text, confirm)
  if text:match("^%s*$") then
    return true
  end

  confirm = confirm or vim.fn.confirm
  return confirm("Discard this review comment?", "&Discard\n&Keep editing", 2) == 1
end

local function discard_input(buf, win)
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  if M._should_discard(text) then
    close_float(win)
  end
end

-- Reads the comment text from the input buffer and anchors it on the target
-- buffer (never on the input float, which is usually 1-2 lines).
function M._save_input(input_buf, path, target_buf, start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  local ok, err = pcall(M.add, path, start_line, end_line, text, { bufnr = target_buf })
  if not ok then
    vim.notify(err, vim.log.levels.WARN)
    return false
  end
  return true
end

local function open_comment_input(path, start_line, end_line)
  local target_buf = vim.api.nvim_get_current_buf()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "acwrite" -- makes :w and :x work via BufWriteCmd
  vim.bo[buf].ft = "markdown"
  vim.api.nvim_buf_set_name(buf, "review-comment://" .. vim.fn.fnamemodify(path, ":t") .. ":L" .. start_line)

  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.25)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = "rounded",
    title = " " .. vim.fn.fnamemodify(path, ":t") .. " L" .. start_line .. " — :w save, q discard ",
    title_pos = "center",
  })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      if M._save_input(buf, path, target_buf, start_line, end_line) then
        vim.bo[buf].modified = false
      end
    end,
  })

  local function save_and_close()
    if M._save_input(buf, path, target_buf, start_line, end_line) then
      close_float(win)
    end
  end

  vim.keymap.set("n", "q", function() discard_input(buf, win) end, { buffer = buf })
  vim.keymap.set("n", "<Esc>", function() discard_input(buf, win) end, { buffer = buf })
  vim.keymap.set("n", "<CR>", save_and_close, { buffer = buf })
  vim.cmd("startinsert")
end

function M.comment_range(line1, line2)
  open_comment_input(vim.api.nvim_buf_get_name(0), line1, line2)
end

function M.remove_under_cursor()
  local index = M.find_under(vim.api.nvim_buf_get_name(0), vim.fn.line("."))
  if not index then
    vim.notify("No review comment under the cursor")
    return
  end
  M.remove(index)
end

function M.open_list()
  if #comments == 0 then
    vim.notify("No review comments yet")
    return
  end
  vim.fn.setqflist({}, " ", { title = "Review comments", items = M.to_qf_items(comments) })
  vim.cmd("botright copen")
end

function M.open_report()
  if #comments == 0 then
    vim.notify("No review comments yet")
    return
  end

  local markdown = M.render_markdown(comments, {})
  vim.fn.setreg("+", markdown)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(markdown, "\n", { plain = true }))
  vim.bo[buf].ft = "markdown"
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_set_name(buf, "review-report.md")
  vim.cmd("botright split")
  vim.api.nvim_set_current_buf(buf)
  vim.notify(#comments .. " comments — report yanked to the clipboard")
end

function M.clear()
  for index = #comments, 1, -1 do
    M.remove(index)
  end
  vim.notify("Review session cleared")
end

------------------------------------------------------------------------------
-- Commands and mappings

vim.api.nvim_create_user_command("ReviewComment", function(opts)
  M.comment_range(opts.line1, opts.line2)
end, { range = true, desc = "Add a review comment to the current line or range" })

vim.api.nvim_create_user_command("ReviewList", M.open_list, { desc = "List review comments in the quickfix" })
vim.api.nvim_create_user_command("ReviewReport", M.open_report, { desc = "Generate the markdown review report" })
vim.api.nvim_create_user_command("ReviewClear", M.clear, { desc = "Clear the review session" })

vim.keymap.set("n", "<leader>rc", "<cmd>ReviewComment<cr>", { desc = "[R]eview [C]omment line" })
vim.keymap.set("v", "<leader>rc", ":ReviewComment<cr>", { desc = "[R]eview [C]omment range" })
vim.keymap.set("n", "<leader>rd", M.remove_under_cursor, { desc = "[R]eview [D]elete comment" })
vim.keymap.set("n", "<leader>rl", M.open_list, { desc = "[R]eview [L]ist comments" })

return M
