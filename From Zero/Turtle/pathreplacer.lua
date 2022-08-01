local bt = require("bt");
local tu = require("tu");
local sides = bt.sides;

local dist = tu.getInput(true, tu.types.number, "Enter Distance: ");

for i = 1, dist do
  bt.goDig(sides.forward);
  bt.dig(sides.up)
  bt.place(sides.down);
end