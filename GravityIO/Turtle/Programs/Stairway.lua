local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local dist = nil;
local height = nil;
local doReturn = nil;

local args = {...};

local function doRepeat(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function requestInput(req)
  write(req);
  return read();
end

local function setup()
  dist = args[1]
  height = args[2] or 1;
  doReturn = args[3];
  if (not dist) then dist = requestInput("Enter Distance: "); end
  dist = tonumber(dist);
  height = tonumber(height);
  if (doReturn == nil) then end
end

local function forward()
  tUtils.goDig(sides.forward);
  for i = 1, height do
    if (i ~= height) then tUtils.goDig(sides.up);
    else tUtils.dig(sides.up) end
  end
  doRepeat(tUtils.goDig, height - 1, sides.down);
  tUtils.goDig(sides.down);
end

local function goBack()
  tUtils.turn(sides.back);
  for id = 1, dist do
    tUtils.goDig(sides.up);
    tUtils.goDig(sides.forward);
  end
  tUtils.turn(sides.back);
end

setup();
doRepeat(forward, dist);
goBack();
