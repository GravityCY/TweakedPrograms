
local gridSize = 8;
local mon = peripheral.find("monitor");
local mx, my = mon.getSize();
local gx, gy = (mx + 1) / gridSize, (my + 1) / gridSize;

local buttons = {};

mon.setTextScale(0.5);
term.redirect(mon);
term.setBackgroundColor(colors.black);
term.clear();
term.setBackgroundColor(colors.white);
term.setTextColor(colors.black);

local function newVector2(x, y)
  return {x=x,y=y};
end

local function newButton(topLeft, bottomRight)
  return {topLeft=topLeft, bottomRight=bottomRight};
end

local function drawBox(topLeft, bottomRight)
  paintutils.drawBox(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
end

local function getButton(x, y)
  for i = 1, #buttons do
    local button = buttons[i];
    local sx, ex = button.topLeft.x, button.bottomRight.x;
    local sy, ey = button.topLeft.y, button.bottomRight.y;
    if (x > sx and x < ex and y > sy and y < ey) then return button; end
  end
end

for cx = 0, gridSize - 1 do
  for cy = 0, gridSize - 1 do
    local sx, sy = cx * gx, cy * gy;
    local ex, ey = sx + gx, sy + gy;
    local topLeft = newVector2(sx, sy);
    local bottomRight = newVector2(ex, ey);
    buttons[#buttons+1] = newButton(topLeft, bottomRight);
    drawBox(topLeft, bottomRight)
  end
end

while true do
  local e, btn, x, y = os.pullEvent("monitor_touch");
  local button = getButton(x, y);
  if (button) then
    local sx, ex = button.topLeft.x, button.bottomRight.x;
    local sy, ey = button.topLeft.y, button.bottomRight.y;
  end
end