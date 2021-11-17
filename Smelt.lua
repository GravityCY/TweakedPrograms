local furnaceName = "minecraft:furnace";
local blastName = "minecraft:blast_furnace";

local inputName = "minecraft:barrel";
local fuelName = "minecraft:barrel";
local arg = ...;

local input = peripheral.find(inputName);
local inputAddress = peripheral.getName(input);
local smelteries = nil;
local totalSmelteries = nil;
local smelterName = nil;

local items = input.list();

local speaker = peripheral.find("speaker");

local function setup()
  local opt = nil;
  if (arg) then opt = arg; 
  else 
    write("Enter Blast/Furnace: ");
    opt = read();
  end
  opt:lower();
  if (opt == "furnace") then smelterName = furnaceName;
  elseif (opt == "blast") then smelterName = blastName; end
  smelteries = {peripheral.find(smelterName)};
  totalSmelteries = #smelteries;
end

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
  extract();
  local eTime = os.clock();
  print("Took " .. eTime - sTime .. " seconds...");
  if (speaker) then 
    for i = 1, 3 do
      speaker.playNote("bell"); 
      sleep(1);
    end
  end
end

setup();
smelt();