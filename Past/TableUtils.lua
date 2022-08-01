local t = {};

function t.cat(tab1, tab2)
  for i, v in ipairs(tab2) do table.insert(tab1, v); end
end

function t.range(tab, from, to)
  from = from or 1;
  to = to or #tab;

  local temp = {};
  for i = from, to do
    temp[#temp+1] = tab[i];
  end
  return temp;
end

function t.toString(tab, from, to, seperator)
  from = from or 1;
  to = to or #tab;
  local str = tab[from];
  for i = from + 1, to do
    str = str .. " " .. tab[i];
  end
  return str;
end

-- 1, 2, 3
-- 1, 2, 3, 4, 5

function t.diff(tab1, tab2)
  local diff = {};
  for i, v in ipairs(tab2) do
    if (tab1[i] == nil) then diff[#diff+1] = v; end
  end
  for i, v in ipairs(tab1) do
    if (tab2[i] == nil) then diff[#diff+1] = v; end
  end
  return diff;
end

function t.remove(tab, doRemove)
  local temp = {}
  for i, v in ipairs(tab) do
    if (not doRemove(v)) then temp[#temp + 1] = v; end
  end
  return temp;
end

function t.swap(tab, i1, i2)
  local temp = tab[i1];
  tab[i1] = tab[i2];
  tab[i2] = temp;
end

return t;