local tu = require("TurtleUtils");
local sides = tu.sides;

local function requestInput(req)
  write(req);
  return read();
end

local fuelName = requestInput("Enter Fuel Name: ");
local fuelValue = tonumber(requestInput("Enter Fuel Value: "));
local fuelAmount = tu.count(fuelName);

local writeFuel = "/WriteFuel.lua";
local useFuel = "/UseFuel.lua";
tu.placeID(sides.up, "computercraft:disk_drive");
tu.selectID("computercraft:disk")
tu.drop(nil, 1, sides.up);
repeat sleep(0); until peripheral.find("drive") ~= nil
local drive = peripheral.find("drive");
local mpath = drive.getMountPath();
local fpath = mpath .. "/levels.txt";


local function getFuelLevels()
  fs.copy(writeFuel, mpath .. "/startup.lua");
  turtle.back();

  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item ~= nil and item.name:find("computercraft:turtle")) then 
      turtle.select(i);
      turtle.place();
      repeat sleep(0) until peripheral.wrap("front") ~= nil
      peripheral.wrap("front").turnOn();
      sleep(0.5);
      turtle.dig();
    end
  end

  turtle.forward();

  local ff = fs.open(fpath, "r");

  local data = {};
  local levels = {};
  local highest = 0;
  local index = 1;
  while true do
    local line = ff.readLine();
    if (line == nil) then break end
    local fuel = tonumber(line);
    levels[index] = fuel;
    if (fuel > highest) then highest = fuel; end
    index = index + 1;
  end
  data.levels = levels;
  data.highest = highest;
  return data;
end

local function getCalculateFuel(fuelLevels)
  local highest = fuelLevels.highest;
  local tempFuelAmount = fuelAmount;
  local fuelNeed = {};
  local doesNeed = {};
  while true do
    if (tempFuelAmount == 0) then break end
    local allEqual = true;
    for i = 1, 16 do
      if (doesNeed[i]) then allEqual = false end
    end
    if (allEqual) then break end
    for i = 1, 16 do
      local fuel = fuelLevels.levels[i];
      if (doesNeed[i]) then break end
      if (fuel - fuelValue < highest) then
        fuelLevels.levels[i] = fuel + fuelValue;
        fuelNeed[i] = (fuelNeed[i] or 0) + 1;
        tempFuelAmount = tempFuelAmount - 1;
      else doesNeed[i] = false; end
    end
  end
  return fuelNeed;
end

local function main()
  tu.placeID(sides.up, "computercraft:disk_drive");
  tu.selectID("computercraft:disk")
  tu.drop(nil, 1, sides.up);
  local fuelLevels = getFuelLevels();
  write(fuelLevels.highest);
  fs.delete(mpath .. "/startup.lua");
  -- fs.copy(useFuel, mpath .. "/startup.lua");
  -- local needs = getCalculateFuel(fuelLevels);
  -- for index, need in pairs(needs) do
  --   print(need);
  -- end
  -- for i = 1, 16 do
  --   local item = turtle.getItemDetail(i);
  --   if (item ~= nil and item.name:find("computercraft:turtle")) then
  --     local fuel = fuelLevels.levels[i];
  --     turtle.select(i);
  --     turtle.place();
  --     tu.selectID(fuelName);
  --     tu.drop
  --     sleep(0.5);
  --     turtle.dig();
  --   end
  -- end

  -- fs.delete(mpath .. "/startup.lua");

  fs.delete(fpath);
end

main();