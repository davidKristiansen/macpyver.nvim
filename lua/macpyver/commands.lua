-- SPDX-License-Identifier: MIT
-- Copyright David Kristiansen

local runner = require("macpyver.runner")
local case = require("macpyver.case")


---@type table<string, { impl: function, complete?: function }>
local subcommands = {}

-- Store last test case (scoped to Lua module, could also use vim.g)
local last_case_input = nil

local function is_yaml_file()
  local file = vim.api.nvim_buf_get_name(0)
  return file and file:match("%.ya?ml$"), file
end

subcommands.run = {
  impl = function(args)
    local is_yaml, file = is_yaml_file()
    if not is_yaml then
      vim.notify("[macpyver] Current buffer is not a YAML file.", vim.log.levels.WARN)
      return
    end
    runner.run(file)
  end,
}

subcommands.runcase = {
  impl = function(args)
    local is_yaml, file = is_yaml_file()
    if not is_yaml then
      vim.notify("[macpyver] Current buffer is not a YAML file.", vim.log.levels.WARN)
      return
    end
    local case_num, err = case.find_case_num()
    if not case_num then
      vim.notify("[macpyver] " .. (err or "Could not detect test case under cursor!"), vim.log.levels.ERROR)
      return
    end
    runner.run(file, { test_case = tostring(case_num) })
  end,
}


subcommands.runcaseinput = {
  impl = function(args)
    local is_yaml, file = is_yaml_file()
    if not is_yaml then
      vim.notify("[macpyver] Current buffer is not a YAML file.", vim.log.levels.WARN)
      return
    end
    vim.ui.input({
      prompt = "Enter test case (tip: <C-u> clears):",
      default = last_case_input or "",
    }, function(input)
      if input and #input > 0 then
        last_case_input = input
        runner.run(file, { test_case = input })
      else
        vim.notify("[macpyver] Cancelled.", vim.log.levels.INFO)
      end
    end)
  end,
}

vim.api.nvim_create_user_command("Macpyver", function(opts)
  local args = opts.fargs
  if #args == 0 then
    vim.notify("[macpyver] Usage: :Macpyver <run|runcase|runcaseinput>", vim.log.levels.WARN)
    return
  end
  local sub = subcommands[args[1]]
  if not sub then
    vim.notify("[macpyver] Unknown subcommand: " .. args[1], vim.log.levels.WARN)
    return
  end
  sub.impl({ unpack(args, 2) })
end, {
  nargs = "*",
  complete = function(arg_lead, cmd_line, cursor_pos)
    local split = vim.split(cmd_line, "%s+")
    if #split <= 2 then
      return vim.tbl_keys(subcommands)
    end
    return {}
  end,
})

return { subcommands = subcommands }
