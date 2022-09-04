local tu = require("TurtleUtils");
local sides = tu.sides;

local xs, zs = 8, 4;
local spacing = 1;

local isForward = true;

local function go(side, times)
  times = times or 1;
  for i = 1, times do tu.go(side); end
end

local function turn(left)
  if (left) then tu.turn(sides.left);
  else tu.turn(sides.right); end
end

local function move()
  go(sides.forward, spacing + 1);
  turtle.placeDown();
end

go(sides.forward);
turtle.placeDown();
for z = 1, zs do
  for x = 1, xs - 1 do move(); end
  if (z ~= zs) then
    turn(isForward);
    go(sides.forward, spacing + 1);
    turn(isForward);
    isForward = not isForward;
  end
end
