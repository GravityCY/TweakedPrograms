local pUtils = require("PeripheralUtils");

local buffer = peripheral.find("minecraft:chest");
local blacklist = { ["minecraft:chest"]=true };
local inventories = pUtils.getAllInventories(blacklist);

-- local items = { iron={ inside={ 0={5,7}, 1={6,8} } } };
local items = {};

local function prep(tab, key, value)
  if (not tab[key]) then tab[key] = value end
  return tab[key];
end

local function map()
  for _, inventory in ipairs(inventories) do
    local addr = peripheral.getName(inventory);
    for slot, item in pairs(inventory.list()) do
      local tItem = prep(items, item.name, { inside = {} });
      local inv = prep(tItem.inside, addr, {});
      table.insert(inv, slot);
    end
  end
end

map();



for id, item in pairs(items) do
  for addr, slots in pairs(item.inside) do
    for _, slot in ipairs(slots) do
      write(id, addr, slot);
    end
  end
end