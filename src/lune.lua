local buf = require 'buf'
local environment = require 'env'
local is_symbol = require 'sym'.is_symbol

local _M = {}
_M.__index = _M

function is_list(o)
  return type(o) == "table" and o[1]
end

function is_pair(o)
  return type(o) == "table" and #o == 2
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
        list[#list+1] = _M.tokenize(buf)
      end
    end
    return list
  elseif token == ")" then
    error("unexpectd )")
  elseif token == "'" then
    return {token, _M.tokenize(buf)}
  elseif token == "`" then
    return {token, _M.tokenize(buf)}
  elseif token == "~" then
    return {token, _M.tokenize(buf)}
  elseif token == "~@" then
    return {token, _M.tokenize(buf)}
  else
    -- atom
    return token
  end
end

local function cons(a, list)
  local x = {a}
  for _, v in ipairs(list) do
    x[#x+1] = v
  end
  return x
end

local function add(env, args)
  local i = 0
  for _, v in ipairs(args) do
    if not is_number(v) then
      error("not a number")
    end
    i = i + v
  end
  return i
end

local native_functions = {}
native_functions["+"]=add
native_functions["cons"]=cons

local function append(args)
  local a = args[1]
  local b = args[2]

  if is_list(a) and is_list(b) then
    for _, v in ipairs(b) do
      a[#a+1] = v
    end
    return a
  elseif is_list(a) and not b then
    return a
  else
    error("invalid arguments!")
  end
end

local function eval_node(atom, env)
  if is_symbol(atom) then
    return env:get(atom)
  elseif is_list(atom) then
    local a = {}
    for i,v in next, atom, 1 do
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

function trace(o)
  if not o then
    print(nil)
    return
  end
  for k,v in pairs(o) do
    print(k, v)
  end
end

local function is_user_function(o)
  return o and o.args and o.env and o.body
end

local function is_function(o)
  if native_functions[o] then
    return true
  end
  return is_user_function(o)
end

local function rest(o)
  if not is_list(o) then
    error("not a list")
  end

  local t = {}
  for _, v in next, o, 1 do
    t[#t+1] = v
  end
  return t
end

local function expand_quasiquote(atom, env)
  if not is_pair(atom) then
    return {"'", atom}
  end

  if atom[1] == "~" then
    return atom[2]
  end

  if is_pair(atom) then
    if is_list(atom[1]) and atom[1][1] == "~@" then
      local rest = rest(atom)
      return {"append", atom[1][2], rest}
    end
  end
  local rest = rest(atom)
  return { "cons", expand_quasiquote(atom[1], env), expand_quasiquote(rest, env) }
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

    -- trace(atom)

    local first = atom[1]

    if is_symbol(first) or is_list(first) then
      first = eval(atom[1], env)
    end

    if first == "define" then
      local sym = atom[2]
      assert(is_symbol(sym))
      local value = eval(atom[3], env)
      env:define(sym, value)
      return sym
    elseif first == "let" then
      local bindings = atom[2]
      local body = atom[3]

      local keys = {}
      local vals = {}
      for i, v in ipairs(bindings) do
        keys[i] = v[1]
        vals[i] = eval(v[2], env)
      end
      local e = env:bind(keys, vals)
      return eval(body, e)
    elseif first == "set!" then
      local sym = atom[2]
      local val = eval(atom[3], env)
      return env:set(sym, val)
    elseif first == "lambda" then
      local f = {
        args=atom[2],
        body=atom[3],
        env=env:create()
      }
      return f
    elseif first == "'" then
      return atom[2]
    elseif first == "`" then
      return expand_quasiquote(atom[2], env)
    elseif first == "begin" then
      local x
      for _, v in next, atom, 1 do
        x = eval(v, env)
      end
      return x
    elseif first == "if" then
      local pred = eval(atom[2], env)
      if pred then
        atom = atom[3]
      elseif #atom > 3 then
        atom = atom[4]
      else
        return false
      end
    elseif is_user_function(first) then
      local args = {}
      for _, v in next, atom, 1 do
        args[#args+1] = eval(v, env)
      end

      local e = first.env:bind(first.args, args)

      return eval(first.body, e)
    else
      local func = native_functions[first]
      local args = {}

      for _, v in next, atom, 1 do
        args[#args+1] = eval(v, env)
      end

      return func(env, args)
    end
  end
end

function _M.parse_eval(s, e)
  local b = buf.create(s)
  local tokens = _M.tokenize(b)
  local result = eval(tokens, e or environment.create())
  return result
end

function repl()
  local env = environment.create()
  while true do
    io.write(">")
    io.flush()
    local line = io.read()
    if not line then
      print("exiting...")
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
  if is_list(r1) and is_list(r2) then
    for i,v in ipairs(r1) do
      if v ~= r2[i] then 
        print(string.format("%s == %s FAIL", t1, t2))
        return
      end
    end
    print(string.format("%s == %s PASS", t1, t2))
  else
    if r1 == r2 then
      print(string.format("%s == %s PASS", t1, t2))
    else
      print(string.format("%s == %s FAIL", t1, t2))
    end
  end
end

local function run_tests()
  assert_expr("3", "(+ 1 2)")
  assert_expr("2", "(if 1 2 3)")
  assert_expr("2", "(if false 1 2)")
  assert_expr("1", "((lambda (x) (+ 1 x)) 0)")
  assert_expr("1", "(let ((x 1)) x)")
  assert_expr("'(1 2)", "'(1 2)")
  assert_expr("'(1 2)", "`(1 2)")
end

if arg[1] == "test" then
  run_tests()
else
  repl()
end
