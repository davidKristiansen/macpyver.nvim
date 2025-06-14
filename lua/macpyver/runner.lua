-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local config = require("macpyver.config")
local job = require("macpyver.job")
local util = require("macpyver.util")

local M = {}

---Builds the CLI command for macpyver based on config and opts.
---@param file string
---@param opts? table  -- opts.macpyver should be the table for CLI args
---@return string[]
local function build_command(file, opts)
  opts = opts or {}
  local cfg = config.merge_user_config(vim.g.macpyver_config or {})
  local cwd = vim.fn.getcwd()
  local rel_file = vim.fn.fnamemodify(file, ":.")

  -- Collect args: opts.macpyver or fallback to cfg.macpyver or {}
  local macpyver_run_args = vim.tbl_deep_extend("force", {}, cfg.macpyver or {}, opts.macpyver or {})
  -- Always ensure test_base_path is set to cwd (override any config)
  macpyver_run_args.test_base_path = cwd

  -- Convert to CLI args
  local cli_args = util.table_to_cli_args(macpyver_run_args)

  -- Compose command: {"macpyver", unpack(cli_args), rel_file}
  local cmd = { "macpyver" }
  vim.list_extend(cmd, cli_args)
  table.insert(cmd, rel_file)
  return cmd
end



---Run the macpyver CLI job, piping output to the appropriate panel.
---@param file string
---@param opts? MacpyverConfig
function M.run(file, opts)
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
