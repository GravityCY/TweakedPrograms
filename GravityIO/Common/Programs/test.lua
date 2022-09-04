local ItemUtils = require("ItemUtils");

local barrel = peripheral.find("minecraft:barrel");
local addr = peripheral.getName(barrel);

local slot = 1;

local item = barrel.list()[slot];

if (not ItemUtils.exists(item.name)) then
  ItemUtils.add(barrel.getItemDetail(slot));
  print("Didn't exist adding to cache");
end
ItemUtils.wrap(item);
print(item.maxCount);
print(item.maxDamage);
print(item.format);
print(item.namespace);
print(item.type);
print("Tags: ");
for k,v in pairs(item.tags) do
  print(k);
end