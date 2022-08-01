local bt = require("bt");
local sides = bt.sides;

local statusEnum = {["cms"]=1,["mbranch"]=2,["ret"]=3};
local statusFormat = {"Clearing out Main Shaft", "Mining Branch", "Returning"};

local spacing = 5;
local distance = 8;

local status = 0;

local function doRep(fn, times, ...)
  for i = 1, times do fn(...); end
end

local function dig()
  bt.goDig(sides.forward);
  bt.dig(sides.up);
  bt.dig(sides.down);
end

local function main()
  while true do
    status = statusEnum.cms;
    doRep(dig, spacing);
    bt.turn(sides.left);
    for i = 1, 2 do
      status = statusEnum.mbranch;
      doRep(dig, distance)
      bt.turn(sides.back);
      status = statusEnum.ret;
      doRep(bt.goDig, distance, sides.forward);
    end
    bt.turn(sides.right);
  end
end

local function ui()
  while true do
    term.clear();
    term.setCursorPos(1, 1);
    write("Status: " .. statusFormat[status]);
    write("Fuel Level: " .. turtle.getFuelLevel());
    sleep(1);
  end
end

parallel.waitForAny(main, ui);