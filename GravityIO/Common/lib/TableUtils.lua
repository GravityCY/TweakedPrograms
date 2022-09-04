local t = {};

function t.copy(tab)
  local new = {};
  for k, v in pairs(tab) do
    if (type(v) == "table") then v = t.copy(v); end
    new[k] = v;
  end
  return new;
end

function t.cat(tab1, tab2)
  for i, v in ipairs(tab2) do table.insert(tab1, v); end
end

function t.toString(tab, seperator)
  local str = "";
  for i = 1, #tab do 
    str = str .. tab[i];
    if (i ~= #tab) then str = str .. seperator end
  end
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

function t.range(tab, from, to)
  local newTab = {};
  from = from or 1;
  to = to or #tab;
  for i = from, to do
    newTab[#newTab+1] = tab[i];
  end
  return newTab;
end

function t.swap(tab, i1, i2)
  local temp = tab[i1];
  tab[i1] = tab[i2];
  tab[i2] = temp;
end

return t;