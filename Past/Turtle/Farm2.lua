local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local sizeX = 9;
local sizeZ = 4;

local isForward = true;
local sleepTime = 240;

local crops = {};

local harvested = nil;

local function load()
  local file = fs.open("/data/crops.txt", "r");
  while true do
    local line = file.readLine();
    if (not line) then break end
    local cropID, harvest, seed = line:match("(%S+) (%S+) (%S+)")
    local t = {};
    t.harvest = tonumber(harvest);
    t.seed = seed;
    crops[cropID] = t;
  end
  file.close();
end

local function doRepeat(fn, times)
  for i = 1, times do fn(); end
end

local function forward()
  turtle.forward();
  local exist, block = turtle.inspectDown();
  if (exist) then
    local crop = crops[block.name];
    if (crop and crop.harvest == block.state.age) then
      turtle.select(1);
      turtle.digDown();
      local ss = tUtils.getSlot(crop.seed);
      if (ss) then
        turtle.select(ss);
        turtle.placeDown();
      end
      turtle.select(1);
      harvested = harvested + 1;
    end
  end
end

local function turn(left)
  if (left) then turtle.turnLeft();
  else turtle.turnRight(); end
end

local function corner()
  turn(isForward);
  doRepeat(forward, 2);
  turn(isForward);
  isForward = not isForward;
end

local function goHome()
  if (isForward) then 
    tUtils.turn(sides.back);
    doRepeat(turtle.forward, sizeX - 1);
  end
  turtle.turnLeft();
  doRepeat(turtle.forward, sizeZ * 2 - 2);
  turtle.turnRight();
  turtle.forward();
  turtle.turnLeft();
  turtle.forward();
  tUtils.turn(sides.back);
  tUtils.dropAll(sides.down);
  isForward = true;
end

local function main()
  while true do
    harvested = 0;
    term.clear();
    term.setCursorPos(1, 1);
    local sTime = os.clock();
    
    forward();
    turtle.turnRight();
    forward();
    for zNow = 1, sizeZ do
      doRepeat(forward, sizeX - 1);
      if (zNow ~= sizeZ) then 
        corner();
      end
    end
    goHome();

    local eTime = os.clock();
    local timeTook = eTime - sTime;
    write("Took " .. timeTook .. " seconds.")
    write("Got " .. harvested .. " crops.")
    write("That's " .. string.format("%.2f", harvested / timeTook) .. " crops a second.")
    write("Sleeping for " .. sleepTime .. " seconds");
    sleep(sleepTime);
  end
end

load();
main();

