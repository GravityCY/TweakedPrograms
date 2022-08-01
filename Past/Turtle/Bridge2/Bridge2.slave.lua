local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local dist = nil;

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
    turtle.placeUp();
  end
end

local id, message = rednet.receive("bridge");
dist = tonumber(message);

move();
