local bt = require("bt");
local tu = require("tu");
local sides = bt.sides;
local sx = tu.getInput(true, tu.types.number, "Enter Size X: ");
local sz = tu.getInput(true, tu.types.number, "Enter Size Z: ");

local function doRep(fn, times, ...)
  for i = 1,times do fn(...); end
end

local function forward()
  bt.goDig(sides.forward);
  bt.dig(sides.up);
  bt.dig(sides.down);
end

doRep(forward, sx);
bt.turn(sides.right);
doRep(forward, sz);
bt.turn(sides.right);
doRep(forward, sx);
bt.turn(sides.right);
doRep(forward, sz);
bt.turn(sides.right);
