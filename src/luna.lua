local _M = {}
_M.__index = _M

function is_list(o)
  if type(o) == "table" then
    return true
  end
  return false
end

function is_atom(o)
  return not is_list(o)
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
        list[#list+1] = read_token()
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
  for _, v in args do
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

function eval(atom, env)
  while true do
    if is_list(atom) then
      if #atom == 0 then
        return nil
      end
    else
      return eval_node(atom, env)
    end

    local first = atom[1]

    if first == "define" then
      local sym = atom[2]
      local value = eval(atom[3], env)
      env[sym] = value
      return sym
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
      for _, v in next(atom, 2) do
        args[#args+1] = eval(v, env)
      end
      return func(env, args)
    end
  end
end

function repl()
  while true do
    io.write(">")
    io.flush()
    local line = io.read()
    local b = buf.create(line)
    local tokens = _M.tokenize(b)
    local result = eval(tokens)
    print(result)
  end
end
