local buf = require 'buf'
local env = require 'env'
local is_symbol = require 'sym'.is_symbol

local _M = {}
_M.__index = _M

function is_list(o)
  return type(o) == "table" and o[1]
end

function is_atom(o)
  return not is_list(o)
end

function is_string(o)
  return type(o) == "string" and not is_symbol(o)
end

function is_number(o)
  return type(o) == "number"
end

function _M.tokenize(buf)
  local token = buf:next_token()
  print("token", token)
  if token == "(" then
    local list = {}

    while true do
      local t = buf:peek()

      if t == ")" then
        buf:next_token()
        break
      elseif not t then
        error("end of file")
      else
        list[#list+1] = buf:next_token()
      end
    end
    return list
  elseif token == ")" then
    error("unexpectd )")
  elseif token == "'" then
    return make_quote_form(token, buf)
  elseif token == "`" then
    return make_quote_form(token, buf)
  elseif token == "~" then
    return make_quote_form(token, buf)
  elseif token == "~@" then
    return make_quote_form(token, buf)
  else
    -- atom
    return token
  end
end

local function add(env, args)
  local i = 0
  for _, v in ipairs(args) do
    i = i + v
  end
  return i
end

local function resolve_function(atom, env)
  if atom == "+" then
    return add
  end

  error("not done yet")
end

local function eval_node(atom, env)
  if is_symbol(atom) then
    return env:get(atom)
  elseif is_list(atom) then
    local a = {}
    for i,v in next(atom, 2) do
      a[#a+1] = eval(v, env)
    end
    return a
  else
    return atom
  end
end

local function print_list(l)
  local s = "("
  for _, v in ipairs(l) do
    s = s .. v .. " "
  end
  return s .. ")"
end

function eval(atom, env)
  while true do
    if is_list(atom) then
      if #atom == 0 then
        return nil
      end
    else
      return eval_node(atom, env)
    end

    print("evaling: ", print_list(atom))
    local first = atom[1]

    if first == "define" then
      local sym = atom[2]
      assert(is_symbol(sym))
      local value = eval(atom[3], env)
      env:define(sym, value)
      return sym
    elseif first == "lambda" then
      local f = {
        args=atom[2],
        body=atom[3],
        env=env:create_child()
      }
      return f
    elseif first == "if" then
      local pred = eval(atom[2], env)
      if pred then
        atom = atom[3]
      elseif #atom > 3 then
        atom = atom[4]
      else
        return false
      end
    else
      -- evaluate function
      local func = resolve_function(first, env)
      local args = {}

      for i, v in ipairs(atom) do
        if i ~= 1 then
          args[#args+1] = eval(v, env)
        end
      end
      return func(env, args)
    end
  end
end

function _M.parse_eval(s, e)
  local b = buf.create(s)
  local tokens = _M.tokenize(b)
  local result = eval(tokens, e or env.create())
  return result
end

function repl()
  local env = env.create()
  while true do
    io.write(">")
    io.flush()
    local line = io.read()
    if not line then
      return
    end
    local b = buf.create(line)
    local tokens = _M.tokenize(b)
    local result = eval(tokens, env)
    print(result)
  end
end

local function assert_expr(t1, t2)
  local r1 = _M.parse_eval(t1)
  local r2 = _M.parse_eval(t2)

  if r1 == r2 then
    print(string.format("%s == %s PASS", t1, t2))
  else
    print(string.format("%s == %s FAIL", t1, t2))
  end
end

local function run_tests()
  assert_expr("3", "(+ 1 2)")
  assert_expr("2", "(if 1 2 3)")
  assert_expr("2", "(if false 1 2)")
end

if arg[1] == "test" then
  run_tests()
else
  repl()
end
