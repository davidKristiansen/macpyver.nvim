-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local util = require("macpyver.util")
local term = require("macpyver.term")
local core = require("macpyver.core")

local Runner = {}

-- Find the macpyver terminal window if open
function Runner.get_term_win()
  local bufnr = core.state.term_bufnr
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        return win
      end
    end
  end
  return nil
end

-- Open a new terminal (or reuse split), always providing a fresh terminal for a new job
function Runner.open_term(cmd, opts, win)
  if win then
    vim.api.nvim_set_current_win(win)
    vim.cmd("enew") -- new buffer in split
  else
    vim.cmd("vsplit")
    win = vim.api.nvim_get_current_win()
    if opts.min_width then
      vim.api.nvim_win_set_width(win, opts.min_width)
    end
  end
  local shell = os.getenv("SHELL") or "/bin/sh"
  vim.cmd("terminal " .. shell .. " -c " .. vim.fn.shellescape(cmd))
  local bufnr = vim.api.nvim_get_current_buf()
  core.state.term_bufnr = bufnr
  if opts.autoscroll then
    term.maybe_autoscroll(win, opts)
  end
  return win
end

function Runner.run(opts, case_num)
  local api = vim.api
  -- Validate: must be in a file buffer
  local file = api.nvim_buf_get_name(0)
  if not file or file == "" then
    vim.notify("Macpyver: No file open (or buffer not saved)!", vim.log.levels.ERROR)
    return
  end
  if vim.fn.filereadable(file) == 0 then
    vim.notify("Macpyver: Current file is not readable! Please save first.", vim.log.levels.ERROR)
    return
  end

  local test_base = util.get_parent_dir(file)
  local positional = util.get_basename(file)

  -- Check required opts
  for k, v in pairs({ config_path = opts.config_path, resources_path = opts.resources_path, output_root = opts.output_root }) do
    if not v or v == "" then
      vim.notify("Macpyver: Option '" .. k .. "' is missing!", vim.log.levels.ERROR)
      return
    end
  end

  local cmd = util.build_cmd(opts, test_base, positional)
  if case_num then
    cmd = cmd .. " --test-cases " .. tostring(case_num)
  end

  -- Try to reuse a running split if present, otherwise create new
  local win = Runner.get_term_win()
  if win then
    local bufnr = api.nvim_win_get_buf(win)
    local job = vim.b.terminal_job_id or vim.t.terminal_job_id or 0
    if job ~= 0 and vim.fn.jobwait({ job }, 0)[1] == -1 then
      -- Terminal is running: send Ctrl-C, clear, and run command
      api.nvim_set_current_win(win)
      api.nvim_chan_send(job, "\003\n")
      api.nvim_chan_send(job, "clear\n")
      api.nvim_chan_send(job, cmd .. "\n")
      if opts.autoscroll then
        term.maybe_autoscroll(win, opts)
      end
    else
      -- Terminal dead: open a new terminal buffer in same split
      Runner.open_term(cmd, opts, win)
    end
  else
    -- No split: open new split and terminal
    Runner.open_term(cmd, opts, nil)
  end

  -- Setup keymaps/autocmds on the current terminal buffer
  term.setup_autocmd_auto_close(core.state.term_bufnr, opts)
  term.close_if_only_window_left(core.state.term_bufnr)
  term.setup_term_keymaps(core.state.term_bufnr, opts)

  return core.state.term_bufnr
end

return Runner
