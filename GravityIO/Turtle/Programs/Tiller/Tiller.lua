local bt = require("BetterTurtle");
local sides = bt.sides;

local arg = ...;

local isForward = true;
local reverse = false;

local function dig(side)
  local exists, block =  bt.inspect(side);
  if (exists) then bt.dig(side); end
end

local function till(side)
  local exists, block = bt.inspect(side);
  if (not exists) then bt.dig(side); end
end

local function forward()
  bt.go(sides.forward);
  dig(sides.down);
  till(sides.down);
end

local function turn(right)
  if (reverse) then right = not right; end
  if (right) then bt.turn(sides.right);
  else bt.turn(sides.left); end
end

local function setup()
  if (arg ~= nil) then
    reverse = arg == "-r";
  end
end

local function main()
  if (reverse) then bt.goPos(5, 0, -4);
  else bt.goPos(5, 0, 4); end

  bt.goDig(sides.down);
  dig(sides.down);
  bt.placeID(sides.down, "minecraft:water_bucket");
  bt.go(sides.up);

  if (reverse) then bt.goPos(5, 0, -5);
  else bt.goPos(-5, 0, 5); end

  bt.turn(sides.back);
  forward();
  for x = 1, 9 do
    for z = 1, 8 do forward(); end
    if (x ~= 9) then
      turn(isForward);
      forward();
      turn(isForward);
      isForward = not isForward;
    end
  end
end

setup()
main()

