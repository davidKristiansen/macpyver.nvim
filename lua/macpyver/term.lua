-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local Term = {}

function Term.maybe_autoscroll(win, opts)
  if opts.autoscroll then
    vim.api.nvim_set_current_win(win)
    vim.cmd("normal! G")
  end
end

local function close_if_only_window_left(bufnr)
  local wins = vim.api.nvim_tabpage_list_wins(0)
  if #wins == 1 and vim.api.nvim_win_get_buf(wins[1]) == bufnr then
    vim.schedule(function()
      vim.cmd("qa")
    end)
    return true
  end
  return false
end

function Term.setup_autocmd_auto_close(bufnr, opts)
  if not opts.auto_close then return end
  vim.api.nvim_create_autocmd("WinEnter", {
    buffer = bufnr,
    desc = "Macpyver auto-close if only split left (WinEnter)",
    callback = function()
      close_if_only_window_left(bufnr)
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = bufnr,
    desc = "Macpyver auto-close if only split left (VimResized)",
    callback = function()
      close_if_only_window_left(bufnr)
    end,
  })
end

Term.close_if_only_window_left = close_if_only_window_left

function Term.setup_term_keymaps(bufnr, opts)
  local keymaps = opts.keymaps or {}
  local close_key = keymaps.close or "q"
  local ctrlc_key = keymaps.ctrlc or "c"
  vim.api.nvim_buf_set_keymap(bufnr, "n", close_key,
    [[<Cmd>lua require("macpyver")._term_close(]] .. bufnr .. [[)<CR>]],
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(bufnr, "n", ctrlc_key,
    [[<Cmd>lua require("macpyver")._term_ctrlc(]] .. bufnr .. [[)<CR>]],
    { noremap = true, silent = true }
  )
end

function Term._term_ctrlc(bufnr)
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      local job = vim.b.terminal_job_id or vim.t.terminal_job_id or 0
      if job ~= 0 and vim.fn.jobwait({ job }, 0)[1] == -1 then
        vim.api.nvim_chan_send(job, "\003")
      end
      break
    end
  end
end

function Term._term_close(bufnr)
  Term._term_ctrlc(bufnr)
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      if #wins > 1 then
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end)
      else
        vim.cmd("qa")
      end
      break
    end
  end
end

return Term
