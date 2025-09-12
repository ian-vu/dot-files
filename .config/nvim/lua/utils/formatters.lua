local M = {}

-- Global registry to collect formatters from all conform configs
_G.conform_formatters = _G.conform_formatters or {}

-- Function for plugins to register their formatters
function M.register_formatters(formatters_by_ft)
  if not formatters_by_ft then
    return
  end

  for _, formatters_list in pairs(formatters_by_ft) do
    if type(formatters_list) == 'table' then
      for _, formatter in ipairs(formatters_list) do
        if not vim.tbl_contains(_G.conform_formatters, formatter) then
          table.insert(_G.conform_formatters, formatter)
        end
      end
    end
  end
end

-- Get all registered formatters
function M.get_all_formatters()
  return _G.conform_formatters
end

return M
