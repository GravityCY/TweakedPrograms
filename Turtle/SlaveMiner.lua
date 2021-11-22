local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

tUtils.blacklist["occultism:stable_wormhole"] = true;

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
  print("Going to Placement...");
  tUtils.goDig(sides.forward);
  if (place ~= 1) then
    tUtils.turn(sides.right);
    doRep(tUtils.goDig, place - 1, sides.forward);
    tUtils.turn(sides.left);
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
  print("Started Mining...");
  doRep(move, distance);
  tUtils.turn(sides.back);
  rednet.send(megaID, nil, "finish");
end

local function dumpItems()
  receiveFrom(megaID, "dump");
  print("Dumping Items...");
  local exists, block = tUtils.inspect(sides.down);
  if (block.name == "occultism:stable_wormhole") then
    tUtils.dropAll(sides.down);
    tUtils.go(sides.forward);
  else
    tUtils.turn(sides.right);
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

local function main()
  setupPlacement()
  gotoPlacement();
  setupDistance();
  startMining();
  dumpItems();
  print("Finished...");
end

main();

