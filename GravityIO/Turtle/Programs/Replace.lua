local tu = require("TurtleUtils");
local sides = tu.sides;

local args = {...};

local distance = tonumber(args[1]);

local function setupDistance()
  if (distance == nil) then
    write("Enter Distance: ");
    distance = tonumber(read());
  end
end

local function moveMine()
  tu.goDig(sides.forward);
  local found = tu.inspect(sides.down);
  if (found) then
    turtle.select(16);
    tu.dig(sides.down);
    tu.drop(16, 64, sides.down);
  end
  turtle.select(tu.getAnySlot());
  tu.place(sides.down);
end

setupDistance();
for i = 1, distance do moveMine() end
