local tu = require("TurtleUtils");

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local aDist = ...;

local dist = nil;
local blockCount = nil;

local function request(req)
  write(req);
  return read();
end

local function split(amount)
  local dropped = 0;
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item) then
      local aDrop = amount - dropped;
      if (aDrop > 64) then aDrop = 64; end
      turtle.select(i);
      turtle.drop(aDrop);
      dropped = dropped + aDrop;
      if (dropped == amount) then break end
    end
  end
  return dropped;
end

local function getSlot()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item) then return i; end
  end
end

local function move()
  for i = 1, dist do
    repeat turtle.dig() until turtle.forward();
    turtle.digUp();
    local slot = getSlot();
    turtle.select(slot);
    turtle.placeDown();
  end
end

if (aDist) then dist = tonumber(aDist);
else dist = tonumber(request("Enter Distance: ")); end
blockCount = dist * 3

turtle.turnLeft();
split(dist);
turtle.turnRight();
turtle.turnRight();
split(dist);
turtle.turnLeft();

rednet.broadcast(dist, "bridge");
move();
turtle.turnLeft();
repeat sleep(1) until turtle.dig();
turtle.turnRight();
turtle.turnRight();
repeat sleep(1) until turtle.dig();
turtle.turnLeft();