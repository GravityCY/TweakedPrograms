
local aDist = ...;

local dist = nil;

local function request(req)
  write(req);
  return read();
end

local function getSlot()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item) then return i; end
  end
end

local function move()
  for i = 1, dist do
    local item = getSlot();
    if (not item) then break end
    turtle.select(item);
    turtle.dig();
    turtle.forward();
    turtle.digDown();
    turtle.down();
    turtle.placeDown();
  end
end

if (aDist) then dist = tonumber(aDist);
else dist = request("Enter Distance: "); end

move();

