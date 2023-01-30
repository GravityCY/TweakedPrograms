local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local sizeX = 9;
local sizeZ = 9;

local isForward = true;
local sleepTime = 600;

local crops = {};
crops["minecraft:wheat"] = { harvest = 7, seed = "minecraft:wheat_seeds" };
crops["minecraft:carrots"] = { harvest = 7, seed = "minecraft:carrot" };
crops["minecraft:potatoes"] = { harvest = 7, seed = "minecraft:potato" };
crops["minecraft:beetroots"] = { harvest = 3, seed = "minecraft:beetroot" };
crops["minecraft:pumpkin"] = { };
crops["minecraft:melon"] = { };

local harvested = nil;

local function doRepeat(fn, times)
  for i = 1, times do fn(); end
end

local function forward()
  turtle.forward();
  local exist, block = turtle.inspectDown();
  if (exist) then
    local crop = crops[block.name];
    if (crop ~= nil) then
      if (crop.harvest ~= nil) then
        if (crop.harvest == block.state.age) then
          turtle.select(1);
          turtle.digDown();
          local ss = tUtils.getSlot(crop.seed);
          if (ss) then
            turtle.select(ss);
            turtle.placeDown();
          end
          turtle.select(1);
        end
      else
        turtle.select(1);
        turtle.digDown();
      end
      harvested = harvested + 1;
    end
  end
end

local function turn(right)
  if (right) then turtle.turnRight();
  else turtle.turnLeft(); end
end

local function corner()
  turn(isForward);
  forward();
  turn(isForward);
  isForward = not isForward;
end

local function goHome()
  if (isForward) then 
    tUtils.turn(sides.back);
    doRepeat(turtle.forward, sizeX - 1);
  end
  turtle.turnRight();
  doRepeat(turtle.forward, sizeZ - 1);
  turtle.turnRight();
  turtle.back();
  tUtils.dropAll(sides.down);
end

local function main()
  while true do
    harvested = 0;
    term.clear();
    term.setCursorPos(1, 1);
    local sTime = os.clock();
    
    forward();
    for zNow = 1, sizeZ do
      doRepeat(forward, sizeX - 1);
      if (zNow ~= sizeZ) then corner(); end
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

main();

