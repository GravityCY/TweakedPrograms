local TurtleUtils = require("TurtleUtils");
local PerUtils = require("PerUtils");

local modem = peripheral.find("modem");
local turtleInvs = PerUtils.getByKey("list", true);

local addr = modem.getNameLocal();

local mx, my = 10, 5;
local area = mx * my;
local workers = 0;

local x, y = 0, 0;

local split = math.ceil((mx * my) / workers);

local function toPosition(index)
  return index % mx, math.ceil(index / mx);
end

local function goPosition(px, py)
  TurtleUtils.goPos(px - x, 0, py - y);
  x, y = px, py;
end

for _, inv in ipairs(turtleInvs) do
  local stop = false;
  for slot, item in pairs(inv.list()) do
    local sx, sy = toPosition(split * workers);
    TurtleUtils.goPos(2, 0, 0);
    goPosition(sx, sy);
    goPosition(1, 1);
    workers = workers + 1;
    -- inv.pushItems(addr, 1, 1, 1);
    -- turtle.place();
    -- repeat sleep(0) until peripheral.wrap("front") ~= nil
    -- peripheral.wrap("front").turnOn();
    if (workers >= area) then stop = true; break end
  end
  if (stop) then break end
end





local function loop()
  for i = 1, workers do
    for s = 1, split do
      local sx, sy = toPosition(s + split * (i - 1));
      if (sx <= mx and sy <= my) then
        if (sx == 0) then sx = mx; end
        if (sy == 0) then sy = my; end
        term.setCursorPos(sx, sy);
        term.write(tostring(i))
      end
    end
  end
end

loop();