---@param tbl table<string, any>
---@return string[]
local function table_to_cli_args(tbl)
  local function kebab_case(str)
    return str:gsub("_", "-")
  end
  local args = {}
  for k, v in pairs(tbl) do
    if v ~= nil then
      table.insert(args, "--" .. kebab_case(k))
      table.insert(args, tostring(v))
    end
  end
  return args
end

return {
  table_to_cli_args = table_to_cli_args,
}
