local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

tUtils.blacklist["occultism:stable_wormhole"] = true;

local distance = 0;
local megaID = 0;
local place = 1;

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
    tUtils.goDig(sides.forward);
    tUtils.goDig(sides.down);
  else
    doRep(tUtils.goDig, place - 1, sides.forward);
    tUtils.goDig(sides.down);
    tUtils.turn(sides.left);
    tUtils.goDig(sides.forward);
  end
  tUtils.dig(sides.up);
  tUtils.dig(sides.down);
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
  tUtils.turn(sides.left);
  doRep(tUtils.goDig, place - 1, sides.forward);
  tUtils.turn(sides.left);
  for i = 1, 16 do
    local item = turtle.getItemDetail(i);
    if (item) then tUtils.drop(i, 64, sides.down); end
  end
  tUtils.goWait(sides.forward);
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

