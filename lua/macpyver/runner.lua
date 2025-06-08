-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local util = require("macpyver.util")
local term = require("macpyver.term")
local core = require("macpyver.core")

local Runner = {}

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

function Runner.open_term(cmd, opts, win)
  local api = vim.api
  local prev_win = api.nvim_get_current_win()

  if win then
    -- Always switch to Macpyver split to safely clear it
    api.nvim_set_current_win(win)
    api.nvim_command("enew")
    -- Set size as appropriate
    if opts.split_type == "vertical" and opts.min_width then
      api.nvim_win_set_width(win, opts.min_width)
    elseif opts.split_type == "horizontal" and opts.min_height then
      api.nvim_win_set_height(win, opts.min_height)
    end
  else
    -- Create the split, focus is always on the new split now
    if opts.split_type == "vertical" then
      api.nvim_command("vsplit")
    else
      api.nvim_command("split")
    end
    win = api.nvim_get_current_win()
    if opts.split_type == "vertical" and opts.min_width then
      api.nvim_win_set_width(win, opts.min_width)
    elseif opts.split_type == "horizontal" and opts.min_height then
      api.nvim_win_set_height(win, opts.min_height)
    end
  end

  -- Always create terminal in the Macpyver split
  api.nvim_set_current_win(win)
  local shell = os.getenv("SHELL") or "/bin/sh"
  api.nvim_command("terminal " .. shell .. " -c " .. vim.fn.shellescape(cmd))
  local bufnr = api.nvim_get_current_buf()
  require("macpyver.core").state.term_bufnr = bufnr

  if opts.autoscroll then
    require("macpyver.term").maybe_autoscroll(win, opts)
  end

  -- Restore focus if user does not want to follow Macpyver split
  if opts.focus_on_run == false then
    api.nvim_set_current_win(prev_win)
  end

  return win
end

function Runner.run(opts, case_num)
  local api = vim.api
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

  local win = Runner.get_term_win()
  if win then
    local bufnr = api.nvim_win_get_buf(win)
    local job = vim.b.terminal_job_id or vim.t.terminal_job_id or 0
    if job ~= 0 and vim.fn.jobwait({ job }, 0)[1] == -1 then
      api.nvim_set_current_win(win)
      api.nvim_chan_send(job, "\003\n")
      api.nvim_chan_send(job, "clear\n")
      api.nvim_chan_send(job, cmd .. "\n")
      if opts.autoscroll then
        term.maybe_autoscroll(win, opts)
      end
    else
      Runner.open_term(cmd, opts, win)
    end
  else
    Runner.open_term(cmd, opts, nil)
  end

  term.setup_autocmd_auto_close(core.state.term_bufnr, opts)
  term.close_if_only_window_left(core.state.term_bufnr)
  term.setup_term_keymaps(core.state.term_bufnr, opts)

  return core.state.term_bufnr
end

return Runner
