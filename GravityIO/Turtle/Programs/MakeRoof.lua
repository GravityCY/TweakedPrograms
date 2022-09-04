local bt = require("bt");
local tu = require("tu");
local sides = bt.sides;

local args = {...};

local dx, dz;

local isForward = true;

local allowed = {};

if (args[1] ~= nil) then
  dx = tonumber(args[1]);
  if (dx == nil) then
    error("Not a Number.");
  end
else
  dx = tu.getInput(true, tu.types.number, "Enter Forward: ");
end

if (args[2] ~= nil) then
  dz = tonumber(args[2]);
  if (dz == nil) then
    error("Not a Number.");
  end
else
  dz = tu.getInput(true, tu.types.number, "Enter Right: ");
end

for i = 1, 16 do
  local item = turtle.getItemDetail(i);
  if (item ~= nil) then allowed[item.name] = true; end
end

local function isAllowed(name)
  return allowed[name] ~= nil;
end

local function doRep(fn, times, ...)
  for i = 1, times do fn(...) end
end

local function select(from, to)
  for i = from, to do
    local item = turtle.getItemDetail(i);
    if (item ~= nil and isAllowed(item.name)) then return turtle.select(i) end
  end
end

local function selectAllowed()
  local selectedSlot = turtle.getSelectedSlot();
  local selectedItem = turtle.getItemDetail(selectedSlot);
  if (selectedItem ~= nil and isAllowed(selectedItem.name)) then return true; end
  if (select(selectedSlot, 16)) then return true; end
  if (select(1, selectedSlot)) then return true; end;
end

local function move()
  bt.goDig(sides.forward);
  bt.dig(sides.up)
  if (selectAllowed()) then bt.place(sides.up); end
end

local function turnRight(isRight)
  if (isRight) then turtle.turnRight();
  else turtle.turnLeft(); end
end

local function turn()
  turnRight(isForward);
  move();
  turnRight(isForward);
  isForward = not isForward;
end

for z = 1, dz do
  if (z == 1) then doRep(move, dx);
  else doRep(move, dx - 1) end
  if (z ~= dz) then turn() end
end
