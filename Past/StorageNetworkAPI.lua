--[[
  An API to conglomerate multiple chests into one huge network. Behaving somewhat as one
--]]

local iu = require("InvUtils");
local tu = require("TableUtils");
iu.getSlot = false;
iu.getItem = true;

local sn = {};
sn.capacity = 0;

local inventoryAddrs = {};
local inventoryList = {};
local inventorySizes = {};
local inventorySlot = {};

local bufferAddr = nil;

local Item = {};

function Item.new(name, count)
  return {name=name, count=count};
end

local function toLocalSlot(globalSlot)
  local total = 0;
  for i = 1, #inventorySizes do
    local size = inventorySizes[i];
    total = total + size;
    if (globalSlot <= total) then 
      if (i == 1) then return globalSlot, i
      else return globalSlot - (total - size), i; end
    end
  end
end

local function toGlobalSlot(localSlot, index)
  return inventorySlot[index] + localSlot;
end

local function setInventory(inventoryAddr, index)
  local inventory = peripheral.wrap(inventoryAddr);
  if (inventory == nil) then return false end
  inventoryList[index] = iu.wrap(inventory);
  inventorySlot[index] = sn.capacity;
  inventorySizes[index] = inventory.size();
  inventoryAddrs[index] = inventoryAddr;
  return true;
end

local function getAvailableSlot(items)
  for i = sn.capacity, 1, -1 do
    if (items[i] == nil) then return i; end
  end
end

local function moveToAvailable(slot, items)
  local slotLocal, inventoryIndexLocal = toLocalSlot(slot);
  local inventory = inventoryList[inventoryIndexLocal];
  local slotAvail, inventoryAvailIndex = toLocalSlot(getAvailableSlot(items));

  if (slotAvail == nil) then
    inventory.pushItems(bufferAddr, slotLocal, 64, 1);
    return bufferAddr, 1;
  else
    inventory.pushItems(inventoryAddrs[inventoryAvailIndex], slotLocal, 64, slotAvail);
    return inventoryAddrs[inventoryIndex], avail;
  end
end

local function getPeripheral(obj)
  local t = type(obj);
  if (t == "string") then return peripheral.wrap(obj);
  elseif (t == "table") then return obj; end
end

local function getAddress(obj)
  local t = type(obj);
  if (t == "string") then return obj;
  elseif (t == "table") then return peripheral.getName(obj) end
end

local function getIndex(addr)
  for index, inventoryAddr in ipairs(inventoryAddrs) do
    if (inventoryAddr == addr) then return index; end
  end
end

-- {
--   ["minecraft:oak_planks"]: { found = 5, slots = { {count=1, slot=1}, {count=2, slot=2}, {count=2, slot=3} }}
--   ["minecraft:chest"]: { found = 7, slots = {1, 2, 3} }
-- }

function sn.getWhere(items)
  local result = {};
  for name, count in pairs(items) do
    local need = count;
    for index, inventory in ipairs(inventoryList) do
      for slot, item in pairs(inventory.list()) do
        if (item.name == name) then
          local found = 0;
          if (item.count >= need) then
            found = need;
            need = 0;
          else
            need = need - item.count;
            found = item.count;
          end
          if (result[name] == nil) then 
            result[name] = {}; 
            result[name].slots = {};
            result[name].found = 0;
          end
          result[name].found = result[name].found + found;
          table.insert(result[name].slots, { count=found, slot=toGlobalSlot(slot, index) });
        end
        if (need == 0) then break end
      end
      if (need == 0) then break end
    end
  end
  return result;
end

-- Given a path will save all of it's data
function sn.save(path)
  local file = fs.open(path.."data", "w");
  file.write((bufferAddr or "") .. "\n\n");
  for _, addr in ipairs(inventoryAddrs) do
    file.write(addr .. "\n");
  end
  file.close();
end

