-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

---@class MacpyverKeymaps
---@field clear? string     -- Key to clear output
---@field kill? string      -- Key to kill job


---@class MacpyverConfig
---@field config_path? string
---@field resources_path? string
---@field output_root? string
---@field split_type? "top"|"bottom"|"left"|"right"
---@field size? integer
---@field autoscroll? boolean
---@field focus_on_run? boolean
---@field clear_before_run? boolean
---@field keymaps? MacpyverKeymaps
