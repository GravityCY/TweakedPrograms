local t = {};
t.enums = {};
t.enums.toTable = {};
t.enums.toTable.SimpleTableMerger = 0;
t.enums.toTable.ComplexTableMerger = 1;


-- Shallow

function t.copy(tab)
  local new = {};
  for k, v in pairs(tab) do new[k] = v; end
  return new;
end

-- Deep
function t.deepCopy(tab)
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
  if (seperator == nil) then seperator = " "; end

  local str = "";
  for i = 1, #tab do 
    str = str .. tab[i];
    if (i ~= #tab) then str = str .. seperator end
  end
  return str;
end

function t.toTable(str, seperator)
  if (seperator == nil) then seperator = " "; end

  local tab = {};
  for substr in str:gmatch(string.format("[^%s]+", seperator)) do
    tab[#tab+1] = substr;
  end
  return tab;
end

function t.range(tab, from, to)
  if (from == nil) then from = 1; end
  if (to == nil or to > #tab) then to = #tab; end

  local newTab = {};
  for i = from, to do newTab[#newTab+1] = tab[i]; end
  return newTab;
end

function t.swap(tab, i1, i2)
  local temp = tab[i1];
  tab[i1] = tab[i2];
  tab[i2] = temp;
end

return t;