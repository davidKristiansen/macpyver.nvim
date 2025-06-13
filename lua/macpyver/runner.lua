-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local config = require("macpyver.config")
local job = require("macpyver.job")

local M = {}

---Builds the CLI command for macpyver based on config and opts.
---@param file string
---@param opts? MacpyverConfig
---@return string[]
local function build_command(file, opts)
  opts = opts or {}
  local cfg = config.merge_user_config(vim.g.macpyver_config or {})
  local cwd = vim.fn.getcwd()
  local rel_file = vim.fn.fnamemodify(file, ":.")

  local args = {
    "macpyver",
    "--config", opts.config_path or cfg.config_path or "",
    "--resources", opts.resources_path or cfg.resources_path or "",
    "--output-root", opts.output_root or cfg.output_root or "",
    "--test-base-path", cwd,
    rel_file,
  }
  if opts.test_case then
    table.insert(args, "--test-case")
    table.insert(args, opts.test_case)
  end
  -- Remove empty args
  local filtered = {}
  for _, arg in ipairs(args) do
    if arg ~= "" then table.insert(filtered, arg) end
  end
  return filtered
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
