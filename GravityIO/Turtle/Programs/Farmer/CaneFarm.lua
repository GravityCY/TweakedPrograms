local tu = require("TurtleUtils");
local bin = require("BinaryFile");
local sides = tu.sides;

local sleepTime = 400;

local sz = nil;
local sx = nil;

local isForward = true;

local hasData = false;

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
  sz = rf.readByte();
  sx = rf.readByte();
  rf.close();
  hasData = true;
end

local function save()
  local wf = bin.wrap(fs.open("/data/lumberjack/size.bin", "wb"));
  wf.writeByte(sz);
  wf.writeByte(sx);
  wf.close();
end

local function setup()
  sz = requestInput("Enter Length: ", "number");
  sx = requestInput("Enter Lines: " , "number");
  save();
end

local function doRep(fn, times, ...)
  for i = 1, times do fn(...) end
end

local function turn(right)
  if (right) then turtle.turnRight();
  else turtle.turnLeft(); end
end

local function move()
  tu.goDig(sides.forward);
end

local function corner()
  turn(isForward);
  doRep(move, 2);
  turn(isForward);
  isForward = not isForward;
end

local function home()
  if (isForward) then
    tu.turn(sides.back);
    doRep(move, sz - 1);
  end
  tu.turn(sides.right);
  doRep(move, (sx - 1) * 2);
  tu.turn(sides.left);
  tu.goDig(sides.forward);
  tu.turn(sides.back);
  tu.dropAll(sides.down);
  turtle.select(1);
end

load();
if (not hasData) then setup(); end
while true do
  isForward = true;
  move();
  for y = 1, sx do
    doRep(move, sz - 1);
    if (y ~= sx) then corner(); end
  end
  home();
  write("Sleeping for " .. sleepTime .. " seconds.");
  sleep(sleepTime);
end