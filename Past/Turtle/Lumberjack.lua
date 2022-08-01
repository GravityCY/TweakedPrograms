local tu = require("TurtleUtils");
local bin = require("BinaryFile");
local sides = tu.sides;

local homeDist = nil;
local xTrees = nil;
local yTrees = nil;
local spacing = nil;
local isForward = true;

local sleepTime = 400;

local treeMap = {}
treeMap["minecraft:spruce_log"] = "minecraft:spruce_sapling";
treeMap["minecraft:oak_log"] = "minecraft:oak_sapling";
treeMap["minecraft:birch_log"] = "minecraft:birch_sapling";
treeMap["minecraft:dark_oak_log"] = "minecraft:dark_oak_sapling";
treeMap["minecraft:acacia"] = "minecraft:acacia_sapling";

local blacklist = {}
blacklist["minecraft:spruce_sapling"] = true;
blacklist["minecraft:oak_sapling"] = true;
blacklist["minecraft:birch_sapling"] = true;
blacklist["minecraft:dark_oak_sapling"] = true;
blacklist["minecraft:acacia_sapling"] = true;

local hasData = false;

local function tobool(str)
  if (str == "true") then return true elseif (str == "false") then return false end
end

local function requestInput(req, type)
  local fns = { ["number"]=tonumber, ["string"]=tostring, ["bool"]=tobool };
  local fn = fns[type];
  if (fn == nil) then return end
  write(req);
  return fn(read());
end

local function load()
  local rf = bin.wrap(fs.open("/data/lumberjack/size.bin", "rb"));
  if (rf == nil) then return end
  xTrees = rf.readByte();
  yTrees = rf.readByte();
  spacing = rf.readByte();
  homeDist = rf.readByte();
  rf.close();
  hasData = true;
end

local function save()
  local wf = bin.wrap(fs.open("/data/lumberjack/size.bin", "wb"));
  wf.writeByte(xTrees);
  wf.writeByte(yTrees);
  wf.writeByte(spacing);
  wf.writeByte(homeDist);
  wf.close();
end

local function setup()
  xTrees = requestInput("Enter Forward Trees: ", "number");
  yTrees = requestInput("Enter Right Trees: " , "number");
  spacing = requestInput("Enter Spacing between Trees (Excluding Sapling Block): ", "number");
  homeDist = requestInput("Enter Distance from Turtle's home to First Tree: ", "number");
  save();
end

local function doRep(fn, times, ...)
  for i = 1, times do fn(...) end
end

local function turn(right)
  if (right) then turtle.turnRight();
  else turtle.turnLeft(); end
end

local function timber()
  local sapling = nil;
  tu.goDig(sides.forward);
  local found, block = tu.inspect(sides.down);
  if (found) then sapling = treeMap[block.name]; end
  tu.dig(sides.down);
  local logs = 0;
  while true do
    local found, block = turtle.inspectUp();
    if (not found or not block.name:find("log")) then break end
    tu.goDig(sides.up);
    logs = logs + 1;
  end
  doRep(tu.goDig, logs, sides.down);
  tu.placeID(sides.down, sapling);
end

local function move()
  local success = turtle.forward();
  turtle.suckDown();
  if (not success) then
    local found, block = turtle.inspect();
    if (found and block.name:find("log")) then timber();
    else tu.goDig(sides.forward) end
  end
end

load();
if (not hasData) then setup(); end
while true do
  isForward = true;
  doRep(move, homeDist + 1);

  for y = 1, yTrees do
    doRep(move, (xTrees - 1) * (spacing + 1))
    if (y ~= yTrees) then
      turn(isForward);
      doRep(move, spacing + 1);
      turn(isForward);
      isForward = not isForward;
    end
  end

  if (isForward) then
    tu.turn(sides.back);
    doRep(move, (xTrees - 1) * (spacing + 1));
  end
  
  tu.turn(sides.right);
  doRep(move, (yTrees - 1) * (spacing + 1));
  tu.turn(sides.left);
  doRep(tu.goDig, homeDist + 1, sides.forward);
  tu.turn(sides.back);
  tu.dropAll(sides.down, blacklist);
  turtle.select(1);
  print("Sleeping for " .. sleepTime .. " seconds.");
  sleep(sleepTime);
end