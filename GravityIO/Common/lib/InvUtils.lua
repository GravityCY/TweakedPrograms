local ItemUtils = require("ItemUtils");

local t = {};

local function getAddress(periph)
  if (type(periph) == "table") then return peripheral.getName(periph);
  else return periph end
end

local function getPeripheral(periph)
  if (type(periph) ~= "table") then return peripheral.wrap(periph);
  else return periph end
end

local function where(before, after)
  local where = {};
  for slot, curItem in pairs(after) do
    local prevItem = before[slot];
    if (prevItem == nil) then 
      where[slot] = curItem.count;
      break;
    elseif(prevItem.count ~= curItem.count) then
      local amount = 0;
      if (t.getItem) then amount = curItem.count;
      else amount = curItem.count - prevItem.count; end
      where[slot] = amount;
    end
  end
  return where;
end

function t.wrap(input)
  local p = getPeripheral(input);
  if (p == nil) then return end
  local addr = getAddress(input);

  local list = p.list;

  function p.pullSlot(fromAddr, fromSlot, amount, toSlot)
    local fromAddrs = getAddress(fromAddr);
    
    local prev = p.list();
    local pulled = p.pullItems(fromAddrs, fromSlot, amount, toSlot);
    if (pulled == 0) then return pulled, {} end
    local cur = p.list();
    return pulled, where(prev, cur);
  end

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
    for slot, _ in pairs(fromPeriph.list()) do
      local pull = p.pullItems(fromAddr, slot, amount - pulled);
      pulled = pulled + pull;
      if pulled == amount then break end
    end
    return pulled;
  end

  function p.pullAll(from)
    local fromPeriph = getPeripheral(from);
    local fromAddr = getAddress(from);

    local pulled = 0;
    for slot, _ in pairs(fromPeriph.list()) do
      local pull = p.pullItems(fromAddr, slot, 64);
      pulled = pulled + pull;
    end
    return pulled;
  end

  function p.pushSlot(toAddr, fromSlot, amount) 
    local toAddrs = getAddress(toAddr);
    local toInv = getPeripheral(toAddr);

    local prev = toInv.list();
    local pushed = p.pushItems(toAddrs, fromSlot, amount);
    local cur = toInv.list();
    return pushed, where(prev, cur);
  end

  function p.push(toAddr, itemName, amount, toSlot)
    local toAddrs = getAddress(toAddr);

    local pushed = 0;
    for slot, item in pairs(p.list()) do
      if (item.name == itemName) then
        local push = p.pushItems(toAddrs, slot, amount - pushed, toSlot);
        pushed = pushed + push;
        if pushed == amount then break end
      end
    end
    return pushed;
  end

  function p.pushAny(toAddr, amount, toSlot)
    local toAddrs = getAddress(toAddr);

    local pushed = 0;
    for slot, _ in pairs(p.list()) do
      local push = p.pushItems(toAddrs, slot, amount - pushed, toSlot);
      pushed = pushed + push;
      if pushed == amount then break end
    end
    return pushed;
  end

  function p.pushAll(to)
    local toAddr = getAddress(to);

    local pushed = 0;
    for slot, item in pairs(p.list()) do
      local push = p.pushItems(toAddr, slot, item.count);
      pushed = pushed + push;
      if (pushed >= item.count) then break end
    end
    return pushed;
  end

  function p.count(itemName)
    local count = 0;
    for _, item in pairs(p.list()) do
      if (item.name == itemName) then count = count + item.count; end
    end
    return count;
  end

  function p.countAll()
    local count = 0;
    for _, item in pairs(p.list()) do count = count + item.count; end
    return count;
  end

  function p.taken()
    local slots = 0;
    for _, _ in pairs(p.list()) do slots = slots + 1; end
    return slots;
  end

  function p.list()
    local items = list();
    for slot, item in pairs(items) do
      if (not ItemUtils.exists(item.name)) then
        ItemUtils.add(p.getItemDetail(slot));
      end
      ItemUtils.wrap(item);
    end
    return items;
  end

  return p;
end

function t.wrapList(list)
  for _, per in ipairs(list) do t.wrap(per); end
  return list;
end

function t.find(addr)
  local peripherals = {peripheral.find(addr)};
  local wrapped = {};
  for index, value in ipairs(peripherals) do wrapped[index] = t.wrap(value); end
  return wrapped;
end

return t;