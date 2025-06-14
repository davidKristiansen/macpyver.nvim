-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local config = require("macpyver.config")
local job = require("macpyver.job")
local util = require("macpyver.util")

local M = {}

---Builds the CLI command for macpyver based on config and opts.
---@param file string Path to the YAML file to run
---@param opts? table
---@return string[] cmdlist
local function build_command(file, opts)
  opts = opts or {}
  local cfg = config.merge_user_config(vim.g.macpyver_config or {})

  local abs_file = vim.fn.fnamemodify(file, ":p")
  local cwd = vim.fn.getcwd()

  local file_arg
  local test_base_path

  if vim.startswith(abs_file, cwd .. "/") then
    -- File is inside cwd: make path relative and use cwd as base
    file_arg = vim.fn.fnamemodify(abs_file, ":.")
    test_base_path = cwd
  else
    -- File is outside cwd: use only the filename and its parent as base
    file_arg = vim.fn.fnamemodify(abs_file, ":t") -- just filename
    test_base_path = vim.fn.fnamemodify(abs_file, ":h")
  end

  local macpyver_run_args = vim.tbl_deep_extend("force", {}, cfg.macpyver or {}, opts.macpyver or {})
  macpyver_run_args.test_base_path = test_base_path

  local cli_args = util.table_to_cli_args(macpyver_run_args)
  local cmd = { "macpyver" }
  vim.list_extend(cmd, cli_args)
  table.insert(cmd, file_arg)
  return cmd
end


---Runs the macpyver CLI job, piping output to the appropriate panel.
---@param file string Path to YAML file to run
---@param opts? table  # Merged config; see config.lua for fields.
function M.run(file, opts)
  -- Merge config: global (vim.g.macpyver_config) < overridden by < opts
  opts = vim.tbl_deep_extend("force", vim.g.macpyver_config or {}, opts or {})

  local panel_name = opts.job_panel or "macpyver"
  local cmd = build_command(file, opts)
  job.run(panel_name, cmd, {
    split_dir = opts.split_dir,
    size = opts.size,
    autoscroll = opts.autoscroll,
    focus = opts.focus,
    clear_before_run = opts.clear_before_run ~= false, -- default: true
    panel = panel_name,
    keymaps = opts.keymaps,
  })
end

return M
