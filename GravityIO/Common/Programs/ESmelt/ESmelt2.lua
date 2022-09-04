local iu = require("InvUtils");
local pu = require("PerUtils");

-- IDS of different Smelteries
local furnaceName = "minecraft:furnace";

-- ID of the Input Inventory
local inputName = "minecraft:barrel";
-- ID of the Fuel Item
local fuelName = "minecraft:charcoal";
local fuelRatio = 8;

local input = iu.wrap(pu.blacklistSides(pu.get(inputName, true))[1]);
local inputAddress = peripheral.getName(input);
local smelteryName = furnaceName;
local smelteries = pu.blacklistSides(pu.get(smelteryName, true));
local totalSmelteries = #smelteries;

local items = input.list();

local function getUniqueCount()
  local uniques = {}
  for slot, item in pairs(items) do
    if (not uniques[item.name]) then uniques[item.name] = item.count;
    else uniques[item.name] = uniques[item.name] + item.count end
  end
  return uniques;
end

local function extract()
  while true do
    local hasItem = false;
    for _, smeltery in pairs(smelteries) do
      local smeltingItem = smeltery.getItemDetail(1);
      smeltery.pushItems(inputAddress, 3, 64);
      if (smeltingItem) then hasItem = true; end
    end
    if (not hasItem) then break end
    sleep(1);
  end
end

local function smelt()
  local sTime = os.clock();
  local uniques = getUniqueCount();
  local fuelCount = uniques[fuelName];
  for itemName, amount in pairs(uniques) do
    if (itemName ~= fuelName) then
      write("Smelting " .. itemName .. " this may take a minute...");
      for i = 1, math.floor(amount / fuelRatio) do
        local index = totalSmelteries;
        if (i % totalSmelteries ~= 0) then index = i % totalSmelteries; end
        local smeltery = smelteries[index];
        if (amount >= fuelRatio and fuelCount >= 1) then
          input.push(smeltery, fuelName, 1, 2);
          input.push(smeltery, itemName, fuelRatio, 1);
          fuelCount = fuelCount - 1;
          amount = amount - fuelRatio;
        else break end
      end
      extract();
      write("Finished Smelting " .. itemName .. ".");
    end
  end
  local eTime = os.clock();
  write("Took " .. eTime - sTime .. " seconds...");
  if (speaker) then 
    for i = 1, 3 do
      speaker.playNote("bell"); 
      sleep(1);
    end
  end
end

smelt();