local bt = require("bt");
local tu = require("tu");
local sides = bt.sides;

local args = {...};

local dx, dy;

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
  dy = tonumber(args[2]);
  if (dy == nil) then
    error("Not a Number.");
  end
else
  dy = tu.getInput(true, tu.types.number, "Enter Up: ");
end

for i = 1, 16 do
  local item = turtle.getItemDetail(i);
  if (item ~= nil) then allowed[item.name] = true; end
end

local function doRep(fn, times, ...)
  for i = 1, times do fn(...) end
end

local function select(from, to)
  for i = from, to do
    local item = turtle.getItemDetail(i);
    if (item ~= nil and allowed[item.name] ~= nil) then return turtle.select(i) end
  end
end

local function selectAllowed()
  local selectedSlot = turtle.getSelectedSlot();
  local selectedItem = turtle.getItemDetail(selectedSlot);
  if (selectedItem ~= nil and allowed[selectedItem.name] ~= nil) then return turtle.select(selectedSlot); end
  local s1 = select(selectedSlot, 16);
  if (s1 ~= nil) then return s1; end
  local s2 = select(1, selectedSlot);
  if (s2 ~= nil) then return s2; end
end

local function move(height)
  bt.goDig(sides.forward);
  if (height ~= dy) then bt.dig(sides.up) end
  bt.dig(sides.down);
  if (selectAllowed()) then bt.place(sides.down); end
end

local function up()
  bt.goDig(sides.up);
  bt.turn(sides.back);
  if (selectAllowed()) then bt.place(sides.down); end
end

bt.goDig(sides.up);
for z = 1, dy do
  if (z == 1) then doRep(move, dx, z);
  else doRep(move, dx - 1, z) end
  if (z ~= dy) then up() end
end
