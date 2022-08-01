local bt = require("bt");

local isForward = true;

local mx, my, mz;

mx = tonumber(read());
my = tonumber(read());
mz = tonumber(read());

local function right()
  if (isForward) then turtle.turnRight();
  else turtle.turnLeft(); end
end

for y = 1, my do
  for x = 1, mx do
    for z = 1, mz do
      turtle.dig();
      turtle.forward();
      turtle.digUp();
      turtle.digDown();
    end
    if (x ~= mx) then
      right();
      turtle.dig();
      turtle.forward(); 
      turtle.digUp();
      turtle.digDown();
      right();
      isForward = not isForward;
    end
  end
  if (y ~= my) then
    turtle.digUp();
    turtle.up();
    turtle.digUp();
    turtle.turnRight();
    turtle.turnRight();
  end
end
