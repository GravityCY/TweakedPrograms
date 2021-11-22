local i = {};

local function getAddress(periph)
  if (type(periph) == "table") then return peripheral.getName(periph);
  else return periph end
end

local function getPeripheral(periph)
  if (type(periph) ~= "table") then return peripheral.wrap(periph);
  else return periph end
end

function i.wrap(p)

  local addr = getAddress(p);

  function p.pull(from, name, amount)
    local fromAddr = getAddress(from);
    local fromPeriph = getPeripheral(from);
    local pulled = 0;
    for slot, item in pairs(fromPeriph.list()) do
      if (item.name == name) then
        local pull = p.pullItems(fromAddr, slot, amount - pulled);
        pulled = pulled + pull;
        if pulled == amount then break end
      end
    end
    return pulled == amount;
  end

  function p.pullAny(from, amount)
    local fromAddr = getAddress(from);
    local fromPeriph = getPeripheral(from);
    local pulled = 0;
    for slot, item in pairs(fromPeriph.list()) do
      local pull = p.pullItems(fromAddr, slot, amount - pulled);
      pulled = pulled + pull;
      if pusshed == amount then break end
    end
    return pulled == amount;
  end

  function p.push(to, item, amount)
    local toAddr = getAddress(to);
    local pushed = 0;
    for slot, item in pairs(p.list()) do
      if (item.name == name) then
        local push = p.pushItems(toAddr, slot, amount - pushed);
        pushed = pushed + push;
        if pushed == amount then break end
      end
    end
    return pushed == amount;
  end

  function p.pushAny(to, amount)
    local toAddr = getAddress(to);
    local pushed = 0;
    for slot, item in pairs(p.list()) do
      local push = p.pushItems(toAddr, slot, amount - pushed);
      pushed = pushed + push;
      if pushed == amount then break end
    end
    return pushed == amount;
  end

  function p.pushAll(to)
    local toAddr = getAddress(to);
    for slot, item in pairs(p.list()) do
      local pushed = 0;
      while true do
        local push = p.pushItems(toAddr, slot, item.count);
        pushed = pushed + push;
        if (pushed >= item.count) then break end
      end
    end
    return true;
  end

  function p.count(name)
    local count = 0;
    for slot, item in pairs(p.list()) do
      if (item.name == name) then count = count + item.count; end
    end
    return count;
  end

  function p.anyCount()
    local count = 0;
    for slot, item in pairs(p.list()) do count = count + item.count; end
    return count;
  end

  return p;
end

function i.find(addr, wrap)
  local peripherals = {peripheral.find(addr)};
  if (wrap) then
    local wrapped = {};
    for k,v in pairs(peripherals) do wrapped[k] = i.wrap(v); end
  else return peripherals; end
end

function i.format(name)
  return name:match(":(.+)"):gsub("_", " "):gsub("%s.", string.upper):gsub("^.", string.upper);
end

return i;