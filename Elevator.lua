local monUtils = require("MonUtils");

local mon = monUtils.wrap(peripheral.find("monitor"));
local floors = 4;

mon.setTextScale(0.5);

local mx, my = mon.getSize();
-- Offset / Padding
local ox, oy = 1, 1;
-- Spacing
-- local sx sy = 1, 1;
local sy = 1;

local mainTextColor = colors.gray;
local secondTextColor = colors.white;
local mainBGColor = colors.white;
local secondBGColor = colors.red;

local buttonXY = {};

local function getColor(i)
  local bgColor = mainBGColor;
  local textColor = mainTextColor;
  if (i % 2 == 0) then
    bgColor = secondBGColor;
    textColor = secondTextColor;
  end
  return bgColor, textColor;
end

-- local function drawFloors()
--   mon.setBackgroundColor(colors.black);
--   mon.clear();
--   mon.setCursorPos(1+ox, 1+oy);
--   for i = 1, floors do
--     local x, y = mon.getCursorPos();
--     local bgColor, textColor = getColor(i);
--     local text = tostring(i);
--     -- if not at first acceptable x pos then add spacing
--     if (x - ox ~= 1) then x = x + sx; end
--     -- if x + text length is higher than acceptible xpos then wrap
--     if (x + text:len() > mx - ox + 1) then x, y = 1 + ox, y + sy + 1 end
--     mon.setCursorPos(x, y);
--     mon.setBackgroundColor(bgColor);
--     mon.setTextColor(textColor);
--     mon.write(text);
--   end
-- end

local function drawFloors()
  mon.setBackgroundColor(colors.black);
  mon.clear();
  mon.setCursorPos(1, 1);
  for i = 1, floors do
    local text = "Floor: " .. tostring(i);
    local bgColor, textColor = getColor(i);
    mon.setBackgroundColor(bgColor);
    mon.setTextColor(textColor);
    mon.offsetX(ox);
    mon.offsetY(sy);
    local x, y = mon.getCursorPos();
    mon.print(text);
    table.insert(buttonXY, {sx=x, bx=x + text:len()-1, sy=y, by=y});
  end
end

local function getFloor(x, y)
  for index, button in pairs(buttonXY) do
    local sx, bx = button.sx, button.bx;
    local sy, by = button.sy, button.by;
    if (x >= sx and x <= bx and y >= sy and y <= by) then return index end
  end
end

drawFloors();

while true do
  local event, monitor, x, y = os.pullEvent("monitor_touch");

end