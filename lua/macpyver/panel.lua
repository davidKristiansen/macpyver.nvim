-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

-- Panel manager: handles named scratch buffers + split/window management.

local panels = {} ---@type table<string, { bufnr: integer, winid?: integer }>
local M = {}

---@class MacpyverPanelKeymaps
---@field clear? string   -- Key to clear panel output
---@field close? string   -- Key to close the panel window

---@class MacpyverPanelOpts
---@field split_dir? "top"|"bottom"|"left"|"right"
---@field size? integer
---@field autoscroll? boolean
---@field focus? boolean
---@field keymaps? MacpyverPanelKeymaps

---Set up buffer-local keymaps for panel actions.
---@param bufnr integer
---@param name string
---@param keymaps? MacpyverPanelKeymaps
local function setup_panel_keymaps(bufnr, name, keymaps)
  keymaps = keymaps or {}
  if keymaps.clear then
    vim.api.nvim_buf_set_keymap(bufnr, "n", keymaps.clear,
      ("<Cmd>lua require('macpyver.panel').clear('%s')<CR>"):format(name),
      { noremap = true, silent = true }
    )
  end
  if keymaps.close then
    vim.api.nvim_buf_set_keymap(bufnr, "n", keymaps.close,
      ("<Cmd>lua require('macpyver.panel').close('%s')<CR>"):format(name),
      { noremap = true, silent = true }
    )
  end
end

---Open a split in the requested direction and size.
---@param split_dir? "top"|"bottom"|"left"|"right"
---@param size? integer
local function open_split(split_dir, size)
  split_dir = split_dir or "bottom"
  if split_dir == "top" then
    vim.cmd("topleft split")
    if size then vim.cmd("resize " .. tostring(size)) end
  elseif split_dir == "bottom" then
    vim.cmd("botright split")
    if size then vim.cmd("resize " .. tostring(size)) end
  elseif split_dir == "left" then
    vim.cmd("topleft vsplit")
    if size then vim.cmd("vertical resize " .. tostring(size)) end
  elseif split_dir == "right" then
    vim.cmd("botright vsplit")
    if size then vim.cmd("vertical resize " .. tostring(size)) end
  else
    vim.cmd("botright split")
    if size then vim.cmd("resize " .. tostring(size)) end
  end
end

---Create a named panel (scratch buffer), optionally with keymaps.
---@param name string
---@param opts? MacpyverPanelOpts
---@return integer bufnr
function M.create(name, opts)
  opts = opts or {}
  if panels[name] and vim.api.nvim_buf_is_valid(panels[name].bufnr) then
    return panels[name].bufnr
  end
  local bufnr = vim.api.nvim_create_buf(false, true)
  setup_panel_keymaps(bufnr, name, opts.keymaps)
  vim.api.nvim_buf_set_option(bufnr, "buflisted", false)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "macpyverlog")
  panels[name] = { bufnr = bufnr }
  return bufnr
end

---Show a panel in a split, creating a window if needed. Honors opts.focus.
---@param name string
---@param opts? MacpyverPanelOpts
---@return integer|nil winid
function M.show(name, opts)
  opts = opts or {}
  local panel = panels[name]
  if not (panel and vim.api.nvim_buf_is_valid(panel.bufnr)) then
    vim.notify("[macpyver] No panel named '" .. name .. "'", vim.log.levels.WARN)
    return nil
  end
  if panel.winid and vim.api.nvim_win_is_valid(panel.winid) then
    if opts.focus ~= false then
      vim.api.nvim_set_current_win(panel.winid)
    end
    return panel.winid
  end
  local prev_win = vim.api.nvim_get_current_win()
  open_split(opts.split_dir, opts.size)
  local winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winid, panel.bufnr)
  vim.wo[winid].number = false
  vim.wo[winid].relativenumber = false
  panel.winid = winid
  if opts.focus == false then
    vim.api.nvim_set_current_win(prev_win)
  end
  if opts.autoscroll then
    vim.cmd("normal! G")
  end
  return winid
end

---Clear all lines in the named panel buffer.
---@param name string
function M.clear(name)
  local panel = panels[name]
  if panel and vim.api.nvim_buf_is_valid(panel.bufnr) then
    vim.api.nvim_buf_set_lines(panel.bufnr, 0, -1, false, {})
  end
end

---Close the panel's window, but keep buffer.
---@param name string
function M.close(name)
  local panel = panels[name]
  if panel and panel.winid and vim.api.nvim_win_is_valid(panel.winid) then
    vim.api.nvim_win_close(panel.winid, true)
    panel.winid = nil
  end
end

---Get the buffer number for a panel.
---@param name string
---@return integer|nil
function M.bufnr(name)
  return panels[name] and panels[name].bufnr or nil
end

---Get the window id for a panel.
---@param name string
---@return integer|nil
function M.winid(name)
  return panels[name] and panels[name].winid or nil
end

return M
