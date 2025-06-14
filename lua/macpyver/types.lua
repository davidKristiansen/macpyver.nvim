-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

---@class MacpyverKeymaps
---@field clear? string     -- Key to clear output
---@field kill? string      -- Key to kill job

---@class MacpyverConfig
---@field config_path? string              -- Path to main config YAML
---@field resources_path? string           -- Path to resource YAML
---@field output_root? string              -- Output directory
---@field split_dir? "top"|"bottom"|"left"|"right"
---@field size? integer                    -- Terminal split width/height
---@field autoscroll? boolean              -- Auto-scroll terminal to end
---@field focus_on_run? boolean            -- Focus terminal after running
---@field clear_before_run? boolean        -- Clear terminal before each run
---@field keymaps? MacpyverKeymaps         -- Terminal keymaps

---@class MacpyverPanelKeymaps
---@field clear? string   -- Key to clear panel output
---@field close? string   -- Key to close the panel window

---@class MacpyverPanelOpts
---@field split_dir? "top"|"bottom"|"left"|"right"
---@field size? integer
---@field autoscroll? boolean
---@field focus? boolean
---@field keymaps? MacpyverPanelKeymaps
