local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local mega = 9;

tUtils.goDig(sides.forward);
tUtils.turn(sides.right);

local robots = 0;

local function doRep(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function move()
  tUtils.goDig(sides.forward);
  tUtils.dig(sides.up);
  tUtils.dig(sides.down);
end

local function place()
  for i = 1, 16 do
    local t = tUtils.getSlot("computercraft:turtle_normal");
    if (t) then
      turtle.select(t);
      tUtils.dig(sides.down);
      tUtils.place(sides.down);
      peripheral.wrap("bottom").turnOn();
      tUtils.goDig(sides.forward);
      robots = robots + 1;
    else break end
  end
end

local function empty()
  local exists, block = tUtils.inspect(sides.down);
  if (block.name == "occultism:stable_wormhole") then
    tUtils.dropAll(sides.down);
  else
    tUtils.turn(sides.left);
    tUtils.dropAll(sides.forward);
  end
end

place();
tUtils.turn(sides.left);
rednet.send(mega, nil, "placed");
rednet.send(mega, nil, "setup");
local _, message = rednet.receive("start");
local distance = tonumber(message);
doRep(move, distance);
rednet.send(mega, nil, "finish");
rednet.receive("back");
doRep(tUtils.goWait, distance, sides.back);
rednet.receive("dump");
empty();

