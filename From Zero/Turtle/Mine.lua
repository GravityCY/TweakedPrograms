local bt = require("bt");
local tu = require("tu");

local isForward = true;
local mx, mz;

mx = tu.getInput(true, tu.types.number, "Enter Forward: ");
mz = tu.getInput(true, tu.types.number, "Enter Right: ");

local function right()
  if (isForward) then turtle.turnRight();
  else turtle.turnLeft(); end
end

for z = 1, mz do
  for x = 1, mx do
    turtle.dig();
    turtle.forward();
    turtle.digUp();
    turtle.digDown();
  end
  if (z ~= mz) then
    right();
    turtle.dig();
    turtle.forward(); 
    turtle.digUp();
    turtle.digDown();
    right();
    isForward = not isForward;
  end
end
