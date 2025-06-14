-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

-- Default config for macpyver.nvim



local config = {
  -- config_path = "",
  -- resources_path = "",
  -- output_path = "",
  macpyver = {},
  split_dir = "right", -- "top", "bottom", "left", or "right"
  size = 90,           -- Height (lines) for horizontal; width (cols) for vertical
  autoscroll = true,
  clear_before_run = true,
  focus = true,
  keymaps = {
    close = "q",
    clear = "c",
  },
}


-- Merge user config from vim.g.macpyver_config, with defaults.
function config.merge_user_config(user_config)
  return vim.tbl_deep_extend("force", config, user_config or {})
end

-- Validate config
function config.validate(cfg)
  local ok, err = pcall(function()
    -- job fields
    vim.validate({
      split_dir = {
        cfg.dir,
        function(v)
          return v == nil or v == "top" or v == "bottom" or v == "left" or v == "right"
        end,
        "must be 'top', 'bottom', 'left', or 'right'",
      },
      size = { cfg.size, "number", true },
      autoscroll = { cfg.autoscroll, "boolean", true },
      focus = { cfg.focus_on_run, "boolean", true },
      keymaps = { cfg.keymaps, "table", true }, -- If you add keymaps
    })
  end)
  return ok, err
end

return config
