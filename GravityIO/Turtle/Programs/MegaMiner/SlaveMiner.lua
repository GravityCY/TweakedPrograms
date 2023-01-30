local bt = require("BetterTurtle");
local sides = bt.sides;

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

bt.blacklist["occultism:stable_wormhole"] = true;

local distance = 0;
local megaID = 0;
local place = 1;

local function doRep(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function move()
  bt.goDig(sides.forward);
  bt.dig(sides.up);
  bt.dig(sides.down);
end

local function back()
  bt.goWait(sides.forward);
end

local function receiveFrom(iid, protocol)
  while true do
    local id, msg = rednet.receive(protocol);
    if (id == iid) then return msg end
  end
end

local function getResponse(id, msg, protocol)
  rednet.send(id, msg, protocol);
  return receiveFrom(id, protocol);
end

local function setupPlacement()
  local mega = peripheral.wrap("bottom");
  megaID = mega.getID();
  place = getResponse(megaID, nil, "enabled");
end

local function gotoPlacement()
  write("Going to Placement...");
  if (place == 1) then
    bt.goDig(sides.forward);
    bt.goDig(sides.down);
  else
    doRep(bt.goDig, place - 1, sides.forward);
    bt.goDig(sides.down);
    bt.turn(sides.left);
    bt.goDig(sides.forward);
  end
  bt.dig(sides.up);
  bt.dig(sides.down);
end

local function setupDistance()
  while true do
    rednet.send(megaID, nil, "distance");
    local id, msg = rednet.receive("distance", 0.5);
    if (id == megaID) then distance = tonumber(msg) break end
  end
end

local function startMining()
  receiveFrom(megaID, "start");
  write("Started Mining...");
  doRep(move, distance);
  rednet.send(megaID, nil, "mined");
end

local function dumpItems()
  receiveFrom(megaID, "dump");
  write("Dumping Items...");
  bt.turn(sides.left);
  doRep(bt.goDig, place - 1, sides.forward);
  bt.turn(sides.left);
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item) then bt.drop(i, 64, sides.down); end
  end
  bt.goWait(sides.forward);
end

local function main()
  setupPlacement()
  gotoPlacement();
  setupDistance();
  startMining();
  dumpItems();
  write("Finished...");
end

main();

