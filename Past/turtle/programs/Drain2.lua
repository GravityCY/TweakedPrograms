local tu = require("TurtleUtils");
local sides = tu.sides;

local function isWater()
  local exists, block = tu.inspect(sides.forward);
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
  tu.place(sides.down);
end

while true do
  tu.turn(sides.right);
  local success = tu.go(sides.back);
  if (success) then place();
  else
    tu.turn(sides.right);
    local success = tu.go(sides.back);
    if (success) then place();
    else
      tu.turn(sides.right);
      local success = tu.go(sides.back);
      if (success) then place();
      else
        tu.turn(sides.right);
        local success = tu.go(sides.back);
      end
    end
  end
end