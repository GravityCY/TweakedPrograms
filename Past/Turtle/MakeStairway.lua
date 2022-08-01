local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local args = {...};

local dist = nil;
local doReturn = true;

local function tobool(str)
  if (type(str) == "boolean") then return str end
  if (str == "true") then return true;
  elseif (str == "false") then return false; end
end

local function doRepeat(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function requestInput(req)
  write(req);
  return read();
end

local function setup()
  dist = args[1];
  doReturn = args[2] or true;
  if (not dist) then dist = requestInput("Enter Distance: "); end
  doReturn = tobool(doReturn);
  dist = tonumber(dist);
end

local function getStairSlot()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item and item.name:lower():find("stair")) then return i end
  end
end

local function goBack()
  tUtils.turn(sides.back);
  tUtils.goDig(sides.forward);
  for i = 1, dist do
    tUtils.goDig(sides.forward);
    tUtils.goDig(sides.down);
  end
end

local function forward()
  tUtils.goDig(sides.up);
  local slot = getStairSlot();
  if (not slot) then write("No Stairs Found."); error(); end
  turtle.select(slot);
  tUtils.place(sides.down);
  tUtils.goDig(sides.forward);
end

setup();
tUtils.goDig(sides.forward);
doRepeat(forward, dist);
if (doReturn) then goBack(); end