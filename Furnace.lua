local invName = "minecraft:barrel";
local smeltName = "minecraft:furnace";

local fuelName = "minecraft:barrel";

local input = peripheral.find(invName);
local inputAddress = peripheral.getName(input);
local smelteries = {peripheral.find(smeltName)};

local speaker = peripheral.find("speaker");

local totalSmelteries = #smelteries;

local items = input.list();

local function itemTotal(name)
  local count = 0;
  for slot, item in pairs(items) do
    if (item.name == name) then count = count + 1; end
  end
  return count;
end

local function getUniqueCount()
  local uniques = {}
  for slot, item in pairs(items) do
    if (not uniques[item.name]) then uniques[item.name] = item.count;
    else uniques[item.name] = uniques[item.name] + item.count end
  end
  return uniques;
end

local function getSlot(name)
  for slot, item in pairs(input.list()) do
    if (item.name == name) then return slot end
  end
end

local sTime = os.clock();

for itemName, amount in pairs(getUniqueCount()) do
  local per = math.ceil(amount / totalSmelteries);
  for _, smeltery in ipairs(smelteries) do
    local tPull = 0;
    while true do
      local slot = getSlot(itemName);
      if (not slot) then break end
      local pulled = 0;
      if (itemName == fuelName) then
        pulled = smeltery.pullItems(inputAddress, slot, per - tPull, 2)
      else
        pulled = smeltery.pullItems(inputAddress, slot, per - tPull, 1);
      end
      tPull = tPull + pulled;
      if (pulled == 0 or tPull >= per) then break end
    end
  end
end

local smelteryCheck = smelteries[1];

while true do
  local smeltedItem = smelteryCheck.getItemDetail(3);
  local hasItem = false;
  for _, smeltery in pairs(smelteries) do
    local smeltingItem = smeltery.getItemDetail(1);
    smeltery.pushItems(inputAddress, 3, 64);
    if (smeltingItem) then hasItem = true; end
  end
  if (not hasItem) then break end
  sleep(1);
end

local eTime = os.clock();

print("Took " .. eTime - sTime .. " seconds...");

if (speaker) then 
  for i = 1, 3 do
    speaker.playNote("bell"); 
    sleep(1);
  end
end