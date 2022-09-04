local pu = require("PerUtils");

local monitor = peripheral.find("monitor");

local converters = {peripheral.find("easy_villagers:converter")};
local converterAddrs = pu.toAddress(converters);
local inputAddr = "minecraft:barrel_7";
local resourceAddr = "storagedrawers:standard_drawers_2_0";
local outputAddr = "minecraft:barrel_6"
local input = peripheral.wrap(inputAddr);
local resources = peripheral.wrap(resourceAddr);

local available = {};
local converterCount = #converters;

local function getAvailable()
  for index, value in ipairs(available) do
    if (value) then return index; end
  end
end

local function getTotalAvailable()
  local total = 0;
  for _, value in ipairs(available) do
    if (value) then total = total + 1 end
  end
  return total;
end

local function getConverter(index)
  return converters[index];
end

local function getWorking()
  local t = {};
  for index, value in ipairs(available) do
    if (not value) then t[#t+1] = index end
  end
  return t;
end

local function setAvailable(index, value)
  available[index] = value;
end

local function hasMaterials()
  local resItems = resources.list();
  return resItems[2] ~= nil and resItems[3] ~= nil;
end

local function startConvert(slot)
  local conIndex = getAvailable();
  if (conIndex == nil) then return end
  local addr = converterAddrs[conIndex];
  if (not hasMaterials()) then return end;
  input.pushItems(addr, slot, 1, 1);
  resources.pushItems(addr, 2, 1, 2);
  resources.pushItems(addr, 3, 1, 3);
  setAvailable(conIndex, false);
end

local function convert(conIndex)
  local converter = getConverter(conIndex);
  converter.pushItems(outputAddr, 5, 1);
  converter.pushItems(resourceAddr, 3, 1);
  setAvailable(conIndex, true);
end

local function main()
  for index, _ in ipairs(converters) do available[index] = true; end
  while true do
    for slot, item in pairs(input.list()) do
      if (item.name == "easy_villagers:villager") then startConvert(slot); end
    end
    for _, conIndex in ipairs(getWorking()) do
      local converter = getConverter(conIndex);
      local conItems = converter.list();
      if (conItems[5] ~= nil) then convert(conIndex); end
    end
    sleep(1);
  end
end

local function render()
  term.redirect(monitor);
  while true do
    term.clear();
    term.setCursorPos(1, 1);
    print("Total Stations: " .. converterCount);
    print("Active Conversions: " .. converterCount - getTotalAvailable());
    sleep(5);
  end
end

parallel.waitForAll(main, render);