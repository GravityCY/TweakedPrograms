local inInv = peripheral.find("minecraft:chest");
local inInvAddr = peripheral.getName(inInv);

local function find(tab)
  local oTab = {};
  for _, periph in ipairs(peripheral.getNames()) do
    for _, iPeriph in ipairs(tab) do
      if (periph:match("(.+)_%d+") == iPeriph) then
        table.insert(oTab, peripheral.wrap(periph));
      end
    end
  end
  return oTab;
end

local sInvs = find({"metalbarrels:gold_tile", "minecraft:barrel"});

for slot, item in pairs(inInv.list()) do
  for _, sInv in ipairs(sInvs) do
    for sSlot, sItem in pairs(sInv.list()) do
      if (sItem.name == item.name) then
        sInv.pullItems(inInvAddr, slot, 64);
      end
    end
  end
end