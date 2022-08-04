local mx, my = term.getSize();

local arg = ...;
local hideNames = false;
if (arg == "true") then hideNames = true;
elseif (arg == "false") then hideNames = false; end

local map = {};
local rendDist = 16;
local cx, cy = 0, 0;
local sc = 1;

local function screenToMap(x, y)
  return x+cx, y+cy;
end

local function mapToScreen(x, y)
  return x-cx, y-cy;
end

local function newBlock(x, y, icon, name)
  local b = {};
  b.icon = icon or "X";
  b.x, b.y = x, y;
  b.name = name;
  b.hideIcon = false;
  b.hideName = hideNames;

  function b.showIcon()
    if (b.hideIcon) then return end
    local sx, sy = mapToScreen(x, y);
    term.setCursorPos(sx, sy);
    term.write(b.icon);
  end

  function b.showName()
    if (b.hideName) then return end
    local name = b.name;
    if (name) then
      local strLen = #name;
      local cpx, cpy = mapToScreen(x, y);
      cpx, cpy = cpx - strLen / 2, cpy - 1;
      if (cpx < 1 or cpx + strLen > mx) then
        cpx = math.min(math.max(1, cpx), mx - strLen + 1);
      end
      term.setCursorPos(cpx, cpy);
      term.write(name)
    end
  end

  return b;
end

local function getBlock(x, y)
  local xTab = map[x];
  if (xTab == nil) then map[x] = {}; end
  local yTab = map[x][y];
  if (yTab == nil) then map[x][y] = newBlock(x, y) end
  return map[x][y];
end

local function draw()
  for y = 1, my do
    for x = 1, mx do
      term.setCursorPos(x, y);
      local block = getBlock(x+cx, y+cy)
      if ( x == mx / 2 and y == my / 2) then 
        term.write("*");
      else
        term.write(block.icon);
      end
      block.showName();
    end
  end
end

local function setPos(x, y)
  cx, cy = x or cx, y or cy;
  draw();
end

for x = 1, mx do
  map[x] = {};
  for y = 1, my do map[x][y] = newBlock(x, y); end
end

for x = -1, 1 do
  for y = -1, 1 do
    local b = getBlock(x, y);
    b.icon = "0";
  end
end

local sx, sy, sz = gps.locate();
draw();
while true do
  local px, py, pz = gps.locate();
  if (px and py and pz) then
    sleep(1);
    setPos(px / 16 - sx / 16, pz / 16 - sz / 16);
    draw();
  end
end

-- while true do
--   local e, p1, p2, p3 = os.pullEvent();
--   if (e == "char") then
--     local char = p1;
--     if (char == "a") then setPos(cx - 1);
--     elseif (char == "d") then setPos(cx + 1);
--     elseif (char == "w") then setPos(_, cy - 1);
--     elseif (char == "s") then setPos(_, cy + 1); end
--   elseif (e == "mouse_click") then
--     local btn, x, y = p1, p2, p3;
--     local mcx, mcy = screenToMap(x, y);
--     local block = getBlock(mcx, mcy);
--     if (btn == 1) then
--       term.clear();
--       term.setCursorPos(1, 1);
--       write("Enter Name: ");
--       block.name = read();
--       write("Enter Icon: ");
--       block.icon = read();
--       draw();
--     elseif (btn == 2) then
--       block.hideName = not block.hideName;
--       draw();
--     end
--   end 
-- end
