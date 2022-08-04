local tu = require("TurtleUtils");
local sides = tu.sides;

write("Repeat: ");
local layers = tonumber(read());

local function bmine(d)
  shell.run("bmine", d, 1, "false");
end

for h = 1, layers do
  local dist = 21;
  tu.dig(sides.up);
  tu.dig(sides.down);
  for i = 1, 3 do
    for j = 1, 4 do
      if (j == 4) then bmine(dist - 1);
      else bmine(dist); end
      turtle.turnRight();
    end
    if (i ~= 3) then
      bmine(1);
      dist = dist - 2;
    end
  end
  local fn = function(side) tu.goDig(side); end
  tu.goPos(-2, 3, -3, fn)
  tu.turn(sides.right);
end