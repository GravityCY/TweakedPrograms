local i = {};

local function getAddress(periph)
  if (type(periph) == "table") then return peripheral.getName(periph);
  else return periph end
end

function i.wrap(p)
  local addr = getAddress(p);
  function p.pull(from, name, amount)
    local fromAddr = getAddress(from);
    local pulled = 0;
    for slot, item in pairs(from.list()) do
      if (item.name == name) then
        local pull = p.pullItems(fromAddr, slot, amount - pulled);
        pulled = pulled + pull;
        if pulled == amount then break end
      end
    end
  end

  function p.push(to, item, amount)
    local toAddr = getAddress(to);
    local pulled = 0;
    for slot, item in pairs(p.list()) do
      if (item.name == name) then
        local pull = p.pushItems(toAddr, slot, amount - pulled);
        pulled = pulled + pull;
        if pulled == amount then break end
      end
    end
  end

  function p.count(name)
    local count = 0;
    for slot, item in pairs(p.list()) do
      if (item.name == name) then count = count + item.count; end
    end
    return count;
  end

  return p;
end

function i.format(name)
  return name:match(":(.+)"):gsub("_", " "):gsub("%s.", string.upper):gsub("^.", string.upper);
end

return i;