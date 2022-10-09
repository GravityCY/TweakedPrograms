local bt = require("BetterTurtle");
local sides = bt.sides;

local function doRep(fn, times, ...)
  for i = 1, times do fn(...); end
end

bt.goDig(sides.forward);
local logs = 0;
while true do
  local found, block = turtle.inspectUp();
  if (not found or not block.name:find("log")) then break end
  bt.goDig(sides.up);
  logs = logs + 1;
end
doRep(bt.goDig, logs, sides.down);