local mons = {peripheral.find("monitor")};

local advance = 1;
local sleepTime = 0.1;

local lx, ly = 6, 1;

local lColors = {colors.white};
local size = 1;

local function draw(mon, x, y)
  for ix = 0, lx-1 do
    for iy = 0, ly-1 do
      mon.setCursorPos(x+ix, y+iy);
      mon.write(" ");
    end
  end
end

local function mapColors()
  for k,v in pairs(colors) do
    if (type(v) == "number") then
      table.insert(lColors, v);
    end
  end
  size = #lColors;
end

local current = 1;

-- mapColors();

while true do
  for _, mon in pairs(mons) do
    local mx, my = mon.getSize();
    local y = math.ceil(my / 2);
    -- local y = my / 2;
    for x = 1, mx+1, advance do
      if (size < current) then current = 1; end
      sleep(sleepTime);
      mon.setBackgroundColor(colors.black);
      mon.clear();
      mon.setBackgroundColor(current);
      draw(mon, x, y);
      current = current + 1;
    end
    mon.setBackgroundColor(colors.black);
    mon.clear();
  end
end