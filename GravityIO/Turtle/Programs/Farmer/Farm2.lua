local bt = require("BetterTurtle");
local tu = require("TermUtils");
local sides = bt.sides;

local sizeX = 9;
local sizeZ = 9;

local isForward = true;
local goRight = true;
local sleepTime = 600;

local crops = {};
crops["minecraft:wheat"] = { harvest = 7, seed = "minecraft:wheat_seeds" };
crops["minecraft:carrots"] = { harvest = 7, seed = "minecraft:carrot" };
crops["minecraft:potatoes"] = { harvest = 7, seed = "minecraft:potato" };
crops["minecraft:beetroots"] = { harvest = 3, seed = "minecraft:beetroot" };
crops["minecraft:pumpkin"] = { };
crops["minecraft:melon"] = { };

local toCrop = {};
toCrop["minecraft:wheat_seeds"] = "minecraft:wheat";
toCrop["minecraft:carrot"] = "minecraft:carrots";
toCrop["minecraft:potato"] = "minecraft:potatoes";
toCrop["minecraft:beetroot"] = "minecraft:beetroots";

local home = bt.getPos();

local function getCrop(seed)
  return crops[toCrop[seed]];
end

local function load()
  local file = fs.open("/data/crops.txt", "r");
  if (file == nil) then return end
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

local function harvest()
  local exist, block = bt.inspect(sides.down);
  if (exist) then
    local crop = crops[block.name];
    if (crop ~= nil and crop.harvest == block.state.age) then
      turtle.select(1);
      bt.dig(sides.down);
      if (crop.seed ~= nil) then
        bt.placeID(sides.down, crop.seed);
      end
      turtle.select(1);
    end
  end
end

local function plant(id, doReplace)
  local exists, block = bt.inspect(sides.down);
  local cropName = toCrop[id];
  local crop = getCrop(id);
  if (doReplace and exists and cropName ~= block.name) then
    turtle.select(1);
    bt.dig(sides.down);
  end
  if (exists and cropName == block.name and crop.harvest == block.state.age) then bt.dig(sides.down); end
  bt.placeID(sides.down, id);
  turtle.select(1);
end

local action = nil;

local function turn(right)
  if (not goRight) then right = not right; end
  if (right) then bt.turn(sides.right);
  else bt.turn(sides.left) end
end

local function corner()
  turn(isForward);
  bt.go(sides.forward);
  action();
  turn(isForward);
  isForward = not isForward;
end

local function goHome()
  bt.goPos(home);
  bt.face(bt.directions.px);
  bt.dropAll(sides.down);
  isForward = true;
end

local function setup()
  load();
end

local function crawl()
  bt.go(sides.forward);
  action();
  for z = 1, sizeZ do
    for x = 1, sizeX - 1 do
      bt.go(sides.forward);
      action();
      bt.goPos(home);
      bt.dropAll(sides.down);
    end
    if (z ~= sizeZ) then corner(); end
  end
end

local function farmMode()
  action = harvest;
  while true do
    crawl();
    goHome();
    sleep(sleepTime);
  end
end

local function plantMode(id, doReplace)
  action = function() plant(id, doReplace) end;
  crawl();
  goHome();
end

local function printHelp()
  print("plant - Sets the turtle to plant mode.");
  print("farm - Sets the turtle to farming mode.");
  print("direction - Sets the turtles direction for actions.");
  print("size - Sets the size of the farmland.");
  print("sleep - Sets the sleep time of the turtle.");
end

local function main()
  printHelp();
  while true do
    write("Enter Command: ");
    local input = read():lower();
    if (input == "plant") then
      write("Enter slot of item to plant: ");
      local slot = tonumber(read());
      local item = turtle.getItemDetail(slot);
      write("Should it Replace other Crops (y/n): ");
      local doReplace = read():lower();
      if (doReplace == "y") then doReplace = true;
      elseif (doReplace == "n") then doReplace = false; end
      plantMode(item.name, doReplace);
    elseif (input == "farm") then
      farmMode();
    elseif (input == "direction") then
      local selectionsf = { "Left", "Right" };
      local selections = { false, true };
      sleep(0.2);
      local selection = tu.select({selections=selectionsf});
      if (selection ~= 0) then goRight = selections[selection]; end
    elseif (input == "size") then
      write("Enter Width: ");
      local width = read();
      write("Enter Length: ");
      local length = read();
      width = tonumber(width);
      length = tonumber(length);
      if (width == nil) then width = 9; end
      if (length == nil) then length = 9; end
      sizeZ = width;
      sizeX = length;
    elseif (input == "sleep") then
      write("Enter sleep time: ");
      local time = read();
      time = tonumber(time);
      if (time == nil) then time = 240; end
      sleepTime = time;
    else printHelp(); end
  end
end

setup();
main();