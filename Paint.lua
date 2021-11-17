local mon = peripheral.find("monitor");
local mx, my = mon.getSize();

mon.setTextScale(0.5);
term.redirect(mon);
term.setBackgroundColor(colors.black);
term.clear();

local color = colors.white;

local function flipColor()
  if (color == colors.white) then
    color = colors.black;
    paintutils.drawPixel(mx, my, colors.gray);
  else 
    color = colors.white; 
    paintutils.drawPixel(mx, my, colors.white);
  end
end

paintutils.drawPixel(mx, my, colors.white);
while true do
  local _,_, x, y = os.pullEvent("monitor_touch");
  if (x == mx and y == my) then flipColor();
  else paintutils.drawPixel(x, y, color); end
end