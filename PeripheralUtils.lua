local p = {};

local sides = {top=true, left=true, right=true, bottom=true, back=true, front=true};

function p.getAll(addr)
  return {peripheral.find(addr)};
end

function p.getAllNotSide(addr)
  local filtered = {};
  for index, periph in pairs(p.getAll(addr)) do
    local pName = peripheral.getName(periph);
    if (not sides[pName]) then table.insert(filtered, periph); end
  end
  return filtered;
end

function p.getAllOnlySide(addr)
  local filtered = {};
  for index, periph in pairs(p.getAll(addr)) do
    local pName = peripheral.getName(periph);
    if (sides[pName]) then tabel.insert(filtered, periph); end
  end
end

return p;