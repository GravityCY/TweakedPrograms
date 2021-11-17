local gridSize = tonumber(...);
local mon = peripheral.find("monitor");
local mx, my = mon.getSize();
local gx, gy = (mx + 1) / gridSize, (my + 1) / gridSize;

mon.setTextScale(0.5);
term.redirect(mon);
term.setBackgroundColor(colors.black);
term.clear();

local function fillBoxAt(x, y)
  local px, py = x / gx * gx, y / gy * gy;
  local ex, ey = px + gx, py + gy;
  paintutils.drawFilledBox(px, py, ex, ey, colors.white);
end 

-- for cx = 0, gridSize - 1 do
--   for cy = 0, gridSize - 1 do
--     local sx, sy = cx * gx, cy * gy;
--     local ex, ey = sx + gx, sy + gy;
--     paintutils.drawBox(sx, sy, ex, ey, colors.white);
--   end
-- end

while true do
  local _,_, x, y = os.pullEvent("monitor_touch");
  paintutils.drawPixel(x, y, colors.white);
end