-- Given a path will load all data to memory
function sn.load(path)
  local file = fs.open(path.."data", "r");
  if (file == nil) then return end
  local addr = file.readLine();
  if (addr == nil or addr == "") then return end
  sn.setBuffer(addr);
  file.readLine();
  while true do
    local line = file.readLine();
    if (line == nil) then break end
    sn.add(line);
  end
  file.close();
end

function sn.setBuffer(addr)
  bufferAddr = addr;
end

-- Adds an inventory to the network
function sn.add(inventoryAddr)
  local valid = setInventory(inventoryAddr, #inventoryList + 1);
  if (not valid) then return false end
  sn.capacity = sn.capacity + inventorySizes[#inventoryList]
  return true;
end

function sn.remove(addr)
  local index = getIndex(addr);
  if (index == nil) then return end
  sn.capacity = sn.capacity - inventorySizes[index];
  local from, to = inventorySlot[index], inventorySlot[index] + inventorySizes[index];
  table.remove(inventoryAddrs, index);
  table.remove(inventoryList, index);
  table.remove(inventorySlot, index);
  table.remove(inventorySizes, index);
end

function sn.pushSlot(toAddr, fromSlot, count, toSlot)
  local slotLocal, invLocalIndex = toLocalSlot(fromSlot);
  local invLocal = inventoryList[invLocalIndex];
  return invLocal.pushItems(toAddr, slotLocal, count, toSlot);
end

function sn.pullSlot(fromAddr, fromSlot, count, toSlot)
  local slotLocal, invLocalIndex = toLocalSlot(toSlot);
  local invLocal = inventoryList[invLocalIndex];
  return invLocal.pullItems(fromAddr, fromSlot, count, slotLocal);
end

function sn.pull(aFrom, itemName, count)
  local fromInventory = getPeripheral(aFrom);
  local fromAddr = getAddress(aFrom);

  local tPull = 0;
  for slot, item in pairs(fromInventory.list()) do
    if (item.name == itemName) then
      for index = #inventoryList, 1, -1 do
        local toInventory = inventoryList[index];
        local pull = toInventory.pullItems(fromAddr, slot, count - tPull);
        tPull = tPull + pull;
        -- for putSlot, nAmount in pairs(where) do
        --   local nItem = Item.new(item.name, nAmount);
        --   local slotGlobal = toGlobalSlot(putSlot, index)
        --   sn.items[slotGlobal] = nItem;
        -- end
        if (tPull == count) then break end
      end
    end
    if (tPull == count) then break end
  end
  return tPull;
end

function sn.pullAll(aFrom, itemName)
  local fromInventory = getPeripheral(aFrom);
  local fromAddr = getAddress(aFrom);
  local tPull = 0;
  for slot, item in pairs(fromInventory.list()) do
    if (itemName == nil or itemName == item.name) then
      local pulled = 0;
      for i = #inventoryList, 1, -1 do
        local toInventory = inventoryList[i];
        local pull = toInventory.pullItems(fromAddr, slot, 64);
        pulled = pulled + pull;
        tPull = tPull + pull;
        -- for putSlot, nAmount in pairs(where) do
        --   local nItem = Item.new(item.name, nAmount);
        --   sn.items[toGlobalSlot(putSlot, i)] = nItem;
        -- end
        if (pulled == item.count) then break end
      end
    end
  end
  return tPull;
end

function sn.push(aTo, itemName, amount)
  local toAddr = getAddress(aTo);
  local tPush = 0;

  for index, inventory in ipairs(inventoryList) do
    for slot, item in pairs(inventory.list()) do
      if (item.name == itemName) then
        -- local slotGlobal = toGlobalSlot(slot, index);
        local push = inventory.pushItems(toAddr, slot, amount - tPush);
        tPush = tPush + push;
        -- if (item.count == push) then sn.items[slotGlobal] = nil;
        -- else sn.items[slotGlobal].count = item.count - push; end
        if (tPush == amount) then break end
      end
      if (tPush == amount) then break end
    end
  end

  return tPush;
end

function sn.pushAll(aTo, itemName) 
  local toAddr = getAddress(aTo);
  local tPush = 0;

  for index, inventory in ipairs(inventoryList) do
    for slot, item in pairs(inventory.list()) do
      if (itemName == nil or itemName == item.name) then
        -- local slotGlobal = toGlobalSlot(slot, index);
        local push = inventory.pushItems(toAddr, slot, 64);
        tPush = tPush + push;
        -- if (item.count - push == 0) then sn.items[slotGlobal] = nil;
        -- else sn.items[slotGlobal].count = item.count - push; end
      end
    end
  end

  return tPush;
end

function sn.getItemDetail(slot)
  local slotLocal, inventoryIndex = toLocalSlot(slot);
  local inventory = inventoryList[inventoryIndex];
  return inventory.getItemDetail(slotLocal);
end

function sn.reorder(from, to)
  if (from > #inventoryAddrs or from <= 0 or to > #inventoryAddrs or to <= 0 or from == to) then return false end
  local fromAddr = inventoryAddrs[from];
  local toAddr = inventoryAddrs[to];
  setInventory(fromAddr, to);
  setInventory(toAddr, from);
  return true;
end

function sn.swap(slot1, slot2, items)
  local aSlotLocal, aInventoryIndex = toLocalSlot(slot1);
  local bSlotLocal, bInventoryIndex = toLocalSlot(slot2);
  local aInventoryAddr, bInventoryAddr = inventoryAddrs[aInventoryIndex], inventoryAddrs[bInventoryIndex]; 
  local aInventory, bInventory = inventoryList[aInventoryIndex], inventoryList[bInventoryIndex];

  if (items[slot1] == nil) then
    bInventory.pushItems(aInventoryAddr, bSlotLocal, 64, aSlotLocal);
  elseif(items[slot2] == nil) then
    aInventory.pushItems(bInventoryAddr, aSlotLocal, 64, bSlotLocal);
  else 
    local tempAddr, slot = moveToAvailable(slot1, items);
    bInventory.pushItems(aInventoryAddr, bSlotLocal, 64, aSlotLocal);
    bInventory.pullItems(tempAddr, slot, 64, bSlotLocal);
  end
  tu.swap(items, slot1, slot2);
end

function sn.compact(onIncrement)
  for index, inventory in ipairs(inventoryList) do
    local addr = inventoryAddrs[index];
    for slot, item in pairs(inventory.list()) do
      onIncrement(toGlobalSlot(slot, index));
      inventory.pushItems(addr, slot, 64);
    end
  end
end

function sn.sort(onIncrement)
  local items = sn.list();
  for i = 1, sn.capacity do
    local lowestName = nil;
    local lowestSlot = nil;
    onIncrement(i);
    for j = i, sn.capacity do
      local item = items[j];
      if (item ~= nil) then
        if (lowestName == nil) then 
          lowestName = item.name; 
          lowestSlot = j;
        end
        if (item.name < lowestName) then
          lowestName = item.name; 
          lowestSlot = j;
        end
      end
    end
    if (lowestName ~= nil and lowestSlot ~= i) then sn.swap(lowestSlot, i, items); end
  end
end

function sn.list()
  local items = {};
  local i = 1;
  for _, inventory in ipairs(inventoryList) do
    local itemsLocal = inventory.list();
    for slot = 1, inventory.size() do
      items[i] = itemsLocal[slot];
      i = i + 1;
    end
  end
  return items;
end

function sn.occupied()
  local occupied = 0;
  for _ in pairs(sn.list()) do occupied = occupied + 1; end
  return occupied;
end

function sn.toFile(path)
  local f = fs.open(path .. "log.txt", "w");
  f.write("Size: " .. sn.capacity .. "\n\n")
  f.write("Buffer Address: " .. (bufferAddr or "None") .. "\n\n");
  f.write("Inventory Addresses: \n");
  for _, addr in ipairs(inventoryAddrs) do f.write(addr .. "\n") end
  f.close();
end

function sn.size()
  return sn.capacity;
end

function sn.getInventories()
  return inventoryAddrs;
end

function sn.getBuffer()
  return bufferAddr;
end

return sn;