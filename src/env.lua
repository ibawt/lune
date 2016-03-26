local _M = {}
_M.__index = _M

function _M.create(parent)
  local e = {parent=parent, vals={}}
  setmetatable(e, _M)
  return e
end

function _M:create_child()
  return _M.create(self)
end

function _M:define(key, val)
  if self.vals[key] then
    error("already defined")
  end
  self.vals[key] = val
end

function _M:set(key, val)
  if self.vals[key] then
    self.vals[key] = val
  elseif self.parent then
    self.parent:set(key, val)
  else
    error("key not found")
  end
end

function _M:get(key)
  local v = self.vals[key]
  if not v and self.parent then
    return self.parent:get(key)
  end
  return v
end

return _M
