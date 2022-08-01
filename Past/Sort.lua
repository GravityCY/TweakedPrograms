local pUtils = require("PeripheralUtils");
local itemUtils = require("ItemUtils");
local buffer = peripheral.find("minecraft:chest");
local inventories = pUtils.getAllInventories({["minecraft:chest"]=true});

local function move(inv, fromSlot, toSlot)
  local addr = peripheral.getName(inv);
  buffer.pullItems(addr, toSlot, 64, 1);
  inv.pushItems(addr, fromSlot, 64, toSlot);
  buffer.pushItems(addr, 1, 64);
end

local function sort(inventory)
  local items = inventory.list();
  local size = inventory.size();
  for i = 1, size do
    local lowestName = nil;
    local lowestSlot = nil;
    for x = i, size do
      local item = items[x];
      if (item) then
        local name = itemUtils.getDisplayName(inventory, x, item.name);
        if (not lowestName) then lowestName = name; lowestSlot = x; end
        if (name < lowestName) then 
          lowestName = name; 
          lowestSlot = x; 
        end
      end
    end
    if (lowestName and lowestSlot ~= i) then 
      move(inventory, lowestSlot, i);
      local prev = items[i];
      items[i] = items[lowestSlot];
      items[lowestSlot] = prev;
    end
  end
end

for _, inventory in pairs(inventories) do
  sort(inventory);
end

-- local inventory = inventories[1];
-- local items = inventory.list();

-- local lowestName = nil;
-- local lowestSlot = nil;
-- for x = 13, 27 do
--   local item = items[x];
--   if (item) then
--     local name = itemUtils.getDisplayName(inventory, x, item.name);
--     if (not lowestName) then lowestName = name; lowestSlot = x; end
--     if (name < lowestName) then 
--       lowestName = name; 
--       lowestSlot = x; 
--     end
--   end
-- end
