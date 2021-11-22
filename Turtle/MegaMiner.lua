local tUtils = require("TurtleUtils");
local getSlot = tUtils.getSlot;
local sides = tUtils.sides;

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local arg = ...;

local outName = "occultism:stable_wormhole";

local distance = nil;
local outSlot = 1;
local maxWidth = 16;
local robots = tUtils.count("computercraft:turtle_normal");

local idMap = {};

local function doRep(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function setup()
  if (arg) then distance = tonumber(arg);
  else
    write("Enter Distance: ");
    distance = tonumber(read());
  end
  local slot = getSlot(outName);
  if (slot) then outSlot = slot
  else print("Please insert a " .. outName)error(); end
end

local function receiveSendDistance()
  local received = {};
  local total = 0;
  while true do
    local id, msg = rednet.receive("distance");
    if (idMap[id]) then
      rednet.send(id, distance, "distance");
      total = total + 1;
    end
    if (total == robots) then break end
  end
end

local function receiveFrom(iid, protocol)
  while true do
    local id, msg = rednet.receive(protocol);
    if (iid == id) then return msg end
  end
end

local function sendToAll(data, protocol)
  for id in pairs(idMap) do
    rednet.send(id, data, protocol);
  end
end

local function waitAll(protocol)
  local total = 0;
  while true do
    local id, msg = rednet.receive(protocol); 
    if (idMap[id]) then total = total + 1 end
    if (total == robots) then break end
  end
end

local function respond(id, msg, protocol)
  local res = receiveFrom(id, protocol);
  rednet.send(id, msg, protocol);
end

local function place()
  print("Placing...");
  tUtils.dig(sides.up);
  for i = robots, 1, -1 do
    local s = tUtils.getSlot("computercraft:turtle_normal");
    turtle.select(s);
    tUtils.placeWait(sides.up);
    local t = peripheral.wrap("top");
    local id = t.getID();
    idMap[id] = true;
    t.turnOn();
    respond(id, i, "enabled");
  end
  print("Finished Placing...");
  receiveSendDistance(idMap, "distance");
  sleep(0.5);
end

local function start()
  print("Starting...");
  tUtils.blacklist["computercraft:turtle_normal"] = true;
  tUtils.goDig(sides.up);
  sendToAll(distance, "start");
  doRep(tUtils.goWait, distance, sides.forward);
  waitAll("finish");
  print("Finished Mining...");
end

local function dump()
  print("Dumping...");
  tUtils.goDig(sides.down);
  tUtils.selectID("occultism:stable_wormhole");
  tUtils.place(sides.forward);
  tUtils.dropAll(sides.forward);
  turtle.select(1);
  sleep(0.5);
  sendToAll(nil, "dump");
end

local function recover()
  print("Recovering...");
  tUtils.blacklist["computercraft:turtle_normal"] = nil;
  for i = 1, robots do
    while true do
      local success = tUtils.dig(sides.up);
      if (success) then break end
      sleep(0.25);
    end
  end
  print("Finished Recovery...");
end

local function goStart()
  tUtils.dig(sides.forward);
  tUtils.turn(sides.back);
  doRep(tUtils.goDig, distance, sides.forward);
  tUtils.turn(sides.back);
end

local function main()
  place();
  start();
  dump();
  recover();
  goStart();
end

setup();
main();



