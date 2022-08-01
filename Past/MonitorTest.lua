local mon = peripheral.find("monitor");

term.redirect(mon);

mon.setTextScale(0.5);
mon.setBackgroundColor(colors.black);
mon.clear();

local x, y = mon.getSize();
for cx = 2, x, 3 do
  for cy = 2, y, 3 do
    if (cx ~= x and cy ~= y) then
      paintutils.drawPixel(cx, cy, colors.red);
    end
  end
end

while true do
  local e, click, clx, cly = os.pullEvent("monitor_touch");
  paintutils.drawPixel(clx, cly, colors.black);
end