local sym = require 'sym'
local Buf = {}
Buf.__index = Buf

Buf.END_OF_FILE = "end of file"

function Buf.create(buf)
  local b = { buf=buf, pos=1 }
  setmetatable(b, Buf)
  return b
end

function Buf:peek()
  if self.pos > self.buf:len() then
    return
  end
  return self.buf:sub(self.pos, self.pos)
end

function Buf:next()
  if self.pos > self.buf:len() then
    return
  end

  local t = self.buf:sub(self.pos, self.pos)
  self.pos = self.pos + 1
  return t
end

local function is_reserved(t)
  local x = {
    "+", "-", "*", "/", "%",
    "if", "lambda", "begin", "define",
    "set!", "let", "cons"
  }
  for _, v in ipairs(x) do
    if v == t then
      return true
    end
  end

  return false
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

  if is_reserved(t) then
    return t
  end

  sym.insert(t)
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
    if c and not is_whitespace(c) then
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
      return t
    elseif t == "`" then
      return t
    elseif t == "~" then
      if self:peek() == "@" then
        self:read()
        return "~@"
      end
      return "~"
    elseif t == ";" then
      error("not implemented")
    elseif is_whitespace(t) then
    else
      return self:read_atom(t)
    end
  end
end

return Buf
