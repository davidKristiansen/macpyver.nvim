-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local config ---@type MacpyverConfig
config = {
  macpyver = {},           -- All CLI options for the macpyver binary.
  split_dir = "right",     -- "top", "bottom", "left", or "right"
  size = 90,               -- Height (lines) for horizontal; width (cols) for vertical
  autoscroll = true,       -- Auto-scroll terminal output
  clear_before_run = true, -- Clear terminal before run
  focus = true,            -- Focus terminal after run
  keymaps = {
    close = "q",
    clear = "c",
  },
}

---Merges user config into defaults, with user config taking precedence.
---@param user_config? table
---@return MacpyverConfig
function config.merge_user_config(user_config)
  return vim.tbl_deep_extend("force", config, user_config or {})
end

---Validates plugin config values (does not check macpyver table content).
---@param cfg MacpyverConfig
---@return boolean, string|nil ok, err Error message if config invalid.
function config.validate(cfg)
  local ok, err = pcall(function()
    vim.validate({
      split_dir = {
        cfg.split_dir,
        function(v)
          return v == nil or v == "top" or v == "bottom" or v == "left" or v == "right"
        end,
        "must be 'top', 'bottom', 'left', or 'right'",
      },
      size = { cfg.size, "number", true },
      autoscroll = { cfg.autoscroll, "boolean", true },
      clear_before_run = { cfg.clear_before_run, "boolean", true },
      focus = { cfg.focus, "boolean", true },
      keymaps = { cfg.keymaps, "table", true },
    })
  end)
  return ok, err
end

return config
