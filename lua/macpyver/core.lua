-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local M = {}

-- User options (overridable with setup)
M.opts = {
  config_path    = "",
  resources_path = "",
  output_root    = "",
  min_width      = 50,
  auto_close     = false,
  autoscroll     = true,
  keymaps        = { close = "q", ctrlc = "c" },
}

-- State for the current terminal buffer (global for the plugin)
M.state = {
  term_bufnr = nil,
}

-- Setup function for user config
function M.setup(opts)
  M.opts = vim.tbl_extend("force", M.opts, opts or {})
end

-- Public API: run the default macpyver job
function M.run()
  local bufnr = require("macpyver.runner").run(M.opts, nil)
  if bufnr then M.state.term_bufnr = bufnr end
end

-- Public API: run a specific case under cursor
function M.run_case()
  require("macpyver.case").run_case(M.opts)
end

-- Expose term helpers for use by keymaps
M._term_ctrlc = require("macpyver.term")._term_ctrlc
M._term_close = require("macpyver.term")._term_close

return M
