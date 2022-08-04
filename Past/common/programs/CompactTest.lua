local pu = require("PeripheralUtils");
local inventories = pu.getAllInventories();

for i = 1, #inventories do
  local inventory = inventories[i];
  local addr = peripheral.getName(inventory);
  for i = 1, inventory.size() do
    inventory.pushItems(addr, i, 64);
  end
end