local mon = peripheral.find("monitor");

local desc = "This is a thing that I would want to wrap across the whole monitor that also is capable to scroll up and down";

local mx, my = mon.getSize();

local lines = {};

local function mwrite(str)
  local x, y = mon.getCursorPos();
  if (#str + x > mx) then
    local fx = mx - x + 1;
    local fstr = str:sub(1, fx);
    local rstr = str:sub(fx + 1);
    mon.setCursorPos(1, y + 1);
    mwrite(rstr);
  else mon.write(str); end
end

local function mprint(str)
  local x, y = mon.getCursorPos();
  mwrite(str);
  mon.setCursorPos(1, y + 1);
end

local function mscroll(num)

end

mon.clear();
mon.setCursorPos(1, 1);
mon.setTextScale(0.5);
mwrite(desc);

while true do
  local _, _, x, y = os.pullEvent("monitor_touch");
  if (y == 1) then
    mscroll(1);
  elseif (y == my) then
    mscroll(-1);
  end
end