local _M = {}
_M.__index = _M

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
