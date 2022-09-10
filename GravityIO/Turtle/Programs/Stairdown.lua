local TurtleUtils = require("TurtleUtils");
local sides = TurtleUtils.sides;
local dist = ...;

local function request(req)
  write(req);
  return read();
end

local function move()
  for i = 1, dist do
    TurtleUtils.goDig(sides.forward);
    TurtleUtils.dig(sides.up);
    TurtleUtils.goDig(sides.down);
  end
end

if (dist ~= nil) then dist = tonumber(dist);
else dist = tonumber(request("Enter Distance: ")); end

move();

