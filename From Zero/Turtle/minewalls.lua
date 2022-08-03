local bt = require("bt");
local tu = require("tu");
local sides = bt.sides;
local sx = tu.getInput(true, tu.types.number, "Enter Size X: ");
local sz = tu.getInput(true, tu.types.number, "Enter Size Z: ");

local function doRep(fn, times, ...)
  for i = 1,times do fn(...); end
end

doRep(bt.goDig, sx, sides.forward);
bt.turn(sides.right);
doRep(bt.goDig, sz, sides.forward);
bt.turn(sides.right);
doRep(bt.goDig, sx, sides.forward);
bt.turn(sides.right);
doRep(bt.goDig, sz, sides.forward);
bt.turn(sides.right);
