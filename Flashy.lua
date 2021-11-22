local mons = {peripheral.find("monitor")};
local sleepTime = 2;

local ads = {"Want Penis Enlargement Pills?", "Come Down to GravityCY!"};

while true do
  for index, mon in pairs(mons) do
    local mx, my = mon.getSize();
    local ad = ads[index];
    local adLen = ad:len();
    mon.setBackgroundColor(colors.white);
    mon.clear();
    mon.setTextColor(colors.black);
    mon.setCursorPos(mx / 2 - adLen / 2, math.ceil(my / 2))
    mon.write(ad);
    sleep(sleepTime);
    mon.setBackgroundColor(colors.black);
    mon.clear();
  end
end