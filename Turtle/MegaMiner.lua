local tUtils = require("TurtleUtils");
local getSlot = tUtils.getSlot;
local sides = tUtils.sides;

-- Place a Boss to place all slaves then when finished alert this MegaMiner to notify the slaves to start mining

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local arg = ...;

local distance = nil;
local maxWidth = 16;
local robots = tUtils.count("computercraft:turtle_normal");

local ids = {};

local function setupDistance()
  if (arg) then distance = tonumber(arg);
  else
    write("Enter Distance: ");
    distance = tonumber(read());
  end
end

local function placeAll()
  for i = 1, robots do
    local s = tUtils.getSlot("computercraft:turtle_normal");
    turtle.select(s);
    tUtils.placeWait(sides.up);
    local t = peripheral.wrap("top");
    table.insert(ids, t.getID());
    t.turnOn();
  end
  print("Placed All");
end

local function sendToAll(data, protocol)
  for i = 1, robots do
    local id = ids[i];
    rednet.send(id, data, protocol);
  end
end

local function waitAllPlaced()
  for i = 1, robots do
    rednet.receive("placed");
  end
  print("All Placed");
end

local function waitAllFinish()
  for i = 1, robots do
    rednet.receive("finish");
  end
  print("All Finished");
end

local function waitAllBack()
  for i = 1, robots do
    rednet.receive("imback");
  end
  print("All Back");
end

setupDistance();
parallel.waitForAll(placeAll, waitAllPlaced);
sendToAll(distance, "start");
waitAllFinish();
sendToAll(nil, "back");
tUtils.selectID("occultism:stable_wormhole");
tUtils.place(sides.forward);
turtle.select(1);
waitAllBack();
sendToAll(nil, "dump");
for i = 1, robots do
  while true do
    local success = tUtils.dig(sides.up);
    if (success) then break end
    sleep(0.25);
  end
end
tUtils.dig(sides.forward);


