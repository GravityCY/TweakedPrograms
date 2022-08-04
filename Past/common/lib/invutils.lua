local iu = require("ItemUtils");

local i = {};
i.getSlot = false;
i.getItem = true;

local function getAddress(periph)
  if (type(periph) == "table") then return peripheral.getName(periph);
  else return periph end
end

local function getPeripheral(periph)
  if (type(periph) ~= "table") then return peripheral.wrap(periph);
  else return periph end
end

function i.wrap(input)
  local p = getPeripheral(input);
  if (p == nil) then return end
  local addr = getAddress(input);

  -- This will use a comparison of state method
  function p.pushSlot(aToAddr, aFromSlot, aAmount, aToSlot) 
    local toAddr = getAddress(aToAddr);
    local toInv = getPeripheral(aToAddr);

    if (i.getSlot) then
      local prev = toInv.list();
      local pushed = p.pushItems(toAddr, aFromSlot, aAmount, aToSlot);
      local cur = toInv.list();
      local where = {};
      for slot, curItem in pairs(cur) do
        local prevItem = prev[slot];
        if (prevItem == nil) then 
          where[slot] = curItem.count;
          break;
        elseif(prevItem.count ~= curItem.count) then
          local amount = 0;
          if (i.getItem) then amount = curItem.count;
          else amount = curItem.count - prevItem.count; end
          where[slot] = amount;
        end
      end
      return pushed, where;
    else
      return p.pushItems(toAddr, aFromSlot, aAmount, aToSlot);
    end
  end

  function p.pullSlot(aFromAddr, aFromSlot, aAmount, aToSlot) 
    local fromAddr = getAddress(aFromAddr);

    if (i.getSlot) then
      local prev = p.list();
      local pulled = p.pullItems(fromAddr, aFromSlot, aAmount, aToSlot);
      if (pulled == 0) then return pulled, {} end
      local cur = p.list();
      local where = {};
      for slot, curItem in pairs(cur) do
        local prevItem = prev[slot];
        if (prevItem == nil) then 
          where[slot] = curItem.count;
          break;
        elseif(prevItem.count ~= curItem.count) then
          local amount = 0;
          if (i.getItem) then amount = curItem.count;
          else amount = curItem.count - prevItem.count; end
          where[slot] = amount; 
        end
      end
      return pulled, where;
    else
      return p.pushItems(fromAddr, aFromSlot, aAmount, aToSlot);
    end
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
      if pusshed == amount then break end
    end
    return pulled == amount;
  end

  function p.push(to, name, amount, toSlot)
    local toAddr = getAddress(to);
    local pushed = 0;
    for slot, item in pairs(p.list()) do
      if (item.name == name) then
        local push = p.pushItems(toAddr, slot, amount - pushed, toSlot);
        pushed = pushed + push;
        if pushed == amount then break end
      end
    end
    return pushed;
  end

  function p.pushAny(aToInv, amount, toSlot)
    local toAddr = getAddress(aToInv);
    local pushed = 0;
    for slot, _ in pairs(p.list()) do
      local push = p.pushItems(toAddr, slot, amount - pushed, toSlot);
      pushed = pushed + push;
      if pushed == amount then break end
    end
    return pushed;
  end

  function p.pushAll(to)
    local toAddr = getAddress(to);
    for slot, item in pairs(p.list()) do
      local pushed = 0;
      local push = p.pushItems(toAddr, slot, item.count);
      pushed = pushed + push;
      if (pushed >= item.count) then break end
    end
    return true;
  end

  function p.pullAll(from)
    local fromPeriph = getPeripheral(from);
    local fromAddr = getAddress(from);
    for slot, item in pairs(fromPeriph.list()) do p.pullItems(fromAddr, slot, 64); end
  end

  function p.splitAny(tos)
    local size = #tos;
    for slot, item in pairs(p.list()) do
      local splitAmount = item.count / size;
      for _, toInv in pairs(tos) do 
        toInv.pullItems(addr, slot, splitAmount); 
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

  function p.anyCount()
    local count = 0;
    for slot, item in pairs(p.list()) do count = count + item.count; end
    return count;
  end

  function p.takenSlots()
    local slots = 0;
    for slot, item in pairs(p.list()) do slots = slots + 1; end
    return slots;
  end

  function p.sort()

  end

  return p;
end

function i.find(addr)
  local peripherals = {peripheral.find(addr)};
  local wrapped = {};
  for k,v in pairs(peripherals) do wrapped[k] = i.wrap(v); end
  return wrapped;
end

function i.calcPutSlot(toInv, putItem, amount, start, onSlotPut)
  start = start or 1;
  if (toInv == nil or putItem == nil or amount == nil or start == nil or onSlotPut == nil) then return false; end
  if (putItem.count > amount) then putItem.count = amount; end
  local toPeriph = getPeripheral(toInv);
  local items = toPeriph.list();
  local itemData = iu.load(putItem.name);
  local count = putItem.count;
  for i = start, toPeriph.size() do
    local item = items[i];
    if (item == nil) then 
      onSlotPut(i, count);
      count = 0;
    else 
      if (item.name == putItem.name and item.nbt == putItem.nbt and item.count ~= itemData.maxCount) then
        local put = 0;
        if (item.count + count > itemData.maxCount) then 
          put = itemData.maxCount - item.count;
        else put = count; end
        count = count - put;
        onSlotPut(i, put);
      end
    end
    if (count == 0) then break end
  end
end

return i;