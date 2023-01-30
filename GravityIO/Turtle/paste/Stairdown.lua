local bt = require("BetterTurtle");
local sides = bt.sides;
local dist = ...;

local function request(req)
  write(req);
  return read();
end

local function move()
  for i = 1, dist do
    if (not bt.goDig(sides.forward)) then break end
    bt.dig(sides.up);
    if (not bt.goDig(sides.down)) then break end
  end
end

if (dist ~= nil) then dist = tonumber(dist);
else dist = tonumber(request("Enter Distance: ")); end

move();

