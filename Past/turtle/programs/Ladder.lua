local tu = require("TurtleUtils");
local sides = tu.sides;

local args = {...};

local dist = tonumber(args[1]);

local ids = {}
ids.ladder = "minecraft:ladder";

local function requestInput(req)
  write(req);
  return read();
end

local function getBlock()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item ~= nil and item.name ~= ids.ladder) then return i; end
  end
end

local function hasBlock()
  local block = turtle.getItemDetail(turtle.getSelectedSlot());
  return block ~= nil and block.name ~= ids.ladder;
end

if (dist == nil) then dist = tonumber(requestInput("Enter Distance To Go Down: ")) end

tu.goDig(sides.forward);
tu.turn(sides.back);
for i = 1, dist do
  tu.goDig(sides.down);
  if (not hasBlock()) then turtle.select(getBlock()); end
  tu.dig(sides.forward);
  turtle.place();
end

tu.turn(sides.back);
tu.goDig(sides.forward);
tu.turn(sides.back);
for i = 1, dist do
  tu.placeID(sides.forward, ids.ladder)
  tu.goDig(sides.up);
end
tu.goDig(sides.forward);
tu.goDig(sides.forward);