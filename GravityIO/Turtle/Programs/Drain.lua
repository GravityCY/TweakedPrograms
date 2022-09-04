local tu = require("TurtleUtils");
local sides = tu.sides;

local function isWater()
  local exists, block = turtle.inspectDown();
  return exists and block.name:find("water");
end

local function place()
  local item = turtle.getItemDetail();
  if (item == nil) then
    for i = 1, 16 do
      local item = turtle.getItemDetail(i);
      if (item ~= nil) then turtle.select(i); end
    end
  end
  turtle.placeDown();
end

if (isWater()) then place(); end

while true do
  turtle.turnLeft();
  tu.goDig(sides.forward);
  if (isWater()) then place();
  else
    tu.go(sides.back);
    tu.turn(sides.right);
    tu.goDig(sides.forward);
    if (isWater()) then place();
    else
      tu.go(sides.back);
      tu.turn(sides.right);
      tu.goDig(sides.forward);
      if (isWater()) then place();
      else
        tu.go(sides.back);
        tu.turn(sides.right);
        tu.go(sides.forward);
      end
    end
  end
end