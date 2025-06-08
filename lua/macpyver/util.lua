-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local Util = {}

function Util.get_parent_dir(filepath)
  return vim.fn.fnamemodify(filepath, ":h")
end

function Util.get_basename(filepath)
  return vim.fn.fnamemodify(filepath, ":t")
end

function Util.build_cmd(opts, test_base, positional)
  return string.format(
    "macpyver --config %s --resources %s --output-root %s --test-base-path %s %s",
    vim.fn.shellescape(opts.config_path),
    vim.fn.shellescape(opts.resources_path),
    vim.fn.shellescape(opts.output_root),
    vim.fn.shellescape(test_base),
    vim.fn.shellescape(positional)
  )
end

return Util
