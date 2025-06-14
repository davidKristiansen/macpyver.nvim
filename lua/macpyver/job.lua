-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local terminal = require("macpyver.terminal")

local M = {}

---Send Ctrl-C to the named terminal (kills current job if running).
---@param name string
function M.kill(name)
  terminal.ctrlc(name)
end

---Run a shell command in a named, reusable terminal split.
---@param name string
---@param cmd string|string[] Shell command to run (as string or list of args).
---@param opts? table Options: { split_dir?, size?, focus?, keymaps?, autoscroll? }
---@field split_dir? "top"|"bottom"|"left"|"right"
---@field size? integer
---@field focus? boolean
---@field keymaps? table<string, string>
---@field autoscroll? boolean
function M.run(name, cmd, opts)
  opts = opts or {}
  M.kill(name) -- Kill any running job in this terminal first

  local split_dir = opts.split_dir or "bottom"
  local size = opts.size or 15
  local focus = opts.focus
  local keymaps = opts.keymaps
  local autoscroll = opts.autoscroll

  -- Open or reuse the terminal split
  local bufnr, winid = terminal.open(
    name,
    split_dir,
    size,
    focus,
    keymaps,
    autoscroll
  )
  -- Accept command as either a string or table (joined with spaces)
  local cmd_str = type(cmd) == "table" and table.concat(cmd, " ") or cmd
  terminal.send(name, cmd_str)
end

---Clear a terminal's screen and scrollback.
---@param name string
function M.clear(name)
  terminal.clear(name)
end

---Close a terminal window.
---@param name string
function M.close(name)
  terminal.close(name)
end

return M
