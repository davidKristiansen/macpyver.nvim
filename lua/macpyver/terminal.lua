-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local terminals = {} -- { [name]: { bufnr = int, winid = int } }

local M = {}

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

---@param name string
---@param split_dir? "top"|"bottom"|"left"|"right"
---@param size? integer
---@param focus? boolean
---@param keymaps? table { close?: string, clear?: string }
---@return integer bufnr, integer winid
function M.open(name, split_dir, size, focus, keymaps)
  -- Reuse existing terminal if valid
  local term = terminals[name]
  if term and vim.api.nvim_buf_is_valid(term.bufnr) and vim.api.nvim_win_is_valid(term.winid) then
    if focus ~= false then
      vim.api.nvim_set_current_win(term.winid)
    end
    return term.bufnr, term.winid
  end

  -- Open the split
  local prev_win = vim.api.nvim_get_current_win()
  open_split(split_dir, size)
  local winid = vim.api.nvim_get_current_win()

  -- Open a "dumb" terminal (no prompt)
  vim.cmd("terminal env PS1= bash --noprofile --norc")
  local bufnr = vim.api.nvim_get_current_buf()

  -- Directly register keymaps (normal mode and terminal mode)
  if keymaps and (keymaps.close or keymaps.clear) then
    if keymaps.close then
      -- Normal mode: close
      vim.api.nvim_buf_set_keymap(bufnr, "n", keymaps.close,
        ("<Cmd>lua require('macpyver.terminal').close('%s')<CR>"):format(name),
        { noremap = true, silent = true })
      -- Terminal mode: close
      vim.api.nvim_buf_set_keymap(bufnr, "t", keymaps.close,
        ([[<C-\><C-n><Cmd>lua require('macpyver.terminal').close('%s')<CR>]]):format(name),
        { noremap = true, silent = true })
    end
    if keymaps.clear then
      -- Normal mode: clear
      vim.api.nvim_buf_set_keymap(bufnr, "n", keymaps.clear,
        ("<Cmd>lua require('macpyver.terminal').clear('%s')<CR>"):format(name),
        { noremap = true, silent = true })
      -- Terminal mode: clear
      vim.api.nvim_buf_set_keymap(bufnr, "t", keymaps.clear,
        ([[<C-\><C-n><Cmd>lua require('macpyver.terminal').clear('%s')<CR>]]):format(name),
        { noremap = true, silent = true })
    end
  end

  terminals[name] = { bufnr = bufnr, winid = winid }

  if focus == false then
    vim.api.nvim_set_current_win(prev_win)
  end

  return bufnr, winid
end

---@param name string
---@param cmd string
function M.send(name, cmd)
  local term = terminals[name]
  if not (term and vim.api.nvim_buf_is_valid(term.bufnr)) then
    error("No terminal named '" .. name .. "'")
  end
  local job_id = M.get_job_id(name)
  if not job_id or type(job_id) ~= "number" then
    vim.notify("[macpyver] No running shell in terminal '" .. name .. "' (cannot send command)", vim.log.levels.WARN)
    return
  end
  local safe_cmd = string.format("reset; %s", cmd)
  vim.api.nvim_chan_send(job_id, safe_cmd .. "\n")
end

---@param name string
function M.clear(name)
  local term = terminals[name]
  if term and vim.api.nvim_buf_is_valid(term.bufnr) then
    vim.api.nvim_buf_set_lines(term.bufnr, 0, -1, false, {})
    -- This doesn't actually clear the terminal screen—just the buffer's scrollback.
    -- To actually clear the visible terminal, send the clear sequence:
    M.send(name, "clear")
  end
end

function M.close(name)
  local term = terminals[name]
  if not term then
    vim.notify(("[macpyver] No terminal named '%s'"):format(name), vim.log.levels.INFO)
    return
  end
  if not vim.api.nvim_win_is_valid(term.winid) then
    vim.notify(("[macpyver] Terminal window for '%s' is not valid (already closed?)"):format(name), vim.log.levels.WARN)
    terminals[name] = nil
    return
  end
  local job_id = M.get_job_id(name)
  if job_id then
    -- Try to exit shell gracefully first
    pcall(vim.api.nvim_chan_send, job_id, "\003")
    pcall(vim.api.nvim_chan_send, job_id, "exit\n")

    -- Optionally, force kill (uncomment if desired)
    vim.fn.jobstop(job_id)
  end
  -- Give shell a moment to clean up, then close window
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(term.winid) then
      vim.api.nvim_win_close(term.winid, true)
    end
    terminals[name] = nil
  end, 80)
end

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

function M.ctrlc(name)
  local job_id = M.get_job_id(name)
  if job_id then
    pcall(vim.api.nvim_chan_send, job_id, "\003")
  end
end

return M
