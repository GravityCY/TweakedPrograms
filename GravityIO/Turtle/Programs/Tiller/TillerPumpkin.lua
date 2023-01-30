local bt = require("BetterTurtle");
local tu = require("TermUtils");
local sides = bt.sides;

local isForward = true;
local goRight = true;
local times = 2;

local function dig(side)
  local exists =  bt.inspect(side);
  if (exists) then bt.dig(side); end
end

local function action()
  bt.dig(sides.down);
  bt.till(sides.down);
end

local function forward()
  bt.go(sides.forward);
  action();
end

local function turn(right)
  if (not goRight) then right = not right; end
  if (right) then bt.turn(sides.right);
  else bt.turn(sides.left); end
end

local function setup()
  sleep(0.25);
  local selections = {"Left", "Right"};
  local index = tu.select({selections=selections});
  if (index == 1) then goRight = false;
  elseif (index == 2) then goRight = true;
  else error() end
end

local function main()
  bt.go(sides.forward);
  for i = 1, times do
    local home = bt.getPos();
    if (goRight) then bt.goPos(home.x + 4, 0, home.z + 4);
    else bt.goPos(home.x + 4, 0, home.z - 4); end

    bt.goDig(sides.down);
    dig(sides.down);
    bt.placeID(sides.down, "minecraft:water_bucket");
    bt.go(sides.up);
    bt.goPos(home.x, 0, home.z);

    bt.face(bt.directions.px);
    action();
    for x = 1, 2 do
      for z = 1, 8 do forward(); end
      if (x ~= 2) then
        turn(isForward);
        bt.go(sides.forward);
        bt.go(sides.forward);
        forward();
        turn(isForward);
        isForward = not isForward;
      end
    end
    if (i ~= times) then
      turn(isForward);
      bt.go(sides.forward);
      bt.go(sides.forward);
      turn(isForward);
      isForward = not isForward;
    end
  end
  bt.goPos(0, 0, 0);
  bt.face(bt.directions.px);
end

setup()
main()

