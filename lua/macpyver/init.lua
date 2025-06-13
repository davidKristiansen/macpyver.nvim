-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local M = {}

local config = require("macpyver.config")
local user_config = vim.g.macpyver_config or {}
local _merged_config = config.merge_user_config(user_config)

function M.get_config()
  return _merged_config
end

function M.setup(user_config)
  vim.g.macpyver_config = vim.tbl_deep_extend(
    "force",
    vim.g.macpyver_config or {},
    user_config or {}
  )
  _merged_config = config.merge_user_config(vim.g.macpyver_config)
end

-- Register user commands!
require("macpyver.commands")

return M
