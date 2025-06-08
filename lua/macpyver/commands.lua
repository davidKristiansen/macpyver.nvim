-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local core = require("macpyver.core")

if not vim.g.macpyver_plugin_loaded then
  vim.api.nvim_create_user_command("MacpyverRun", function() core.run() end, {})
  vim.api.nvim_create_user_command("MacpyverCase", function() core.run_case() end, {})
  vim.g.macpyver_plugin_loaded = true
end
