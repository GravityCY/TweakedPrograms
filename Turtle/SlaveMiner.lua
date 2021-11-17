local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local mega = 9;

local function doRep(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function move()
  tUtils.goDig(sides.forward);
  tUtils.dig(sides.up);
  tUtils.dig(sides.down);
end

local function back()
  tUtils.goWait(sides.forward);
end

local function emptySpot()
  while true do
    local _, block = tUtils.inspect(sides.forward);
    if (block) then
      if (not tUtils.isTurtle(block.name)) then
        tUtils.goDig(sides.forward);
        tUtils.dig(sides.up);
        tUtils.dig(sides.down);
        return
      else
        tUtils.turn(sides.right);
        tUtils.goDig(sides.forward);
        tUtils.turn(sides.left);
      end
    else
      tUtils.goDig(sides.forward); 
      tUtils.dig(sides.up);
      tUtils.dig(sides.down);
      return
    end
  end  
end

local function dumpItems()
  local exists, block = tUtils.inspect(sides.down);
  if (block.name == "occultism:stable_wormhole") then
    tUtils.dropAll(sides.down);
    tUtils.go(sides.back);
  else
    tUtils.turn(sides.left);
    while true do
      tUtils.goWait(sides.forward);
      local exists, block = tUtils.inspect(sides.down);
      if (block.name == "occultism:stable_wormhole") then
        tUtils.turn(sides.left);
        tUtils.dropAll(sides.down);
        tUtils.go(sides.forward);
        break
      end
    end
  end
end

emptySpot();
rednet.send(mega, nil, "placed");
local _, message = rednet.receive("start");
local distance = tonumber(message);
doRep(move, distance);
rednet.send(mega, nil, "finish");
rednet.receive("back");
doRep(tUtils.goWait, distance, sides.back);
rednet.send(mega, nil, "imback");
rednet.receive("dump");
dumpItems();
