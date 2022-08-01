local tUtils = require("TurtleUtils");
local sides = tUtils.sides;

local modem = peripheral.find("modem");
rednet.open(peripheral.getName(modem));

local args = {...};

local distance = nil;
local doReturn = true;
local outSlot = nil;
local botSlot = nil;
local botName = nil;
local robots = 0;

local idMap = {};

local function doRep(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function tobool(str)
  if (str == "true") then return true
  elseif (str == "false") then return false end
end

local function requestInput(req)
  write(req);
  return read();
end

local function setup()
  distance = args[1] or tonumber(requestInput("Enter Distance: "));
  doReturn = args[2] or tobool(requestInput("Should Return? (False / True): "));
  outSlot = args[3] or tonumber(requestInput("Enter Slot of Shulker to Dump: "));
  botSlot = args[3] or tonumber(requestInput("Enter Slot of Shulker with Turtles: "));
  botName = turtle.getItemDetail(botSlot);
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
  write("Placing...");
  tUtils.goDig(sides.up);
  turtle.select(botSlot);
  tUtils.placeDig(sides.down);
  while true do
    local s = tUtils.getSlot("computercraft:turtle_normal");
    if (s) then
      robots = robots + 1;
      if (robots == 2) then tUtils.turn(sides.right); end
      turtle.select(s);
      tUtils.placeDig(sides.up);
      repeat sleep(0) until peripheral.wrap("top");
      local t = peripheral.wrap("top");
      local id = t.getID();
      idMap[id] = true;
      t.turnOn();
      respond(id, robots, "enabled");
    else
      local success = tUtils.suck(sides.down);
      if (not success) then break end
    end
  end
  turtle.select(botSlot);
  tUtils.dig(sides.down);
  if (robots > 1) then tUtils.turn(sides.left); end
  write("Finished Placing...");
  receiveSendDistance();
  sleep(0.5);
end

local function goStart()
  tUtils.turn(sides.back);
  tUtils.goDig(sides.up);
  doRep(tUtils.goDig, distance, sides.forward);
  tUtils.turn(sides.back);
  tUtils.goDig(sides.down);
end

local function start()
  write("Starting...");
  tUtils.blacklist["computercraft:turtle_normal"] = true;
  sendToAll(distance, "start");
  doRep(tUtils.goWait, distance, sides.forward);
  write("Finished Mining...");
end

local function dump()
  write("Dumping...");
  tUtils.goDig(sides.down);
  turtle.select(outSlot);
  tUtils.placeDig(sides.forward);
  turtle.select(botSlot);
  tUtils.placeDig(sides.down);
  turtle.select(1);
  tUtils.dropAll(sides.forward);
  sleep(0.5);
  sendToAll(nil, "dump");
end

local function recover()
  write("Recovering...");
  tUtils.blacklist["computercraft:turtle_normal"] = nil;
  for i = 1, robots do
    while true do
      local success = tUtils.dig(sides.up);
      if (success) then 
        local slot = tUtils.getSlot("computercraft:turtle_normal");
        tUtils.drop(slot, _, sides.down); 
        break 
      end
      sleep(0.25);
    end
  end
  turtle.select(botSlot);
  tUtils.dig(sides.down);
  turtle.select(outSlot);
  tUtils.dig(sides.forward);
  write("Finished Recovery...");
end

local function main()
  place();
  parallel.waitForAll(start, function() waitAll("mined") end);
  dump();
  recover();
  if (doReturn) then goStart(); end
end

setup();
main();