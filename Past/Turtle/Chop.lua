local tu = require("TurtleUtils");
local sides = tu.sides;

local function doRep(fn, times, ...)
  for i = 1, times do fn(...); end
end

tu.goDig(sides.forward);
local logs = 0;
while true do
  local found, block = turtle.inspectUp();
  if (not found or not block.name:find("log")) then break end
  tu.goDig(sides.up);
  logs = logs + 1;
end
doRep(tu.goDig, logs, sides.down);