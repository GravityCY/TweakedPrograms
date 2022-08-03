local t = {};

function t.toString(tab, si, ei)
  local str = "";
  si = si or 1;
  ei = ei or #tab;
  for i = si, ei do str = str .. tab[i]; end
  return str;
end

function t.toTable(str, sep)
  sep = sep or " ";

  local tab = {};
  for substr in str:gmatch(string.format("[^%s]+", sep)) do
    tab[#tab+1] = substr;
  end
  return tab;
end

return t;