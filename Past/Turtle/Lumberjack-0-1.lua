
local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local go = tUtils.go;
local goDig = tUtils.goDig;
local dig = tUtils.dig;
local getSlot = tUtils.getSlot;
local getSlotTab = tUtils.getSlotTab;

local xSize = 4;
local zSize = 4;

local isForward = true;

local sleepTime = 60;

local function doRepeat(fn, times)
  for i = 1, times do fn(); end
end
local function chopTree()
  goDig(sides.forward)
  dig(sides.down);
  local logs = 0;
  while true do
    local found, block = turtle.inspectUp();
    if (not found) then break
    else
      if (block.name:find("log")) then
        turtle.digUp();
        turtle.up();
        logs = logs + 1;
      else break end
    end
  end
  for i = 1, logs do goDig(sides.down); end
  return logs;
end

local function goHome()
  local zIsEven = zSize % 2 == 0;
  if (zIsEven) then turtle.turnRight();
  else
    doRepeat(turtle.back, xSize - 1);
    turtle.turnLeft();
  end
  doRepeat(turtle.forward, zSize - 1);
  turtle.turnRight();
  turtle.back();
end

local function forward()
  local success = go(sides.forward);
  local harvested = 0;
  if (not success) then harvested = chopTree(); end
  local slot = getSlot("minecraft:oak_sapling");
  if (slot) then
    turtle.select(slot);
    turtle.placeDown();
    turtle.select(1);
  end
  turtle.suckDown();
  return harvested;
end

local function turn(right)
  if (right) then turtle.turnRight();
  else turtle.turnLeft(); end
end

local function corner()
  turn(isForward);
  local harvested = forward();
  turn(isForward);
  isForward = not isForward;
  return harvested;
end

local function main()
  while true do
    local logsHarvested = 0;
    local sTime = os.clock();
    isForward = true;
    forward();
    for zNow = 1, zSize do
      for xNow = 1, xSize - 1 do
        logsHarvested = logsHarvested + forward();
      end
      if (zNow ~= zSize) then logsHarvested = logsHarvested + corner(); end
    end
    goHome();
    local eTime = os.clock();
    print("Took " .. eTime - sTime .. " seconds.");
    print("Got " .. logsHarvested .. " logs.");
    sleep(sleepTime);
  end
end

main();
