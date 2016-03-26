local _M = {}
_M.__index = _M

local symbol_table = {}

function _M.insert(sym)
  symbol_table[sym] = sym
end

function _M.is_symbol(sym)
  return symbol_table[sym]
end

return _M
