
local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local go = tUtils.go;
local goDig = tUtils.goDig;
local dig = tUtils.dig;
local getSlot = tUtils.getSlot;
local getSlotTab = tUtils.getSlotTab;

local xSize = 4;
local zSize = 4;

local trees = {};

local isForward = true;

local sleepTime = 20;

local function doRepeat(fn, times)
  for i = 1, times do fn(); end
end

local function load()
  local file = fs.open("trees.txt", "r");
  while true do
    local line = file.readLine();
    if (not line or #line == 0) then break end
    local log, sapling = line:match("(.+) (.+)");
    trees[log] = {sapling=sapling};
  end
  file.close();
end

local function chopTree()
  local _, block = turtle.inspect();
  local sapling = trees[block.name].sapling;
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
  local slot = getSlot(sapling);
  if (slot) then
    turtle.select(slot);
    turtle.placeDown();
    turtle.select(1);
  end
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
    write("Took " .. eTime - sTime .. " seconds.");
    write("Got " .. logsHarvested .. " logs.");
    sleep(sleepTime);
  end
end

load();
main();
