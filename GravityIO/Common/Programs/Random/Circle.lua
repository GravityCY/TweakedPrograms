local function point(x, y)
  term.setCursorPos(x, y);
  term.write(" ");
end

local monitor = peripheral.find("monitor");

monitor.setTextScale(0.5);
term.redirect(monitor);
term.setBackgroundColor(colors.black);
term.clear();
term.setBackgroundColor(colors.white);

local mx, my = term.getSize();

local cx, cy = mx / 2, my / 2;
local r = 8;

local radStep = 1 / (1.5 * r);
for angle = 1, math.pi + radStep, radStep do
  local px = math.cos(angle) * r * 1.5;
  local py = math.sin(angle) * r;
  for i = -1, 1, 2 do
    for j = -1, 1, 2 do
      point(cx + i * px, cy + j * py);
    end
  end
end