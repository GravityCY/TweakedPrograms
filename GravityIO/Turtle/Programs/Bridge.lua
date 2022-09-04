local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local arg = ...;

local distance = 0;

local function setupDistance()
  if (arg) then
    distance = tonumber(arg);
  else
    write("Enter Distance: ");
    distance = tonumber(read());
  end
end

local function moveMine()
  tUtils.goDig(sides.forward);
  tUtils.dig(sides.up);
  turtle.select(tUtils.getAnySlot());
  if (not tUtils.isBlock(sides.down)) then tUtils.placeDig(sides.down); end
end

setupDistance();
for i = 1, distance do moveMine() end
