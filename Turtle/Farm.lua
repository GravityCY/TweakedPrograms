local tUtils = require("TurtleUtils");

local crops = {};

local sizeX = 9;
local sizeZ = 9;

local isForward = true;

local sleepTime = 60;

local function doRepeat(fn, times)
  for i = 1, times do fn(); end
end

local function loadCrops()
  local file = fs.open("crops.txt", "r");
  while true do
    local line = file.readLine();
    if (not line) then break end
    local idName, sName, age = line:match("(.+) (.+) (.+)");
    crops[idName] = {seed=sName, harvest=tonumber(age)};
  end
  file.close();
end

local function forward()
  turtle.forward();
  local found, block = turtle.inspectDown();
  if (found) then
      local crop = crops[block.name];
      if (crop and crop.harvest == block.state.age) then
          turtle.digDown();
          turtle.select(tUtils.getSlot(crop.seed));
          turtle.placeDown();
          turtle.select(1);
          return 1;
      end
  end
  return 0;
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
  local zIsEven = sizeZ % 2 == 0;
  if (zIsEven) then turtle.turnRight();
  else
    doRepeat(turtle.back, sizeX - 1);
    turtle.turnLeft();
  end
  doRepeat(turtle.forward, sizeZ - 1);
  turtle.turnRight();
  turtle.back();
end

local function main()
  while true do
    term.clear();
    term.setCursorPos(1, 1);
    local sTime = os.clock();
    local harvested = forward();
    for zNow = 1, sizeZ do
      for xNow = 1, sizeX - 1 do
        harvested = harvested + forward();
      end
      if (zNow ~= sizeZ) then corner(); end
    end
    goHome();
    local eTime = os.clock();
    local timeTook = eTime - sTime;
    print("Took " .. timeTook .. " seconds.")
    print("Got " .. harvested .. " crops.")
    print("That's " .. string.format("%.2f", harvested / timeTook) .. " crops a second.")
    print("Sleeping for " .. sleepTime .. " seconds");
    sleep(sleepTime);
  end
end

loadCrops();
main();

