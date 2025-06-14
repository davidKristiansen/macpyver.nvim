-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local M = {}

local config = require("macpyver.config")

-- Pull user config from global var if present
local user_config = vim.g.macpyver_config or {}

-- The merged config (module-level cache, updated via setup())
---@type table
local _merged_config = config.merge_user_config(user_config)

---Returns the merged plugin config (default + user).
---@return table
function M.get_config()
  return _merged_config
end

---Sets up/overrides user config and recomputes the merged config.
---You do NOT need to call this unless setting config programmatically (see README).
---@param user_config? table
function M.setup(user_config)
  -- Update the global user config (preserves across plugin reloads)
  vim.g.macpyver_config = vim.tbl_deep_extend(
    "force",
    vim.g.macpyver_config or {},
    user_config or {}
  )
  -- Update our local merged config cache
  _merged_config = config.merge_user_config(vim.g.macpyver_config)
end

-- Register user commands (side-effect on load)
require("macpyver.commands")

return M
