local t = {};

function t.wordCase(str)
  return str:gsub("%L%l", string.upper):gsub("^%l", string.upper)
end

return t;