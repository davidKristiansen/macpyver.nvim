-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local terminal = require("macpyver.terminal")

local M = {}

function M.kill(name)
  terminal.ctrlc(name)
end

---Run a shell command in a named, reusable terminal.
---@param name string
---@param cmd string|string[]
---@param opts? table { split_dir?, size?, focus? }
function M.run(name, cmd, opts)
  opts = opts or {}
  M.kill(name) -- Kill running job first
  local split_dir = opts.split_dir or "bottom"
  local size = opts.size or 15
  local focus = opts.focus
  local keymaps = opts.keymaps
  local autoscroll = opts.autoscroll


  local bufnr, winid = terminal.open(
    name,
    split_dir,
    size,
    focus,
    keymaps,
    autoscroll
  )
  -- Turn table command into string if needed
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
