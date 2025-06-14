-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local M = {}

--- Returns the 1-based index of the YAML case ("-") under the cursor, or nil and an error message if not found.
---@return integer|nil case_index The 1-based index of the current case under cursor, or nil if not found.
---@return string|nil errmsg An error message if not found, otherwise nil.
function M.find_case_num()
  local api = vim.api
  local bufnr = api.nvim_get_current_buf()
  local total_lines = api.nvim_buf_line_count(bufnr)
  local cursor = api.nvim_win_get_cursor(0)
  local cur_line = cursor[1] -- 1-based

  -- 1. Find the 'cases:' header line at column 0.
  local cases_line = nil
  for i = 1, total_lines do
    local line = api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    if line:match("^cases:%s*$") then
      cases_line = i
      break
    end
  end
  if not cases_line then
    return nil, "No 'cases:' found in file"
  end

  -- 2. Find the first '-' after 'cases:' to determine indentation.
  local case_dash_indent = nil
  local first_case_line = nil
  for i = cases_line + 1, total_lines do
    local line = api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    local indent = line:match("^(%s*)%-")
    if indent then
      case_dash_indent = #indent
      first_case_line = i
      break
    end
    -- Blank or comment lines are skipped.
  end
  if not case_dash_indent then
    return nil, "No '-' found after 'cases:'"
  end

  -- 3. Gather all lines with '-' at the same indent (top-level cases).
  ---@type integer[]
  local case_starts = {}
  for i = first_case_line, total_lines do
    local line = api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    local indent = line:match("^(%s*)%-")
    if indent and #indent == case_dash_indent then
      table.insert(case_starts, i)
    end
  end
  if #case_starts == 0 then
    return nil, "No cases detected after 'cases:'"
  end

  -- 4. Find the nearest case above or at the cursor line.
  local found = nil
  for idx = #case_starts, 1, -1 do
    if cur_line >= case_starts[idx] then
      found = idx
      break
    end
  end

  if found then
    return found
  else
    return nil, "No matching case for current line"
  end
end

return M
