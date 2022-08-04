local t = {};

function t.toString(tab, seperator)
  local str = "";
  for i = 1, #tab do 
    str = str .. tab[i];
    if (i ~= #tab) then str = str .. seperator end
  end
  return str;
end

function t.splice(tab, from, to)
  local newTab = {};
  from = from or 1;
  to = to or #tab;
  for i = from, to do
    newTab[#newTab+1] = tab[i];
  end
  return newTab;
end

return t;