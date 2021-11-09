local tUtils = require("TurtleUtils");
local getCount = tUtils.getCount;

local fuel = "minecraft:coal";

local sizeX = 4;
local sizeZ = 3;

local smeltTime = 10;

local totalFurnace = sizeX * sizeZ;
local totalFuel = getCount(fuel);
local fuelPerFurnace = totalFuel / totalFurnace;
local fuelSlots = 1;
local totalItems = getCount("minecraft:log");
local itemPerFurnace = math.ceil(totalItems / totalFurnace);
local itemSlots = 1;

local isForward = true;

local function doRepeat(fn, times)
  for i = 1, times do fn(); end
end

local function turn(right)
  if (right) then turtle.turnRight();
  else turtle.turnLeft(); end
end

local function loop(thenFn)
  for zNow = 1, sizeZ do
    for xNow = 1, sizeX - 1 do
      turtle.forward();
      thenFn();
    end
    if (zNow ~= sizeZ) then
        turn(isForward);
        turtle.forward();
        thenFn();
        turn(isForward);
        isForward = not isForward;
    end
  end
end

local function fuelLoop()
  turtle.select(fuelSlots);
  turtle.forward()
  -- turtle.dropUp(fuelPerFurnace)
  loop(function() --[[ turtle.dropUp(itemPerFurnace); --]] end);
end

local function itemLoop()
  turtle.select(itemSlots);
  turtle.forward();
  turtle.dropDown(itemPerFurnace);
  loop(function() turtle.dropDown(itemPerFurnace); end);
end

local function goHome()
  doRepeat(turtle.forward, 2);
  doRepeat(turtle.down, 2);
  doRepeat(turtle.turnLeft, 2);
  turtle.forward();
  isForward = true;
end

local function collectItems()
  print(string.format("Waiting for items to smelt (%ss)", itemPerFurnace * smeltTime));
  sleep(itemPerFurnace * smeltTime);
  turtle.forward();
  turtle.suckUp();
  loop(turtle.suckUp);
end

local function main()
  fuelLoop();
  turtle.forward();
  doRepeat(turtle.up, 2);
  doRepeat(turtle.turnRight, 2);
  itemLoop();
  goHome();
  collectItems();
end

main();
