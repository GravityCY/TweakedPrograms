--[[
  An API to conglomerate multiple chests into one huge network. Behaving somewhat as one
--]]

local iu = require("InvUtils");
local tu = require("TableUtils");

local sn = {};
sn.capacity = 0;

-- Key map from address to index
local addrsLookup = {};
local inventoryList = {};

local function Inventory(address)
  local i = {};
  i.address = address;
  i.periph = iu.wrap(peripheral.wrap(address));
  i.size = i.periph.size();
  i.start = sn.capacity + 1;
  i.fin = sn.capacity + i.size;
  return i;
end

local function toLocalSlot(globalSlot)
  for i, inv in ipairs(inventoryList) do
    if (globalSlot >= inv.start and globalSlot <= inv.fin) then
      return globalSlot - inv.start + 1, inv;
    end
  end
end

local function toGlobalSlot(localSlot, inv)
  return inv.start + localSlot - 1;
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

local function get(addr)
  return inventoryList[addrsLookup[addr]];
end

-- Given a path will save all of it's data
function sn.save(path)
  local file = fs.open(path.."data", "w");
  for _, inv in ipairs(inventoryList) do
    file.write(inv.addr .. "\n");
  end
  file.close();
end

-- Given a path will load all data to memory
function sn.load(path)
  local file = fs.open(path.."data", "r");
  if (file == nil) then return end
  while true do
    local line = file.readLine();
    if (line == nil) then break end
    sn.add(line);
  end
  file.close();
end


local function isValidInv(addr)
  local p = peripheral.wrap(addr);
  return p ~= nil and p.list ~= nil;
end

-- Adds an inventory to the network
function sn.add(inventoryAddr)
  if (not isValidInv(inventoryAddr)) then return false end
  local inventory = Inventory(inventoryAddr);
  table.insert(inventoryList, inventory);
  addrsLookup[inventoryAddr] = #inventoryList;
  sn.capacity = sn.capacity + inventory.size;
  return true;
end

function sn.addAll(inventoryAddrList)
  for _, addr in ipairs(inventoryAddrList) do sn.add(addr); end
end

function sn.remove(addr)
  local inventory = get(addr);
  if (inventory == nil) then return end
  sn.capacity = sn.capacity - inventory.size;
  local index = addrsLookup[addr];
  table.remove(inventoryList, index);
  addrsLookup[addr] = nil;
end

function sn.pushItems(toAddr, fromSlot, count, toSlot)
  local slotLocal, inventory = toLocalSlot(fromSlot);
  return inventory.periph.pushItems(toAddr, slotLocal, count, toSlot);
end

function sn.pullItems(fromAddr, fromSlot, count, toSlot)
  if (toSlot ~= nil) then
    local slotLocal, inventory = toLocalSlot(toSlot);
    return inventory.periph.pullItems(fromAddr, fromSlot, count, slotLocal);
  else
    local pulled = 0;
    for _, inv in ipairs(inventoryList) do
      local pull = inv.periph.pullItems(fromAddr, fromSlot, count - pulled);
      pulled = pulled + pull;
      if (pull == count) then break end
    end
    return pulled;
  end
end

function sn.push(aTo, itemName, amount, toSlot)
  local toAddr = getAddress(aTo);
  local tPush = 0;

  for index, inventoryObj in ipairs(inventoryList) do
    local inventory = inventoryObj.periph;
    for fromSlot, item in pairs(inventory.list()) do
      if (item.name == itemName) then
        local push = inventory.pushItems(toAddr, fromSlot, amount - tPush, toSlot);
        tPush = tPush + push;
        if (tPush == amount) then break end
      end
      if (tPush == amount) then break end
    end
  end

  return tPush;
end

function sn.pull(aFrom, itemName, count, toSlot)
  local fromInventory = getPeripheral(aFrom);
  local fromAddr = getAddress(aFrom);

  local tPull = 0;
  for fromSlot, item in pairs(fromInventory.list()) do
    if (item.name == itemName) then
      for index = #inventoryList, 1, -1 do
        local toInventory = inventoryList[index];
        local pull = toInventory.periph.pullItems(fromAddr, fromSlot, count - tPull, toSlot);
        tPull = tPull + pull;
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
        local pull = toInventory.periph.pullItems(fromAddr, slot, 64);
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

function sn.pushAll(aTo, itemName) 
  local toAddr = getAddress(aTo);
  local tPush = 0;

  for index, inventory in ipairs(inventoryList) do
    for slot, item in pairs(inventory.periph.list()) do
      if (itemName == nil or itemName == item.name) then
        local push = inventory.pushItems(toAddr, slot, 64);
        tPush = tPush + push;
      end
    end
  end

  return tPush;
end

function sn.getItemDetail(slot)
  local slotLocal, inventory = toLocalSlot(slot);
  return inventory.periph.getItemDetail(slotLocal);
end

function sn.swap(slot1, slot2, items)
  local aSlotLocal, aInventory = toLocalSlot(slot1);
  local bSlotLocal, bInventory = toLocalSlot(slot2);

  if (items[slot1] == nil) then
    bInventory.periph.pushItems(aInventory.address, bSlotLocal, 64, aSlotLocal);
  elseif (items[slot2] == nil) then
    aInventory.periph.pushItems(bInventory.address, aSlotLocal, 64, bSlotLocal);
  end
  if (items[slot1] == nil or items[slot2] == nil) then tu.swap(items, slot1, slot2); end
end

function sn.list()
  local items = {};
  for _, inv in ipairs(inventoryList) do
    for slot, item in pairs(inv.periph.list()) do
      items[inv.start + slot - 1] = item;
    end
  end
  return items;
end

function sn.size()
  return sn.capacity;
end

function sn.getInventories()
  return inventoryList;
end

return sn;