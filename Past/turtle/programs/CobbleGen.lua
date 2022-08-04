
local mined = 0;

local sides = {["forward"]=0, ["up"]=1, ["down"]=2};
local dig_sides = {sides.up, sides.down, sides.forward};


local runMainThread = true;

local function dig(side)
  local success = false;
  if (side == sides.forward) then success = turtle.dig()
  elseif(side == sides.up) then success = turtle.digUp();
  elseif(side == sides.down) then success = turtle.digDown(); end 
  if (success) then mined = mined + 1; end
end

local function doDig()
  for _, v in ipairs(dig_sides) do dig(v); end
end

local function doUI()
  term.clear();
  term.setCursorPos(1, 1);
  write("Mined: " .. mined);
end

local function mainThread()
  while true do
    doDig();
    doUI();
    sleep(0.5);
  end
end

local function modemThread()
  local modem = peripheral.find("modem");
  modem.open(1);
  local event, side, channel, rchannel, message = os.pullEvent("modem_message");
  if (message == "pause") then runMainThread = false; return
  elseif(message == "resume") then runMainThread = true; end
end

while true do
  local runs = {modemThread};
  if (runMainThread) then runs[#runs+1] = mainThread; end
  parallel.waitForAny(table.unpack(runs));
end
