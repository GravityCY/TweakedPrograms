local bt = require("BetterTurtle");
local sides = bt.sides;

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
  bt.goDig(sides.up);
  turtle.select(botSlot);
  bt.placeDig(sides.down);
  while true do
    local s = bt.getSlot("computercraft:turtle_normal");
    if (s ~= nil) then
      robots = robots + 1;
      if (robots == 2) then bt.turn(sides.right); end
      turtle.select(s);
      bt.placeDig(sides.up);
      repeat sleep(0) until peripheral.wrap("top");
      local t = peripheral.wrap("top");
      local id = t.getID();
      idMap[id] = true;
      t.turnOn();
      respond(id, robots, "enabled");
    else
      local success = bt.suck(sides.down);
      if (not success) then break end
    end
  end
  turtle.select(botSlot);
  bt.dig(sides.down);
  if (robots > 1) then bt.turn(sides.left); end
  write("Finished Placing...");
  receiveSendDistance();
  sleep(0.5);
end

local function goStart()
  bt.turn(sides.back);
  bt.goDig(sides.up);
  doRep(bt.goDig, distance, sides.forward);
  bt.turn(sides.back);
  bt.goDig(sides.down);
end

local function start()
  write("Starting...");
  bt.blacklist["computercraft:turtle_normal"] = true;
  sendToAll(distance, "start");
  doRep(bt.goWait, distance, sides.forward);
  write("Finished Mining...");
end

local function dump()
  write("Dumping...");
  bt.goDig(sides.down);
  turtle.select(outSlot);
  bt.placeDig(sides.forward);
  turtle.select(botSlot);
  bt.placeDig(sides.down);
  turtle.select(1);
  bt.dropAll(sides.forward);
  sleep(0.5);
  sendToAll(nil, "dump");
end

local function recover()
  write("Recovering...");
  bt.blacklist["computercraft:turtle_normal"] = nil;
  for i = 1, robots do
    while true do
      local success = bt.dig(sides.up);
      if (success) then 
        local slot = bt.getSlot("computercraft:turtle_normal");
        bt.drop(slot, _, sides.down); 
        break 
      end
      sleep(0.25);
    end
  end
  turtle.select(botSlot);
  bt.dig(sides.down);
  turtle.select(outSlot);
  bt.dig(sides.forward);
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