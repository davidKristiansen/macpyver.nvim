-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local terminals = {} ---@type table<string, { bufnr: integer, winid: integer }>

local M = {}

---Open a split window in the requested direction and set size.
---@param split_dir? "top"|"bottom"|"left"|"right"
---@param size? integer
local function open_split(split_dir, size)
  split_dir = split_dir or "bottom"
  if split_dir == "top" then
    vim.cmd("topleft split")
    if size then vim.cmd("resize " .. size) end
  elseif split_dir == "bottom" then
    vim.cmd("botright split")
    if size then vim.cmd("resize " .. size) end
  elseif split_dir == "left" then
    vim.cmd("topleft vsplit")
    if size then vim.cmd("vertical resize " .. size) end
  elseif split_dir == "right" then
    vim.cmd("botright vsplit")
    if size then vim.cmd("vertical resize " .. size) end
  else
    vim.cmd("botright split")
    if size then vim.cmd("resize " .. size) end
  end
end

---Open (or reuse) a named terminal in a split window.
---@param name string
---@param split_dir? "top"|"bottom"|"left"|"right"
---@param size? integer
---@param focus? boolean
---@param keymaps? table { close?: string, clear?: string }
---@param autoscroll? boolean
---@return integer bufnr, integer winid
function M.open(name, split_dir, size, focus, keymaps, autoscroll)
  -- If the terminal is already open, reuse it.
  local term = terminals[name]
  if term and vim.api.nvim_buf_is_valid(term.bufnr) and vim.api.nvim_win_is_valid(term.winid) then
    if focus ~= false then
      vim.api.nvim_set_current_win(term.winid)
    end
    return term.bufnr, term.winid
  end

  -- Open the split in the requested direction.
  local prev_win = vim.api.nvim_get_current_win()
  open_split(split_dir, size)
  local winid = vim.api.nvim_get_current_win()

  -- Start a "dumb" bash terminal (no prompt, minimal environment).
  vim.cmd("terminal env PS1= bash --noprofile --norc")
  local bufnr = vim.api.nvim_get_current_buf()


  -- Disable shell echo to avoid duplicated commands.
  vim.api.nvim_chan_send(vim.b.terminal_job_id, "stty -echo\n")

  -- Buffer-local keymaps for closing/clearing the terminal (both normal and terminal modes).
  if keymaps and (keymaps.close or keymaps.clear) then
    if keymaps.close then
      vim.api.nvim_buf_set_keymap(bufnr, "n", keymaps.close,
        ("<Cmd>lua require('macpyver.terminal').close('%s')<CR>"):format(name),
        { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(bufnr, "t", keymaps.close,
        ([[<C-\><C-n><Cmd>lua require('macpyver.terminal').close('%s')<CR>]]):format(name),
        { noremap = true, silent = true })
    end
    if keymaps.clear then
      vim.api.nvim_buf_set_keymap(bufnr, "n", keymaps.clear,
        ("<Cmd>lua require('macpyver.terminal').clear('%s')<CR>"):format(name),
        { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(bufnr, "t", keymaps.clear,
        ([[<C-\><C-n><Cmd>lua require('macpyver.terminal').clear('%s')<CR>]]):format(name),
        { noremap = true, silent = true })
    end
  end

  -- Optional: auto-scroll terminal to bottom when output changes.
  if autoscroll then
    vim.api.nvim_create_autocmd({ "TermEnter", "TermClose", "TextChanged", "BufWinEnter" }, {
      buffer = bufnr,
      callback = function()
        if vim.api.nvim_win_is_valid(winid) then
          vim.api.nvim_win_set_cursor(winid, { vim.api.nvim_buf_line_count(bufnr), 0 })
        end
      end,
      desc = "[macpyver] Autoscroll on output",
    })
  end

  terminals[name] = { bufnr = bufnr, winid = winid }

  -- Restore previous window if focus is false.
  if focus == false then
    vim.api.nvim_set_current_win(prev_win)
  end

  return bufnr, winid
end

local function quote_all_args(cmd)
  local args = {}
  for word in vim.gsplit(cmd, "%s+") do
    table.insert(args, string.format("%q", word))
  end
  return table.concat(args, " ")
end

---Send a command to the named terminal.
---@param name string
---@param cmd string
function M.send(name, cmd)
  local term = terminals[name]
  if not (term and vim.api.nvim_buf_is_valid(term.bufnr)) then
    error("No terminal named '" .. name .. "'")
  end
  local job_id = M.get_job_id(name)
  if not job_id or type(job_id) ~= "number" then
    vim.notify("[macpyver] No running shell in terminal '" .. name .. "'", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_chan_send(job_id, " clear\n")
  vim.defer_fn(function()
    local safe_cmd = quote_all_args(cmd)
    vim.api.nvim_chan_send(job_id, safe_cmd .. "\n")
  end, 300)
end

---Clear a terminal's scrollback and screen.
---@param name string
function M.clear(name)
  local term = terminals[name]
  if term and vim.api.nvim_buf_is_valid(term.bufnr) then
    vim.api.nvim_buf_set_lines(term.bufnr, 0, -1, false, {})
    -- Actually clear the visible terminal.
    M.send(name, "clear")
  end
end

---Close the terminal window, quitting Neovim if it's the last window.
---@param name string
function M.close(name)
  local term = terminals[name]
  if not term then
    vim.notify(("[macpyver] No terminal named '%s'"):format(name), vim.log.levels.INFO)
    return
  end

  -- Leave terminal mode before closing.
  if vim.api.nvim_get_mode().mode == "t" then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
      "n",
      false
    )
    vim.schedule(function()
      M.close(name)
    end)
    return
  end

  if not vim.api.nvim_win_is_valid(term.winid) then
    vim.notify(("[macpyver] Terminal window for '%s' is not valid (already closed?)"):format(name), vim.log.levels.WARN)
    terminals[name] = nil
    return
  end

  -- Attempt graceful job termination (Ctrl-C, exit, jobstop)
  local job_id = M.get_job_id(name)
  if job_id then
    pcall(vim.api.nvim_chan_send, job_id, "\003")
    pcall(vim.api.nvim_chan_send, job_id, "exit\n")
    pcall(vim.fn.jobstop, job_id)
  end

  -- If this is the last window, quit Neovim. Otherwise, just close the split.
  if vim.api.nvim_win_is_valid(term.winid) then
    if #vim.api.nvim_list_wins() == 1 then
      pcall(vim.cmd, "qa!")
    else
      pcall(vim.api.nvim_win_close, term.winid, true)
    end
  end
  terminals[name] = nil
end

---Get the terminal job id for a given name.
---@param name string
---@return integer|nil
function M.get_job_id(name)
  local term = terminals[name]
  if not term or not vim.api.nvim_buf_is_valid(term.bufnr) then
    return nil
  end
  local job_id = vim.b[term.bufnr].terminal_job_id
  if job_id and type(job_id) == "number" then
    return job_id
  end
  return nil
end

---Send Ctrl-C to the terminal job.
---@param name string
function M.ctrlc(name)
  local job_id = M.get_job_id(name)
  if job_id then
    pcall(vim.api.nvim_chan_send, job_id, "\003")
  end
end

return M
