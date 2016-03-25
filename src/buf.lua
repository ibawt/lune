local Buf = {}
Buf.__index = Buf

function Buf.create(buf)
  local b = { buf=buf, pos=0 }
  setmetatable(b, Buf)
  return b
end

function Buf:peek()
  return self.buf[self.pos]
end

function Buf:next()
  local t = self.buf[self.pos]
  self.pos += 1
  return t
end

local function parse_atom(t)
  local n = tonumber(t)
  if n then
    return n
  end

  if n == "true" then
    return true
  end

  if n == "false" then
    return false
  end

  if n == "nil" then
    return nil
  end

  return t
end

local function is_whitespace(t)
  return t == " "
end

function Buf:read_string()
  local s = ""
  while true do
    local c = self:next()
    if c == "\"" then
      local e = self:next()
      s = s .. e
    elseif c == "\"" then
      return s
    elseif c then
      s = s .. c
    else
      error("end of file")
    end
  end
end

function Buf:read_atom(t)
  while true do
    if self:peek() == ")" then
      return parse_atom(t)
    end
    local c = self:next()
    if not is_whitespace(c) then
      t = t .. c
    else
      return parse_atom(t)
    end
  end
  error("unreachable")
end

function Buf:next_token()
  while true do
    local t = self:next()

    if t == "\"" then
      return self:read_string()
    elseif t == "(" then
      return t
    elseif t == ")" then
      return t
    elseif t == "'" then
    elseif t == "~" then
    elseif t == ";" then
    elseif is_whitespace(t) then
    else
      return self:read_atom(t)
    end
  end
end

return Buf
